import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'web_iframe_stub.dart' if (dart.library.html) 'web_iframe_web.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String title;
  final String category;
  final String description;
  final String role;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.category,
    required this.description,
    required this.role,
  });

  // Şterge badge-ul nativ de pe iconiţă şi marchează notificările ca citite
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
            .where('courseId', isEqualTo: courseId)
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

  // Funcție de trimitere Push Notification prin FCM API v1 către toti elevii aprobați
  Future<void> _sendPushToStudents({
    required String lessonTitle,
    required String notificationType, // 'lesson' sau 'homework'
  }) async {
    try {
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "be2af79dfbe281af83316b25ea293ebfc1beee3a",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/GHpRVvpGCezi\nK33vzeOvzPaVcNL/+U0wrAcyLDQGlaDnY/k/mjeq6XMr0l+IAapukBaI/cFUsx1r\npTnIByGyMJ6ibS9ywHygjk0imuKOtSioiFsxCa7w9cOJe8tHyugIjQWm6vELqGAk\njt9GNy1uIODZVpmeF4qyhBFcCXnbOZFLkKeNKx4V9xQcpZ7gyjvVUuDWnuPT9sLv\n5zwvi+OgBJOiksSZ03ShGgDMKwe+mnfRm/VtzfABlEdaf+hnnEsnVWm22/TVrHEk\nkZMlDH/QFh77Mf3l0bY0I5VhUfG5O/2/R+Z6X8ZWyZo+D9BF2eb2Lr71gP4FBoL/\nxCK64kEhAgMBAAECggEAApHLIl5qQRhk2SKUWpiQBU8FrOXaB5Q2skYRcyWXdQz8\ndMcqIu2UCrYsOGOgVBuCg/D2DJxmqW4esCdNJ3yeZULfNk11w/shgBefFMm0l0dQ\nisDtSd5KduenFOJJI1mojbsaX1pQtsNN1Pqtfh2nJ0kpOUZ4RTZ7KGXJjKK2NKPY\n/6WFYPpAwpr0h5utvqmVgRvkZ/SZm4dDF2q8v/S+b//Ws1Vd5T4Ng4k/aUDontpT\nwxT3Riy0O3dDO8DETM/jj5FMKNpVByM4ZfbN7fYEz9qeR9x4KdFWSo6L+a5E4PZv\nF+xvLqRcFiLqrcnXiCCViGde13KjqAr0UNmkQC+EDQKBgQDwjs/phhcMuFmEySi3\nK5LT0/6t9R4ii0nC9Uu4NaY9WiNlKAoy9Ne3whl9zOGzmRY+Fe9DAmGPFg1cWyRo\nGyUbuI2w/3fM8Hx3Fix+pT+mGNjn2K0pdy87NtAlTtjyrmWkOfPm+fOdVnBi6+Ml\nugFGxBwBkJ6q6ff0b5fGN4RyRwKBgQDLXNT5NeRnfkyhh2VFifb2YKkzFiWyCyBg\nZBQXaojMoTY5ueBdPbUecGN+G07aRJ2kx08uCY/EQYCEccjHyeB3R+0EjyiaxEnF\n33//tywzxvZ8jjUo2oZuXgO3iPXQ0SEnnIMYAtTJ7SyYsZl7Ala9SC4CIqNiPWKR\n+hdRnve9VwKBgGbeGyiYT5j/6D/xKXkSqAnvWLQY4pcRCyzUalnOj1UjC4nBUoMx\n0mFhHjd+enGroChShusXxJJEctgwnWPrX7X3+Jdc12UK3Z6rG8HYdlxXucGDFaFq\ntwbSTLX3fqxgSVSt94+pCTUZ9ptGle7XGJ6jU/qTVlZuELs1USjRKtEXAoGBAMNF\nG1dEsVHTC6Aa01pndJT1EeL1BDMmzergjg5CBKOAtQHPAqplg1F8F3zSme+p7Tl5\nDAWntr17K/2BCIsWxIukq+kx0YpyqmfvCQgxCaeaB7poDpFw6550dds5Dth4xv4z\nIgnfRhWywJzKBBcCkuljspHoUrwVN132J4f/PeE3AoGBAMO918DIrrHdGyaHSA0E\nK0gEY2dMUuAmaMeDEFtVHoZtugUUC6ZFMOgP4fQIjPnL52igeW6IUs96du2d+GIC\nqdlMb7Tp/lTxvaRGqUcAVhYbYaawonFK7QU8kNygU1IqWljXa+S+nR1O/tCmG2/n\n34ZJZ4VSGVZ/GX9IToAU297e\n-----END PRIVATE KEY-----\n",
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
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (enrollments.docs.isEmpty) {
        client.close();
        return;
      }

      String pushTitle = notificationType == 'homework'
          ? '📝 Temă Nouă în $title'
          : '📚 Lecție Nouă în $title';

      String pushBody = notificationType == 'homework'
          ? 'A fost încărcată tema: "$lessonTitle"'
          : 'A fost adăugată înregistrarea cursului: "$lessonTitle"';

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

      for (var doc in enrollments.docs) {
        String userId = doc['userId'];

        // Salvare notificare in-app
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': pushTitle,
          'body': pushBody,
          'courseId': courseId,
          'type': notificationType,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Calculare BADGE DINAMIC pentru elev
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
                    'courseId': courseId,
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
            .doc(courseId)
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

  void _showAddLessonDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final videoUrlController = TextEditingController();
    final pdfUrlController = TextEditingController();
    String notificationType = 'lesson';

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
              title: const Text(
                "Adaugă Lecție Nouă",
                style: TextStyle(
                  color: Color(0xff42153e),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "Titlu Lecție",
                          hintText: "ex: Lecția 1 - Introducere",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Tipul notificării trimise elevilor:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xff42153e),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "📚 Lecție / Teorie",
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'lesson',
                              groupValue: notificationType,
                              onChanged: (val) {
                                setDialogState(() => notificationType = val!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                "📝 Temă PDF",
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'homework',
                              groupValue: notificationType,
                              onChanged: (val) {
                                setDialogState(() => notificationType = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Conținut / Explicații Teoretice",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: videoUrlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: "Link Video Bunny Embed (Teorie)",
                          hintText:
                              "https://iframe.mediadelivery.net/embed/...",
                          prefixIcon: Icon(
                            Icons.video_library,
                            color: Colors.purple,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pdfUrlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: "Link Document PDF (Temă / Suport)",
                          hintText: "https://.../fisier.pdf",
                          prefixIcon: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          border: OutlineInputBorder(),
                        ),
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
                    final String lTitle = titleController.text.trim();
                    if (lTitle.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('courses')
                          .doc(courseId)
                          .collection('lessons')
                          .add({
                            'title': lTitle,
                            'content': contentController.text.trim(),
                            'videoUrl': videoUrlController.text.trim(),
                            'pdfUrl': pdfUrlController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      await _sendPushToStudents(
                        lessonTitle: lTitle,
                        notificationType: notificationType,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lecție salvată și notificări trimise!',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff42153e),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Salvează Lecția"),
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
    _clearBadgeAndMarkAsRead();

    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: role == 'teacher'
          ? FloatingActionButton.extended(
              onPressed: () => _showAddLessonDialog(context),
              backgroundColor: const Color(0xff42153e),
              foregroundColor: Colors.amber,
              icon: const Icon(Icons.add),
              label: const Text("Adaugă Lecție"),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff42153e),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Lecții și Materiale",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff42153e),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('lessons')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Nu există lecții adăugate în acest curs încă.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
                    String lessonContent = lessonData['content'] ?? '';
                    String videoUrl = lessonData['videoUrl'] ?? '';
                    String pdfUrl = lessonData['pdfUrl'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xff42153e),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          lessonTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xff42153e),
                          ),
                        ),
                        trailing: role == 'teacher'
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteLesson(
                                  context,
                                  lessonId,
                                  lessonTitle,
                                ),
                              )
                            : null,
                        children: [
                          DefaultTabController(
                            length: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const TabBar(
                                  labelColor: Color(0xff42153e),
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: Color(0xff42153e),
                                  tabs: [
                                    Tab(
                                      icon: Icon(Icons.menu_book, size: 18),
                                      text: "Teorie & Aplicații",
                                    ),
                                    Tab(
                                      icon: Icon(Icons.assignment, size: 18),
                                      text: "Temă (PDF)",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 500,
                                  child: TabBarView(
                                    children: [
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (lessonContent.isNotEmpty) ...[
                                              Text(
                                                lessonContent,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            if (videoUrl.isNotEmpty) ...[
                                              const Text(
                                                "📹 Înregistrare Curs",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xff42153e),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              UniversalEmbeddedViewer(
                                                viewId: 'video_$lessonId',
                                                url: videoUrl,
                                                height: 280,
                                              ),
                                            ] else ...[
                                              const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(32.0),
                                                  child: Text(
                                                    "Nu există înregistrare video încărcată pentru această lecție.",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (pdfUrl.isNotEmpty) ...[
                                              UniversalEmbeddedViewer(
                                                viewId: 'pdf_$lessonId',
                                                url:
                                                    pdfUrl.contains(
                                                          'drive.google.com',
                                                        ) ||
                                                        pdfUrl.contains(
                                                          'firebasestorage',
                                                        )
                                                    ? 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(pdfUrl)}'
                                                    : pdfUrl,
                                                height: 420,
                                              ),
                                            ] else ...[
                                              const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(32.0),
                                                  child: Text(
                                                    "Nu a fost încărcat niciun fișier PDF pentru temă încă.",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

// DEFINIȚIA CLASEI UNIVERSAL EMBEDDED VIEWER (ÎN AFARA CLASEI PRINCIPALE)
class UniversalEmbeddedViewer extends StatefulWidget {
  final String viewId;
  final String url;
  final double height;

  const UniversalEmbeddedViewer({
    super.key,
    required this.viewId,
    required this.url,
    required this.height,
  });

  @override
  State<UniversalEmbeddedViewer> createState() =>
      _UniversalEmbeddedViewerState();
}

class _UniversalEmbeddedViewerState extends State<UniversalEmbeddedViewer> {
  WebViewController? _mobileController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _mobileController?.runJavaScript('''
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
                document.getElementsByTagName('head')[0].appendChild(meta);
              ''');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        child: kIsWeb
            ? getWebIframe(widget.viewId, widget.url)
            : (_mobileController != null
                  ? WebViewWidget(controller: _mobileController!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    )),
      ),
    );
  }
}
