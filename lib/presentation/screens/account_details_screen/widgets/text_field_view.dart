import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passwords/data/models/account_field.dart';

class TextFieldView extends StatefulWidget {
  final AccountField field;
  final BorderRadius? borderRadius;
  const TextFieldView({super.key, required this.field, this.borderRadius});

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

            // Text content
            if (value.isNotEmpty)
              _buildTextRow(value)
            else
              Text(
                'No text set',
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

  Widget _buildTextRow(String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon
          Icon(
            Icons.text_fields,
            size: 20, // Increased icon size
            color: colorScheme.primary,
          ),
          SizedBox(width: 12),

          // Text value
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16, // Increased font size
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
