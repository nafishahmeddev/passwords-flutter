import 'package:flutter/material.dart';

class KnownServiceIcon {
  final String name;
  final List<String> keywords;
  final IconData icon;
  final Color? color;

  const KnownServiceIcon({
    required this.name,
    required this.keywords,
    required this.icon,
    this.color,
  });
}

class ServiceIconService {
  static const List<KnownServiceIcon> _knownServices = [
    // Social Media
    KnownServiceIcon(
      name: 'Facebook',
      keywords: ['facebook', 'fb', 'meta', 'facebook.com'],
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
    KnownServiceIcon(
      name: 'Twitter/X',
      keywords: ['twitter', 'x.com', 'x', 'tweet', 'twitter.com'],
      icon: Icons.alternate_email,
      color: Color(0xFF1DA1F2),
    ),
    KnownServiceIcon(
      name: 'Instagram',
      keywords: ['instagram', 'insta', 'ig', 'instagram.com'],
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
    ),
    KnownServiceIcon(
      name: 'LinkedIn',
      keywords: ['linkedin', 'linked', 'linkedin.com'],
      icon: Icons.business_center,
      color: Color(0xFF0A66C2),
    ),
    KnownServiceIcon(
      name: 'YouTube',
      keywords: ['youtube', 'yt', 'youtube.com'],
      icon: Icons.play_circle_filled,
      color: Color(0xFFFF0000),
    ),
    KnownServiceIcon(
      name: 'TikTok',
      keywords: ['tiktok', 'tik tok', 'tiktok.com'],
      icon: Icons.music_video,
      color: Color(0xFF000000),
    ),
    KnownServiceIcon(
      name: 'WhatsApp',
      keywords: ['whatsapp', 'whats app', 'wa', 'whatsapp.com'],
      icon: Icons.chat,
      color: Color(0xFF25D366),
    ),
    KnownServiceIcon(
      name: 'Telegram',
      keywords: ['telegram', 'tg', 'telegram.org', 't.me'],
      icon: Icons.send,
      color: Color(0xFF0088CC),
    ),
    KnownServiceIcon(
      name: 'Discord',
      keywords: ['discord', 'discord.com', 'discord.gg'],
      icon: Icons.forum,
      color: Color(0xFF5865F2),
    ),

    // Email Services
    KnownServiceIcon(
      name: 'Gmail',
      keywords: ['gmail', 'google mail', 'gmail.com', 'mail.google.com'],
      icon: Icons.email,
      color: Color(0xFFEA4335),
    ),
    KnownServiceIcon(
      name: 'Outlook',
      keywords: [
        'outlook',
        'hotmail',
        'live',
        'msn',
        'outlook.com',
        'hotmail.com',
        'live.com',
      ],
      icon: Icons.mail_outline,
      color: Color(0xFF0078D4),
    ),
    KnownServiceIcon(
      name: 'Yahoo Mail',
      keywords: ['yahoo', 'ymail', 'yahoo.com', 'ymail.com'],
      icon: Icons.alternate_email,
      color: Color(0xFF6001D2),
    ),

    // Google Services
    KnownServiceIcon(
      name: 'Google',
      keywords: ['google.com', 'www.google.com', 'google search'],
      icon: Icons.search,
      color: Color(0xFF4285F4),
    ),

    // Cloud Storage
    KnownServiceIcon(
      name: 'Google Drive',
      keywords: ['google drive', 'drive', 'gdrive', 'drive.google.com'],
      icon: Icons.cloud,
      color: Color(0xFF4285F4),
    ),
    KnownServiceIcon(
      name: 'Dropbox',
      keywords: ['dropbox', 'dropbox.com'],
      icon: Icons.cloud_upload,
      color: Color(0xFF0061FF),
    ),
    KnownServiceIcon(
      name: 'OneDrive',
      keywords: ['onedrive', 'one drive', 'onedrive.live.com'],
      icon: Icons.cloud_circle,
      color: Color(0xFF0078D4),
    ),
    KnownServiceIcon(
      name: 'iCloud',
      keywords: ['icloud', 'apple cloud', 'icloud.com'],
      icon: Icons.cloud_outlined,
      color: Color(0xFF007AFF),
    ),

    // Streaming Services
    KnownServiceIcon(
      name: 'Netflix',
      keywords: ['netflix', 'netflix.com'],
      icon: Icons.tv,
      color: Color(0xFFE50914),
    ),
    KnownServiceIcon(
      name: 'Spotify',
      keywords: ['spotify', 'spotify.com'],
      icon: Icons.music_note,
      color: Color(0xFF1DB954),
    ),
    KnownServiceIcon(
      name: 'Apple Music',
      keywords: ['apple music', 'itunes'],
      icon: Icons.library_music,
      color: Color(0xFFFA243C),
    ),
    KnownServiceIcon(
      name: 'Amazon Prime',
      keywords: ['amazon prime', 'prime video', 'prime'],
      icon: Icons.local_movies,
      color: Color(0xFF00A8E1),
    ),
    KnownServiceIcon(
      name: 'Disney+',
      keywords: ['disney', 'disney+', 'disney plus'],
      icon: Icons.castle,
      color: Color(0xFF113CCF),
    ),

    // Gaming
    KnownServiceIcon(
      name: 'Steam',
      keywords: ['steam', 'valve'],
      icon: Icons.games,
      color: Color(0xFF171A21),
    ),
    KnownServiceIcon(
      name: 'PlayStation',
      keywords: ['playstation', 'psn', 'ps4', 'ps5', 'sony'],
      icon: Icons.sports_esports,
      color: Color(0xFF003791),
    ),
    KnownServiceIcon(
      name: 'Xbox',
      keywords: ['xbox', 'microsoft gaming'],
      icon: Icons.videogame_asset,
      color: Color(0xFF107C10),
    ),
    KnownServiceIcon(
      name: 'Nintendo',
      keywords: ['nintendo', 'switch'],
      icon: Icons.gamepad,
      color: Color(0xFFE60012),
    ),

    // Financial
    KnownServiceIcon(
      name: 'PayPal',
      keywords: ['paypal'],
      icon: Icons.payment,
      color: Color(0xFF00457C),
    ),
    KnownServiceIcon(
      name: 'Bank',
      keywords: ['bank', 'banking', 'chase', 'wells fargo', 'bofa', 'citibank'],
      icon: Icons.account_balance,
      color: Color(0xFF2E7D32),
    ),
    KnownServiceIcon(
      name: 'Credit Card',
      keywords: ['visa', 'mastercard', 'amex', 'discover', 'credit'],
      icon: Icons.credit_card,
      color: Color(0xFF1976D2),
    ),

    // Work & Productivity
    KnownServiceIcon(
      name: 'Microsoft Office',
      keywords: ['microsoft', 'office', 'word', 'excel', 'powerpoint'],
      icon: Icons.work,
      color: Color(0xFF0078D4),
    ),
    KnownServiceIcon(
      name: 'Google Workspace',
      keywords: ['google workspace', 'gsuite', 'google docs', 'google sheets'],
      icon: Icons.business,
      color: Color(0xFF4285F4),
    ),
    KnownServiceIcon(
      name: 'Slack',
      keywords: ['slack'],
      icon: Icons.chat_bubble,
      color: Color(0xFF4A154B),
    ),
    KnownServiceIcon(
      name: 'Zoom',
      keywords: ['zoom'],
      icon: Icons.video_call,
      color: Color(0xFF2D8CFF),
    ),
    KnownServiceIcon(
      name: 'GitHub',
      keywords: ['github', 'git', 'github.com'],
      icon: Icons.code,
      color: Color(0xFF181717),
    ),

    // Shopping
    KnownServiceIcon(
      name: 'Amazon',
      keywords: ['amazon', 'aws'],
      icon: Icons.shopping_cart,
      color: Color(0xFFFF9900),
    ),
    KnownServiceIcon(
      name: 'eBay',
      keywords: ['ebay'],
      icon: Icons.store,
      color: Color(0xFFE53238),
    ),
    KnownServiceIcon(
      name: 'Shopping',
      keywords: ['shop', 'store', 'retail', 'buy'],
      icon: Icons.shopping_bag,
      color: Color(0xFF9C27B0),
    ),

    // Default/Fallback
    KnownServiceIcon(
      name: 'Website',
      keywords: ['website', 'web', 'site', 'www'],
      icon: Icons.language,
      color: Color(0xFF757575),
    ),
    KnownServiceIcon(
      name: 'App',
      keywords: ['app', 'application', 'mobile'],
      icon: Icons.apps,
      color: Color(0xFF757575),
    ),
  ];

  /// Find a known service icon based on account name or website URL
  static KnownServiceIcon? findServiceIcon(
    String? accountName, [
    String? websiteUrl,
  ]) {
    if (accountName == null && websiteUrl == null) return null;

    // Extract domain from URL for better matching
    String? domain;
    if (websiteUrl != null) {
      try {
        final uri = Uri.parse(websiteUrl.toLowerCase());
        domain = uri.host.replaceFirst('www.', '');
      } catch (e) {
        // Invalid URL, ignore domain matching
      }
    }

    final searchText =
        '${accountName ?? ''} ${websiteUrl ?? ''} ${domain ?? ''}'
            .toLowerCase();

    // First, try exact domain matching for better accuracy
    if (domain != null) {
      for (final service in _knownServices) {
        for (final keyword in service.keywords) {
          final keywordLower = keyword.toLowerCase();
          
          // Prioritize exact domain matches
          if (domain == keywordLower) {
            return service;
          }
          
          // Check for exact domain matches with common variations
          if (domain == 'www.$keywordLower' || 'www.$domain' == keywordLower) {
            return service;
          }
          
          // For domain-based keywords (those containing dots), only match if they're subdomains
          if (keywordLower.contains('.')) {
            if (domain.endsWith('.$keywordLower') || keywordLower.endsWith('.$domain')) {
              return service;
            }
          }
        }
      }
      
      // Second pass: looser domain matching for services without exact domain matches
      for (final service in _knownServices) {
        for (final keyword in service.keywords) {
          final keywordLower = keyword.toLowerCase();
          
          // Skip domain-based keywords in this pass
          if (keywordLower.contains('.')) continue;
          
          // Only match if the keyword is a clear part of the domain
          // e.g., "facebook" matches "facebook.com" but "gmail" doesn't match "google.com"
          if (domain.contains(keywordLower) && keywordLower.length >= 4) {
            // Additional check: ensure it's not a substring match that would be misleading
            final domainParts = domain.split('.');
            final mainDomain = domainParts.isNotEmpty ? domainParts[0] : domain;
            
            if (mainDomain == keywordLower || mainDomain.startsWith(keywordLower)) {
              return service;
            }
          }
        }
      }
    }

    // Fallback to general text matching (for account names, etc.)
    for (final service in _knownServices) {
      for (final keyword in service.keywords) {
        final keywordLower = keyword.toLowerCase();
        
        // Skip domain-based keywords for text matching
        if (keywordLower.contains('.')) continue;
        
        if (searchText.contains(keywordLower) && keywordLower.length >= 3) {
          return service;
        }
      }
    }

    return null;
  }

  /// Get all available service icons for selection
  static List<KnownServiceIcon> getAllServices() {
    return List.unmodifiable(_knownServices);
  }

  /// Find a service by its exact name
  static KnownServiceIcon? findServiceByName(String serviceName) {
    try {
      return _knownServices.firstWhere(
        (service) => service.name.toLowerCase() == serviceName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find services matching a search query
  static List<KnownServiceIcon> searchServices(String query) {
    if (query.isEmpty) return getAllServices();

    final queryLower = query.toLowerCase();
    return _knownServices.where((service) {
      return service.name.toLowerCase().contains(queryLower) ||
          service.keywords.any(
            (keyword) => keyword.toLowerCase().contains(queryLower),
          );
    }).toList();
  }
}
