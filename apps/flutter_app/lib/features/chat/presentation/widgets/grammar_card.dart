import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Expandable "Grammar" panel (spec §7, §9).
class GrammarCard extends StatelessWidget {
  const GrammarCard({required this.grammar, super.key});

  final GrammarAnalysis grammar;

  @override
  Widget build(BuildContext context) {
    if (grammar.isEmpty) return const SizedBox.shrink();

    final rows = <MapEntry<String, String>>[
      if (grammar.subject != null) MapEntry('Subject', grammar.subject!),
      if (grammar.object != null) MapEntry('Object', grammar.object!),
      if (grammar.verb != null) MapEntry('Verb', grammar.verb!),
      if (grammar.tense != null) MapEntry('Tense', grammar.tense!),
      if (grammar.person != null) MapEntry('Person', grammar.person!),
      if (grammar.number != null) MapEntry('Number', grammar.number!),
      if (grammar.voice != null) MapEntry('Voice', grammar.voice!),
      if (grammar.mood != null) MapEntry('Mood', grammar.mood!),
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text('Grammar', style: Theme.of(context).textTheme.titleMedium),
        initiallyExpanded: true,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (final row in rows)
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.key, style: Theme.of(context).textTheme.bodySmall),
                      Text(row.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          if (grammar.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final note in grammar.notes)
              Text('• $note', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
