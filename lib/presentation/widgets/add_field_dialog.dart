import 'package:flutter/material.dart';
import '../../data/models/account_field.dart';
import '../../business/providers/account_form_provider.dart';

class AddFieldDialog extends StatefulWidget {
  final AccountFormProvider formProvider;
  final String?
  accountId; // Made optional - will get from provider state if not provided
  final VoidCallback? onFieldAdded;

  const AddFieldDialog({
    super.key,
    required this.formProvider,
    this.accountId,
    this.onFieldAdded,
  });

  @override
  AddFieldDialogState createState() => AddFieldDialogState();
}

class AddFieldDialogState extends State<AddFieldDialog> {
  final _labelController = TextEditingController();
  String _selectedType = 'text';
  bool _isRequired = false;
  bool _isLoading = false;

  final List<Map<String, String>> _fieldTypes = [
    {'value': 'text', 'label': 'Text'},
    {'value': 'credential', 'label': 'Credential'},
    {'value': 'password', 'label': 'Password'},
    {'value': 'website', 'label': 'Website/URL'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Field',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Field label input
              Text(
                'Field Label',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Username, Security Question',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              SizedBox(height: 20),

              // Field type selection
              Text(
                'Field Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 12),
              Column(
                children: _fieldTypes.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type['value']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.3)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFieldTypeIcon(type['value']!),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type['label']!,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    _getFieldTypeDescription(type['value']!),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Required field toggle
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Field',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'This field must be filled',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRequired,
                      onChanged: (value) {
                        setState(() {
                          _isRequired = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _addField,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text('Add Field'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFieldTypeIcon(String type) {
    switch (type) {
      case 'credential':
        return Icons.person;
      case 'password':
        return Icons.lock;
      case 'website':
        return Icons.language;
      default:
        return Icons.text_fields;
    }
  }

  String _getFieldTypeDescription(String type) {
    switch (type) {
      case 'credential':
        return 'Username and password pair';
      case 'password':
        return 'Single password field';
      case 'website':
        return 'Website URL or link';
      default:
        return 'Plain text or note';
    }
  }

  Future<void> _addField() async {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a field label'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current highest order from the form state
      final maxOrder = widget.formProvider.fields.isNotEmpty
          ? widget.formProvider.fields
                .map((f) => f.order)
                .reduce((a, b) => a > b ? a : b)
          : 0;

      // Get accountId from widget parameter or from provider state
      final accountId = widget.accountId ?? widget.formProvider.account!.id;

      final newField = AccountField(
        accountId: accountId,
        label: _labelController.text.trim(),
        type: AccountFieldType.fromString(_selectedType),
        requiredField: _isRequired,
        order: maxOrder + 1,
      );

      widget.formProvider.addField(newField);
      // No need to call onFieldAdded since addField already updates the form state
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Field "${newField.label}" added successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding field: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
