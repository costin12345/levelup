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
  String?
  _selectedChildEmail; // Emailul copilului selectat curent de către părinte

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xfffff8dc),
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Antet prietenos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff42153e), Color(0xff6a2465)],
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
                              : "Catalogul Meu Academic",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Vizualizează notele și progresul în timp real",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dacă este PĂRINTE, afișăm un selector de copii (dacă are mai mulți)
            if (widget.role == 'parent')
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, parentSnap) {
                  if (!parentSnap.hasData || !parentSnap.data!.exists) {
                    return const SizedBox();
                  }

                  var parentData =
                      parentSnap.data!.data() as Map<String, dynamic>;

                  // Putem stoca copiii ca o listă 'childrenEmails' sau un singur 'childEmail'
                  List<dynamic> childrenList =
                      parentData['childrenEmails'] ?? [];
                  if (childrenList.isEmpty &&
                      parentData['childEmail'] != null) {
                    childrenList = [parentData['childEmail']];
                  }

                  if (childrenList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Nu ai setat niciun copil în profilul tău de părinte.",
                        style: TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Dacă nu e selectat niciunul, îl setăm pe primul din listă implicit
                  if (_selectedChildEmail == null ||
                      !childrenList.contains(_selectedChildEmail)) {
                    _selectedChildEmail = childrenList.first;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedChildEmail,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xff42153e),
                        ),
                        items: childrenList.map((email) {
                          return DropdownMenuItem<String>(
                            value: email.toString(),
                            child: Text(
                              "Copil selectat: $email",
                              style: const TextStyle(
                                color: Color(0xff42153e),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedChildEmail = val;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),

            // Stream pentru preluarea notelor
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, gradesSnapshot) {
                  if (gradesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    );
                  }

                  if (!gradesSnapshot.hasData ||
                      gradesSnapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_satisfied_alt,
                            size: 64,
                            color: Colors.purple.shade200,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Nu există note înregistrate momentan.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var allGrades = gradesSnapshot.data!.docs;

                  // Filtrăm notele în funcție de rol și de copilul selectat
                  var myGrades = allGrades.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (widget.role == 'parent') {
                      return data['studentEmail'] == _selectedChildEmail;
                    } else {
                      return data['studentId'] == currentUser.uid ||
                          data['studentEmail'] == currentUser.email;
                    }
                  }).toList();

                  if (myGrades.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 64,
                            color: Colors.amber.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.role == 'parent'
                                ? "Nu s-au găsit note pentru copilul: ${_selectedChildEmail ?? 'N/A'}"
                                : "Nu ai primit nicio notă încă.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: myGrades.length,
                    itemBuilder: (context, index) {
                      var data = myGrades[index].data() as Map<String, dynamic>;
                      String course = data['courseTitle'] ?? 'Materie';
                      String grade = data['grade'] ?? '';
                      String className = data['className'] ?? '';
                      String date = data['date'] ?? 'Azi';
                      String comment = data['comment'] ?? '';
                      String studentName = data['studentName'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff42153e).withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xff42153e)
                                .withOpacity(0.1),
                            child: const Icon(Icons.star, color: Colors.amber),
                          ),
                          title: Text(
                            widget.role == 'parent'
                                ? "$studentName • $course"
                                : course,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff42153e),
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (className.isNotEmpty)
                                Text(
                                  "Clasa: $className",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "Comentariu / Temă: $comment",
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Data: $date",
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff42153e),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              grade,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 18,
                              ),
                            ),
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
