import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  String? _selectedClass; // Nivelul 2: Dacă este selectată o clasă, afișăm grupele din acea clasă

  // ================= DIALOGURI PENTRU CLASE (NIVELUL 1) =================
  void _showAddOrEditClassDialog({String? oldClassName}) {
    final classNameController = TextEditingController(text: oldClassName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          oldClassName == null
              ? 'Adaugă Clasă Nouă'
              : 'Editează Denumirea Clasei',
        ),
        content: TextField(
          controller: classNameController,
          decoration: const InputDecoration(
            labelText: 'Nume Clasă (ex: Clasa a V-a)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff42153e),
            ),
            onPressed: () async {
              String newName = classNameController.text.trim();
              if (newName.isEmpty) return;

              if (oldClassName == null) {
                // Adăugăm un curs inițial în această clasă pentru a o crea în baza de date
                await FirebaseFirestore.instance.collection('courses').add({
                  'title': 'Prima Grupă / Curs',
                  'className': newName,
                  'category': newName,
                  'description': 'Grupă generată automat pentru clasa $newName',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                // Actualizăm denumirea clasei pentru toate cursurile care aparțineau vechii clase
                var snapshot = await FirebaseFirestore.instance
                    .collection('courses')
                    .where('className', isEqualTo: oldClassName)
                    .get();

                for (var doc in snapshot.docs) {
                  await doc.reference.update({'className': newName});
                }
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      oldClassName == null
                          ? 'Clasa a fost adăugată!'
                          : 'Clasa a fost actualizată!',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Salvează',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(
    String className,
    List<QueryDocumentSnapshot> allDocs,
  ) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Șterge clasa "$className"?'),
        content: const Text(
          'Această acțiune va șterge clasa și toate grupele/cursurile asociate ei!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Șterge Tot',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var coursesToDelete = allDocs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return (data['className'] ?? data['category'] ?? 'Clasa Generală') ==
            className;
      }).toList();

      for (var doc in coursesToDelete) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clasa "$className" a fost ștersă.')),
        );
      }
    }
  }

  // ================= DIALOGURI PENTRU GRUPE / CURSURI (NIVELUL 2) =================
  void _showAddOrEditGroupDialog({DocumentSnapshot? existingCourse}) {
    var data = existingCourse?.data() as Map<String, dynamic>?;

    final titleController = TextEditingController(text: data?['title'] ?? '');
    final descriptionController = TextEditingController(
      text: data?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existingCourse == null
              ? 'Adaugă Grupă Nouă în $_selectedClass'
              : 'Editează Grupa',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Nume Grupă / Curs (ex: Grupa 5A, Matematică)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descriere scurtă',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff42153e),
            ),
            onPressed: () async {
              String title = titleController.text.trim();
              if (title.isEmpty) return;

              if (existingCourse == null) {
                await FirebaseFirestore.instance.collection('courses').add({
                  'title': title,
                  'className': _selectedClass!,
                  'category': _selectedClass!,
                  'description': descriptionController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await existingCourse.reference.update({
                  'title': title,
                  'description': descriptionController.text.trim(),
                });
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grupa a fost salvată cu succes!'),
                  ),
                );
              }
            },
            child: const Text(
              'Salvează',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(String courseId, String courseTitle) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Șterge grupa "$courseTitle"?'),
        content: const Text(
          'Această acțiune va șterge grupa și toate lecțiile din ea.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Grupa a fost ștearsă.')));
      }
    }
  }

  // Solicitare înscriere elev
  Future<void> _requestEnrollment(String courseId, String courseTitle) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': currentUser!.uid,
        'courseId': courseId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitarea de înscriere a fost trimisă!'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Eroare înscriere: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
        title: Text(
          _selectedClass == null
              ? 'Clase Disponibile'
              : 'Grupe: $_selectedClass',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _selectedClass != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedClass = null),
              )
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff42153e)),
            );
          }

          var allDocs = snapshot.hasData ? snapshot.data!.docs : [];

          // ================= NIVELUL 1: AFIȘARE CLASE =================
          if (_selectedClass == null) {
            Set<String> uniqueClasses = {};
            for (var doc in allDocs) {
              var data = doc.data() as Map<String, dynamic>;
              String className =
                  data['className'] ?? data['category'] ?? 'Clasa Generală';
              uniqueClasses.add(className);
            }
            var classList = uniqueClasses.toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.role == 'teacher') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddOrEditClassDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xff42153e),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xff42153e),
                        ),
                        label: const Text(
                          'Adaugă Clasă Nouă',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Selectează o clasă:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff42153e),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: classList.isEmpty
                        ? const Center(
                            child: Text(
                              "Nu există clase adăugate.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: classList.length,
                            itemBuilder: (context, index) {
                              String className = classList[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xff42153e),
                                    child: Icon(
                                      Icons.school,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    className,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff42153e),
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Apasă pentru a vedea grupele',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.role == 'teacher') ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue,
                                            size: 22,
                                          ),
                                          tooltip: 'Editează Clasa',
                                          onPressed: () =>
                                              _showAddOrEditClassDialog(
                                                oldClassName: className,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 22,
                                          ),
                                          tooltip: 'Șterge Clasa',
                                          onPressed: () => _deleteClass(
                                            className,
                                            allDocs
                                                as List<QueryDocumentSnapshot>,
                                          ),
                                        ),
                                      ],
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedClass = className;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          // ================= NIVELUL 2: AFIȘARE GRUPE DIN CLASA SELECTATĂ =================
          var filteredGroups = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String className =
                data['className'] ?? data['category'] ?? 'Clasa Generală';
            return className == _selectedClass;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.role == 'teacher') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddOrEditGroupDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xff42153e),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xff42153e),
                      ),
                      label: const Text(
                        'Adaugă Grupă Nouă',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: filteredGroups.isEmpty
                      ? const Center(
                          child: Text(
                            "Nu există grupe în această clasă.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            var groupDoc = filteredGroups[index];
                            var groupData =
                                groupDoc.data() as Map<String, dynamic>;
                            String courseId = groupDoc.id;
                            String title =
                                groupData['title'] ?? 'Grupă fără titlu';
                            String description = groupData['description'] ?? '';

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff42153e),
                                          ),
                                        ),
                                        if (widget.role == 'teacher')
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blue,
                                                  size: 22,
                                                ),
                                                tooltip: 'Editează Grupa',
                                                onPressed: () =>
                                                    _showAddOrEditGroupDialog(
                                                      existingCourse: groupDoc,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 22,
                                                ),
                                                tooltip: 'Șterge Grupa',
                                                onPressed: () => _deleteGroup(
                                                  courseId,
                                                  title,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        description,
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
                                              builder: (context) =>
                                                  CourseDetailScreen(
                                                    courseId: courseId,
                                                    title: title,
                                                    category: _selectedClass!,
                                                    description: description,
                                                    role: widget.role,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff42153e,
                                          ),
                                          foregroundColor: Colors.amber,
                                        ),
                                        icon: const Icon(Icons.menu_book),
                                        label: const Text(
                                          'Administrează Lecțiile',
                                        ),
                                      )
                                    else
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('enrollments')
                                            .where(
                                              'courseId',
                                              isEqualTo: courseId,
                                            )
                                            .where(
                                              'userId',
                                              isEqualTo: currentUser?.uid,
                                            )
                                            .snapshots(),
                                        builder: (context, enrollSnap) {
                                          if (!enrollSnap.hasData ||
                                              enrollSnap.data!.docs.isEmpty) {
                                            return ElevatedButton.icon(
                                              onPressed: () =>
                                                  _requestEnrollment(
                                                    courseId,
                                                    title,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xff42153e,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              label: const Text(
                                                'Solicită înscriere',
                                              ),
                                            );
                                          }

                                          var enrollData =
                                              enrollSnap.data!.docs.first.data()
                                                  as Map<String, dynamic>;
                                          String status =
                                              enrollData['status'] ?? 'pending';

                                          if (status == 'approved') {
                                            return ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CourseDetailScreen(
                                                          courseId: courseId,
                                                          title: title,
                                                          category:
                                                              _selectedClass!,
                                                          description:
                                                              description,
                                                          role: widget.role,
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(
                                                Icons.play_circle_fill,
                                              ),
                                              label: const Text(
                                                'Intră la Curs',
                                              ),
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
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                ),
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
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
