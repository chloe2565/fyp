import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'firestore_service.dart';

class FCMService {
  final db = FirestoreService.instance.db;
  static const String _projectId = 'handymanfyp-51049';
  static const String _fcmScope =
      'https://www.googleapis.com/auth/firebase.messaging';

  static const Map<String, dynamic> _serviceAccountJson = {
    "type": "service_account",
    "project_id": "handymanfyp-51049",
    "private_key_id": "fb0cf971e4472f03ecdf2c9bad1dfb327d1e2461",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDPqYV42bZ8NGnL\nynPfRCo+uYb4qSH9pXG94n1MW/Dx1TeqH+ICAGEFZZl6SSn9PkB58zz08PD+5emN\nszDDeNynZikbPschD30KaE0OqkYS8QT4KZNqa30rBeGASF4koj//p6IAOI+qf++y\nVeSnp6OOyRGJl+l2P9u1Q2EqWTrIXVM1F/PQ6yQW/pcjJBTn2AJQTT0/0PlvrWY/\nrB0gVArGxEdSpuFNwLJBT+xJxLikMq6HKZoWaD015eY2DEeBrCHJUALkcCmBqHYZ\nlHjDScJ9Xu3H+Wsto7jsHIAt16TJdsHa8A2vh+FthhXztyLVX0E4bJWniyG9rV3W\nHzdhXoj/AgMBAAECggEAAzR/Gl/l2KHodhxAUJRZQJGVezYFD8ijakZaH7kVjW34\nh3gpgVVnKfGo/kGt07pHvXobGT60wYJj6et3l7TAVxcVEFYWNbTq/aOheNX48ebl\naD0gCNby3hyfn96+ETut2DDKp803rm5+ERcRSeMk+5mv2xtMn6YZqoEJOWGaLih3\ndIpLlsNf894e9z/e+hnWjXj8paDJjF5vnPtlJnzH5OlE+1B/Vx3GIYnqWOHVZcPo\nGriJRhny4gEM4GCBhs6jMy53QAp452AX9+oozWsKJE/y2/HOyF6zU9c8qKJKl19D\nB0x0qOeykaruNWTRrsYtNQSwOT8IoniMbXW1Zupc3QKBgQD0uExqnGKbO+CcjOXr\ndhcTVKV+BE9HIl1A07q6NAdCUPwI0q+uOr9FedpJso6r7WHTnnx07F1YU5wBBy7/\nGrOplNeDe4Kj3Qb03fWnbwIf2bQ1EEBSUSQPXMqgcgMRD/wmgQUfiCMWsywoDleN\nc4/jmaAaO4QAQfnWXAeY/GEMUwKBgQDZO/DVfzQzgN9BO0xndVf9NDXz+PXyS0rV\n+OlhbyojxtsgXGluJFAzH0USILgxg3z9K5U6xMAcMifCJgk330XpwusJuLij7QPe\nnuz3pxR+/b5rTJ+7C/ULv4RdjUZIpGIVEmyFyiqWf8LdviMzyuC1A22jjZ+luKZE\niFt7T2kbJQKBgA7hWfwtkC1iQbEjPCPKJXMOdZWpC20G4Oa9OSBzY3Gb3QdoUDhm\n6BSAaU6L5fL8VzN38pdle/OP+e9yEWB/ricEnuomy3XNTcv75yEMNfPb2AJV/6NB\nvdCVUtjYtekGsM1ikP4u1/tcX7X70UUPntM3Fy4hKlCdsmRfajLaPchzAoGBALFp\nXafPCj/hyPMKTbzUvbaBtGp68coeqZCUh21Wj1DGr+D+9+/G4mTN7ef/Js7xNtvA\ng1CKrOaaI5RQ4ghqZTujP7ch0FG4WQewPZGIN5n6+0/ANVdaTZd5os2Qek0LSzsw\nX8boM93Tm77i8Pb0go3yrdD78d0zLz8bKbNMSGetAoGAXh7W3/FZ7Qjw77Gq4Akf\nGhTY3I+tkEaCKRN387/5N0DV3Z5Pyb8PDfwm/KCtGijM2CrRz2IXKPSuAQ3ZmywE\nLK4w/o5EPMNzHFQolsw0Qe8ULwLFnw00xxT+QOmngmqV1j20dDKD/pz0MD0sOKdL\nF2OzXMAMkt48dHaK4NhiE+0=\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@handymanfyp-51049.iam.gserviceaccount.com",
    "client_id": "100158675559078274040",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40handymanfyp-51049.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  // Get access token for FCM
  Future<String> _getAccessToken() async {
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(
      _serviceAccountJson,
    );

    final authClient = await auth.clientViaServiceAccount(accountCredentials, [
      _fcmScope,
    ]);

    final accessToken = authClient.credentials.accessToken.data;
    authClient.close();

    return accessToken;
  }

  // Send notification to a specific user
  Future<bool> sendNotificationToUser({
    required String userID,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await db.collection('User').doc(userID).get();

      if (!userDoc.exists) {
        print('User not found: $userID');
        return false;
      }

      final fcmToken = userDoc.data()?['fcmToken']?.toString();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('No FCM token found for user: $userID');
        return false;
      }

      return await sendNotification(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error sending notification to user: $e');
      return false;
    }
  }

  // Send FCM notification
  Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'token': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'service_request_channel',
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1},
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      return false;
    }
  }
}
