import 'dart:async';
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

  Timer? _nameDebounceTimer;
  Timer? _noteDebounceTimer;

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized when state is loaded
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _noteController?.dispose();
    _nameDebounceTimer?.cancel();
    _noteDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeControllers(Account account) {
    _nameController = TextEditingController(text: account.name);
    _noteController = TextEditingController(text: account.note ?? '');
  }

  void _debounceUpdateAccount(String value, AccountFormProvider provider) {
    _nameDebounceTimer?.cancel();
    _nameDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final updatedAccount = provider.account!.copyWith(name: value);
      provider.updateAccount(updatedAccount);
    });
  }

  void _debounceUpdateNote(String value, AccountFormProvider provider) {
    _noteDebounceTimer?.cancel();
    _noteDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final updatedAccount = provider.account!.copyWith(
        note: value.isEmpty ? null : value,
      );
      provider.updateAccount(updatedAccount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AccountFormProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreateMode ? 'Create Account' : 'Edit Account'),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await provider.saveChanges();
                Navigator.pop(
                  context,
                  true,
                ); // Return true to indicate changes were saved
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save changes: $e'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFieldDialog(context),
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(Icons.add),
      ),
      body: Consumer<AccountFormProvider>(
        builder: (context, provider, child) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = Provider.of<AccountFormProvider>(context, listen: false);

    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (provider.state == AccountFormState.loaded) {
      // Initialize controllers if not already done
      if (_nameController == null) {
        _initializeControllers(provider.account!);
      }

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account name field
                  Card(
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.account_circle_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Account Name',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      SizedBox(height: 4),
                                      TextField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter account name',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                        onChanged: (value) {
                                          _debounceUpdateAccount(
                                            value,
                                            provider,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Fields section header
                  if (provider.fields.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Fields',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Fields list
          SliverToBoxAdapter(
            child: Consumer<AccountFormProvider>(
              builder: (context, provider, child) =>
                  _FieldsList(fields: provider.fields),
            ),
          ),

          // Additional Information section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'Additional Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.note_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notes',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      SizedBox(height: 4),
                                      TextField(
                                        controller: _noteController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add any additional notes (optional)',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                        maxLines: null,
                                        onChanged: (value) {
                                          _debounceUpdateNote(value, provider);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Add bottom padding for FAB
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
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
}

class _FieldsList extends StatelessWidget {
  final List<AccountField> fields;

  const _FieldsList({required this.fields});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AccountFormProvider>(context, listen: false);

    if (fields.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Card(
          elevation: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No fields yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first field',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: fields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Builder(
                builder: (dialogContext) => FieldWidgetBuilder.buildFieldWidget(
                  dialogContext,
                  field,
                  provider,
                  () {
                    _confirmDeleteField(context, field);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  void _confirmDeleteField(BuildContext context, AccountField field) {
    final provider = Provider.of<AccountFormProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
          size: 28,
        ),
        title: Text(
          'Delete Field',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          'Are you sure you want to delete "${field.label}"?\n\nThis will permanently remove the field and its data.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteField(context, field, provider);
            },
            child: Text('Delete'),
          ),
        ],
        actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _deleteField(
    BuildContext context,
    AccountField field,
    AccountFormProvider provider,
  ) async {
    try {
      // Remove the field from form state (will be persisted when saved)
      provider.removeField(field.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Field "${field.label}" removed'),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing field: $e'),
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
