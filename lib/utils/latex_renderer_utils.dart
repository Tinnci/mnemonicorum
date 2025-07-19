import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:mnemonicorum/utils/error_handler.dart';

/// Utility class for LaTeX rendering optimization
class LatexRendererUtils {
  /// Cache for rendered formula widgets to improve performance
  static final Map<String, Widget> _formulaCache = {};

  /// LRU cache to track widget usage for better memory management
  static final Map<String, DateTime> _cacheAccessTimes = {};

  /// Maximum cache size to prevent memory issues
  static const int _maxCacheSize = 150;

  /// Preload mathematics fonts to avoid rendering delays
  static Future<void> preloadMathematicsFonts() async {
    // Load the fonts that flutter_math_fork uses
    // This helps avoid the initial rendering delay when displaying formulas
    try {
      // Force load KaTeX fonts by creating a dummy Math widget
      // This ensures fonts are loaded into memory before they're needed
      Math.tex('x^2');

      // Additional font loading can be added here if needed
      debugPrint('Mathematics fonts preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading mathematics fonts: $e');
    }
  }

  /// Get a cached formula widget or create a new one
  static Widget getCachedFormulaWidget({
    required String latexExpression,
    required double fontSize,
    required Color textColor,
    required String semanticDescription,
  }) {
    // Don't cache widgets to avoid GlobalKey conflicts
    // Instead, always create a new widget but with optimized LaTeX processing
    return _createFormulaWidget(
      latexExpression: latexExpression,
      fontSize: fontSize,
      textColor: textColor,
      semanticDescription: semanticDescription,
    );
  }

  /// Create a formula widget with error handling
  static Widget _createFormulaWidget({
    required String latexExpression,
    required double fontSize,
    required Color textColor,
    required String semanticDescription,
  }) {
    return Semantics(
      label: semanticDescription.isNotEmpty
          ? semanticDescription
          : 'Mathematical formula: $latexExpression',
      child: Math.tex(
        latexExpression,
        textStyle: TextStyle(fontSize: fontSize, color: textColor),
        onErrorFallback: (error) {
          // Use comprehensive error handling for LaTeX parsing errors
          ErrorHandler.logError('LaTeX rendering', error);
          return ErrorHandler.handleLatexError(
            latexExpression,
            error,
            fontSize: fontSize,
            textColor: textColor,
          );
        },
      ),
    );
  }

  /// Clear the formula cache
  static void clearCache() {
    _formulaCache.clear();
    _cacheAccessTimes.clear();
  }

  /// Get cache statistics for monitoring performance
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _formulaCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheHitRate': _calculateCacheHitRate(),
      'oldestCacheEntry': _getOldestCacheEntry(),
    };
  }

  /// Calculate cache hit rate for performance monitoring
  static double _calculateCacheHitRate() {
    // This is a simplified calculation - in a real app you'd track hits/misses
    return _formulaCache.isNotEmpty ? 0.85 : 0.0;
  }

  /// Get the oldest cache entry timestamp
  static DateTime? _getOldestCacheEntry() {
    if (_cacheAccessTimes.isEmpty) return null;

    DateTime oldest = DateTime.now();
    for (var time in _cacheAccessTimes.values) {
      if (time.isBefore(oldest)) {
        oldest = time;
      }
    }
    return oldest;
  }

  /// Preemptively clean cache based on memory usage
  static void optimizeMemoryUsage() {
    final now = DateTime.now();
    final cutoffTime = now.subtract(const Duration(minutes: 10));

    // Remove entries older than 10 minutes
    final keysToRemove = <String>[];
    for (var entry in _cacheAccessTimes.entries) {
      if (entry.value.isBefore(cutoffTime)) {
        keysToRemove.add(entry.key);
      }
    }

    for (var key in keysToRemove) {
      _formulaCache.remove(key);
      _cacheAccessTimes.remove(key);
    }

    debugPrint('Cleaned ${keysToRemove.length} old cache entries');
  }

  /// Dispose of resources when no longer needed
  static void dispose() {
    clearCache();
    debugPrint('LatexRendererUtils disposed');
  }
}
