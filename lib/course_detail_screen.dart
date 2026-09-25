import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:url_launcher/url_launcher.dart';
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

  // Funcție de trimitere Push Notification prin FCM API v1 către toți elevii aprobați
  Future<void> _sendPushToStudents(String lessonTitle) async {
    try {
      // 1. Credentials din fișierul Service Account JSON descărcat din Firebase Console
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        {
          "type": "service_account",
          "project_id": "level-up-19583",
          "private_key_id": "VALOAREA_PRIVATE_KEY_ID_DIN_JSON",
          "private_key": "-----BEGIN PRIVATE KEY-----\nVALOAREA_PRIVATE_KEY_DIN_JSON\n-----END PRIVATE KEY-----\n",
          "client_email": "VALOAREA_CLIENT_EMAIL_DIN_JSON",
          "client_id": "VALOAREA_CLIENT_ID_DIN_JSON",
        },
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        serviceAccountCredentials,
        scopes,
      );

      // 2. Găsim toți elevii aprobați la acest curs
      final enrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (enrollments.docs.isEmpty) {
        client.close();
        return;
      }

      final String fcmV1Url =
          'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

      for (var doc in enrollments.docs) {
        String userId = doc['userId'];

        // Salvare notificare in-app
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Lecție nouă în $title',
          'body': 'A fost adăugată: "$lessonTitle"',
          'courseId': courseId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = uData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            // 3. Trimitere cerere FCM API v1 cu payload corectat
            final response = await client.post(
              Uri.parse(fcmV1Url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': {
                  'token': fcmToken,
                  'notification': {
                    'title': 'Lecție nouă în $title 📚',
                    'body': 'A fost adăugată lecția: "$lessonTitle"',
                  },
                  'android': {
                    'priority': 'HIGH',
                    'notification': {
                      'sound': 'default',
                      'default_vibrate_timings': true,
                    },
                  },
                  'apns': {
                    'headers': {'apns-priority': '10'},
                    'payload': {
                      'aps': {
                        'alert': {
                          'title': 'Lecție nouă în $title 📚',
                          'body': 'A fost adăugată lecția: "$lessonTitle"',
                        },
                        'sound': 'default',
                        'badge': 1,
                        'content-available': 1,
                      },
                    },
                  },
                  'data': {
                    'courseId': courseId,
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );

            debugPrint("FCM v1 Response status: ${response.statusCode}");
            debugPrint("FCM v1 Response body: ${response.body}");
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint("Eroare la trimiterea notificarii FCM v1: $e");
    }
  }

  Future<void> _openUrl(String urlString, BuildContext context) async {
    if (urlString.trim().isEmpty) return;
    final Uri url = Uri.parse(urlString.trim());
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nu s-a putut deschide link-ul: $urlString'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Eroare: $e')));
      }
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

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
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
                      labelText: "Link Video Bunny Embed",
                      hintText: "https://iframe.mediadelivery.net/embed/...",
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
                      labelText: "Link Document PDF",
                      hintText: "https://.../fisier.pdf",
                      prefixIcon: Icon(Icons.picture_as_pdf, color: Colors.red),
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
                  // 1. Salvare Lecție în Firestore
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

                  // 2. Trimitere Push Notification la toți elevii
                  await _sendPushToStudents(lTitle);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lecție salvată și notificări trimise!'),
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
  }

  @override
  Widget build(BuildContext context) {
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    "📹 Video Lecție",
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
                                    height: 250,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (pdfUrl.isNotEmpty) ...[
                                  const Text(
                                    "📄 Suport de Curs (PDF)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xff42153e),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  UniversalEmbeddedViewer(
                                    viewId: 'pdf_$lessonId',
                                    url:
                                        pdfUrl.contains('drive.google.com') ||
                                            pdfUrl.contains('firebasestorage')
                                        ? 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(pdfUrl)}'
                                        : pdfUrl,
                                    height: 450,
                                  ),
                                ],
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
      child: kIsWeb
          ? getWebIframe(widget.viewId, widget.url)
          : (_mobileController != null
                ? WebViewWidget(controller: _mobileController!)
                : const Center(child: CircularProgressIndicator())),
    );
  }
}
