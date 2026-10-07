import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:levelup/teacher_catalog_screen.dart';

import 'courses_screen.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'login_screen.dart';
import 'materials_screen.dart';
import 'notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainScreen());
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    return MaterialApp(
      title: 'Level Up Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryIndigo),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff8fafc),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xfff8fafc),
              body: Center(
                child: CircularProgressIndicator(color: primaryIndigo),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    final currentUser = FirebaseAuth.instance.currentUser;
    // Verificăm lățimea ecranului pentru a ști dacă suntem pe telefon
    bool isMobile = MediaQuery.of(context).size.width < 750;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid ?? 'dummy_user')
          .snapshots(),
      builder: (context, userSnapshot) {
        String userRole = 'teacher';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var data = userSnapshot.data!.data() as Map<String, dynamic>?;
          userRole = data?['role'] ?? 'teacher';
        }

        final List<Widget> screens = [
          HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
          const TeacherCatalogScreen(),
          CoursesScreen(role: userRole),
          MaterialsScreen(role: userRole),
          const Center(
            child: Text(
              "Progres & Statistici",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryIndigo,
              ),
            ),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xfff8fafc),
          // 🚀 Meniul lateral (Drawer) care se poate închide/deschide pe telefon
          drawer: isMobile
              ? Drawer(
            child: Container(
              color: primaryIndigo,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xff151336),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: primaryIndigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "LEVEL UP",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDrawerItem("Home", 0, Icons.home_outlined),
                  _buildDrawerItem("Catalog", 1, Icons.menu_book_outlined),
                  _buildDrawerItem("Cursuri", 2, Icons.book_outlined),
                  _buildDrawerItem("Materiale", 3, Icons.folder_outlined),
                  _buildDrawerItem("Progres", 4, Icons.bar_chart_outlined),
                  const Divider(color: Colors.white24, height: 32),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      "Deconectare",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Închide drawer-ul
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
          )
              : null,
          appBar: AppBar(
            backgroundColor: primaryIndigo,
            elevation: 0,
            toolbarHeight: 70,
            titleSpacing: isMobile ? 0 : 24,
            // 🚀 Pe telefon apare automat iconița cu 3 linii (Hamburger), pe desktop nu
            iconTheme: const IconThemeData(color: Colors.white),
            title: Row(
              children: [
                if (!isMobile) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: primaryIndigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Text(
                  "LEVEL UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              // Buton Notificări
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(role: userRole),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                tooltip: "Notificări",
              ),
              const SizedBox(width: 8),

              // Pe desktop afișăm butoanele orizontale, pe telefon le ascundem în meniul cu 3 linii
              if (!isMobile) ...[
                _buildTopNavButton("Home", 0),
                _buildTopNavButton("Catalog", 1),
                _buildTopNavButton("Cursuri", 2),
                _buildTopNavButton("Materiale", 3),
                _buildTopNavButton("Progres", 4),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: "Deconectare",
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
          body: screens[_currentIndex],
        );
      },
    );
  }

  Widget _buildTopNavButton(String title, int index) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () => setState(() => _currentIndex = index),
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? const Color(0xffffd700) : Colors.white,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xffffd700) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xffffd700) : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xffffd700) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context); // Închide meniul lateral după selecție
      },
    );
  }
}