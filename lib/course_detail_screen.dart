import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'lesson_detail_page.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final String category;
  final String description;
  final String role;
  final String? targetLessonId;
  final String? initialTab;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.category,
    required this.description,
    required this.role,
    this.targetLessonId,
    this.initialTab,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    _clearBadgeAndMarkAsRead();

    if (widget.targetLessonId != null && widget.targetLessonId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          DocumentSnapshot lessonDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.courseId)
              .collection('lessons')
              .doc(widget.targetLessonId)
              .get();

          if (lessonDoc.exists && mounted) {
            var lData = lessonDoc.data() as Map<String, dynamic>;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LessonDetailPage(
                  courseId: widget.courseId,
                  lessonId: widget.targetLessonId!,
                  lessonTitle: lData['title'] ?? 'Lecție',
                  initialTab: widget.initialTab ?? 'lesson',
                  role: 'student',
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Eroare navigare lectie: $e");
        }
      });
    }
  }

  Future<void> _clearBadgeAndMarkAsRead() async {
    try {
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.removeBadge();
      }

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        var unreadDocs = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .where('courseId', isEqualTo: widget.courseId)
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in unreadDocs.docs) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      debugPrint("Eroare la curățarea notificărilor: $e");
    }
  }

  Future<void> _sendPushToStudents({
    required String lessonTitle,
    required String notificationType,
    required String lessonId,
  }) async {
    try {
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\nSwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\n/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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

      final enrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: widget.courseId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (enrollments.docs.isEmpty) {
        client.close();
        return;
      }

      String pushTitle = notificationType == 'homework'
          ? '📝 Temă Nouă în ${widget.title}'
          : '📚 Lecție Nouă în ${widget.title}';

      String pushBody = notificationType == 'homework'
          ? 'A fost încărcată tema: "$lessonTitle"'
          : 'A fost adăugată înregistrarea cursului: "$lessonTitle"';

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

      for (var doc in enrollments.docs) {
        String userId = doc['userId'];

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': pushTitle,
          'body': pushBody,
          'courseId': widget.courseId,
          'lessonId': lessonId,
          'type': notificationType,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final unreadSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        int unreadCount = unreadSnap.docs.length;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = uData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await client.post(
              Uri.parse(fcmV1Url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': {
                  'token': fcmToken,
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
                      'aps': {'sound': 'default', 'badge': unreadCount},
                    },
                  },
                  'data': {
                    'courseId': widget.courseId,
                    'lessonId': lessonId,
                    'notificationType': notificationType,
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la trimiterea notificarii FCM v1: $e");
    }
  }

  Future<void> _deleteLesson(
    BuildContext context,
    String lessonId,
    String lessonTitle,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere "$lessonTitle"'),
        content: const Text(
          'Ești sigur că vrei să ștergi această lecție? Acțiunea este ireversibilă.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('lessons')
            .doc(lessonId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lecția a fost ștearsă cu succes!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Eroare la ștergere: $e')));
        }
      }
    }
  }

  void _showAddOrEditLessonDialog(
    BuildContext context, {
    DocumentSnapshot? existingLesson,
  }) {
    var data = existingLesson?.data() as Map<String, dynamic>?;

    final titleController = TextEditingController(text: data?['title'] ?? '');
    final contentController = TextEditingController(
      text: data?['content'] ?? '',
    );
    final homeworkContentController = TextEditingController(
      text: data?['homeworkContent'] ?? '',
    );

    List<String> videoUrls = [];
    if (data?['videoUrls'] != null) {
      videoUrls = List<String>.from(data!['videoUrls']);
    } else if (data?['videoUrl'] != null &&
        (data!['videoUrl'] as String).isNotEmpty) {
      videoUrls = [data['videoUrl']];
    }

    List<String> pdfUrls = [];
    if (data?['pdfUrls'] != null) {
      pdfUrls = List<String>.from(data!['pdfUrls']);
    } else if (data?['pdfUrl'] != null &&
        (data!['pdfUrl'] as String).isNotEmpty) {
      pdfUrls = [data['pdfUrl']];
    }

    final newVideoController = TextEditingController();
    final newPdfController = TextEditingController();

    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                existingLesson == null
                    ? "Adaugă Lecție Nouă (Video & PDF)"
                    : "Editează Lecția",
                style: const TextStyle(
                  color: primaryIndigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Titlu Lecție",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "--- SECȚIUNEA 1: TEORIE & VIDEO ---",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Conținut / Explicații Teoretice",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Link-uri Video Bunny (iframe embed):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...videoUrls.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String url = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.video_library, color: accentLila),
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                setDialogState(() => videoUrls.removeAt(idx)),
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newVideoController,
                              decoration: const InputDecoration(
                                hintText: "Adaugă URL Video Embed...",
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: primaryIndigo),
                            onPressed: () {
                              String url = newVideoController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() {
                                  videoUrls.add(url);
                                  newVideoController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "--- SECȚIUNEA 2: TEMĂ & PDF ---",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: homeworkContentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Cerințe / Exerciții Temă (Text)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Fișiere PDF încărcate:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...pdfUrls.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String url = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                setDialogState(() => pdfUrls.removeAt(idx)),
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newPdfController,
                              decoration: const InputDecoration(
                                hintText: "Lipește link-ul PDF...",
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: primaryIndigo),
                            tooltip: "Adaugă PDF în listă",
                            onPressed: () {
                              String url = newPdfController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() {
                                  pdfUrls.add(url);
                                  newPdfController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Anulează",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPdfController.text.trim().isNotEmpty) {
                      pdfUrls.add(newPdfController.text.trim());
                    }
                    if (newVideoController.text.trim().isNotEmpty) {
                      videoUrls.add(newVideoController.text.trim());
                    }

                    final String lTitle = titleController.text.trim();
                    if (lTitle.isNotEmpty) {
                      Map<String, dynamic> lessonPayload = {
                        'title': lTitle,
                        'content': contentController.text.trim(),
                        'videoUrls': videoUrls,
                        'homeworkContent': homeworkContentController.text
                            .trim(),
                        'pdfUrls': pdfUrls,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (existingLesson == null) {
                        lessonPayload['createdAt'] =
                            FieldValue.serverTimestamp();
                        DocumentReference docRef = await FirebaseFirestore
                            .instance
                            .collection('courses')
                            .doc(widget.courseId)
                            .collection('lessons')
                            .add(lessonPayload);

                        await _sendPushToStudents(
                          lessonTitle: lTitle,
                          notificationType: 'lesson',
                          lessonId: docRef.id,
                        );
                      } else {
                        await existingLesson.reference.update(lessonPayload);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lecția a fost salvată cu succes!'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Salvează"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      floatingActionButton: widget.role == 'teacher'
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOrEditLessonDialog(context),
              backgroundColor: accentLila,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Adaugă Lecție"),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ANTET MODERN CURS
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
                      Icons.book,
                      color: Colors.amberAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DESCRIERE CURS
            if (widget.description.isNotEmpty) ...[
              const Text(
                "Despre Curs",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryIndigo,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              "Lecții și Materiale",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryIndigo,
              ),
            ),
            const SizedBox(height: 12),

            // ANUNȚ / REMINDER GLOBAL
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .snapshots(),
              builder: (context, courseSnapshot) {
                if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                var courseData =
                    courseSnapshot.data!.data() as Map<String, dynamic>;
                String reminderText = courseData['generalReminder'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reminderText.isNotEmpty ||
                        widget.role == 'teacher') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentLila.withOpacity(
                            0.06,
                          ), // Fundal fin lila în loc de galben
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentLila.withOpacity(
                              0.3,
                            ), // Margine elegantă lila
                            width: 1.5,
                          ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.campaign,
                                      color:
                                          accentLila, // Iconiță în nuanța lila
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Anunț / Reminder Important",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryIndigo, // Text în indigo închis
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.role == 'teacher')
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: primaryIndigo,
                                    ),
                                    tooltip: "Editează Reminderul",
                                    onPressed: () => _showEditReminderDialog(
                                      context,
                                      reminderText,
                                    ),
                                  ),
                              ],
                            ),
                            if (reminderText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                reminderText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ] else if (widget.role == 'teacher') ...[
                              const SizedBox(height: 4),
                              Text(
                                "Niciun reminder setat. Apasă pe creion pentru a adăuga un mesaj vizibil pentru elevi.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                );
              },
            ),

            // LISTA DE LECȚII
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('lessons')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: accentLila),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        "Nu există lecții adăugate în acest curs încă.",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                var lessons = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    var lessonDoc = lessons[index];
                    var lessonData = lessonDoc.data() as Map<String, dynamic>;
                    String lessonId = lessonDoc.id;
                    String lessonTitle = lessonData['title'] ?? 'Lecție';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: accentLila.withOpacity(0.15),
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: accentLila,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          lessonTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryIndigo,
                          ),
                        ),
                        subtitle: Text(
                          "Apasă pentru a deschide lecția și tema",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.role == 'teacher') ...[
                              IconButton(
                                icon: Icon(Icons.edit, color: primaryIndigo),
                                tooltip: "Editează lecția",
                                onPressed: () => _showAddOrEditLessonDialog(
                                  context,
                                  existingLesson: lessonDoc,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: "Șterge lecția",
                                onPressed: () => _deleteLesson(
                                  context,
                                  lessonId,
                                  lessonTitle,
                                ),
                              ),
                            ],
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonDetailPage(
                                courseId: widget.courseId,
                                lessonId: lessonId,
                                lessonTitle: lessonTitle,
                                initialTab: 'lesson',
                                role: 'student',
                              ),
                            ),
                          );
                        },
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

  void _showEditReminderDialog(BuildContext context, String currentReminder) {
    final reminderController = TextEditingController(text: currentReminder);
    const Color primaryIndigo = Color(0xff1e1b4b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editează Anunțul / Reminderul"),
        content: TextField(
          controller: reminderController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Scrie un anunț important pentru toți elevii...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anulează"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryIndigo),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .update({'generalReminder': reminderController.text.trim()});

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Reminderul a fost actualizat!"),
                  ),
                );
              }
            },
            child: const Text(
              "Salvează",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
