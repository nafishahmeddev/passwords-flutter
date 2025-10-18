
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FaviconService {
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxFileSize = 1024 * 1024; // 1MB max

  /// Fetch favicon from a website URL
  static Future<Uint8List?> fetchFavicon(String websiteUrl) async {
    try {
      final uri = Uri.tryParse(websiteUrl);
      if (uri == null || (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
        return null;
      }

      // Try multiple favicon URLs in order of preference
      final faviconUrls = _generateFaviconUrls(uri);
      
      for (final faviconUrl in faviconUrls) {
        try {
          final response = await http.get(
            Uri.parse(faviconUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(_timeout);

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            // Check file size
            if (response.bodyBytes.length > _maxFileSize) {
              debugPrint('Favicon too large: ${response.bodyBytes.length} bytes');
              continue;
            }

            // Check if it's likely an image by checking content type or magic bytes
            if (_isValidImage(response.bodyBytes, response.headers['content-type'])) {
              return response.bodyBytes;
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch favicon from $faviconUrl: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error fetching favicon for $websiteUrl: $e');
    }
    
    return null;
  }

  /// Generate potential favicon URLs for a given website
  static List<String> _generateFaviconUrls(Uri uri) {
    final baseUrl = '${uri.scheme}://${uri.host}';
    
    return [
      // Modern favicon locations
      '$baseUrl/favicon.ico',
      '$baseUrl/favicon.png',
      '$baseUrl/apple-touch-icon.png',
      '$baseUrl/apple-touch-icon-precomposed.png',
      
      // Common subdirectories
      '$baseUrl/assets/favicon.ico',
      '$baseUrl/assets/favicon.png',
      '$baseUrl/images/favicon.ico',
      '$baseUrl/images/favicon.png',
      '$baseUrl/img/favicon.ico',
      '$baseUrl/img/favicon.png',
      
      // Different sizes
      '$baseUrl/favicon-32x32.png',
      '$baseUrl/favicon-16x16.png',
      '$baseUrl/icon-192x192.png',
      '$baseUrl/icon-512x512.png',
      
      // Google's favicon service as fallback
      'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64',
    ];
  }

  /// Check if the response contains valid image data
  static bool _isValidImage(Uint8List data, String? contentType) {
    if (data.isEmpty) return false;

    // Check content type if available
    if (contentType != null) {
      final lowerContentType = contentType.toLowerCase();
      if (lowerContentType.startsWith('image/')) {
        return true;
      }
      // Sometimes favicons are served with generic content types
      if (lowerContentType.contains('octet-stream') && data.length > 0) {
        // Fall through to magic byte check
      } else if (!lowerContentType.startsWith('image/')) {
        return false;
      }
    }

    // Check magic bytes for common image formats
    if (data.length >= 4) {
      // PNG: 89 50 4E 47
      if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
        return true;
      }
      
      // JPEG: FF D8 FF
      if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
        return true;
      }
      
      // GIF: 47 49 46 38 (GIF8)
      if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38) {
        return true;
      }
      
      // ICO: 00 00 01 00
      if (data[0] == 0x00 && data[1] == 0x00 && data[2] == 0x01 && data[3] == 0x00) {
        return true;
      }
      
      // WebP: RIFF...WEBP
      if (data.length >= 12 &&
          data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
          data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
        return true;
      }
    }

    return false;
  }

  /// Extract domain from URL for display purposes
  static String? extractDomain(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.hasScheme) {
        return uri.host.replaceFirst('www.', '');
      }
    } catch (e) {
      debugPrint('Error extracting domain from $url: $e');
    }
    
    return null;
  }

  /// Check if a URL is valid for favicon fetching
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.tryParse(url);
      return uri != null && 
             uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}