import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';


class MapTileConfig {
  MapTileConfig._();

  static const String positron =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  static const String positronNoLabels =
      'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

  static const String darkMatter =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const List<String> subdomains = ['a', 'b', 'c', 'd'];

  static const String attribution =
      '© OpenStreetMap contributors © CARTO';

  static TileLayer tileLayer({
    String? urlTemplate,
    double tileOpacity = 1.0,
  }) {
    return TileLayer(
      urlTemplate: urlTemplate ?? positron,
      subdomains: subdomains,
      userAgentPackageName: 'com.wakemap.wakeMap',
      retinaMode: true,
      maxZoom: 20,
      tileBuilder: tileOpacity < 1.0
          ? (context, tileWidget, tile) => Opacity(
                opacity: tileOpacity,
                child: tileWidget,
              )
          : null,
    );
  }

  static RichAttributionWidget attributionWidget() {
    return const RichAttributionWidget(
      popupInitialDisplayDuration: Duration.zero,
      attributions: [
        TextSourceAttribution('OpenStreetMap contributors'),
        TextSourceAttribution('CARTO'),
      ],
    );
  }
}
