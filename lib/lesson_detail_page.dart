import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'web_iframe_stub.dart' if (dart.library.html) 'web_iframe_web.dart';

class LessonDetailPage extends StatefulWidget {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  final String initialTab;

  const LessonDetailPage({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    this.initialTab = 'lesson',
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  @override
  Widget build(BuildContext context) {
    int initialIndex = (widget.initialTab == 'homework') ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xfffff8dc),
        appBar: AppBar(
          backgroundColor: const Color(0xff42153e),
          foregroundColor: Colors.white,
          title: Text(
            widget.lessonTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: const TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(
                icon: Icon(Icons.menu_book, size: 20),
                text: "Teorie & Aplicații",
              ),
              Tab(
                icon: Icon(Icons.assignment, size: 20),
                text: "Temă (PDF & Text)",
              ),
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
                // TAB 1: TEORIE
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lessonContent.isNotEmpty) ...[
                        Text(
                          lessonContent,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (videoUrls.isNotEmpty) ...[
                        const Text(
                          "📹 Înregistrări Video Curs (Bunny Embed):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xff42153e),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...videoUrls.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: UniversalEmbeddedViewer(
                              viewId: 'video_${widget.lessonId}_${entry.key}',
                              url: entry.value,
                              height: 380,
                            ),
                          ),
                        ),
                      ] else if (lessonContent.isEmpty) ...[
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

                // TAB 2: TEMĂ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (homeworkContent.isNotEmpty) ...[
                        const Text(
                          "📝 Cerințe Temă:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xff42153e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            homeworkContent,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (pdfUrls.isNotEmpty) ...[
                        const Text(
                          "📄 Fișiere PDF Suport / Fișe de Lucru:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xff42153e),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...pdfUrls.asMap().entries.map((entry) {
                          String pdfUrl = entry.value;
                          String embedUrl =
                              (pdfUrl.contains('drive.google.com') ||
                                  pdfUrl.contains('firebasestorage'))
                              ? 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(pdfUrl)}'
                              : pdfUrl;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: UniversalEmbeddedViewer(
                              viewId: 'pdf_${widget.lessonId}_${entry.key}',
                              url: embedUrl,
                              height: 520,
                            ),
                          );
                        }),
                      ] else if (homeworkContent.isEmpty) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Text(
                              "Nu a fost adăugată nicio temă (text sau PDF) pentru această lecție.",
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
              ],
            );
          },
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
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        child: kIsWeb
            ? getWebIframe(widget.viewId, widget.url)
            : (_mobileController != null
                  ? WebViewWidget(controller: _mobileController!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff42153e),
                      ),
                    )),
      ),
    );
  }
}
