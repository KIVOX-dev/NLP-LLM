import 'package:dio/dio.dart';
import 'package:shared_models/shared_models.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

/// Thrown for any failed API call; the UI only ever needs the message and
/// (optionally) the error code, never Dio/HTTP internals.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.requestId});

  final String message;
  final String? code;
  final String? requestId;

  @override
  String toString() => message;
}

/// The Flutter app's only path to the backend (spec §3: "The LLM must never
/// be called directly from the Flutter application" — more generally, this
/// is the only network boundary the app has at all; no direct MongoDB or
/// LLM provider access ever happens on-device).
class ApiClient {
  ApiClient({Dio? dio, SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.apiTimeout,
                receiveTimeout: AppConfig.apiTimeout,
                sendTimeout: AppConfig.apiTimeout,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;

  Future<TranslationResponse> translate(TranslationRequest request) async {
    final json = await _post('/translate', request.toJson());
    return TranslationResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> chat(TranslationRequest request) => _post('/chat', request.toJson());

  Future<List<Map<String, dynamic>>> searchDictionary(String query, {int limit = 20}) async {
    final json = await _post('/dictionary/search', {'query': query, 'limit': limit});
    return List<Map<String, dynamic>>.from(json['results'] as List);
  }

  Future<Map<String, dynamic>> getDictionaryEntry(String word) => _get('/dictionary/${Uri.encodeComponent(word)}');

  Future<Map<String, dynamic>> analyzeSandhi(String text) => _post('/sandhi', {'text': text});

  Future<Map<String, dynamic>> getPronunciation(String text) => _post('/pronunciation', {'text': text});

  Future<List<Conversation>> listConversations() async {
    final json = await _get('/conversations');
    return (json['conversations'] as List<dynamic>)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitFeedback(TranslationFeedback feedback) => _post('/feedback', feedback.toJson());

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? {};
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return response.data ?? {};
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map) {
      final error = ApiErrorResponse.fromJson(data);
      return ApiException(error.message, code: error.code, requestId: error.requestId);
    }
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return ApiException('The request timed out. Please try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException('Could not reach the server. Check your connection.');
    }
    return ApiException('Something went wrong. Please try again.');
  }
}
