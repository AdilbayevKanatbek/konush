import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared source for the catalog and listing location picker. NetworkTileProvider
/// uses flutter_map's built-in cache and respects the server's cache headers.
class OpenStreetMapTiles extends StatelessWidget {
  const OpenStreetMapTiles({super.key});

  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.konush.konush',
    maxNativeZoom: 19,
  );
}

class OpenStreetMapAttribution extends StatelessWidget {
  const OpenStreetMapAttribution({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () =>
              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 11, color: Color(0xFF12211F)),
            ),
          ),
        ),
      ),
    ),
  );
}
