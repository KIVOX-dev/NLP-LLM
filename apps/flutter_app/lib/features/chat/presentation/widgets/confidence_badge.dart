import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/theme/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({required this.confidence, super.key});

  final Confidence confidence;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (confidence.level) {
      ConfidenceLevel.high => (AppColors.confidenceHigh, 'High confidence'),
      ConfidenceLevel.medium => (AppColors.confidenceMedium, 'Medium confidence'),
      ConfidenceLevel.low => (AppColors.confidenceLow, 'Low confidence'),
    };

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ],
      ),
    );

    if (confidence.notes.isEmpty) return badge;

    return Tooltip(
      message: confidence.notes.join('\n'),
      child: badge,
    );
  }
}
