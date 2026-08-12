import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The bottom composer bar (spec §7): text field + voice-input placeholder
/// + send. Handles Enter-to-send on desktop/web while keeping Shift+Enter
/// (or plain Enter on mobile soft keyboards) for newlines.
class SanskritInput extends StatefulWidget {
  const SanskritInput({
    required this.onSubmit,
    this.enabled = true,
    this.hintText = 'Ask Sanskrit…',
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final bool enabled;
  final String hintText;

  @override
  State<SanskritInput> createState() => _SanskritInputState();
}

class _SanskritInputState extends State<SanskritInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSubmit(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            tooltip: 'Voice input (coming soon)',
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Upload text (coming soon)',
            onPressed: null,
          ),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (event) {
                final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
                final isShiftHeld = HardwareKeyboard.instance.isShiftPressed;
                if (event is KeyDownEvent && isEnter && !isShiftHeld) {
                  _submit();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                ),
              ),
            ),
          ),
          IconButton.filled(
            icon: const Icon(Icons.arrow_upward_rounded),
            tooltip: 'Send',
            onPressed: widget.enabled ? _submit : null,
          ),
        ],
      ),
    );
  }
}
