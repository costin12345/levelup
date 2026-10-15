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
import 'profile_tab.dart'; // 🌟 Import corect pentru Profil
import 'progress_screen.dart'; // 🌟 Import corect pentru Progres

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

        bool isTeacher = userRole == 'teacher';
        bool isParent = userRole == 'parent';

        // 🌟 Generăm ecranele și meniurile dinamic în funcție de rol
        // 🌟 Generăm ecranele corect în funcție de rol

        // 🌟 Generăm ecranele și meniurile dinamic în funcție de rol
        final List<Widget> screens = isTeacher
            ? [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
                const TeacherCatalogScreen(),
                CoursesScreen(role: userRole),
                MaterialsScreen(role: userRole),
                const ProfileTab(), // Index 4
              ]
            : isParent
            ? [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 1)),
                CatalogScreen(role: userRole), // Index 1
                const ProgressScreen(), // Index 2
                const ProfileTab(), // Index 3
              ]
            : [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
                CatalogScreen(role: userRole),
                CoursesScreen(role: userRole),
                MaterialsScreen(role: userRole),
                const ProgressScreen(), // Index 4
                const ProfileTab(), // Index 5
              ];
        return Scaffold(
          backgroundColor: const Color(0xfff8fafc),
          appBar: AppBar(
            backgroundColor: primaryIndigo,
            elevation: 0,
            toolbarHeight: 70,
            titleSpacing: 24,
            title: Row(
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
                    size: 20,
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
            actions: [
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

              // 🌟 Generăm butoanele dinamic în funcție de rol, fără const global
              if (isParent) ...[
                _buildTopNavButton("Home", 0),
                _buildTopNavButton("Catalog", 1),
                _buildTopNavButton("Progres", 2),
                _buildTopNavButton("Profil", 3),
              ] else if (isTeacher) ...[
                _buildTopNavButton("Home", 0),
                _buildTopNavButton("Catalog", 1),
                _buildTopNavButton("Cursuri", 2),
                _buildTopNavButton("Materiale", 3),
                _buildTopNavButton("Profil", 4),
              ] else ...[
                _buildTopNavButton("Home", 0),
                _buildTopNavButton("Catalog", 1),
                _buildTopNavButton("Cursuri", 2),
                _buildTopNavButton("Materiale", 3),
                _buildTopNavButton("Progres", 4),
                _buildTopNavButton("Profil", 5),
              ],

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
}
