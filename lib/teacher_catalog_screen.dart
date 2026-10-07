/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_grade_dialog.dart';

class TeacherCatalogScreen extends StatefulWidget {
  const TeacherCatalogScreen({super.key});

  @override
  State<TeacherCatalogScreen> createState() => _TeacherCatalogScreenState();
}

class _TeacherCatalogScreenState extends State<TeacherCatalogScreen> {
  String _activeCatalogMenu = "Note și Absențe";

  String _selectedFilterClass = "Toate";
  String _selectedFilterGroup = "Toate";
  String _selectedFilterCourse = "Toate";
  String _selectedFilterType = "Toate";
  String _selectedFilterMonth = "Toate";
  String _reportScope = "Pe Grupe";
  String _selectedFilterStudent = "Toate";

  final List<String> _monthsList = [
    "Toate",
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

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    bool isMediiPeGrupa = _activeCatalogMenu == "Medii pe Grupă";
    bool isRapoarte = _activeCatalogMenu == "Rapoarte Academice";
    bool isMobile = MediaQuery.of(context).size.width < 750;

    // Conținutul meniului lateral (folosit în Drawer pe telefon sau Row pe desktop)
    Widget catalogSidebarContent = Container(
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
            isMobile,
          ),
          _buildSidebarItem(
            "Medii pe Grupă",
            Icons.bar_chart,
            accentLila,
            primaryIndigo,
            isMobile,
          ),
          _buildSidebarItem(
            "Rapoarte Academice",
            Icons.description_outlined,
            accentLila,
            primaryIndigo,
            isMobile,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      drawer: isMobile ? Drawer(child: catalogSidebarContent) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            catalogSidebarContent,
            const VerticalDivider(width: 1, color: Colors.black12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryIndigo, Color(0xff312e81)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (isMobile)
                                Builder(
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Scaffold.of(context).openDrawer(),
                                      tooltip: "Meniu Catalog",
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _activeCatalogMenu,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Managementul notelor, mediilor și rapoartelor",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMediiPeGrupa && !isRapoarte && !isMobile)
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const AddGradeDialog(isAbsence: false),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentLila,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Notă"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const AddGradeDialog(isAbsence: true),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.person_remove, size: 16),
                                label: const Text("Absență"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Pe telefon, butoanele de adăugare le punem sub antet pentru spațiu optim
                  if (!isMediiPeGrupa && !isRapoarte && isMobile) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) =>
                                  const AddGradeDialog(isAbsence: false),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentLila,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Adaugă Notă"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) =>
                                  const AddGradeDialog(isAbsence: true),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.person_remove, size: 16),
                            label: const Text("Adaugă Absență"),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('grades')
                          .snapshots(),
                      builder: (context, studentSnapshot) {
                        List<String> studentList = ["Toate"];
                        if (studentSnapshot.hasData) {
                          Set<String> uniqueStudents = {};
                          for (var doc in studentSnapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            String sName = data['studentName'] ?? '';
                            if (sName.isNotEmpty) {
                              if (_selectedFilterClass != "Toate" &&
                                  data['className'] != _selectedFilterClass)
                                continue;
                              if (_selectedFilterGroup != "Toate" &&
                                  data['groupName'] != _selectedFilterGroup)
                                continue;
                              uniqueStudents.add(sName);
                            }
                          }
                          studentList.addAll(uniqueStudents);
                        }
                        if (!studentList.contains(_selectedFilterStudent)) {
                          _selectedFilterStudent = "Toate";
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildDropdownFilter(
                              "Clasă",
                              [
                                "Toate",
                                "9A",
                                "9B",
                                "10A",
                                "11A",
                                "Clasa a IX-a",
                              ],
                              _selectedFilterClass,
                              (val) =>
                                  setState(() => _selectedFilterClass = val!),
                            ),
                            _buildDropdownFilter(
                              "Grupă",
                              [
                                "Toate",
                                "Grupa 1",
                                "Grupa 2",
                                "Grupa A",
                                "Grupa B",
                              ],
                              _selectedFilterGroup,
                              (val) =>
                                  setState(() => _selectedFilterGroup = val!),
                            ),
                            _buildDropdownFilter(
                              "Materie",
                              ["Toate", "Matematică", "Informatică", "Fizică"],
                              _selectedFilterCourse,
                              (val) =>
                                  setState(() => _selectedFilterCourse = val!),
                            ),
                            _buildDropdownFilter(
                              "Lună",
                              _monthsList,
                              _selectedFilterMonth,
                              (val) =>
                                  setState(() => _selectedFilterMonth = val!),
                            ),
                            if (!isMediiPeGrupa && !isRapoarte) ...[
                              _buildDropdownFilter(
                                "Tip",
                                ["Toate", "Notă", "Absență"],
                                _selectedFilterType,
                                (val) =>
                                    setState(() => _selectedFilterType = val!),
                              ),
                            ],
                            if (isRapoarte) ...[
                              _buildDropdownFilter(
                                "Nivel Raport",
                                ["Pe Grupe", "Individual Elev"],
                                _reportScope,
                                (val) => setState(() => _reportScope = val!),
                              ),
                              if (_reportScope == "Individual Elev")
                                _buildDropdownFilter(
                                  "Elev",
                                  studentList,
                                  _selectedFilterStudent,
                                  (val) => setState(
                                    () => _selectedFilterStudent = val!,
                                  ),
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  isMediiPeGrupa
                      ? _buildMediiPeGrupaView(primaryIndigo, accentLila)
                      : isRapoarte
                      ? _buildRapoarteAcademiceView(primaryIndigo, accentLila)
                      : _buildNoteSiAbsenteView(accentLila, primaryIndigo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: items.contains(currentVal) ? currentVal : "Toate",
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    Color accentLila,
    Color primaryIndigo,
    bool isMobile,
  ) {
    bool isSelected = _activeCatalogMenu == title;
    return InkWell(
      onTap: () {
        setState(() => _activeCatalogMenu = title);
        if (isMobile) Navigator.pop(context);
      },
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

  String _getMonthShort(String dateStr) {
    if (!dateStr.contains('.')) return "Oct";
    List<String> parts = dateStr.split('.');
    if (parts.length < 2) return "Oct";
    int monthNum = int.tryParse(parts[1]) ?? 10;
    switch (monthNum) {
      case 9:
        return "Sept";
      case 10:
        return "Oct";
      case 11:
        return "Noi";
      case 12:
        return "Dec";
      case 1:
        return "Ian";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "Mai";
      case 6:
        return "Iun";
      default:
        return "Oct";
    }
  }

  Widget _buildNoteSiAbsenteView(Color accentLila, Color primaryIndigo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        docs = docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          if (_selectedFilterClass != "Toate" &&
              data['className'] != _selectedFilterClass)
            return false;
          if (_selectedFilterGroup != "Toate" &&
              data['groupName'] != _selectedFilterGroup)
            return false;
          if (_selectedFilterCourse != "Toate" &&
              data['courseTitle'] != _selectedFilterCourse)
            return false;
          if (_selectedFilterType == "Notă" && (data['isAbsence'] == true))
            return false;
          if (_selectedFilterType == "Absență" && (data['isAbsence'] != true))
            return false;
          if (_selectedFilterMonth != "Toate") {
            String mShort = _getMonthShort(data['date'] ?? '');
            if (mShort != _selectedFilterMonth) return false;
          }
          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Nu există note sau absențe conform filtrelor selectate.",
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool isAbsence = data['isAbsence'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['studentName'] ?? 'Elev',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Clasa: ${data['className']} • Grupa: ${data['groupName']} • Materie: ${data['courseTitle']} • Data: ${data['date'] ?? '-'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Chip(
                        backgroundColor: isAbsence
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        label: Text(
                          isAbsence ? "Absență" : "Nota: ${data['grade']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAbsence
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => docs[index].reference.delete(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediiPeGrupaView(Color primaryIndigo, Color accentLila) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        Map<String, List<double>> groupGrades = {};
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['isAbsence'] == true) continue;

          String cName = data['className'] ?? 'Clasă';
          String gName = data['groupName'] ?? 'Grupă';

          if (_selectedFilterClass != "Toate" && cName != _selectedFilterClass)
            continue;
          if (_selectedFilterGroup != "Toate" && gName != _selectedFilterGroup)
            continue;

          if (_selectedFilterMonth != "Toate") {
            String mShort = _getMonthShort(data['date'] ?? '');
            if (mShort != _selectedFilterMonth) continue;
          }

          String key = "$cName ($gName)";
          double? val = double.tryParse(data['grade']?.toString() ?? '');
          if (!groupGrades.containsKey(key)) groupGrades[key] = [];
          if (val != null) groupGrades[key]!.add(val);
        }

        List<String> keys = groupGrades.keys.toList();
        if (keys.isEmpty)
          return const Center(
            child: Text("Nu există date pentru medii cu filtrele selectate."),
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            String key = keys[index];
            List<double> grades = groupGrades[key]!;
            double sum = 0;
            for (var g in grades) sum += g;
            String avg = grades.isNotEmpty
                ? (sum / grades.length).toStringAsFixed(2)
                : "-";

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryIndigo,
                      fontSize: 15,
                    ),
                  ),
                  Chip(
                    label: Text(
                      "Medie: $avg",
                      style: TextStyle(
                        color: accentLila,
                        fontWeight: FontWeight.bold,
                      ),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        //
        Map<String, Map<String, List<double>>> entityMonthlyGrades = {};

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['isAbsence'] == true) continue;

          String cName = data['className'] ?? 'Clasă';
          String gName = data['groupName'] ?? 'Grupă';
          String studentName = data['studentName'] ?? 'Elev';

          if (_selectedFilterClass != "Toate" && cName != _selectedFilterClass)
            continue;
          if (_selectedFilterGroup != "Toate" && gName != _selectedFilterGroup)
            continue;

          if (_reportScope == "Individual Elev" &&
              _selectedFilterStudent != "Toate" &&
              studentName != _selectedFilterStudent) {
            continue;
          }

          double? gradeVal = double.tryParse(data['grade']?.toString() ?? '');
          if (gradeVal == null) continue;

          String monthShort = _getMonthShort(data['date'] ?? '');
          if (_selectedFilterMonth != "Toate" &&
              monthShort != _selectedFilterMonth)
            continue;

          String entityKey = _reportScope == "Individual Elev"
              ? studentName
              : "$cName ($gName)";

          if (!entityMonthlyGrades.containsKey(entityKey)) {
            entityMonthlyGrades[entityKey] = {};
          }
          if (!entityMonthlyGrades[entityKey]!.containsKey(monthShort)) {
            entityMonthlyGrades[entityKey]![monthShort] = [];
          }
          entityMonthlyGrades[entityKey]![monthShort]!.add(gradeVal);
        }

        List<String> entities = entityMonthlyGrades.keys.toList();
        if (entities.isEmpty)
          return const Center(
            child: Text(
              "Nu există date pentru rapoarte cu filtrele selectate.",
            ),
          );

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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _reportScope == "Individual Elev"
                            ? Icons.person
                            : Icons.group,
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
    );
  }
}
*/
