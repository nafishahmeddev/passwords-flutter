import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class PasswordFieldView extends StatefulWidget {
  final AccountField field;
  const PasswordFieldView({super.key, required this.field});

  @override
  State<PasswordFieldView> createState() => _PasswordFieldViewState();
}

class _PasswordFieldViewState extends State<PasswordFieldView> {
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _copyToClipboard() {
    final password = widget.field.getMetadata("value");
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final password = field.getMetadata("value");

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and label
              Row(
                children: [
                  Icon(Icons.lock, color: colorScheme.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Password content
              if (password.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isPasswordVisible
                                ? password
                                : '•' * password.length,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              letterSpacing: _isPasswordVisible ? null : 2.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _togglePasswordVisibility,
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon: Icon(Icons.copy, size: 18),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No password set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
