import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lottie/lottie.dart';

import 'catalog_screen.dart';
import 'course_detail_screen.dart';
import 'lesson_detail_page.dart';

class NotificationsScreen extends StatefulWidget {
  final String role;

  const NotificationsScreen({super.key, required this.role});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryIndigo = Color(0xff1e1b4b);
  static const Color accentPurple = Color(0xff7c3aed);
  static const Color bgColor = Color(0xfff8fafc);

  @override
  void initState() {
    super.initState();
    _updateBadgeForUser();
  }

  // Funcție ajutătoare care alege animația Lottie în funcție de tipul notificării
  Widget _getAnimationForType(String type, bool isRead) {
    String assetPath = 'images/animations/homework.json';

    if (type == 'user_registration') {
      assetPath = 'images/animations/enrollment.json';
    } else if (type == 'enrollment') {
      assetPath = 'images/animations/user_reg.json';
    }

    return SizedBox(
      width: 42,
      height: 42,
      child: Opacity(
        opacity: isRead ? 0.5 : 1.0,
        child: Lottie.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.notifications_active,
              color: isRead ? Colors.grey : primaryIndigo,
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateBadgeForUser() async {
    if (kIsWeb || currentUser == null) return;
    try {
      var pendingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('hasAccess', isEqualTo: false)
          .get();

      var pendingEnrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();

      int totalPending =
          pendingUsers.docs.length + pendingEnrollments.docs.length;

      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (totalPending > 0) {
          FlutterAppBadger.updateBadgeCount(totalPending);
        } else {
          FlutterAppBadger.removeBadge();
        }
      }
    } catch (e) {
      debugPrint("Eroare la actualizarea badge-ului: $e");
    }
  }

  Future<void> _confirmAndDeleteUser(String userId, String userName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere "$userName"'),
        content: Text(
          'Ești sigur că vrei să ștergi contul utilizatorului $userName? '
          'Toate înscrierile și notificările acestuia vor fi eliminate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Șterge Definitiv',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        var enrollments = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('userId', isEqualTo: userId)
            .get();
        for (var doc in enrollments.docs) {
          await doc.reference.delete();
        }

        var notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        for (var doc in notifications.docs) {
          await doc.reference.delete();
        }

        await _updateBadgeForUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Contul "$userName" a fost șters.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la ștergerea utilizatorului: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleStudentNotificationClick(
    DocumentSnapshot notifDoc,
  ) async {
    var data = notifDoc.data() as Map<String, dynamic>;
    String notifId = notifDoc.id;

    String courseId = data['courseId'] ?? '';
    String lessonId = data['lessonId'] ?? '';
    String notifType = data['type'] ?? 'lesson';
    String notifTitle = data['title'] ?? 'Detalii';

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});

    _updateBadgeForUser();

    if (!mounted) return;

    if (notifType == 'grade') {
      if (widget.role == 'parent') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: CatalogScreen(role: 'parent')),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: CatalogScreen(role: 'student')),
          ),
        );
      }
    } else if (courseId.isNotEmpty && lessonId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailPage(
            courseId: courseId,
            lessonId: lessonId,
            lessonTitle: notifTitle,
            initialTab: notifType,
            role: widget.role,
          ),
        ),
      );
    } else if (courseId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            courseId: courseId,
            title: notifTitle,
            category: 'General',
            description: '',
            role: widget.role,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    // ==========================================
    // 1. DACĂ ESTE PROFESOR -> Panou de Administrare cu noul design
    // ==========================================
    if (widget.role == 'teacher') {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: primaryIndigo,
            toolbarHeight: 85,
            titleSpacing: 16,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'images/logo.jpg',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "PANOU ADMIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      "GESTIONARE UTILIZATORI",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottom: const TabBar(
              labelColor: accentPurple,
              unselectedLabelColor: Colors.white70,
              indicatorColor: accentPurple,
              tabs: [
                Tab(
                  icon: Icon(Icons.person_add, size: 20),
                  text: "Conturi Noi",
                ),
                Tab(icon: Icon(Icons.school, size: 20), text: "Înscrieri"),
                Tab(
                  icon: Icon(Icons.group_remove, size: 20),
                  text: "Gestionare Useri",
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // TAB 1: CONTURI NOI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .where('hasAccess', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentPurple),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nu există conturi noi în așteptare.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  var unapprovedUsers = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: unapprovedUsers.length,
                    itemBuilder: (context, index) {
                      var uDoc = unapprovedUsers[index];
                      var uData = uDoc.data() as Map<String, dynamic>;
                      String uId = uDoc.id;
                      String name =
                          uData['fullName'] ?? uData['name'] ?? 'Elev';
                      String email = uData['email'] ?? '';

                      return Card(
                        elevation: 1,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryIndigo,
                            ),
                          ),
                          subtitle: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                ),
                                tooltip: 'Aprobă Accesul',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uId)
                                      .update({'hasAccess': true});
                                  _updateBadgeForUser();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                tooltip: 'Respinge Contul',
                                onPressed: () =>
                                    _confirmAndDeleteUser(uId, name),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // TAB 2: ÎNSCRIERI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentPurple),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nu există solicitări de curs în așteptare.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  var requests = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var reqDoc = requests[index];
                      var reqData = reqDoc.data() as Map<String, dynamic>;
                      String reqId = reqDoc.id;
                      String studentId = reqData['userId'];
                      String courseId = reqData['courseId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(studentId)
                            .get(),
                        builder: (context, userSnap) {
                          String studentName =
                              userSnap.data?['fullName'] ?? 'Elev';
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('courses')
                                .doc(courseId)
                                .get(),
                            builder: (context, courseSnap) {
                              String courseTitle =
                                  courseSnap.data?['title'] ?? 'Curs';
                              return Card(
                                elevation: 1,
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  title: Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryIndigo,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Solicită înscriere la: $courseTitle',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('enrollments')
                                              .doc(reqId)
                                              .update({'status': 'approved'});
                                          _updateBadgeForUser();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 28,
                                        ),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('enrollments')
                                              .doc(reqId)
                                              .delete();
                                          _updateBadgeForUser();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),

              // TAB 3: GESTIONARE USERI
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      cursorColor: accentPurple,
                      decoration: InputDecoration(
                        hintText: 'Caută după nume sau email...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: primaryIndigo,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: accentPurple,
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: accentPurple,
                              ),
                            );
                          }

                          String query = _searchController.text
                              .toLowerCase()
                              .trim();
                          var users = snapshot.data!.docs.where((doc) {
                            var uData = doc.data() as Map<String, dynamic>;
                            String name = (uData['fullName'] ?? '')
                                .toString()
                                .toLowerCase();
                            String email = (uData['email'] ?? '')
                                .toString()
                                .toLowerCase();
                            if (doc.id == currentUser?.uid) return false;
                            return name.contains(query) ||
                                email.contains(query);
                          }).toList();

                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var uDoc = users[index];
                              var uData = uDoc.data() as Map<String, dynamic>;
                              String name = uData['fullName'] ?? 'Utilizator';
                              String email = uData['email'] ?? '';
                              bool hasAccess = uData['hasAccess'] ?? false;

                              return Card(
                                elevation: 1,
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryIndigo,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$email • ${hasAccess ? 'Activ' : 'Neaprobat'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmAndDeleteUser(uDoc.id, name),
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
            ],
          ),
        ),
      );
    }

    // ==========================================
    // 2. DACĂ ESTE ELEV/PĂRINTE -> Notificări personale cu noul design
    // ==========================================
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryIndigo,
        toolbarHeight: 85,
        titleSpacing: 16,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'images/logo.jpg',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "NOTIFICĂRI",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "ACTIVITATE RECENTĂ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentPurple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nu ai nicio notificare în prezent.",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          var notifs = snapshot.data!.docs.toList();
          notifs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? tA = dataA['createdAt'] as Timestamp?;
            Timestamp? tB = dataB['createdAt'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              var doc = notifs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool isRead = data['isRead'] ?? false;
              String title = data['title'] ?? 'Notificare';
              String body = data['body'] ?? '';
              String type = data['type'] ?? 'homework';

              return Card(
                elevation: isRead ? 1 : 2,
                color: isRead ? Colors.white : const Color(0xfff3e8ff),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isRead
                      ? BorderSide(color: Colors.grey.shade200)
                      : const BorderSide(color: accentPurple, width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: _getAnimationForType(type, isRead),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: primaryIndigo,
                    ),
                  ),
                  subtitle: Text(
                    body,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  trailing: !isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: accentPurple,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () => _handleStudentNotificationClick(doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
