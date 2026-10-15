import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import 'login_screen.dart';
import 'main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _childEmailController = TextEditingController();
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

      // 2. Salvare profil în Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': name,
        'email': email,
        'role': _selectedRole,
        'childEmail': _selectedRole == 'parent'
            ? _childEmailController.text.trim()
            : null,
        'hasAccess': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Trimitem notificarea și push-ul către profesor
      await _notifyTeacherAboutNewUser(rawName: name, userRole: _selectedRole);

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
    required String userRole,
  }) async {
    try {
      String formattedName = userRole == 'parent' || userRole == 'parinte'
          ? 'Părintele $rawName'
          : 'Elevul $rawName';

      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\nSwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\nUGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\nSFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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

        var pendingUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('hasAccess', isEqualTo: false)
            .get();

        var pendingEnrollments = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('status', isEqualTo: 'pending')
            .get();

        int unreadCount =
            pendingUsers.docs.length + pendingEnrollments.docs.length;

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
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la notificarea profesorului pentru cont nou: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Stack(
        children: [
          // 1. Elemente decorative matematice de fundal (la fel ca la Login)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff7c4dff).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff7c4dff).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: 80,
            child: Text(
              "π",
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: const Color(0xff7c4dff).withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 60,
            child: Text(
              "√x",
              style: TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.bold,
                color: const Color(0xff7c4dff).withOpacity(0.03),
              ),
            ),
          ),

          // 2. Conținutul principal
          Column(
            children: [
              // Bara de sus (Header identic cu Login)
              Container(
                color: primaryIndigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'images/logo.jpg',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LEVEL UP",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "YOUR GRADES",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Corpul ecranului cu formularul de înregistrare centrat
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          margin: const EdgeInsets.only(top: 35),
                          padding: const EdgeInsets.fromLTRB(32, 50, 32, 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryIndigo.withOpacity(0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
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
                                  fontWeight: FontWeight.w900,
                                  color: primaryIndigo,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Completează datele pentru a începe.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'student',
                                    label: Text('Elev'),
                                    icon: Icon(Icons.school_outlined),
                                  ),
                                  ButtonSegment(
                                    value: 'teacher',
                                    label: Text('Profesor'),
                                    icon: Icon(Icons.person_outline),
                                  ),
                                  ButtonSegment(
                                    value: 'parent',
                                    label: Text('Părinte'),
                                    icon: Icon(Icons.family_restroom),
                                  ),
                                ],
                                selected: {_selectedRole},
                                onSelectionChanged: (newSelection) => setState(
                                  () => _selectedRole = newSelection.first,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_selectedRole == 'parent') ...[
                                TextField(
                                  controller: _childEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Adresa de email a copilului',
                                    prefixIcon: const Icon(
                                      Icons.mark_email_read_outlined,
                                      color: primaryIndigo,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nume și Prenume',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: primaryIndigo,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Adresă de Email',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: primaryIndigo,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Parolă',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: primaryIndigo,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirmă Parola',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset,
                                    color: primaryIndigo,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryIndigo,
                                      ),
                                    )
                                  : SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryIndigo,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
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
                              const SizedBox(height: 16),
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
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Autentifică-te",
                                      style: TextStyle(
                                        color: primaryIndigo,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Iconița rotundă plutitoare din partea de sus a cardului (exact ca la Login)
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryIndigo,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryIndigo.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
