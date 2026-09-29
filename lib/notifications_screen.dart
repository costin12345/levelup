import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  Future<void> _updateBadgeForUser() async {
    if (kIsWeb || currentUser == null) return;
    try {
      // Numărăm strict doar înscrierile/cererile care sunt în așteptare
      QuerySnapshot pendingEnrollmentsSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();

      int unreadCount = pendingEnrollmentsSnap.docs.length;

      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (unreadCount > 0) {
          FlutterAppBadger.updateBadgeCount(unreadCount);
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

        _updateBadgeForUser();

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

  // 🚀 Clic pe notificare: deschide direct pagina dedicată a lecției pe tab-ul corespunzător
  Future<void> _handleStudentNotificationClick(
    DocumentSnapshot notifDoc,
  ) async {
    var data = notifDoc.data() as Map<String, dynamic>;
    String notifId = notifDoc.id;

    String courseId = data['courseId'] ?? '';
    String lessonId = data['lessonId'] ?? '';
    String notifType = data['type'] ?? 'lesson'; // 'lesson' sau 'homework'
    String notifTitle = data['title'] ?? 'Detalii Lecție';

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});

    _updateBadgeForUser();

    if (!mounted) return;

    if (courseId.isNotEmpty && lessonId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonDetailPage(
            courseId: courseId,
            lessonId: lessonId,
            lessonTitle: notifTitle,
            initialTab:
                notifType, // va selecta automat Tab-ul 'homework' sau 'lesson'
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
        body: Center(child: Text("Utilizator neconectat.")),
      );
    }

    if (widget.role == 'teacher') {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xfffff8dc),
          appBar: AppBar(
            title: const Text(
              "Panou Administrare",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xff42153e),
            foregroundColor: Colors.white,
            bottom: const TabBar(
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.amber,
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
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
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
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xff42153e),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            email,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                tooltip: 'Aprobă Accesul',
                                onPressed: () async {
                                  // 1. Aprobăm accesul utilizatorului
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uId)
                                      .update({'hasAccess': true});

                                  // 2. Ștergem sau marcăm notificările legate de acest student ca citite/rezolvate
                                  var notifs = await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .where(
                                        'userId',
                                        isEqualTo: currentUser!.uid,
                                      ) // Notificările primite de profesor
                                      .where(
                                        'studentId',
                                        isEqualTo: uId,
                                      ) // Dacă salvezi studentId în notificare
                                      .get();
                                  for (var doc in notifs.docs) {
                                    await doc.reference.delete(); // Sau .update({'isRead': true})
                                  }

                                  _updateBadgeForUser();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                tooltip: 'Respinge Contul',
                                onPressed: () =>
                                    _confirmAndDeleteUser(uId, name), // Aceasta șterge deja și notificările în funcția ta _confirmAndDeleteUser!
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
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
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
                          String studentName = 'Elev';
                          if (userSnap.hasData && userSnap.data!.exists) {
                            var uData =
                                userSnap.data!.data() as Map<String, dynamic>?;
                            studentName =
                                uData?['fullName'] ??
                                uData?['name'] ??
                                uData?['email'] ??
                                'Elev';
                          }

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('courses')
                                .doc(courseId)
                                .get(),
                            builder: (context, courseSnap) {
                              String courseTitle = 'Curs';
                              if (courseSnap.hasData &&
                                  courseSnap.data!.exists) {
                                var cData =
                                    courseSnap.data!.data()
                                        as Map<String, dynamic>?;
                                courseTitle = cData?['title'] ?? 'Curs';
                              }

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Solicită înscriere la: $courseTitle',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 30,
                                        ),
                                        onPressed: () async {
                                          // 1. Actualizăm înscrierea
                                          await FirebaseFirestore.instance
                                              .collection('enrollments')
                                              .doc(reqId)
                                              .update({'status': 'approved'});

                                          // 2. Ștergem notificarea asociată acestei cereri din Firestore
                                          var notifs = await FirebaseFirestore
                                              .instance
                                              .collection('notifications')
                                              .where(
                                                'courseId',
                                                isEqualTo: courseId,
                                              )
                                              .where(
                                                'userId',
                                                isEqualTo: currentUser!.uid,
                                              )
                                              .get();
                                          for (var doc in notifs.docs) {
                                            await doc.reference.delete();
                                          }

                                          _updateBadgeForUser();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                        onPressed: () async {
                                          // 1. Ștergem cererea de înscriere
                                          await FirebaseFirestore.instance
                                              .collection('enrollments')
                                              .doc(reqId)
                                              .delete();

                                          // 2. Ștergem notificarea corespunzătoare
                                          var notifs = await FirebaseFirestore
                                              .instance
                                              .collection('notifications')
                                              .where(
                                                'courseId',
                                                isEqualTo: courseId,
                                              )
                                              .where(
                                                'userId',
                                                isEqualTo: currentUser!.uid,
                                              )
                                              .get();
                                          for (var doc in notifs.docs) {
                                            await doc.reference.delete();
                                          }

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
                      decoration: InputDecoration(
                        hintText: 'Caută după nume sau email...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff42153e),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff42153e),
                              ),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('Nu s-au găsit utilizatori.'),
                            );
                          }

                          String query = _searchController.text
                              .toLowerCase()
                              .trim();

                          var users = snapshot.data!.docs.where((doc) {
                            var uData = doc.data() as Map<String, dynamic>;
                            String name =
                                (uData['fullName'] ?? uData['name'] ?? '')
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
                              String uId = uDoc.id;
                              String name =
                                  uData['fullName'] ??
                                  uData['name'] ??
                                  'Utilizator';
                              String email = uData['email'] ?? '';
                              String role = uData['role'] ?? 'student';
                              bool hasAccess = uData['hasAccess'] ?? false;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: role == 'teacher'
                                        ? Colors.amber.shade800
                                        : (role == 'parent'
                                              ? Colors.blue
                                              : const Color(0xff42153e)),
                                    child: Text(
                                      role.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$email • $role ${hasAccess ? '(Activ)' : '(Neaprobat)'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Șterge Utilizatorul',
                                    onPressed: () =>
                                        _confirmAndDeleteUser(uId, name),
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

    // LISTA DE NOTIFICĂRI PENTRU ELEVI / PĂRINȚI
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        title: const Text(
          "Notificări",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff42153e),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff42153e)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nu ai nicio notificare în prezent.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
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

              return Card(
                elevation: isRead ? 1 : 3,
                color: isRead ? Colors.white : Colors.amber.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isRead
                      ? BorderSide.none
                      : BorderSide(color: Colors.amber.shade700, width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey.shade300
                        : const Color(0xff42153e),
                    child: Icon(
                      isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: isRead ? Colors.grey.shade700 : Colors.amber,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: const Color(0xff42153e),
                    ),
                  ),
                  subtitle: Text(
                    body,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                  trailing: !isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
