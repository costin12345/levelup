import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class CatalogScreen extends StatefulWidget {
  final String role; // 'student' sau 'parent'

  const CatalogScreen({super.key, required this.role});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _childEmail;
  bool _isLoadingChild = true;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'parent') {
      _fetchChildEmail();
    }
  }

  // Preluăm email-ul copilului asociat părintelui din colecția 'users'
  Future<void> _fetchChildEmail() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>?;
          if (mounted) {
            setState(() {
              _childEmail = data?['childEmail'];
              _isLoadingChild = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Eroare la preluarea email-ului copilului: $e");
        if (mounted) setState(() => _isLoadingChild = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingChild = false);
    }
  }

  // Helper pentru afișarea statusului temei
  Widget _buildHomeworkBadge(String? status) {
    String text;
    Color bgColor;
    Color textColor;

    switch (status?.toLowerCase()) {
      case 'efectuata':
        text = '🟢 Temă Efectuată';
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      case 'partiala':
        text = '🟡 Temă Parțială';
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        break;
      case 'neefectuata':
      default:
        text = '🔴 Lipsă Temă';
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
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

      // 3. Pregătim credențialele de Google APIs pentru trimiterea FCM V1
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

      // 4. Căutăm profesorii și token-ul lor FCM
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

        // Salvăm și în Firestore în colecția de notificări
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': pushTitle,
          'body': pushBody,
          'isRead': false,
          'type': 'course_enrollment',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Trimiterea efectivă pe telefon prin FCM V1
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
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la trimiterea notificării de înscriere: $e");
    }
  }

  // Helper pentru afișarea statusului plății ședinței
  Widget _buildPaymentBadge(String? status) {
    bool isPaid = status?.toLowerCase() == 'platita';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPaid ? '💵 Plătită' : '⏳ Neplătită',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPaid ? Colors.blue.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xfff8fafc),
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ANTET MODERN ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryIndigo, Color(0xff312e81)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentLila.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentLila.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.amberAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'parent'
                              ? "Catalogul Copilului Meu"
                              : "Catalogul Virtual • Progres Academic",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Vizualizează notele, testele, temele și plățile în timp real",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dacă este părinte și încă se încarcă email-ul copilului
            if (widget.role == 'parent' && _isLoadingChild)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              )
            else if (widget.role == 'parent' &&
                (_childEmail == null || _childEmail!.isEmpty))
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    "Nu este asociat niciun elev acestui cont de părinte (verificați câmpul 'childEmail' în baza de date).",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              // --- STREAM PENTRU NOTE ȘI ȘEDINȚE ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, gradesSnapshot) {
                  if (gradesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: accentLila),
                      ),
                    );
                  }

                  if (!gradesSnapshot.hasData ||
                      gradesSnapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Nu există înregistrări momentan.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  var allDocs = gradesSnapshot.data!.docs;

                  // Filtrare după rol (student sau părinte)
                  // Filtrare flexibilă pe bază de ID, Email sau chiar Nume pentru siguranță totală
                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    if (widget.role == 'parent') {
                      return data['studentEmail'] == _childEmail;
                    } else {
                      String? sId = data['studentId'];
                      String? sEmail = data['studentEmail'];
                      String? sName = data['studentName'];

                      // Căutăm după oricare dintre elemente pentru a fi siguri că găsim nota
                      return sId == currentUser.uid ||
                          sEmail == currentUser.email ||
                          (sName != null &&
                              currentUser.displayName != null &&
                              sName == currentUser.displayName);
                    }
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Nu s-au găsit date pentru elevul selectat.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  // Grupare dinamică pe elev
                  Map<String, List<Map<String, dynamic>>> studentMap = {};
                  for (var doc in filteredDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String studentName =
                        data['studentName'] ?? 'Elev necunoscut';

                    if (!studentMap.containsKey(studentName)) {
                      studentMap[studentName] = [];
                    }
                    studentMap[studentName]!.add({
                      'id': doc.id,
                      'grade': data['grade']?.toString() ?? '-',
                      'sessionNumber':
                          data['sessionNumber']?.toString() ?? 'Ședință',
                      'homeworkStatus': data['homeworkStatus'] ?? 'neefectuata',
                      'paymentStatus': data['paymentStatus'] ?? 'neplatita',
                      'feedback': data['feedback'] ?? 'Fără observații',
                      'className': data['className'] ?? '',
                      'date': data['createdAt'],
                    });
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentMap.keys.length,
                    itemBuilder: (context, index) {
                      String studentName = studentMap.keys.elementAt(index);
                      List<Map<String, dynamic>> sessions =
                          studentMap[studentName]!;
                      String className = sessions.isNotEmpty
                          ? sessions[0]['className']
                          : '';

                      // Calcul medie note teste
                      double sum = 0;
                      int count = 0;
                      for (var item in sessions) {
                        double? val = double.tryParse(item['grade']);
                        if (val != null) {
                          sum += val;
                          count++;
                        }
                      }
                      String average = count > 0
                          ? (sum / count).toStringAsFixed(1)
                          : "-";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header elev + Medie generală
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: accentLila.withOpacity(
                                        0.12,
                                      ),
                                      child: Text(
                                        studentName.isNotEmpty
                                            ? studentName[0].toUpperCase()
                                            : "E",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: accentLila,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                        Text(
                                          className.isNotEmpty
                                              ? "Clasa: $className"
                                              : "Fără detalii clasă",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentLila.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Medie",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: accentLila,
                                        ),
                                      ),
                                      Text(
                                        average,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: accentLila,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            const Text(
                              "Istoric Ședințe, Teste & Plăți",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Listă detaliată per ședință
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sessions.length,
                              separatorBuilder: (context, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, sessionIndex) {
                                var session = sessions[sessionIndex];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Număr ședință
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          session['sessionNumber'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                      ),
                                      // Notă test
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            const Text(
                                              "Test: ",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: accentLila.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                session['grade'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: primaryIndigo,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status temă
                                      Expanded(
                                        flex: 3,
                                        child: Center(
                                          child: _buildHomeworkBadge(
                                            session['homeworkStatus'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Status plată ședință
                                      Expanded(
                                        flex: 3,
                                        child: Center(
                                          child: _buildPaymentBadge(
                                            session['paymentStatus'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
