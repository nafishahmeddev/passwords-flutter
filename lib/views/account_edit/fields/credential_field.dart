import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/account_field.dart';

class CredentialField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;

  const CredentialField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<CredentialField> createState() => _CredentialFieldState();
}

class _CredentialFieldState extends State<CredentialField> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.field.getMetadata('username'),
    );
    _passwordController = TextEditingController(
      text: widget.field.getMetadata('password'),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.field.setMetadataMap({
        'username': _usernameController.text,
        'password': _passwordController.text,
      });

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
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username or email',
              ),
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
              ),
              obscureText: true,
              onChanged: (_) => _onFieldChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
