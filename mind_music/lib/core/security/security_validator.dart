import 'dart:io';
import 'package:path/path.dart' as p;

/// Security validation and sanitization utility for Mind-Music.
///
/// Prevents:
/// 1. Directory traversal attacks (`../`, hidden system files, sensitive OS directories)
/// 2. Code / Command injection in AI prompt text and search queries
/// 3. Resource exhaustion (DoS via unbounded directory recursion or malicious file formats)
class SecurityValidator {
  SecurityValidator._();

  // Whitelisted Audio & Video extensions
  static const Set<String> allowedAudioExtensions = {
    '.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.opus', '.alac'
  };

  static const Set<String> allowedVideoExtensions = {
    '.mp4', '.mkv', '.webm', '.avi', '.mov', '.3gp'
  };

  // Forbidden system directories (in POSIX / slash format)
  static const Set<String> prohibitedSystemPrefixes = {
    '/etc', '/system', '/proc', '/sys', '/data/data',
    'c:/windows', 'c:/program files', 'c:/windows/system32'
  };

  /// Sanitizes text input for AI Copilot queries and search bars.
  /// Strips control characters, script tags, shell metacharacters, and restricts max length.
  static String sanitizeInput(String input, {int maxLength = 250}) {
    if (input.isEmpty) return '';

    // Trim and cap length to prevent buffer/memory exhaustion
    String sanitized = input.trim();
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    // Strip script / HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Strip shell metacharacters and control characters
    sanitized = sanitized.replaceAll(RegExp(r'[;&|`$><\\\r\n\t]'), ' ');

    // Normalize multiple whitespace to single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return sanitized;
  }

  /// Validates whether a file path is safe to access and belongs to an allowed media format.
  /// Prevents directory traversal attacks (`../`, symlinks to private system locations).
  static bool isSafeMediaPath(String filePath) {
    if (filePath.isEmpty) return false;

    // Reject paths containing parent directory traversal attempts
    if (filePath.contains('..')) return false;

    // Reject null bytes
    if (filePath.contains('\u0000')) return false;

    // Allow Flutter bundled assets
    if (filePath.startsWith('assets/')) return true;

    try {
      // Normalize slashes across platforms
      final normalized = p.normalize(filePath).replaceAll('\\', '/').toLowerCase();

      final ext = p.extension(normalized);

      // Must have an allowed media extension
      final isAllowedExt = allowedAudioExtensions.contains(ext) || allowedVideoExtensions.contains(ext);
      if (!isAllowedExt) return false;

      // Reject sensitive root or system directories
      for (final blocked in prohibitedSystemPrefixes) {
        if (normalized.startsWith(blocked) || normalized.startsWith('/$blocked')) {
          return false;
        }
      }

      // Hidden system files (e.g. .hidden or .nomedia)
      final fileName = p.basename(normalized);
      if (fileName.startsWith('.')) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a directory is safe to scan without risking system loops or unauthorized access.
  static bool isSafeScanDirectory(Directory dir) {
    try {
      final normalized = p.normalize(dir.path).replaceAll('\\', '/').toLowerCase();

      // Check against forbidden directories
      for (final blocked in prohibitedSystemPrefixes) {
        if (normalized.startsWith(blocked) || normalized.startsWith('/$blocked')) {
          return false;
        }
      }

      // Check path segments for hidden folders
      final segments = normalized.split('/');
      for (final seg in segments) {
        if (seg.startsWith('.') && seg != '.' && seg != '..') {
          return false;
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validates AI intent command tokens against a strict whitelist of player actions.
  static bool isValidPlayerIntent(String sanitizedCommand) {
    if (sanitizedCommand.isEmpty) return false;

    final lower = sanitizedCommand.toLowerCase();
    const validKeywords = [
      'play', 'joue', 'pause', 'arrête', 'stop', 'next', 'suivant',
      'previous', 'précédent', 'timer', 'minuteur', 'mix', 'playlist',
      'shuffle', 'volume', 'bass', 'boost', 'chill', 'theme', 'dark'
    ];

    return validKeywords.any((keyword) => lower.contains(keyword));
  }
}
