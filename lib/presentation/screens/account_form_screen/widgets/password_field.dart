import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/account_field.dart';
import '../../../../business/providers/account_form_provider.dart';

class PasswordField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;
  final BorderRadius? borderRadius;

  const PasswordField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
    this.borderRadius,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late TextEditingController _valueController;
  Timer? _debounceTimer;
  bool _isPasswordVisible = false;

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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Colors.orange.shade700,
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
                        'value',
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
                          controller: _valueController,
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
                            'value',
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
