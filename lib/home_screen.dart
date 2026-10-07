import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onGoToCourses;

  const HomeTab({super.key, required this.onGoToCourses});

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipPath(
              clipper: _VeeClipper(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryDark,
                      const Color(0xff312e81),
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 160),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentLila.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "ÎNVĂȚARE EFICIENTĂ • REZULTATE GARANTATE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Every problem,\nhas a solution.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Text(
                              "La Level Up, ajutăm fiecare elev și părinte să țină pasul cu performanța prin metode moderne și structurate.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: onGoToCourses,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentLila,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 36,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "VEZI CURSURILE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -110),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentLila.withOpacity(0.3),
                            blurRadius: 50,
                            offset: const Offset(0, 25),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            'images/spatiu.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 800;
                      Widget textContent = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentLila.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "DESPRE NOI",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentLila,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Viziunea, Valorile și Performanța Ta",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryDark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "La Level Up, combinăm educația de performanță cu instrumente moderne de învățare digitală. Fiecare elev beneficiază de mentorat dedicat, monitorizare a progresului în timp real și materiale structurate.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ],
                      );
                      Widget imageContent = Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accentLila.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentLila.withOpacity(0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'images/info.png',
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            textContent,
                            const SizedBox(height: 30),
                            imageContent,
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: textContent),
                            const SizedBox(width: 40),
                            Expanded(child: imageContent),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Container(
              color: primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, usersSnapshot) {
                  int studentCount = 0;
                  int teacherCount = 0;
                  if (usersSnapshot.hasData) {
                    for (var doc in usersSnapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      if (data['role'] == 'teacher') {
                        teacherCount++;
                      } else {
                        studentCount++;
                      }
                    }
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('courses')
                        .snapshots(),
                    builder: (context, coursesSnapshot) {
                      int coursesCount = coursesSnapshot.hasData
                          ? coursesSnapshot.data!.docs.length
                          : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCounterItem(
                            "$studentCount",
                            "Utilizatori",
                            accentLila,
                          ),
                          _buildCounterItem(
                            "$teacherCount",
                            "Profesori",
                            accentLila,
                          ),
                          _buildCounterItem(
                            "$coursesCount",
                            "Cursuri",
                            accentLila,
                          ),
                          _buildCounterItem("24/7", "Suport", accentLila),
                        ],
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

  Widget _buildCounterItem(String count, String label, Color accentLila) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: accentLila,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VeeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
