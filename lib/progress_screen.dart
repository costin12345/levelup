import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatefulWidget {
  final String role; // 'student', 'parent', sau 'teacher'
  final String currentUserId;
  final String? childEmail;

  const ProgressScreen({
    Key? key,
    required this.role,
    required this.currentUserId,
    this.childEmail,
  }) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = "Toate";

  @override
  Widget build(BuildContext context) {
    String titleText = widget.role == 'parent'
        ? 'Scările Progresului pe Materii - Copilul Meu'
        : widget.role == 'student'
        ? 'Scările Progresului Meu pe Materii'
        : 'Scările Performanței pe Materii (Elevi)';

    String fieldQuery = widget.role == 'parent' ? 'studentEmail' : 'studentId';
    String valueQuery = widget.role == 'parent'
        ? (widget.childEmail ?? '')
        : widget.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selectorul de perioade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Evoluția pe discipline:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff42153e),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xff42153e),
                    fontWeight: FontWeight.bold,
                  ),
                  items: ["Toate", "Luna aceasta", "Săptămâna aceasta"]
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPeriod = val!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista materiilor, fiecare având scara ei dedicată
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.role == 'teacher'
                    ? FirebaseFirestore.instance
                          .collection('grades')
                          .snapshots()
                    : FirebaseFirestore.instance
                          .collection('grades')
                          .where(fieldQuery, isEqualTo: valueQuery)
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
                        "Nu există note înregistrate pentru a genera scările pe materii.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  // Grupăm notele pe materii (Course Title)
                  Map<String, List<GradePoint>> subjectGroups = {};

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String gradeStr = data['grade'] ?? '10';
                    double gradeVal = double.tryParse(gradeStr) ?? 10.0;
                    String course = data['courseTitle'] ?? 'Materie Generală';
                    String date = data['date'] ?? '';
                    String studentName = data['studentName'] ?? '';

                    String displayKey =
                        widget.role == 'teacher' && studentName.isNotEmpty
                        ? "$course ($studentName)"
                        : course;

                    if (!subjectGroups.containsKey(displayKey)) {
                      subjectGroups[displayKey] = [];
                    }

                    subjectGroups[displayKey]!.add(
                      GradePoint(grade: gradeVal, date: date),
                    );
                  }

                  var subjects = subjectGroups.keys.toList();

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      String subject = subjects[index];
                      List<GradePoint> points = subjectGroups[subject]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff42153e).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titlul materiei și legenda rapidă
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subject,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff42153e),
                                  ),
                                ),
                                Row(
                                  children: const [
                                    Text(
                                      "😊 Urcă (≥8)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "🙁 Coborâre (<8)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Scara animată dedicată acestei materii
                            SizedBox(
                              height: 130,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1000),
                                builder: (context, animationValue, child) {
                                  return CustomPaint(
                                    size: const Size(double.infinity, 130),
                                    painter: SingleSubjectStaircasePainter(
                                      points: points,
                                      animationProgress: animationValue,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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

class GradePoint {
  final double grade;
  final String date;

  GradePoint({required this.grade, required this.date});
}

// Pictorul pentru scara fiecărei materii în parte
class SingleSubjectStaircasePainter extends CustomPainter {
  final List<GradePoint> points;
  final double animationProgress;

  SingleSubjectStaircasePainter({
    required this.points,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xff42153e)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double dxStep = points.length > 1
        ? size.width / (points.length - 1)
        : size.width / 2;

    double mapGradeToY(double grade) {
      double paddingBottom = 25.0;
      double paddingTop = 25.0;
      double availableHeight = size.height - paddingBottom - paddingTop;
      return size.height - paddingBottom - ((grade - 1) / 9) * availableHeight;
    }

    Path path = Path();

    for (int i = 0; i < points.length; i++) {
      double x = points.length == 1 ? size.width / 2 : i * dxStep;
      double targetY = mapGradeToY(points[i].grade);
      double y = size.height - (size.height - targetY) * animationProgress;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    // Punctele, fețele zâmbitoare/triste și notele pe trepte
    for (int i = 0; i < points.length; i++) {
      double x = points.length == 1 ? size.width / 2 : i * dxStep;
      double targetY = mapGradeToY(points[i].grade);
      double y = size.height - (size.height - targetY) * animationProgress;

      Paint pointPaint = Paint()
        ..color = points[i].grade >= 8.0
            ? Colors.green.shade600
            : Colors.orange.shade700
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 7, pointPaint);

      Paint borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(x, y), 7, borderPaint);

      // Fața fericită sau tristă
      TextPainter emojiPainter = TextPainter(
        text: TextSpan(
          text: points[i].grade >= 8.0 ? '😊' : '🙁',
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      emojiPainter.layout();
      emojiPainter.paint(canvas, Offset(x - 8, y - 28));

      // Nota și data dedesubt
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: "${points[i].grade} (${points[i].date})",
          style: const TextStyle(
            color: Color(0xff42153e),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
