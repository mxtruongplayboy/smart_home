import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_home/firebase_options.dart';

// Global declaration of the notification channel and its state.
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool isFlutterLocalNotificationsInitialized = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await _ensureNotificationSetup();
  // _showNotification(message);
}

Future<void> _ensureNotificationSetup() async {
  if (isFlutterLocalNotificationsInitialized) return;

  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  isFlutterLocalNotificationsInitialized = true;
}

void _showNotification(RemoteMessage message) {
  if (!kIsWeb) {
    // Cấu hình cho Android
    var androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      icon: '@mipmap/ic_launcher',
      // largeIcon: message.data['title'] == "New Matches!"
      //     ? const DrawableResourceAndroidBitmap('live')
      //     : null,
      onlyAlertOnce: true,
      importance: channel.importance,
      priority: Priority.high,
      showWhen: true,
    );

    // Cấu hình cho iOS
    var iOSDetails = const DarwinNotificationDetails(
      presentAlert: true, // Hiển thị cảnh báo
      presentBadge: true, // Hiển thị biểu tượng số
      presentSound: true, // Phát âm thanh
      badgeNumber: null, // Số trên badge (nếu có)
      subtitle: 'Thông báo mới', // Tiêu đề phụ (nếu muốn)
      sound: 'default', // Âm thanh thông báo
    );

    // Tạo NotificationDetails cho cả hai nền tảng
    var notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    // Hiển thị thông báo
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.data['title'],
      message.data['body'],
      notificationDetails,
    );
  }
}

class FirebaseAPI {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await _ensureNotificationSetup();
    await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true);
    await _subscribeToTopics();
    _registerMessageHandlers();
    _firebaseMessaging.getToken().then((value) => print(value));
  }

  Future<void> _subscribeToTopics() async {
    const topics = ['SmartHome'];
    for (var topic in topics) {
      await _firebaseMessaging.subscribeToTopic(topic);
    }
  }

  void _registerMessageHandlers() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_foregroundMessageHandler);
  }

  Future<void> _foregroundMessageHandler(RemoteMessage message) async {
    await _ensureNotificationSetup();
    _showNotification(message);
  }
}
