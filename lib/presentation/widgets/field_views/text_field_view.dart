import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class TextFieldView extends StatefulWidget {
  final AccountField field;
  const TextFieldView({super.key, required this.field});

  @override
  State<TextFieldView> createState() => _TextFieldViewState();
}

class _TextFieldViewState extends State<TextFieldView> {
  void _copyToClipboard() {
    final value = widget.field.getMetadata("value");
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text copied to clipboard'),
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
    final value = field.getMetadata("value");

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
                  Icon(Icons.text_fields, color: colorScheme.primary, size: 20),
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

              // Text content
              if (value.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.bodyLarge,
                        maxLines: null, // Allow multiple lines for long text
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
                  'No text set',
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
