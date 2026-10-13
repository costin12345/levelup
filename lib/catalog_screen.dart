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

  // Preluăm email-ul copilului asociat părintelui din colecția 'users'
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

  // Helper pentru afișarea statusului temei
  Widget _buildHomeworkBadge(String? status) {
    String text;
    Color bgColor;
    Color textColor;

    switch (status?.toLowerCase()) {
      case 'efectuata':
        text = '🟢 Temă Efectuată';
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      case 'partiala':
        text = '🟡 Temă Parțială';
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        break;
      case 'neefectuata':
      default:
        text = '🔴 Lipsă Temă';
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // Helper pentru afișarea statusului plății ședinței
  Widget _buildPaymentBadge(String? status) {
    bool isPaid = status?.toLowerCase() == 'platita';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPaid ? '💵 Plătită' : '⏳ Neplătită',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPaid ? Colors.blue.shade800 : Colors.orange.shade800,
        ),
      ),
    );
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
                          "Vizualizează notele, testele, temele și plățile în timp real",
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
              // --- STREAM PENTRU NOTE ȘI ȘEDINȚE ---
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
                          "Nu există înregistrări momentan.",
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
                          "Nu s-au găsit date pentru elevul selectat.",
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

                    if (!studentMap.containsKey(studentName)) {
                      studentMap[studentName] = [];
                    }
                    studentMap[studentName]!.add({
                      'id': doc.id,
                      'grade': data['grade']?.toString() ?? '-',
                      'sessionNumber':
                          data['sessionNumber']?.toString() ?? 'Ședință',
                      'homeworkStatus': data['homeworkStatus'] ?? 'neefectuata',
                      'paymentStatus': data['paymentStatus'] ?? 'neplatita',
                      'feedback': data['feedback'] ?? 'Fără observații',
                      'className': data['className'] ?? '',
                      'date': data['createdAt'],
                    });
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentMap.keys.length,
                    itemBuilder: (context, index) {
                      String studentName = studentMap.keys.elementAt(index);
                      List<Map<String, dynamic>> sessions =
                          studentMap[studentName]!;
                      String className = sessions.isNotEmpty
                          ? sessions[0]['className']
                          : '';

                      // Calcul medie note teste
                      double sum = 0;
                      int count = 0;
                      for (var item in sessions) {
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
                            // Header elev + Medie generală
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
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
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                        Text(
                                          className.isNotEmpty
                                              ? "Clasa: $className"
                                              : "Fără detalii clasă",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: accentLila,
                                        ),
                                      ),
                                      Text(
                                        average,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: accentLila,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            const Text(
                              "Istoric Ședințe, Teste & Plăți",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Listă detaliată per ședință
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sessions.length,
                              separatorBuilder: (context, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, sessionIndex) {
                                var session = sessions[sessionIndex];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Număr ședință
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          session['sessionNumber'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                      ),
                                      // Notă test
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            const Text(
                                              "Test: ",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: accentLila.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                session['grade'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: primaryIndigo,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status temă
                                      Expanded(
                                        flex: 3,
                                        child: Center(
                                          child: _buildHomeworkBadge(
                                            session['homeworkStatus'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Status plată ședință
                                      Expanded(
                                        flex: 3,
                                        child: Center(
                                          child: _buildPaymentBadge(
                                            session['paymentStatus'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
        ),
      ),
    );
  }
}
