import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import 'login_screen.dart';
//import 'package0:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'student';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Te rugăm să completezi toate câmpurile!');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Parolele introduse nu se potrivesc!');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Parola trebuie să aibă cel puțin 6 caractere!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Creare cont în Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 2. Salvare profil în Firestore (Implicit FĂRĂ ACCES 'hasAccess: false')
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': name,
        'email': email,
        'role': _selectedRole,
        'hasAccess': false, // Se aprobă manual din consola Firebase sau din panoul profesorului
        'createdAt': FieldValue.serverTimestamp(),
      });
      _notifyTeacherAboutNewUser(rawName: name, userRole: _selectedRole);
      if (!mounted) return;

      // Intrarea în aplicație
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'A apărut o eroare la înregistrare.');
    } catch (e) {
      _showSnackBar('Eroare: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _notifyTeacherAboutNewUser({
    required String rawName,
    required String userRole, // 'student' sau 'parent'
  }) async {
    try {
      // Formatăm denumirea în funcție de rol
      String formattedName = userRole == 'parent' || userRole == 'parinte'
          ? 'Părintele $rawName'
          : 'Elevul $rawName';

      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\nSwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\n/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\nFQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\nUGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\nSFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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

      final teachersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'Teacher'])
          .get();

      if (teachersDocs.docs.isEmpty) {
        client.close();
        return;
      }

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

      String pushTitle = '👤 Cont nou creat!';
      String pushBody = '$formattedName a creat un cont și așteaptă aprobarea.';

      for (var teacherDoc in teachersDocs.docs) {
        var tData = teacherDoc.data();
        String? teacherFcmToken = tData['fcmToken'];
        String teacherId = teacherDoc.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': pushTitle,
          'body': pushBody,
          'isRead': false,
          'type': 'user_registration',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final unreadSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: teacherId)
            .where('isRead', isEqualTo: false)
            .get();
        int unreadCount = unreadSnap.docs.length;

        if (teacherFcmToken != null && teacherFcmToken.isNotEmpty) {
          await client.post(
            Uri.parse(fcmV1Url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': {
                'token': teacherFcmToken,
                'notification': {'title': pushTitle, 'body': pushBody},
                'android': {
                  'priority': 'HIGH',
                  'notification': {
                    'sound': 'default',
                    'icon': '@images/fundal.jpeg',
                  },
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
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la notificarea profesorului pentru cont nou: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff42153e),
        toolbarHeight: 85,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'images/logo.jpg',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LEVEL UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "YOUR GRADES",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff42153e).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Creează un Cont Nou",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff42153e),
                  ),
                ),
                const SizedBox(height: 20), // Spațiu sub titlu

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'student',
                      label: Text('Sunt Elev'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: 'teacher',
                      label: Text('Sunt Profesor'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (newSelection) =>
                      setState(() => _selectedRole = newSelection.first),
                ),
                const SizedBox(height: 20), // Spațiu sub selectorul de rol

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nume și Prenume',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Spațiu între Nume și Email

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Adresă de Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Spațiu între Email și Parolă

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Parolă',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xff42153e),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ), // Spațiu între Parolă și Confirmare Parolă

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmă Parola',
                    prefixIcon: const Icon(
                      Icons.lock_reset,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 28), // Spațiu înainte de buton

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff42153e),
                        ),
                      )
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff42153e),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Creează Contul',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                // --- AICI PUI NOUL SIZEDBOX ȘI ROW-UL PENTRU LOGIN ---
                const SizedBox(
                  height: 16,
                ), // Spațiu între Buton și textul de Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Ai deja un cont?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Autentifică-te",
                        style: TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
