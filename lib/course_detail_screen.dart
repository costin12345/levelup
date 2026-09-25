import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final String category;
  final String description;
  final String role;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
    required this.title,
    required this.category,
    required this.description,
    required this.role,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  // Trimitere Push Notification direct către un token FCM
  Future<void> sendPushNotification(String fcmToken, String lessonTitle) async {
    try {
      const String serverKey = 'AICI_PUI_SERVER_KEY_DIN_FIREBASE';

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'to': fcmToken,
          'priority': 'high',
          'notification': <String, dynamic>{
            'title': 'Lecție nouă în ${widget.title}',
            'body': 'A fost adăugată lecția: "$lessonTitle"',
            'sound': 'default',
            'badge': '1',
          },
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'courseId': widget.courseId,
          },
        }),
      );
    } catch (e) {
      debugPrint("Eroare trimitere Push Notification: $e");
    }
  }

  // Salvarea lecției și notificarea tuturor elevilor din curs
  Future<void> _saveLessonAndNotify() async {
    final String lessonTitle = _titleController.text.trim();
    final String lessonContent = _contentController.text.trim();

    if (lessonTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vă rugăm să introduceți titlul lecției.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Salvează lecția în sub-colecția cursului
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('lessons')
          .add({
            'title': lessonTitle,
            'content': lessonContent,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Preia toți elevii aprobați pentru acest curs
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: widget.courseId)
          .where('status', isEqualTo: 'approved')
          .get();

      // 3. Parcurge fiecare elev înrolat
      for (var doc in enrollmentsSnapshot.docs) {
        String studentId = doc['userId'];

        // Notificare In-App
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': studentId,
          'title': 'Lecție nouă în ${widget.title}',
          'body': 'A fost adăugată: "$lessonTitle"',
          'courseId': widget.courseId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Extragere FCM Token
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = userData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await sendPushNotification(fcmToken, lessonTitle);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lecție salvată și notificări trimise!'),
          ),
        );
        _titleController.clear();
        _contentController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('A apărut o eroare: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddLessonDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Adaugă o lecție nouă',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titlu Lecție',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Conținut Lecție (opțional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLessonAndNotify,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Salvează și Notifică Elevii'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.role == 'teacher';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('lessons')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nu există lecții adăugate în acest curs.'),
            );
          }

          final lessons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(
                    lesson['title'] ?? 'Fără titlu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lesson['content'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: _showAddLessonDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adaugă Lecție'),
            )
          : null,
    );
  }
}
