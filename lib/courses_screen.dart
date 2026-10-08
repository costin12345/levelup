import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key, required String role});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedCategoryFilter = 'Toate';

  final List<String> _allCategories = [
    'Matematică - Clasa a V-a',
    'Matematică - Clasa a VI-a',
    'Matematică - Clasa a VII-a',
    'Matematică - Clasa a VIII-a',
    'Matematică - Clasa a IX-a',
    'Matematică - Clasa a X-a',
    'Matematică - Clasa a XI-a',
    'Matematică - Clasa a XII-a',
    'Matematică - Admitere',
    'Fizică - Clasa a IX-a',
    'Fizică - Clasa a X-a',
    'Fizică - Clasa a XI-a',
    'Fizică - Clasa a XII-a',
    'Fizică - Admitere',
    'Informatică - Clasa a IX-a',
    'Informatică - Clasa a X-a',
    'Informatică - Clasa a XI-a',
    'Informatică - Clasa a XII-a',
    'Informatică - Admitere',
  ];

  // Trimiterea cererii de înscriere de către elev (salvăm și numele complet)
  Future<void> _requestEnrollment(
    String courseId,
    String userId,
    String userEmail,
    String userName,
  ) async {
    final enrollmentId = '${courseId}_$userId';
    await FirebaseFirestore.instance
        .collection('enrollments')
        .doc(enrollmentId)
        .set({
          'courseId': courseId,
          'userId': userId,
          'userEmail': userEmail,
          'userName': userName,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cererea de înscriere a fost trimisă!')),
      );
    }
  }

  // Dialog de adăugare curs (doar pentru profesori)
  void _showAddCourseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _allCategories.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                "Adaugă Curs Nou",
                style: TextStyle(
                  color: Color(0xff42153e),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Titlu Curs",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Categorie",
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _allCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() => selectedCategory = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Descriere Curs",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                    if (titleController.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('courses')
                          .add({
                            'title': titleController.text.trim(),
                            'category': selectedCategory,
                            'description': descriptionController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff42153e),
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

  // Ştergere curs (doar pentru profesori)
  Future<void> _deleteCourse(String courseId, String courseTitle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere "$courseTitle"'),
        content: const Text(
          'Ești sigur că vrei să ștergi acest curs? Toate datele vor fi șterse definitiv.',
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
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cursul a fost șters cu succes!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Eroare la ștergere: $e')));
        }
      }
    }
  }

  // Dialog pentru aprobarea cererilor (Afișează Nume Elev + Titlu Curs)
  void _showPendingRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cereri de Înscriere în Așteptare",
          style: TextStyle(
            color: Color(0xff42153e),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('enrollments')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff42153e)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Nu există cereri în așteptare.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final requests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final data = req.data() as Map<String, dynamic>;
                  final String userId = data['userId'] ?? '';
                  final String courseId = data['courseId'] ?? '';
                  final String fallbackName =
                      data['userName'] ?? data['userEmail'] ?? 'Elev';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        // Numele complet al elevului
                        title: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnap) {
                            if (userSnap.hasData && userSnap.data!.exists) {
                              var uData =
                                  userSnap.data!.data() as Map<String, dynamic>;
                              String fullName =
                                  uData['fullName'] ?? fallbackName;
                              return Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xff42153e),
                                ),
                              );
                            }
                            return Text(
                              fallbackName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            );
                          },
                        ),
                        // Titlul cursului solicitat
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('courses')
                              .doc(courseId)
                              .get(),
                          builder: (context, courseSnap) {
                            if (courseSnap.hasData && courseSnap.data!.exists) {
                              var cData =
                                  courseSnap.data!.data()
                                      as Map<String, dynamic>;
                              return Text(
                                'Curs: ${cData['title'] ?? 'Fără titlu'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            return const Text('Se încarcă cursul...');
                          },
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
                              tooltip: "Aprobă",
                              onPressed: () =>
                                  req.reference.update({'status': 'approved'}),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 28,
                              ),
                              tooltip: "Respinge",
                              onPressed: () =>
                                  req.reference.update({'status': 'rejected'}),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Închide"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Utilizator neconectat."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff42153e)),
          );
        }

        String role = 'student';
        String currentUserName = 'Elev';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          role = userData['role'] ?? 'student';
          currentUserName = userData['fullName'] ?? 'Elev';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Toate Cursurile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff42153e),
                    ),
                  ),
                  if (role == 'teacher') ...[
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_active,
                        color: Colors.amber,
                        size: 26,
                      ),
                      onPressed: _showPendingRequestsDialog,
                      tooltip: "Cereri Înscriere",
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddCourseDialog,
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text("Adaugă Curs"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff42153e),
                        foregroundColor: Colors.amber,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // FILTRE
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip("Toate"),
                    _buildFilterChip("Matematică"),
                    _buildFilterChip("Fizică"),
                    _buildFilterChip("Informatică"),
                    _buildFilterChip("Admitere"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // LISTA DE CURSURI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, coursesSnapshot) {
                  if (!coursesSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    );
                  }

                  var filteredDocs = coursesSnapshot.data!.docs.where((doc) {
                    if (_selectedCategoryFilter == 'Toate') return true;
                    var data = doc.data() as Map<String, dynamic>;
                    String cat = data['category'] ?? '';
                    return cat.contains(_selectedCategoryFilter);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Nu am găsit cursuri pentru categoria '$_selectedCategoryFilter'.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var courseDoc = filteredDocs[index];
                      var courseData = courseDoc.data() as Map<String, dynamic>;
                      String courseId = courseDoc.id;
                      String title = courseData['title'] ?? '';
                      String category = courseData['category'] ?? '';
                      String description = courseData['description'] ?? '';

                      if (role == 'teacher') {
                        return _buildCourseCard(
                          courseId: courseId,
                          title: title,
                          category: category,
                          description: description,
                          role: role,
                          isApproved: true,
                          actionWidget: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteCourse(courseId, title),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        );
                      }

                      // Pentru Elevi: Verificăm starea înscrierii
                      final enrollmentId = '${courseId}_${currentUser.uid}';
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('enrollments')
                            .doc(enrollmentId)
                            .snapshots(),
                        builder: (context, enrollSnap) {
                          String status = 'none';
                          if (enrollSnap.hasData && enrollSnap.data!.exists) {
                            status = enrollSnap.data!['status'] ?? 'none';
                          }

                          Widget buttonWidget;
                          bool canAccess = false;

                          if (status == 'approved') {
                            canAccess = true;
                            buttonWidget = const Text(
                              "Intră la Curs",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else if (status == 'pending') {
                            buttonWidget = Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "În Așteptare",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else {
                            buttonWidget = ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff42153e),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _requestEnrollment(
                                courseId,
                                currentUser.uid,
                                currentUser.email ?? '',
                                currentUserName,
                              ),
                              child: const Text(
                                "Solicită Înscrierea",
                                style: TextStyle(fontSize: 12),
                              ),
                            );
                          }

                          return _buildCourseCard(
                            courseId: courseId,
                            title: title,
                            category: category,
                            description: description,
                            role: role,
                            isApproved: canAccess,
                            actionWidget: buttonWidget,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard({
    required String courseId,
    required String title,
    required String category,
    required String description,
    required String role,
    required bool isApproved,
    required Widget actionWidget,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (role == 'teacher' || isApproved) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  courseId: courseId,
                  title: title,
                  category: category,
                  description: description,
                  role: role,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Trebuie să fii înscris și aprobat de profesor pentru a accesa acest curs!',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 11,
                      ),
                    ),
                  ),
                  actionWidget,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff42153e),
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedCategoryFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff42153e),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        selectedColor: const Color(0xff42153e),
        backgroundColor: Colors.white,
        checkmarkColor: Colors.amber,
        onSelected: (selected) {
          setState(() => _selectedCategoryFilter = label);
        },
      ),
    );
  }
}
