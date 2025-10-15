// lib/presentation/screens/account_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:passwords/presentation/widgets/field_views/grouped_fields_view.dart';
import 'package:provider/provider.dart';
import '../../data/models/account.dart';
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
            elevation: 3,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(Icons.edit_rounded),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.loadFields();
            },
            child: CustomScrollView(
              slivers: [
                // Account Header Section - Pixel style (minimal, clean)
                SliverToBoxAdapter(
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          radius: 24,
                          child: Icon(Icons.account_circle, size: 28),
                        ),
                        title: Text(
                          account.name,
                          style: theme.textTheme.titleLarge,
                        ),
                        subtitle:
                            account.note != null && account.note!.isNotEmpty
                            ? Text(
                                account.note!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
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
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
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
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading fields',
                              style: theme.textTheme.titleMedium?.copyWith(
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
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pixel-style empty state
                            Icon(
                              Icons.note_alt_outlined,
                              size: 48,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No fields added yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add information to this account',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            FilledButton.tonal(
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
                              child: Text('Add Fields'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SimplifiedGroupedFieldsView(fields: provider.fields),
                  ),

                // Bottom spacing for FAB (Pixel style)
                SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
        );
      },
    );
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
