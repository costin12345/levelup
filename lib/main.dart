import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart'; // Generat de FlutterFire CLI (sau configurat local)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Level Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff42153e),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  // Configurarea Push Notifications prin FCM API v1
  Future<void> _setupFCM() async {
    // Pe Web nu se înregistrează Service Worker pentru receptor, prevenind erorile
    if (kIsWeb) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();

        if (token != null && token.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          debugPrint('FCM Token salvat: $token');
        }
      }
    } catch (e) {
      debugPrint('Eroare FCM: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listă ecrane demo
    final List<Widget> pages = [
      const Center(child: Text("Pagina Principala / Cursuri")),
      const Center(child: Text("Notificări")),
      const Center(child: Text("Profil Utilizator")),
      const Center(child: Text("Setări")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Level Up"),
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xff42153e),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.book,
              color: _currentIndex == 0
                  ? const Color(0xff42153e)
                  : Colors.grey,
            ),
            label: 'Cursuri',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
              color: _currentIndex == 1
                  ? const Color(0xff42153e)
                  : Colors.grey,
            ),
            label: 'Notificări',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _currentIndex == 2
                  ? const Color(0xff42153e)
                  : Colors.grey,
            ),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
              color: _currentIndex == 3
                  ? const Color(0xff42153e)
                  : Colors.grey,
            ),
            label: 'Setări',
          ),
        ],
      ),
    );
  }
}