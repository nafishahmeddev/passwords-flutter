import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/account_field.dart';

class CredentialFieldView extends StatefulWidget {
  final AccountField field;

  const CredentialFieldView({super.key, required this.field});

  @override
  State<CredentialFieldView> createState() => _CredentialFieldViewState();
}

class _CredentialFieldViewState extends State<CredentialFieldView> {
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _copyToClipboard(String value, String type) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard'),
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

    final username = field.getMetadata("username");
    final password = field.getMetadata("password");

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
                  Icon(Icons.person, color: colorScheme.primary, size: 20),
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

              // Username section
              if (username.isNotEmpty) ...[
                _buildFieldSection(
                  context,
                  label: 'Username/Email',
                  value: username,
                  onCopy: () => _copyToClipboard(username, 'Username'),
                ),
                SizedBox(height: 12),
              ],

              // Password section
              if (password.isNotEmpty) ...[
                _buildFieldSection(
                  context,
                  label: 'Password',
                  value: _isPasswordVisible ? password : '••••••••',
                  onCopy: () => _copyToClipboard(password, 'Password'),
                  isPassword: true,
                  onToggleVisibility: _togglePasswordVisibility,
                ),
              ],

              // Empty state
              if (username.isEmpty && password.isEmpty) ...[
                Text(
                  'No credentials set',
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

  Widget _buildFieldSection(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPassword && onToggleVisibility != null) ...[
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            IconButton(
              onPressed: onCopy,
              icon: Icon(Icons.copy, size: 18),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
