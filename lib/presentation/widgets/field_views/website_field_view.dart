import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class WebsiteFieldView extends StatefulWidget {
  final AccountField field;
  const WebsiteFieldView({super.key, required this.field});

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
                  Icon(Icons.language, color: colorScheme.primary, size: 20),
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

              // URL content
              if (url.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                        maxLines: null,
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
              ] else ...[
                Text(
                  'No URL set',
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
