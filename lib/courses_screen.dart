import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final String role; // 'teacher' sau 'student'

  const CoursesScreen({super.key, required this.role});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // Metodă pentru reîmprospătarea badge-ului profesorului
  Future<void> _refreshTeacherBadge() async {
    if (kIsWeb) return;
    try {
      final unapprovedUsersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('hasAccess', isEqualTo: false)
          .get();

      final pendingEnrollmentsSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();

      int remaining =
          unapprovedUsersSnap.docs.length + pendingEnrollmentsSnap.docs.length;

      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (remaining > 0) {
          FlutterAppBadger.updateBadgeCount(remaining);
        } else {
          FlutterAppBadger.removeBadge();
        }
      }
    } catch (e) {
      debugPrint("Eroare la actualizarea badge-ului: $e");
    }
  }

  // 1. Ștergere curs (pentru profesor)
  Future<void> _deleteCourse(String courseId, String courseTitle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere "$courseTitle"'),
        content: const Text(
          'Ești sigur că vrei să ștergi acest curs cu toate lecțiile asociate? Acțiunea este ireversibilă.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Șterge Cursul',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cursul a fost ștearsă cu succes!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la ștergerea cursului: $e')),
          );
        }
      }
    }
  }

  // 2. Notificare profesor la o cerere nouă de înscriere
  Future<void> _notifyTeacherAboutEnrollment({
    required String courseTitle,
    required String studentName,
  }) async {
    try {
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

      for (var teacherDoc in teachersDocs.docs) {
        var tData = teacherDoc.data();
        String? teacherFcmToken = tData['fcmToken'];
        String teacherId = teacherDoc.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': '🙋‍♂️ Solicitare nouă de înscriere!',
          'body': '$studentName dorește să se înscrie la "$courseTitle".',
          'isRead': false,
          'type': 'enrollment_request',
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
                'notification': {
                  'title': '🙋‍♂️ Solicitare nouă de înscriere!',
                  'body':
                      '$studentName dorește să se înscrie la "$courseTitle".',
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
                  'type': 'enrollment_request',
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
              },
            }),
          );
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la notificarea profesorului: $e");
    }
  }

  // 3. Trimitere cerere înscriere la curs de către elev
  Future<void> _requestEnrollment(String courseId, String courseTitle) async {
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      String studentName = 'Un elev';
      if (userDoc.exists) {
        var uData = userDoc.data() as Map<String, dynamic>?;
        studentName =
            uData?['fullName'] ??
            uData?['name'] ??
            uData?['email'] ??
            'Un elev';
      }

      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': currentUser!.uid,
        'courseId': courseId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitarea a fost trimisă! Așteaptă aprobarea profesorului.',
            ),
          ),
        );
      }

      await _notifyTeacherAboutEnrollment(
        courseTitle: courseTitle,
        studentName: studentName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la trimiterea solicitării: $e')),
        );
      }
    }
  }

  // 4. Centru de Aprobări la Clopoțel (Conturi noi + Înscrieri cursuri)
  void _showPendingRequestsDialog() {
    // Curățăm notificările vechi/orfane ale profesorului la deschiderea clopoțelului
    User? currentTeacher = FirebaseAuth.instance.currentUser;
    if (currentTeacher != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentTeacher.uid)
          .where('isRead', isEqualTo: false)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'isRead': true});
            }
          });
    }
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Centru de Aprobări',
              style: TextStyle(
                color: Color(0xff42153e),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xff42153e),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xff42153e),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.person_add, size: 18),
                        text: "Conturi Noi",
                      ),
                      Tab(
                        icon: Icon(Icons.school, size: 18),
                        text: "Înscrieri Curs",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: CONTURI NOI NEAPROBATE
                        // TAB 1: CONTURI NOI NEAPROBATE
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'student')
                              .where('hasAccess', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nu există conturi noi în așteptare.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            var unapprovedUsers = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: unapprovedUsers.length,
                              itemBuilder: (context, index) {
                                var uDoc = unapprovedUsers[index];
                                var uData = uDoc.data() as Map<String, dynamic>;
                                String uId = uDoc.id;
                                String name =
                                    uData['fullName'] ??
                                    uData['name'] ??
                                    'Elev';
                                String email = uData['email'] ?? '';

                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xff42153e),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    email,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // BUTON APROBARE CONT
                                      // BUTON APROBARE CONT
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                        tooltip: 'Aprobă Accesul',
                                        onPressed: () async {
                                          // 1. Aprobăm contul în Firestore
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(uId)
                                              .update({'hasAccess': true});

                                          // 2. Marchează notificările necitite ale profesorului legate de conturi ca fiind citite
                                          if (currentUser != null) {
                                            var notifs = await FirebaseFirestore
                                                .instance
                                                .collection('notifications')
                                                .where(
                                                  'userId',
                                                  isEqualTo: currentUser!.uid,
                                                )
                                                .where(
                                                  'isRead',
                                                  isEqualTo: false,
                                                )
                                                .get();

                                            for (var doc in notifs.docs) {
                                              String bodyText =
                                                  doc.data()['body'] ?? '';
                                              if (bodyText.contains(email) ||
                                                  bodyText.contains(name)) {
                                                await doc.reference.update({
                                                  'isRead': true,
                                                });
                                              }
                                            }
                                          }

                                          // 3. Actualizăm badge-ul nativ
                                          _refreshTeacherBadge();
                                        },
                                      ),

                                      // BUTON RESPINGERE/ȘTERGERE CONT
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 28,
                                        ),
                                        tooltip: 'Respinge Contul',
                                        onPressed: () async {
                                          // 1. Ștergem contul neaprobat
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(uId)
                                              .delete();

                                          // 2. 👈 Ștergem și notificările generate pentru acest utilizator
                                          var userNotifs =
                                              await FirebaseFirestore.instance
                                                  .collection('notifications')
                                                  .get();

                                          for (var doc in userNotifs.docs) {
                                            String bodyText =
                                                doc.data()['body'] ?? '';
                                            if (bodyText.contains(email) ||
                                                bodyText.contains(name)) {
                                              await doc.reference.delete();
                                            }
                                          }

                                          // 3. Actualizăm badge-ul profesorului
                                          _refreshTeacherBadge();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // TAB 2: ÎNSCRIERI PENDING LA CURSURI
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('enrollments')
                              .where('status', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nu există solicitări de curs în așteptare.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            var requests = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: requests.length,
                              itemBuilder: (context, index) {
                                var reqDoc = requests[index];
                                var reqData =
                                    reqDoc.data() as Map<String, dynamic>;
                                String reqId = reqDoc.id;
                                String studentId = reqData['userId'];
                                String courseId = reqData['courseId'];

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(studentId)
                                      .get(),
                                  builder: (context, userSnap) {
                                    String studentName = 'Elev';
                                    if (userSnap.hasData &&
                                        userSnap.data!.exists) {
                                      var uData =
                                          userSnap.data!.data()
                                              as Map<String, dynamic>?;
                                      studentName =
                                          uData?['fullName'] ??
                                          uData?['name'] ??
                                          uData?['email'] ??
                                          'Elev';
                                    }

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('courses')
                                          .doc(courseId)
                                          .get(),
                                      builder: (context, courseSnap) {
                                        String courseTitle = 'Curs';
                                        if (courseSnap.hasData &&
                                            courseSnap.data!.exists) {
                                          var cData =
                                              courseSnap.data!.data()
                                                  as Map<String, dynamic>?;
                                          courseTitle =
                                              cData?['title'] ?? 'Curs';
                                        }

                                        return ListTile(
                                          title: Text(
                                            studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Curs: $courseTitle',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 28,
                                                ),
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('enrollments')
                                                      .doc(reqId)
                                                      .update({
                                                        'status': 'approved',
                                                      });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                  size: 28,
                                                ),
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('enrollments')
                                                      .doc(reqId)
                                                      .delete();
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Închide'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
        title: const Text(
          'Cursuri Disponibile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.role == 'teacher')
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .where('hasAccess', isEqualTo: false)
                  .snapshots(),
              builder: (context, unapprovedSnap) {
                int unapprovedAccountsCount = unapprovedSnap.hasData
                    ? unapprovedSnap.data!.docs.length
                    : 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, pendingEnrollSnap) {
                    int pendingEnrollmentsCount = pendingEnrollSnap.hasData
                        ? pendingEnrollSnap.data!.docs.length
                        : 0;
                    int totalPending =
                        unapprovedAccountsCount + pendingEnrollmentsCount;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_active),
                          onPressed: _showPendingRequestsDialog,
                        ),
                        if (totalPending > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$totalPending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff42153e)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nu există cursuri adăugate în bază.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          var courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var courseDoc = courses[index];
              var courseData = courseDoc.data() as Map<String, dynamic>;
              String courseId = courseDoc.id;
              String title = courseData['title'] ?? 'Curs fără titlu';
              String category = courseData['category'] ?? 'General';
              String description = courseData['description'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (widget.role == 'teacher')
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Șterge Cursul',
                              onPressed: () => _deleteCourse(courseId, title),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff42153e),
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      if (widget.role == 'teacher')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseDetailScreen(
                                  courseId: courseId,
                                  title: title,
                                  category: category,
                                  description: description,
                                  role: widget.role,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff42153e),
                            foregroundColor: Colors.amber,
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Gestionează Cursul'),
                        )
                      else
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('enrollments')
                              .where('courseId', isEqualTo: courseId)
                              .where('userId', isEqualTo: currentUser?.uid)
                              .snapshots(),
                          builder: (context, enrollSnap) {
                            if (!enrollSnap.hasData ||
                                enrollSnap.data!.docs.isEmpty) {
                              return ElevatedButton.icon(
                                onPressed: () =>
                                    _requestEnrollment(courseId, title),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff42153e),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Solicită înscriere'),
                              );
                            }

                            var enrollData =
                                enrollSnap.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            String status = enrollData['status'] ?? 'pending';

                            if (status == 'approved') {
                              return ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseDetailScreen(
                                        courseId: courseId,
                                        title: title,
                                        category: category,
                                        description: description,
                                        role: widget.role,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.play_circle_fill),
                                label: const Text('Intră la Curs'),
                              );
                            } else {
                              return OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(
                                  Icons.hourglass_top,
                                  color: Colors.orange,
                                ),
                                label: const Text(
                                  'Solicitare în așteptare...',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
