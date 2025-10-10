// lib/presentation/screens/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:passwords/presentation/widgets/field_views/credential_field_view.dart';
import 'package:passwords/presentation/widgets/field_views/password_field_view.dart';
import 'package:passwords/presentation/widgets/field_views/text_field_view.dart';
import 'package:passwords/presentation/widgets/field_views/website_field_view.dart';
import 'package:passwords/presentation/widgets/otp_field_view.dart';
import 'package:provider/provider.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import '../../business/providers/account_detail_provider.dart';
import 'account_form_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;
  final AccountRepository repository;

  const AccountDetailScreen({
    super.key,
    required this.account,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AccountDetailProvider(repository: repository, accountId: account.id)
            ..loadFields(),
      child: _AccountDetailScreenContent(
        account: account,
        repository: repository,
      ),
    );
  }
}

class _AccountDetailScreenContent extends StatefulWidget {
  final Account account;
  final AccountRepository repository;

  const _AccountDetailScreenContent({
    required this.account,
    required this.repository,
  });

  @override
  State<_AccountDetailScreenContent> createState() =>
      _AccountDetailScreenContentState();
}

class _AccountDetailScreenContentState
    extends State<_AccountDetailScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccountDetailProvider>(
      builder: (context, provider, child) {
        final account = provider.account ?? widget.account;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: colorScheme.error),
                          SizedBox(width: 12),
                          Text(
                            'Delete Account',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountFormScreen(
                    repository: widget.repository,
                    accountId: account.id,
                    isCreateMode: false,
                  ),
                ),
              );
              if (result == true) {
                provider.loadFields();
              }
            },
            child: Icon(Icons.edit),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.loadFields();
            },
            child: CustomScrollView(
              slivers: [
                // Account Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor:
                                      colorScheme.onPrimaryContainer,
                                  radius: 24,
                                  child: Icon(Icons.account_circle, size: 28),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.name,
                                        style: theme.textTheme.headlineSmall,
                                      ),
                                      if (account.note != null &&
                                          account.note!.isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          account.note!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                ),

                // Fields Section
                if (provider.isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading fields...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading fields',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              provider.errorMessage ??
                                  'An unexpected error occurred',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (provider.fields.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No fields yet',
                              style: theme.textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add some fields to get started with this account',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AccountFormScreen(
                                      repository: widget.repository,
                                      accountId: account.id,
                                      isCreateMode: false,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  provider.loadFields();
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Add Fields'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20, bottom: 8, top: 8),
                          child: Text(
                            'Fields (${provider.fields.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        ...provider.fields.map((field) {
                          return _buildFieldTile(field);
                        }).toList(),
                      ],
                    ),
                  ),

                // Bottom spacing for FAB
                SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldTile(AccountField field) {
    // Use the existing field view widgets directly without extra card wrapper
    switch (field.type) {
      case AccountFieldType.credential:
        return CredentialFieldView(field: field);
      case AccountFieldType.password:
        return PasswordFieldView(field: field);
      case AccountFieldType.text:
        return TextFieldView(field: field);
      case AccountFieldType.website:
        return WebsiteFieldView(field: field);
      case AccountFieldType.otp:
        return Consumer<AccountDetailProvider>(
          builder: (context, provider, child) {
            return OtpFieldView(
              field: field,
              onFieldUpdate: (updatedField) {
                provider.updateField(updatedField);
              },
            );
          },
        );
    }
  }

  void _handleMenuSelection(String value) {
    if (value == 'delete') {
      _confirmAndDeleteAccount();
    }
  }

  void _confirmAndDeleteAccount() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: colorScheme.error,
          size: 28,
        ),
        title: Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${widget.account.name}"?',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone. All associated fields will be permanently deleted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<AccountDetailProvider>(
                context,
                listen: false,
              ).deleteField(widget.account.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
