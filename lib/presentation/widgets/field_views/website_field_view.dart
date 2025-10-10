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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language,
                        color: Colors.purple.shade700,
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

                // URL content
                if (url.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.link,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            url,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.purple.shade700,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.purple.shade700,
                            ),
                            maxLines: null,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _copyToClipboard();
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
                  ),
                ] else ...[
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
                          'No URL set',
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
}
