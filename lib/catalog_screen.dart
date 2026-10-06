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
  String? _selectedChildEmail;

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xfffff8dc),
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    const Color primaryDark = Color(0xff42153e);

    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ANTET ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryDark, Color(0xff6a2465)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'parent'
                              ? "Catalogul Copiilor Mei"
                              : "Catalogul Virtual • Progres Academic",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Vizualizează notele centralizate pe rânduri, exact ca într-un catalog modern",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- STREAM PENTRU NOTE ȘI GRUPARE PE ELEVI (STIL KINDERPEDIA) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grades')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, gradesSnapshot) {
                if (gradesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryDark),
                    ),
                  );
                }

                if (!gradesSnapshot.hasData ||
                    gradesSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "Nu există note înregistrate momentan.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                var allDocs = gradesSnapshot.data!.docs;

                // Filtrare după rol
                var filteredDocs = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (widget.role == 'parent') {
                    return data['studentEmail'] == _selectedChildEmail;
                  } else {
                    return data['studentId'] == currentUser.uid ||
                        data['studentEmail'] == currentUser.email;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "Nu s-au găsit note.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                // Grupare dinamică pe elev (cum ar fi Nume Elev -> Listă de note)
                Map<String, List<Map<String, dynamic>>> studentMap = {};
                for (var doc in filteredDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String studentName = data['studentName'] ?? 'Elev necunoscut';
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

                    // Calcul medie simplă pe elev
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
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryDark.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 1. Avatar și Nume Elev
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: primaryDark.withOpacity(0.1),
                                  child: Text(
                                    studentName.isNotEmpty
                                        ? studentName[0].toUpperCase()
                                        : "E",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryDark,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: primaryDark,
                                        ),
                                      ),
                                      if (className.isNotEmpty)
                                        Text(
                                          "Clasa: $className",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Notele înșiruite orizontal (Stil Kinderpedia)
                          Expanded(
                            flex: 5,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: studentGrades.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    item['grade'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: primaryDark,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // 3. Media încheiată
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Medie",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  average,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber,
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
