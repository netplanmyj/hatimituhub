import 'package:flutter/material.dart';

class QuantityInput extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const QuantityInput({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity.toString() != _controller.text) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trimmedText = _controller.text.trim();
    final quantityStr = widget.quantity.toString();
    if (!_focusNode.hasFocus && quantityStr != trimmedText) {
      _controller.text = quantityStr;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              if (widget.quantity > 1) widget.onChanged(widget.quantity - 1);
            },
          ),
          SizedBox(
            width: 40,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final num = int.tryParse(val) ?? 1;
                widget.onChanged(num < 1 ? 1 : num);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              widget.onChanged(widget.quantity + 1);
            },
          ),
        ],
      ),
    );
  }
}
