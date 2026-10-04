import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { info, debug, auth, db, warning, error }

/// Structured logger for EduNexus Application.
/// Outputs formatted console logs with timestamps, log levels, and visual markers.
class AppLogger {
  static const bool _enabled = true;

  static void info(String message, {String tag = 'APP', Object? data}) {
    _log(LogLevel.info, tag, message, data: data);
  }

  static void auth(String message, {String? username, String? role, Object? data}) {
    final details = [
      if (username != null) 'user=$username',
      if (role != null) 'role=$role',
      if (data != null) 'data=$data',
    ].join(' | ');
    _log(LogLevel.auth, 'AUTH', '$message ${details.isNotEmpty ? "($details)" : ""}');
  }

  static void db(String message, {String? collection, String? action, Object? data}) {
    final details = [
      if (collection != null) 'collection=$collection',
      if (action != null) 'action=$action',
      if (data != null) 'data=$data',
    ].join(' | ');
    _log(LogLevel.db, 'FIRESTORE', '$message ${details.isNotEmpty ? "($details)" : ""}');
  }

  static void warning(String message, {String tag = 'APP', Object? error}) {
    _log(LogLevel.warning, tag, message, error: error);
  }

  static void error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    final String levelPrefix;
    switch (level) {
      case LogLevel.info:
        levelPrefix = 'ℹ️ [INFO]';
        break;
      case LogLevel.debug:
        levelPrefix = '🔍 [DEBUG]';
        break;
      case LogLevel.auth:
        levelPrefix = '🔐 [AUTH]';
        break;
      case LogLevel.db:
        levelPrefix = '🗄️ [DB]';
        break;
      case LogLevel.warning:
        levelPrefix = '⚠️ [WARN]';
        break;
      case LogLevel.error:
        levelPrefix = '❌ [ERROR]';
        break;
    }

    final formattedLog = '[$timeStr] $levelPrefix [$tag] $message'
        '${data != null ? "\n   📦 Data: $data" : ""}'
        '${error != null ? "\n   ❗ Error: $error" : ""}';

    if (kDebugMode) {
      debugPrint(formattedLog);
      if (stackTrace != null) {
        debugPrint('   📜 Stack: $stackTrace');
      }
    } else {
      dev.log(
        message,
        name: 'SAMS.$tag',
        time: now,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
