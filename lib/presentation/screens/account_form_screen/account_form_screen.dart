import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business/providers/account_form_provider.dart';
import '../../../data/models/account.dart';
import '../../../data/models/account_field.dart';
import '../../../data/repositories/account_repository.dart';
import '../../widgets/account_logo.dart';
import 'widgets/add_field_dialog.dart';
import 'widgets/grouped_fields_form.dart';
import 'widgets/logo_picker_dialog.dart';

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

  String? _getWebsiteUrl(AccountFormProvider provider) {
    // Look for website field in current fields
    for (final field in provider.fields) {
      if (field.type == AccountFieldType.website) {
        final url = field.getMetadata('value');
        if (url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  void _showLogoPickerDialog(
    BuildContext context,
    AccountFormProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => LogoPickerDialog(
        account: provider.account,
        websiteUrl: _getWebsiteUrl(provider),
        formProvider: provider, // Pass the provider to access cached favicons
        onLogoSelected: (logoType, logoData) {
          // Defer the provider update to avoid setState during build
          Future.microtask(() {
            provider.updateAccountLogo(logoType, logoData);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreateMode ? 'Create Account' : 'Edit Account'),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Consumer<AccountFormProvider>(
            builder: (context, provider, child) {
              // Validate current form state
              final validation = provider.validateForm();
              final hasErrors = !validation.isValid;
              final canSave = provider.canSave && !hasErrors;

              return Tooltip(
                message: provider.isSaving
                    ? 'Saving...'
                    : hasErrors
                    ? 'Please fix validation errors before saving'
                    : 'Save changes',
                child: TextButton(
                  onPressed: (provider.isSaving || !canSave)
                      ? null
                      : () async {
                          try {
                            await provider.saveChanges();
                            if (provider.state == AccountFormState.loaded) {
                              Navigator.pop(
                                context,
                                true,
                              ); // Return true to indicate changes were saved
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save changes: $e'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.all(16),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        },
                  child: provider.isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : provider.isLoadingFavicon
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading...'),
                          ],
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !canSave
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.38)
                                : null,
                          ),
                        ),
                ),
              );
            },
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

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80), // Bottom padding for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show validation errors if any
              Consumer<AccountFormProvider>(
                builder: (context, validationProvider, child) {
                  if (validationProvider.hasError &&
                      validationProvider.errorMessage != null) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Validation Errors',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                validationProvider.errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),

              // Account name section
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account name field
                    Card(
                      margin: EdgeInsets.all(0),
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Consumer<AccountFormProvider>(
                                    builder: (context, provider, child) {
                                      return AccountLogoSelector(
                                        account: provider.account,
                                        websiteUrl: _getWebsiteUrl(provider),
                                        size: 60,
                                        onTap: () => _showLogoPickerDialog(
                                          context,
                                          provider,
                                        ),
                                      );
                                    },
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
                                        Consumer<AccountFormProvider>(
                                          builder: (context, provider, child) {
                                            final hasError =
                                                provider
                                                    .getAccountValidationError(
                                                      'name',
                                                    ) !=
                                                null;
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextField(
                                                  controller: _nameController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Enter account name',
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    isDense: true,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: hasError
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .error
                                                            : null,
                                                      ),
                                                  onChanged: (value) {
                                                    _debounceUpdateAccount(
                                                      value,
                                                      provider,
                                                    );
                                                  },
                                                ),
                                                if (hasError) ...[
                                                  SizedBox(height: 4),
                                                  Text(
                                                    provider
                                                        .getAccountValidationError(
                                                          'name',
                                                        )!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ],
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
                  ],
                ),
              ),

              // Fields list section
              Consumer<AccountFormProvider>(
                builder: (context, provider, child) {
                  if (provider.fields.isEmpty) {
                    return SizedBox.shrink(); // Don't show anything if no fields
                  }
                  return _FieldsList(fields: provider.fields);
                },
              ),

              // Additional Information section
              Padding(
                padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 0,
                        right: 0,
                        top: 24,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Information",
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.all(0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.note_outlined,
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
                                            _debounceUpdateNote(
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
                  ],
                ),
              ),
            ],
          ),
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

    return GroupedFieldsFormView(
      fields: fields,
      formProvider: provider,
      onDeleteField: (field) => _confirmDeleteField(context, field),
    );
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
