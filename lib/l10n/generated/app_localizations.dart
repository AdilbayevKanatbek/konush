import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ky'),
    Locale('ru'),
  ];

  /// No description provided for @message000.
  ///
  /// In ru, this message translates to:
  /// **'Этот номер телефона уже зарегистрирован'**
  String get message000;

  /// No description provided for @message001.
  ///
  /// In ru, this message translates to:
  /// **'Неверный номер телефона или пароль'**
  String get message001;

  /// No description provided for @message002.
  ///
  /// In ru, this message translates to:
  /// **'Неверный или просроченный код'**
  String get message002;

  /// No description provided for @message003.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт заблокирован'**
  String get message003;

  /// No description provided for @message004.
  ///
  /// In ru, this message translates to:
  /// **'Необходимо войти в аккаунт'**
  String get message004;

  /// No description provided for @message005.
  ///
  /// In ru, this message translates to:
  /// **'Данные не найдены'**
  String get message005;

  /// No description provided for @message006.
  ///
  /// In ru, this message translates to:
  /// **'Размер файла превышает 10 МБ'**
  String get message006;

  /// No description provided for @message007.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживаются JPEG, PNG и WebP'**
  String get message007;

  /// No description provided for @message008.
  ///
  /// In ru, this message translates to:
  /// **'Достигнут лимит фотографий'**
  String get message008;

  /// No description provided for @message009.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный ответ сервера'**
  String get message009;

  /// No description provided for @message010.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось связаться с сервером'**
  String get message010;

  /// No description provided for @message011.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ошибка сервера'**
  String get message011;

  /// No description provided for @message012.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get message012;

  /// No description provided for @message013.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get message013;

  /// No description provided for @message014.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get message014;

  /// No description provided for @message015.
  ///
  /// In ru, this message translates to:
  /// **'Подать'**
  String get message015;

  /// No description provided for @message016.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get message016;

  /// No description provided for @message017.
  ///
  /// In ru, this message translates to:
  /// **'Кабинет'**
  String get message017;

  /// No description provided for @message018.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get message018;

  /// No description provided for @message019.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из приложения?'**
  String get message019;

  /// No description provided for @message020.
  ///
  /// In ru, this message translates to:
  /// **'Вы сможете вернуться в Konush в любое время.'**
  String get message020;

  /// No description provided for @message021.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get message021;

  /// No description provided for @message022.
  ///
  /// In ru, this message translates to:
  /// **'Dev OTP отключён'**
  String get message022;

  /// No description provided for @message023.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить профиль. Проверьте подключение и повторите.'**
  String get message023;

  /// No description provided for @message024.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти. Повторите попытку.'**
  String get message024;

  /// No description provided for @message025.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер в формате +996 XXX XXX XXX'**
  String get message025;

  /// No description provided for @message026.
  ///
  /// In ru, this message translates to:
  /// **'Введите шестизначный код'**
  String get message026;

  /// No description provided for @message027.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите телефон'**
  String get message027;

  /// No description provided for @message028.
  ///
  /// In ru, this message translates to:
  /// **'Код восстановления'**
  String get message028;

  /// No description provided for @message029.
  ///
  /// In ru, this message translates to:
  /// **'Введите шестизначный код для номера\n{arg0}'**
  String message029(String arg0);

  /// No description provided for @message030.
  ///
  /// In ru, this message translates to:
  /// **'Код staging: {arg0}'**
  String message030(String arg0);

  /// No description provided for @message031.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get message031;

  /// No description provided for @message032.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код повторно'**
  String get message032;

  /// No description provided for @message033.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить пароль'**
  String get message033;

  /// No description provided for @message034.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон, привязанный к аккаунту.'**
  String get message034;

  /// No description provided for @message035.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get message035;

  /// No description provided for @message036.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get message036;

  /// No description provided for @message037.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён. Войдите с новым паролем.'**
  String get message037;

  /// No description provided for @message038.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get message038;

  /// No description provided for @message039.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте надёжный пароль минимум из 8 символов.'**
  String get message039;

  /// No description provided for @message040.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get message040;

  /// No description provided for @message041.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get message041;

  /// No description provided for @message042.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get message042;

  /// No description provided for @message043.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get message043;

  /// No description provided for @message044.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить запрос'**
  String get message044;

  /// No description provided for @message045.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get message045;

  /// No description provided for @message046.
  ///
  /// In ru, this message translates to:
  /// **'Шестизначный код'**
  String get message046;

  /// No description provided for @message047.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации'**
  String get message047;

  /// No description provided for @message048.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get message048;

  /// No description provided for @message049.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа'**
  String get message049;

  /// No description provided for @message050.
  ///
  /// In ru, this message translates to:
  /// **'Найдём ваш новый дом'**
  String get message050;

  /// No description provided for @message051.
  ///
  /// In ru, this message translates to:
  /// **'Рады видеть вас снова'**
  String get message051;

  /// No description provided for @message052.
  ///
  /// In ru, this message translates to:
  /// **'Создайте аккаунт и сохраняйте любимые места'**
  String get message052;

  /// No description provided for @message053.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы всё избранное было под рукой'**
  String get message053;

  /// No description provided for @message054.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get message054;

  /// No description provided for @message055.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get message055;

  /// No description provided for @message056.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get message056;

  /// No description provided for @message057.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get message057;

  /// No description provided for @message058.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get message058;

  /// No description provided for @message059.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get message059;

  /// No description provided for @message060.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get message060;

  /// No description provided for @message061.
  ///
  /// In ru, this message translates to:
  /// **'Не менее 8 символов'**
  String get message061;

  /// No description provided for @message062.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get message062;

  /// No description provided for @message063.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get message063;

  /// No description provided for @message064.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get message064;

  /// No description provided for @message065.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get message065;

  /// No description provided for @message066.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get message066;

  /// No description provided for @message067.
  ///
  /// In ru, this message translates to:
  /// **'После регистрации подтвердите номер телефона кодом.'**
  String get message067;

  /// No description provided for @message068.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение должно быть не длиннее 4000 символов'**
  String get message068;

  /// No description provided for @message069.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить отправку. Обновите переписку перед повтором.'**
  String get message069;

  /// No description provided for @message070.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя написать самому себе'**
  String get message070;

  /// No description provided for @message071.
  ///
  /// In ru, this message translates to:
  /// **'Диалог или объявление не найдено'**
  String get message071;

  /// No description provided for @message072.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к диалогу'**
  String get message072;

  /// No description provided for @message073.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сообщения. Проверьте подключение и повторите.'**
  String get message073;

  /// No description provided for @message074.
  ///
  /// In ru, this message translates to:
  /// **'Помощь Konush'**
  String get message074;

  /// No description provided for @message075.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообщений'**
  String get message075;

  /// No description provided for @message076.
  ///
  /// In ru, this message translates to:
  /// **'Откройте объявление и нажмите «Написать», чтобы связаться с продавцом.'**
  String get message076;

  /// No description provided for @message077.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get message077;

  /// No description provided for @message078.
  ///
  /// In ru, this message translates to:
  /// **'Начните переписку'**
  String get message078;

  /// No description provided for @message079.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы переписываться'**
  String get message079;

  /// No description provided for @message080.
  ///
  /// In ru, this message translates to:
  /// **'Все ваши диалоги будут доступны в аккаунте.'**
  String get message080;

  /// No description provided for @message081.
  ///
  /// In ru, this message translates to:
  /// **'Войти в аккаунт'**
  String get message081;

  /// No description provided for @message082.
  ///
  /// In ru, this message translates to:
  /// **'Войдите заново, чтобы получать сообщения'**
  String get message082;

  /// No description provided for @message083.
  ///
  /// In ru, this message translates to:
  /// **'Соединение прервано. Переподключаемся…'**
  String get message083;

  /// No description provided for @message084.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get message084;

  /// No description provided for @message085.
  ///
  /// In ru, this message translates to:
  /// **'Переписка'**
  String get message085;

  /// No description provided for @message086.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get message086;

  /// No description provided for @message087.
  ///
  /// In ru, this message translates to:
  /// **'Начните разговор'**
  String get message087;

  /// No description provided for @message088.
  ///
  /// In ru, this message translates to:
  /// **'Уточните детали объявления у продавца.'**
  String get message088;

  /// No description provided for @message089.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get message089;

  /// No description provided for @message090.
  ///
  /// In ru, this message translates to:
  /// **'Ранее'**
  String get message090;

  /// No description provided for @message091.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get message091;

  /// No description provided for @message092.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get message092;

  /// No description provided for @message093.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано'**
  String get message093;

  /// No description provided for @message094.
  ///
  /// In ru, this message translates to:
  /// **'Доставлено'**
  String get message094;

  /// No description provided for @message095.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено'**
  String get message095;

  /// No description provided for @message096.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение с изображением'**
  String get message096;

  /// No description provided for @message097.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть диалог. Повторите попытку.'**
  String get message097;

  /// No description provided for @message098.
  ///
  /// In ru, this message translates to:
  /// **'Ваше объявление'**
  String get message098;

  /// No description provided for @message099.
  ///
  /// In ru, this message translates to:
  /// **'Написать'**
  String get message099;

  /// No description provided for @message100.
  ///
  /// In ru, this message translates to:
  /// **'Ала-Тоо Резиденс'**
  String get message100;

  /// No description provided for @message101.
  ///
  /// In ru, this message translates to:
  /// **'IV кв. 2027'**
  String get message101;

  /// No description provided for @message102.
  ///
  /// In ru, this message translates to:
  /// **'Магистраль'**
  String get message102;

  /// No description provided for @message103.
  ///
  /// In ru, this message translates to:
  /// **'Бизнес'**
  String get message103;

  /// No description provided for @message104.
  ///
  /// In ru, this message translates to:
  /// **'Авангард Стиль'**
  String get message104;

  /// No description provided for @message105.
  ///
  /// In ru, this message translates to:
  /// **'Конуш Сити'**
  String get message105;

  /// No description provided for @message106.
  ///
  /// In ru, this message translates to:
  /// **'II кв. 2028'**
  String get message106;

  /// No description provided for @message107.
  ///
  /// In ru, this message translates to:
  /// **'Джал'**
  String get message107;

  /// No description provided for @message108.
  ///
  /// In ru, this message translates to:
  /// **'Комфорт'**
  String get message108;

  /// No description provided for @message109.
  ///
  /// In ru, this message translates to:
  /// **'Имарат Строй'**
  String get message109;

  /// No description provided for @message110.
  ///
  /// In ru, this message translates to:
  /// **'Тумар Тауэрс'**
  String get message110;

  /// No description provided for @message111.
  ///
  /// In ru, this message translates to:
  /// **'I кв. 2027'**
  String get message111;

  /// No description provided for @message112.
  ///
  /// In ru, this message translates to:
  /// **'Эркиндик'**
  String get message112;

  /// No description provided for @message113.
  ///
  /// In ru, this message translates to:
  /// **'Премиум'**
  String get message113;

  /// No description provided for @message114.
  ///
  /// In ru, this message translates to:
  /// **'Премиум КГ'**
  String get message114;

  /// No description provided for @message115.
  ///
  /// In ru, this message translates to:
  /// **'Эркиндик Плаза'**
  String get message115;

  /// No description provided for @message116.
  ///
  /// In ru, this message translates to:
  /// **'Асанбай Парк'**
  String get message116;

  /// No description provided for @message117.
  ///
  /// In ru, this message translates to:
  /// **'Асанбай'**
  String get message117;

  /// No description provided for @message118.
  ///
  /// In ru, this message translates to:
  /// **'Жилые комплексы'**
  String get message118;

  /// No description provided for @message119.
  ///
  /// In ru, this message translates to:
  /// **'Новый дом. Новая глава.'**
  String get message119;

  /// No description provided for @message120.
  ///
  /// In ru, this message translates to:
  /// **'Жилые комплексы Бишкека · демо-каталог'**
  String get message120;

  /// No description provided for @message121.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get message121;

  /// No description provided for @message122.
  ///
  /// In ru, this message translates to:
  /// **'Строятся'**
  String get message122;

  /// No description provided for @message123.
  ///
  /// In ru, this message translates to:
  /// **'Сданы'**
  String get message123;

  /// No description provided for @message124.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} · {arg1}-класс'**
  String message124(String arg0, String arg1);

  /// No description provided for @message125.
  ///
  /// In ru, this message translates to:
  /// **'от \${arg0}/м²'**
  String message125(String arg0);

  /// No description provided for @message126.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} квартир · {arg1}'**
  String message126(String arg0, String arg1);

  /// No description provided for @message127.
  ///
  /// In ru, this message translates to:
  /// **'Строится · {arg0}'**
  String message127(String arg0);

  /// No description provided for @message128.
  ///
  /// In ru, this message translates to:
  /// **'Сдан в {arg0}'**
  String message128(String arg0);

  /// No description provided for @message129.
  ///
  /// In ru, this message translates to:
  /// **'ЖИЛОЙ КОМПЛЕКС'**
  String get message129;

  /// No description provided for @message130.
  ///
  /// In ru, this message translates to:
  /// **'Жилой комплекс'**
  String get message130;

  /// No description provided for @message131.
  ///
  /// In ru, this message translates to:
  /// **'{arg0}, Бишкек · {arg1}-класс'**
  String message131(String arg0, String arg1);

  /// No description provided for @message132.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационный каталог. Цены, наличие и характеристики приведены для знакомства с разделом.'**
  String get message132;

  /// No description provided for @message133.
  ///
  /// In ru, this message translates to:
  /// **'О комплексе'**
  String get message133;

  /// No description provided for @message134.
  ///
  /// In ru, this message translates to:
  /// **'Застройщик'**
  String get message134;

  /// No description provided for @message135.
  ///
  /// In ru, this message translates to:
  /// **'Сдача'**
  String get message135;

  /// No description provided for @message136.
  ///
  /// In ru, this message translates to:
  /// **'Этажность'**
  String get message136;

  /// No description provided for @message137.
  ///
  /// In ru, this message translates to:
  /// **'Корпусов'**
  String get message137;

  /// No description provided for @message138.
  ///
  /// In ru, this message translates to:
  /// **'Квартиры'**
  String get message138;

  /// No description provided for @message139.
  ///
  /// In ru, this message translates to:
  /// **'Инфраструктура'**
  String get message139;

  /// No description provided for @message140.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} паркинг: {arg1} из {arg2} мест · от \${arg3}'**
  String message140(String arg0, String arg1, String arg2, String arg3);

  /// No description provided for @message141.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} помещений · {arg1}'**
  String message141(String arg0, String arg1);

  /// No description provided for @message142.
  ///
  /// In ru, this message translates to:
  /// **'Отдел продаж: {arg0}'**
  String message142(String arg0);

  /// No description provided for @message143.
  ///
  /// In ru, this message translates to:
  /// **'Контакты застройщика пока недоступны'**
  String get message143;

  /// No description provided for @message144.
  ///
  /// In ru, this message translates to:
  /// **'Все новостройки'**
  String get message144;

  /// No description provided for @message145.
  ///
  /// In ru, this message translates to:
  /// **'Чолпон Бейшенова'**
  String get message145;

  /// No description provided for @message146.
  ///
  /// In ru, this message translates to:
  /// **'Жылдыз Асанова'**
  String get message146;

  /// No description provided for @message147.
  ///
  /// In ru, this message translates to:
  /// **'Бакыт Орозбеков'**
  String get message147;

  /// No description provided for @message148.
  ///
  /// In ru, this message translates to:
  /// **'Сданный дом бизнес-класса над бульваром Эркиндик, введён в 2023 году. Консьерж, приватные лифтовые холлы, виды на дубовую аллею. Последние квартиры от застройщика.'**
  String get message148;

  /// No description provided for @message149.
  ///
  /// In ru, this message translates to:
  /// **'Современный жилой комплекс с закрытым двором, паркингом и продуманными планировками. Актуальные квартиры доступны напрямую от застройщика.'**
  String get message149;

  /// No description provided for @message150.
  ///
  /// In ru, this message translates to:
  /// **'2-комн.'**
  String get message150;

  /// No description provided for @message151.
  ///
  /// In ru, this message translates to:
  /// **'72 м²'**
  String get message151;

  /// No description provided for @message152.
  ///
  /// In ru, this message translates to:
  /// **'от \$99,400'**
  String get message152;

  /// No description provided for @message153.
  ///
  /// In ru, this message translates to:
  /// **'4-комн.\nпентхаус'**
  String get message153;

  /// No description provided for @message154.
  ///
  /// In ru, this message translates to:
  /// **'140 м²'**
  String get message154;

  /// No description provided for @message155.
  ///
  /// In ru, this message translates to:
  /// **'1-комн.'**
  String get message155;

  /// No description provided for @message156.
  ///
  /// In ru, this message translates to:
  /// **'42–48 м²'**
  String get message156;

  /// No description provided for @message157.
  ///
  /// In ru, this message translates to:
  /// **'от \${arg0}'**
  String message157(String arg0);

  /// No description provided for @message158.
  ///
  /// In ru, this message translates to:
  /// **'58–66 м²'**
  String get message158;

  /// No description provided for @message159.
  ///
  /// In ru, this message translates to:
  /// **'Наземный'**
  String get message159;

  /// No description provided for @message160.
  ///
  /// In ru, this message translates to:
  /// **'Подземный'**
  String get message160;

  /// No description provided for @message161.
  ///
  /// In ru, this message translates to:
  /// **'Офис на первом этаже · 110 м² — \$176,000'**
  String get message161;

  /// No description provided for @message162.
  ///
  /// In ru, this message translates to:
  /// **'Помещение на первом этаже'**
  String get message162;

  /// No description provided for @message163.
  ///
  /// In ru, this message translates to:
  /// **'РУС'**
  String get message163;

  /// No description provided for @message164.
  ///
  /// In ru, this message translates to:
  /// **'Дом начинается здесь'**
  String get message164;

  /// No description provided for @message165.
  ///
  /// In ru, this message translates to:
  /// **'Недвижимость в Кыргызстане'**
  String get message165;

  /// No description provided for @message166.
  ///
  /// In ru, this message translates to:
  /// **'Свежие объявления'**
  String get message166;

  /// No description provided for @message167.
  ///
  /// In ru, this message translates to:
  /// **'Объявления не загрузились'**
  String get message167;

  /// No description provided for @message168.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся новые объекты'**
  String get message168;

  /// No description provided for @message169.
  ///
  /// In ru, this message translates to:
  /// **'Объявлений пока нет. Загляните позже.'**
  String get message169;

  /// No description provided for @message170.
  ///
  /// In ru, this message translates to:
  /// **'Купить'**
  String get message170;

  /// No description provided for @message171.
  ///
  /// In ru, this message translates to:
  /// **'Своя история'**
  String get message171;

  /// No description provided for @message172.
  ///
  /// In ru, this message translates to:
  /// **'Арендовать'**
  String get message172;

  /// No description provided for @message173.
  ///
  /// In ru, this message translates to:
  /// **'Своё пространство'**
  String get message173;

  /// No description provided for @message174.
  ///
  /// In ru, this message translates to:
  /// **'Новостройки'**
  String get message174;

  /// No description provided for @message175.
  ///
  /// In ru, this message translates to:
  /// **'Новые возможности'**
  String get message175;

  /// No description provided for @message176.
  ///
  /// In ru, this message translates to:
  /// **'Жилые\nкомплексы'**
  String get message176;

  /// No description provided for @message177.
  ///
  /// In ru, this message translates to:
  /// **'Мои\nобъявления'**
  String get message177;

  /// No description provided for @message178.
  ///
  /// In ru, this message translates to:
  /// **'Помощь'**
  String get message178;

  /// No description provided for @message179.
  ///
  /// In ru, this message translates to:
  /// **'Konush · Недвижимость Кыргызстана'**
  String get message179;

  /// No description provided for @message180.
  ///
  /// In ru, this message translates to:
  /// **'Личный кабинет'**
  String get message180;

  /// No description provided for @message181.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get message181;

  /// No description provided for @message182.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get message182;

  /// No description provided for @message183.
  ///
  /// In ru, this message translates to:
  /// **'Ваше пространство в Konush'**
  String get message183;

  /// No description provided for @message184.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get message184;

  /// No description provided for @message185.
  ///
  /// In ru, this message translates to:
  /// **'Агент'**
  String get message185;

  /// No description provided for @message186.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get message186;

  /// No description provided for @message187.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы синхронизировать избранное и управлять своими объявлениями.'**
  String get message187;

  /// No description provided for @message188.
  ///
  /// In ru, this message translates to:
  /// **'Войти или зарегистрироваться'**
  String get message188;

  /// No description provided for @message189.
  ///
  /// In ru, this message translates to:
  /// **'Номер подтверждён'**
  String get message189;

  /// No description provided for @message190.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите номер телефона'**
  String get message190;

  /// No description provided for @message191.
  ///
  /// In ru, this message translates to:
  /// **'Мои объявления'**
  String get message191;

  /// No description provided for @message192.
  ///
  /// In ru, this message translates to:
  /// **'Все ваши объекты и их статусы — в одном месте.'**
  String get message192;

  /// No description provided for @message193.
  ///
  /// In ru, this message translates to:
  /// **'Открыть мои объявления'**
  String get message193;

  /// No description provided for @message194.
  ///
  /// In ru, this message translates to:
  /// **'Подать объявление'**
  String get message194;

  /// No description provided for @message195.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get message195;

  /// No description provided for @message196.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get message196;

  /// No description provided for @message197.
  ///
  /// In ru, this message translates to:
  /// **'Настройки приложения'**
  String get message197;

  /// No description provided for @message198.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get message198;

  /// No description provided for @message199.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get message199;

  /// No description provided for @message200.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get message200;

  /// No description provided for @message201.
  ///
  /// In ru, this message translates to:
  /// **'Недвижимость в Кыргызстане. Находите объекты для покупки и аренды.'**
  String get message201;

  /// No description provided for @message202.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get message202;

  /// No description provided for @message203.
  ///
  /// In ru, this message translates to:
  /// **'Для доступа к своим объявлениям понадобится снова войти.'**
  String get message203;

  /// No description provided for @message204.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить выход. Повторите попытку.'**
  String get message204;

  /// No description provided for @message205.
  ///
  /// In ru, this message translates to:
  /// **'Как сохранить объявление?'**
  String get message205;

  /// No description provided for @message206.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на сердце в карточке объекта. Сохранённые объявления доступны во вкладке «Избранное».'**
  String get message206;

  /// No description provided for @message207.
  ///
  /// In ru, this message translates to:
  /// **'Как связаться с продавцом?'**
  String get message207;

  /// No description provided for @message208.
  ///
  /// In ru, this message translates to:
  /// **'Откройте объявление и нажмите «Связаться с продавцом». Если номер указан, вы сможете позвонить.'**
  String get message208;

  /// No description provided for @message209.
  ///
  /// In ru, this message translates to:
  /// **'Где мои объявления?'**
  String get message209;

  /// No description provided for @message210.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт, откройте «Кабинет», затем «Мои объявления». Там доступны статусы и удаление.'**
  String get message210;

  /// No description provided for @message211.
  ///
  /// In ru, this message translates to:
  /// **'Как восстановить пароль?'**
  String get message211;

  /// No description provided for @message212.
  ///
  /// In ru, this message translates to:
  /// **'На экране входа нажмите «Забыли пароль?». Укажите номер +996 и следуйте шагам подтверждения.'**
  String get message212;

  /// No description provided for @message213.
  ///
  /// In ru, this message translates to:
  /// **'Как подать объявление?'**
  String get message213;

  /// No description provided for @message214.
  ///
  /// In ru, this message translates to:
  /// **'Публикация через мобильное приложение пока недоступна. Этот раздел появится в следующем обновлении.'**
  String get message214;

  /// No description provided for @message215.
  ///
  /// In ru, this message translates to:
  /// **'Здесь собраны ответы на частые вопросы. Чат с поддержкой пока недоступен.'**
  String get message215;

  /// No description provided for @message216.
  ///
  /// In ru, this message translates to:
  /// **'Чем можем помочь?'**
  String get message216;

  /// No description provided for @message217.
  ///
  /// In ru, this message translates to:
  /// **'Выберите вопрос ниже'**
  String get message217;

  /// No description provided for @message218.
  ///
  /// In ru, this message translates to:
  /// **'Начнём с главного'**
  String get message218;

  /// No description provided for @message219.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сделку и тип недвижимости'**
  String get message219;

  /// No description provided for @message220.
  ///
  /// In ru, this message translates to:
  /// **'Новое объявление'**
  String get message220;

  /// No description provided for @message221.
  ///
  /// In ru, this message translates to:
  /// **'Продать'**
  String get message221;

  /// No description provided for @message222.
  ///
  /// In ru, this message translates to:
  /// **'Сдать в аренду'**
  String get message222;

  /// No description provided for @message223.
  ///
  /// In ru, this message translates to:
  /// **'Посуточно'**
  String get message223;

  /// No description provided for @message224.
  ///
  /// In ru, this message translates to:
  /// **'Недвижимость'**
  String get message224;

  /// No description provided for @message225.
  ///
  /// In ru, this message translates to:
  /// **'Квартира'**
  String get message225;

  /// No description provided for @message226.
  ///
  /// In ru, this message translates to:
  /// **'Дом'**
  String get message226;

  /// No description provided for @message227.
  ///
  /// In ru, this message translates to:
  /// **'Коммерческая'**
  String get message227;

  /// No description provided for @message228.
  ///
  /// In ru, this message translates to:
  /// **'Участок'**
  String get message228;

  /// No description provided for @message229.
  ///
  /// In ru, this message translates to:
  /// **'Гараж'**
  String get message229;

  /// No description provided for @message230.
  ///
  /// In ru, this message translates to:
  /// **'Подача объявлений в приложении скоро появится. Сейчас можно просматривать и удалять уже размещённые объекты в кабинете.'**
  String get message230;

  /// No description provided for @message231.
  ///
  /// In ru, this message translates to:
  /// **'Публикация скоро'**
  String get message231;

  /// No description provided for @message232.
  ///
  /// In ru, this message translates to:
  /// **'Объявление'**
  String get message232;

  /// No description provided for @message233.
  ///
  /// In ru, this message translates to:
  /// **'Бишкек'**
  String get message233;

  /// No description provided for @message234.
  ///
  /// In ru, this message translates to:
  /// **'Ош'**
  String get message234;

  /// No description provided for @message235.
  ///
  /// In ru, this message translates to:
  /// **'Джалал-Абад'**
  String get message235;

  /// No description provided for @message236.
  ///
  /// In ru, this message translates to:
  /// **'Каракол'**
  String get message236;

  /// No description provided for @message237.
  ///
  /// In ru, this message translates to:
  /// **'Нарын'**
  String get message237;

  /// No description provided for @message238.
  ///
  /// In ru, this message translates to:
  /// **'Талас'**
  String get message238;

  /// No description provided for @message239.
  ///
  /// In ru, this message translates to:
  /// **'Баткен'**
  String get message239;

  /// No description provided for @message240.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить избранное'**
  String get message240;

  /// No description provided for @message241.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить избранное'**
  String get message241;

  /// No description provided for @message242.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить избранное. Попробуйте ещё раз.'**
  String get message242;

  /// No description provided for @message243.
  ///
  /// In ru, this message translates to:
  /// **'Покупка'**
  String get message243;

  /// No description provided for @message244.
  ///
  /// In ru, this message translates to:
  /// **'Аренда'**
  String get message244;

  /// No description provided for @message245.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните то, что нравится'**
  String get message245;

  /// No description provided for @message246.
  ///
  /// In ru, this message translates to:
  /// **'В этой категории пока пусто'**
  String get message246;

  /// No description provided for @message247.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на сердце рядом с объявлением, чтобы вернуться к нему позже.'**
  String get message247;

  /// No description provided for @message248.
  ///
  /// In ru, this message translates to:
  /// **'Найти недвижимость'**
  String get message248;

  /// No description provided for @message249.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} сохранено'**
  String message249(String arg0);

  /// No description provided for @message250.
  ///
  /// In ru, this message translates to:
  /// **'Золотой квадрат'**
  String get message250;

  /// No description provided for @message251.
  ///
  /// In ru, this message translates to:
  /// **'Восток-5'**
  String get message251;

  /// No description provided for @message252.
  ///
  /// In ru, this message translates to:
  /// **'Кок-Жар'**
  String get message252;

  /// No description provided for @message253.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get message253;

  /// No description provided for @message254.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get message254;

  /// No description provided for @message255.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get message255;

  /// No description provided for @message256.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get message256;

  /// No description provided for @message257.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего не нашли'**
  String get message257;

  /// No description provided for @message258.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить район, цену или количество комнат.'**
  String get message258;

  /// No description provided for @message259.
  ///
  /// In ru, this message translates to:
  /// **'Изменить фильтры'**
  String get message259;

  /// No description provided for @message260.
  ///
  /// In ru, this message translates to:
  /// **'Объявлений: {arg0}'**
  String message260(String arg0);

  /// No description provided for @message261.
  ///
  /// In ru, this message translates to:
  /// **'Демо-каталог'**
  String get message261;

  /// No description provided for @message262.
  ///
  /// In ru, this message translates to:
  /// **'От собственника'**
  String get message262;

  /// No description provided for @message263.
  ///
  /// In ru, this message translates to:
  /// **'Агентство'**
  String get message263;

  /// No description provided for @message264.
  ///
  /// In ru, this message translates to:
  /// **'Топ'**
  String get message264;

  /// No description provided for @message265.
  ///
  /// In ru, this message translates to:
  /// **'Новостройка'**
  String get message265;

  /// No description provided for @message266.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get message266;

  /// No description provided for @message267.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get message267;

  /// No description provided for @message268.
  ///
  /// In ru, this message translates to:
  /// **'Возможен торг'**
  String get message268;

  /// No description provided for @message269.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get message269;

  /// No description provided for @message270.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get message270;

  /// No description provided for @message271.
  ///
  /// In ru, this message translates to:
  /// **'{arg0}-комн.'**
  String message271(String arg0);

  /// No description provided for @message272.
  ///
  /// In ru, this message translates to:
  /// **'квартира'**
  String get message272;

  /// No description provided for @message273.
  ///
  /// In ru, this message translates to:
  /// **'дом'**
  String get message273;

  /// No description provided for @message274.
  ///
  /// In ru, this message translates to:
  /// **'коммерческая недвижимость'**
  String get message274;

  /// No description provided for @message275.
  ///
  /// In ru, this message translates to:
  /// **'участок'**
  String get message275;

  /// No description provided for @message276.
  ///
  /// In ru, this message translates to:
  /// **'гараж'**
  String get message276;

  /// No description provided for @message277.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} м²'**
  String message277(String arg0);

  /// No description provided for @message278.
  ///
  /// In ru, this message translates to:
  /// **'{arg0}/{arg1} этаж'**
  String message278(String arg0, String arg1);

  /// No description provided for @message279.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} сом'**
  String message279(String arg0);

  /// No description provided for @message280.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявление'**
  String get message280;

  /// No description provided for @message281.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение и попробуйте ещё раз.'**
  String get message281;

  /// No description provided for @message282.
  ///
  /// In ru, this message translates to:
  /// **'Новостройка · демо'**
  String get message282;

  /// No description provided for @message283.
  ///
  /// In ru, this message translates to:
  /// **'Комнаты'**
  String get message283;

  /// No description provided for @message284.
  ///
  /// In ru, this message translates to:
  /// **'Площадь'**
  String get message284;

  /// No description provided for @message285.
  ///
  /// In ru, this message translates to:
  /// **'Этаж'**
  String get message285;

  /// No description provided for @message286.
  ///
  /// In ru, this message translates to:
  /// **'Год постройки'**
  String get message286;

  /// No description provided for @message287.
  ///
  /// In ru, this message translates to:
  /// **'Об объекте'**
  String get message287;

  /// No description provided for @message288.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовано {arg0}'**
  String message288(String arg0);

  /// No description provided for @message289.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get message289;

  /// No description provided for @message290.
  ///
  /// In ru, this message translates to:
  /// **'Собственник'**
  String get message290;

  /// No description provided for @message291.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с продавцом'**
  String get message291;

  /// No description provided for @message292.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с агентом'**
  String get message292;

  /// No description provided for @message293.
  ///
  /// In ru, this message translates to:
  /// **'По объявлению: {arg0}-комн., {arg1} м² · {arg2}'**
  String message293(String arg0, String arg1, String arg2);

  /// No description provided for @message294.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть приложение телефона'**
  String get message294;

  /// No description provided for @message295.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить'**
  String get message295;

  /// No description provided for @message296.
  ///
  /// In ru, this message translates to:
  /// **'Скажите, что нашли объявление на Konush'**
  String get message296;

  /// No description provided for @message297.
  ///
  /// In ru, this message translates to:
  /// **'Продавец не указал номер телефона'**
  String get message297;

  /// No description provided for @message298.
  ///
  /// In ru, this message translates to:
  /// **'Введите число от 0'**
  String get message298;

  /// No description provided for @message299.
  ///
  /// In ru, this message translates to:
  /// **'Введите целую сумму'**
  String get message299;

  /// No description provided for @message300.
  ///
  /// In ru, this message translates to:
  /// **'От'**
  String get message300;

  /// No description provided for @message301.
  ///
  /// In ru, this message translates to:
  /// **'Не меньше значения «От»'**
  String get message301;

  /// No description provided for @message302.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get message302;

  /// No description provided for @message303.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get message303;

  /// No description provided for @message304.
  ///
  /// In ru, this message translates to:
  /// **'Любое'**
  String get message304;

  /// No description provided for @message305.
  ///
  /// In ru, this message translates to:
  /// **'Район Бишкека'**
  String get message305;

  /// No description provided for @message306.
  ///
  /// In ru, this message translates to:
  /// **'Все районы'**
  String get message306;

  /// No description provided for @message307.
  ///
  /// In ru, this message translates to:
  /// **'Цена за м², USD'**
  String get message307;

  /// No description provided for @message308.
  ///
  /// In ru, this message translates to:
  /// **'Цена, сом'**
  String get message308;

  /// No description provided for @message309.
  ///
  /// In ru, this message translates to:
  /// **'Площадь, м²'**
  String get message309;

  /// No description provided for @message310.
  ///
  /// In ru, this message translates to:
  /// **'Любой'**
  String get message310;

  /// No description provided for @message311.
  ///
  /// In ru, this message translates to:
  /// **'Не первый'**
  String get message311;

  /// No description provided for @message312.
  ///
  /// In ru, this message translates to:
  /// **'От 5 этажа'**
  String get message312;

  /// No description provided for @message313.
  ///
  /// In ru, this message translates to:
  /// **'От 10 этажа'**
  String get message313;

  /// No description provided for @message314.
  ///
  /// In ru, this message translates to:
  /// **'Показать объявления'**
  String get message314;

  /// No description provided for @message315.
  ///
  /// In ru, this message translates to:
  /// **'Удалить объявление?'**
  String get message315;

  /// No description provided for @message316.
  ///
  /// In ru, this message translates to:
  /// **'«{arg0}» будет удалено без возможности восстановления.'**
  String message316(String arg0);

  /// No description provided for @message317.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get message317;

  /// No description provided for @message318.
  ///
  /// In ru, this message translates to:
  /// **'Объявление удалено'**
  String get message318;

  /// No description provided for @message319.
  ///
  /// In ru, this message translates to:
  /// **'Ваши объявления будут здесь'**
  String get message319;

  /// No description provided for @message320.
  ///
  /// In ru, this message translates to:
  /// **'Здесь можно следить за статусами, просмотрами и контактами по вашим объектам.'**
  String get message320;

  /// No description provided for @message321.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к каталогу'**
  String get message321;

  /// No description provided for @message322.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {arg0}'**
  String message322(String arg0);

  /// No description provided for @message323.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовано'**
  String get message323;

  /// No description provided for @message324.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get message324;

  /// No description provided for @message325.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get message325;

  /// No description provided for @message326.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get message326;

  /// No description provided for @message327.
  ///
  /// In ru, this message translates to:
  /// **'{arg0} просмотров · {arg1} контактов'**
  String message327(String arg0, String arg1);

  /// No description provided for @message328.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get message328;

  /// No description provided for @message329.
  ///
  /// In ru, this message translates to:
  /// **'Удалить объявление'**
  String get message329;

  /// No description provided for @message330.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию или адресу'**
  String get message330;

  /// No description provided for @message331.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get message331;

  /// No description provided for @message332.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get message332;

  /// No description provided for @message333.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить ещё'**
  String get message333;

  /// No description provided for @message334.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить следующую страницу'**
  String get message334;

  /// No description provided for @message335.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить язык. Повторите попытку.'**
  String get message335;

  /// No description provided for @message336.
  ///
  /// In ru, this message translates to:
  /// **'/мес'**
  String get message336;

  /// No description provided for @message337.
  ///
  /// In ru, this message translates to:
  /// **'/сутки'**
  String get message337;

  /// No description provided for @message338.
  ///
  /// In ru, this message translates to:
  /// **'Откройте объявление и нажмите «Написать» для переписки или «Связаться с продавцом» для звонка.'**
  String get message338;

  /// No description provided for @message339.
  ///
  /// In ru, this message translates to:
  /// **'Объявление больше недоступно'**
  String get message339;

  /// No description provided for @message340.
  ///
  /// In ru, this message translates to:
  /// **'Можно добавить до 20 фотографий'**
  String get message340;

  /// No description provided for @message341.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать фотографии. Проверьте доступ к галерее.'**
  String get message341;

  /// No description provided for @message342.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть форму?'**
  String get message342;

  /// No description provided for @message343.
  ///
  /// In ru, this message translates to:
  /// **'Введённые данные не будут сохранены.'**
  String get message343;

  /// No description provided for @message344.
  ///
  /// In ru, this message translates to:
  /// **'Объявление уже создано. Незагруженные фотографии останутся только в этой форме.'**
  String get message344;

  /// No description provided for @message345.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте длину текста'**
  String get message345;

  /// No description provided for @message346.
  ///
  /// In ru, this message translates to:
  /// **'Введите число больше нуля'**
  String get message346;

  /// No description provided for @message347.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое число больше нуля'**
  String get message347;

  /// No description provided for @message348.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы подать объявление.'**
  String get message348;

  /// No description provided for @message349.
  ///
  /// In ru, this message translates to:
  /// **'Для подачи объявления нужен подтверждённый номер.'**
  String get message349;

  /// No description provided for @message350.
  ///
  /// In ru, this message translates to:
  /// **'Объявление отправлено на проверку'**
  String get message350;

  /// No description provided for @message351.
  ///
  /// In ru, this message translates to:
  /// **'После одобрения оно появится в каталоге. Статус доступен в моих объявлениях.'**
  String get message351;

  /// No description provided for @message352.
  ///
  /// In ru, this message translates to:
  /// **'Открыть объявление'**
  String get message352;

  /// No description provided for @message353.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите об объекте'**
  String get message353;

  /// No description provided for @message354.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get message354;

  /// No description provided for @message355.
  ///
  /// In ru, this message translates to:
  /// **'От 10 до 200 символов'**
  String get message355;

  /// No description provided for @message356.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get message356;

  /// No description provided for @message357.
  ///
  /// In ru, this message translates to:
  /// **'От 20 до 5000 символов'**
  String get message357;

  /// No description provided for @message358.
  ///
  /// In ru, this message translates to:
  /// **'Комнат'**
  String get message358;

  /// No description provided for @message359.
  ///
  /// In ru, this message translates to:
  /// **'Этаж не может быть выше этажности дома'**
  String get message359;

  /// No description provided for @message360.
  ///
  /// In ru, this message translates to:
  /// **'Этажей в доме'**
  String get message360;

  /// No description provided for @message361.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get message361;

  /// No description provided for @message362.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get message362;

  /// No description provided for @message363.
  ///
  /// In ru, this message translates to:
  /// **'Указать место на карте'**
  String get message363;

  /// No description provided for @message364.
  ///
  /// In ru, this message translates to:
  /// **'Место на карте выбрано'**
  String get message364;

  /// No description provided for @message365.
  ///
  /// In ru, this message translates to:
  /// **'Выберите точное расположение объекта для отправки.'**
  String get message365;

  /// No description provided for @message366.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get message366;

  /// No description provided for @message367.
  ///
  /// In ru, this message translates to:
  /// **'До 20 фото, JPEG, PNG или WebP, до 10 МБ каждое.'**
  String get message367;

  /// No description provided for @message368.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get message368;

  /// No description provided for @message369.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фотографии'**
  String get message369;

  /// No description provided for @message370.
  ///
  /// In ru, this message translates to:
  /// **'Объявление создано. Завершите загрузку фотографий.'**
  String get message370;

  /// No description provided for @message371.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте обязательные поля и расположение на карте.'**
  String get message371;

  /// No description provided for @message372.
  ///
  /// In ru, this message translates to:
  /// **'Проверить мои объявления'**
  String get message372;

  /// No description provided for @message373.
  ///
  /// In ru, this message translates to:
  /// **'Загружено фото'**
  String get message373;

  /// No description provided for @message374.
  ///
  /// In ru, this message translates to:
  /// **'Объявление появится в каталоге после проверки.'**
  String get message374;

  /// No description provided for @message375.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get message375;

  /// No description provided for @message376.
  ///
  /// In ru, this message translates to:
  /// **'Отправка…'**
  String get message376;

  /// No description provided for @message377.
  ///
  /// In ru, this message translates to:
  /// **'Отправить на проверку'**
  String get message377;

  /// No description provided for @message378.
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку фото'**
  String get message378;

  /// No description provided for @message379.
  ///
  /// In ru, this message translates to:
  /// **'Расположение объекта'**
  String get message379;

  /// No description provided for @message380.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на карту, чтобы отметить объект.'**
  String get message380;

  /// No description provided for @message381.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать это место'**
  String get message381;

  /// No description provided for @message382.
  ///
  /// In ru, this message translates to:
  /// **'Связь прервалась. Проверьте мои объявления перед повторной отправкой.'**
  String get message382;

  /// No description provided for @message383.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить результат. Проверьте мои объявления.'**
  String get message383;

  /// No description provided for @message384.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить жилые комплексы'**
  String get message384;

  /// No description provided for @message385.
  ///
  /// In ru, this message translates to:
  /// **'Название ЖК или застройщик'**
  String get message385;

  /// No description provided for @message386.
  ///
  /// In ru, this message translates to:
  /// **'Жилых комплексов пока нет'**
  String get message386;

  /// No description provided for @message387.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся опубликованные жилые комплексы. Попробуйте изменить поиск или обновить список позже.'**
  String get message387;

  /// No description provided for @message388.
  ///
  /// In ru, this message translates to:
  /// **'Цена не указана'**
  String get message388;

  /// No description provided for @message389.
  ///
  /// In ru, this message translates to:
  /// **'от'**
  String get message389;

  /// No description provided for @message390.
  ///
  /// In ru, this message translates to:
  /// **'сом'**
  String get message390;

  /// No description provided for @message391.
  ///
  /// In ru, this message translates to:
  /// **'Сдан'**
  String get message391;

  /// No description provided for @message392.
  ///
  /// In ru, this message translates to:
  /// **'Строится'**
  String get message392;

  /// No description provided for @message393.
  ///
  /// In ru, this message translates to:
  /// **'кв.'**
  String get message393;

  /// No description provided for @message394.
  ///
  /// In ru, this message translates to:
  /// **'Готовность'**
  String get message394;

  /// No description provided for @message395.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить жилой комплекс'**
  String get message395;

  /// No description provided for @message396.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить предложения'**
  String get message396;

  /// No description provided for @message397.
  ///
  /// In ru, this message translates to:
  /// **'Комплекс может быть недоступен. Попробуйте обновить страницу.'**
  String get message397;

  /// No description provided for @message398.
  ///
  /// In ru, this message translates to:
  /// **'Доступные предложения'**
  String get message398;

  /// No description provided for @message399.
  ///
  /// In ru, this message translates to:
  /// **'Свободных предложений пока нет'**
  String get message399;

  /// No description provided for @message400.
  ///
  /// In ru, this message translates to:
  /// **'Паркинг'**
  String get message400;

  /// No description provided for @message401.
  ///
  /// In ru, this message translates to:
  /// **'Офис'**
  String get message401;

  /// No description provided for @message402.
  ///
  /// In ru, this message translates to:
  /// **'Корпус'**
  String get message402;

  /// No description provided for @message403.
  ///
  /// In ru, this message translates to:
  /// **'От 3 до 300 символов'**
  String get message403;

  /// No description provided for @message404.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get message404;

  /// No description provided for @message405.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать объявление'**
  String get message405;

  /// No description provided for @message406.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get message406;

  /// No description provided for @message407.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get message407;

  /// No description provided for @message408.
  ///
  /// In ru, this message translates to:
  /// **'Повторить сохранение'**
  String get message408;

  /// No description provided for @message409.
  ///
  /// In ru, this message translates to:
  /// **'Изменения сохранены'**
  String get message409;

  /// No description provided for @message410.
  ///
  /// In ru, this message translates to:
  /// **'Актуальный статус доступен в моих объявлениях.'**
  String get message410;

  /// No description provided for @message411.
  ///
  /// In ru, this message translates to:
  /// **'Изменение содержания отправит объявление на повторную проверку.'**
  String get message411;

  /// No description provided for @message412.
  ///
  /// In ru, this message translates to:
  /// **'Несохранённые изменения будут потеряны.'**
  String get message412;

  /// No description provided for @message413.
  ///
  /// In ru, this message translates to:
  /// **'Изменения объявления уже сохранены. Работа с фотографиями не завершена.'**
  String get message413;

  /// No description provided for @message414.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть фото'**
  String get message414;

  /// No description provided for @message415.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии будут удалены после сохранения.'**
  String get message415;

  /// No description provided for @message416.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование недоступно'**
  String get message416;

  /// No description provided for @message417.
  ///
  /// In ru, this message translates to:
  /// **'В этом статусе объявление нельзя редактировать.'**
  String get message417;

  /// No description provided for @message418.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить объявление'**
  String get message418;

  /// No description provided for @message419.
  ///
  /// In ru, this message translates to:
  /// **'Без отделки (ПСО)'**
  String get message419;

  /// No description provided for @message420.
  ///
  /// In ru, this message translates to:
  /// **'В любое время'**
  String get message420;

  /// No description provided for @message421.
  ///
  /// In ru, this message translates to:
  /// **'В месяц'**
  String get message421;

  /// No description provided for @message422.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get message422;

  /// No description provided for @message423.
  ///
  /// In ru, this message translates to:
  /// **'Введите положительное целое число'**
  String get message423;

  /// No description provided for @message424.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться в каталог'**
  String get message424;

  /// No description provided for @message425.
  ///
  /// In ru, this message translates to:
  /// **'Вечером'**
  String get message425;

  /// No description provided for @message426.
  ///
  /// In ru, this message translates to:
  /// **'Видео о комплексе'**
  String get message426;

  /// No description provided for @message427.
  ///
  /// In ru, this message translates to:
  /// **'Видеонаблюдение'**
  String get message427;

  /// No description provided for @message428.
  ///
  /// In ru, this message translates to:
  /// **'Все предложения'**
  String get message428;

  /// No description provided for @message429.
  ///
  /// In ru, this message translates to:
  /// **'Всего выплат по кредиту'**
  String get message429;

  /// No description provided for @message430.
  ///
  /// In ru, this message translates to:
  /// **'Высота потолков'**
  String get message430;

  /// No description provided for @message431.
  ///
  /// In ru, this message translates to:
  /// **'Государственная программа'**
  String get message431;

  /// No description provided for @message432.
  ///
  /// In ru, this message translates to:
  /// **'Готовность от, %'**
  String get message432;

  /// No description provided for @message433.
  ///
  /// In ru, this message translates to:
  /// **'Данные о строительстве предоставлены застройщиком. Платформа не гарантирует сроки сдачи.'**
  String get message433;

  /// No description provided for @message434.
  ///
  /// In ru, this message translates to:
  /// **'Детская площадка'**
  String get message434;

  /// No description provided for @message435.
  ///
  /// In ru, this message translates to:
  /// **'Детский сад'**
  String get message435;

  /// No description provided for @message436.
  ///
  /// In ru, this message translates to:
  /// **'Диапазон ставки'**
  String get message436;

  /// No description provided for @message437.
  ///
  /// In ru, this message translates to:
  /// **'Днём'**
  String get message437;

  /// No description provided for @message438.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get message438;

  /// No description provided for @message439.
  ///
  /// In ru, this message translates to:
  /// **'Допустимый диапазон'**
  String get message439;

  /// No description provided for @message440.
  ///
  /// In ru, this message translates to:
  /// **'Есть ипотека'**
  String get message440;

  /// No description provided for @message441.
  ///
  /// In ru, this message translates to:
  /// **'Есть квартиры с комнатностью'**
  String get message441;

  /// No description provided for @message442.
  ///
  /// In ru, this message translates to:
  /// **'Есть рассрочка'**
  String get message442;

  /// No description provided for @message443.
  ///
  /// In ru, this message translates to:
  /// **'Забронировано'**
  String get message443;

  /// No description provided for @message444.
  ///
  /// In ru, this message translates to:
  /// **'Завершена'**
  String get message444;

  /// No description provided for @message445.
  ///
  /// In ru, this message translates to:
  /// **'Заказать звонок'**
  String get message445;

  /// No description provided for @message446.
  ///
  /// In ru, this message translates to:
  /// **'Закрытая территория'**
  String get message446;

  /// No description provided for @message447.
  ///
  /// In ru, this message translates to:
  /// **'Заявка на звонок'**
  String get message447;

  /// No description provided for @message448.
  ///
  /// In ru, this message translates to:
  /// **'Заявка на этот объект уже отправлена. Проверьте мои заявки.'**
  String get message448;

  /// No description provided for @message449.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отправлена'**
  String get message449;

  /// No description provided for @message450.
  ///
  /// In ru, this message translates to:
  /// **'Заявок пока нет'**
  String get message450;

  /// No description provided for @message451.
  ///
  /// In ru, this message translates to:
  /// **'Земляные работы'**
  String get message451;

  /// No description provided for @message452.
  ///
  /// In ru, this message translates to:
  /// **'Инфраструктура — все выбранные'**
  String get message452;

  /// No description provided for @message453.
  ///
  /// In ru, this message translates to:
  /// **'Ипотека'**
  String get message453;

  /// No description provided for @message454.
  ///
  /// In ru, this message translates to:
  /// **'Ипотечных программ пока нет'**
  String get message454;

  /// No description provided for @message455.
  ///
  /// In ru, this message translates to:
  /// **'КБ'**
  String get message455;

  /// No description provided for @message456.
  ///
  /// In ru, this message translates to:
  /// **'Каждый платёж'**
  String get message456;

  /// No description provided for @message457.
  ///
  /// In ru, this message translates to:
  /// **'Каркас'**
  String get message457;

  /// No description provided for @message458.
  ///
  /// In ru, this message translates to:
  /// **'Класс жилья'**
  String get message458;

  /// No description provided for @message459.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get message459;

  /// No description provided for @message460.
  ///
  /// In ru, this message translates to:
  /// **'Коммерческая программа'**
  String get message460;

  /// No description provided for @message461.
  ///
  /// In ru, this message translates to:
  /// **'Коммерческие помещения'**
  String get message461;

  /// No description provided for @message462.
  ///
  /// In ru, this message translates to:
  /// **'Комплексы застройщика'**
  String get message462;

  /// No description provided for @message463.
  ///
  /// In ru, this message translates to:
  /// **'Консьерж'**
  String get message463;

  /// No description provided for @message464.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get message464;

  /// No description provided for @message465.
  ///
  /// In ru, this message translates to:
  /// **'Кредит'**
  String get message465;

  /// No description provided for @message466.
  ///
  /// In ru, this message translates to:
  /// **'Лифт'**
  String get message466;

  /// No description provided for @message467.
  ///
  /// In ru, this message translates to:
  /// **'Максимальная сумма кредита'**
  String get message467;

  /// No description provided for @message468.
  ///
  /// In ru, this message translates to:
  /// **'Максимум должен быть не меньше минимума'**
  String get message468;

  /// No description provided for @message469.
  ///
  /// In ru, this message translates to:
  /// **'Машиноместа от'**
  String get message469;

  /// No description provided for @message470.
  ///
  /// In ru, this message translates to:
  /// **'Мои заявки'**
  String get message470;

  /// No description provided for @message471.
  ///
  /// In ru, this message translates to:
  /// **'На карте'**
  String get message471;

  /// No description provided for @message472.
  ///
  /// In ru, this message translates to:
  /// **'Наземная парковка'**
  String get message472;

  /// No description provided for @message473.
  ///
  /// In ru, this message translates to:
  /// **'Не более 500 символов'**
  String get message473;

  /// No description provided for @message474.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть ссылку'**
  String get message474;

  /// No description provided for @message475.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить заявку. Проверьте данные.'**
  String get message475;

  /// No description provided for @message476.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя отправить заявку на свой объект'**
  String get message476;

  /// No description provided for @message477.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено по этим фильтрам'**
  String get message477;

  /// No description provided for @message478.
  ///
  /// In ru, this message translates to:
  /// **'Новая'**
  String get message478;

  /// No description provided for @message479.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено'**
  String get message479;

  /// No description provided for @message480.
  ///
  /// In ru, this message translates to:
  /// **'Объект'**
  String get message480;

  /// No description provided for @message481.
  ///
  /// In ru, this message translates to:
  /// **'Объект в ЖК'**
  String get message481;

  /// No description provided for @message482.
  ///
  /// In ru, this message translates to:
  /// **'Объект недоступен'**
  String get message482;

  /// No description provided for @message483.
  ///
  /// In ru, this message translates to:
  /// **'Объект скрыт или больше не опубликован.'**
  String get message483;

  /// No description provided for @message484.
  ///
  /// In ru, this message translates to:
  /// **'Ответ не получен. Проверьте список заявок перед повторной отправкой.'**
  String get message484;

  /// No description provided for @message485.
  ///
  /// In ru, this message translates to:
  /// **'Отделка'**
  String get message485;

  /// No description provided for @message486.
  ///
  /// In ru, this message translates to:
  /// **'Отклонена'**
  String get message486;

  /// No description provided for @message487.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заявку'**
  String get message487;

  /// No description provided for @message488.
  ///
  /// In ru, this message translates to:
  /// **'Охрана'**
  String get message488;

  /// No description provided for @message489.
  ///
  /// In ru, this message translates to:
  /// **'Парк рядом'**
  String get message489;

  /// No description provided for @message490.
  ///
  /// In ru, this message translates to:
  /// **'Первый взнос'**
  String get message490;

  /// No description provided for @message491.
  ///
  /// In ru, this message translates to:
  /// **'Первый взнос от, %'**
  String get message491;

  /// No description provided for @message492.
  ///
  /// In ru, this message translates to:
  /// **'Первый взнос, %'**
  String get message492;

  /// No description provided for @message493.
  ///
  /// In ru, this message translates to:
  /// **'Переплата'**
  String get message493;

  /// No description provided for @message494.
  ///
  /// In ru, this message translates to:
  /// **'Период платежа не указан'**
  String get message494;

  /// No description provided for @message495.
  ///
  /// In ru, this message translates to:
  /// **'Планировка'**
  String get message495;

  /// No description provided for @message496.
  ///
  /// In ru, this message translates to:
  /// **'Платежей'**
  String get message496;

  /// No description provided for @message497.
  ///
  /// In ru, this message translates to:
  /// **'Площадь до, м²'**
  String get message497;

  /// No description provided for @message498.
  ///
  /// In ru, this message translates to:
  /// **'Площадь от, м²'**
  String get message498;

  /// No description provided for @message499.
  ///
  /// In ru, this message translates to:
  /// **'Площадь по возрастанию'**
  String get message499;

  /// No description provided for @message500.
  ///
  /// In ru, this message translates to:
  /// **'Площадь по убыванию'**
  String get message500;

  /// No description provided for @message501.
  ///
  /// In ru, this message translates to:
  /// **'По готовности'**
  String get message501;

  /// No description provided for @message502.
  ///
  /// In ru, this message translates to:
  /// **'По корпусу, этажу и номеру'**
  String get message502;

  /// No description provided for @message503.
  ///
  /// In ru, this message translates to:
  /// **'По сроку сдачи'**
  String get message503;

  /// No description provided for @message504.
  ///
  /// In ru, this message translates to:
  /// **'По цене за м²'**
  String get message504;

  /// No description provided for @message505.
  ///
  /// In ru, this message translates to:
  /// **'Под ключ'**
  String get message505;

  /// No description provided for @message506.
  ///
  /// In ru, this message translates to:
  /// **'Подземный паркинг'**
  String get message506;

  /// No description provided for @message507.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите телефон перед отправкой заявки'**
  String get message507;

  /// No description provided for @message508.
  ///
  /// In ru, this message translates to:
  /// **'Показать телефон'**
  String get message508;

  /// No description provided for @message509.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить фильтры или обновить список позже.'**
  String get message509;

  /// No description provided for @message510.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте обновить список позже.'**
  String get message510;

  /// No description provided for @message511.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть свободные'**
  String get message511;

  /// No description provided for @message512.
  ///
  /// In ru, this message translates to:
  /// **'Предложений пока нет'**
  String get message512;

  /// No description provided for @message513.
  ///
  /// In ru, this message translates to:
  /// **'Предложения в ЖК'**
  String get message513;

  /// No description provided for @message514.
  ///
  /// In ru, this message translates to:
  /// **'Предчистовая'**
  String get message514;

  /// No description provided for @message515.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get message515;

  /// No description provided for @message516.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте допустимое значение'**
  String get message516;

  /// No description provided for @message517.
  ///
  /// In ru, this message translates to:
  /// **'Проектирование'**
  String get message517;

  /// No description provided for @message518.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр изображения'**
  String get message518;

  /// No description provided for @message519.
  ///
  /// In ru, this message translates to:
  /// **'Рассрочка'**
  String get message519;

  /// No description provided for @message520.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитать ипотеку'**
  String get message520;

  /// No description provided for @message521.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитать рассрочку'**
  String get message521;

  /// No description provided for @message522.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт ориентировочный. Решение и окончательную ставку определяет банк.'**
  String get message522;

  /// No description provided for @message523.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт ориентировочный. Уточните условия у застройщика.'**
  String get message523;

  /// No description provided for @message524.
  ///
  /// In ru, this message translates to:
  /// **'Сайт застройщика'**
  String get message524;

  /// No description provided for @message525.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get message525;

  /// No description provided for @message526.
  ///
  /// In ru, this message translates to:
  /// **'Свободно'**
  String get message526;

  /// No description provided for @message527.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с застройщиком'**
  String get message527;

  /// No description provided for @message528.
  ///
  /// In ru, this message translates to:
  /// **'Сдача до года'**
  String get message528;

  /// No description provided for @message529.
  ///
  /// In ru, this message translates to:
  /// **'Сдача с года'**
  String get message529;

  /// No description provided for @message530.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Попробуйте позже.'**
  String get message530;

  /// No description provided for @message531.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дешевле'**
  String get message531;

  /// No description provided for @message532.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дороже'**
  String get message532;

  /// No description provided for @message533.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новые'**
  String get message533;

  /// No description provided for @message534.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get message534;

  /// No description provided for @message535.
  ///
  /// In ru, this message translates to:
  /// **'Спортплощадка'**
  String get message535;

  /// No description provided for @message536.
  ///
  /// In ru, this message translates to:
  /// **'Срок до, лет'**
  String get message536;

  /// No description provided for @message537.
  ///
  /// In ru, this message translates to:
  /// **'Срок сдачи не указан'**
  String get message537;

  /// No description provided for @message538.
  ///
  /// In ru, this message translates to:
  /// **'Срок сдачи прошёл'**
  String get message538;

  /// No description provided for @message539.
  ///
  /// In ru, this message translates to:
  /// **'Срок, лет'**
  String get message539;

  /// No description provided for @message540.
  ///
  /// In ru, this message translates to:
  /// **'Ставка от'**
  String get message540;

  /// No description provided for @message541.
  ///
  /// In ru, this message translates to:
  /// **'Статус продажи'**
  String get message541;

  /// No description provided for @message542.
  ///
  /// In ru, this message translates to:
  /// **'Стоимость с удорожанием'**
  String get message542;

  /// No description provided for @message543.
  ///
  /// In ru, this message translates to:
  /// **'Стоимость, сом'**
  String get message543;

  /// No description provided for @message544.
  ///
  /// In ru, this message translates to:
  /// **'Студия'**
  String get message544;

  /// No description provided for @message545.
  ///
  /// In ru, this message translates to:
  /// **'Сумма кредита превышает лимит программы'**
  String get message545;

  /// No description provided for @message546.
  ///
  /// In ru, this message translates to:
  /// **'Тип объекта'**
  String get message546;

  /// No description provided for @message547.
  ///
  /// In ru, this message translates to:
  /// **'Только сданные'**
  String get message547;

  /// No description provided for @message548.
  ///
  /// In ru, this message translates to:
  /// **'Удобное время'**
  String get message548;

  /// No description provided for @message549.
  ///
  /// In ru, this message translates to:
  /// **'Удорожание за весь срок'**
  String get message549;

  /// No description provided for @message550.
  ///
  /// In ru, this message translates to:
  /// **'Условия банка'**
  String get message550;

  /// No description provided for @message551.
  ///
  /// In ru, this message translates to:
  /// **'Условия расчёта недоступны'**
  String get message551;

  /// No description provided for @message552.
  ///
  /// In ru, this message translates to:
  /// **'Условия сверены'**
  String get message552;

  /// No description provided for @message553.
  ///
  /// In ru, this message translates to:
  /// **'Утром'**
  String get message553;

  /// No description provided for @message554.
  ///
  /// In ru, this message translates to:
  /// **'Фасад'**
  String get message554;

  /// No description provided for @message555.
  ///
  /// In ru, this message translates to:
  /// **'Фитнес-зал'**
  String get message555;

  /// No description provided for @message556.
  ///
  /// In ru, this message translates to:
  /// **'Фундамент'**
  String get message556;

  /// No description provided for @message557.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get message557;

  /// No description provided for @message558.
  ///
  /// In ru, this message translates to:
  /// **'Цена до, сом'**
  String get message558;

  /// No description provided for @message559.
  ///
  /// In ru, this message translates to:
  /// **'Цена за м² до, сом'**
  String get message559;

  /// No description provided for @message560.
  ///
  /// In ru, this message translates to:
  /// **'Цена за м² от, сом'**
  String get message560;

  /// No description provided for @message561.
  ///
  /// In ru, this message translates to:
  /// **'Цена от, сом'**
  String get message561;

  /// No description provided for @message562.
  ///
  /// In ru, this message translates to:
  /// **'Цены могут быть неактуальны'**
  String get message562;

  /// No description provided for @message563.
  ///
  /// In ru, this message translates to:
  /// **'Цены обновлены'**
  String get message563;

  /// No description provided for @message564.
  ///
  /// In ru, this message translates to:
  /// **'Цены опубликованы'**
  String get message564;

  /// No description provided for @message565.
  ///
  /// In ru, this message translates to:
  /// **'Школа'**
  String get message565;

  /// No description provided for @message566.
  ///
  /// In ru, this message translates to:
  /// **'Эконом'**
  String get message566;

  /// No description provided for @message567.
  ///
  /// In ru, this message translates to:
  /// **'Этаж до'**
  String get message567;

  /// No description provided for @message568.
  ///
  /// In ru, this message translates to:
  /// **'Этаж от'**
  String get message568;

  /// No description provided for @message569.
  ///
  /// In ru, this message translates to:
  /// **'Этаж по возрастанию'**
  String get message569;

  /// No description provided for @message570.
  ///
  /// In ru, this message translates to:
  /// **'Этаж по убыванию'**
  String get message570;

  /// No description provided for @message571.
  ///
  /// In ru, this message translates to:
  /// **'Этажей'**
  String get message571;

  /// No description provided for @message572.
  ///
  /// In ru, this message translates to:
  /// **'ежемесячно'**
  String get message572;

  /// No description provided for @message573.
  ///
  /// In ru, this message translates to:
  /// **'комн. квартира'**
  String get message573;

  /// No description provided for @message574.
  ///
  /// In ru, this message translates to:
  /// **'мес.'**
  String get message574;

  /// No description provided for @message575.
  ///
  /// In ru, this message translates to:
  /// **'раз в год'**
  String get message575;

  /// No description provided for @message576.
  ///
  /// In ru, this message translates to:
  /// **'раз в квартал'**
  String get message576;

  /// No description provided for @message577.
  ///
  /// In ru, this message translates to:
  /// **'раз в полгода'**
  String get message577;

  /// No description provided for @message578.
  ///
  /// In ru, this message translates to:
  /// **'сом/м²'**
  String get message578;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
