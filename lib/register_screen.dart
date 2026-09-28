import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Funcție de notificare Push către profesori pentru cont nou
  Future<void> _notifyTeacherAboutNewUser({
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "be2af79dfbe281af83316b25ea293ebfc1beee3a",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/GHpRVvpGCezi\nK33vzeOvzPaVcNL/+U0wrAcyLDQGlaDnY/k/mjeq6XMr0l+IAapukBaI/cFUsx1r\npTnIByGyMJ6ibS9ywHygjk0imuKOtSioiFsxCa7w9cOJe8tHyugIjQWm6vELqGAk\njt9GNy1uIODZVpmeF4qyhBFcCXnbOZFLkKeNKx4V9xQcpZ7gyjvVUuDWnuPT9sLv\n5zwvi+OgBJOiksSZ03ShGgDMKwe+mnfRm/VtzfABlEdaf+hnnEsnVWm22/TVrHEk\nkZMlDH/QFh77Mf3l0bY0I5VhUfG5O/2/R+Z6X8ZWyZo+D9BF2eb2Lr71gP4FBoL/\nxCK64kEhAgMBAAECggEAApHLIl5qQRhk2SKUWpiQBU8FrOXaB5Q2skYRcyWXdQz8\ndMcqIu2UCrYsOGOgVBuCg/D2DJxmqW4esCdNJ3yeZULfNk11w/shgBefFMm0l0dQ\nisDtSd5KduenFOJJI1mojbsaX1pQtsNN1PqtsNN1Pqtfh2nJ0kpOUZ4RTZ7KGXJjKK2NKPY\n/6WFYPpAwpr0h5utvqmVgRvkZ/SZm4dDF2q8v/S+b//Ws1Vd5T4Ng4k/aUDontpT\nwxT3Riy0O3dDO8DETM/jj5FMKNpVByM4ZfbN7fYEz9qeR9x4KdFWSo6L+a5E4PZv\nF+xvLqRcFiLqrcnXiCCViGde13KjqAr0UNmkQC+EDQKBgQDwjs/phhcMuFmEySi3\nK5LT0/6t9R4ii0nC9Uu4NaY9WiNlKAoy9Ne3whl9zOGzmRY+Fe9DAmGPFg1cWyRo\nGyUbuI2w/3fM8Hx3Fix+pT+mGNjn2K0pdy87NtAlTtjyrmWkOfPm+fOdVnBi6+Ml\nugFGxBwBkJ6q6ff0b5fGN4RyRwKBgQDLXNT5NeRnfkyhh2VFifb2YKkzFiWyCyBg\nZBQXaojMoTY5ueBdPbUecGN+G07aRJ2kx08uCY/EQYCEccjHyeB3R+0EjyiaxEnF\n33//tywzxvZ8jjUo2oZuXgO3iPXQ0SEnnIMYAtTJ7SyYsZl7Ala9SC4CIqNiPWKR\n+hdRnve9VwKBgGbeGyiYT5j/6D/xKXkSqAnvWLQY4pcRCyzUalnOj1UjC4nBUoMx\n0mFhHjd+enGroChShusXxJJEctgwnWPrX7X3+Jdc12UK3Z6rG8HYdlxXucGDFaFq\ntwbSTLX3fqxgSVSt94+pCTUZ9ptGle7XGJ6jU/qTVlZuELs1USjRKtEXAoGBAMNF\nG1dEsVHTC6Aa01pndJT1EeL1BDMmzergjg5CBKOAtQHPAqplg1F8F3zSme+p7Tl5\nDAWntr17K/2BCIsWxIukq+kx0YpyqmfvCQgxCaeaB7poDpFw6550dds5Dth4xv4z\nIgnfRhWywJzKBBcCkuljspHoUrwVN132J4f/PeE3AoGBAMO918DIrrHdGyaHSA0E\nK0gEY2dMUuAmaMeDEFtVHoZtugUUC6ZFMOgP4fQIjPnL52igeW6IUs96du2d+GIC\nqdlMb7Tp/lTxvaRGqUcAVhYbYaawonFK7QU8kNygU1IqWljXa+S+nR1O/tCmG2/n\n34ZJZ4VSGVZ/GX9IToAU297e\n-----END PRIVATE KEY-----\n",
          "client_email":
              "firebase-adminsdk-fbsvc@level-up-19583.iam.gserviceaccount.com",
          "client_id": "112777526185284576732",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40level-up-19583.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com",
        },
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        serviceAccountCredentials,
        scopes,
      );

      // Căutăm profesorii din Firestore
      final teachersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'Teacher'])
          .get();

      debugPrint(
        "🔍 Profesori găsiți la înregistrare: ${teachersDocs.docs.length}",
      );

      if (teachersDocs.docs.isEmpty) {
        debugPrint(
          "⚠️ Nu s-a găsit niciun profesor cu role == 'teacher' în Firestore!",
        );
        client.close();
        return;
      }

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

      for (var teacherDoc in teachersDocs.docs) {
        var tData = teacherDoc.data();
        String? teacherFcmToken = tData['fcmToken'];
        String teacherId = teacherDoc.id;

        debugPrint(
          "👨‍🏫 Profesor ID: $teacherId | FCM Token: $teacherFcmToken",
        );

        // 1. Salvare notificare in-app
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': '👤 Cont nou creat!',
          'body':
              '$studentName ($studentEmail) a creat un cont și așteaptă aprobarea.',
          'isRead': false,
          'type': 'user_registration',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Calculare badge necitit
        final unreadSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: teacherId)
            .where('isRead', isEqualTo: false)
            .get();
        int unreadCount = unreadSnap.docs.length;

        // 3. Trimitere Push Notification
        if (teacherFcmToken != null && teacherFcmToken.isNotEmpty) {
          final res = await client.post(
            Uri.parse(fcmV1Url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': {
                'token': teacherFcmToken,
                'notification': {
                  'title': '👤 Cont nou creat!',
                  'body':
                      '$studentName ($studentEmail) dorește aprobarea contului.',
                },
                'android': {
                  'priority': 'HIGH',
                  'notification': {'sound': 'default'},
                },
                'apns': {
                  'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
                  'payload': {
                    'aps': {'sound': 'default', 'badge': unreadCount},
                  },
                },
                'data': {
                  'type': 'user_registration',
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
              },
            }),
          );
          debugPrint(
            "🚀 Trimis notificare profesor pentru cont nou! Response status: ${res.statusCode}",
          );
        } else {
          debugPrint(
            "❌ Profesorul $teacherId NU are câmpul fcmToken salvat în Firestore!",
          );
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la notificarea profesorului pentru cont nou: $e");
    }
  }

  Future<void> _handleRegister() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completează toate câmpurile.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Salvare utilizator nou în Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'fullName': name,
              'email': email,
              'role': 'student',
              'hasAccess': false, // Așteaptă aprobarea
              'createdAt': FieldValue.serverTimestamp(),
            });

        // TRIMITERE NOTIFICARE PUSH CĂTRE PROFESORI
        await _notifyTeacherAboutNewUser(
          studentName: name,
          studentEmail: email,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cont creat cu succes! Așteaptă aprobarea profesorului.',
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare la înregistrare: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Înregistrare Elev'),
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nume Complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Parolă',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff42153e),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Creează Cont'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
