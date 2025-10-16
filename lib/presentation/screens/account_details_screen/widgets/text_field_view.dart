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
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Text copied'),
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
    final value = field.getMetadata("value");

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with icon
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: colorScheme.secondary),
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

          // Text content
          if (value.isNotEmpty)
            _buildTextRow(value)
          else
            Text(
              'No text set',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String value) {
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
          // Text value
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),

          // Copy button with modern styling
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
