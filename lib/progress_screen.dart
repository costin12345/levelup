import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GradePoint {
  final double grade;
  final String date;
  final String title;

  GradePoint({required this.grade, required this.date, required this.title});
}

class ProgressScreen extends StatefulWidget {
  final String role;
  final String currentUserId;
  final String? childEmail;

  const ProgressScreen({
    super.key,
    required this.role,
    required this.currentUserId,
    this.childEmail,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = "Toate";
  String? _selectedStudentFilter;

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    String titleText = widget.role == 'parent'
        ? 'Progresul Academic - Copilul Meu'
        : widget.role == 'student'
        ? 'Progresul Meu Academic'
        : 'Panou Performanță Elevi';

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStudentFilter ?? "Toți elevii",
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: primaryIndigo,
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
                  "Evoluția Notelor & Concluzii",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryIndigo,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: primaryIndigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: accentLila),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Nu există note înregistrate."),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  Map<String, List<GradePoint>> subjectGroups = {};

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
                    String title = data['title'] ?? 'Evaluare';

                    if (!subjectGroups.containsKey(course)) {
                      subjectGroups[course] = [];
                    }
                    subjectGroups[course]!.add(
                      GradePoint(grade: gradeVal, date: date, title: title),
                    );
                  }

                  var subjects = subjectGroups.keys.toList();

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      String subject = subjects[index];
                      List<GradePoint> points = subjectGroups[subject]!;

                      double sum = points.fold(
                        0,
                        (sum, element) => sum + element.grade,
                      );
                      double average = points.isNotEmpty
                          ? sum / points.length
                          : 0.0;

                      // Generare concluzie automată bazată pe medie
                      String conclusionText = "";
                      Color conclusionColor = Colors.green;
                      IconData conclusionIcon = Icons.sentiment_very_satisfied;

                      if (average >= 9.0) {
                        conclusionText = "Performanță excelentă! Elevul demonstrează o înțelegere profundă a materiei și consecvență la evaluări.";
                        conclusionColor = Colors.green.shade700;
                        conclusionIcon = Icons.military_tech;
                      } else if (average >= 7.0) {
                        conclusionText = "Rezultate bune și un ritm stabil de învățare. Cu puțină atenție suplimentară, se poate atinge excelența.";
                        conclusionColor = Colors.blue.shade700;
                        conclusionIcon = Icons.thumb_up;
                      } else {
                        conclusionText = "Atenție sporită necesară! Se recomandă recapitularea temelor anterioare și o comunicare mai strânsă cu profesorul.";
                        conclusionColor = Colors.orange.shade800;
                        conclusionIcon = Icons.warning_amber_rounded;
                      }

                      double chartWidth = points.length > 5
                          ? points.length * 80.0
                          : MediaQuery.of(context).size.width - 70;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Antet Materie și Medie
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentLila.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.show_chart,
                                        color: accentLila,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentLila.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Media: ${average.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: primaryIndigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // GRAFICUL DE LINIE INTERACTIV CU SCROLL
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: chartWidth,
                                height: 230,
                                child: points.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "Fără date pentru grafic",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : CustomPaint(
                                        size: Size(chartWidth, 230),
                                        painter: LineChartPainter(
                                          points: points,
                                          primaryColor: accentLila,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // CASETA DE CONCLUZIE AUTOMATĂ
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: conclusionColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: conclusionColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    conclusionIcon,
                                    color: conclusionColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Concluzie & Evaluare:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          conclusionText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// --- CUSTOM PAINTER PREMIUM PENTRU GRAFICUL DE LINIE ---
// ============================================================================
class LineChartPainter extends CustomPainter {
  final List<GradePoint> points;
  final Color primaryColor;

  LineChartPainter({required this.points, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    double paddingLeft = 35.0;
    double paddingBottom = 40.0;
    double paddingTop = 30.0;
    double availableWidth = size.width - paddingLeft - 25;
    double availableHeight = size.height - paddingBottom - paddingTop;

    for (int grade = 2; grade <= 10; grade += 2) {
      double y =
          paddingTop + availableHeight - ((grade - 1) / 9) * availableHeight;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - 10, y),
        paintGrid,
      );

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '$grade',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - (textPainter.height / 2)));
    }

    double dxStep = points.length > 1
        ? availableWidth / (points.length - 1)
        : availableWidth / 2;

    List<Offset> coords = [];
    for (int i = 0; i < points.length; i++) {
      double x =
          paddingLeft + (points.length == 1 ? availableWidth / 2 : i * dxStep);
      double y =
          paddingTop +
          availableHeight -
          ((points[i].grade - 1) / 9) * availableHeight;
      coords.add(Offset(x, y));
    }

    if (coords.length > 1) {
      Path fillPath = Path.from(
        Path()..moveTo(coords.first.dx, paddingTop + availableHeight),
      );
      for (var coord in coords) {
        fillPath.lineTo(coord.dx, coord.dy);
      }
      fillPath.lineTo(coords.last.dx, paddingTop + availableHeight);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.25),
                primaryColor.withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromLTWH(0, paddingTop, size.width, availableHeight),
            );

      canvas.drawPath(fillPath, fillPaint);
    }

    Path path = Path();
    for (int i = 0; i < coords.length; i++) {
      if (i == 0) {
        path.moveTo(coords[i].dx, coords[i].dy);
      } else {
        path.lineTo(coords[i].dx, coords[i].dy);
      }
    }
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < coords.length; i++) {
      bool isGood = points[i].grade >= 8.0;

      Paint glowPaint = Paint()
        ..color = (isGood ? Colors.green : Colors.orange).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(coords[i], 10, glowPaint);

      Paint pointPaint = Paint()
        ..color = isGood ? Colors.green.shade600 : Colors.orange.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(coords[i], 6, pointPaint);

      Paint whiteBorder = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(coords[i], 6, whiteBorder);

      TextPainter gradePainter = TextPainter(
        text: TextSpan(
          text: "${points[i].grade}",
          style: TextStyle(
            color: isGood ? Colors.green.shade800 : Colors.orange.shade900,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      gradePainter.layout();
      gradePainter.paint(
        canvas,
        Offset(coords[i].dx - (gradePainter.width / 2), coords[i].dy - 25),
      );

      TextPainter datePainter = TextPainter(
        text: TextSpan(
          text: points[i].date,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      datePainter.layout();
      datePainter.paint(
        canvas,
        Offset(coords[i].dx - (datePainter.width / 2), size.height - 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.primaryColor != primaryColor;
  }
}
