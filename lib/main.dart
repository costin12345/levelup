import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  // 🌟 Înregistrăm handler-ul pentru notificări în fundal
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MainScreen());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Mesaj primit în fundal: ${message.messageId}");
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

//
// class _MainNavigationScreenState extends State<MainNavigationScreen> {
//   int _currentIndex = 0;
//   @override
//   void initState() {
//     super.initState();
//     _saveFcmTokenForCurrentUser(); // 🌟 Aici salvăm token-ul la pornirea ecranului principal
//   }
//
//   PopupMenuItem<int> _buildPopupItem(int index, String title, IconData icon) {
//     bool isSelected = _currentIndex == index;
//     return PopupMenuItem<int>(
//       value: index,
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: isSelected ? const Color(0xffffd700) : Colors.white70,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             title,
//             style: TextStyle(
//               color: isSelected ? const Color(0xffffd700) : Colors.white,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const Color primaryIndigo = Color(0xff1e1b4b);
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUser?.uid ?? 'dummy_user')
//           .snapshots(),
//       builder: (context, userSnapshot) {
//         String userRole = 'teacher';
//         if (userSnapshot.hasData && userSnapshot.data!.exists) {
//           var data = userSnapshot.data!.data() as Map<String, dynamic>?;
//           userRole = data?['role'] ?? 'teacher';
//         }
//
//         bool isTeacher = userRole == 'teacher';
//         bool isParent = userRole == 'parent';
//
//         // Listă de ecrane în funcție de rol
//         final List<Widget> screens = isTeacher
//             ? [
//                 HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
//                 const TeacherCatalogScreen(),
//                 CoursesScreen(role: userRole),
//                 MaterialsScreen(role: userRole),
//                 const ProfileTab(),
//               ]
//             : isParent
//             ? [
//                 HomeTab(onGoToCourses: () => setState(() => _currentIndex = 1)),
//                 CatalogScreen(role: userRole),
//                 const ProgressScreen(),
//                 const ProfileTab(),
//               ]
//             : [
//                 HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
//                 CatalogScreen(role: userRole),
//                 CoursesScreen(role: userRole),
//                 MaterialsScreen(role: userRole),
//                 const ProgressScreen(),
//                 const ProfileTab(),
//               ];
//
//         // Titlurile și iconițele pentru meniul lateral (Drawer) pe telefon
//         final List<Map<String, dynamic>> menuItems = isTeacher
//             ? [
//                 {'title': 'Home', 'icon': Icons.home},
//                 {'title': 'Catalog', 'icon': Icons.star},
//                 {'title': 'Cursuri', 'icon': Icons.book},
//                 {'title': 'Materiale', 'icon': Icons.folder},
//                 {'title': 'Profil', 'icon': Icons.person},
//               ]
//             : isParent
//             ? [
//                 {'title': 'Home', 'icon': Icons.home},
//                 {'title': 'Catalog', 'icon': Icons.star},
//                 {'title': 'Progres', 'icon': Icons.trending_up},
//                 {'title': 'Profil', 'icon': Icons.person},
//               ]
//             : [
//                 {'title': 'Home', 'icon': Icons.home},
//                 {'title': 'Catalog', 'icon': Icons.star},
//                 {'title': 'Cursuri', 'icon': Icons.book},
//                 {'title': 'Materiale', 'icon': Icons.folder},
//                 {'title': 'Progres', 'icon': Icons.trending_up},
//                 {'title': 'Profil', 'icon': Icons.person},
//               ];
//
//         // Verificăm dacă ecranul este îngust (telefon)
//         bool isMobile = MediaQuery.of(context).size.width < 850;
//
//         return Scaffold(
//           backgroundColor: const Color(0xfff8fafc),
//           // 🌟 Meniul lateral (Drawer) apare automat pe telefon când se apasă pe iconița cu 3 linii
//           drawer: isMobile
//               ? Drawer(
//                   backgroundColor: Colors.white,
//                   child: ListView(
//                     padding: EdgeInsets.zero,
//                     children: [
//                       DrawerHeader(
//                         decoration: const BoxDecoration(color: primaryIndigo),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             const Icon(
//                               Icons.school,
//                               color: Colors.white,
//                               size: 36,
//                             ),
//                             const SizedBox(height: 10),
//                             const Text(
//                               "LEVEL UP",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               "Rol: ${userRole.toUpperCase()}",
//                               style: const TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       ...menuItems.asMap().entries.map((entry) {
//                         int index = entry.key;
//                         var item = entry.value;
//                         bool isSelected = _currentIndex == index;
//
//                         return ListTile(
//                           leading: Icon(
//                             item['icon'],
//                             color: isSelected
//                                 ? const Color(0xff7c4dff)
//                                 : Colors.grey.shade700,
//                           ),
//                           title: Text(
//                             item['title'],
//                             style: TextStyle(
//                               color: isSelected
//                                   ? const Color(0xff7c4dff)
//                                   : primaryIndigo,
//                               fontWeight: isSelected
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                           selected: isSelected,
//                           onTap: () {
//                             setState(() => _currentIndex = index);
//                             Navigator.pop(
//                               context,
//                             ); // Închide drawer-ul după selecție
//                           },
//                         );
//                       }),
//                       const Divider(),
//                       ListTile(
//                         leading: const Icon(Icons.logout, color: Colors.red),
//                         title: const Text(
//                           "Deconectare",
//                           style: TextStyle(color: Colors.red),
//                         ),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await FirebaseAuth.instance.signOut();
//                         },
//                       ),
//                     ],
//                   ),
//                 )
//               : null,
//           appBar: AppBar(
//             backgroundColor: primaryIndigo,
//             elevation: 0,
//             toolbarHeight: 70,
//             titleSpacing: 24,
//             title: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(
//                     Icons.school,
//                     color: primaryIndigo,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   "LEVEL UP",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                     fontSize: 18,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               // 1. Clopoțelul de notificări
//               IconButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => NotificationsScreen(role: userRole),
//                     ),
//                   );
//                 },
//                 icon: const Icon(
//                   Icons.notifications_outlined,
//                   color: Colors.white,
//                 ),
//                 tooltip: "Notificări",
//               ),
//               const SizedBox(width: 8),
//
//               // 2. Meniul cu 3 linii (Hamburger) poziționat în dreapta, cu fundal închis
//               PopupMenuButton<int>(
//                 icon: const Icon(
//                   Icons.menu,
//                   color: Colors.white,
//                   size: 28,
//                 ), // Cele 3 linii
//                 color: const Color(
//                   0xff0f172a,
//                 ), // Negru închis / Albastru foarte închis elegant
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 onSelected: (index) {
//                   setState(() => _currentIndex = index);
//                 },
//                 itemBuilder: (context) {
//                   // Generăm opțiunile în funcție de rol
//                   if (isParent) {
//                     return [
//                       _buildPopupItem(0, "Home", Icons.home),
//                       _buildPopupItem(1, "Catalog", Icons.star),
//                       _buildPopupItem(2, "Progres", Icons.trending_up),
//                       _buildPopupItem(3, "Profil", Icons.person),
//                     ];
//                   } else if (isTeacher) {
//                     return [
//                       _buildPopupItem(0, "Home", Icons.home),
//                       _buildPopupItem(1, "Catalog", Icons.star),
//                       _buildPopupItem(2, "Cursuri", Icons.book),
//                       _buildPopupItem(3, "Materiale", Icons.folder),
//                       _buildPopupItem(4, "Profil", Icons.person),
//                     ];
//                   } else {
//                     return [
//                       _buildPopupItem(0, "Home", Icons.home),
//                       _buildPopupItem(1, "Catalog", Icons.star),
//                       _buildPopupItem(2, "Cursuri", Icons.book),
//                       _buildPopupItem(3, "Materiale", Icons.folder),
//                       _buildPopupItem(4, "Progres", Icons.trending_up),
//                       _buildPopupItem(5, "Profil", Icons.person),
//                     ];
//                   }
//                 },
//               ),
//
//               const SizedBox(width: 8),
//
//               // 3. Butonul de deconectare
//               IconButton(
//                 onPressed: () async {
//                   await FirebaseAuth.instance.signOut();
//                 },
//                 icon: const Icon(Icons.logout, color: Colors.white70),
//                 tooltip: "Deconectare",
//               ),
//               const SizedBox(width: 16),
//             ],
//           ),
//           body: screens[_currentIndex],
//         );
//       },
//     );
//   }
//
//   Widget _buildTopNavButton(String title, int index) {
//     bool isSelected = _currentIndex == index;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//       child: TextButton(
//         onPressed: () => setState(() => _currentIndex = index),
//         style: TextButton.styleFrom(
//           foregroundColor: isSelected ? const Color(0xffffd700) : Colors.white,
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             color: isSelected ? const Color(0xffffd700) : Colors.white,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _saveFcmTokenForCurrentUser() async {
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
//
//       String? token;
//
//       if (kIsWeb) {
//         // Pe Web, pentru a evita eroarea, sărim generarea token-ului FCM de pe client
//         // sau o rulăm doar dacă ai nevoie neapărat de Web push (necesită VAPID key din Firebase Console).
//         debugPrint("Rulează pe Web - omitere obținere token FCM nativ.");
//         return;
//       } else {
//         // Pe Telefon (Android / iOS)
//         NotificationSettings settings = await FirebaseMessaging.instance
//             .requestPermission(alert: true, badge: true, sound: true);
//
//         if (settings.authorizationStatus == AuthorizationStatus.authorized ||
//             settings.authorizationStatus == AuthorizationStatus.provisional) {
//           token = await FirebaseMessaging.instance.getToken();
//         }
//       }
//
//       if (token != null && token.isNotEmpty) {
//         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//           'fcmToken': token,
//         }, SetOptions(merge: true));
//
//         debugPrint("SUCCES: Token FCM salvat -> $token");
//       }
//     } catch (e) {
//       debugPrint("Eroare la obținerea/salvarea token-ului FCM: $e");
//     }
//   }
// }
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

        // Listă ecrane
        final List<Widget> screens = isTeacher
            ? [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
                const TeacherCatalogScreen(),
                CoursesScreen(role: userRole),
                MaterialsScreen(role: userRole),
                const ProfileTab(),
              ]
            : isParent
            ? [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 1)),
                CatalogScreen(role: userRole),
                const ProgressScreen(),
                const ProfileTab(),
              ]
            : [
                HomeTab(onGoToCourses: () => setState(() => _currentIndex = 2)),
                CatalogScreen(role: userRole),
                CoursesScreen(role: userRole),
                MaterialsScreen(role: userRole),
                const ProgressScreen(),
                const ProfileTab(),
              ];

        // Opțiunile pentru meniul lateral (inclusiv Deconectare la final)
        final List<Map<String, dynamic>> menuItems = isTeacher
            ? [
                {'title': 'Home', 'icon': Icons.home},
                {'title': 'Catalog', 'icon': Icons.star},
                {'title': 'Cursuri', 'icon': Icons.book},
                {'title': 'Materiale', 'icon': Icons.folder},
                {'title': 'Profil', 'icon': Icons.person},
              ]
            : isParent
            ? [
                {'title': 'Home', 'icon': Icons.home},
                {'title': 'Catalog', 'icon': Icons.star},
                {'title': 'Progres', 'icon': Icons.trending_up},
                {'title': 'Profil', 'icon': Icons.person},
              ]
            : [
                {'title': 'Home', 'icon': Icons.home},
                {'title': 'Catalog', 'icon': Icons.star},
                {'title': 'Cursuri', 'icon': Icons.book},
                {'title': 'Materiale', 'icon': Icons.folder},
                {'title': 'Progres', 'icon': Icons.trending_up},
                {'title': 'Profil', 'icon': Icons.person},
              ];

        return Scaffold(
          backgroundColor: const Color(0xfff8fafc),
          // Meniul lateral cu fundal negru închis / indigo foarte închis
          drawer: Drawer(
            backgroundColor: const Color(0xff0f172a), // Negru închis elegant
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: primaryIndigo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.school, color: Colors.white, size: 36),
                      const SizedBox(height: 10),
                      const Text(
                        "LEVEL UP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rol: ${userRole.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ...menuItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  bool isSelected = _currentIndex == index;

                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color: isSelected
                          ? const Color(0xffffd700)
                          : Colors.white70,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xffffd700)
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() => _currentIndex = index);
                      Navigator.pop(context); // Închide drawer-ul
                    },
                  );
                }),
                const Divider(color: Colors.white24),
                // 🌟 Butonul de Deconectare mutat pe ultimul rând în meniu
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Deconectare",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: primaryIndigo,
            elevation: 0,
            toolbarHeight: 70,
            titleSpacing: 16,
            // Flutter pune automat iconița cu 3 linii în stânga datorită drawer-ului de mai sus
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
              // Doar clopoțelul de notificări rămâne în dreapta sus
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
              const SizedBox(width: 16),
            ],
          ),
          body: screens[_currentIndex],
        );
      },
    );
  }
}
