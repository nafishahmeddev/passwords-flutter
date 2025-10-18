import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/account_field.dart';
import '../../../../business/providers/account_form_provider.dart';

class CredentialField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;
  final BorderRadius? borderRadius;

  const CredentialField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
    this.borderRadius,
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(0),
      shape: widget.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: widget.borderRadius!)
          : null,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, label, and delete action
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withAlpha(180),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.field.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Username field
              Text(
                'Username',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Consumer<AccountFormProvider>(
                builder: (context, provider, child) {
                  final hasError =
                      provider.getFieldValidationError(
                        widget.field.id,
                        'username',
                      ) !=
                      null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: hasError
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Enter username or email',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ),
                      if (hasError) ...[
                        SizedBox(height: 4),
                        Text(
                          provider.getFieldValidationError(
                            widget.field.id,
                            'username',
                          )!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: 16),

              // Password field
              Text(
                'Password',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Consumer<AccountFormProvider>(
                builder: (context, provider, child) {
                  final hasError =
                      provider.getFieldValidationError(
                        widget.field.id,
                        'password',
                      ) !=
                      null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: hasError
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _togglePasswordVisibility,
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ),
                      if (hasError) ...[
                        SizedBox(height: 4),
                        Text(
                          provider.getFieldValidationError(
                            widget.field.id,
                            'password',
                          )!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
