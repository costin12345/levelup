import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'web_iframe_stub.dart' if (dart.library.html) 'web_iframe_web.dart';

class LessonDetailPage extends StatefulWidget {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  final String initialTab;
  final String role;

  const LessonDetailPage({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    this.initialTab = 'lesson',
    required this.role,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  bool _isAiProcessing = false;

  // Funcție pentru prelucrarea textului existent cu Google Gemini AI
  Future<void> _enhanceWithAI(String sourceUrlOrText, String fieldType) async {
    if (sourceUrlOrText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu există conținut de prelucrat.')),
      );
      return;
    }

    setState(() => _isAiProcessing = true);

    try {
      const apiKey = 'AQ.Ab8RN6LZbJMzN1Rv4Td2CCGHicDZqQOO_rxSp7wsnrmZvWSMLw'; // Introdu cheia ta Gemini

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      bool isImageUrl =
          sourceUrlOrText.startsWith('http') &&
          (sourceUrlOrText.endsWith('.png') ||
              sourceUrlOrText.endsWith('.jpg') ||
              sourceUrlOrText.endsWith('.jpeg') ||
              sourceUrlOrText.contains('drive.google.com'));

      Map<String, dynamic> requestBody;

      if (isImageUrl) {
        requestBody = {
          "contents": [
            {
              "parts": [
                {
                  "text": "Ești un profesor expert. Analizează această imagine/fișier, extrage tot textul, corectează-l și formatează-l într-un stil extrem de curat, profesional, cu titluri și structură clară pentru elevi (folosind Markdown).",
                },
                {
                  "file_data": {
                    "mime_type": "image/jpeg",
                    "file_uri": sourceUrlOrText,
                  },
                },
              ],
            },
          ],
        };
      } else {
        requestBody = {
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Ești un profesor expert în educație. Analizează acest text brut, corectează-l și rescrie-l într-un format extrem de curat, profesional, structurat cu titluri clare și subpuncte (Markdown):\n\n$sourceUrlOrText",
                },
              ],
            },
          ],
        };
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String enhancedText =
            data['candidates'][0]['content']['parts'][0]['text'] ??
            sourceUrlOrText;

        String updateField = fieldType == 'theory'
            ? 'content'
            : 'homeworkContent';
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('lessons')
            .doc(widget.lessonId)
            .update({updateField: enhancedText});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Conținutul a fost extras și optimizat cu succes de AI!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Eroare API: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la prelucrarea cu AI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int initialIndex = (widget.initialTab == 'homework') ? 1 : 0;
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        appBar: AppBar(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          title: Text(
            widget.lessonTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentLila,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 20),
                text: "Teorie & Aplicații",
              ),
              Tab(
                icon: Icon(Icons.assignment_rounded, size: 20),
                text: "Temă (PDF & Text)",
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('lessons')
                  .doc(widget.lessonId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: accentLila),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "Lecția nu a fost găsită.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var lessonData = snapshot.data!.data() as Map<String, dynamic>;
                String lessonContent = lessonData['content'] ?? '';
                String homeworkContent = lessonData['homeworkContent'] ?? '';

                List<String> videoUrls = [];
                if (lessonData['videoUrls'] != null) {
                  videoUrls = List<String>.from(lessonData['videoUrls']);
                } else if (lessonData['videoUrl'] != null &&
                    (lessonData['videoUrl'] as String).isNotEmpty) {
                  videoUrls = [lessonData['videoUrl']];
                }

                List<String> pdfUrls = [];
                if (lessonData['pdfUrls'] != null) {
                  pdfUrls = List<String>.from(lessonData['pdfUrls']);
                } else if (lessonData['pdfUrl'] != null &&
                    (lessonData['pdfUrl'] as String).isNotEmpty) {
                  pdfUrls = [lessonData['pdfUrl']];
                }

                return TabBarView(
                  children: [
                    // --- TAB 1: TEORIE & VIDEO ---
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lessonContent.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.lightbulb_outline_rounded,
                                                color: accentLila,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Note de curs / Explicații",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: primaryIndigo,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (widget.role == 'teacher')
                                            TextButton.icon(
                                              onPressed: () => _enhanceWithAI(
                                                lessonContent,
                                                'theory',
                                              ),
                                              icon: const Icon(
                                                Icons.auto_awesome,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              label: const Text(
                                                "Prelucinează cu AI",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        lessonContent,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              if (videoUrls.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: accentLila,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Înregistrări Video Curs",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...videoUrls.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.03,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            color: primaryIndigo,
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.video_library_rounded,
                                                  color: Colors.amberAccent,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  "Video Lecția #${entry.key + 1}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          UniversalEmbeddedViewer(
                                            viewId:
                                                'video_${widget.lessonId}_${entry.key}',
                                            url: entry.value,
                                            height: 420,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (lessonContent.isEmpty &&
                                  videoUrls.isEmpty) ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 60),
                                    child: Text(
                                      "Nu există conținut teoretic încărcat pentru această lecție.",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- TAB 2: TEMĂ (PDF & Text) ---
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accentLila.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentLila.withOpacity(0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.assignment_outlined,
                                              color: accentLila,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Cerințe Temă & Exerciții",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: primaryIndigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.role == 'teacher' &&
                                            pdfUrls.isNotEmpty &&
                                            homeworkContent.isEmpty)
                                          ElevatedButton.icon(
                                            onPressed: () => _enhanceWithAI(
                                              pdfUrls.first,
                                              'homework',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accentLila,
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.auto_awesome,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Extrage text din PDF cu AI",
                                            ),
                                          ),
                                        if (widget.role == 'teacher' &&
                                            homeworkContent.isNotEmpty)
                                          TextButton.icon(
                                            onPressed: () => _enhanceWithAI(
                                              homeworkContent,
                                              'homework',
                                            ),
                                            icon: const Icon(
                                              Icons.auto_awesome,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            label: const Text(
                                              "Optimizează cu AI",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 16),
                                    homeworkContent.isNotEmpty
                                        ? Text(
                                            homeworkContent,
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 1.7,
                                              color: Colors.grey.shade800,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Nu a fost generat textul pentru această temă încă.",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (pdfUrls.isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  "Ai un fișier PDF atașat. Apasă pe butonul de sus „Extrage text din PDF cu AI” pentru ca Gemini să-l transforme într-un text curat și structurat!",
                                                  style: TextStyle(
                                                    color: accentLila,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Indicator de încărcare în timp ce AI-ul procesează
            if (_isAiProcessing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: accentLila),
                        const SizedBox(height: 16),
                        const Text(
                          "Gemini AI rescrie și formatează conținutul...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xff1e1b4b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UniversalEmbeddedViewer extends StatefulWidget {
  final String viewId;
  final String url;
  final double height;

  const UniversalEmbeddedViewer({
    super.key,
    required this.viewId,
    required this.url,
    required this.height,
  });

  @override
  State<UniversalEmbeddedViewer> createState() =>
      _UniversalEmbeddedViewerState();
}

class _UniversalEmbeddedViewerState extends State<UniversalEmbeddedViewer> {
  WebViewController? _mobileController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _mobileController?.runJavaScript('''
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
                document.getElementsByTagName('head')[0].appendChild(meta);
              ''');
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentLila = Color(0xff7c4dff);

    return Container(
      height: widget.height,
      width: double.infinity,
      color: Colors.white,
      child: kIsWeb
          ? getWebIframe(widget.viewId, widget.url)
          : (_mobileController != null
                ? WebViewWidget(controller: _mobileController!)
                : const Center(
                    child: CircularProgressIndicator(color: accentLila),
                  )),
    );
  }
}
