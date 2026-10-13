import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  // Meniu inferior pentru alegerea sursei (Cameră sau Galerie)
  void _showImageSourceSelector(String fieldType) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xff7c4dff)),
                title: const Text('Fă o poză cu camera'),
                onTap: () {
                  Navigator.pop(context);
                  _processImageSource(ImageSource.camera, fieldType);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xff7c4dff),
                ),
                title: const Text('Alege din galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _processImageSource(ImageSource.gallery, fieldType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Procesarea locală a imaginii cu Google ML Kit (pe procesor)
  Future<void> _processImageSource(ImageSource source, String fieldType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() => _isProcessing = true);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      String extractedText = recognizedText.text;

      await textRecognizer.close();

      extractedText = extractedText.replaceAll(r'\', '');

      String updateField = fieldType == 'theory'
          ? 'content'
          : 'homeworkContent';

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('lessons')
          .doc(widget.lessonId)
          .update({updateField: extractedText});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text extras local cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la procesare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            onPressed: () =>
                                                _showImageSourceSelector(
                                                  'theory',
                                                ),
                                            icon: const Icon(
                                              Icons.document_scanner,
                                              size: 16,
                                              color: accentLila,
                                            ),
                                            label: const Text(
                                              "Scanează OCR Local",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: accentLila,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    lessonContent.isNotEmpty
                                        ? MarkdownBody(
                                            data: lessonContent,
                                            selectable: true,
                                            styleSheet: MarkdownStyleSheet(
                                              p: const TextStyle(
                                                fontSize: 14,
                                                height: 1.6,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            "Nu există conținut. Folosește butonul de sus pentru a scana local textul.",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

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
                                        if (widget.role == 'teacher')
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _showImageSourceSelector(
                                                  'homework',
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accentLila,
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.document_scanner,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Scanează OCR Local",
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 16),
                                    homeworkContent.isNotEmpty
                                        ? MarkdownBody(
                                            data: homeworkContent,
                                            selectable: true,
                                            styleSheet: MarkdownStyleSheet(
                                              p: TextStyle(
                                                fontSize: 15,
                                                height: 1.7,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            "Nu a fost generată tema. Apasă pe „Scanează OCR Local” pentru a citi cerința.",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 14,
                                            ),
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

            // Indicator de procesare locală pe procesor
            if (_isProcessing)
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
                          "Se citește textul local pe procesor...",
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
