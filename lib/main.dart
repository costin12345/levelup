import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainScreen());
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Level Up Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1e1b4b)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- ECRANUL PRINCIPAL CU MENIUL DE SUS ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // 1 este "Catalog" setat implicit

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
      const TeacherCatalogScreen(),
      const Center(
        child: Text(
          "Cursuri & Materiale",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      const Center(
        child: Text(
          "Progres & Statistici",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryIndigo,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: primaryIndigo, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "LEVEL UP",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          _buildTopNavButton("Home", 0),
          _buildTopNavButton("Catalog", 1),
          _buildTopNavButton("Cursuri", 2),
          _buildTopNavButton("Progres", 3),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.logout, color: Colors.white70),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _screens[_currentIndex],
    );
  }

  Widget _buildTopNavButton(String title, int index) {
    bool isSelected = _currentIndex == index;
    return TextButton(
      onPressed: () => setState(() => _currentIndex = index),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xffffd700) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ==========================================
// --- HOME TAB ---
// ==========================================
class HomeTab extends StatelessWidget {
  final VoidCallback onGoToCourses;

  const HomeTab({super.key, required this.onGoToCourses});

  @override
  Widget build(BuildContext context) {
    // User? currentUser = FirebaseAuth.instance.currentUser;
    const Color primaryDark = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECȚIUNEA SUPERIOARĂ (CU DEGRADE ȘI FORMULE) ---
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
                child: Stack(
                  children: [
                    Positioned(
                      top: 30,
                      left: 40,
                      child: Text(
                        "E = mc²",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 80,
                      right: 60,
                      child: Text(
                        "∫ f(x)dx",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      left: 80,
                      child: Text(
                        "a² + b² = c²",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 150,
                      right: 180,
                      child: Text(
                        "π ≈ 3.14",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 160,
                      right: 100,
                      child: Text(
                        "lim (1 + 1/n)ⁿ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.06),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Padding(
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
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
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
                  ],
                ),
              ),
            ),

            // --- WHITEBOARD DISPLAY ---
            Transform.translate(
              offset: const Offset(0, -110),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      children: [
                        Container(
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
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.asset(
                                    'images/spatiu.jpeg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        primaryDark.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "• Monitorizare note în timp real",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "• Conexiune părinte-elev",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 140,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- DESPRE NOI ---
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
                            "La Level Up, combinăm educația de performanță cu instrumente moderne de învățare digitală. Fiecare elev beneficiază de mentorat dedicat, monitorizare a progresului în timp real și materiale structurate pentru a obține rezultate excepționale la examene și în carieră.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: onGoToCourses,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text(
                              "Află mai multe",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      );

                      Widget imageContent = _buildInfoImageCard(
                        accentLila,
                        primaryDark,
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
            const SizedBox(height: 80),

            // --- CARDURI FACILITĂȚI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildFeatureCard(
                            Icons.school,
                            "Excelență Academică",
                            "Materiale structurate",
                            constraints.maxWidth,
                            accentLila,
                          ),
                          _buildFeatureCard(
                            Icons.groups,
                            "Corp Didactic",
                            "Mentori cu experiență",
                            constraints.maxWidth,
                            accentLila,
                          ),
                          _buildFeatureCard(
                            Icons.sports_esports,
                            "Gamification",
                            "Învățare prin joc",
                            constraints.maxWidth,
                            accentLila,
                          ),
                          _buildFeatureCard(
                            Icons.verified,
                            "Valori & Integritate",
                            "Dezvoltare personală",
                            constraints.maxWidth,
                            accentLila,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // --- STATISTICI DIN FIREBASE ---
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

            // --- FOOTER ---
            Container(
              color: const Color(0xff0f172a),
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'images/logo.jpg',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "LEVEL UP",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Platformă educațională modernă destinată performanței.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    "© 2026 Level Up App. Toate drepturile rezervate.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoImageCard(Color accentLila, Color primaryDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentLila.withOpacity(0.2), width: 1.5),
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
        ),
        Positioned(
          top: 25,
          left: -15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentLila.withOpacity(0.15),
                  child: const Icon(
                    Icons.star,
                    color: Color(0xff7c4dff),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // <-- Fără 'const'
                    Text(
                      "Excelență",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: primaryDark,
                      ),
                    ),
                    Text(
                      "Evaluare 5 Stele",
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String desc,
    double maxWidth,
    Color accentLila,
  ) {
    double cardWidth = maxWidth > 800
        ? (maxWidth - 48) / 4
        : (maxWidth - 16) / 2;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentLila.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: accentLila.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentLila, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xff1e1b4b),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
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

// ==========================================
// --- TEACHER CATALOG SCREEN ---
// ==========================================
class TeacherCatalogScreen extends StatefulWidget {
  const TeacherCatalogScreen({super.key});

  @override
  State<TeacherCatalogScreen> createState() => _TeacherCatalogScreenState();
}

class _TeacherCatalogScreenState extends State<TeacherCatalogScreen> {
  String _selectedFilterClass = "Toate";
  String _selectedFilterGroup = "Toate";
  String _selectedFilterCourse = "Toate";
  String _selectedFilterGrade = "Toate";
  String _selectedFilterType = "Toate";
  String? _selectedSingleStudent;

  String _activeCatalogMenu = "Note și Absențe";
  String _reportScope = "Pe Grupe";

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    bool isMediiPeGrupa = _activeCatalogMenu == "Medii pe Grupă";
    bool isRapoarte = _activeCatalogMenu == "Rapoarte Academice";

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MENIUL LATERAL INTERN AL CATALOGULUI ---
          Container(
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
                      child: const Icon(
                        Icons.menu_book,
                        color: accentLila,
                        size: 20,
                      ),
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
                ),
                _buildSidebarItem(
                  "Medii pe Grupă",
                  Icons.bar_chart,
                  accentLila,
                  primaryIndigo,
                ),
                _buildSidebarItem(
                  "Rapoarte Academice",
                  Icons.description_outlined,
                  accentLila,
                  primaryIndigo,
                ),
                _buildSidebarItem(
                  "Arhivă Teste",
                  Icons.folder_shared_outlined,
                  accentLila,
                  primaryIndigo,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.black12),

          // --- CONȚINUTUL PRINCIPAL ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ANTET SAAS MODERN ---
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeCatalogMenu,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMediiPeGrupa
                                  ? "Situația mediilor centralizate pe fiecare clasă și grupă în parte"
                                  : isRapoarte
                                  ? "Statistici vizuale și rapoarte de performanță academică"
                                  : "Managementul avansat al notelor, absențelor și progresului pe rânduri",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        if (!isMediiPeGrupa && !isRapoarte)
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const AddGradeDialog(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentLila,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  "Adaugă Notă",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => _showAddAbsenceDialog(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.event_busy,
                                  size: 16,
                                  color: Colors.amberAccent,
                                ),
                                label: const Text(
                                  "Adaugă Absență",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- FILTRE (APAR DOAR LA NOTE ȘI ABSENȚE) ---
                  if (!isMediiPeGrupa && !isRapoarte)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('grades')
                          .snapshots(),
                      builder: (context, snapshot) {
                        Set<String> classes = {"Toate"};
                        Set<String> groups = {"Toate"};
                        Set<String> courses = {
                          "Toate",
                          "Matematică",
                          "Informatică",
                          "Fizică",
                        };
                        Set<String> gradesSet = {"Toate"};
                        Set<String> studentsSet = {"Toți elevii"};

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            if (data['className'] != null)
                              classes.add(data['className']);
                            if (data['groupName'] != null)
                              groups.add(data['groupName']);
                            if (data['grade'] != null)
                              gradesSet.add(data['grade']);
                            if (data['studentName'] != null)
                              studentsSet.add(data['studentName']);
                          }
                        }

                        Set<String> typeOptions = {
                          "Toate",
                          "Doar Note",
                          "Doar Absențe",
                        };

                        return Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Clasa",
                                  _selectedFilterClass,
                                  classes,
                                  (val) => setState(
                                    () => _selectedFilterClass = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Grupa",
                                  _selectedFilterGroup,
                                  groups,
                                  (val) => setState(
                                    () => _selectedFilterGroup = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Elev",
                                  _selectedSingleStudent ?? "Toți elevii",
                                  studentsSet,
                                  (val) => setState(
                                    () => _selectedSingleStudent =
                                        val == "Toți elevii" ? null : val,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Materia",
                                  _selectedFilterCourse,
                                  courses,
                                  (val) => setState(
                                    () => _selectedFilterCourse = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Nota",
                                  _selectedFilterGrade,
                                  gradesSet,
                                  (val) => setState(
                                    () => _selectedFilterGrade = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: _buildFineDropdown(
                                  "Afișare",
                                  _selectedFilterType,
                                  typeOptions,
                                  (val) => setState(
                                    () => _selectedFilterType = val!,
                                  ),
                                  accentLila,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (!isMediiPeGrupa && !isRapoarte)
                    const SizedBox(height: 16),

                  // --- CONȚINUT DINAMIC DUPĂ TABUL ACTIV ---
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Text(
                "Nivel analiză an școlar: ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1e1b4b),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text("Pe Grupe"),
                selected: _reportScope == "Pe Grupe",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Grupe"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Grupe"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Pe Elevi"),
                selected: _reportScope == "Pe Elevi",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Elevi"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Elevi"),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Pe Clase"),
                selected: _reportScope == "Pe Clase",
                selectedColor: accentLila.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _reportScope == "Pe Clase"
                      ? accentLila
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) => setState(() => _reportScope = "Pe Clase"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('grades').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    "Nu există date pentru generarea graficului anual.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            Map<String, Map<String, List<double>>> entityMonthlyGrades = {};

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              double? gradeVal = double.tryParse(
                data['grade']?.toString() ?? '',
              );
              if (gradeVal == null) continue;

              String dateStr = data['date'] ?? '';
              String monthShort = "Oct";
              if (dateStr.contains('.')) {
                List<String> parts = dateStr.split('.');
                if (parts.length >= 2) {
                  int monthNum = int.tryParse(parts[1]) ?? 10;
                  switch (monthNum) {
                    case 9:
                      monthShort = "Sept";
                      break;
                    case 10:
                      monthShort = "Oct";
                      break;
                    case 11:
                      monthShort = "Noi";
                      break;
                    case 12:
                      monthShort = "Dec";
                      break;
                    case 1:
                      monthShort = "Ian";
                      break;
                    case 2:
                      monthShort = "Feb";
                      break;
                    case 3:
                      monthShort = "Mar";
                      break;
                    case 4:
                      monthShort = "Apr";
                      break;
                    case 5:
                      monthShort = "Mai";
                      break;
                    case 6:
                      monthShort = "Iun";
                      break;
                    default:
                      monthShort = "Oct";
                  }
                }
              }

              String entityKey = "";
              if (_reportScope == "Pe Grupe") {
                entityKey =
                    "${data['className'] ?? 'Clasă'} (${data['groupName'] ?? 'Grupă'})";
              } else if (_reportScope == "Pe Elevi") {
                entityKey = data['studentName'] ?? 'Elev';
              } else {
                entityKey = data['className'] ?? 'Clasa generală';
              }

              if (!entityMonthlyGrades.containsKey(entityKey)) {
                entityMonthlyGrades[entityKey] = {};
              }
              if (!entityMonthlyGrades[entityKey]!.containsKey(monthShort)) {
                entityMonthlyGrades[entityKey]![monthShort] = [];
              }
              entityMonthlyGrades[entityKey]![monthShort]!.add(gradeVal);
            }

            List<String> entities = entityMonthlyGrades.keys.toList();

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
                      Row(
                        children: [
                          Icon(
                            _reportScope == "Pe Elevi"
                                ? Icons.person
                                : _reportScope == "Pe Grupe"
                                ? Icons.group
                                : Icons.class_,
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
                      const Text(
                        "Evoluția mediilor pe parcursul anului școlar:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

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
        ),
      ],
    );
  }

  Widget _buildMediiPeGrupaView(Color primaryIndigo, Color accentLila) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: accentLila)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Text(
                "Nu există note înregistrate pentru calculul mediilor pe grupe.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        Map<String, List<double>> groupGrades = {};
        Map<String, Set<String>> groupStudents = {};
        Map<String, String> groupTitleMap = {};

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;

          String className = data['className'] ?? 'Clasa generală';
          String groupName = data['groupName'] ?? 'Grupa A';
          String studentName = data['studentName'] ?? 'Elev';
          double? gradeVal = double.tryParse(data['grade']?.toString() ?? '');

          String uniqueKey = "$className — $groupName";

          if (!groupGrades.containsKey(uniqueKey)) {
            groupGrades[uniqueKey] = [];
            groupStudents[uniqueKey] = {};
            groupTitleMap[uniqueKey] = "$className ($groupName)";
          }

          groupStudents[uniqueKey]!.add(studentName);
          if (gradeVal != null) {
            groupGrades[uniqueKey]!.add(gradeVal);
          }
        }

        List<String> keys = groupGrades.keys.toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            String key = keys[index];
            List<double> grades = groupGrades[key]!;
            int studentCount = groupStudents[key]!.length;
            String displayTitle = groupTitleMap[key] ?? key;

            double sum = 0;
            for (var g in grades) {
              sum += g;
            }
            String groupAverage = grades.isNotEmpty
                ? (sum / grades.length).toStringAsFixed(2)
                : "-";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentLila.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group_outlined,
                          color: accentLila,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryIndigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$studentCount elevi în grupă • ${grades.length} note total",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accentLila.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Media Grupei",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentLila,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          groupAverage,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: accentLila,
                            fontSize: 18,
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
    );
  }

  Widget _buildNoteSiAbsenteView(Color accentLila, Color primaryIndigo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('grades').snapshots(),
      builder: (context, gradesSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('absences').snapshots(),
          builder: (context, absencesSnapshot) {
            if (gradesSnapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: accentLila),
                ),
              );
            }

            Set<String> allStudents = {};
            Map<String, List<Map<String, dynamic>>> studentGrades = {};
            Map<String, List<Map<String, dynamic>>> studentAbsences = {};
            Map<String, String> studentClasses = {};

            if (gradesSnapshot.hasData &&
                _selectedFilterType != "Doar Absențe") {
              for (var doc in gradesSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String name = data['studentName'] ?? 'Elev';

                if (_selectedFilterClass != "Toate" &&
                    data['className'] != _selectedFilterClass)
                  continue;
                if (_selectedFilterGroup != "Toate" &&
                    data['groupName'] != _selectedFilterGroup)
                  continue;
                if (_selectedSingleStudent != null &&
                    name != _selectedSingleStudent)
                  continue;
                if (_selectedFilterCourse != "Toate" &&
                    data['courseTitle'] != _selectedFilterCourse)
                  continue;
                if (_selectedFilterGrade != "Toate" &&
                    data['grade'] != _selectedFilterGrade)
                  continue;

                allStudents.add(name);
                studentClasses[name] =
                    "${data['className'] ?? ''} (${data['groupName'] ?? 'Grupă'})";

                if (!studentGrades.containsKey(name)) studentGrades[name] = [];
                studentGrades[name]!.add({
                  'id': doc.id,
                  'grade': data['grade'] ?? '',
                  'course': data['courseTitle'] ?? 'Materie',
                  'date': data['date'] ?? 'Azi',
                });
              }
            }

            if (absencesSnapshot.hasData &&
                _selectedFilterType != "Doar Note") {
              for (var doc in absencesSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String name = data['studentName'] ?? 'Elev';

                if (_selectedFilterGroup != "Toate" &&
                    data['groupName'] != _selectedFilterGroup)
                  continue;
                if (_selectedSingleStudent != null &&
                    name != _selectedSingleStudent)
                  continue;
                if (_selectedFilterCourse != "Toate" &&
                    data['courseTitle'] != _selectedFilterCourse)
                  continue;

                allStudents.add(name);

                if (!studentAbsences.containsKey(name))
                  studentAbsences[name] = [];
                studentAbsences[name]!.add({
                  'id': doc.id,
                  'course': data['courseTitle'] ?? 'Materie',
                  'date': data['date'] ?? 'Azi',
                });
              }
            }

            if (allStudents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "Nicio înregistrare găsită pentru filtrele selectate.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              );
            }

            List<String> studentList = allStudents.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studentList.length,
              itemBuilder: (context, index) {
                String studentName = studentList[index];
                List<Map<String, dynamic>> grades =
                    studentGrades[studentName] ?? [];
                List<Map<String, dynamic>> absences =
                    studentAbsences[studentName] ?? [];
                String classInfo = studentClasses[studentName] ?? '';

                double sum = 0;
                int count = 0;
                for (var item in grades) {
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
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: accentLila.withOpacity(0.12),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    classInfo.isNotEmpty
                                        ? classInfo
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
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (grades.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: grades.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentLila.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentLila.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['course'],
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  item['grade'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: primaryIndigo,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "(${item['date']})",
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () async {
                                            await FirebaseFirestore.instance
                                                .collection('grades')
                                                .doc(item['id'])
                                                .delete();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (absences.isNotEmpty) ...[
                              if (grades.isNotEmpty) const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: absences.map((abs) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff1f5f9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              abs['course'],
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.event_busy,
                                                  size: 11,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  "Absență",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: Color(0xff475569),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "(${abs['date']})",
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () async {
                                            await FirebaseFirestore.instance
                                                .collection('absences')
                                                .doc(abs['id'])
                                                .delete();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
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
        );
      },
    );
  }

  void _showAddAbsenceDialog(BuildContext context) {
    String studentName = "";
    String groupName = "9A";
    String courseTitle = "Matematică";
    String date =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adaugă Absență"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nume Elev"),
                onChanged: (val) => studentName = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Grupa (ex: 9A, 9B)",
                ),
                onChanged: (val) => groupName = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Materie (ex: Matematică)",
                ),
                onChanged: (val) => courseTitle = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Data (ex: 05.10.2026)",
                ),
                controller: TextEditingController(text: date),
                onChanged: (val) => date = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7c4dff),
              ),
              onPressed: () async {
                if (studentName.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('absences').add({
                    'studentName': studentName,
                    'groupName': groupName,
                    'courseTitle': courseTitle,
                    'date': date,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Salvează Absența",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    Color accentLila,
    Color primaryIndigo,
  ) {
    bool isSelected = _activeCatalogMenu == title;
    return InkWell(
      onTap: () => setState(() => _activeCatalogMenu = title),
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

  Widget _buildFineDropdown(
    String label,
    String currentValue,
    Set<String> items,
    ValueChanged<String?> onChanged,
    Color accentLila,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: accentLila),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                "$label: $item",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff1e1b4b),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ==========================================
// --- ADD GRADE DIALOG ---
// ==========================================
class AddGradeDialog extends StatefulWidget {
  const AddGradeDialog({super.key});

  @override
  State<AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<AddGradeDialog> {
  String studentName = "";
  String className = "9A";
  String groupName = "Grupa 1";
  String courseTitle = "Matematică";
  String grade = "10";
  String date =
      "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

  @override
  Widget build(BuildContext context) {
    const Color accentLila = Color(0xff7c4dff);

    return AlertDialog(
      title: const Text("Adaugă Notă Nouă"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Nume Elev"),
              onChanged: (val) => studentName = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: "Clasa (ex: 9A, 10B)",
              ),
              controller: TextEditingController(text: className),
              onChanged: (val) => className = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: "Grupa (ex: Grupa 1)",
              ),
              controller: TextEditingController(text: groupName),
              onChanged: (val) => groupName = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Materie"),
              controller: TextEditingController(text: courseTitle),
              onChanged: (val) => courseTitle = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Nota (ex: 9, 10)"),
              controller: TextEditingController(text: grade),
              onChanged: (val) => grade = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Data"),
              controller: TextEditingController(text: date),
              onChanged: (val) => date = val,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anulează"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentLila),
          onPressed: () async {
            if (studentName.isNotEmpty) {
              await FirebaseFirestore.instance.collection('grades').add({
                'studentName': studentName,
                'className': className,
                'groupName': groupName,
                'courseTitle': courseTitle,
                'grade': grade,
                'date': date,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text("Salvează", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
