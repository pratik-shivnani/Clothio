import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings.g.dart';

const _kBackendUrl = 'backend_url';
const kDefaultBackendUrl = 'http://localhost:8000';

/// Pre-initialized in main.dart before runApp
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

@Riverpod(keepAlive: true)
class BackendUrl extends _$BackendUrl {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_kBackendUrl) ?? kDefaultBackendUrl;
  }

  Future<void> setUrl(String url) async {
    // Normalize: remove trailing slash
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kBackendUrl, normalized);
    ref.invalidateSelf();
  }
}
