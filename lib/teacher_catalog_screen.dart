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
  bool _isFiltersExpanded = false;
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

    // Widget-ul pentru conținutul meniului lateral (refolosit în Drawer sau Row)
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
      // Pe telefon afișăm un AppBar cu buton de meniu (Drawer)
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
          // Pe desktop / tabletă lăsăm meniul fix lateral
          if (!isMobile) ...[
            Container(
              width: 240,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: SingleChildScrollView(child: sidebarContent),
            ),
            const VerticalDivider(width: 1, color: Colors.black12),
          ],

          // --- CONȚINUTUL PRINCIPAL ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) ...[
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArhivadTeste
                                    ? "Arhivă Teste (${_selectedClassTab ?? 'Clasa a 4-a'})"
                                    : _activeCatalogMenu,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMediiPeGrupa
                                    ? "Situația mediilor centralizate pe fiecare clasă și grupă"
                                    : isRapoarte
                                    ? "Statistici vizuale și rapoarte de performanță"
                                    : isArhivadTeste
                                    ? "Gestionarea folderelor și testelor încărcate"
                                    : "Managementul avansat al notelor și absențelor",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          if (!isMediiPeGrupa && !isRapoarte && !isArhivadTeste)
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) =>
                                    const AddGradeDialog(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentLila,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    "Adaugă Notă",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showAddAbsenceDialog(context),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.event_busy,
                                    size: 16,
                                    color: Colors.amberAccent,
                                  ),
                                  label: const Text(
                                    "Adaugă Absență",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- FILTRE ---
                  if (!isMediiPeGrupa && !isRapoarte && !isArhivadTeste)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
                      builder: (context, snapshot) {
                        Set<String> classes = {"Toate"};
                        Set<String> groups = {"Toate"};
                        Set<String> courses = {"Toate", "Matematică", "Informatică", "Fizică"};
                        Set<String> gradesSet = {"Toate"};
                        Set<String> studentsSet = {"Toți elevii"};

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            if (data['className'] != null) classes.add(data['className']);
                            if (data['groupName'] != null) groups.add(data['groupName']);
                            if (data['grade'] != null) gradesSet.add(data['grade']);
                            if (data['studentName'] != null) studentsSet.add(data['studentName']);
                          }
                        }

                        Set<String> typeOptions = {"Toate", "Doar Note", "Doar Absențe"};

                        // Construim conținutul efectiv al filtrelor
                        Widget filtersWidget = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Clasa", _selectedFilterClass, classes, (val) => setState(() => _selectedFilterClass = val!), accentLila),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Grupa", _selectedFilterGroup, groups, (val) => setState(() => _selectedFilterGroup = val!), accentLila),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Elev", _selectedSingleStudent ?? "Toți elevii", studentsSet, (val) => setState(() => _selectedSingleStudent = val == "Toți elevii" ? null : val), accentLila),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Materia", _selectedFilterCourse, courses, (val) => setState(() => _selectedFilterCourse = val!), accentLila),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Nota", _selectedFilterGrade, gradesSet, (val) => setState(() => _selectedFilterGrade = val!), accentLila),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 160,
                              child: _buildFineDropdown("Afișare", _selectedFilterType, typeOptions, (val) => setState(() => _selectedFilterType = val!), accentLila),
                            ),
                          ],
                        );

                        // Pe mobil afișăm un buton de tip „Filtre” care deschide/închide opțiunile
                        if (isMobile) {
                          bool hasActiveFilters = _selectedFilterClass != "Toate" ||
                              _selectedFilterGroup != "Toate" ||
                              _selectedFilterCourse != "Toate" ||
                              _selectedFilterGrade != "Toate" ||
                              _selectedFilterType != "Toate" ||
                              _selectedSingleStudent != null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: _isFiltersExpanded,
                              onExpansionChanged: (val) => setState(() => _isFiltersExpanded = val),
                              leading: Icon(Icons.filter_list, color: accentLila),
                              title: Row(
                                children: [
                                  const Text(
                                    "Filtrare date",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff1e1b4b)),
                                  ),
                                  if (hasActiveFilters) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentLila.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Activ",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentLila),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: filtersWidget,
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 160,
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
                                width: 160,
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
                                width: 160,
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
                                width: 160,
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
                                width: 160,
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
                                width: 160,
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

                  // --- CONȚINUT DINAMIC ---
                  isMediiPeGrupa
                      ? _buildMediiPeGrupaView(primaryIndigo, accentLila)
                      : isRapoarte
                      ? _buildRapoarteAcademiceView(primaryIndigo, accentLila)
                      : isArhivadTeste
                      ? _buildArhivaTesteView(primaryIndigo, accentLila)
                      : _buildNoteSiAbsenteView(accentLila, primaryIndigo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG ADAUGARE ABSENȚĂ (CU NOTIFICĂRI FCM COMPLETE) ---
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
                      // 1. Salvăm absența în colecția 'absences'
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

                      String pushTitle =
                          '⚠️ Absență Înregistrată la $courseTitle';
                      String pushBody =
                          'Ai primit o absență la $groupName. Data: $date';

                      // 2. Colectăm ID-urile destinatarilor (Elevul + Părinții asociați)
                      Set<String> recipientIds = {selectedStudentId!};

                      if (selectedStudentEmail != null &&
                          selectedStudentEmail!.isNotEmpty) {
                        var parentQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'parent')
                            .where(
                          'childEmail',
                          isEqualTo: selectedStudentEmail,
                        )
                            .get();

                        for (var parentDoc in parentQuery.docs) {
                          recipientIds.add(parentDoc.id);
                        }
                      }

                      List<String> uniqueRecipients = recipientIds
                          .toList();

                      // 3. Salvăm în Firestore pentru TOȚI destinatarii (istoric + clopoțel + badge)
                      for (String userId in uniqueRecipients) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .add({
                          'userId': userId,
                          'title': pushTitle,
                          'body': pushBody,
                          'type': 'absence',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      // 4. Trimitem mesajul fizic (push notification) către primul destinatar
                      if (uniqueRecipients.isNotEmpty) {
                        String targetUserId = uniqueRecipients.first;

                        final serviceAccountCredentials =
                        auth.ServiceAccountCredentials.fromJson({
                          "type": "service_account",
                          "project_id": "level-up-19583",
                          "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
                          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\SwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
                          "client_email": "firebase-adminsdk-fbsvc@level-up-19583.iam.gserviceaccount.com",
                          "client_id": "112777526185284576732",
                          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                          "token_uri":
                          "https://oauth2.googleapis.com/token",
                          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40level-up-19583.iam.gserviceaccount.com",
                          "universe_domain": "googleapis.com",
                        });

                        final scopes = [
                          'https://www.googleapis.com/auth/firebase.messaging',
                        ];
                        final client = await auth.clientViaServiceAccount(
                          serviceAccountCredentials,
                          scopes,
                        );

                        final String fcmV1Url =
                            'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

                        final unreadSnap = await FirebaseFirestore
                            .instance
                            .collection('notifications')
                            .where('userId', isEqualTo: targetUserId)
                            .where('isRead', isEqualTo: false)
                            .get();
                        int unreadCount = unreadSnap.docs.length;

                        DocumentSnapshot userDoc = await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(targetUserId)
                            .get();

                        if (userDoc.exists) {
                          var uData =
                          userDoc.data() as Map<String, dynamic>?;
                          String? fcmToken = uData?['fcmToken'];

                          if (fcmToken != null && fcmToken.isNotEmpty) {
                            await client.post(
                              Uri.parse(fcmV1Url),
                              headers: {
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'message': {
                                  'token': fcmToken,
                                  'notification': {
                                    'title': pushTitle,
                                    'body': pushBody,
                                  },
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
                                      'aps': {
                                        'sound': 'default',
                                        'badge': unreadCount,
                                      },
                                    },
                                  },
                                  'data': {
                                    'notificationType': 'absence',
                                    'click_action':
                                    'FLUTTER_NOTIFICATION_CLICK',
                                  },
                                },
                              }),
                            );
                          }
                        }
                        client.close();
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Absența a fost salvată și notificarea trimisă!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint(
                        "Eroare la trimiterea notificării FCM pentru absențe: $e",
                      );
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

  // --- VIZUALIZARE NOTE ȘI ABSENȚE ---
  Widget _buildNoteSiAbsenteView(Color accentLila, Color primaryIndigo) {
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: accentLila.withOpacity(0.12),
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : "E",
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
                                  const SizedBox(height: 2),
                                  Text(
                                    classInfo.isNotEmpty
                                        ? classInfo
                                        : "Fără detalii",
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (grades.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: grades.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentLila.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentLila.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['course'],
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  item['grade'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: primaryIndigo,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "(${item['date']})",
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                            if (absences.isNotEmpty) ...[
                              if (grades.isNotEmpty) const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: absences.map((abs) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff1f5f9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              abs['course'],
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.event_busy,
                                                  size: 11,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  "Absență",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: Color(0xff475569),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "(${abs['date']})",
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                      ),
                      const SizedBox(width: 10),
                      if (average != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentLila.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Medie",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: accentLila,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                average,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: accentLila,
                                  fontSize: 15,
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
        );
      },
    );
  }

  Widget _buildArhivaTesteView(Color primaryIndigo, Color accentLila) {
    String currentClass = _selectedClassTab ?? "Clasa a 4-a";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Foldere și Teste - $currentClass",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryIndigo,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddFolderDialog(context, currentClass),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentLila,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.create_new_folder, size: 16),
              label: const Text("Adaugă Folder"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('test_folders')
              .where('className', isEqualTo: currentClass)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  "Niciun folder creat pentru această clasă. Apasă pe „Adaugă Folder”.",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            var folders = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                var folderDoc = folders[index];
                var folderData = folderDoc.data() as Map<String, dynamic>;
                String folderName = folderData['folderName'] ?? 'Folder';
                String folderId = folderDoc.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.folder,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                folderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: primaryIndigo,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showUploadTestDialog(context, folderId),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentLila),
                            ),
                            icon: Icon(
                              Icons.upload_file,
                              size: 16,
                              color: accentLila,
                            ),
                            label: Text(
                              "Încarcă Test",
                              style: TextStyle(color: accentLila, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('test_folders')
                            .doc(folderId)
                            .collection('tests')
                            .snapshots(),
                        builder: (context, testSnapshot) {
                          if (!testSnapshot.hasData ||
                              testSnapshot.data!.docs.isEmpty) {
                            return const Text(
                              "Nu există teste încărcate în acest folder.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }

                          var tests = testSnapshot.data!.docs;

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tests.map((testDoc) {
                              var testData =
                              testDoc.data() as Map<String, dynamic>;
                              String testTitle = testData['title'] ?? 'Test';
                              String testDate = testData['date'] ?? '';

                              return Chip(
                                avatar: const Icon(
                                  Icons.insert_drive_file,
                                  size: 14,
                                  color: Colors.deepPurple,
                                ),
                                label: Text(
                                  "$testTitle ($testDate)",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () async {
                                  await testDoc.reference.delete();
                                },
                                backgroundColor: Colors.grey.shade100,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddFolderDialog(BuildContext context, String className) {
    String folderName = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adaugă Folder Nou pentru $className"),
          content: TextField(
            decoration: const InputDecoration(
              labelText: "Nume Folder (ex: Teste Semestrul 1)",
            ),
            onChanged: (val) => folderName = val,
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
              onPressed: () async {
                if (folderName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('test_folders')
                      .add({
                    'className': className,
                    'folderName': folderName,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Creează",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadTestDialog(BuildContext context, String folderId) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    String date =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Încarcă Teste în Folder"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Poți adăuga linkuri multiple (ex: Bunny.net, PDF, Google Drive) pentru testele din acest folder.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Titlu Test (ex: Test Unitar 1 - Matematică)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Link Bunny.net / Fișier (URL)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Data",
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: date),
                  onChanged: (val) => date = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Închide"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7c4dff),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text(
                "Adaugă și altul",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    linkController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('test_folders')
                      .doc(folderId)
                      .collection('tests')
                      .add({
                    'title': titleController.text,
                    'details': linkController.text,
                    'date': date,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  titleController.clear();
                  linkController.clear();
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1e1b4b),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    linkController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('test_folders')
                      .doc(folderId)
                      .collection('tests')
                      .add({
                    'title': titleController.text,
                    'details': linkController.text,
                    'date': date,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Salvează și Gata",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRapoarteAcademiceView(Color primaryIndigo, Color accentLila) {
    final List<String> schoolMonths = [
      "Sept",
      "Oct",
      "Noi",
      "Dec",
      "Ian",
      "Feb",
      "Mar",
      "Apr",
      "Mai",
      "Iun",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Text(
                "Nivel analiză an școlar: ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1e1b4b),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text("Pe Grupe"),
                selected: _reportScope == "Pe Grupe",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Grupe"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Grupe"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Pe Elevi"),
                selected: _reportScope == "Pe Elevi",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Elevi"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Elevi"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Pe Clase"),
                selected: _reportScope == "Pe Clase",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Clase"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Clase"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('grades').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    "Nu există date pentru generarea graficului anual.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            Map<String, Map<String, List<double>>> entityMonthlyGrades = {};

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              double? gradeVal = double.tryParse(
                data['grade']?.toString() ?? '',
              );
              if (gradeVal == null) continue;

              String dateStr = data['date'] ?? '';
              String monthShort = "Oct";
              if (dateStr.contains('.')) {
                List<String> parts = dateStr.split('.');
                if (parts.length >= 2) {
                  int monthNum = int.tryParse(parts[1]) ?? 10;
                  switch (monthNum) {
                    case 9:
                      monthShort = "Sept";
                      break;
                    case 10:
                      monthShort = "Oct";
                      break;
                    case 11:
                      monthShort = "Noi";
                      break;
                    case 12:
                      monthShort = "Dec";
                      break;
                    case 1:
                      monthShort = "Ian";
                      break;
                    case 2:
                      monthShort = "Feb";
                      break;
                    case 3:
                      monthShort = "Mar";
                      break;
                    case 4:
                      monthShort = "Apr";
                      break;
                    case 5:
                      monthShort = "Mai";
                      break;
                    case 6:
                      monthShort = "Iun";
                      break;
                    default:
                      monthShort = "Oct";
                  }
                }
              }

              String entityKey = "";
              if (_reportScope == "Pe Grupe") {
                entityKey =
                "${data['className'] ?? 'Clasă'} (${data['groupName'] ?? 'Grupă'})";
              } else if (_reportScope == "Pe Elevi") {
                entityKey = data['studentName'] ?? 'Elev';
              } else {
                entityKey = data['className'] ?? 'Clasa generală';
              }

              if (!entityMonthlyGrades.containsKey(entityKey)) {
                entityMonthlyGrades[entityKey] = {};
              }
              if (!entityMonthlyGrades[entityKey]!.containsKey(monthShort)) {
                entityMonthlyGrades[entityKey]![monthShort] = [];
              }
              entityMonthlyGrades[entityKey]![monthShort]!.add(gradeVal);
            }

            List<String> entities = entityMonthlyGrades.keys.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                String entityName = entities[index];
                Map<String, List<double>> monthsData =
                entityMonthlyGrades[entityName]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _reportScope == "Pe Elevi"
                                ? Icons.person
                                : _reportScope == "Pe Grupe"
                                ? Icons.group
                                : Icons.class_,
                            color: accentLila,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entityName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryIndigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Evoluția mediilor pe parcursul anului școlar:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: schoolMonths.map((month) {
                          List<double>? grades = monthsData[month];
                          double avg = 0;
                          if (grades != null && grades.isNotEmpty) {
                            double sum = 0;
                            for (var g in grades) sum += g;
                            avg = sum / grades.length;
                          }

                          bool hasData = grades != null && grades.isNotEmpty;

                          return Expanded(
                            child: Column(
                              children: [
                                Text(
                                  hasData ? avg.toStringAsFixed(1) : "-",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hasData
                                        ? accentLila
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 80,
                                  width: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: hasData
                                        ? (avg / 10).clamp(0.05, 1.0)
                                        : 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: avg >= 8
                                            ? Colors.green.shade400
                                            : (avg >= 5
                                            ? accentLila
                                            : Colors.orange),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  month,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasData
                                        ? primaryIndigo
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMediiPeGrupaView(Color primaryIndigo, Color accentLila) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: accentLila)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Text(
                "Nu există note înregistrate pentru calculul mediilor pe grupe.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        Map<String, List<double>> groupGrades = {};
        Map<String, Set<String>> groupStudents = {};
        Map<String, String> groupTitleMap = {};

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;

          String className = data['className'] ?? 'Clasa generală';
          String groupName = data['groupName'] ?? 'Grupa A';
          String studentName = data['studentName'] ?? 'Elev';
          double? gradeVal = double.tryParse(data['grade']?.toString() ?? '');

          String uniqueKey = "$className — $groupName";

          if (!groupGrades.containsKey(uniqueKey)) {
            groupGrades[uniqueKey] = [];
            groupStudents[uniqueKey] = {};
            groupTitleMap[uniqueKey] = "$className ($groupName)";
          }

          groupStudents[uniqueKey]!.add(studentName);
          if (gradeVal != null) {
            groupGrades[uniqueKey]!.add(gradeVal);
          }
        }

        List<String> keys = groupGrades.keys.toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            String key = keys[index];
            List<double> grades = groupGrades[key]!;
            int studentCount = groupStudents[key]!.length;
            String displayTitle = groupTitleMap[key] ?? key;

            double sum = 0;
            for (var g in grades) {
              sum += g;
            }
            String groupAverage = grades.isNotEmpty
                ? (sum / grades.length).toStringAsFixed(2)
                : "-";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentLila.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group_outlined,
                          color: accentLila,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryIndigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$studentCount elevi în grupă • ${grades.length} note total",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accentLila.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Media Grupei",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentLila,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          groupAverage,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: accentLila,
                            fontSize: 18,
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
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: accentLila),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                "$label: $item",
                style: const TextStyle(
                  fontSize: 12,
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