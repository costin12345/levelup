import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class AddGradeDialog extends StatefulWidget {
  const AddGradeDialog({super.key});

  @override
  State<AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<AddGradeDialog> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentEmail;

  // Valori predefinite pentru selecție
  String _selectedClass = "Clasa a IX-a";
  String _selectedCourse = "Matematică";
  String _selectedGrade = "10";

  final TextEditingController _commentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Listele fixe cerute
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

      // 1. Salvăm nota în colecția 'grades'
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

      String pushTitle = '🌟 Notă Nouă la $_selectedCourse';
      String pushBody =
          'Ai primit nota $_selectedGrade la $_selectedClass. Data: $formattedDate';

      // 2. Colectăm ID-urile destinatarilor (Elevul + Părinții asociați)
      Set<String> recipientIds = {_selectedStudentId!};

      if (_selectedStudentEmail != null && _selectedStudentEmail!.isNotEmpty) {
        var parentQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'parent')
            .where('childEmail', isEqualTo: _selectedStudentEmail)
            .get();

        for (var parentDoc in parentQuery.docs) {
          recipientIds.add(parentDoc.id);
        }
      }

      List<String> uniqueRecipients = recipientIds.toList();

      // 3. Salvăm în Firestore pentru TOȚI destinatarii (istoric + clopoțel + badge)
      for (String userId in uniqueRecipients) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': pushTitle,
          'body': pushBody,
          'type': 'grade',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Trimitem mesajul fizic (push notification) DOAR CĂTRE PRIMUL UTILIZATOR din listă
      // Astfel, baza de date știe de amândoi, dar telefonul primește un singur semnal vizual.
      if (uniqueRecipients.isNotEmpty) {
        String targetUserId = uniqueRecipients.first;

        final serviceAccountCredentials =
            auth.ServiceAccountCredentials.fromJson({
              "type": "service_account",
              "project_id": "level-up-19583",
              "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
              "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\nSwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\nSFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
              "client_email": "firebase-adminsdk-fbsvc@level-up-19583.iam.gserviceaccount.com",
              "client_id": "112777526185284576732",
              "auth_uri": "https://accounts.google.com/o/oauth2/auth",
              "token_uri": "https://oauth2.googleapis.com/token",
              "auth_provider_x509_cert_url":
                  "https://www.googleapis.com/oauth2/v1/certs",
              "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40level-up-19583.iam.gserviceaccount.com",
              "universe_domain": "googleapis.com",
            });

        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final client = await auth.clientViaServiceAccount(
          serviceAccountCredentials,
          scopes,
        );

        final String fcmV1Url =
            'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

        final unreadSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: targetUserId)
            .where('isRead', isEqualTo: false)
            .get();
        int unreadCount = unreadSnap.docs.length;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();

        if (userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = uData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await client.post(
              Uri.parse(fcmV1Url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': {
                  'token': fcmToken,
                  'notification': {'title': pushTitle, 'body': pushBody},
                  'android': {
                    'priority': 'HIGH',
                    'notification': {'sound': 'default'},
                  },
                  'apns': {
                    'headers': {
                      'apns-priority': '10',
                      'apns-push-type': 'alert',
                    },
                    'payload': {
                      'aps': {'sound': 'default', 'badge': unreadCount},
                    },
                  },
                  'data': {
                    'notificationType': 'grade',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );
          }
        }
        client.close();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Nota a fost adăugată și notificarea trimisă!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Eroare la trimiterea notificării FCM v1 pentru note: $e");
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
              // 1. Selector Clasa
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

              // 2. Selector Nume Elev
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

              // 3. Selector Materie
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

              // 4. Nota & Calendar
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

              // 5. Observații / Temă
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

/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class AddGradeDialog extends StatefulWidget {
  final bool isAbsence;
  const AddGradeDialog({super.key, required this.isAbsence});

  @override
  State<AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<AddGradeDialog> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentEmail;

  // Valori predefinite pentru selecție
  String _selectedClass = "Clasa a IX-a";
  String _selectedGroup = "Grupa A"; // NOU: Valoare predefinită pentru grupă
  String _selectedCourse = "Matematică";
  String _selectedGrade = "10";

  final TextEditingController _commentController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool _isSimulation = false;

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

  // Listă orientativă de grupe (poate fi adaptată sau scrisă liber)
  final List<String> _groupsList = [
    "Grupa A",
    "Grupa B",
    "Grupa C",
    "5A",
    "5B",
    "9A",
    "9B",
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

      // 1. Salvăm nota în colecția 'grades' incluzând și 'groupName'
      await FirebaseFirestore.instance.collection('grades').add({
        'studentId': _selectedStudentId,
        'studentName': _selectedStudentName ?? 'Elev',
        'studentEmail': _selectedStudentEmail ?? '',
        'className': _selectedClass,
        'groupName': _selectedGroup, // <--- Salvăm grupa selectată
        'courseTitle': _selectedCourse,
        'grade': _selectedGrade,
        'comment': _commentController.text.trim(),
        'date': formattedDate,
        'isSimulation': _isSimulation,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String gradeTypeLabel = _isSimulation
          ? 'Simulare / Evaluare'
          : 'Notă Nouă';
      String pushTitle = '🌟 $gradeTypeLabel la $_selectedCourse';
      String pushBody =
          'Ai primit nota $_selectedGrade ($gradeTypeLabel) la $_selectedClass ($_selectedGroup). Data: $formattedDate';

      Set<String> recipientIds = {_selectedStudentId!};

      if (_selectedStudentEmail != null && _selectedStudentEmail!.isNotEmpty) {
        var parentQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'parent')
            .where('childEmail', isEqualTo: _selectedStudentEmail)
            .get();

        for (var parentDoc in parentQuery.docs) {
          recipientIds.add(parentDoc.id);
        }
      }

      List<String> uniqueRecipients = recipientIds.toList();

      for (String userId in uniqueRecipients) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': pushTitle,
          'body': pushBody,
          'type': 'grade',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (uniqueRecipients.isNotEmpty) {
        String targetUserId = uniqueRecipients.first;

        final serviceAccountCredentials =
            auth.ServiceAccountCredentials.fromJson({
              "type": "service_account",
              "project_id": "level-up-19583",
              "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
              "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\nSwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
              "client_email": "firebase-adminsdk-fbsvc@level-up-19583.iam.gserviceaccount.com",
              "client_id": "112777526185284576732",
              "auth_uri": "https://accounts.google.com/o/oauth2/auth",
              "token_uri": "https://oauth2.googleapis.com/token",
              "auth_provider_x509_cert_url":
                  "https://www.googleapis.com/oauth2/v1/certs",
              "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40level-up-19583.iam.gserviceaccount.com",
              "universe_domain": "googleapis.com",
            });

        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final client = await auth.clientViaServiceAccount(
          serviceAccountCredentials,
          scopes,
        );

        final String fcmV1Url =
            'https://fcm.googleapis.com/v1/projects/level-up-19583/messages:send';

        final unreadSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: targetUserId)
            .where('isRead', isEqualTo: false)
            .get();
        int unreadCount = unreadSnap.docs.length;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();

        if (userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = uData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await client.post(
              Uri.parse(fcmV1Url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': {
                  'token': fcmToken,
                  'notification': {'title': pushTitle, 'body': pushBody},
                  'android': {
                    'priority': 'HIGH',
                    'notification': {'sound': 'default'},
                  },
                  'apns': {
                    'headers': {
                      'apns-priority': '10',
                      'apns-push-type': 'alert',
                    },
                    'payload': {
                      'aps': {'sound': 'default', 'badge': unreadCount},
                    },
                  },
                  'data': {
                    'notificationType': 'grade',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              }),
            );
          }
        }
        client.close();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Nota a fost adăugată și notificarea trimisă!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Eroare la trimiterea notificării FCM v1 pentru note: $e");
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
              // 1. Selector Clasa
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

              // 🚀 1.1. NOU: Selector Grupa (ex: 5A, 5B, Grupa A etc.)
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: InputDecoration(
                  labelText: 'Selectează Grupa',
                  prefixIcon: const Icon(Icons.group, color: Color(0xff42153e)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _groupsList.map((String groupName) {
                  return DropdownMenuItem<String>(
                    value: groupName,
                    child: Text(
                      groupName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedGroup = val!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. Selector Nume Elev
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

              // 3. Selector Materie
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

              // 4. Nota & Calendar
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

              // 5. Observații / Temă
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
              const SizedBox(height: 16),

              // 6. Checkbox pentru Simulare / Evaluare
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSimulation
                        ? Colors.orange.shade400
                        : Colors.grey.shade300,
                    width: _isSimulation ? 2 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    "Aceasta este o Simulare / Evaluare",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff42153e),
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "Va apărea pe scara specială de simulări",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  secondary: Icon(
                    Icons.military_tech,
                    color: _isSimulation ? Colors.orange : Colors.grey,
                    size: 26,
                  ),
                  activeColor: Colors.orange,
                  value: _isSimulation,
                  onChanged: (bool? value) {
                    setState(() {
                      _isSimulation = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
*/
