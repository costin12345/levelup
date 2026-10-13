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
            labelColor: accentLila,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentLila,
            indicatorWeight: 3,
            tabs: const [
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
                // TAB 1: TEORIE
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
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                lessonContent,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (videoUrls.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  color: accentLila,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "📹 Înregistrări Video Curs (Bunny Embed):",
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
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: UniversalEmbeddedViewer(
                                  viewId:
                                      'video_${widget.lessonId}_${entry.key}',
                                  url: entry.value,
                                  height: 380,
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

                // TAB 2: TEMĂ
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (homeworkContent.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  color: accentLila,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "📝 Cerințe Temă:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryIndigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentLila.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentLila.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                homeworkContent,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (pdfUrls.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "📄 Fișiere PDF Suport / Fișe de Lucru:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryIndigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...pdfUrls.asMap().entries.map((entry) {
                              String pdfUrl = entry.value;

                              String embedUrl = pdfUrl;
                              if (pdfUrl.contains('drive.google.com')) {
                                embedUrl = pdfUrl.contains('&embedded=true')
                                    ? pdfUrl
                                    : '$pdfUrl&embedded=true';
                              } else {
                                if (!embedUrl.contains('#toolbar=0')) {
                                  embedUrl = '$embedUrl#toolbar=0';
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1.5,
                                    ),
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
                                            Icon(
                                              Icons.picture_as_pdf,
                                              color: accentLila,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Fișă de lucru #${entry.key + 1}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 520,
                                        child: UniversalEmbeddedViewer(
                                          viewId:
                                              'pdf_${widget.lessonId}_${entry.key}',
                                          url: embedUrl,
                                          height: 520,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ] else if (homeworkContent.isEmpty &&
                              pdfUrls.isEmpty) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 60),
                                child: Text(
                                  "Nu a fost adăugată nicio temă sau fișier PDF pentru această lecție.",
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
    const Color accentLila = Color(0xff7c4dff);

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
                      child: CircularProgressIndicator(color: accentLila),
                    )),
      ),
    );
  }
}
