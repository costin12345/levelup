import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CatalogScreen extends StatefulWidget {
  final String role; // 'student' sau 'parent'

  const CatalogScreen({super.key, required this.role});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _childEmail;
  bool _isLoadingChild = true;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'parent') {
      _fetchChildEmail();
    }
  }

  // Preluăm email-ul copilului asociat părintelui dincolecția 'users'
  Future<void> _fetchChildEmail() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>?;
          if (mounted) {
            setState(() {
              _childEmail = data?['childEmail'];
              _isLoadingChild = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Eroare la preluarea email-ului copilului: $e");
        if (mounted) setState(() => _isLoadingChild = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingChild = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xfff8fafc),
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ANTET MODERN ---
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentLila.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.amberAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'parent'
                              ? "Catalogul Copilului Meu"
                              : "Catalogul Virtual • Progres Academic",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Vizualizează notele centralizate în timp real",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dacă este părinte și încă se încarcă email-ul copilului
            if (widget.role == 'parent' && _isLoadingChild)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              )
            else if (widget.role == 'parent' &&
                (_childEmail == null || _childEmail!.isEmpty))
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    "Nu este asociat niciun elev acestui cont de părinte (verificați câmpul 'childEmail' în baza de date).",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              // --- STREAM PENTRU NOTE ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, gradesSnapshot) {
                  if (gradesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: accentLila),
                      ),
                    );
                  }

                  if (!gradesSnapshot.hasData ||
                      gradesSnapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Nu există note înregistrate momentan.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  var allDocs = gradesSnapshot.data!.docs;

                  // Filtrare după rol (student sau părinte)
                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (widget.role == 'parent') {
                      return data['studentEmail'] == _childEmail;
                    } else {
                      return data['studentId'] == currentUser.uid ||
                          data['studentEmail'] == currentUser.email;
                    }
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Nu s-au găsit note pentru elevul selectat.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  // Grupare dinamică pe elev
                  Map<String, List<Map<String, dynamic>>> studentMap = {};
                  for (var doc in filteredDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String studentName =
                        data['studentName'] ?? 'Elev necunoscut';
                    String grade = data['grade']?.toString() ?? '-';
                    String course = data['courseTitle'] ?? 'Materie';
                    String className = data['className'] ?? '';

                    if (!studentMap.containsKey(studentName)) {
                      studentMap[studentName] = [];
                    }
                    studentMap[studentName]!.add({
                      'id': doc.id,
                      'grade': grade,
                      'course': course,
                      'className': className,
                    });
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentMap.keys.length,
                    itemBuilder: (context, index) {
                      String studentName = studentMap.keys.elementAt(index);
                      List<Map<String, dynamic>> studentGrades =
                          studentMap[studentName]!;
                      String className = studentGrades.isNotEmpty
                          ? studentGrades[0]['className']
                          : '';

                      // Calcul medie
                      double sum = 0;
                      int count = 0;
                      for (var item in studentGrades) {
                        double? val = double.tryParse(item['grade']);
                        if (val != null) {
                          sum += val;
                          count++;
                        }
                      }
                      String average = count > 0
                          ? (sum / count).toStringAsFixed(1)
                          : "-";

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
                            // 1. Avatar și Nume Elev
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: accentLila.withOpacity(
                                      0.12,
                                    ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          className.isNotEmpty
                                              ? "Clasa: $className"
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

                            // 2. Notele înșiruite
                            Expanded(
                              flex: 6,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: studentGrades.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentLila.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentLila.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      item['grade'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 3. Media
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
              ),
          ],
        ),
      ),
    );
  }
}
