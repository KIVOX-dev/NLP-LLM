import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Pronunciation guide + a placeholder button for audio playback (spec §7,
/// §21, §46: text-to-speech is a future extension point, not implemented
/// on-device here).
class PronunciationCard extends StatelessWidget {
  const PronunciationCard({required this.pronunciation, this.onPlayPressed, super.key});

  final PronunciationResult pronunciation;
  final VoidCallback? onPlayPressed;

  @override
  Widget build(BuildContext context) {
    if (pronunciation.guide == null || pronunciation.guide!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pronunciation', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              iconSize: 18,
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'Play pronunciation (coming soon)',
              onPressed: onPlayPressed,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                pronunciation.guide!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
