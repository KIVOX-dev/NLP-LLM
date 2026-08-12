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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
