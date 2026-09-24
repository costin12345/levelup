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

  // Lista completă de categorii solicitată
  final List<String> _allCategories = [
    // Matematică
    'Matematică - Clasa a V-a',
    'Matematică - Clasa a VI-a',
    'Matematică - Clasa a VII-a',
    'Matematică - Clasa a VIII-a',
    'Matematică - Clasa a IX-a',
    'Matematică - Clasa a X-a',
    'Matematică - Clasa a XI-a',
    'Matematică - Clasa a XII-a',
    'Matematică - Admitere',
    // Fizică
    'Fizică - Clasa a IX-a',
    'Fizică - Clasa a X-a',
    'Fizică - Clasa a XI-a',
    'Fizică - Clasa a XII-a',
    'Fizică - Admitere',
    // Informatică
    'Informatică - Clasa a IX-a',
    'Informatică - Clasa a X-a',
    'Informatică - Clasa a XI-a',
    'Informatică - Clasa a XII-a',
    'Informatică - Admitere',
  ];

  // Dialog adăugare curs (doar pentru profesori)
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
                        labelText: "Titlu Curs (ex: Algoritmi pe Grafuri)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Categorie & Clasă",
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
                          setDialogState(() {
                            selectedCategory = newValue;
                          });
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

  // Funcție de ștergere curs cu confirmare (doar pentru profesori)
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

        bool hasAccess = false;
        String role = 'student';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          hasAccess = userData['hasAccess'] ?? false;
          role = userData['role'] ?? 'student';
        }

        if (!hasAccess) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 72,
                    color: Color(0xff42153e),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Acces Restricționat",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff42153e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Contul tău este în curs de verificare. Accesul la cursuri va fi activat în curând!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER: TITLU + BUTON ADAUGĂ (EXCLUSIV PROFESORI)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cursurile Tale",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff42153e),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Selectează materia și clasa dorită",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (role == 'teacher')
                      ElevatedButton.icon(
                        onPressed: _showAddCourseDialog,
                        icon: const Icon(Icons.add_circle, size: 18),
                        label: const Text(
                          "Adaugă Curs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff42153e),
                          foregroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // FILTRU DE MATERII (BUTOANE DERULABILE PE ORIZONTALĂ)
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

                // LISTA DE CURSURI ÎNCĂRCATĂ DIN FIRESTORE
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, coursesSnapshot) {
                    if (coursesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Color(0xff42153e),
                          ),
                        ),
                      );
                    }

                    if (!coursesSnapshot.hasData ||
                        coursesSnapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              "Nu există cursuri adăugate momentan.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filtrare locală după butonul apăsat de elev
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
                        var courseData =
                            courseDoc.data() as Map<String, dynamic>;
                        String courseId = courseDoc.id;
                        String title = courseData['title'] ?? 'Fără titlu';
                        String category = courseData['category'] ?? 'General';
                        String description = courseData['description'] ?? '';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
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
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      Row(
                                        children: [
                                          if (role == 'teacher')
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () => _deleteCourse(
                                                courseId,
                                                title,
                                              ),
                                            ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
      },
    );
  }

  // Widget pentru pastilele de filtrare
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
          setState(() {
            _selectedCategoryFilter = label;
          });
        },
      ),
    );
  }
}
