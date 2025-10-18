import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/account.dart';
import '../../business/services/favicon_service.dart';
import '../../business/services/service_icon_service.dart';

class AccountLogo extends StatelessWidget {
  final Account? account;
  final String? websiteUrl; // Keep for backward compatibility but not used
  final double size;
  final bool showFallback;

  const AccountLogo({
    super.key,
    this.account,
    this.websiteUrl,
    this.size = 40,
    this.showFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    // If account has a logo, display it based on its type
    if (account?.logo != null && account?.logoType != null) {
      switch (account!.logoType!) {
        case LogoType.file:
          return _buildFileImage(context, account!.logo!);
        case LogoType.url:
          return _buildUrlImage(context, account!.logo!);
        case LogoType.icon:
          return _buildServiceIcon(context, account!.logo!);
      }
    }

    // Show fallback icon
    return _buildFallbackIcon(context);
  }

  Widget _buildFileImage(BuildContext context, String filePath) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _loadFileImage(filePath),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon(context);
              },
            );
          }
          return _buildFallbackIcon(context);
        },
      ),
    );
  }

  Widget _buildUrlImage(BuildContext context, String url) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: FaviconService.fetchFavicon(url),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon(context);
              },
            );
          }
          return _buildFallbackIcon(context);
        },
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, String serviceName) {
    final service = ServiceIconService.findServiceByName(serviceName);
    if (service != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Icon(
          service.icon,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }
    return _buildFallbackIcon(context);
  }

  Future<Uint8List?> _loadFileImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Failed to load image file: $e');
    }
    return null;
  }

  Widget _buildFallbackIcon(BuildContext context) {
    if (!showFallback) {
      return SizedBox(width: size, height: size);
    }
    // Always show default fallback icon after logo removal
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Icon(
        Icons.account_circle_outlined,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// A larger, interactive version for selection/editing
class AccountLogoSelector extends StatelessWidget {
  final Account? account;
  final String? websiteUrl;
  final VoidCallback? onTap;
  final double size;

  const AccountLogoSelector({
    super.key,
    this.account,
    this.websiteUrl,
    this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AccountLogo(
            account: account,
            websiteUrl: websiteUrl,
            size: size,
            showFallback: true,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(size * 0.15),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.edit,
                size: size * 0.15,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
