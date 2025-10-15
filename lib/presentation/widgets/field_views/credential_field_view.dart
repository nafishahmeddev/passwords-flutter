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

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field label - simple clean design with larger font
            Text(field.label, style: theme.textTheme.titleSmall),
            SizedBox(height: 8),

            // Username field if available
            if (username.isNotEmpty) ...[
              _buildSimpleField(
                context,
                value: username,
                onCopy: () => _copyToClipboard(username, 'Username'),
                iconData: Icons.person_outline,
              ),
            ],

            // Password field if available
            if (password.isNotEmpty)
              _buildPasswordField(context, password: password),

            // Empty state
            if (username.isEmpty && password.isEmpty)
              Text(
                'No credentials set',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 16, // Increased font size
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleField(
    BuildContext context, {
    required String value,
    required VoidCallback onCopy,
    required IconData iconData,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon
          Icon(iconData, size: 16, color: colorScheme.primary),
          SizedBox(width: 12),

          // Value text
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Copy button
          IconButton(
            onPressed: () {
              onCopy();
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.copy_outlined, size: 18),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, {required String password}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon
          Icon(Icons.lock_outline, size: 16, color: colorScheme.primary),
          SizedBox(width: 12),

          // Password text
          Expanded(
            child: Text(
              _isPasswordVisible ? password : '••••••••',
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Visibility toggle button
          IconButton(
            onPressed: _togglePasswordVisibility,
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
            ),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(),
          ),
          SizedBox(width: 8),

          // Copy button
          IconButton(
            onPressed: () {
              _copyToClipboard(password, 'Password');
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.copy_outlined, size: 18),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
