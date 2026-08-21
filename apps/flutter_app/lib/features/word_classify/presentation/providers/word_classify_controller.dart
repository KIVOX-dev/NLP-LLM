import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';

enum WordClassifyStatus { idle, loading, loaded, error }

class WordClassifyState {
  const WordClassifyState({
    this.status = WordClassifyStatus.idle,
    this.result,
    this.errorMessage,
  });

  final WordClassifyStatus status;
  final WordClassificationResponse? result;
  final String? errorMessage;

  WordClassifyState copyWith({
    WordClassifyStatus? status,
    WordClassificationResponse? result,
    String? errorMessage,
  }) =>
      WordClassifyState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage,
      );
}

/// Drives the word-classify screen: sends one Sanskrit word to
/// `POST /word-classify` and renders its category + example sentence.
class WordClassifyController extends StateNotifier<WordClassifyState> {
  WordClassifyController(this._apiClient) : super(const WordClassifyState());

  final ApiClient _apiClient;

  Future<void> classify(String word) async {
    final trimmed = word.trim();
    final errors = WordClassificationRequest(word: trimmed).validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(status: WordClassifyStatus.error, errorMessage: errors.join('; '));
      return;
    }

    state = state.copyWith(status: WordClassifyStatus.loading);
    try {
      final result = await _apiClient.classifyWord(trimmed);
      state = state.copyWith(status: WordClassifyStatus.loaded, result: result);
    } on ApiException catch (e) {
      state = state.copyWith(status: WordClassifyStatus.error, errorMessage: e.message);
    }
  }

  void clear() => state = const WordClassifyState();
}

final wordClassifyControllerProvider =
    StateNotifierProvider<WordClassifyController, WordClassifyState>((ref) {
  return WordClassifyController(ref.watch(apiClientProvider));
});
