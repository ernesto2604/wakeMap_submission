import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _fallbackProductionApiBaseUrl =
      'https://lastversionwakemap.onrender.com';

  static String get apiBaseUrl {
    final configured = _definedApiBaseUrl.trim();
    if (configured.isNotEmpty) return configured;

    if (!kDebugMode) return _fallbackProductionApiBaseUrl;

    if (kIsWeb) return 'http://localhost:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080';
    }
  }
}
