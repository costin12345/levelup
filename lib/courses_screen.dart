import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'lesson_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  final String role;
  const CoursesScreen({super.key, required this.role});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedSubject = "Matematică";
  DocumentSnapshot? _selectedCourseDoc;

  final List<String> _subjects = ["Matematică", "Informatică", "Fizică"];

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meniu lateral cu materii
          Container(
            width: 240,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentLila.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: accentLila,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Materii Cursuri",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryIndigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      String subject = _subjects[index];
                      bool isSelected = _selectedSubject == subject;

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedSubject = subject;
                          _selectedCourseDoc = null; // Resetează cursul selectat la schimbarea materiei
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentLila.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 18,
                                color: isSelected
                                    ? accentLila
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? primaryIndigo
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.black12),

          // Conținut Principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (_selectedCourseDoc != null)
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() {
                                  _selectedCourseDoc = null;
                                }),
                              ),
                            Flexible(
                              child: Text(
                                _selectedCourseDoc != null
                                    ? "Clasa: ${_selectedCourseDoc!['title']} ($_selectedSubject)"
                                    : "Cursuri & Materiale - $_selectedSubject",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: primaryIndigo,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🚀 Aici adăugăm butonul vizibil în dreapta sus
                      if (widget.role == 'teacher')
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddCourseDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentLila,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Adaugă Curs / Clasă"),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _selectedCourseDoc == null
                        ? _buildCoursesList(accentLila, primaryIndigo)
                        : _buildCourseGroupsWithTabs(
                            _selectedCourseDoc!.id,
                            accentLila,
                            primaryIndigo,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Lista de Cursuri/Clase
  Widget _buildCoursesList(Color accentLila, Color primaryIndigo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('subject', isEqualTo: _selectedSubject)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text("Nu există cursuri adăugate pentru această materie."),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () => setState(() => _selectedCourseDoc = doc),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: accentLila),
                        const SizedBox(width: 12),
                        Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                    if (widget.role == 'teacher')
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => doc.reference.delete(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Afișează Grupele sub formă de TAB-uri în partea de sus, cu opțiune de ștergere pentru profesori
  Widget _buildCourseGroupsWithTabs(
    String courseId,
    Color accentLila,
    Color primaryIndigo,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('groups')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var groupDocs = snapshot.data!.docs;
        if (groupDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Nu există grupe create în acest curs."),
                const SizedBox(height: 12),
                if (widget.role == 'teacher')
                  ElevatedButton(
                    onPressed: () => _showAddGroupDialog(context, courseId),
                    child: const Text("Adaugă Prima Grupă"),
                  ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: groupDocs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bara de Tab-uri pentru Grupe
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        labelColor: Colors.white,
                        unselectedLabelColor: primaryIndigo,
                        indicator: BoxDecoration(
                          color: accentLila,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: groupDocs.map((groupDoc) {
                          var groupData =
                              groupDoc.data() as Map<String, dynamic>;
                          return Tab(text: groupData['groupName'] ?? 'Grupă');
                        }).toList(),
                      ),
                    ),
                  ),
                  if (widget.role == 'teacher') ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddGroupDialog(context, courseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryIndigo,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.group_add, size: 16),
                      label: const Text("Adaugă Grupă"),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Conținutul corespunzător fiecărui tab de grupă (Lecțiile grupei respective)
              Expanded(
                child: TabBarView(
                  children: groupDocs.map((groupDoc) {
                    String groupId = groupDoc.id;
                    var groupData = groupDoc.data() as Map<String, dynamic>;
                    String groupName = groupData['groupName'] ?? 'Grupă';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Lecții pentru: $groupName",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryIndigo,
                                  ),
                                ),
                                // Buton de ștergere grupă vizibil doar pentru profesori
                                if (widget.role == 'teacher') ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    tooltip: "Șterge grupa curentă",
                                    onPressed: () => _confirmAndDeleteGroup(
                                      context,
                                      courseId,
                                      groupId,
                                      groupName,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.role == 'teacher')
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddLessonDialog(context, groupId),
                                icon: Icon(
                                  Icons.add,
                                  color: accentLila,
                                  size: 18,
                                ),
                                label: Text(
                                  "Adaugă Lecție în această grupă",
                                  style: TextStyle(color: accentLila),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _buildLessonsList(
                            groupId,
                            accentLila,
                            primaryIndigo,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Metodă de confirmare și ștergere a grupei și a lecțiilor din interiorul ei
  Future<void> _confirmAndDeleteGroup(
    BuildContext context,
    String courseId,
    String groupId,
    String groupName,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ștergere grupă "$groupName"'),
        content: const Text(
          'Ești sigur că vrei să ștergi această grupă? Toate lecțiile și materialele asociate acestei grupe vor fi eliminate definitiv.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Ștergem lecțiile din subcolecția 'lessons' a grupei
        var lessonsSnap = await FirebaseFirestore.instance
            .collection('course_groups')
            .doc(groupId)
            .collection('lessons')
            .get();

        for (var doc in lessonsSnap.docs) {
          await doc.reference.delete();
        }

        // 2. Ștergem referința din colecția globală 'course_groups'
        await FirebaseFirestore.instance
            .collection('course_groups')
            .doc(groupId)
            .delete();

        // 3. Ștergem documentul grupei din curs ('courses/{courseId}/groups/{groupId}')
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('groups')
            .doc(groupId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grupa "$groupName" a fost ștersă cu succes.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la ștergerea grupei: $e')),
          );
        }
      }
    }
  }

  // 3. Lista de lecții pentru grupa curentă
  Widget _buildLessonsList(
    String groupId,
    Color accentLila,
    Color primaryIndigo,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('course_groups')
          .doc(groupId)
          .collection('lessons')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Nu există lecții adăugate în această grupă.",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonDetailScreen(
                          courseId: groupId,
                          lessonId: doc.id,
                          lessonTitle: data['title'] ?? 'Lecție',
                          role: widget.role,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (_selectedCourseDoc != null)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () => setState(() {
                                          _selectedCourseDoc = null;
                                        }),
                                      ),
                                    Flexible(
                                      child: Text(
                                        _selectedCourseDoc != null
                                            ? "Clasa: ${_selectedCourseDoc!['title']} ($_selectedSubject)"
                                            : "Cursuri & Materiale - $_selectedSubject",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xff1e1b4b),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 🚀 Forțăm afișarea butonului să vedem dacă se randează acum
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddCourseDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff7c4dff),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text("Adaugă Curs (${widget.role})"), // Afișează și rolul să vedem ce valoare are
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 🚀 Butonul de adăugare curs vizibil clar pentru profesor când nu este selectată o clasă
                        if (widget.role == 'teacher' &&
                            _selectedCourseDoc == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddCourseDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff7c4dff),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Adaugă Curs / Clasă"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Dialog adăugare curs
  void _showAddCourseDialog(BuildContext context) {
    String title = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adaugă Curs Nou pentru $_selectedSubject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Titlu Curs / Clasă (ex: Clasa a 9-a)",
                ),
                onChanged: (val) => title = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Descriere"),
                onChanged: (val) => description = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('courses').add({
                    'title': title,
                    'description': description,
                    'subject': _selectedSubject,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Salvează"),
            ),
          ],
        );
      },
    );
  }

  // Dialog adăugare grupă
  void _showAddGroupDialog(BuildContext context, String courseId) {
    String groupName = "";
    String description = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adaugă Grupă Nouă"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Nume Grupă (ex: Grupa 1)",
                ),
                onChanged: (val) => groupName = val,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Descriere / Detalii",
                ),
                onChanged: (val) => description = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupName.isNotEmpty) {
                  var docRef = await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .collection('groups')
                      .add({
                        'groupName': groupName,
                        'description': description,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  await FirebaseFirestore.instance
                      .collection('course_groups')
                      .doc(docRef.id)
                      .set({'groupName': groupName, 'courseId': courseId});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Salvează"),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonDialog(BuildContext context, String groupId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final homeworkContentController = TextEditingController();

    List<String> videoUrls = [];
    List<String> pdfUrls = [];

    final newVideoController = TextEditingController();
    final newPdfController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Adaugă Lecție Nouă (Video & PDF)",
                style: TextStyle(
                  color: Color(0xff1e1b4b),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Titlu Lecție",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "--- SECȚIUNEA 1: TEORIE & VIDEO ---",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Conținut / Explicații Teoretice",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Link-uri Video Bunny (iframe embed):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...videoUrls.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String url = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.video_library,
                            color: Colors.purple,
                          ),
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                setDialogState(() => videoUrls.removeAt(idx)),
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newVideoController,
                              decoration: const InputDecoration(
                                hintText: "Adaugă URL Video Embed...",
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xff1e1b4b),
                            ),
                            onPressed: () {
                              String url = newVideoController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() {
                                  videoUrls.add(url);
                                  newVideoController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "--- SECȚIUNEA 2: TEMĂ & PDF ---",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: homeworkContentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Cerințe / Exerciții Temă (Text)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Fișiere PDF încărcate:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...pdfUrls.asMap().entries.map((entry) {
                        int idx = entry.key;
                        String url = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                setDialogState(() => pdfUrls.removeAt(idx)),
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newPdfController,
                              decoration: const InputDecoration(
                                hintText: "Lipește link-ul PDF...",
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xff1e1b4b),
                            ),
                            onPressed: () {
                              String url = newPdfController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() {
                                  pdfUrls.add(url);
                                  newPdfController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Anulează",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPdfController.text.trim().isNotEmpty) {
                      pdfUrls.add(newPdfController.text.trim());
                    }
                    if (newVideoController.text.trim().isNotEmpty) {
                      videoUrls.add(newVideoController.text.trim());
                    }

                    final String lTitle = titleController.text.trim();
                    if (lTitle.isNotEmpty) {
                      // 1. Salvăm lecția în Firestore sub grupa respectivă
                      DocumentReference lessonRef = await FirebaseFirestore
                          .instance
                          .collection('course_groups')
                          .doc(groupId)
                          .collection('lessons')
                          .add({
                            'title': lTitle,
                            'content': contentController.text.trim(),
                            'videoUrls': videoUrls,
                            'homeworkContent': homeworkContentController.text
                                .trim(),
                            'pdfUrls': pdfUrls,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      // 2. 🚀 TRIMITEM NOTIFICĂRI CĂTRE ELEVI (Logica recuperată)
                      try {
                        // Găsim toți elevii care au acces sau sunt înscriși
                        var studentsSnap = await FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'student')
                            .get();

                        for (var studentDoc in studentsSnap.docs) {
                          String studentId = studentDoc.id;

                          // Notificare pentru Lecție / Teorie
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .add({
                                'userId': studentId,
                                'courseId': groupId,
                                'lessonId': lessonRef.id,
                                'title': lTitle,
                                'body': 'A fost adăugată o nouă lecție/material video.',
                                'type':
                                    'lesson', // Va deschide tab-ul de lecție
                                'isRead': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          // Dacă există și conținut de temă, trimitem și notificare de temă
                          if (homeworkContentController.text
                                  .trim()
                                  .isNotEmpty ||
                              pdfUrls.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                                  'userId': studentId,
                                  'courseId': groupId,
                                  'lessonId': lessonRef.id,
                                  'title': 'Temă nouă: $lTitle',
                                  'body': 'Au fost adăugate cerințe de temă sau fișiere PDF.',
                                  'type': 'homework', // Va deschide direct tab-ul de temă
                                  'isRead': false,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                          }
                        }
                      } catch (e) {
                        debugPrint("Eroare la trimiterea notificărilor: $e");
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lecția a fost adăugată și s-au trimis notificările!',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1e1b4b),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Salvează"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
