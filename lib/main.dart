import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:levelup/progress_screen.dart';

import 'catalog_screen.dart';
import 'notifications_screen.dart';
import 'courses_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'add_grade_dialog.dart';

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

        List<Widget> pages = [];
        List<String> menuTitles = ["Home", "Catalog", "", "Profil"];

        if (userRole == 'teacher') {
          menuTitles[2] = "Cursuri";
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(2)),
            const TeacherCatalogScreen(), // Ecranul profesorului
            CoursesScreen(role: userRole),
            const Center(
              child: Text(
                "Profilul Profesorului",
                style: TextStyle(
                  color: Color(0xff42153e),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        } else if (userRole == 'parent') {
          menuTitles[2] = "Copilul Meu";
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(1)),
            const CatalogScreen(role: 'parent'),
            // Aici trimitem corect datele către ProgressScreen pentru părinte
            ProgressScreen(
              role: 'parent',
              currentUserId: currentUser?.uid ?? '',
              childEmail:
                  (userSnapshot.data?.data()
                      as Map<String, dynamic>?)?['childEmail'] ??
                  '',
            ),
            const Center(
              child: Text(
                "Profilul Părintelui",
                style: TextStyle(
                  color: Color(0xff42153e),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        } else {
          // Student / Elev
          menuTitles[2] = "Cursuri";
          pages = [
            HomeTab(onGoToCourses: () => _changeTab(2)),
            const CatalogScreen(
              role: 'student',
            ), // <-- Aici punem catalogul pentru Elev
            CoursesScreen(role: userRole),
            const Center(
              child: Text(
                "Profilul Elevului",
                style: TextStyle(
                  color: Color(0xff42153e),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        }

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

                        // --- ADĂUGĂM ACEST BLOC PENTRU BADGE-UL TELEFONULUI ---
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
                        // ---------------------------------------------------

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
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _changeTab(0),
                          child: Text(
                            menuTitles[0],
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
                            menuTitles[1],
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
                            menuTitles[2],
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
                            menuTitles[3],
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

// ================= ECRAN CATALOG PROFESOR CU FILTRARE AVANSATĂ =================
class TeacherCatalogScreen extends StatefulWidget {
  const TeacherCatalogScreen({super.key});

  @override
  State<TeacherCatalogScreen> createState() => _TeacherCatalogScreenState();
}

class _TeacherCatalogScreenState extends State<TeacherCatalogScreen> {
  String _selectedFilterClass = "Toate";
  String _selectedFilterCourse = "Toate";
  String _selectedFilterGrade = "Toate";
  String _selectedFilterDate = "Toate";
  String? _selectedSingleStudent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff42153e), Color(0xff6a2465)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_stories, color: Colors.amber, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Catalogul Virtual",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Filtrare avansată pe clase, elevi și note",
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddGradeDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xff42153e),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xff42153e),
                      ),
                      label: const Text(
                        "Adaugă Notă",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grades')
                  .snapshots(),
              builder: (context, snapshot) {
                Set<String> classes = {"Toate"};
                Set<String> courses = {
                  "Toate",
                  "Matematică",
                  "Informatică",
                  "Fizică",
                };
                Set<String> gradesSet = {"Toate"};
                Set<String> studentsSet = {"Toți elevii"};
                Set<String> datesSet = {"Toate"};

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['className'] != null)
                      classes.add(data['className']);
                    if (data['grade'] != null) gradesSet.add(data['grade']);
                    if (data['studentName'] != null)
                      studentsSet.add(data['studentName']);
                    if (data['date'] != null)
                      datesSet.add(
                        data['date'],
                      ); // <--- Colectăm datele existente
                  }
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownFilter(
                            "Clasa",
                            _selectedFilterClass,
                            classes,
                            (val) =>
                                setState(() => _selectedFilterClass = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdownFilter(
                            "Elev",
                            _selectedSingleStudent ?? "Toți elevii",
                            studentsSet,
                            (val) => setState(
                              () => _selectedSingleStudent =
                                  val == "Toți elevii" ? null : val,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownFilter(
                            "Materia",
                            _selectedFilterCourse,
                            courses,
                            (val) =>
                                setState(() => _selectedFilterCourse = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdownFilter(
                            "Nota",
                            _selectedFilterGrade,
                            gradesSet,
                            (val) =>
                                setState(() => _selectedFilterGrade = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rând nou dedicat filtrului după Dată pe tot ecranul sau jumătate
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownFilter(
                            "Data",
                            _selectedFilterDate,
                            datesSet,
                            (val) => setState(() => _selectedFilterDate = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grades')
                    .orderBy('createdAt', descending: true)
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_satisfied_alt,
                            size: 64,
                            color: Colors.purple.shade200,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Nicio notă adăugată momentan.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var allDocs = snapshot.data!.docs;

                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String className = data['className'] ?? '';
                    String studentName = data['studentName'] ?? '';
                    String courseTitle = data['courseTitle'] ?? '';
                    String grade = data['grade'] ?? '';

                    bool matchesClass =
                        _selectedFilterClass == "Toate" ||
                        className == _selectedFilterClass;
                    bool matchesStudent =
                        _selectedSingleStudent == null ||
                        studentName == _selectedSingleStudent;
                    bool matchesCourse =
                        _selectedFilterCourse == "Toate" ||
                        courseTitle == _selectedFilterCourse;
                    bool matchesGrade =
                        _selectedFilterGrade == "Toate" ||
                        grade == _selectedFilterGrade;

                    return matchesClass &&
                        matchesStudent &&
                        matchesCourse &&
                        matchesGrade;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nu s-au găsit note pentru filtrele selectate.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      String studentName = data['studentName'] ?? 'Elev';
                      String className = data['className'] ?? 'Fără clasă';
                      String course = data['courseTitle'] ?? 'Materie';
                      String grade = data['grade'] ?? '';
                      String date = data['date'] ?? 'Azi';
                      String comment = data['comment'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff42153e).withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xff42153e)
                                .withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xff42153e),
                            ),
                          ),
                          title: Text(
                            "$studentName • $course",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff42153e),
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Clasa: $className",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "Comentariu: $comment",
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Data: $date",
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              grade,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff42153e),
                                fontSize: 18,
                              ),
                            ),
                          ),
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

  Widget _buildDropdownFilter(
    String label,
    String currentValue,
    Set<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xff42153e)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                "$label: $item",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff42153e),
                  fontWeight: FontWeight.w600,
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

// ================= ECRANUL HOME COMPLET =================
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
                height: 550,
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
              if (!hasAccess && role != 'parent')
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
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Contul tău ($fullName - $role) este în așteptarea aprobării.",
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
                          "Materiale structurate",
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
                          "Învățare prin joc",
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
                      "Pregătire Adaptată",
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
                                    "Bacalaureat",
                                    "Simulări & Teste",
                                    Icons.assignment,
                                  ),
                                ],
                              )
                            : Row(
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

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCounterItem("$studentCount", "Utilizatori"),
                            _buildCounterItem("$teacherCount", "Profesori"),
                            _buildCounterItem("$coursesCount", "Cursuri"),
                            _buildCounterItem("24/7", "Suport"),
                          ],
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
    return Transform.translate(
      offset: const Offset(
        0,
        -190,
      ), // <--- Modifică valoarea -30 ca să o urci sau să o cobori
      child: Container(
        height: 125,
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
            SizedBox(height: 2),
            Text(
              "• Monitorizare note în timp real\n• Conexiune părinte-elev\n• Notificări instant",
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
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
