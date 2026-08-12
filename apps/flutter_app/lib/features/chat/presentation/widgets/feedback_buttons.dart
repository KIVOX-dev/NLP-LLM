import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class FeedbackButtons extends StatefulWidget {
  const FeedbackButtons({
    required this.onRate,
    this.onCopy,
    this.onShare,
    this.onRegenerate,
    this.onSave,
    super.key,
  });

  final ValueChanged<FeedbackRating> onRate;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSave;

  @override
  State<FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<FeedbackButtons> {
  FeedbackRating? _selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        if (widget.onCopy != null)
          IconButton(icon: const Icon(Icons.copy_outlined, size: 18), tooltip: 'Copy', onPressed: widget.onCopy),
        if (widget.onShare != null)
          IconButton(icon: const Icon(Icons.share_outlined, size: 18), tooltip: 'Share', onPressed: widget.onShare),
        if (widget.onRegenerate != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'Regenerate',
            onPressed: widget.onRegenerate,
          ),
        if (widget.onSave != null)
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, size: 18),
            tooltip: 'Save translation',
            onPressed: widget.onSave,
          ),
        IconButton(
          icon: Icon(
            _selected == FeedbackRating.up ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            size: 18,
          ),
          tooltip: 'Good translation',
          onPressed: () {
            setState(() => _selected = FeedbackRating.up);
            widget.onRate(FeedbackRating.up);
          },
        ),
        IconButton(
          icon: Icon(
            _selected == FeedbackRating.down ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
            size: 18,
          ),
          tooltip: 'Poor translation',
          onPressed: () {
            setState(() => _selected = FeedbackRating.down);
            widget.onRate(FeedbackRating.down);
          },
        ),
      ],
    );
  }
}
