import 'package:flutter/material.dart';

/// Editable list of chips with add/remove support.
class ChipEditor extends StatefulWidget {
  const ChipEditor({
    super.key,
    required this.values,
    required this.hintText,
    required this.onChanged,
  });

  final List<String> values;
  final String hintText;
  final void Function(List<String>) onChanged;

  @override
  State<ChipEditor> createState() => _ChipEditorState();
}

class _ChipEditorState extends State<ChipEditor> {
  final _controller = TextEditingController();

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    if (widget.values.contains(v)) return;
    widget.onChanged([...widget.values, v]);
    _controller.clear();
  }

  void _remove(String v) {
    widget.onChanged(
      widget.values.where((x) => x != v).toList(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.values.map(
              (v) => Chip(
                label: Text(v),
                onDeleted: () => _remove(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}
