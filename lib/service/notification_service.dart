import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService.internal();
  factory NotificationService() => instance;
  NotificationService.internal();

  final FirebaseMessaging fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  final db = FirestoreService.instance.db;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'service_request_channel',
      'Service Requests',
      description: 'Notifications for service request updates',
      importance: Importance.high,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation< 
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // Background messages
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpenedApp);

    // Get FCM token and save to Firestore
    await saveTokenToFirestore();
    fcm.onTokenRefresh.listen(saveTokenToFirestore);
  }

  Future<void> saveTokenToFirestore([String? token]) async {
    try {
      token ??= await fcm.getToken();
      if (token != null) {
        final userID = FirebaseAuth.instance.currentUser?.uid;
        if (userID != null) {
          await db.collection('User').doc(userID).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': DateTime.now(),
          });
          print('FCM token saved to Firestore');
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'service_request_channel',
            'Service Requests',
            channelDescription: 'Notifications for service request updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void handleMessageOpenedApp(RemoteMessage message) {
    print('Notification opened app: ${message.notification?.title}');
    // Handle navigation based on message.data
  }

  void onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }
}

// Background message handler 
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}