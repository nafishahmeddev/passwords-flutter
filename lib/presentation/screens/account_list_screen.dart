import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../business/cubit/account_cubit.dart';
import '../../data/templates/account_templates.dart';
import '../widgets/account_list_item.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountSearchDelegate extends SearchDelegate<String> {
  final List<dynamic> accounts;

  AccountSearchDelegate(this.accounts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = accounts.where(
      (account) =>
          account.name.toLowerCase().contains(query.toLowerCase()) ||
          (account.note?.toLowerCase().contains(query.toLowerCase()) ?? false),
    );

    return ListView(
      children: results
          .map(
            (account) => ListTile(
              title: Text(account.name),
              subtitle: Text(account.note ?? ''),
              onTap: () {
                close(context, account.id);
              },
            ),
          )
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = accounts.where(
      (account) =>
          account.name.toLowerCase().contains(query.toLowerCase()) ||
          (account.note?.toLowerCase().contains(query.toLowerCase()) ?? false),
    );

    return ListView(
      children: suggestions
          .map(
            (account) => ListTile(
              title: Text(account.name),
              subtitle: Text(account.note ?? ''),
              onTap: () {
                close(context, account.id);
              },
            ),
          )
          .toList(),
    );
  }
}

class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show about dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passwords'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final state = context.read<AccountCubit>().state;
              if (state is AccountLoaded) {
                final result = await showSearch(
                  context: context,
                  delegate: AccountSearchDelegate(state.accounts),
                );
                if (result != null && result.isNotEmpty) {
                  // Navigate to the selected account's detail screen
                  final account = state.accounts.firstWhere(
                    (a) => a.id == result,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountDetailScreen(
                        account: account,
                        repository: context.read<AccountCubit>().repository,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state is AccountLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is AccountLoaded) {
                  if (state.accounts.isEmpty) {
                    return Center(child: Text('No accounts found'));
                  }
                  final favoriteAccounts = state.accounts
                      .where((a) => a.isFavorite)
                      .toList();
                  final allAccounts = state.accounts;
                  return ListView(
                    children: [
                      if (favoriteAccounts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'FAVORITES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.05,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...favoriteAccounts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final account = entry.value;
                          final isFirst = index == 0;
                          final isLast = index == favoriteAccounts.length - 1;

                          BorderRadius borderRadius;
                          if (favoriteAccounts.length == 1) {
                            borderRadius = BorderRadius.circular(18);
                          } else if (isFirst) {
                            borderRadius = BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            );
                          } else if (isLast) {
                            borderRadius = BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            );
                          } else {
                            borderRadius = BorderRadius.zero;
                          }

                          return AccountListItem(
                            account: account,
                            borderRadius: borderRadius,
                          );
                        }),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'ALL ACCOUNTS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...allAccounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final account = entry.value;
                        final isFirst = index == 0;
                        final isLast = index == allAccounts.length - 1;

                        BorderRadius borderRadius;
                        if (allAccounts.length == 1) {
                          borderRadius = BorderRadius.circular(18);
                        } else if (isFirst) {
                          borderRadius = BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          );
                        } else if (isLast) {
                          borderRadius = BorderRadius.only(
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          );
                        } else {
                          borderRadius = BorderRadius.zero;
                        }

                        return AccountListItem(
                          account: account,
                          borderRadius: borderRadius,
                        );
                      }),
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
