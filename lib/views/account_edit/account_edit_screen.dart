import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/account_field_cubit.dart';
import '../../models/account_field.dart';
import '../../repositories/account_repository.dart';
import 'add_field_dialog.dart';
import 'field_widget_builder.dart';

class AccountEditScreen extends StatelessWidget {
  final AccountRepository repository;
  final int accountId;

  const AccountEditScreen({
    super.key,
    required this.repository,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AccountFieldCubit(repository: repository, accountId: accountId)
            ..loadFields(),
      child: _AccountEditBody(repository: repository, accountId: accountId),
    );
  }
}

class _AccountEditBody extends StatefulWidget {
  final AccountRepository repository;
  final int accountId;

  const _AccountEditBody({required this.repository, required this.accountId});

  @override
  _AccountEditBodyState createState() => _AccountEditBodyState();
}

class _AccountEditBodyState extends State<_AccountEditBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Account'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              // Save all fields - metadata is automatically saved with each field
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFieldDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Add New Field',
      ),
      body: BlocBuilder<AccountFieldCubit, AccountFieldState>(
        builder: (context, state) {
          if (state is AccountFieldLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is AccountFieldLoaded) {
            if (state.fields.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No fields yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first field',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.all(16),
              children: state.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FieldWidgetBuilder.buildFieldWidget(
                    context,
                    field,
                    widget.repository,
                    () => _confirmDeleteField(context, field),
                  ),
                );
              }).toList(),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddFieldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddFieldDialog(
          repository: widget.repository,
          accountId: widget.accountId,
          onFieldAdded: () {
            context.read<AccountFieldCubit>().loadFields();
          },
        );
      },
    );
  }

  void _confirmDeleteField(BuildContext context, AccountField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Field'),
        content: Text(
          'Are you sure you want to delete "${field.label}"?\n\nThis will permanently remove the field and its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteField(context, field);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteField(BuildContext context, AccountField field) async {
    try {
      // Delete the field from database (metadata is automatically deleted)
      await widget.repository.deleteField(field.id!);

      // Refresh the fields list
      context.read<AccountFieldCubit>().loadFields();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Field "${field.label}" deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting field: $e')));
    }
  }
}
