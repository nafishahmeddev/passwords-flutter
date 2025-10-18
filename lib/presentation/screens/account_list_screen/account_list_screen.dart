import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../business/providers/account_provider.dart';
import '../../../business/providers/settings_provider.dart';
import 'widgets/account_list_item.dart';
import '../account_details_screen/account_detail_screen.dart';
import '../account_form_screen/account_form_screen.dart';
import '../../widgets/account_logo.dart';

class AccountListScreenCard extends StatefulWidget {
  const AccountListScreenCard({Key? key}) : super(key: key);

  @override
  _AccountListScreenCardState createState() => _AccountListScreenCardState();
}

class _AccountListScreenCardState extends State<AccountListScreenCard> {
  late TextEditingController _searchController;
  bool _isSearchActive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
      } else {
        // Focus the search field when activated
        FocusScope.of(context).requestFocus();
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Refresh accounts
    final provider = Provider.of<AccountProvider>(context, listen: false);
    await provider.loadAccounts();
  }

  /// Filter accounts based on search query
  List<dynamic> _filterAccounts(List<dynamic> accounts) {
    // Apply search filter if there's a query
    if (_searchQuery.isEmpty) {
      return accounts;
    }

    final query = _searchQuery.toLowerCase();

    return accounts.where((account) {
      // Match against account name
      final nameMatches = account.name.toLowerCase().contains(query);

      // Match against account notes (if they exist)
      final noteMatches =
          account.note != null && account.note!.toLowerCase().contains(query);

      // Return true if either field matches
      return nameMatches || noteMatches;
    }).toList();
  }

  /// Build the app bar with search functionality
  AppBar _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search accounts...",
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: textTheme.titleMedium,
            )
          : Text(
              'Accounts',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        // Search toggle button
        IconButton(
          icon: Icon(_isSearchActive ? Icons.close : Icons.search_rounded),
          onPressed: _toggleSearch,
          tooltip: _isSearchActive ? 'Cancel search' : 'Search accounts',
        ),
        Consumer(
          builder: (context, SettingsProvider settingsProvider, child) {
            if (settingsProvider.isAuthEnabled) {
              // Lock app button
              return IconButton(
                icon: const Icon(Icons.lock_outline_rounded),
                tooltip: 'Lock App',
                onPressed: () {
                  final settingsProvider = Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  );
                  settingsProvider.lockApp();
                },
              );
            } else {
              return Container();
            }
          },
        ),
      ],
    );
  }

  /// Shows a confirmation dialog for account deletion
  Future<bool> _showDeleteConfirmationDialog(dynamic account) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: 32,
              ),
              title: Text('Delete Account', style: textTheme.headlineSmall),
              content: Text(
                'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
                style: textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ) ??
        false;
  }

  /// Build the empty state display when no accounts are found
  Widget _buildEmptyState(bool isSearchActive) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Select the appropriate icon based on context
    IconData emptyStateIcon;
    String emptyStateMessage;

    if (isSearchActive) {
      // No search results
      emptyStateIcon = Icons.search_off_rounded;
      emptyStateMessage = 'No matching accounts found';
    } else {
      // No accounts/favorites at all
      emptyStateIcon = Icons.account_circle_outlined;
      emptyStateMessage = 'No accounts yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyStateIcon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withAlpha(178),
          ),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearchActive)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 32.0, right: 32.0),
              child: Text(
                'Tap the + button to add your first account',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Build a dismissible account list item with swipe-to-delete
  Widget _buildAccountListItem(dynamic account, int index, int length) {
    final bool useAlternateBackground = index % 2 == 1;
    BorderRadius borderRadius = BorderRadius.circular(16);
    if (length == 1) {
      borderRadius = BorderRadius.circular(16);
    } else if (index == 0) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(4),
      );
    } else if (index == length - 1) {
      borderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      );
    }

    return Dismissible(
      key: Key(account.id),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmationDialog(account),
      onDismissed: (direction) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        accountProvider.deleteAccount(account.id);

        // Show confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account.name} deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // Undo delete functionality would go here
                // Note: This would require implementing restore functionality in provider
              },
            ),
          ),
        );
      },
      child: AccountListItem(
        account: account,
        useAlternativeBackground: useAlternateBackground,
        onLongPress: () => _showAccountOptionsSheet(account),
        borderRadius: borderRadius,
      ),
    );
  }

  /// Show the options bottom sheet for an account
  void _showAccountOptionsSheet(dynamic account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAccountOptionsBottomSheet(account),
    );
  }

  /// Build the header for the account options bottom sheet
  Widget _buildAccountHeaderSection(dynamic account) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Account header with icon and details
          Row(
            children: [
              AccountLogo(account: account, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (account.note?.isNotEmpty == true)
                      Text(
                        account.note!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  /// Navigate to account detail screen
  void _navigateToDetailScreen(dynamic account) {
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

  /// Navigate to account edit screen
  void _navigateToEditScreen(dynamic account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          repository: Provider.of<AccountProvider>(
            context,
            listen: false,
          ).repository,
          accountId: account.id,
          isCreateMode: false,
        ),
      ),
    );
  }

  /// Build the account options bottom sheet
  Widget _buildAccountOptionsBottomSheet(dynamic account) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Account header section
          _buildAccountHeaderSection(account),

          // Action buttons
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('View Account'),
            onTap: () {
              Navigator.pop(context);
              _navigateToDetailScreen(account);
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Account'),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditScreen(account);
            },
          ),

          ListTile(
            leading: Icon(
              account.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: account.isFavorite ? colorScheme.primary : null,
            ),
            title: Text(
              account.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            ),
            onTap: () {
              Navigator.pop(context);
              accountProvider.toggleFavorite(account.id);
            },
          ),

          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.error,
            ),
            title: Text(
              'Delete Account',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              bool confirm = await _showDeleteConfirmationDialog(account);
              if (confirm && context.mounted) {
                accountProvider.deleteAccount(account.id);
              }
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading accounts...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          } else if (provider.state == AccountState.loaded) {
            final filteredAccounts = _filterAccounts(provider.accounts);

            if (filteredAccounts.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height - 200,
                    child: _buildEmptyState(_searchQuery.isNotEmpty),
                  ),
                ),
              );
            }

            // If we're not already showing only favorites, split into sections
            final favoriteAccounts = filteredAccounts
                .where((account) => account.isFavorite)
                .toList();
            final otherAccounts = filteredAccounts
                .where((account) => !account.isFavorite)
                .toList();

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Favorites section
                    if (favoriteAccounts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          top: 8.0,
                          bottom: 12.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Favorites',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${favoriteAccounts.length}',
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
                      ...favoriteAccounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final account = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _buildAccountListItem(
                            account,
                            index,
                            favoriteAccounts.length,
                          ),
                        );
                      }),
                    ],

                    // Others section
                    if (otherAccounts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          top: 16.0,
                          bottom: 12.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Others',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${otherAccounts.length}',
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
                      ...otherAccounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final account = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _buildAccountListItem(
                            account,
                            index,
                            otherAccounts.length,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          } else if (provider.hasError) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
                          const SizedBox(height: 24),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => provider.loadAccounts(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Default state
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Text(
                    'Press + to add account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
