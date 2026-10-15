import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
          String role = userData['role'] ?? 'student';
          String targetEmail = currentUser?.email ?? '';

          if (role == 'parent') {
            targetEmail = userData['childEmail'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Progres & Statistici Academice",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryIndigo,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role == 'parent'
                          ? "Situația școlară pentru copilul tău ($targetEmail)"
                          : "Evoluția ta școlară și statisticile de note pe materii",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('grades')
                          .where('studentEmail', isEqualTo: targetEmail)
                          .snapshots(),
                      builder: (context, gradeSnapshot) {
                        if (gradeSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!gradeSnapshot.hasData ||
                            gradeSnapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Nu există note înregistrate momentan.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        var docs = gradeSnapshot.data!.docs;
                        double totalScore = 0;
                        int validGradesCount = 0;

                        // Mapare pentru a grupa notele pe materii (ex: "Matematică" -> [nota1, nota2...])
                        Map<String, List<Map<String, dynamic>>>
                        gradesBySubject = {};

                        for (var doc in docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          double? val = double.tryParse(
                            data['grade']?.toString() ?? '',
                          );
                          if (val != null) {
                            totalScore += val;
                            validGradesCount++;
                          }

                          String subject = data['courseTitle'] ?? 'General';
                          if (!gradesBySubject.containsKey(subject)) {
                            gradesBySubject[subject] = [];
                          }
                          gradesBySubject[subject]!.add(data);
                        }

                        double average = validGradesCount > 0
                            ? totalScore / validGradesCount
                            : 0;

                        // Mesaj motivațional automat
                        String motivationalMessage = "";
                        Color messageColor = Colors.green;
                        IconData messageIcon = Icons.sentiment_very_satisfied;

                        if (average >= 9.0) {
                          motivationalMessage = "Performanță de top! Ești un elev model, continuă tot așa! 🌟";
                          messageColor = Colors.green.shade700;
                          messageIcon = Icons.emoji_events;
                        } else if (average >= 7.0) {
                          motivationalMessage = "Rezultate foarte bune! Ai un potențial excelent. 🚀";
                          messageColor = accentLila;
                          messageIcon = Icons.thumb_up;
                        } else if (average >= 5.0) {
                          motivationalMessage = "Ești pe drumul cel bun, dar mai este de muncă. Poți mai mult! 💪";
                          messageColor = Colors.orange.shade800;
                          messageIcon = Icons.trending_up;
                        } else {
                          motivationalMessage = "Este nevoie de mai multă atenție și implicare. Ai nevoie de sprijin? 📚";
                          messageColor = Colors.red.shade700;
                          messageIcon = Icons.warning_amber_rounded;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Card Media Generală
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff1e1b4b),
                                    Color(0xff7c4dff),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Media Generală",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Performanță Academică",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      average.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Mesaj Motivațional
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: messageColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: messageColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    messageIcon,
                                    color: messageColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      motivationalMessage,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: messageColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // 3. Grafic separat pentru fiecare Materie
                            const Text(
                              "Evoluție Grafică pe Materii",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryIndigo,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Generăm dinamic câte un card grafic pentru fiecare materie în parte
                            ...gradesBySubject.entries.map((entry) {
                              String subjectName = entry.key;
                              List<Map<String, dynamic>> subjectGrades =
                                  entry.value;

                              // Calculăm media specifică pe materie
                              double subSum = 0;
                              int subCount = 0;
                              for (var item in subjectGrades) {
                                double? v = double.tryParse(
                                  item['grade']?.toString() ?? '',
                                );
                                if (v != null) {
                                  subSum += v;
                                  subCount++;
                                }
                              }
                              double subAvg = subCount > 0
                                  ? subSum / subCount
                                  : 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
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
                                    // Titlu materie și media ei
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.menu_book,
                                              color: accentLila,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              subjectName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryIndigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentLila.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            "Medie: ${subAvg.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: accentLila,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Graficul pe bare al materiei respective (fără eroare de overflow)
                                    SizedBox(
                                      height: 150,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: subjectGrades.map((
                                            gradeItem,
                                          ) {
                                            double val =
                                                double.tryParse(
                                                  gradeItem['grade']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0;
                                            String session =
                                                gradeItem['sessionNumber'] ??
                                                'Test';
                                            String date =
                                                gradeItem['date'] ?? '';

                                            return Container(
                                              width: 65,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    val.toString(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: accentLila,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    height: (val * 9).clamp(
                                                      10.0,
                                                      85.0,
                                                    ),
                                                    width: 16,
                                                    decoration: BoxDecoration(
                                                      color: val >= 8
                                                          ? Colors
                                                                .green
                                                                .shade400
                                                          : (val >= 5
                                                                ? accentLila
                                                                : Colors
                                                                      .orange),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    session,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    date,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
