import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddGradeDialog extends StatefulWidget {
  const AddGradeDialog({super.key});

  @override
  State<AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<AddGradeDialog> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentEmail;

  String _className = "9A";
  String _groupName = "Grupa A";
  String _courseTitle = "Matematică";
  String _grade = "10";
  String _sessionNumber = "Ședința 1";
  String _homeworkStatus =
      "efectuata"; // 'efectuata', 'partiala', 'neefectuata'
  String _paymentStatus = "neplatita"; // 'platita', 'neplatita'
  String _feedback = "";

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryIndigo = Color(0xff1e1b4b);
    const Color accentLila = Color(0xff7c4dff);

    return AlertDialog(
      title: const Text(
        "Adaugă Notă, Ședință & Plată",
        style: TextStyle(color: primaryIndigo, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
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

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    onChanged: (val) =>
                        setState(() => _selectedStudentId = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Clasa (ex: 9A)",
                          ),
                          controller: TextEditingController(text: _className),
                          onChanged: (val) => _className = val,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: "Grupa"),
                          controller: TextEditingController(text: _groupName),
                          onChanged: (val) => _groupName = val,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Materie",
                          ),
                          controller: TextEditingController(text: _courseTitle),
                          onChanged: (val) => _courseTitle = val,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Ședința (ex: Ședința 12)",
                          ),
                          controller: TextEditingController(
                            text: _sessionNumber,
                          ),
                          onChanged: (val) => _sessionNumber = val,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Nota la Test (1-10)",
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _grade),
                    onChanged: (val) => _grade = val,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Status Temă Acasă:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: primaryIndigo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _homeworkStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'efectuata',
                        child: Text("🟢 Efectuată complet"),
                      ),
                      DropdownMenuItem(
                        value: 'partiala',
                        child: Text("🟡 Efectuată parțial"),
                      ),
                      DropdownMenuItem(
                        value: 'neefectuata',
                        child: Text("🔴 Lipsă temă / Neefectuată"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _homeworkStatus = val!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Status Plată Ședință:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: primaryIndigo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _paymentStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'platita',
                        child: Text("💵 Ședință Plătită"),
                      ),
                      DropdownMenuItem(
                        value: 'neplatita',
                        child: Text("⏳ Ședință Neplătită"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _paymentStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Feedback / Observații pentru părinte",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (val) => _feedback = val,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anulează"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentLila),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_selectedStudentId == null ||
                      _selectedStudentName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Te rog selectează elevul!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    String currentDate =
                        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

                    await FirebaseFirestore.instance.collection('grades').add({
                      'studentId': _selectedStudentId,
                      'studentName': _selectedStudentName,
                      'studentEmail': _selectedStudentEmail ?? '',
                      'className': _className,
                      'groupName': _groupName,
                      'courseTitle': _courseTitle,
                      'grade': _grade,
                      'sessionNumber': _sessionNumber,
                      'homeworkStatus': _homeworkStatus,
                      'paymentStatus': _paymentStatus,
                      'feedback': _feedback,
                      'date': currentDate,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Datele ședinței au fost salvate cu succes!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Eroare la salvare: $e");
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
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
