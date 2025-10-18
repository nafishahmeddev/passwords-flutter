import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class FaviconService {
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxFileSize = 1024 * 1024; // 1MB max
  static const Duration _cacheExpiry = Duration(days: 7); // Cache for 7 days

  static Directory? _cacheDirectory;

  /// Initialize the cache directory
  static Future<void> _initCacheDirectory() async {
    if (_cacheDirectory != null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/favicon_cache');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error initializing favicon cache directory: $e');
    }
  }

  /// Get cache file path for a domain
  static String _getCacheFilePath(String domain) {
    final hash = sha256.convert(utf8.encode(domain)).toString();
    return '${_cacheDirectory!.path}/$hash.favicon';
  }

  /// Get cached favicon if available and not expired
  static Future<Uint8List?> _getCachedFavicon(String domain) async {
    try {
      await _initCacheDirectory();
      if (_cacheDirectory == null) return null;

      final cacheFile = File(_getCacheFilePath(domain));
      if (!await cacheFile.exists()) return null;

      final stat = await cacheFile.stat();
      final cacheAge = DateTime.now().difference(stat.modified);

      // Check if cache is expired
      if (cacheAge > _cacheExpiry) {
        try {
          await cacheFile.delete();
        } catch (e) {
          debugPrint('Error deleting expired cache file: $e');
        }
        return null;
      }

      return await cacheFile.readAsBytes();
    } catch (e) {
      debugPrint('Error reading cached favicon for $domain: $e');
      return null;
    }
  }

  /// Cache favicon data
  static Future<void> _cacheFavicon(String domain, Uint8List data) async {
    try {
      await _initCacheDirectory();
      if (_cacheDirectory == null) return;

      final cacheFile = File(_getCacheFilePath(domain));
      await cacheFile.writeAsBytes(data);

      debugPrint('Cached favicon for $domain (${data.length} bytes)');
    } catch (e) {
      debugPrint('Error caching favicon for $domain: $e');
    }
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      await _initCacheDirectory();
      if (_cacheDirectory == null) return;

      final files = await _cacheDirectory!.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.endsWith('.favicon')) {
          final stat = await file.stat();
          final cacheAge = now.difference(stat.modified);

          if (cacheAge > _cacheExpiry) {
            try {
              await file.delete();
              debugPrint('Deleted expired cache file: ${file.path}');
            } catch (e) {
              debugPrint('Error deleting expired cache file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing expired cache: $e');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      await _initCacheDirectory();
      if (_cacheDirectory == null) return 0;

      final files = await _cacheDirectory!.list().toList();
      int totalSize = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.favicon')) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Clear all cached favicons
  static Future<void> clearCache() async {
    try {
      await _initCacheDirectory();
      if (_cacheDirectory == null) return;

      final files = await _cacheDirectory!.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith('.favicon')) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint('Error deleting cache file: $e');
          }
        }
      }

      debugPrint('Cleared favicon cache');
    } catch (e) {
      debugPrint('Error clearing favicon cache: $e');
    }
  }

  /// Fetch favicon from a website URL with caching support
  static Future<Uint8List?> fetchFavicon(String websiteUrl) async {
    try {
      final uri = Uri.tryParse(websiteUrl);
      if (uri == null ||
          (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
        return null;
      }

      final domain = uri.host;

      // Try to get from cache first
      final cachedFavicon = await _getCachedFavicon(domain);
      if (cachedFavicon != null) {
        debugPrint('Found cached favicon for $domain');
        return cachedFavicon;
      }

      debugPrint('Fetching favicon from network for $domain');
      final faviconUrls = _generateFaviconUrls(uri);

      for (final faviconUrl in faviconUrls) {
        try {
          final response = await http
              .get(
                Uri.parse(faviconUrl),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'Accept': 'image/*,*/*;q=0.8',
                },
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final contentLength =
                response.contentLength ?? response.bodyBytes.length;

            if (contentLength > _maxFileSize) {
              debugPrint(
                'Favicon too large: ${contentLength} bytes for $faviconUrl',
              );
              continue;
            }

            final faviconData = response.bodyBytes;
            final contentType = response.headers['content-type'];

            if (_isValidImage(faviconData, contentType)) {
              // Cache the favicon for future use
              await _cacheFavicon(domain, faviconData);
              return faviconData;
            }
          }
        } catch (e) {
          debugPrint('Error fetching $faviconUrl: $e');
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
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        return true;
      }

      // JPEG: FF D8 FF
      if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
        return true;
      }

      // GIF: 47 49 46 38 (GIF8)
      if (data[0] == 0x47 &&
          data[1] == 0x49 &&
          data[2] == 0x46 &&
          data[3] == 0x38) {
        return true;
      }

      // ICO: 00 00 01 00
      if (data[0] == 0x00 &&
          data[1] == 0x00 &&
          data[2] == 0x01 &&
          data[3] == 0x00) {
        return true;
      }

      // WebP: RIFF...WEBP
      if (data.length >= 12 &&
          data[0] == 0x52 &&
          data[1] == 0x49 &&
          data[2] == 0x46 &&
          data[3] == 0x46 &&
          data[8] == 0x57 &&
          data[9] == 0x45 &&
          data[10] == 0x42 &&
          data[11] == 0x50) {
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
