import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import 'confidence_badge.dart';
import 'feedback_buttons.dart';
import 'grammar_card.dart';
import 'pronunciation_card.dart';
import 'word_analysis_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders one full translation result: Sanskrit / IAST / English / Tamil /
/// word analysis / grammar / pronunciation / confidence (spec §9), plus the
/// action row (copy/share/regenerate/save/thumbs).
class TranslationCard extends ConsumerWidget {
  const TranslationCard({
    required this.response,
    this.onRegenerate,
    super.key,
  });

  final TranslationResponse response;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Sanskrit', style: textTheme.titleMedium)),
                if (response.confidence != null) ConfidenceBadge(confidence: response.confidence!),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(response.source.original, style: const TextStyle(fontSize: 18)),
            if (response.source.iast != null && response.source.iast!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('IAST', style: textTheme.bodySmall),
              SelectableText(
                response.source.iast!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const Divider(height: 28),
            if (response.translations['en'] != null) ...[
              Text('English', style: textTheme.titleMedium),
              const SizedBox(height: 6),
              SelectableText(response.translations['en']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
            if (response.translations['ta'] != null) ...[
              Text('Tamil', style: textTheme.titleMedium),
              const SizedBox(height: 6),
              SelectableText(response.translations['ta']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
            if (response.words.isNotEmpty) ...[
              WordAnalysisCard(words: response.words),
              const SizedBox(height: 16),
            ],
            if (response.grammar != null && !response.grammar!.isEmpty) ...[
              GrammarCard(grammar: response.grammar!),
              const SizedBox(height: 16),
            ],
            if (response.pronunciation != null) ...[
              PronunciationCard(pronunciation: response.pronunciation!),
              const SizedBox(height: 16),
            ],
            if (response.uncertainties.isNotEmpty) ...[
              _UncertaintiesNotice(notes: response.uncertainties),
              const SizedBox(height: 8),
            ],
            FeedbackButtons(
              onCopy: () => _copy(context, response.translations['en'] ?? response.source.original),
              onShare: () {}, // Extension point: share_plus once platform channels are available.
              onRegenerate: onRegenerate,
              onSave: () {}, // Extension point: persisted "saved translations" list.
              onRate: (rating) => _submitFeedback(ref, rating),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _submitFeedback(WidgetRef ref, FeedbackRating rating) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.submitFeedback(
        TranslationFeedback(translationId: response.requestId, rating: rating),
      );
    } on ApiException {
      // Feedback is best-effort; a failure here shouldn't interrupt the user.
    }
  }
}

class _UncertaintiesNotice extends StatelessWidget {
  const _UncertaintiesNotice({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Text(
                'Uncertainties',
                style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final note in notes) Text('• $note', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
