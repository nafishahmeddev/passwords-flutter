import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business/cubit/account_cubit.dart';
import '../../data/templates/account_templates.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  String _searchQuery = '';

  Future<void> _showAccountTypeDialog(BuildContext context) async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Account Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: accountTemplates.keys.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedType != null) {
      // Get template fields for the selected type
      final templateFields = getTemplateFields(
        selectedType,
        'temp',
      ); // accountId will be set later

      // Navigate to create new account with template fields
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountFormScreen(
            repository: context.read<AccountCubit>().repository,
            isCreateMode: true,
            templateFields: templateFields,
          ),
        ),
      );

      // If account was successfully created, navigate to its detail screen
      if (result == true) {
        // Reload accounts to get the newly created account
        await context.read<AccountCubit>().loadAccounts();

        // Find the newly created account (it should be the most recent one)
        final state = context.read<AccountCubit>().state;
        if (state is AccountLoaded && state.accounts.isNotEmpty) {
          final newestAccount = state.accounts.reduce(
            (a, b) => a.createdAt > b.createdAt ? a : b,
          );

          // Navigate to the detail screen of the newly created account
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountDetailScreen(
                  account: newestAccount,
                  repository: context.read<AccountCubit>().repository,
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      context.read<AccountCubit>().deleteAccount(account.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accounts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state is AccountLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is AccountLoaded) {
                  if (state.accounts.isEmpty) {
                    return Center(child: Text('No accounts found'));
                  }
                  final filteredAccounts = state.accounts
                      .where(
                        (a) =>
                            a.name.toLowerCase().contains(_searchQuery) ||
                            (a.note?.toLowerCase().contains(_searchQuery) ??
                                false),
                      )
                      .toList();
                  final favoriteAccounts = filteredAccounts
                      .where((a) => a.isFavorite)
                      .toList();
                  final allAccounts = filteredAccounts;
                  return ListView(
                    children: [
                      if (favoriteAccounts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Favorites',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ...favoriteAccounts.map(
                          (account) => ListTile(
                            contentPadding: EdgeInsets.fromLTRB(
                              16.0,
                              0.0,
                              0,
                              0.0,
                            ),
                            title: Text(account.name),
                            subtitle: Text(account.note ?? ''),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AccountFormScreen(
                                        repository: context
                                            .read<AccountCubit>()
                                            .repository,
                                        accountId: account.id,
                                        isCreateMode: false,
                                      ),
                                    ),
                                  );
                                } else if (value == 'favorite') {
                                  context.read<AccountCubit>().toggleFavorite(
                                    account.id,
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteConfirmationDialog(
                                    context,
                                    account,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'favorite',
                                  child: Row(
                                    children: [
                                      Icon(
                                        account.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        account.isFavorite
                                            ? 'Unfavorite'
                                            : 'Favorite',
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountDetailScreen(
                                    account: account,
                                    repository: context
                                        .read<AccountCubit>()
                                        .repository,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Divider(),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'All Accounts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      ...allAccounts.map(
                        (account) => ListTile(
                          contentPadding: EdgeInsets.fromLTRB(
                            16.0,
                            0.0,
                            0,
                            0.0,
                          ),
                          title: Text(account.name),
                          subtitle: Text(account.note ?? ''),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AccountFormScreen(
                                      repository: context
                                          .read<AccountCubit>()
                                          .repository,
                                      accountId: account.id,
                                      isCreateMode: false,
                                    ),
                                  ),
                                );
                              } else if (value == 'favorite') {
                                context.read<AccountCubit>().toggleFavorite(
                                  account.id,
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirmationDialog(context, account);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'favorite',
                                child: Row(
                                  children: [
                                    Icon(
                                      account.isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      account.isFavorite
                                          ? 'Unfavorite'
                                          : 'Favorite',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountDetailScreen(
                                  account: account,
                                  repository: context
                                      .read<AccountCubit>()
                                      .repository,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else if (state is AccountError) {
                  return Center(child: Text(state.message));
                }
                return Center(child: Text('Press + to add account'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAccountTypeDialog(context),
      ),
    );
  }
}
