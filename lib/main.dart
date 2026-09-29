import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'notifications_screen.dart';
import 'courses_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

// --- FUNCȚII GLOBALE PENTRU NOTIFICĂRI ---

Future<void> clearAppBadge() async {
  // Pe Web sau alte platforme non-mobile nu există badge-uri native
  if (kIsWeb) return;

  try {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      FlutterAppBadger.removeBadge(); // Șterge bulina roșie de pe logo
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
  runApp(const LevelUpApp());
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Level Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfffff8dc),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xff42153e)),
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

  @override
  void initState() {
    super.initState();
    setupFCM();
    clearAppBadge();
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

        final List<Widget> pages = [
          HomeTab(onGoToCourses: () => _changeTab(1)),
          CoursesScreen(role: userRole),
          const Center(
            child: Text(
              "Sistemul de Chat va fi activat în curând.",
              style: TextStyle(color: Color(0xff42153e)),
            ),
          ),
          const Center(
            child: Text(
              "Profilul Tău",
              style: TextStyle(color: Color(0xff42153e)),
            ),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xfffff8dc),
          appBar: AppBar(
            backgroundColor: const Color(0xff42153e),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [],
                  ),
                ),
              ],
            ),
            actions: [
              // BUTON UNIVERSAL DE NOTIFICĂRI ADAPTAT DUPĂ ROL
              if (currentUser != null)
                StreamBuilder<int>(
                  stream: (() async* {
                    if (userRole == 'teacher') {
                      // Ascultăm modificările din colecția users pentru a actualiza instant
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
                      // Pentru elevi/părinți, păstrăm notificările obișnuite
                      await for (var snapshot
                          in FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', isEqualTo: currentUser.uid)
                              .where('isRead', isEqualTo: false)
                              .snapshots()) {
                        yield snapshot.docs.length;
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
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NotificationsScreen(role: userRole),
                              ),
                            );

                            if (result == 'open_approval_center' && mounted) {
                              _changeTab(1);
                            }
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

              // Meniul existent...
              LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = MediaQuery.of(context).size.width;

                  if (screenWidth > 600) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _changeTab(0),
                          child: Text(
                            "Home",
                            style: TextStyle(
                              color: _currentIndex == 0
                                  ? Colors.amber
                                  : Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _changeTab(1),
                          child: Text(
                            "Cursuri",
                            style: TextStyle(
                              color: _currentIndex == 1
                                  ? Colors.amber
                                  : Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _changeTab(2),
                          child: Text(
                            "Chat",
                            style: TextStyle(
                              color: _currentIndex == 2
                                  ? Colors.amber
                                  : Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _changeTab(3),
                          child: Text(
                            "Profil",
                            style: TextStyle(
                              color: _currentIndex == 3
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
                            const PopupMenuItem(
                              value: 0,
                              child: Text(
                                "Home",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 1,
                              child: Text(
                                "Cursuri",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 2,
                              child: Text(
                                "Chat",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 3,
                              child: Text(
                                "Profil",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 4,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
          body: pages[_currentIndex],
        );
      },
    );
  }
}

// ================= ECRANUL HOME =================
class HomeTab extends StatelessWidget {
  final VoidCallback onGoToCourses;

  const HomeTab({super.key, required this.onGoToCourses});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Utilizator neconectat."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff42153e)),
          );
        }

        String fullName = "Utilizator";
        String role = "student";
        bool hasAccess = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          fullName = userData['fullName'] ?? "Utilizator";
          role = userData['role'] ?? "student";
          hasAccess = userData['hasAccess'] ?? false;
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/spatiu.jpeg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                child: Container(
                  color: const Color(0xff42153e).withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 750;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildHeroText(context)),
                                const SizedBox(width: 24),
                                SizedBox(width: 320, child: _buildHeroCard()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroText(context),
                                const SizedBox(height: 24),
                                _buildHeroCard(),
                              ],
                            );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (!hasAccess)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Contul tău ($fullName - $role) este în așteptarea aprobării de la profesor.",
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFeatureCard(
                          Icons.school,
                          "Excelență Academică",
                          "Materiale structurate de top",
                          constraints.maxWidth,
                        ),
                        _buildFeatureCard(
                          Icons.groups,
                          "Corp Didactic",
                          "Mentori cu experiență",
                          constraints.maxWidth,
                        ),
                        _buildFeatureCard(
                          Icons.sports_esports,
                          "Gamification",
                          "Învățare prin joc și XP",
                          constraints.maxWidth,
                        ),
                        _buildFeatureCard(
                          Icons.verified,
                          "Valori & Integritate",
                          "Dezvoltare personală",
                          constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Niveluri de Studiu",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Pregătire Adaptată Fiecărui Elev",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff42153e),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        return isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCategoryCard(
                                    "Gimnaziu",
                                    "Clasele V - VIII",
                                    Icons.child_care,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCategoryCard(
                                    "Liceu",
                                    "Clasele IX - XII",
                                    Icons.menu_book,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCategoryCard(
                                    "Evaluarea Națională/Bacalaureat",
                                    "Simulări & Teste",
                                    Icons.assignment,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildCategoryCard(
                                      "Gimnaziu",
                                      "Clasele V - VIII",
                                      Icons.child_care,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCategoryCard(
                                      "Liceu",
                                      "Clasele IX - XII",
                                      Icons.menu_book,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCategoryCard(
                                      "Bacalaureat",
                                      "Simulări & Teste",
                                      Icons.assignment,
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                color: const Color(0xff42153e),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
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

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            bool isMobile = constraints.maxWidth < 600;
                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: _buildCounterItem(
                                          "$studentCount",
                                          "Elevi",
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCounterItem(
                                          "$teacherCount",
                                          "Profesori",
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: _buildCounterItem(
                                          "$coursesCount",
                                          "Cursuri",
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCounterItem(
                                          "24/7",
                                          "Suport",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCounterItem(
                                  "$studentCount",
                                  "Elevi Înregistrați",
                                ),
                                _buildCounterItem(
                                  "$teacherCount",
                                  "Profesori Activi",
                                ),
                                _buildCounterItem(
                                  "$coursesCount",
                                  "Cursuri Disponibile",
                                ),
                                _buildCounterItem("24/7", "Suport Platformă"),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              Container(
                color: const Color(0xff2b0c28),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Platformă educațională modernă destinată pregătirii de performanță pentru elevi și profesori.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 500;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "©Aplicație dezvoltată de Diana Cioroiu. 2026 Level Up App. Toate drepturile rezervate.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "© 2026 Level Up App. Toate drepturile rezervate.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.facebook,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
              letterSpacing: 1.1,
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
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black45,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "La Level Up, ajutăm fiecare elev să își atingă potențialul maxim prin cursuri interactive, profesori dedicați și suport continuu.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onGoToCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: const Color(0xff42153e),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "VEZI CURSURILE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
          ],
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
        children: [
          const Text(
            "De ce Level Up?",
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildHeroFeatureRow(
            Icons.school_outlined,
            "Programă Bacalaureat & Evaluare",
          ),
          const SizedBox(height: 8),
          _buildHeroFeatureRow(
            Icons.person_outline,
            "Profesori Experți și Mentori",
          ),
          const SizedBox(height: 8),
          _buildHeroFeatureRow(
            Icons.quiz_outlined,
            "Teste & Exerciții Interactive",
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeatureRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
  ) {
    double cardWidth = maxWidth > 600
        ? (maxWidth - 36) / 4
        : (maxWidth - 12) / 2;
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

  Widget _buildCounterItem(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
