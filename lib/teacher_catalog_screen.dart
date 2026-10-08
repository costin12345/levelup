import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import 'add_grade_dialog.dart';

class TeacherCatalogScreen extends StatefulWidget {
  const TeacherCatalogScreen({super.key});

  @override
  State<TeacherCatalogScreen> createState() => _TeacherCatalogScreenState();
}

class _TeacherCatalogScreenState extends State<TeacherCatalogScreen> {
  String _selectedFilterClass = "Toate";
  String _selectedFilterGroup = "Toate";
  String _selectedFilterCourse = "Toate";
  String _selectedFilterGrade = "Toate";
  String _selectedFilterType = "Toate";
  String? _selectedSingleStudent;

  String _activeCatalogMenu = "Note și Absențe";
  String _reportScope = "Pe Grupe";

  bool _isArhivaTestExpanded = false;
  String? _selectedClassTab;

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    bool isMediiPeGrupa = _activeCatalogMenu == "Medii pe Grupă";
    bool isRapoarte = _activeCatalogMenu == "Rapoarte Academice";
    bool isArhivadTeste = _activeCatalogMenu == "Arhivă Teste";

    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget sidebarContent = Column(
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
              "Meniu Catalog",
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

        _buildSidebarItem(
          "Note și Absențe",
          Icons.fact_check,
          accentLila,
          primaryIndigo,
          onTap: () {
            setState(() => _activeCatalogMenu = "Note și Absențe");
            if (isMobile) Navigator.pop(context);
          },
        ),
        _buildSidebarItem(
          "Medii pe Grupă",
          Icons.bar_chart,
          accentLila,
          primaryIndigo,
          onTap: () {
            setState(() => _activeCatalogMenu = "Medii pe Grupă");
            if (isMobile) Navigator.pop(context);
          },
        ),
        _buildSidebarItem(
          "Rapoarte Academice",
          Icons.description_outlined,
          accentLila,
          primaryIndigo,
          onTap: () {
            setState(() => _activeCatalogMenu = "Rapoarte Academice");
            if (isMobile) Navigator.pop(context);
          },
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isArhivaTestExpanded = !_isArhivaTestExpanded;
                  if (_isArhivaTestExpanded && _selectedClassTab == null) {
                    _selectedClassTab = "Clasa a 4-a";
                    _activeCatalogMenu = "Arhivă Teste";
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isArhivadTeste
                      ? accentLila.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      size: 18,
                      color: isArhivadTeste ? accentLila : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Arhivă Teste",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isArhivadTeste
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isArhivadTeste
                              ? primaryIndigo
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Icon(
                      _isArhivaTestExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_isArhivaTestExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(9, (index) {
                    int gradeNumber = index + 4;
                    String className = "Clasa a ${gradeNumber}-a";
                    bool isClassSelected =
                        isArhivadTeste && _selectedClassTab == className;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeCatalogMenu = "Arhivă Teste";
                          _selectedClassTab = className;
                        });
                        if (isMobile) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isClassSelected
                              ? accentLila.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          className,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isClassSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isClassSelected
                                ? primaryIndigo
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: isMobile
          ? AppBar(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              title: Text(
                isArhivadTeste
                    ? "Arhivă Teste (${_selectedClassTab ?? 'Clasa a 4-a'})"
                    : _activeCatalogMenu,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: SingleChildScrollView(child: sidebarContent),
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Container(
              width: 240,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: SingleChildScrollView(child: sidebarContent),
            ),
            const VerticalDivider(width: 1, color: Colors.black12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner sus (afișat complet și pe mobil cu butoane adaptate)
                  Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryIndigo, Color(0xff312e81)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArhivadTeste
                              ? "Arhivă Teste (${_selectedClassTab ?? 'Clasa a 4-a'})"
                              : _activeCatalogMenu,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMediiPeGrupa
                              ? "Situația mediilor centralizate"
                              : isRapoarte
                              ? "Statistici și rapoarte de performanță"
                              : isArhivadTeste
                              ? "Gestionarea folderelor"
                              : "Managementul notelor și absențelor",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        if (!isMediiPeGrupa &&
                            !isRapoarte &&
                            !isArhivadTeste) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => const AddGradeDialog(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentLila,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  "Notă",
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showAddAbsenceDialog(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.event_busy,
                                  size: 14,
                                  color: Colors.amberAccent,
                                ),
                                label: const Text(
                                  "Absență",
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- FILTRE RESPONSIVE ---
                  if (!isMediiPeGrupa && !isRapoarte && !isArhivadTeste)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('grades')
                          .snapshots(),
                      builder: (context, snapshot) {
                        Set<String> classes = {"Toate"};
                        Set<String> groups = {"Toate"};
                        Set<String> courses = {
                          "Toate",
                          "Matematică",
                          "Informatică",
                          "Fizică",
                        };
                        Set<String> gradesSet = {"Toate"};
                        Set<String> studentsSet = {"Toți elevii"};

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            if (data['className'] != null) {
                              classes.add(data['className']);
                            }
                            if (data['groupName'] != null) {
                              groups.add(data['groupName']);
                            }
                            if (data['grade'] != null) {
                              gradesSet.add(data['grade']);
                            }
                            if (data['studentName'] != null) {
                              studentsSet.add(data['studentName']);
                            }
                          }
                        }

                        Set<String> typeOptions = {
                          "Toate",
                          "Doar Note",
                          "Doar Absențe",
                        };

                        double filterWidth = isMobile
                            ? (MediaQuery.of(context).size.width - 36) / 2
                            : 160;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Clasa",
                                  _selectedFilterClass,
                                  classes,
                                  (val) => setState(
                                    () => _selectedFilterClass = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Grupa",
                                  _selectedFilterGroup,
                                  groups,
                                  (val) => setState(
                                    () => _selectedFilterGroup = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Elev",
                                  _selectedSingleStudent ?? "Toți elevii",
                                  studentsSet,
                                  (val) => setState(
                                    () => _selectedSingleStudent =
                                        val == "Toți elevii" ? null : val,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Materia",
                                  _selectedFilterCourse,
                                  courses,
                                  (val) => setState(
                                    () => _selectedFilterCourse = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Nota",
                                  _selectedFilterGrade,
                                  gradesSet,
                                  (val) => setState(
                                    () => _selectedFilterGrade = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: filterWidth,
                                child: _buildFineDropdown(
                                  "Afișare",
                                  _selectedFilterType,
                                  typeOptions,
                                  (val) => setState(
                                    () => _selectedFilterType = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (!isMediiPeGrupa && !isRapoarte && !isArhivadTeste)
                    const SizedBox(height: 16),

                  isMediiPeGrupa
                      ? _buildMediiPeGrupaView(primaryIndigo, accentLila)
                      : isRapoarte
                      ? _buildRapoarteAcademiceView(primaryIndigo, accentLila)
                      : isArhivadTeste
                      ? _buildArhivaTesteView(primaryIndigo, accentLila)
                      : _buildNoteSiAbsenteView(
                          accentLila,
                          primaryIndigo,
                          isMobile,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG ADAUGARE ABSENȚĂ ---
  void _showAddAbsenceDialog(BuildContext context) {
    String? selectedStudentId;
    String? selectedStudentName;
    String? selectedStudentEmail;
    String groupName = "9A";
    String courseTitle = "Absență Generală";
    String date =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Adaugă Absență"),
              content: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var students = snapshot.data!.docs;
                  if (students.isEmpty) {
                    return const Text("Nu există elevi înregistrați.");
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedStudentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Selectează Elevul",
                        ),
                        items: students.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String name =
                              data['fullName'] ??
                              data['name'] ??
                              'Elev fără nume';
                          String email = data['email'] ?? '';
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            onTap: () {
                              selectedStudentName = name;
                              selectedStudentEmail = email;
                            },
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedStudentId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Grupa (ex: 9A, 9B)",
                        ),
                        controller: TextEditingController(text: groupName),
                        onChanged: (val) => groupName = val,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Materie (opțional)",
                        ),
                        controller: TextEditingController(text: courseTitle),
                        onChanged: (val) => courseTitle = val,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Data (ex: 05.10.2026)",
                        ),
                        controller: TextEditingController(text: date),
                        onChanged: (val) => date = val,
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Anulează"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7c4dff),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (selectedStudentId == null ||
                              selectedStudentName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Te rog selectează elevul!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection('absences')
                                .add({
                                  'studentId': selectedStudentId,
                                  'studentName': selectedStudentName,
                                  'studentEmail': selectedStudentEmail ?? '',
                                  'groupName': groupName,
                                  'courseTitle': courseTitle,
                                  'date': date,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Absența a fost salvată!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("Eroare la salvarea absenței: $e");
                          } finally {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Salvează Absența",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- VIZUALIZARE NOTE ȘI ABSENȚE (ADAPTATĂ PENTRU MOBIL) ---
  Widget _buildNoteSiAbsenteView(
    Color accentLila,
    Color primaryIndigo,
    bool isMobile,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, gradesSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('absences').snapshots(),
          builder: (context, absencesSnapshot) {
            if (gradesSnapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              );
            }

            Set<String> allStudents = {};
            Map<String, List<Map<String, dynamic>>> studentGrades = {};
            Map<String, List<Map<String, dynamic>>> studentAbsences = {};
            Map<String, String> studentClasses = {};

            if (gradesSnapshot.hasData &&
                _selectedFilterType != "Doar Absențe") {
              for (var doc in gradesSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String name = data['studentName'] ?? 'Elev';

                if (_selectedFilterClass != "Toate" &&
                    data['className'] != _selectedFilterClass) {
                  continue;
                }
                if (_selectedFilterGroup != "Toate" &&
                    data['groupName'] != _selectedFilterGroup) {
                  continue;
                }
                if (_selectedSingleStudent != null &&
                    name != _selectedSingleStudent) {
                  continue;
                }
                if (_selectedFilterCourse != "Toate" &&
                    data['courseTitle'] != _selectedFilterCourse) {
                  continue;
                }
                if (_selectedFilterGrade != "Toate" &&
                    data['grade'] != _selectedFilterGrade) {
                  continue;
                }

                allStudents.add(name);
                studentClasses[name] =
                    "${data['className'] ?? ''} (${data['groupName'] ?? 'Grupă'})";

                if (!studentGrades.containsKey(name)) studentGrades[name] = [];
                studentGrades[name]!.add({
                  'id': doc.id,
                  'grade': data['grade'] ?? '',
                  'course': data['courseTitle'] ?? 'Materie',
                  'date': data['date'] ?? 'Azi',
                });
              }
            }

            if (absencesSnapshot.hasData &&
                _selectedFilterType != "Doar Note") {
              for (var doc in absencesSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String name = data['studentName'] ?? 'Elev';

                if (_selectedFilterGroup != "Toate" &&
                    data['groupName'] != _selectedFilterGroup) {
                  continue;
                }
                if (_selectedSingleStudent != null &&
                    name != _selectedSingleStudent) {
                  continue;
                }

                allStudents.add(name);

                if (!studentAbsences.containsKey(name)) {
                  studentAbsences[name] = [];
                }
                studentAbsences[name]!.add({
                  'id': doc.id,
                  'course': data['courseTitle'] ?? 'Absență',
                  'date': data['date'] ?? 'Azi',
                });
              }
            }

            if (allStudents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "Nicio înregistrare găsită pentru filtrele selectate.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              );
            }

            List<String> studentList = allStudents.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studentList.length,
              itemBuilder: (context, index) {
                String studentName = studentList[index];
                List<Map<String, dynamic>> grades =
                    studentGrades[studentName] ?? [];
                List<Map<String, dynamic>> absences =
                    studentAbsences[studentName] ?? [];
                String classInfo = studentClasses[studentName] ?? '';

                double sum = 0;
                int count = 0;
                for (var item in grades) {
                  double? val = double.tryParse(item['grade']);
                  if (val != null) {
                    sum += val;
                    count++;
                  }
                }

                String? average = count > 0
                    ? (sum / count).toStringAsFixed(1)
                    : null;

                // Layout diferit pe mobil vs desktop
                if (isMobile) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: accentLila.withOpacity(0.12),
                                  child: Text(
                                    studentName.isNotEmpty
                                        ? studentName[0].toUpperCase()
                                        : "E",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: accentLila,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    Text(
                                      classInfo,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (average != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentLila.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Medie: $average",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: accentLila,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 16),
                        if (grades.isNotEmpty) ...[
                          const Text(
                            "Note:",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: grades.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentLila.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: accentLila.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${item['course']}: ",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      item['grade'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('grades')
                                            .doc(item['id'])
                                            .delete();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (absences.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Absențe:",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: absences.map((abs) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      abs['course'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('absences')
                                            .doc(abs['id'])
                                            .delete();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Layout original pentru desktop/tabletă
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: accentLila.withOpacity(0.12),
                              child: Text(
                                studentName[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentLila,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: primaryIndigo,
                                    ),
                                  ),
                                  Text(
                                    classInfo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: grades
                              .map(
                                (item) => Chip(
                                  label: Text(
                                    "${item['course']}: ${item['grade']}",
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (average != null) Text("Medie: $average"),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildArhivaTesteView(Color primaryIndigo, Color accentLila) {
    String currentClass = _selectedClassTab ?? "Clasa a 4-a";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Foldere și Teste - $currentClass",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryIndigo,
          ),
        ),
      ],
    );
  }

  Widget _buildRapoarteAcademiceView(Color primaryIndigo, Color accentLila) {
    return const SizedBox();
  }

  Widget _buildMediiPeGrupaView(Color primaryIndigo, Color accentLila) {
    return const SizedBox();
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    Color accentLila,
    Color primaryIndigo, {
    VoidCallback? onTap,
  }) {
    bool isSelected = _activeCatalogMenu == title;
    return InkWell(
      onTap: onTap ?? () => setState(() => _activeCatalogMenu = title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentLila.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? accentLila : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryIndigo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFineDropdown(
    String label,
    String currentValue,
    Set<String> items,
    ValueChanged<String?> onChanged,
    Color accentLila,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: accentLila),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                "$label: $item",
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff1e1b4b),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
