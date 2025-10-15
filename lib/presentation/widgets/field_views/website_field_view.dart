import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/account_field.dart';

class WebsiteFieldView extends StatefulWidget {
  final AccountField field;
  final BorderRadius? borderRadius;

  const WebsiteFieldView({super.key, required this.field, this.borderRadius});

  @override
  State<WebsiteFieldView> createState() => _WebsiteFieldViewState();
}

class _WebsiteFieldViewState extends State<WebsiteFieldView> {
  void _copyToClipboard() {
    final url = widget.field.getMetadata("value");
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied to clipboard'),
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
    final url = field.getMetadata("value");

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      shape: widget.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: widget.borderRadius!)
          : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field label - simple clean design with larger font
            Text(field.label, style: theme.textTheme.titleSmall),
            SizedBox(height: 8),

            // URL content
            if (url.isNotEmpty)
              _buildUrlRow(url)
            else
              Text(
                'No URL set',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                  fontSize: 16, // Increased font size
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlRow(String url) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon
          Icon(Icons.language, size: 16, color: colorScheme.primary),
          SizedBox(width: 12),

          // URL value (with link styling)
          Expanded(
            child: Text(
              url,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Open URL button
          IconButton(
            onPressed: () {
              // Open URL functionality would go here
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.open_in_new, size: 18),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(),
          ),

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
