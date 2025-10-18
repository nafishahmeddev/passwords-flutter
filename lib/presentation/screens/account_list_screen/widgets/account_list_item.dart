import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../business/providers/account_provider.dart';

import '../../../widgets/account_logo.dart';
import '../../account_details_screen/account_detail_screen.dart';


class AccountListItem extends StatelessWidget {
  final dynamic account;
  final bool useAlternativeBackground;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;

  // Define a constant BorderRadius for default value
  static const BorderRadius defaultBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  const AccountListItem({
    super.key,
    required this.account,
    this.useAlternativeBackground = false,
    this.onLongPress,
    this.borderRadius = defaultBorderRadius, // Default to rounded corners
  });

  Color _getIconBackgroundColor(BuildContext context) {
    // Create a deterministic color based on the account name
    final int hash = account.name.hashCode;
    final colorScheme = Theme.of(context).colorScheme;

    // Use a list of predefined colors from the theme with consistent opacity
    const double opacity = 0.9;

    // Primary colors from theme
    final List<Color> baseColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    // Generate additional blended colors for more variety
    final List<Color> blendedColors = [
      Color.lerp(colorScheme.primary, colorScheme.secondary, 0.5)!,
      Color.lerp(colorScheme.secondary, colorScheme.tertiary, 0.5)!,
      Color.lerp(colorScheme.tertiary, colorScheme.primary, 0.5)!,
    ];

    // Combine all colors and apply opacity
    final List<Color> allColors = [
      ...baseColors,
      ...blendedColors,
    ].map((color) => color.withOpacity(opacity)).toList();

    // Return a color based on the account name's hash
    return allColors[hash.abs() % allColors.length];
  }

  /// Shows a confirmation dialog before deleting an account
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    // Get theme elements for consistent styling
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must take an action
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
    );

    // Only delete if user confirmed
    if (confirmed == true) {
      if (context.mounted) {
        Provider.of<AccountProvider>(
          context,
          listen: false,
        ).deleteAccount(account.id);
      }
    }
  }

  /// Builds the account icon avatar with dynamic color
  Widget _buildAccountAvatar(BuildContext context, Color color) {
    // Use the new AccountLogo widget for consistent logo display
    // Note: In list view, we only use account name for service recognition
    // Website URL detection requires loading fields, which is done in detail/form screens
    return AccountLogo(
      account: account,
      websiteUrl: null, // No website URL available in list view
      size: 48,
    );
  }

  /// Builds the account content section (name, favorite icon, description)
  Widget _buildAccountContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account name row with optional favorite star
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (account.isFavorite) ...[
                const SizedBox(width: 8),
                Icon(Icons.star_rounded, color: colorScheme.primary, size: 16),
              ],
            ],
          ),

          // Account description or placeholder text
          const SizedBox(height: 4),
          Text(
            account.note != null && account.note!.isNotEmpty
                ? account.note!
                : 'No description',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: account.note == null || account.note!.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getIconBackgroundColor(context);
    return Card(
      elevation: 0, // No shadow
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      margin:
          EdgeInsets.zero, // No margin for consistent spacing in grouped layout
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetailScreen(context),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Account avatar
              _buildAccountAvatar(context, color),
              const SizedBox(width: 16),
              // Account content
              _buildAccountContent(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to the account detail screen
  void _navigateToDetailScreen(BuildContext context) {
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
