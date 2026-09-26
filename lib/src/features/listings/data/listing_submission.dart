import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/features/listings/data/listing_model.dart';
import 'package:konush/src/features/listings/domain/listing.dart';

class ListingUpload {
  ListingUpload({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
  bool uploaded = false;
  String? get mime {
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        listEquals(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10])) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}

class ListingSubmissionRepository {
  const ListingSubmissionRepository(this.client);
  final ApiClient client;
  Future<Listing> create(Map<String, dynamic> draft) async =>
      (await client.post(
        '/listings',
        data: draft,
        decode: (json) => ListingModel.fromJson(json! as Map<String, dynamic>),
      )).data;
  Future<Listing> update(String id, Map<String, dynamic> draft) async =>
      (await client.put(
        '/listings/$id',
        data: draft,
        decode: (json) => ListingModel.fromJson(json! as Map<String, dynamic>),
      )).data;

  Future<void> deletePhoto(String id, String photoId) async {
    await client.delete(
      '/listings/$id/photos/$photoId',
      decode: (json) => json,
    );
  }

  Future<void> upload(String id, ListingUpload photo) async {
    final mime = photo.mime;
    if (mime == null) {
      throw const AppException(
        'Поддерживаются JPEG, PNG и WebP',
        code: 'INVALID_FILE_TYPE',
      );
    }
    if (photo.bytes.length > 10 * 1024 * 1024) {
      throw const AppException(
        'Размер файла превышает 10 МБ',
        code: 'FILE_TOO_LARGE',
      );
    }
    await client.post(
      '/listings/$id/photos',
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          photo.bytes,
          filename: photo.name,
          contentType: DioMediaType.parse(mime),
        ),
      }),
      decode: (json) => json,
    );
  }
}

/// Keeps the server ID and successful uploads across retries in this form.
/// Ambiguous create/upload results must be checked by the user before retrying.
class ListingSubmission extends ChangeNotifier {
  ListingSubmission(this.repository, {this.listingId});
  final ListingSubmissionRepository repository;
  final String? listingId;
  final _deletedPhotoIds = <String>{};
  Listing? created;
  bool busy = false, complete = false, uncertain = false, _disposed = false;
  String? error;
  Object? validationDetails;
  int uploadedCount = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> submit(
    Map<String, dynamic> draft,
    List<ListingUpload> photos, {
    Iterable<String> removedPhotoIds = const [],
  }) async {
    if (busy || complete || uncertain || _disposed) return;
    busy = true;
    error = null;
    validationDetails = null;
    _notify();
    try {
      created ??= listingId == null
          ? await repository.create(draft)
          : await repository.update(listingId!, draft);
      _notify();
      for (final photoId in removedPhotoIds) {
        if (_deletedPhotoIds.contains(photoId)) continue;
        await repository.deletePhoto(created!.id, photoId);
        _deletedPhotoIds.add(photoId);
      }
      for (final photo in photos) {
        if (photo.uploaded) continue;
        await repository.upload(created!.id, photo);
        photo.uploaded = true;
        uploadedCount++;
        _notify();
      }
      complete = true;
    } catch (failure) {
      if (failure is AppException) {
        uncertain =
            failure.statusCode == null && failure.code == null ||
            (failure.statusCode != null && failure.statusCode! >= 500);
        validationDetails = failure.details;
        error = uncertain
            ? 'Связь прервалась. Проверьте мои объявления перед повторной отправкой.'
            : failure.code == 'PHONE_NOT_VERIFIED'
            ? 'Подтвердите номер телефона'
            : failure.code == 'INVALID_STATUS'
            ? 'В этом статусе объявление нельзя редактировать.'
            : failure.userMessage;
      } else {
        uncertain = true;
        error = 'Не удалось подтвердить результат. Проверьте мои объявления.';
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
