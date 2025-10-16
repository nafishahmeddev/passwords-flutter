import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/account_field.dart';

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

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label - simple clean design with larger font
          Text(
            field.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),

          // URL content
          if (url.isNotEmpty)
            _buildUrlRow(url)
          else
            Text(
              'No URL set',
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

  Widget _buildUrlRow(String url) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(78),
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                fontSize: 15,
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
            icon: Icon(Icons.open_in_new_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,

              minimumSize: Size(36, 36),
            ),
            tooltip: "Open URL",
            visualDensity: VisualDensity(horizontal: -4.0, vertical: 0),
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
              minimumSize: Size(36, 36),
            ),
            tooltip: "Copy to clipboard",
            visualDensity: VisualDensity(horizontal: -4.0, vertical: 0),
          ),
        ],
      ),
    );
  }
}
