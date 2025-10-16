import 'package:flutter/material.dart';
import 'package:passwords/presentation/screens/account_details_screen/widgets/grouped_fields_view.dart';
import 'package:provider/provider.dart';
import '../../../data/models/account.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../business/providers/account_detail_provider.dart';
import '../account_form_screen/account_form_screen.dart';

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
    extends State<_AccountDetailScreenContent>
    with TickerProviderStateMixin {
  // Scroll controller to track scroll position for animations
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _headerAnimationController;

  // Track if we're showing header info expanded or collapsed
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Setup scroll listener
    _scrollController.addListener(_scrollListener);

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerAnimationController.forward();
    });
  }

  void _scrollListener() {
    // Update header collapse state based on scroll position
    if (_scrollController.offset > 120 && !_isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = true;
      });
    } else if (_scrollController.offset <= 120 && _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = false;
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountDetailProvider>(
      builder: (context, provider, child) {
        final account = provider.account ?? widget.account;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              account.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(
                icon: Icon(Icons.favorite_border_rounded),
                tooltip: account.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () {
                  provider.toggleFavorite(account.id);
                },
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                icon: Icon(Icons.more_vert_rounded),
                position: PopupMenuPosition.under,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
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
          floatingActionButton: FloatingActionButton.extended(
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
            elevation: 4,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icon(Icons.edit_rounded),
            label: Text('Edit Account'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.loadFields();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Simple non-animated header
                SliverToBoxAdapter(
                  child: Container(
                    height: 120,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Account avatar - simple layout
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.account_circle_rounded,
                              size: 36,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Account details with simple layout
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (account.note != null &&
                                  account.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    account.note!,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withOpacity(0.8),
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Favorite indicator
                        if (account.isFavorite)
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Less spacing for more compact design
                SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Fields Section with improved UI
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
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 32),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              provider.errorMessage ??
                                  'An unexpected error occurred',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onErrorContainer.withOpacity(
                                  0.8,
                                ),
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => provider.loadFields(),
                              child: Text('Try Again'),
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
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 32),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.note_alt_outlined,
                                size: 32,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No fields added yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add credentials, passwords, or other information to this account',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 15,
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
                              icon: Icon(Icons.add_rounded),
                              label: Text('Add Fields'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: 88,
                    ), // Extra padding for FAB
                    sliver: SliverToBoxAdapter(
                      child: SimplifiedGroupedFieldsView(
                        fields: provider.fields,
                      ),
                    ),
                  ),
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
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        icon: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            color: colorScheme.error,
            size: 32,
          ),
        ),
        title: Text(
          'Delete Account',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete "${widget.account.name}"?',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All associated fields will be permanently deleted.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.error.withOpacity(0.8),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<AccountDetailProvider>(
                context,
                listen: false,
              ).deleteAccount(widget.account.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
