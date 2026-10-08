import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:levelup/teacher_catalog_screen.dart';

import 'catalog_screen.dart';
import 'notifications_screen.dart';
import 'courses_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'add_grade_dialog.dart';
import 'progress_screen.dart'; // Asigură-te că importi fișierul cu ecranul de progres

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
// --- FUNCȚII GLOBALE PENTRU NOTIFICĂRI ---

Future<void> clearAppBadge() async {
  if (kIsWeb) return;

  try {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      if (FirebaseAuth.instance.currentUser == null) {
        FlutterAppBadger.removeBadge();
      }
    }
  } catch (e) {
    debugPrint("Eroare la ștergerea badge-ului: $e");
  }
}

Future<void> saveTokenToFirestore(String token) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("SUCCESS: FCM Token salvat în Firestore pentru: ${user.uid}");
    } catch (e) {
      debugPrint("Eroare la salvarea FCM Token: $e");
    }
  }
}

Future<void> setupFCM() async {
  if (kIsWeb) return;

  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      messaging.onTokenRefresh.listen((newToken) {
        saveTokenToFirestore(newToken);
      });

      String? fcmToken = await messaging.getToken();

      if (fcmToken == null && defaultTargetPlatform == TargetPlatform.iOS) {
        await Future.delayed(const Duration(seconds: 3));
        fcmToken = await messaging.getToken();
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await saveTokenToFirestore(fcmToken);
      }
    }
  } catch (e) {
    debugPrint("Eroare FCM: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    try {
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.removeBadge();
      }
    } catch (_) {}
  }

  runApp(const LevelUpApp());
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    return MaterialApp(
      title: 'Level Up',
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
              body: Center(
                child: CircularProgressIndicator(color: primaryIndigo),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
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

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    _changeTab(0);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    const Color primaryIndigo = Color(0xff1e1b4b);
    return StreamBuilder<DocumentSnapshot>(
      stream: currentUser != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots()
          : null,
      builder: (context, userSnapshot) {
        String userRole = 'student';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          userRole = userData?['role'] ?? 'student';
        }

        List<Widget> pages = [];
        List<String> menuTitles = [];

        if (userRole == 'teacher') {
          menuTitles = [
            "Home",
            "Catalog",
            "Cursuri",
            // Fără Profil, dacă l-ai scos
          ];
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(2)),
            const TeacherCatalogScreen(),
            CoursesScreen(role: userRole),
            ProgressScreen(role: 'teacher', currentUserId: currentUser!.uid),
            // Dacă ai adăugat Arhivă sau alt ecran, îl pui aici
            const Center(
              child: Text(
                "Arhivă teste",
                style: TextStyle(
                  color: Color(0xff1e1b4b),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        } else if (userRole == 'parent') {
          menuTitles = ["Home", "Catalog", "Copilul Meu", "Profil"];
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(1)),
            const CatalogScreen(role: 'parent'),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                String childEmail = '';
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  childEmail = data['childEmail'] ?? '';
                }
                return ProgressScreen(
                  role: 'parent',
                  currentUserId: currentUser!.uid,
                  childEmail: childEmail,
                );
              },
            ),
            const Center(
              child: Text(
                "Profilul Părintelui",
                style: TextStyle(
                  color: primaryIndigo,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        } else {
          // Student / Elev
          menuTitles = ["Home", "Catalog", "Cursuri", "Progres"];
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(2)),
            const CatalogScreen(role: 'student'),
            CoursesScreen(role: userRole),
            ProgressScreen(role: 'student', currentUserId: currentUser!.uid),
            const Center(
              child: Text(
                "Profilul Elevului",
                style: TextStyle(
                  color: primaryIndigo,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        }

        return Scaffold(
          backgroundColor: primaryIndigo,
          appBar: AppBar(
            backgroundColor: primaryIndigo,
            toolbarHeight: 75,
            titleSpacing: 12,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'images/logo.jpg',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
            actions: [
              if (currentUser != null)
                StreamBuilder<int>(
                  stream: (() async* {
                    if (userRole == 'teacher') {
                      await for (var _
                          in FirebaseFirestore.instance
                              .collection('users')
                              .snapshots()) {
                        var pendingUsers = await FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'student')
                            .where('hasAccess', isEqualTo: false)
                            .get();

                        var pendingEnrollments = await FirebaseFirestore
                            .instance
                            .collection('enrollments')
                            .where('status', isEqualTo: 'pending')
                            .get();

                        yield pendingUsers.docs.length +
                            pendingEnrollments.docs.length;
                      }
                    } else {
                      await for (var snapshot
                          in FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', isEqualTo: currentUser.uid)
                              .where('isRead', isEqualTo: false)
                              .snapshots()) {
                        int unreadCount = snapshot.docs.length;

                        if (!kIsWeb) {
                          try {
                            if (unreadCount > 0) {
                              FlutterAppBadger.updateBadgeCount(unreadCount);
                            } else {
                              FlutterAppBadger.removeBadge();
                            }
                          } catch (e) {
                            debugPrint("Eroare actualizare badge: $e");
                          }
                        }

                        yield unreadCount;
                      }
                    }
                  })(),
                  builder: (context, notifSnap) {
                    int unreadCount = notifSnap.data ?? 0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 26,
                          ),
                          tooltip: "Notificări",
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NotificationsScreen(role: userRole),
                              ),
                            );
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unreadCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(width: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = MediaQuery.of(context).size.width;

                  if (screenWidth > 600) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (int i = 0; i < menuTitles.length; i++)
                            TextButton(
                              onPressed: () => _changeTab(i),
                              child: Text(
                                menuTitles[i],
                                style: TextStyle(
                                  color: _currentIndex == i
                                      ? Colors.amber
                                      : Colors.white,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: "Deconectare",
                            onPressed: _handleLogout,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          color: const Color(0xff42153e),
                          onSelected: (index) {
                            if (index == 4) {
                              _handleLogout();
                            } else {
                              _changeTab(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Text(
                                menuTitles[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 1,
                              child: Text(
                                menuTitles[1],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: Text(
                                menuTitles[2],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Text(
                                menuTitles[3],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 4,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Deconectare",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          body: pages[_currentIndex < pages.length ? _currentIndex : 0],
        );
      },
    );
  }
}

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 800;

                      if (isMobile) {
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
                              isRow: false,
                            ),
                            _buildFeatureCard(
                              Icons.groups,
                              "Corp Didactic",
                              "Mentori cu experiență",
                              constraints.maxWidth,
                              accentLila,
                              isRow: false,
                            ),
                            _buildFeatureCard(
                              Icons.sports_esports,
                              "Gamification",
                              "Învățare prin joc",
                              constraints.maxWidth,
                              accentLila,
                              isRow: false,
                            ),
                            _buildFeatureCard(
                              Icons.verified,
                              "Valori & Integritate",
                              "Dezvoltare personală",
                              constraints.maxWidth,
                              accentLila,
                              isRow: false,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.school,
                                "Excelență Academică",
                                "Materiale structurate",
                                constraints.maxWidth,
                                accentLila,
                                isRow: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.groups,
                                "Corp Didactic",
                                "Mentori cu experiență",
                                constraints.maxWidth,
                                accentLila,
                                isRow: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.sports_esports,
                                "Gamification",
                                "Învățare prin joc",
                                constraints.maxWidth,
                                accentLila,
                                isRow: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.verified,
                                "Valori & Integritate",
                                "Dezvoltare personală",
                                constraints.maxWidth,
                                accentLila,
                                isRow: true,
                              ),
                            ),
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

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "ÎNVĂȚARE EFICIENTĂ • REZULTATE GARANTATE",
            style: TextStyle(
              color: Color(0xff42153e),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Every problem,\nhas a solution.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "La Level Up, ajutăm fiecare elev și părinte să țină pasul cu performanța.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onGoToCourses,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: const Color(0xff42153e),
          ),
          child: const Text(
            "VEZI CURSURILE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff42153e).withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "De ce Level Up?",
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "• Monitorizare note în timp real\n• Conexiune părinte-elev\n• Notificări instant",
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String desc,
    double maxWidth,
    Color accentLila, {
    required bool isRow,
  }) {
    double? cardWidth = isRow
        ? null
        : (maxWidth > 600 ? (maxWidth - 36) / 4 : (maxWidth - 12) / 2);

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff42153e).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff42153e), size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xff42153e),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xff42153e).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xff42153e)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xff42153e),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
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
