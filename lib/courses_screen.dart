import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

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

/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'lesson_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final String role;
  const CoursesScreen({super.key, required this.role});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedSubject = "Matematică";
  DocumentSnapshot? _selectedCourseDoc;

  final List<String> _subjects = ["Matematică", "Informatică", "Fizică"];

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);
    bool isMobile = MediaQuery.of(context).size.width < 750;

    Widget subjectsDrawerContent = Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentLila.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book, color: accentLila, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                "Materii Cursuri",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: primaryIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                String subject = _subjects[index];
                bool isSelected = _selectedSubject == subject;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubject = subject;
                      _selectedCourseDoc = null;
                    });
                    if (isMobile) Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentLila.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 18,
                          color: isSelected ? accentLila : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          subject,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? primaryIndigo
                                : Colors.grey.shade700,
                          ),
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

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      drawer: isMobile ? Drawer(child: subjectsDrawerContent) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            subjectsDrawerContent,
            const VerticalDivider(width: 1, color: Colors.black12),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isMobile)
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: primaryIndigo,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                  tooltip: "Meniu Materii",
                                ),
                              ),
                            if (_selectedCourseDoc != null)
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() {
                                  _selectedCourseDoc = null;
                                }),
                              ),
                            Flexible(
                              child: Text(
                                _selectedCourseDoc != null
                                    ? "${_selectedCourseDoc!['title']}"
                                    : "Cursuri - $_selectedSubject",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: primaryIndigo,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.role == 'teacher' &&
                          _selectedCourseDoc == null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddCourseDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentLila,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Curs"),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _selectedCourseDoc == null
                        ? _buildCoursesList(accentLila, primaryIndigo, isMobile)
                        : _buildCourseGroupsWithTabs(
                            _selectedCourseDoc!.id,
                            accentLila,
                            primaryIndigo,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(
    Color accentLila,
    Color primaryIndigo,
    bool isMobile,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('subject', isEqualTo: _selectedSubject)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text("Nu există cursuri adăugate pentru această materie."),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 3.5 : 2.5,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () => setState(() => _selectedCourseDoc = doc),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.school, color: accentLila),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              data['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryIndigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.role == 'teacher')
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => doc.reference.delete(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseGroupsWithTabs(
    String courseId,
    Color accentLila,
    Color primaryIndigo,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('groups')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var groupDocs = snapshot.data!.docs;
        if (groupDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Nu există grupe create în acest curs."),
                const SizedBox(height: 16),
                // 🚀 Buton explicit afișat profesorului când nu există grupe
                if (widget.role == 'teacher')
                  ElevatedButton.icon(
                    onPressed: () => _showAddGroupDialog(context, courseId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentLila,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.group_add, size: 18),
                    label: const Text("Adaugă Prima Grupă"),
                  ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: groupDocs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        labelColor: Colors.white,
                        unselectedLabelColor: primaryIndigo,
                        indicator: BoxDecoration(
                          color: accentLila,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: groupDocs.map((groupDoc) {
                          var groupData =
                              groupDoc.data() as Map<String, dynamic>;
                          return Tab(text: groupData['groupName'] ?? 'Grupă');
                        }).toList(),
                      ),
                    ),
                  ),
                  if (widget.role == 'teacher') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddGroupDialog(context, courseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryIndigo,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.group_add, size: 16),
                      label: const Text("Grupă"),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: groupDocs.map((groupDoc) {
                    String groupId = groupDoc.id;
                    var groupData = groupDoc.data() as Map<String, dynamic>;
                    String groupName = groupData['groupName'] ?? 'Grupă';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Lecții: $groupName",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryIndigo,
                                  ),
                                ),
                                if (widget.role == 'teacher') ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () => _confirmAndDeleteGroup(
                                      context,
                                      courseId,
                                      groupId,
                                      groupName,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.role == 'teacher')
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddLessonDialog(context, groupId),
                                icon: Icon(
                                  Icons.add,
                                  color: accentLila,
                                  size: 16,
                                ),
                                label: Text(
                                  "Lecție",
                                  style: TextStyle(color: accentLila),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _buildLessonsList(
                            groupId,
                            accentLila,
                            primaryIndigo,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonsList(
    String groupId,
    Color accentLila,
    Color primaryIndigo,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('course_groups')
          .doc(groupId)
          .collection('lessons')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Nu există lecții adăugate în această grupă.",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonDetailScreen(
                          courseId: groupId,
                          lessonId: doc.id,
                          lessonTitle: data['title'] ?? 'Lecție',
                          role: widget.role,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.play_lesson, color: accentLila),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Lecție fără titlu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: primaryIndigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDeleteGroup(
    BuildContext context,
    String courseId,
    String groupId,
    String groupName,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere grupă "$groupName"'),
        content: const Text(
          'Ești sigur că vrei să ștergi această grupă? Toate lecțiile vor fi eliminate.',
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
      try {
        var lessonsSnap = await FirebaseFirestore.instance
            .collection('course_groups')
            .doc(groupId)
            .collection('lessons')
            .get();

        for (var doc in lessonsSnap.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('course_groups')
            .doc(groupId)
            .delete();

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('groups')
            .doc(groupId)
            .delete();
      } catch (e) {
        debugPrint("Eroare la ștergerea grupei: $e");
      }
    }
  }

  void _showAddCourseDialog(BuildContext context) {
    String title = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adaugă Curs Nou pentru $_selectedSubject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Titlu Curs / Clasă (ex: Clasa a 9-a)",
                ),
                onChanged: (val) => title = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Descriere"),
                onChanged: (val) => description = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('courses').add({
                    'title': title,
                    'description': description,
                    'subject': _selectedSubject,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Salvează"),
            ),
          ],
        );
      },
    );
  }

  void _showAddGroupDialog(BuildContext context, String courseId) {
    String groupName = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adaugă Grupă Nouă"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Nume Grupă (ex: Grupa 1)",
                ),
                onChanged: (val) => groupName = val,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Descriere / Detalii",
                ),
                onChanged: (val) => description = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupName.isNotEmpty) {
                  var docRef = await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .collection('groups')
                      .add({
                        'groupName': groupName,
                        'description': description,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  await FirebaseFirestore.instance
                      .collection('course_groups')
                      .doc(docRef.id)
                      .set({'groupName': groupName, 'courseId': courseId});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Salvează"),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonDialog(BuildContext context, String groupId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final homeworkContentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adaugă Lecție Nouă"),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
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
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Conținut / Explicații Teoretice",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: homeworkContentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Cerințe Temă",
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
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              onPressed: () async {
                final String lTitle = titleController.text.trim();
                if (lTitle.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('course_groups')
                      .doc(groupId)
                      .collection('lessons')
                      .add({
                        'title': lTitle,
                        'content': contentController.text.trim(),
                        'homeworkContent': homeworkContentController.text
                            .trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Salvează"),
            ),
          ],
        );
      },
    );
  }
}
*/
