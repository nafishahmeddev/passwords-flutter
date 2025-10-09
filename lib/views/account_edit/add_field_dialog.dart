import 'package:flutter/material.dart';
import '../../models/account_field.dart';
import '../../repositories/account_repository.dart';

class AddFieldDialog extends StatefulWidget {
  final AccountRepository repository;
  final int accountId;
  final VoidCallback onFieldAdded;

  const AddFieldDialog({
    Key? key,
    required this.repository,
    required this.accountId,
    required this.onFieldAdded,
  }) : super(key: key);

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
              value: _selectedType,
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
      // Get the current highest order to append the new field at the end
      final existingFields = await widget.repository.getFields(
        widget.accountId,
      );
      final maxOrder = existingFields.isEmpty
          ? 0
          : existingFields.map((f) => f.order).reduce((a, b) => a > b ? a : b);

      final newField = AccountField(
        accountId: widget.accountId,
        label: _labelController.text.trim(),
        type: AccountFieldType.fromString(_selectedType),
        requiredField: _isRequired,
        order: maxOrder + 1,
      );

      await widget.repository.insertField(newField);
      widget.onFieldAdded();
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
