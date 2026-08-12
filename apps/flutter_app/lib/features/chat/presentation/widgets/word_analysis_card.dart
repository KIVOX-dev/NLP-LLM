import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/theme/app_colors.dart';

/// Word-by-word breakdown shown under a translation (spec §9). Tapping a
/// word is the extension point for the dictionary popup (spec §7).
class WordAnalysisCard extends StatelessWidget {
  const WordAnalysisCard({required this.words, this.onWordTap, super.key});

  final List<WordAnalysis> words;
  final ValueChanged<WordAnalysis>? onWordTap;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final border = Theme.of(context).dividerColor;

    return _Section(
      title: 'Word Analysis',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final word in words)
            InkWell(
              onTap: onWordTap == null ? null : () => onWordTap!(word),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minWidth: 96),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(word.surface, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (word.iast.isNotEmpty)
                      Text(word.iast, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.accent)),
                    if (word.englishMeaning != null)
                      Text(word.englishMeaning!, style: Theme.of(context).textTheme.bodySmall),
                    if (word.tamilMeaning != null)
                      Text(word.tamilMeaning!, style: Theme.of(context).textTheme.bodySmall),
                    if (word.morphology != null && word.morphology!.partOfSpeech != PartOfSpeech.unknown)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          partOfSpeechToString(word.morphology!.partOfSpeech).replaceAll('_', ' '),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 10, letterSpacing: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
