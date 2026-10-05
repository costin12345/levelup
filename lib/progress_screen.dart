import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GradePoint {
  final double grade;
  final String date;

  GradePoint({required this.grade, required this.date});
}

class ProgressScreen extends StatefulWidget {
  final String role;
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
  String? _selectedStudentFilter;

  @override
  Widget build(BuildContext context) {
    String titleText = widget.role == 'parent'
        ? 'Scările Progresului pe Materii - Copilul Meu'
        : widget.role == 'student'
        ? 'Scările Progresului Meu pe Materii'
        : 'Evoluția Elevilor - Scările Performanței';

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
            if (widget.role == 'teacher') ...[
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, studentSnap) {
                  List<DropdownMenuItem<String>> studentItems = [
                    const DropdownMenuItem(
                      value: "Toți elevii",
                      child: Text("Toți elevii (General)"),
                    ),
                  ];

                  if (studentSnap.hasData) {
                    for (var doc in studentSnap.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data['fullName'] ?? data['name'] ?? 'Elev';
                      studentItems.add(
                        DropdownMenuItem(value: name, child: Text(name)),
                      );
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStudentFilter ?? "Toți elevii",
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                        items: studentItems,
                        onChanged: (val) {
                          setState(() {
                            _selectedStudentFilter = (val == "Toți elevii")
                                ? null
                                : val;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ],

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

            // 🚀 Folosim structura originală cu Expanded + ListView.builder care funcționa perfect
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
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
                      child: Text("Nu există note înregistrate."),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  Map<String, List<GradePoint>> regularGroups = {};
                  Map<String, List<GradePoint>> simulationGroups = {};

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;

                    var rawGrade = data['grade'];
                    double gradeVal = 10.0;
                    if (rawGrade is String) {
                      gradeVal = double.tryParse(rawGrade) ?? 10.0;
                    } else if (rawGrade is num) {
                      gradeVal = rawGrade.toDouble();
                    }

                    String course = data['courseTitle'] ?? 'Matematică';
                    String date = data['date'] ?? '';

                    bool isSim =
                        data['isSimulation'] == true ||
                        (data['title'] != null &&
                            data['title'].toString().toLowerCase().contains(
                              'simulare',
                            ));

                    if (isSim) {
                      if (!simulationGroups.containsKey(course)) {
                        simulationGroups[course] = [];
                      }
                      simulationGroups[course]!.add(
                        GradePoint(grade: gradeVal, date: date),
                      );
                    } else {
                      if (!regularGroups.containsKey(course)) {
                        regularGroups[course] = [];
                      }
                      regularGroups[course]!.add(
                        GradePoint(grade: gradeVal, date: date),
                      );
                    }
                  }

                  Set<String> allSubjects = {
                    ...regularGroups.keys,
                    ...simulationGroups.keys,
                  };
                  var subjectsList = allSubjects.toList();

                  // 🚀 Folosim SingleChildScrollView + Column pentru a garanta afișarea pe web
                  return SingleChildScrollView(
                    child: Column(
                      children: subjectsList.map((subject) {
                        List<GradePoint> regularPoints =
                            regularGroups[subject] ?? [];
                        List<GradePoint> simulationPoints =
                            simulationGroups[subject] ?? [];

                        return Column(
                          children: [
                            // 🏫 1. SCARA PRINCIPALĂ (NOTE CURENTE)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff42153e)
                                        .withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$subject (Note Curente)",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff42153e),
                                        ),
                                      ),
                                      const Text(
                                        "🚶‍♂️ 🎒 Mers pe trepte",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 210,
                                    child: regularPoints.isEmpty
                                        ? const Center(
                                            child: Text(
                                              "Nu există note curente.",
                                            ),
                                          )
                                        : TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 3000,
                                            ),
                                            builder:
                                                (
                                                  context,
                                                  animationValue,
                                                  child,
                                                ) {
                                                  return CustomPaint(
                                                    size: const Size(
                                                      double.infinity,
                                                      210,
                                                    ),
                                                    painter:
                                                        SingleSubjectStaircasePainter(
                                                          points: regularPoints,
                                                          animationProgress:
                                                              animationValue,
                                                        ),
                                                  );
                                                },
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            // 🏆 2. SCARA DE SIMULĂRI
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xfffff3cd),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.military_tech,
                                        color: Colors.orange,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$subject — Simulări & Evaluări",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff42153e),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 210,
                                    child: simulationPoints.isEmpty
                                        ? const Center(
                                            child: Text(
                                              "Nicio simulare înregistrată încă.",
                                              style: TextStyle(
                                                color: Colors.brown,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        : TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 3000,
                                            ),
                                            builder:
                                                (
                                                  context,
                                                  animationValue,
                                                  child,
                                                ) {
                                                  return CustomPaint(
                                                    size: const Size(
                                                      double.infinity,
                                                      210,
                                                    ),
                                                    painter:
                                                        SingleSubjectStaircasePainter(
                                                          points:
                                                              simulationPoints,
                                                          animationProgress:
                                                              animationValue,
                                                        ),
                                                  );
                                                },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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

class SingleSubjectStaircasePainter extends CustomPainter {
  final List<GradePoint> points;
  final double animationProgress;

  SingleSubjectStaircasePainter({
    required this.points,
    required this.animationProgress,
  });

  @override
  bool shouldRepaint(covariant SingleSubjectStaircasePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.points != points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintStaircaseStructure = Paint()
      ..color = const Color(0xff42153e).withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintLine = Paint()
      ..color = const Color(0xff42153e)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double horizontalPadding = 60.0;
    double availableWidth = size.width - (horizontalPadding * 2);

    double dxStep = points.length > 1
        ? availableWidth / (points.length - 1)
        : 0;

    double mapGradeToY(double grade) {
      double paddingBottom = 40.0;
      double paddingTop = 50.0;
      double availableHeight = size.height - paddingBottom - paddingTop;
      return size.height - paddingBottom - ((grade - 1) / 9) * availableHeight;
    }

    List<Offset> evaluatedPoints = [];
    for (int i = 0; i < points.length; i++) {
      double x = points.length == 1
          ? size.width / 2
          : horizontalPadding + (i * dxStep);
      double targetY = mapGradeToY(points[i].grade);
      double y = size.height - (size.height - targetY) * animationProgress;
      evaluatedPoints.add(Offset(x, y));
    }

    Path stairPath = Path();
    Path structurePath = Path();

    for (int i = 0; i < evaluatedPoints.length; i++) {
      double x = evaluatedPoints[i].dx;
      double y = evaluatedPoints[i].dy;

      if (i == 0) {
        stairPath.moveTo(x, y);
      } else {
        double prevX = evaluatedPoints[i - 1].dx;
        double prevY = evaluatedPoints[i - 1].dy;

        stairPath.lineTo(x, prevY);
        stairPath.lineTo(x, y);

        structurePath.moveTo(prevX, size.height - 40);
        structurePath.lineTo(prevX, prevY);
        structurePath.lineTo(x, prevY);
        structurePath.lineTo(x, size.height - 40);
      }
    }

    canvas.drawPath(structurePath, paintStaircaseStructure);
    canvas.drawPath(stairPath, paintLine);

    double exactIndexFloat = animationProgress * (evaluatedPoints.length - 1);
    int currentIndex = exactIndexFloat.floor();
    int nextIndex = (currentIndex + 1 < evaluatedPoints.length)
        ? currentIndex + 1
        : currentIndex;
    double localProgress = exactIndexFloat - currentIndex;

    Offset studentPos;
    if (currentIndex == nextIndex) {
      studentPos = evaluatedPoints[currentIndex];
    } else {
      double currentX = evaluatedPoints[currentIndex].dx;
      double currentY = evaluatedPoints[currentIndex].dy;
      double nextX = evaluatedPoints[nextIndex].dx;
      double nextY = evaluatedPoints[nextIndex].dy;

      double interpX = currentX + (nextX - currentX) * localProgress;
      double interpY = currentY + (nextY - currentY) * localProgress;
      studentPos = Offset(interpX, interpY);
    }

    for (int i = 0; i < points.length; i++) {
      double x = evaluatedPoints[i].dx;
      double y = evaluatedPoints[i].dy;

      Paint pointPaint = Paint()
        ..color = points[i].grade >= 8.0
            ? Colors.green.shade600
            : Colors.orange.shade700
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, pointPaint);

      Paint borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(x, y), 8, borderPaint);

      TextPainter emojiPainter = TextPainter(
        text: TextSpan(
          text: points[i].grade >= 8.0 ? '😊' : '🙁',
          style: const TextStyle(fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      );
      emojiPainter.layout();
      emojiPainter.paint(canvas, Offset(x - (emojiPainter.width / 2), y - 26));

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: "${points[i].grade} (${points[i].date})",
          style: const TextStyle(
            color: Color(0xff42153e),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 24),
      );
    }

    TextPainter studentPainter = TextPainter(
      text: const TextSpan(text: '🚶‍♂️ 🎒', style: TextStyle(fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    studentPainter.layout();
    studentPainter.paint(
      canvas,
      Offset(studentPos.dx - (studentPainter.width / 2), studentPos.dy - 44),
    );
  }
}
