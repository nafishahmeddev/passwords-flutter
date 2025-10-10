import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';

class WebsiteField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;

  const WebsiteField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<WebsiteField> createState() => _WebsiteFieldState();
}

class _WebsiteFieldState extends State<WebsiteField> {
  late TextEditingController _valueController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.field.getMetadata('value'),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.field.setMetadataMap({'value': _valueController.text});

      widget.onChange(widget.field);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: TextFormField(
        controller: _valueController,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'Website',
          hintText: 'Enter website',
          border: InputBorder.none,
          suffix: InkWell(onTap: widget.onRemove, child: Icon(Icons.close)),
        ),
        onChanged: (_) => _onFieldChanged(),
      ),
    );
  }
}
