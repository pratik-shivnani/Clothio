import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings.g.dart';

const _kBackendUrl = 'backend_url';
const _kDefaultBackendUrl = 'http://localhost:8000';

@riverpod
class BackendUrl extends _$BackendUrl {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBackendUrl) ?? _kDefaultBackendUrl;
  }

  Future<void> setUrl(String url) async {
    // Normalize: remove trailing slash
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackendUrl, normalized);
    state = AsyncData(normalized);
  }
}
