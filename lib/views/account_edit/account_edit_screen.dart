import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/account_edit_cubit.dart';
import '../../models/account.dart';
import '../../models/account_field.dart';
import '../../repositories/account_repository.dart';
import 'add_field_dialog.dart';
import 'field_widget_builder.dart';

class AccountEditScreen extends StatelessWidget {
  final AccountRepository repository;
  final int? accountId; // Made nullable for create mode
  final bool isCreateMode;

  const AccountEditScreen({
    super.key,
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountEditCubit(
        repository: repository,
        accountId: accountId,
        isCreateMode: isCreateMode,
      )..loadFields(),
      child: _AccountEditBody(
        repository: repository,
        accountId: accountId,
        isCreateMode: isCreateMode,
      ),
    );
  }
}

class _AccountEditBody extends StatefulWidget {
  final AccountRepository repository;
  final int? accountId;
  final bool isCreateMode;

  const _AccountEditBody({
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
  });

  @override
  _AccountEditBodyState createState() => _AccountEditBodyState();
}

class _AccountEditBodyState extends State<_AccountEditBody> {
  TextEditingController? _nameController;
  TextEditingController? _descriptionController;
  TextEditingController? _noteController;

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized when state is loaded
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _descriptionController?.dispose();
    _noteController?.dispose();
    super.dispose();
  }

  void _initializeControllers(Account account) {
    _nameController = TextEditingController(text: account.name);
    _descriptionController = TextEditingController(
      text: account.description ?? '',
    );
    _noteController = TextEditingController(text: account.note ?? '');
  }

  void _updateControllers(Account account) {
    if (_nameController != null) {
      _nameController!.text = account.name;
      _descriptionController!.text = account.description ?? '';
      _noteController!.text = account.note ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreateMode ? 'Create Account' : 'Edit Account'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              try {
                await context.read<AccountEditCubit>().saveChanges();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save changes: $e')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFieldDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Add New Field',
      ),
      body: BlocBuilder<AccountEditCubit, AccountEditState>(
        builder: (context, state) {
          if (state is AccountEditLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is AccountEditLoaded) {
            // Initialize controllers if not already done
            if (_nameController == null) {
              _initializeControllers(state.account);
            } else {
              // Update controllers if account data changed
              _updateControllers(state.account);
            }

            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Account editing section
                Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Details',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Account Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_circle),
                          ),
                          onChanged: (value) {
                            final updatedAccount = state.account.copyWith(
                              name: value,
                            );
                            context.read<AccountEditCubit>().updateAccount(
                              updatedAccount,
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            final updatedAccount = state.account.copyWith(
                              description: value.isEmpty ? null : value,
                            );
                            context.read<AccountEditCubit>().updateAccount(
                              updatedAccount,
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: 'Note (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            final updatedAccount = state.account.copyWith(
                              note: value.isEmpty ? null : value,
                            );
                            context.read<AccountEditCubit>().updateAccount(
                              updatedAccount,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Fields section header
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Fields',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Fields list or empty message
                if (state.fields.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No fields yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first field',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...state.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: FieldWidgetBuilder.buildFieldWidget(
                        context,
                        field,
                        context.read<AccountEditCubit>(),
                        () => _confirmDeleteField(context, field),
                      ),
                    );
                  }).toList(),
              ],
            );
          } else if (state is AccountEditSaving) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving changes...'),
                ],
              ),
            );
          } else if (state is AccountEditError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AccountEditCubit>().loadFields(),
                    child: Text('Retry'),
                  ),
                ],
              ),
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
          formCubit: context.read<AccountEditCubit>(),
          // accountId will be determined from cubit state
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
      // Remove the field from form state (will be persisted when saved)
      context.read<AccountEditCubit>().removeField(field.id!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Field "${field.label}" removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing field: $e')));
    }
  }
}
