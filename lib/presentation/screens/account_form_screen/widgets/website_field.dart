import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/account_field.dart';

class WebsiteField extends StatefulWidget {
  final AccountField field;
  final void Function(AccountField field) onChange;
  final VoidCallback onRemove;
  final BorderRadius? borderRadius;

  const WebsiteField({
    super.key,
    required this.field,
    required this.onChange,
    required this.onRemove,
    this.borderRadius,
  });

  @override
  State<WebsiteField> createState() => _WebsiteFieldState();
}

class _WebsiteFieldState extends State<WebsiteField> {
  late TextEditingController _valueController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.field.getMetadata('value'),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.field.setMetadataMap({'value': _valueController.text});

      widget.onChange(widget.field);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(0),
      shape: widget.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: widget.borderRadius!)
          : null,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, label, and delete action
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.language,
                      color: Colors.purple.shade700,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.field.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Website field
              Text(
                'Website URL',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'Enter website URL',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (_) => _onFieldChanged(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
