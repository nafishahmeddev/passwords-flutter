import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/account_form_provider.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import '../widgets/add_field_dialog.dart';
import '../widgets/field_widget_builder.dart';

class AccountFormScreen extends StatelessWidget {
  final AccountRepository repository;
  final String? accountId; // Made nullable for create mode
  final bool isCreateMode;
  final List<AccountField>? templateFields; // Template fields for create mode

  const AccountFormScreen({
    super.key,
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
    this.templateFields,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountFormProvider(
        repository: repository,
        accountId: accountId,
        isCreateMode: isCreateMode,
        templateFields: templateFields,
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
  final String? accountId;
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
  TextEditingController? _noteController;

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized when state is loaded
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _noteController?.dispose();
    super.dispose();
  }

  void _initializeControllers(Account account) {
    _nameController = TextEditingController(text: account.name);
    _noteController = TextEditingController(text: account.note ?? '');
  }

  void _updateControllers(Account account) {
    if (_nameController != null) {
      _nameController!.text = account.name;
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
                await Provider.of<AccountFormProvider>(
                  context,
                  listen: false,
                ).saveChanges();
                Navigator.pop(
                  context,
                  true,
                ); // Return true to indicate changes were saved
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
        tooltip: 'Add New Field',
        child: Icon(Icons.add),
      ),
      body: Consumer<AccountFormProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.state == AccountFormState.loaded) {
            // Initialize controllers if not already done
            if (_nameController == null) {
              _initializeControllers(provider.account!);
            } else {
              // Update controllers if account data changed
              _updateControllers(provider.account!);
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
                            final updatedAccount = provider.account!.copyWith(
                              name: value,
                            );
                            provider.updateAccount(updatedAccount);
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
                            final updatedAccount = provider.account!.copyWith(
                              note: value.isEmpty ? null : value,
                            );
                            provider.updateAccount(updatedAccount);
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
                if (provider.fields.isEmpty)
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
                  ...provider.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Builder(
                        builder: (dialogContext) =>
                            FieldWidgetBuilder.buildFieldWidget(
                              dialogContext,
                              field,
                              Provider.of<AccountFormProvider>(
                                context,
                                listen: false,
                              ),
                              () {
                                _confirmDeleteField(dialogContext, field);
                              },
                            ),
                      ),
                    );
                  }),
              ],
            );
          } else if (provider.isSaving) {
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
          } else if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'An error occurred'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadFields(),
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
          formProvider: Provider.of<AccountFormProvider>(
            context,
            listen: false,
          ),
          // accountId will be determined from provider state
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
              await _deleteField(field);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteField(AccountField field) async {
    try {
      // Remove the field from form state (will be persisted when saved)
      Provider.of<AccountFormProvider>(
        context,
        listen: false,
      ).removeField(field.id);

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
