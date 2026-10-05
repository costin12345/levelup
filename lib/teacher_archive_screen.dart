import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Folosit pentru deschiderea link-urilor către teste (PDF/Drive)

class TeacherArchiveScreen extends StatefulWidget {
  final String currentUserId;

  const TeacherArchiveScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  State<TeacherArchiveScreen> createState() => _TeacherArchiveScreenState();
}

class _TeacherArchiveScreenState extends State<TeacherArchiveScreen> {
  String _selectedCourseFilter = "Toate";
  String _selectedYearFilter = "Toate";

  final List<String> _courses = [
    "Toate",
    "Matematică",
    "Informatică",
    "Fizică",
  ];
  final List<String> _years = ["Toate", "2026", "2025", "2024", "2023", "2022"];

  // Funcție pentru a deschide link-ul subiectului (PDF / Google Drive)
  Future<void> _openTestLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nu s-a putut deschide link-ul fișierului!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dialog pentru adăugarea unui test nou în arhivă de către profesor
  void _showAddTestDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController highSchoolController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    String selectedCourse = "Matematică";
    String selectedYear = "2026";
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xfffff8dc),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.archive, color: Color(0xff42153e), size: 26),
                  SizedBox(width: 10),
                  Text(
                    "Adaugă Subiect în Arhivă",
                    style: TextStyle(
                      color: Color(0xff42153e),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Titlul Testului (ex: Simulare Județeană)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: highSchoolController,
                        decoration: InputDecoration(
                          labelText: 'Liceul / Centrul de Examen',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCourse,
                        decoration: InputDecoration(
                          labelText: 'Materia',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ["Matematică", "Informatică", "Fizică"]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedCourse = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Anul Subiectului',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ["2026", "2025", "2024", "2023", "2022", "2021"]
                            .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedYear = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'Link PDF / Google Drive către subiect',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff42153e),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              urlController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Completează titlul și link-ul fișierului!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isUploading = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection('archive_tests')
                                .add({
                                  'title': titleController.text.trim(),
                                  'highSchool':
                                      highSchoolController.text.trim().isEmpty
                                      ? 'Liceu Necunoscut'
                                      : highSchoolController.text.trim(),
                                  'course': selectedCourse,
                                  'year': selectedYear,
                                  'fileUrl': urlController.text.trim(),
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '📁 Testul a fost adăugat cu succes în arhivă!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            debugPrint("Eroare la adăugarea testului: $e");
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Salvează"),
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
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        title: const Text('Arhiva Națională de Subiecte — Profesori'),
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
        onPressed: () => _showAddTestDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Adaugă Subiect"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Bara de filtre
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCourseFilter,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                        items: _courses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text("Materie: $c"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCourseFilter = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYearFilter,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                        items: _years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text("An: $y"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedYearFilter = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📚 Lista subiectelor din arhivă
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('archive_tests')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nu există teste în arhivă momentan.\nFolosește butonul de mai jos pentru a adăuga primul subiect!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  // Aplicăm filtrele alese de profesor
                  if (_selectedCourseFilter != "Toate") {
                    docs = docs
                        .where(
                          (d) =>
                              (d.data() as Map<String, dynamic>)['course'] ==
                              _selectedCourseFilter,
                        )
                        .toList();
                  }
                  if (_selectedYearFilter != "Toate") {
                    docs = docs
                        .where(
                          (d) =>
                              (d.data() as Map<String, dynamic>)['year'] ==
                              _selectedYearFilter,
                        )
                        .toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nun s-a găsit niciun test conform filtrelor selectate.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String title = data['title'] ?? 'Subiect Fără Titlu';
                      String highSchool =
                          data['highSchool'] ?? 'Liceu Necunoscut';
                      String course = data['course'] ?? 'Matematică';
                      String year = data['year'] ?? '2026';
                      String fileUrl = data['fileUrl'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff42153e).withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xfffff3cd),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Color(0xff42153e),
                              size: 26,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff42153e),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                "🏫 $highSchool",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      course,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xff42153e),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      "An: $year",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff42153e),
                                      ),
                                    ),
                                    backgroundColor: Colors.amber.shade100,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Color(0xff42153e),
                              size: 28,
                            ),
                            onPressed: () {
                              if (fileUrl.isNotEmpty) {
                                _openTestLink(fileUrl);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Acest subiect nu are atașat un link valid!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
