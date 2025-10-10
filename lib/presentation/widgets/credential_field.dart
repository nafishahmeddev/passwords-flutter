import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';

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
  bool _isPasswordVisible = false;

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

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.field.label, style: TextStyle(fontSize: 14)),
            const Spacer(),
            InkWell(onTap: widget.onRemove, child: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username or email',
              border: InputBorder.none,
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              border: InputBorder.none,
              suffix: InkWell(
                onTap: _togglePasswordVisibility,
                child: _isPasswordVisible
                    ? const Icon(Icons.visibility)
                    : const Icon(Icons.visibility_off),
              ),
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
        ),
      ],
    );
  }
}
