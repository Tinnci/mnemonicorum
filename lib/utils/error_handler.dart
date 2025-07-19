import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

/// Comprehensive error handling utility for the math formula app
class ErrorHandler {
  static const String _logTag = 'MathFormulaApp';

  /// Handle LaTeX parsing errors with graceful recovery
  static Widget handleLatexError(
    String latexExpression,
    dynamic error, {
    double fontSize = 16,
    Color textColor = Colors.black,
  }) {
    debugPrint('$_logTag: LaTeX parsing error for "$latexExpression": $error');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange.shade700,
                size: fontSize * 0.8,
              ),
              const SizedBox(width: 4),
              Text(
                'Formula rendering error',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: fontSize * 0.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            latexExpression,
            style: TextStyle(
              color: textColor.withAlpha((0.8 * 255).round()),
              fontSize: fontSize * 0.9,
              fontStyle: FontStyle.italic,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to retry',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: fontSize * 0.6,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle data loading errors with retry mechanism
  static Future<T?> handleDataLoadingError<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool showUserMessage = true,
    BuildContext? context,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint(
          '$_logTag: Attempting $operationName (attempt $attempts/$maxRetries)',
        );

        final result = await operation();

        if (attempts > 1) {
          debugPrint(
            '$_logTag: $operationName succeeded after $attempts attempts',
          );
        }

        return result;
      } catch (error) {
        debugPrint(
          '$_logTag: $operationName failed (attempt $attempts/$maxRetries): $error',
        );

        if (attempts >= maxRetries) {
          // Final attempt failed
          if (showUserMessage && context != null && context.mounted) {
            _showErrorSnackBar(
              context,
              _getErrorMessage(error, operationName),
              canRetry: true,
              onRetry: () => handleDataLoadingError(
                operation,
                operationName,
                maxRetries: maxRetries,
                retryDelay: retryDelay,
                showUserMessage: false,
                context: context,
              ),
            );
          }
          return null;
        }

        // Wait before retrying
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    return null;
  }

  /// Handle network-related errors
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    } else {
      return 'Network error occurred. Please try again.';
    }
  }

  /// Handle file system errors
  static String handleFileSystemError(dynamic error) {
    if (error is FileSystemException) {
      return 'File access error. Please check app permissions.';
    } else if (error is FormatException) {
      return 'Invalid file format. Please check the data files.';
    } else {
      return 'File system error occurred. Please restart the app.';
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error, String operationName) {
    if (error is SocketException || error is TimeoutException) {
      return handleNetworkError(error);
    } else if (error is FileSystemException || error is FormatException) {
      return handleFileSystemError(error);
    } else {
      return 'Failed to $operationName. Please try again.';
    }
  }

  /// Show error snackbar with retry option
  static void _showErrorSnackBar(
    BuildContext context,
    String message, {
    bool canRetry = false,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: canRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    bool canRetry = false,
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            if (canRetry && onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Log error for debugging purposes
  static void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    debugPrint('$_logTag ERROR: $operation');
    debugPrint('Error: $error');

    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    if (additionalInfo != null) {
      debugPrint('Additional info: $additionalInfo');
    }
  }

  /// Handle formula repository errors
  static Future<T?> handleRepositoryError<T>(
    Future<T> Function() operation,
    String operationName, {
    BuildContext? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(operationName, error, stackTrace: stackTrace);

      if (context != null && context.mounted) {
        _showErrorSnackBar(
          context,
          _getErrorMessage(error, operationName),
          canRetry: true,
          onRetry: () =>
              handleRepositoryError(operation, operationName, context: context),
        );
      }

      return null;
    }
  }

  /// Handle exercise generation errors
  static T? handleExerciseError<T>(
    T Function() operation,
    String operationName, {
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      logError(operationName, error, stackTrace: stackTrace);
      return fallbackValue;
    }
  }

  /// Handle progress tracking errors
  static Future<bool> handleProgressError(
    Future<void> Function() operation,
    String operationName, {
    BuildContext? context,
  }) async {
    try {
      await operation();
      return true;
    } catch (error, stackTrace) {
      logError(operationName, error, stackTrace: stackTrace);

      if (context != null && context.mounted) {
        _showErrorSnackBar(
          context,
          'Failed to save progress. Your progress may not be saved.',
        );
      }

      return false;
    }
  }

  /// Create error boundary widget for catching widget errors
  static Widget errorBoundary({
    required Widget child,
    Widget? fallback,
    String? errorMessage,
  }) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          logError('Widget rendering', error, stackTrace: stackTrace);

          return fallback ??
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage ?? 'Something went wrong',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please restart the app if the problem persists.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }
      },
    );
  }
}

/// Custom exception classes for better error handling
class FormulaLoadingException implements Exception {
  final String message;
  final dynamic originalError;

  const FormulaLoadingException(this.message, [this.originalError]);

  @override
  String toString() => 'FormulaLoadingException: $message';
}

class ExerciseGenerationException implements Exception {
  final String message;
  final String? formulaId;

  const ExerciseGenerationException(this.message, [this.formulaId]);

  @override
  String toString() => 'ExerciseGenerationException: $message';
}

class ProgressSaveException implements Exception {
  final String message;
  final Map<String, dynamic>? progressData;

  const ProgressSaveException(this.message, [this.progressData]);

  @override
  String toString() => 'ProgressSaveException: $message';
}
