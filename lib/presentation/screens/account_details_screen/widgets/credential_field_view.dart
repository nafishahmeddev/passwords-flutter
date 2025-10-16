import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/account_field.dart';

class CredentialFieldView extends StatefulWidget {
  final AccountField field;
  final BorderRadius borderRadius;

  const CredentialFieldView({
    super.key,
    required this.field,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

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

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with icon
          Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: colorScheme.secondary),
              SizedBox(width: 12),
              Text(
                field.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Username field if available
          if (username.isNotEmpty) ...[
            _buildSimpleField(
              context,
              value: username,
              onCopy: () => _copyToClipboard(username, 'Username'),
              iconData: Icons.person_outline,
            ),
            SizedBox(height: 12),
          ],

          // Password field if available
          if (password.isNotEmpty)
            _buildPasswordField(context, password: password),

          // Empty state
          if (username.isEmpty && password.isEmpty)
            Text(
              'No credentials set',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
        ],
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Copy button
          IconButton(
            onPressed: () {
              onCopy();
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.copy_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
              minimumSize: Size(36, 36),
            ),
            tooltip: "Copy to clipboard",
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, {required String password}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Visibility toggle button
          IconButton(
            onPressed: _togglePasswordVisibility,
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
              minimumSize: Size(36, 36),
            ),
            tooltip: _isPasswordVisible ? "Hide password" : "Show password",
          ),
          SizedBox(width: 8),

          // Copy button
          IconButton(
            onPressed: () {
              _copyToClipboard(password, 'Password');
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.copy_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
              minimumSize: Size(36, 36),
            ),
            tooltip: "Copy to clipboard",
          ),
        ],
      ),
    );
  }
}
