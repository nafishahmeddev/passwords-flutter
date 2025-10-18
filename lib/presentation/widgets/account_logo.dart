import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/account.dart';
import '../../business/services/favicon_service.dart';
import '../../business/services/service_icon_service.dart';

class AccountLogo extends StatefulWidget {
  final Account? account;
  final String? websiteUrl;
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
  State<AccountLogo> createState() => _AccountLogoState();
}

class _AccountLogoState extends State<AccountLogo> {
  Uint8List? _faviconData;
  bool _isLoadingFavicon = false;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void didUpdateWidget(AccountLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account?.logo != widget.account?.logo ||
        oldWidget.websiteUrl != widget.websiteUrl) {
      // Defer logo loading to avoid setState during build
      Future.microtask(() {
        if (mounted) {
          _loadLogo();
        }
      });
    }
  }

  Future<void> _loadLogo() async {
    // Reset state
    if (mounted) {
      setState(() {
        _faviconData = null;
        _isLoadingFavicon = true;
      });
    } // If account has a custom logo, use it
    if (widget.account?.logo != null && widget.account?.logoType != null) {
      switch (widget.account!.logoType!) {
        case LogoType.file:
          // Custom file logo
          try {
            final file = File(widget.account!.logo!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (mounted) {
                setState(() {
                  _faviconData = bytes;
                });
              }
              return;
            }
          } catch (e) {
            debugPrint('Failed to load custom logo file: $e');
          }
          break;
        case LogoType.url:
          // Custom URL logo (favicon)
          await _loadFavicon(widget.account!.logo!);
          return;
        case LogoType.icon:
          // Custom system icon - handled in build method
          return;
      }
    }

    // Try to auto-fetch favicon from website URL
    final url = widget.websiteUrl;
    if (url != null && FaviconService.isValidUrl(url)) {
      await _loadFavicon(url);
    }
  }

  Future<void> _loadFavicon(String url) async {
    if (mounted) {
      setState(() {
        _isLoadingFavicon = true;
      });
    }

    try {
      final faviconData = await FaviconService.fetchFavicon(url);
      if (mounted) {
        setState(() {
          _faviconData = faviconData;
          _isLoadingFavicon = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavicon = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have favicon data, show it
    if (_faviconData != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.25),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          _faviconData!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        ),
      );
    }

    // If loading favicon, show loading indicator
    if (_isLoadingFavicon) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.25),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // If account has custom icon type, show it
    if (widget.account?.logoType == LogoType.icon &&
        widget.account?.logo != null) {
      return _buildCustomIcon(widget.account!.logo!);
    }

    // Show fallback icon
    return _buildFallbackIcon();
  }

  Widget _buildCustomIcon(String iconData) {
    // Parse custom icon data - could be icon code point or service name
    try {
      // Try to parse as icon code point
      final codePoint = int.tryParse(iconData);
      if (codePoint != null) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(
            IconData(codePoint, fontFamily: 'MaterialIcons'),
            size: widget.size * 0.5,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
      }

      // Try to find known service by name
      final service = ServiceIconService.getAllServices()
          .where((s) => s.name.toLowerCase() == iconData.toLowerCase())
          .firstOrNull;

      if (service != null) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            color:
                service.color?.withOpacity(0.1) ??
                Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(
            service.icon,
            size: widget.size * 0.5,
            color:
                service.color ??
                Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to parse custom icon data: $e');
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    if (!widget.showFallback) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    // Try to find a known service icon based on account name or website
    final knownService = ServiceIconService.findServiceIcon(
      widget.account?.name,
      widget.websiteUrl,
    );

    if (knownService != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.25),
          color:
              knownService.color?.withOpacity(0.1) ??
              Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Icon(
          knownService.icon,
          size: widget.size * 0.5,
          color:
              knownService.color ??
              Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    // Default fallback icon
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.25),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Icon(
        Icons.account_circle_outlined,
        size: widget.size * 0.5,
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
          AccountLogo(account: account, websiteUrl: websiteUrl, size: size),
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
