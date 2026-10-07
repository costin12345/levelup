import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialsScreen extends StatefulWidget {
  final String role;
  const MaterialsScreen({super.key, required this.role});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  String _activeTab = "Bacalaureat";
  bool _isArhivaTestExpanded = false;
  String? _selectedClassTab;

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);
    bool isMobile = MediaQuery.of(context).size.width < 750;

    if (widget.role != 'teacher' && _activeTab == "Arhivă Teste") {
      _activeTab = "Bacalaureat";
    }

    // Conținutul meniului lateral (folosit în Drawer pe telefon sau Row pe desktop)
    Widget materialsSidebarContent = Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: ListView(
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
                  Icons.folder_open,
                  color: accentLila,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Materiale",
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

          if (widget.role == 'teacher')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _isArhivaTestExpanded = !_isArhivaTestExpanded;
                    if (_isArhivaTestExpanded && _selectedClassTab == null) {
                      _selectedClassTab = "Clasa a 4-a";
                      _activeTab = "Arhivă Teste";
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_shared_outlined,
                          size: 18,
                          color: _activeTab == "Arhivă Teste"
                              ? accentLila
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Arhivă Teste",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(
                          _isArhivaTestExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isArhivaTestExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(9, (index) {
                        int gradeNum = index + 4;
                        String cName = "Clasa a ${gradeNum}-a";
                        bool isSel =
                            _activeTab == "Arhivă Teste" &&
                            _selectedClassTab == cName;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _activeTab = "Arhivă Teste";
                              _selectedClassTab = cName;
                            });
                            if (isMobile) Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            child: Text(
                              cName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel ? primaryIndigo : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

          _buildSidebarItem(
            "Bacalaureat",
            Icons.school_outlined,
            accentLila,
            primaryIndigo,
            isMobile,
          ),
          _buildSidebarItem(
            "Evaluarea Națională",
            Icons.menu_book_outlined,
            accentLila,
            primaryIndigo,
            isMobile,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      drawer: isMobile ? Drawer(child: materialsSidebarContent) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            materialsSidebarContent,
            const VerticalDivider(width: 1, color: Colors.black12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryIndigo, Color(0xff312e81)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (isMobile)
                          Builder(
                            builder: (context) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                                tooltip: "Meniu Materiale",
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activeTab == "Arhivă Teste"
                                    ? "Arhivă Teste (${_selectedClassTab ?? 'Clasa a 4-a'})"
                                    : _activeTab,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "Resurse educaționale, teste și pregătire examen",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _activeTab == "Arhivă Teste"
                      ? _buildArhivaTesteView(
                          primaryIndigo,
                          accentLila,
                          isMobile,
                        )
                      : _activeTab == "Bacalaureat"
                      ? _buildExamView("Bacalaureat", primaryIndigo, accentLila)
                      : _buildExamView(
                          "Evaluarea Națională",
                          primaryIndigo,
                          accentLila,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    Color accentLila,
    Color primaryIndigo,
    bool isMobile,
  ) {
    bool isSelected = _activeTab == title;
    return InkWell(
      onTap: () {
        setState(() => _activeTab = title);
        if (isMobile) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentLila.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? accentLila : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryIndigo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArhivaTesteView(
    Color primaryIndigo,
    Color accentLila,
    bool isMobile,
  ) {
    String currentClass = _selectedClassTab ?? "Clasa a 4-a";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🚀 Antet cu titlu și butonul de adăugare folder vizibil clar pentru profesori
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Foldere - $currentClass",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryIndigo,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.role == 'teacher')
              ElevatedButton.icon(
                onPressed: () => _showAddFolderDialog(context, currentClass),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentLila,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.create_new_folder, size: 16),
                label: const Text("Adaugă Folder"),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('test_folders')
              .where('className', isEqualTo: currentClass)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var folders = snapshot.data!.docs;
            if (folders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Niciun folder creat pentru această clasă.",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                var folderDoc = folders[index];
                var folderData = folderDoc.data() as Map<String, dynamic>;
                String folderId = folderDoc.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.folder,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    folderData['folderName'] ?? 'Folder',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: primaryIndigo,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.role == 'teacher')
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showUploadTestDialog(context, folderId),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accentLila),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              icon: Icon(
                                Icons.upload_file,
                                size: 16,
                                color: accentLila,
                              ),
                              label: Text(
                                "Încarcă Test",
                                style: TextStyle(
                                  color: accentLila,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('test_folders')
                            .doc(folderId)
                            .collection('tests')
                            .snapshots(),
                        builder: (context, testSnapshot) {
                          if (!testSnapshot.hasData ||
                              testSnapshot.data!.docs.isEmpty) {
                            return const Text(
                              "Nu există teste încărcate în acest folder.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }
                          var tests = testSnapshot.data!.docs;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tests.map((testDoc) {
                              var testData =
                                  testDoc.data() as Map<String, dynamic>;
                              return Chip(
                                avatar: const Icon(
                                  Icons.insert_drive_file,
                                  size: 14,
                                  color: Colors.deepPurple,
                                ),
                                label: Text(
                                  "${testData['title']} (${testData['date']})",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: widget.role == 'teacher'
                                    ? const Icon(Icons.close, size: 14)
                                    : null,
                                onDeleted: widget.role == 'teacher'
                                    ? () => testDoc.reference.delete()
                                    : null,
                                backgroundColor: Colors.grey.shade100,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildExamView(
    String examTitle,
    Color primaryIndigo,
    Color accentLila,
  ) {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 48, color: accentLila),
          const SizedBox(height: 12),
          Text(
            "Materiale Oficiale - $examTitle",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryIndigo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Aici elevii au acces la simulări, subiecte din anii trecuți și variante rezolvate.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, String className) {
    String folderName = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adaugă Folder Nou pentru $className"),
          content: TextField(
            decoration: const InputDecoration(
              labelText: "Nume Folder (ex: Teste Semestrul 1)",
            ),
            onChanged: (val) => folderName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anulează"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7c4dff),
              ),
              onPressed: () async {
                if (folderName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('test_folders')
                      .add({
                        'className': className,
                        'folderName': folderName,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Creează",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadTestDialog(BuildContext context, String folderId) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    String date =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Încarcă Teste în Folder"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Adaugă linkul (ex: Bunny.net, PDF, Google Drive) pentru test.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Titlu Test",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Link Bunny.net / Fișier (URL)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Închide"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1e1b4b),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    linkController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('test_folders')
                      .doc(folderId)
                      .collection('tests')
                      .add({
                        'title': titleController.text,
                        'details': linkController.text,
                        'date': date,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Salvează",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
