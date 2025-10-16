import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/account_field.dart';

class PasswordFieldView extends StatefulWidget {
  final AccountField field;
  final BorderRadius? borderRadius;

  const PasswordFieldView({super.key, required this.field, this.borderRadius});

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
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Password copied'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final password = field.getMetadata("value");

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with icon
          Row(
            children: [
              Icon(
                Icons.password_rounded,
                size: 20,
                color: colorScheme.secondary,
              ),
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

          // Password content
          if (password.isNotEmpty)
            _buildPasswordRow(password)
          else
            Text(
              'No password set',
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

  Widget _buildPasswordRow(String password) {
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
          // Password text
          Expanded(
            child: Text(
              _isPasswordVisible ? password : '••••••••',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: _isPasswordVisible ? null : 'monospace',
                letterSpacing: _isPasswordVisible ? null : 2.0,
                fontSize: 15,
              ),
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
              _copyToClipboard();
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
