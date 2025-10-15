import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/account_field.dart';

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

            // Password content
            if (password.isNotEmpty)
              _buildPasswordRow(password)
            else
              Text(
                'No password set',
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

  Widget _buildPasswordRow(String password) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon
          Icon(Icons.lock_outline, size: 16, color: colorScheme.secondary),
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
              _copyToClipboard();
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
