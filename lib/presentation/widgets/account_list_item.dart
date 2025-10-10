import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/account_provider.dart';
import '../screens/account_detail_screen.dart';
import '../screens/account_form_screen.dart';

class AccountListItem extends StatelessWidget {
  final dynamic account;
  final BorderRadius borderRadius;

  const AccountListItem({
    super.key,
    required this.account,
    this.borderRadius = BorderRadius.zero,
  });

  void _showDeleteConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          title: Text(
            'Delete Account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: Text(
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text('Delete'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );

    if (confirmed == true) {
      Provider.of<AccountProvider>(
        context,
        listen: false,
      ).deleteAccount(account.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
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
          },
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar/Icon with better styling
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAccountIcon(),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                // Content with improved typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isFavorite) ...[
                            SizedBox(width: 8),
                            Icon(
                              Icons.star_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      if (account.note != null && account.note!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          account.note!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        SizedBox(height: 4),
                        Text(
                          'No description',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Enhanced menu button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.all(8),
                  onSelected: (value) {
                    if (value == 'edit') {
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
                    } else if (value == 'favorite') {
                      Provider.of<AccountProvider>(
                        context,
                        listen: false,
                      ).toggleFavorite(account.id);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            account.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: account.isFavorite
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            account.isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Edit',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon() {
    // You can customize this based on account type or use a default
    if (account.name.toLowerCase().contains('email') ||
        account.name.toLowerCase().contains('gmail') ||
        account.name.toLowerCase().contains('outlook')) {
      return Icons.email_outlined;
    } else if (account.name.toLowerCase().contains('social') ||
        account.name.toLowerCase().contains('facebook') ||
        account.name.toLowerCase().contains('twitter') ||
        account.name.toLowerCase().contains('instagram')) {
      return Icons.share_outlined;
    } else if (account.name.toLowerCase().contains('bank') ||
        account.name.toLowerCase().contains('paypal') ||
        account.name.toLowerCase().contains('payment')) {
      return Icons.account_balance_outlined;
    } else if (account.name.toLowerCase().contains('shop') ||
        account.name.toLowerCase().contains('amazon') ||
        account.name.toLowerCase().contains('store')) {
      return Icons.shopping_bag_outlined;
    } else if (account.name.toLowerCase().contains('work') ||
        account.name.toLowerCase().contains('office') ||
        account.name.toLowerCase().contains('company')) {
      return Icons.work_outline;
    } else if (account.name.toLowerCase().contains('game') ||
        account.name.toLowerCase().contains('steam') ||
        account.name.toLowerCase().contains('xbox')) {
      return Icons.sports_esports_outlined;
    } else if (account.name.toLowerCase().contains('netflix') ||
        account.name.toLowerCase().contains('youtube') ||
        account.name.toLowerCase().contains('spotify')) {
      return Icons.movie_outlined;
    } else {
      return Icons.account_circle_outlined;
    }
  }
}
