import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'course_detail_screen.dart'; // Asigură-te că importi ecranul de detalii curs (pentru accesare)

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Stări pentru ordonare (sortare)
  String _sortBy =
      'title'; // 'title' (alfabetic/clase) sau 'category' (materie)
  bool _isAscending = true; // crescător sau descrescător

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Variabile pentru motivul ștergerii
    String selectedReason = 'Nu mai folosesc aplicația';
    final List<String> reasons = [
      'Nu mai folosesc aplicația',
      'Nu găsesc cursurile dorite',
      'Probleme tehnice / erori',
      'Alt motiv',
    ];
    final TextEditingController customReasonController =
        TextEditingController();

    // Pasul 1: Afișăm dialogul de confirmare și selectare a motivului
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Ștergere Cont"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ești sigur/ă că vrei să ștergi contul? Această acțiune este ireversibilă.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Te rugăm să ne spui motivul ștergerii:",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(
                          reason,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReason = val);
                          }
                        },
                      );
                    }),
                    if (selectedReason == 'Alt motiv') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customReasonController,
                        decoration: const InputDecoration(
                          labelText: "Specifică motivul",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Anulează"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Șterge Definitiv"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    // Determinăm motivul final
    String finalReason = selectedReason == 'Alt motiv'
        ? (customReasonController.text.trim().isNotEmpty
              ? customReasonController.text.trim()
              : 'Alt motiv')
        : selectedReason;

    try {
      // Preluăm detaliile utilizatorului înainte de ștergere pentru a le trimite profesorului
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String userName = "Utilizator";
      String userEmail = user.email ?? '';
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        userName = data['fullName'] ?? data['name'] ?? 'Utilizator';
      }

      // Pasul 2: Trimitem o notificare / înregistrare către profesori în colecția 'account_deletion_requests'
      await FirebaseFirestore.instance
          .collection('account_deletion_requests')
          .add({
            'userId': user.uid,
            'userName': userName,
            'userEmail': userEmail,
            'reason': finalReason,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Pasul 3: Ștergem documentul din Firestore și contul din Firebase Auth
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contul a fost șters, iar profesorul a fost informat.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eroare: ${e.message}. Te rugăm să te reautentifici.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDeletionRequestsDialog(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Motive ștergere cont",
          style: TextStyle(
            color: primaryIndigo,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('account_deletion_requests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff7c4dff)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Niciun cont șters momentan.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final requests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final data = req.data() as Map<String, dynamic>;
                  final String name = data['userName'] ?? 'Utilizator';
                  final String email = data['userEmail'] ?? '';
                  final String reason = data['reason'] ?? 'Fără motiv';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryIndigo,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            "Email: $email",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Motiv: $reason",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.grey,
                          size: 22,
                        ),
                        tooltip: "Șterge din istoric",
                        onPressed: () => req.reference.delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Închide"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                String fullName = "Utilizator";
                String email = user?.email ?? '';
                String role = 'student';

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  fullName = data['fullName'] ?? data['name'] ?? 'Utilizator';
                  role = data['role'] ?? 'student';
                }

                String roleText = role == 'teacher'
                    ? 'Profesor'
                    : (role == 'parent' ? 'Părinte' : 'Elev');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secțiunea de profil (Sus)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: accentLila.withOpacity(0.15),
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : "U",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: accentLila,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryIndigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              "Rol: $roleText",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentLila,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Titlu + Opțiuni de Ordonare (Sortare)
                    // ... în interiorul clasei ProfileTab, în metoda build ...

                    // Titlu + Opțiuni de Ordonare (Sortare) - Modificat pentru a fi responsive
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Dacă ecranul este prea îngust (telefon), afișăm pe două rânduri
                          bool isPhone = constraints.maxWidth < 400;

                          return isPhone
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Rândul 1: Titlul
                                    Text(
                                      role == 'teacher'
                                          ? "Cururile pe care le predai"
                                          : "Cururile la care ești înscris",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Rândul 2: Sortarea și butonul de ștergere (aliniate între ele)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Dropdown-ul de sortare
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: DropdownButton<String>(
                                              value: _sortBy,
                                              isExpanded: true,
                                              underline: const SizedBox(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryIndigo,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'title',
                                                  child: Text(
                                                    "După titlu/clasă",
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'category',
                                                  child: Text("După materie"),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null)
                                                  setState(() => _sortBy = val);
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Butonul de sortare crescător/descrescător
                                        Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              _isAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              size: 18,
                                              color: accentLila,
                                            ),
                                            tooltip: _isAscending
                                                ? "Crescător"
                                                : "Descrescător",
                                            onPressed: () {
                                              setState(
                                                () => _isAscending =
                                                    !_isAscending,
                                              );
                                            },
                                          ),
                                        ),
                                        // Butonul pentru conturi șterse (vizibil doar pentru profesor)
                                        if (role == 'teacher') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.person_remove_alt_1,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              tooltip:
                                                  "Conturi șterse și motive",
                                              onPressed: () =>
                                                  _showDeletionRequestsDialog(
                                                    context,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                )
                              : // Varianta originală pentru tablete / ecrane mari
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      role == 'teacher'
                                          ? "Cururile pe care le predai"
                                          : "Cururile la care ești înscris",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Dropdown-ul de sortare
                                        DropdownButton<String>(
                                          value: _sortBy,
                                          underline: const SizedBox(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: primaryIndigo,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'title',
                                              child: Text("După titlu/clasă"),
                                            ),
                                            DropdownMenuItem(
                                              value: 'category',
                                              child: Text("După materie"),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null)
                                              setState(() => _sortBy = val);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        // Săgeata de sortare
                                        IconButton(
                                          icon: Icon(
                                            _isAscending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 18,
                                            color: accentLila,
                                          ),
                                          tooltip: _isAscending
                                              ? "Crescător"
                                              : "Descrescător",
                                          onPressed: () {
                                            setState(
                                              () =>
                                                  _isAscending = !_isAscending,
                                            );
                                          },
                                        ),
                                        // Iconița pentru conturi șterse
                                        if (role == 'teacher') ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.person_remove_alt_1,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            tooltip: "Conturi șterse și motive",
                                            onPressed: () =>
                                                _showDeletionRequestsDialog(
                                                  context,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aici urmează StreamBuilder-ul care afișează lista de cursuri (rămâne neschimbat)
                    // role == 'teacher' ? ... : ...
                    const SizedBox(height: 12),

                    // Zona de afișare a cursurilor (cu sortare aplicată)
                    // În interiorul clasei ProfileTab, la StreamBuilder-ul pentru cursuri (pentru non-profesori):
                    role == 'teacher'
                        ? StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('courses')
                                .where('teacherId', isEqualTo: user?.uid)
                                .snapshots(),
                            builder: (context, courseSnapshot) {
                              return _buildCoursesList(
                                context,
                                courseSnapshot,
                                role,
                                primaryIndigo,
                                accentLila,
                              );
                            },
                          )
                        : FutureBuilder<DocumentSnapshot>(
                            // Pasul 1: Preluăm datele contului curent pentru a vedea dacă are un `childEmail` (în cazul în care e părinte)
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .get(),
                            builder: (context, userDocSnap) {
                              if (!userDocSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              var userData =
                                  userDocSnap.data!.data()
                                      as Map<String, dynamic>? ??
                                  {};
                              String targetEmail = email; // Valoarea implicită este emailul elevului logat

                              if (role == 'parent') {
                                targetEmail = userData['childEmail'] ?? '';
                              }

                              // Pasul 2: Căutăm în `enrollments` folosind emailul țintă (al elevului sau al copilului asociat)
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('enrollments')
                                    .where('userEmail', isEqualTo: targetEmail)
                                    .snapshots(),
                                builder: (context, enrollSnapshot) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('courses')
                                        .snapshots(),
                                    builder: (context, allCoursesSnap) {
                                      if (!enrollSnapshot.hasData ||
                                          !allCoursesSnap.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      var enrollDocs =
                                          enrollSnapshot.data!.docs;
                                      List<String> enrolledCourseIds =
                                          enrollDocs
                                              .map(
                                                (d) =>
                                                    (d.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >)['courseId']
                                                        as String? ??
                                                    '',
                                              )
                                              .toList();

                                      var filteredCourseDocs = allCoursesSnap
                                          .data!
                                          .docs
                                          .where(
                                            (doc) => enrolledCourseIds.contains(
                                              doc.id,
                                            ),
                                          )
                                          .toList();

                                      return _buildManualCoursesList(
                                        context,
                                        filteredCourseDocs,
                                        enrollDocs,
                                        role,
                                        primaryIndigo,
                                        accentLila,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                    const SizedBox(height: 30),
                    const Text(
                      "Setări Cont",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryIndigo,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Butoanele de Acțiune (Deconectare & Ștergere Cont)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: primaryIndigo,
                            ),
                            title: const Text("Deconectare"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _handleLogout(context),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                            title: const Text(
                              "Ștergere Cont",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            onTap: () => _handleDeleteAccount(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget ajutător pentru afișarea și sortarea curursurilor profesorului
  Widget _buildCoursesList(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snapshot,
    String role,
    Color primaryIndigo,
    Color accentLila,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          "Nu ai asignat niciun curs momentan.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    var courses = snapshot.data!.docs;

    // Aplicăm sortarea locală în funcție de opțiunile alese (_sortBy și _isAscending)
    courses.sort((a, b) {
      var dataA = a.data() as Map<String, dynamic>;
      var dataB = b.data() as Map<String, dynamic>;

      String valA = _sortBy == 'title'
          ? (dataA['title'] ?? '')
          : (dataA['category'] ?? '');
      String valB = _sortBy == 'title'
          ? (dataB['title'] ?? '')
          : (dataB['category'] ?? '');

      return _isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        var courseDoc = courses[index];
        var courseData = courseDoc.data() as Map<String, dynamic>;
        String courseId = courseDoc.id;
        String courseTitle = courseData['title'] ?? 'Curs necunoscut';
        String category = courseData['category'] ?? '';
        String description = courseData['description'] ?? '';

        return _buildCourseItemContainer(
          context,
          courseId,
          courseTitle,
          category,
          description,
          role,
          primaryIndigo,
          accentLila,
          status: 'Profesor Titular',
        );
      },
    );
  }

  // Widget ajutător pentru elevi/părinți
  Widget _buildManualCoursesList(
    BuildContext context,
    List<QueryDocumentSnapshot> courseDocs,
    List<QueryDocumentSnapshot> enrollDocs,
    String role,
    Color primaryIndigo,
    Color accentLila,
  ) {
    if (courseDocs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          "Nu ești înscris la niciun curs momentan.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sortare
    courseDocs.sort((a, b) {
      var dataA = a.data() as Map<String, dynamic>;
      var dataB = b.data() as Map<String, dynamic>;

      String valA = _sortBy == 'title'
          ? (dataA['title'] ?? '')
          : (dataA['category'] ?? '');
      String valB = _sortBy == 'title'
          ? (dataB['title'] ?? '')
          : (dataB['category'] ?? '');

      return _isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courseDocs.length,
      itemBuilder: (context, index) {
        var courseDoc = courseDocs[index];
        var courseData = courseDoc.data() as Map<String, dynamic>;
        String courseId = courseDoc.id;
        String courseTitle = courseData['title'] ?? 'Curs';
        String category = courseData['category'] ?? '';
        String description = courseData['description'] ?? '';

        // Găsim statusul înscrierii în siguranță
        String status = 'Înscris';
        try {
          var enroll = enrollDocs.firstWhere(
            (e) => (e.data() as Map<String, dynamic>)['courseId'] == courseId,
          );
          var enrollData = enroll.data() as Map<String, dynamic>;
          if (enrollData['status'] == 'pending') {
            status = 'În așteptare';
          }
        } catch (_) {
          status = 'Înscris';
        }

        return _buildCourseItemContainer(
          context,
          courseId,
          courseTitle,
          category,
          description,
          role,
          primaryIndigo,
          accentLila,
          status: status,
        );
      },
    );
  }

  // Designul unui rând de curs cu posibilitate de accesare la apăsare
  Widget _buildCourseItemContainer(
    BuildContext context,
    String courseId,
    String title,
    String category,
    String description,
    String role,
    Color primaryIndigo,
    Color accentLila, {
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentLila.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.book, color: accentLila, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryIndigo,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              category,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'În așteptare'
                    ? Colors.orange.withOpacity(0.1)
                    : accentLila.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: status == 'În așteptare' ? Colors.orange : accentLila,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
        // Accesarea cursului direct de aici
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                courseId: courseId,
                title: title,
                category: category,
                description: description,
                role: role,
              ),
            ),
          );
        },
      ),
    );
  }
}
