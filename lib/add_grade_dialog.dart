import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'main.dart';

// Extern din main.dart
externFlutterLocalNotificationsPlugin() => flutterLocalNotificationsPlugin;

class AddGradeDialog extends StatefulWidget {
  const AddGradeDialog({super.key});

  @override
  State<AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<AddGradeDialog> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentEmail;

  String _selectedClass = "Clasa a IX-a";
  String _selectedCourse = "Matematică";
  String _selectedGrade = "10";

  final TextEditingController _commentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _classesList = [
    "Clasa a IV-a",
    "Clasa a V-a",
    "Clasa a VI-a",
    "Clasa a VII-a",
    "Clasa a VIII-a",
    "Clasa a IX-a",
    "Clasa a X-a",
    "Clasa a XI-a",
    "Clasa a XII-a",
  ];

  final List<String> _coursesList = ["Matematică", "Informatică", "Fizică"];

  final List<String> _gradesList = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
  ];

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff42153e),
              onPrimary: Colors.white,
              surface: Color(0xfffff8dc),
              onSurface: Color(0xff42153e),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'level_up_channel_id',
          'Level Up Notificări',
          channelDescription: 'Notificări pentru note și teme',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _saveGrade() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te rog selectează elevul!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formattedDate =
          "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}";

      // 1. Salvăm nota în 'grades'
      await FirebaseFirestore.instance.collection('grades').add({
        'studentId': _selectedStudentId,
        'studentName': _selectedStudentName ?? 'Elev',
        'studentEmail': _selectedStudentEmail ?? '',
        'className': _selectedClass,
        'courseTitle': _selectedCourse,
        'grade': _selectedGrade,
        'comment': _commentController.text.trim(),
        'date': formattedDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Trimitem în 'notifications' (pentru clopoțel și badge)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': _selectedStudentId,
        'title': 'Notă nouă la $_selectedCourse',
        'body':
            'Ai primit nota $_selectedGrade la $_selectedClass. Data: $formattedDate',
        'type': 'grade',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Afișăm bannerul local pe ecranul elevului
      await _showLocalNotification(
        'Notă nouă la $_selectedCourse',
        'Ai primit nota $_selectedGrade la $_selectedClass!',
      );

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Nota a fost adăugată cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Eroare la adăugarea notei: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr =
        "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}";

    return AlertDialog(
      backgroundColor: const Color(0xfffff8dc),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.star, color: Colors.amber, size: 28),
          SizedBox(width: 10),
          Text(
            "Adaugă Notă în Catalog",
            style: TextStyle(
              color: Color(0xff42153e),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: InputDecoration(
                  labelText: 'Selectează Clasa',
                  prefixIcon: const Icon(
                    Icons.class_,
                    color: Color(0xff42153e),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _classesList.map((String className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(
                      className,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var students = snapshot.data!.docs;
                  if (students.isEmpty) {
                    return const Text(
                      "Nu există elevi înregistrați în baza de date.",
                    );
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Selectează Numele Elevului',
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xff42153e),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: students.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data['fullName'] ?? 'Elev fără nume';
                      String email = data['email'] ?? '';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        onTap: () {
                          _selectedStudentName = name;
                          _selectedStudentEmail = email;
                        },
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStudentId = val;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                decoration: InputDecoration(
                  labelText: 'Selectează Materia',
                  prefixIcon: const Icon(Icons.book, color: Color(0xff42153e)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _coursesList.map((String course) {
                  return DropdownMenuItem<String>(
                    value: course,
                    child: Text(
                      course,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCourse = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: InputDecoration(
                        labelText: 'Nota',
                        prefixIcon: const Icon(
                          Icons.grade,
                          color: Colors.amber,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _gradesList.map((String grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(
                            grade,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGrade = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xff42153e),
                        size: 18,
                      ),
                      label: Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observații / Temă (opțional)',
                  prefixIcon: const Icon(
                    Icons.comment,
                    color: Color(0xff42153e),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
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
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff42153e),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.amber,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Salvează Nota",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
