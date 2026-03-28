import 'package:flutter/material.dart';

import '../../../core/constants/app_borders.dart';

/// Text field and send button for the chat thread.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.hint = 'Message',
    this.enabled = true,
    this.disabledHint,
  });

  final void Function(String text) onSend;
  final String hint;
  final bool enabled;
  final String? disabledHint;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: !widget.enabled,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: widget.enabled ? widget.hint : (widget.disabledHint ?? widget.hint),
                      counterText: '',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                      borderRadius: AppBorders.borderRadius,
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppBorders.borderRadius,
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppBorders.borderRadius,
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: !widget.enabled ? (widget.disabledHint ?? 'Connecting...') : '',
                child: Material(
                  color: widget.enabled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  borderRadius: AppBorders.borderRadius,
                  elevation: 0,
                  child: InkWell(
                    onTap: _submit,
                  borderRadius: AppBorders.borderRadius,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        size: 24,
                        color: widget.enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
