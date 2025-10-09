import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/account_field.dart';

class PasswordField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;

  const PasswordField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.field.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Delete field',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password or email',
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
