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
    return AlertDialog(
      title: Text('Add New Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Field Label',
                hintText: 'e.g., Username, Security Question',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Field Type',
                border: OutlineInputBorder(),
              ),
              items: _fieldTypes.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Required Field'),
              subtitle: Text('This field must be filled'),
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addField,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Add Field'),
        ),
      ],
    );
  }

  Future<void> _addField() async {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a field label')));
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
        SnackBar(content: Text('Field "${newField.label}" added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding field: $e')));
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
