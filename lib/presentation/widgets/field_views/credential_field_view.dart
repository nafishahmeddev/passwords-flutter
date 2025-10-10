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
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and label
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        field.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Username section
                if (username.isNotEmpty) ...[
                  _buildFieldSection(
                    context,
                    label: 'Username/Email',
                    value: username,
                    onCopy: () => _copyToClipboard(username, 'Username'),
                    icon: Icons.account_circle_outlined,
                  ),
                  SizedBox(height: 16),
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
                    icon: Icons.lock_outline,
                  ),
                ],

                // Empty state
                if (username.isEmpty && password.isEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No credentials set',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    letterSpacing: isPassword && !_isPasswordVisible
                        ? 1.5
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPassword && onToggleVisibility != null) ...[
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onToggleVisibility,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
              ],
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    onCopy();
                    // Add haptic feedback
                    HapticFeedback.lightImpact();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
