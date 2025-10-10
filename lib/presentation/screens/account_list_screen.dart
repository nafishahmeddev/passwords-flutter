import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/account_provider.dart';
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
  const AccountListScreen({super.key});

  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  IconData _getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'social media':
        return Icons.share_outlined;
      case 'banking':
        return Icons.account_balance_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'work':
        return Icons.work_outline;
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.account_circle_outlined;
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return Colors.blue;
      case 'social media':
        return Colors.purple;
      case 'banking':
        return Colors.green;
      case 'shopping':
        return Colors.orange;
      case 'work':
        return Colors.indigo;
      case 'gaming':
        return Colors.red;
      case 'entertainment':
        return Colors.pink;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getAccountTypeDescription(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return 'Email accounts and services';
      case 'social media':
        return 'Social platforms and networks';
      case 'banking':
        return 'Banking and financial services';
      case 'shopping':
        return 'E-commerce and retail accounts';
      case 'work':
        return 'Professional and work accounts';
      case 'gaming':
        return 'Gaming platforms and services';
      case 'entertainment':
        return 'Streaming and entertainment';
      default:
        return 'General account type';
    }
  }

  Future<void> _showAccountTypeDialog(BuildContext context) async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_circle_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Account Type',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select a template to get started',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Account types list
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: accountTemplates.keys.map((type) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(type),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getAccountTypeColor(
                                        type,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getAccountTypeIcon(type),
                                      color: _getAccountTypeColor(type),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          _getAccountTypeDescription(type),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            repository: Provider.of<AccountProvider>(
              context,
              listen: false,
            ).repository,
            isCreateMode: true,
            templateFields: templateFields,
          ),
        ),
      );

      // If account was successfully created, navigate to its detail screen
      if (result == true) {
        // Reload accounts to get the newly created account
        await Provider.of<AccountProvider>(
          context,
          listen: false,
        ).loadAccounts();

        // Find the newly created account (it should be the most recent one)
        final provider = Provider.of<AccountProvider>(context, listen: false);
        if (provider.state == AccountState.loaded &&
            provider.accounts.isNotEmpty) {
          final newestAccount = provider.accounts.reduce(
            (a, b) => a.createdAt > b.createdAt ? a : b,
          );

          // Navigate to the detail screen of the newly created account
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountDetailScreen(
                  account: newestAccount,
                  repository: Provider.of<AccountProvider>(
                    context,
                    listen: false,
                  ).repository,
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
        title: Text(
          'Passwords',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () async {
              final provider = Provider.of<AccountProvider>(
                context,
                listen: false,
              );
              if (provider.state == AccountState.loaded) {
                final result = await showSearch(
                  context: context,
                  delegate: AccountSearchDelegate(provider.accounts),
                );
                if (result != null && result.isNotEmpty) {
                  // Navigate to the selected account's detail screen
                  final provider = Provider.of<AccountProvider>(
                    context,
                    listen: false,
                  );
                  final account = provider.accounts.firstWhere(
                    (a) => a.id == result,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountDetailScreen(
                        account: account,
                        repository: Provider.of<AccountProvider>(
                          context,
                          listen: false,
                        ).repository,
                      ),
                    ),
                  );
                }
              }
            },
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'about':
                  // TODO: Show about dialog
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AccountProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading accounts...',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                } else if (provider.state == AccountState.loaded) {
                  if (provider.accounts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                Icons.account_circle_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'No accounts yet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to create your first account',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final favoriteAccounts = provider.accounts
                      .where((a) => a.isFavorite)
                      .toList();
                  final allAccounts = provider.accounts;
                  return CustomScrollView(
                    slivers: [
                      if (favoriteAccounts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'FAVORITES',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final account = favoriteAccounts[index];
                              final isFirst = index == 0;
                              final isLast =
                                  index == favoriteAccounts.length - 1;

                              BorderRadius borderRadius;
                              if (favoriteAccounts.length == 1) {
                                borderRadius = BorderRadius.circular(12);
                              } else if (isFirst) {
                                borderRadius = BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                );
                              } else if (isLast) {
                                borderRadius = BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                );
                              } else {
                                borderRadius = BorderRadius.circular(4);
                              }

                              return AccountListItem(
                                account: account,
                                borderRadius: borderRadius,
                              );
                            }, childCount: favoriteAccounts.length),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ALL ACCOUNTS',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              Spacer(),
                              Text(
                                '${allAccounts.length}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final account = allAccounts[index];
                            final isFirst = index == 0;
                            final isLast = index == allAccounts.length - 1;

                            BorderRadius borderRadius;
                            if (allAccounts.length == 1) {
                              borderRadius = BorderRadius.circular(12);
                            } else if (isFirst) {
                              borderRadius = BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              );
                            } else if (isLast) {
                              borderRadius = BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              );
                            } else {
                              borderRadius = BorderRadius.circular(4);
                            }

                            return AccountListItem(
                              account: account,
                              borderRadius: borderRadius,
                            );
                          }, childCount: allAccounts.length),
                        ),
                      ),
                      // Bottom padding for FAB
                      SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  );
                } else if (provider.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            provider.errorMessage ??
                                'An error occurred while loading accounts',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => provider.loadAccounts(),
                            icon: Icon(Icons.refresh_rounded),
                            label: Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Press + to add account',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountTypeDialog(context),
        icon: Icon(Icons.add_rounded),
        label: Text('New Account'),
        elevation: 3,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
