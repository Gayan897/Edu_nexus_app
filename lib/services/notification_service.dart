import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firebase_options.dart';
import '../models/models.dart';
import '../utils/app_logger.dart';

/// Top-level background message handler for Firebase Messaging.
/// Must be outside any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}

  AppLogger.auth('FCM Background Message received', data: message.data.toString());
  await NotificationService.showRemoteMessage(message);
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'sams_attendance_channel';
  static const String channelName = 'Attendance & Academic Alerts';
  static const String channelDesc =
      'Real-time alerts when teachers record attendance, absence, or late arrivals';

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  String? _activeStudentId;
  String? get activeStudentId => _activeStudentId;

  /// Stream controller for notification taps that UI screens can listen to.
  final StreamController<Map<String, dynamic>> _onNotificationClickController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationClick =>
      _onNotificationClickController.stream;

  /// Initialize Local Notifications & FCM listeners
  Future<void> init() async {
    if (_initialized) return;

    // Load active student ID from local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeStudentId = prefs.getString('active_student_id');
    } catch (_) {}

    // 1. Initialize Flutter Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifs.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _onNotificationClickController.add(data);
          } catch (_) {
            _onNotificationClickController.add({'payload': response.payload});
          }
        }
      },
    );

    // 2. Create High-Priority Android Notification Channel
    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      showBadge: true,
    );

    final androidPlugin = _localNotifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }

    // 3. Foreground FCM message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.auth('FCM Foreground message received',
          data: message.notification?.title ?? message.data.toString());
      showRemoteMessage(message);
    });

    // 4. App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.auth('App opened from notification tap', data: message.data.toString());
      _onNotificationClickController.add(message.data);
    });

    // 5. App opened from terminated state via notification tap
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.auth('App launched from terminated notification',
          data: initialMessage.data.toString());
      _onNotificationClickController.add(initialMessage.data);
    }

    _initialized = true;
    AppLogger.db('NotificationService initialized successfully',
        collection: 'notifications', action: 'init');
  }

  /// Request permissions for system notifications (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    try {
      // FCM permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      // Android 13+ POST_NOTIFICATIONS permission
      final androidPlugin = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      bool? androidGranted = true;
      if (androidPlugin != null) {
        androidGranted = await androidPlugin.requestNotificationsPermission();
      }

      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional ||
          (androidGranted ?? false);

      AppLogger.auth('Notification permission status', data: 'granted=$granted');
      return granted;
    } catch (e) {
      AppLogger.error('Failed to request notification permission', error: e);
      return false;
    }
  }

  /// Register current user / student with FCM and Firestore
  Future<void> registerUser({
    required String studentId,
    String? parentPhone,
    required String userId,
  }) async {
    try {
      await requestPermissions();

      // Fetch FCM Token
      _fcmToken = await _fcm.getToken();
      if (_fcmToken == null) {
        AppLogger.warning('Unable to get FCM token on this device');
        return;
      }

      AppLogger.auth('FCM Device Token retrieved', data: _fcmToken);

      // Clean topic identifiers (FCM topics only allow [a-zA-Z0-9-_.~%])
      final cleanSid = studentId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

      // Store and persist active student ID
      _activeStudentId = studentId.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_student_id', _activeStudentId!);

      // If a previous student was subscribed on this device, unsubscribe first
      final prevSid = prefs.getString('subscribed_student_id');
      if (prevSid != null && prevSid.isNotEmpty && prevSid != cleanSid) {
        await _fcm.unsubscribeFromTopic('student_$prevSid');
        AppLogger.auth('Unsubscribed from previous student topic', data: 'student_$prevSid');
      }

      // 1. Subscribe ONLY to this parent's specific student topic
      if (cleanSid.isNotEmpty) {
        await _fcm.subscribeToTopic('student_$cleanSid');
        await prefs.setString('subscribed_student_id', cleanSid);
        AppLogger.auth('Subscribed to FCM student topic', data: 'student_$cleanSid');
      }

      // 2. Persist token in Firestore
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // In users collection
      if (userId.isNotEmpty) {
        final userDoc = db.collection('users').doc(userId);
        batch.set(userDoc, {
          'fcmToken': _fcmToken,
          'fcmTokens': FieldValue.arrayUnion([_fcmToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // In students collection
      if (studentId.isNotEmpty) {
        final stuDoc = db.collection('students').doc(studentId);
        batch.set(stuDoc, {
          'fcmTokens': FieldValue.arrayUnion([_fcmToken]),
          'parentFcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // In dedicated device_tokens collection for fast server-side lookups
      final tokenDoc = db.collection('fcm_tokens').doc(_fcmToken);
      batch.set(tokenDoc, {
        'token': _fcmToken,
        'userId': userId,
        'studentId': studentId,
        'parentPhone': parentPhone,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      AppLogger.db('FCM token registered in Firestore',
          collection: 'fcm_tokens', action: 'save');

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerUser(
          studentId: studentId,
          parentPhone: parentPhone,
          userId: userId,
        );
      });
    } catch (e, st) {
      AppLogger.error('Failed to register user for FCM notifications',
          error: e, stackTrace: st);
    }
  }

  /// Unsubscribe and clear user registration on logout
  Future<void> unregisterUser({
    required String studentId,
    String? parentPhone,
  }) async {
    try {
      final cleanSid = studentId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

      if (cleanSid.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('student_$cleanSid');
      }

      final prefs = await SharedPreferences.getInstance();
      final prevSid = prefs.getString('subscribed_student_id');
      if (prevSid != null && prevSid.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('student_$prevSid');
      }
      await prefs.remove('active_student_id');
      await prefs.remove('subscribed_student_id');
      _activeStudentId = null;

      AppLogger.auth('Unsubscribed from student FCM topic on logout');
    } catch (e) {
      AppLogger.error('Failed to unregister FCM topics', error: e);
    }
  }

  /// Show a real native Android/iOS system notification in the notification bar
  Future<void> showAttendanceNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payloadData,
    AttendanceStatus? status,
    bool isUrgent = false,
  }) async {
    final int notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'SAMS Attendance Alert',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'EduNexus SAMS',
      ),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(
        isUrgent ? [0, 400, 200, 400, 200, 400] : [0, 250, 150, 250],
      ),
      color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF1E3A8A),
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadStr = payloadData != null ? jsonEncode(payloadData) : null;

    await _localNotifs.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payloadStr,
    );

    AppLogger.auth('Real system notification displayed', data: title);
  }

  /// Render an incoming FCM RemoteMessage as a system notification
  static Future<void> showRemoteMessage(RemoteMessage message) async {
    // STRICT STUDENT FILTER: If notification is for a different student, suppress it!
    final msgStudentId = (message.data['studentId'] ?? '').toString().trim().toLowerCase();

    final prefs = await SharedPreferences.getInstance();
    final activeSid = (instance._activeStudentId ?? prefs.getString('active_student_id') ?? '')
        .trim()
        .toLowerCase();

    if (msgStudentId.isNotEmpty && activeSid.isNotEmpty && msgStudentId != activeSid) {
      AppLogger.auth('Suppressed push notification meant for another student',
          data: 'msgStudent=$msgStudentId, activeStudent=$activeSid');
      return; // Do NOT show alert for another student!
    }

    final title = message.notification?.title ??
        message.data['title'] ??
        '🚨 Attendance Update';
    final body = message.notification?.body ??
        message.data['message'] ??
        message.data['body'] ??
        'New attendance update received from school';

    final statusStr = message.data['status']?.toString().toLowerCase();
    final isUrgent = statusStr == 'absent' ||
        message.data['priority'] == 'urgent' ||
        title.contains('ABSENT');

    await instance.showAttendanceNotification(
      title: title,
      body: body,
      payloadData: message.data,
      isUrgent: isUrgent,
    );
  }

  /// Send a real test notification to verify device status bar display
  Future<void> sendTestNotification({String studentName = 'Kasun Perera'}) async {
    await requestPermissions();
    await showAttendanceNotification(
      title: '🚨 ABSENT ALERT: $studentName',
      body: 'URGENT: $studentName was marked ABSENT for school today. Please verify with school if unexcused.',
      isUrgent: true,
      payloadData: {
        'type': 'attendance',
        'status': 'absent',
        'studentName': studentName,
        'date': DateTime.now().toString().split(' ').first,
      },
    );
  }
}
