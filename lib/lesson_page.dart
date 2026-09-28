import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonPage extends StatefulWidget {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  final String initialTab; // 'lesson' (index 0) sau 'homework' (index 1)

  const LessonPage({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    this.initialTab = 'lesson',
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  @override
  Widget build(BuildContext context) {
    int initialIndex = (widget.initialTab == 'homework') ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex:
          initialIndex, // Selectează automat Tab-ul corect (Lecție vs Temă)
      child: Scaffold(
        backgroundColor: const Color(0xfffff8dc),
        appBar: AppBar(
          title: Text(
            widget.lessonTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xff42153e),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.play_circle_fill), text: "Lecție"),
              Tab(icon: Icon(Icons.assignment), text: "Temă"),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.courseId)
              .collection('lessons')
              .doc(widget.lessonId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff42153e)),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Conținutul nu a fost găsit."));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            String videoUrl = data['videoUrl'] ?? '';
            String pdfUrl = data['pdfUrl'] ?? '';
            String homeworkText = data['homeworkText'] ?? '';

            return TabBarView(
              children: [
                // TAB 1: PAGINA CU CONȚINUTUL LECȚIEI
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (videoUrl.isNotEmpty) ...[
                          const Text(
                            "Video Lecție:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            videoUrl,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (pdfUrl.isNotEmpty) ...[
                          const Text(
                            "Material PDF / Fișier Suport:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            pdfUrl,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        if (videoUrl.isEmpty && pdfUrl.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Text(
                                "Nu există videoclip sau PDF atașat acestei lecții.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // TAB 2: PAGINA CU CERINȚELE TEMEI
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cerințe Temă pentru Acasă:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xff42153e),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (homeworkText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.shade700,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              homeworkText,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Text(
                                "Nu a fost adăugată o temă pentru această lecție.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
