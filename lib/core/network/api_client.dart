import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl}) : _client = http.Client();

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Uint8List> removeBackground(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/remove-bg'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamedResponse = await request.send();
    return await streamedResponse.stream.toBytes();
  }

  Future<Map<String, dynamic>> classifyClothing(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/classify'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<Uint8List> tryOn({
    required File bodyImage,
    required File clothingImage,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/try-on'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('body', bodyImage.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath('clothing', clothingImage.path),
    );
    final streamedResponse = await request.send();
    return await streamedResponse.stream.toBytes();
  }

  Future<List<Map<String, dynamic>>> getSuggestions({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
    Map<String, dynamic>? weather,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/suggest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'wardrobe': wardrobeItems,
        if (occasion != null) 'occasion': occasion,
        if (weather != null) 'weather': weather,
      }),
    );
    final data = jsonDecode(response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  void dispose() => _client.close();
}

@riverpod
ApiClient apiClient(ApiClientRef ref) {
  final client = ApiClient(baseUrl: 'http://localhost:8000');
  ref.onDispose(() => client.dispose());
  return client;
}
