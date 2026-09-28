import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Funcție de ștergere a cursului din Firestore (pentru profesor)
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

  // 1. Trimite Push Notification către toți profesorii când un elev cere acces
  Future<void> _notifyTeacherAboutEnrollment({
    required String courseTitle,
    required String studentName,
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

      final teachersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
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
                    'aps': {'sound': 'default', 'badge': 1},
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

  // 2. Metoda prin care elevul cere acces la un curs
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
        studentName = uData?['name'] ?? uData?['email'] ?? 'Un elev';
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

  // 3. Dialog de gestionare a cererilor (Clopoțelul Profesorului)
  void _showPendingRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitări de înscriere în așteptare'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nu există nicio solicitare în așteptare.'),
                  );
                }

                var requests = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var reqDoc = requests[index];
                    var reqData = reqDoc.data() as Map<String, dynamic>;
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
                        if (userSnap.hasData && userSnap.data!.exists) {
                          var uData =
                              userSnap.data!.data() as Map<String, dynamic>?;
                          studentName =
                              uData?['name'] ?? uData?['email'] ?? 'Elev';
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('courses')
                              .doc(courseId)
                              .get(),
                          builder: (context, courseSnap) {
                            String courseTitle = 'Curs';
                            if (courseSnap.hasData && courseSnap.data!.exists) {
                              var cData =
                                  courseSnap.data!.data()
                                      as Map<String, dynamic>?;
                              courseTitle = cData?['title'] ?? 'Curs';
                            }

                            return ListTile(
                              title: Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Curs: $courseTitle'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('enrollments')
                                          .doc(reqId)
                                          .update({'status': 'approved'});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Închide'),
            ),
          ],
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
                  .collection('enrollments')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_active),
                      onPressed: _showPendingRequestsDialog,
                    ),
                    if (count > 0)
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
                            '$count',
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
            return const Center(child: Text('Nu există cursuri adăugate.'));
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
                          // BUTONUL DE ȘTERGERE CURS (PENTRU PROFESOR)
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

                      // BUTOANELE PENTRU PROFESOR SAU ELEV
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
