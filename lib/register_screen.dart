import 'dart:convert';
import 'dart:math';

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
  final TextEditingController _studentCodeController =
      TextEditingController(); // 🌟 Redenumit pentru codul unic
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'student';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String _generateStudentCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

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

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Te rugăm să introduci o adresă de email validă!');
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

    // Validare specială pentru Părinte (Verificare Cod Unic Elev)
    String? linkedChildEmail;
    if (_selectedRole == 'parent') {
      String codeInput = _studentCodeController.text.trim().toUpperCase();
      if (codeInput.isEmpty) {
        _showSnackBar('Te rugăm să introduci codul unic al elevului!');
        return;
      }

      // Căutăm elevul care deține acest cod unic în Firestore
      var studentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentCode', isEqualTo: codeInput)
          .where('role', isEqualTo: 'student')
          .get();

      if (studentQuery.docs.isEmpty) {
        _showSnackBar('Codul unic introdus nu este valid.');
        return;
      }

      // Preluăm emailul elevului asociat pentru a-l salva în contul părintelui (câmpul 'childEmail')
      var studentData = studentQuery.docs.first.data();
      String foundChildEmail = studentData['email'];

      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await userCredential.user?.sendEmailVerification();

        String uid = userCredential.user!.uid;
        String studentCode = _selectedRole == 'student'
            ? _generateStudentCode()
            : '';

        // Salvăm profilul în Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': name,
          'email': email,
          'role': _selectedRole,
          'childrenEmails': [foundChildEmail], // Listă de emailuri
          'hasAccess': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _notifyTeacherAboutNewUser(
          rawName: name,
          userRole: _selectedRole,
        );

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cont creat cu succes! Verifică-ți adresa de email pentru a confirma contul.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? 'A apărut o eroare la înregistrare.');
      } catch (e) {
        _showSnackBar('Eroare: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enrollStudentInCourse(
    String courseId,
    String courseTitle,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 1. Preluăm numele elevului din Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String studentName = userDoc.exists
          ? (userDoc.data()?['fullName'] ?? 'Elev')
          : 'Elev';

      // 2. Salvăm înscrierea în colecția 'enrollments'
      await FirebaseFirestore.instance.collection('enrollments').add({
        'courseId': courseId,
        'courseTitle': courseTitle,
        'userId': currentUser.uid,
        'studentName': studentName,
        'studentEmail': currentUser.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Credențiale identice ca la RegisterScreen
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\SwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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

      // 4. Căutăm profesorii
      final teachersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['teacher', 'Teacher'])
          .get();

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';
      String pushTitle = '📚 Înscriere nouă la curs!';
      String pushBody =
          'Elevul $studentName s-a înscris la cursul "$courseTitle".';

      for (var teacherDoc in teachersDocs.docs) {
        var tData = teacherDoc.data();
        String? teacherFcmToken = tData['fcmToken'];
        String teacherId = teacherDoc.id;

        // Salvăm în colecția de notificări din Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': pushTitle,
          'body': pushBody,
          'isRead': false,
          'type': 'course_enrollment',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Trimitere Push FCM V1 pe telefonul profesorului
        if (teacherFcmToken != null && teacherFcmToken.isNotEmpty) {
          try {
            var response = await client.post(
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
                    'headers': {
                      'apns-priority': '10',
                      'apns-push-type': 'alert',
                    },
                    'payload': {
                      'aps': {'sound': 'default'},
                    },
                  },
                  'data': {
                    'type': 'course_enrollment',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );
            debugPrint(
              "Răspuns FCM Înscriere: ${response.statusCode} - ${response.body}",
            );
          } catch (e) {
            debugPrint("Eroare trimitere FCM înscriere: $e");
          }
        } else {
          debugPrint("Profesorul $teacherId nu are fcmToken salvat!");
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare generală la înscriere: $e");
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
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\SwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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
        var tData = teacherDoc.data() as Map<String, dynamic>;
        String? teacherFcmToken = tData['fcmToken'];
        String teacherId = teacherDoc.id;

        // 1. Salvăm notificarea în Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': pushTitle,
          'body': pushBody,
          'isRead': false,
          'type': 'user_registration',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Trimitem Push Notification (FCM) către profesor
        if (teacherFcmToken != null && teacherFcmToken.isNotEmpty) {
          try {
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
                    'headers': {
                      'apns-priority': '10',
                      'apns-push-type': 'alert',
                    },
                    'payload': {
                      'aps': {'sound': 'default'},
                    },
                  },
                  'data': {
                    'type': 'user_registration',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );
          } catch (e) {
            debugPrint("Eroare trimitere FCM către profesor: $e");
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la notificarea profesorului: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Stack(
        children: [
          Column(
            children: [
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
                                  controller: _studentCodeController,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Codul Unic al Elevului (ex: A4B7C9)',
                                    prefixIcon: const Icon(
                                      Icons.vpn_key_outlined,
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
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryIndigo,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryIndigo.withOpacity(
                                    0.3,
                                  ), // 🌟 Aici era 'primaryindigo' cu i mic
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
