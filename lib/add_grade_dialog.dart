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

  String className = "9A";
  String groupName = "Grupa 1";
  String courseTitle = "Matematică";
  String grade = "10";
  String date =
      "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

  bool _isLoading = false;

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
      // 1. Salvăm nota în colecția 'grades'
      await FirebaseFirestore.instance.collection('grades').add({
        'studentId': _selectedStudentId,
        'studentName': _selectedStudentName ?? 'Elev',
        'studentEmail': _selectedStudentEmail ?? '',
        'className': className,
        'groupName': groupName,
        'courseTitle': courseTitle,
        'grade': grade,
        'date': date,
        'createdAt': FieldValue.serverTimestamp(),
      });

      String pushTitle = '🌟 Notă Nouă la $courseTitle';
      String pushBody =
          'Ai primit nota $grade la $className ($groupName). Data: $date';

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

      // 4. Trimitem mesajul fizic (push notification) către primul destinatar
      if (uniqueRecipients.isNotEmpty) {
        String targetUserId = uniqueRecipients.first;

        final serviceAccountCredentials =
            auth.ServiceAccountCredentials.fromJson({
              "type": "service_account",
              "project_id": "level-up-19583",
              "private_key_id": "151838f47968dcd4313994d7176c1f7cf2e69513",
              "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUoFcO7yVlsfky\nHnDJJtXw66laZ26aTXRzz7Vb7VAJ967FYnrDTEiNNWfSYx9omDXLOMCsDyxLbbJE\ncmdgOVm6RX6q7bLhpJplGdHTL7zUTDVXfJE/E/KHOb5feAtk2c1zjZdXol4gBAIR\nFa9Y/KNRUlfMLgcx+Tgkh+F08tb58hFINgK+U3zdNtpWNV8rP2owjZtRGKYKRgg+\nLG0dbMMMgc1KdvcEJE4wAWTMB2Q0p+5hOCexJP0r7VGOh+xhyiQfZFjprX2GTCpq\nSoLuRgfFp+4FzaMNpBDs8XORQLpGYmoE6dPX5EJ4Jh0lFwY/8gq80wM9AdmA80AE\nUAd3TFC3AgMBAAECggEAAnzmd+DEIxam2qIbjLxSbYa8YmKVGzjDyjpzHfe+uNci\nlDcCRmMP8u2zNiAodRdZgx66C76uXyrnQUDGGoyhPaTkMLN7pS3sC+R2SDkl8E/8\nocuYgXtGGl9Kbcs1oED3fp4jWAhTf0lnYsl1AJ64JH1I/1/HKsZb6frYYFTFFNiY\SwVIlyvIddpIKvXCLWPT8XyBBfIsOsyRQfoNbtdsoKrdfLTCMNTkcXQG7mhOpRXf\nBAYGCfh3sxRYj0V06A2KzLrfbbl5zd+8phYTrClYKVonWUGXiTTOHgKHOQOftrO/\nPjU8D3NDzff/zh8uMGecTDcR9O35jx9h3bhBk09KZQKBgQDsIBLKVEmzBs+WSgwx\/0xft/PoZ/6E7FLC1RWOmZY77pXpQRoMjQDQzJRC+YdI5yVGmlRTfulNPZE53lO7\nu2efdX9wbcnWmwpmAWWKhJyBnQao1cwWRCF1Irlj7olx3x4EXjfh5vxpIAVe8/T5\nCbb6K39W/0QedUtCDgRYTm9xbQKBgQDmhevSRjFN/jdok/J995cfnuX6bLyYazDY\nghRXAts2Pb/+qhSsggQvGUSb6x//r3y5SHZrbYsVoB1W97InzMsrtzCxT+jtocxb\n68u8EzEfU2xYW5eRwDc4M0ZIbhN1QHGKHEUigj2BWt03OW2eSvCpeBxA6VukFtwE\n8E0kwsCYMwKBgFVV3hSbU6tMydcR2chz8KEjNRYIB3b4hYx+P/UyUpZESo9rBMQG\nbYYIeYie76KMTu9uNQ2b7ysIFiUo0XAmcXOyniT+uJRDogVtecoO1RUOr+pyofhm\FQVlUETqX2f07786Yc3VkeFYPjiryBv8w9EzySiixnaPg2xS7oUPi70dAoGBALXU\nwNSVxWJNuYrl2AqAd1Xb0m+bwY9ATcEZqc2QVTUNtBm+Mpx32bEE71dFOXJHC8xi\nWfYW6/Rc3YexzXcTVNbgoqnZ7FM0oquG7KcnREH/XaC8bmvrACN2XmPXX8XG1Ugp\UGcN8FHOSFu9ErgfSIGEWlThPQXLejTzDwaGD8B9AoGBAMKMxgN+EdI1XWvR2nqT\SFXnQkEu+8HG62jakbjda2I5rNO7ozvE+YUeh8U0o+y+lEgdmvms4UIvc1RQVJ0U\npCvJ5YSUlFWlnCab+yZZBkkHihGiCGWWMDCJbdlZe++XBl2mBcna8UiurFpdtXnu\nrMhuipkeyIUYvku53bTFvmny\n-----END PRIVATE KEY-----\n",
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
    const Color accentLila = Color(0xff7c4dff);

    return AlertDialog(
      title: const Text("Adaugă Notă Nouă"),
      content: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var students = snapshot.data!.docs;
            if (students.isEmpty) {
              return const Text(
                "Nu există elevi înregistrați în baza de date.",
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Selectează Elevul",
                  ),
                  items: students.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name =
                        data['fullName'] ?? data['name'] ?? 'Elev fără nume';
                    String email = data['email'] ?? '';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      onTap: () {
                        _selectedStudentName = name;
                        _selectedStudentEmail = email;
                      },
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStudentId = val;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Clasa (ex: 9A, 10B)",
                  ),
                  controller: TextEditingController(text: className),
                  onChanged: (val) => className = val,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Grupa (ex: Grupa 1)",
                  ),
                  controller: TextEditingController(text: groupName),
                  onChanged: (val) => groupName = val,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Materie"),
                  controller: TextEditingController(text: courseTitle),
                  onChanged: (val) => courseTitle = val,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Nota (ex: 9, 10)",
                  ),
                  controller: TextEditingController(text: grade),
                  onChanged: (val) => grade = val,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Data"),
                  controller: TextEditingController(text: date),
                  onChanged: (val) => date = val,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anulează"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentLila),
          onPressed: _isLoading ? null : _saveGrade,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Salvează", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
