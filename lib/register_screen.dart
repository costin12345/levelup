import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
//import 'package0:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'student';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Te rugăm să completezi toate câmpurile!');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Parolele introduse nu se potrivesc!');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Parola trebuie să aibă cel puțin 6 caractere!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Creare cont în Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 2. Salvare profil în Firestore (Implicit FĂRĂ ACCES 'hasAccess: false')
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': name,
        'email': email,
        'role': _selectedRole,
        'hasAccess': false, // Se aprobă manual din consola Firebase sau din panoul profesorului
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Intrarea în aplicație
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'A apărut o eroare la înregistrare.');
    } catch (e) {
      _showSnackBar('Eroare: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff42153e),
        toolbarHeight: 85,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'images/logo.png',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LEVEL UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "YOUR GRADES",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff42153e).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Creează un Cont Nou",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff42153e),
                  ),
                ),
                const SizedBox(height: 20), // Spațiu sub titlu

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'student',
                      label: Text('Sunt Elev'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: 'teacher',
                      label: Text('Sunt Profesor'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (newSelection) =>
                      setState(() => _selectedRole = newSelection.first),
                ),
                const SizedBox(height: 20), // Spațiu sub selectorul de rol

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nume și Prenume',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Spațiu între Nume și Email

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Adresă de Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Spațiu între Email și Parolă

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Parolă',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xff42153e),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ), // Spațiu între Parolă și Confirmare Parolă

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmă Parola',
                    prefixIcon: const Icon(
                      Icons.lock_reset,
                      color: Color(0xff42153e),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 28), // Spațiu înainte de buton

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff42153e),
                        ),
                      )
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff42153e),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Creează Contul',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                // --- AICI PUI NOUL SIZEDBOX ȘI ROW-UL PENTRU LOGIN ---
                const SizedBox(
                  height: 16,
                ), // Spațiu între Buton și textul de Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Ai deja un cont?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Autentifică-te",
                        style: TextStyle(
                          color: Color(0xff42153e),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'login_screen.dart';
// import 'main.dart';
//
// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});
//
//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//
//   String _selectedRole = 'student';
//   bool _isPasswordVisible = false;
//   bool _isLoading = false;
//
//   static const Color primaryIndigo = Color(0xff1e1b4b);
//   static const Color accentPurple = Color(0xff7c3aed);
//   static const Color bgColor = Color(
//     0xfff8fafc,
//   ); // Fundalul unitar din aplicație
//
//   Future<void> _register() async {
//     String name = _nameController.text.trim();
//     String email = _emailController.text.trim();
//     String password = _passwordController.text;
//     String confirmPassword = _confirmPasswordController.text;
//
//     if (name.isEmpty ||
//         email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty) {
//       _showSnackBar('Te rugăm să completezi toate câmpurile!');
//       return;
//     }
//
//     if (password != confirmPassword) {
//       _showSnackBar('Parolele introduse nu se potrivesc!');
//       return;
//     }
//
//     if (password.length < 6) {
//       _showSnackBar('Parola trebuie să aibă cel puțin 6 caractere!');
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       // 1. Creare cont în Firebase Auth
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);
//
//       String uid = userCredential.user!.uid;
//
//       // 2. Salvare profil în Firestore (Elevii și Părinții au nevoie de aprobare prin hasAccess: false)
//       await FirebaseFirestore.instance.collection('users').doc(uid).set({
//         'uid': uid,
//         'fullName': name,
//         'email': email,
//         'role': _selectedRole,
//         'hasAccess': _selectedRole == 'teacher' ? true : false,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//
//       // 3. 🚀 TRIMITERE NOTIFICARE CĂTRE PROFESORI (Dacă e elev sau părinte în așteptare)
//       if (_selectedRole != 'teacher') {
//         // Găsim toți profesorii din sistem pentru a le trimite notificare
//         var teachersSnap = await FirebaseFirestore.instance
//             .collection('users')
//             .where('role', isEqualTo: 'teacher')
//             .get();
//
//         for (var teacherDoc in teachersSnap.docs) {
//           String teacherId = teacherDoc.id;
//
//           await FirebaseFirestore.instance.collection('notifications').add({
//             'userId': teacherId,
//             'title': 'Cont nou în așteptare',
//             'body':
//                 'Utilizatorul $name ($email) s-a înregistrat ca $_selectedRole și așteaptă aprobare.',
//             'type': 'user_registration',
//             'isRead': false,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }
//       }
//
//       if (!mounted) return;
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const MainScreen()),
//       );
//     } on FirebaseAuthException catch (e) {
//       _showSnackBar(e.message ?? 'A apărut o eroare la înregistrare.');
//     } catch (e) {
//       _showSnackBar('Eroare: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   void _showSnackBar(String message, {bool isError = true}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: primaryIndigo,
//         toolbarHeight: 85,
//         titleSpacing: 16,
//         elevation: 0,
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Image.asset(
//                 'images/logo.jpg',
//                 height: 48,
//                 fit: BoxFit.contain,
//               ),
//             ),
//             const SizedBox(width: 14),
//             const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   "LEVEL UP",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//                 Text(
//                   "YOUR GRADES",
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       body: Stack(
//         children: [
//           // 🚀 Cercuri decorative multiple în fundal (exact ca la Login)
//           Positioned(
//             top: 40,
//             right: -100,
//             child: Container(
//               width: 420,
//               height: 420,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: accentPurple.withOpacity(0.07),
//               ),
//             ),
//           ),
//           Positioned(
//             top: -60,
//             left: -60,
//             child: Container(
//               width: 250,
//               height: 250,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: primaryIndigo.withOpacity(0.04),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 40,
//             left: 120,
//             child: Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: accentPurple.withOpacity(0.05),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -80,
//             right: 180,
//             child: Container(
//               width: 220,
//               height: 220,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: primaryIndigo.withOpacity(0.05),
//               ),
//             ),
//           ),
//
//           // Simboluri matematice pe fundal
//           Positioned(
//             top: 60,
//             left: 80,
//             child: Text(
//               "∑",
//               style: TextStyle(
//                 fontSize: 70,
//                 color: primaryIndigo.withOpacity(0.04),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 80,
//             right: 100,
//             child: Text(
//               "∫",
//               style: TextStyle(
//                 fontSize: 80,
//                 color: primaryIndigo.withOpacity(0.04),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Positioned(
//             top: 150,
//             right: 120,
//             child: Text(
//               "π",
//               style: TextStyle(
//                 fontSize: 60,
//                 color: primaryIndigo.withOpacity(0.04),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 120,
//             left: 100,
//             child: Text(
//               "√x",
//               style: TextStyle(
//                 fontSize: 50,
//                 color: primaryIndigo.withOpacity(0.04),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//
//           // Cardul central cu bula și toca
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 24.0,
//                 vertical: 40.0,
//               ),
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 alignment: Alignment.topCenter,
//                 children: [
//                   Container(
//                     constraints: const BoxConstraints(maxWidth: 440),
//                     padding: const EdgeInsets.fromLTRB(40, 55, 40, 40),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(28),
//                       border: Border.all(color: Colors.grey.shade100, width: 1),
//                       boxShadow: [
//                         BoxShadow(
//                           color: primaryIndigo.withOpacity(0.08),
//                           blurRadius: 40,
//                           offset: const Offset(0, 20),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const Text(
//                           "Creează un Cont Nou",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.w900,
//                             color: primaryIndigo,
//                             letterSpacing: -0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "Completează datele pentru a te înregistra.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         const SizedBox(height: 28),
//
//                         // Selector de Rol modern
//                         DropdownButtonFormField<String>(
//                           value: _selectedRole,
//                           dropdownColor: Colors.white,
//                           decoration: InputDecoration(
//                             labelText: 'Tip Utilizator',
//                             labelStyle: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 13,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.badge_outlined,
//                               color: primaryIndigo.withOpacity(0.7),
//                               size: 20,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xfff8fafc),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: const BorderSide(
//                                 color: accentPurple,
//                                 width: 2,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                           items: const [
//                             DropdownMenuItem(
//                               value: 'student',
//                               child: Text('Elev'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'parent',
//                               child: Text('Părinte'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'teacher',
//                               child: Text('Profesor'),
//                             ),
//                           ],
//                           onChanged: (val) {
//                             if (val != null)
//                               setState(() => _selectedRole = val);
//                           },
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Nume și Prenume
//                         TextField(
//                           controller: _nameController,
//                           cursorColor: accentPurple,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Nume și Prenume',
//                             labelStyle: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 13,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.person_outline,
//                               color: primaryIndigo.withOpacity(0.7),
//                               size: 20,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xfff8fafc),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: const BorderSide(
//                                 color: accentPurple,
//                                 width: 2,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Email
//                         TextField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           cursorColor: accentPurple,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Adresă de Email',
//                             labelStyle: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 13,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.email_outlined,
//                               color: primaryIndigo.withOpacity(0.7),
//                               size: 20,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xfff8fafc),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: const BorderSide(
//                                 color: accentPurple,
//                                 width: 2,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Parolă
//                         TextField(
//                           controller: _passwordController,
//                           obscureText: !_isPasswordVisible,
//                           cursorColor: accentPurple,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Parolă',
//                             labelStyle: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 13,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.lock_outline,
//                               color: primaryIndigo.withOpacity(0.7),
//                               size: 20,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _isPasswordVisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: Colors.grey.shade400,
//                                 size: 20,
//                               ),
//                               onPressed: () => setState(
//                                 () => _isPasswordVisible = !_isPasswordVisible,
//                               ),
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xfff8fafc),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: const BorderSide(
//                                 color: accentPurple,
//                                 width: 2,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Confirmare Parolă
//                         TextField(
//                           controller: _confirmPasswordController,
//                           obscureText: !_isPasswordVisible,
//                           cursorColor: accentPurple,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Confirmă Parola',
//                             labelStyle: TextStyle(
//                               color: Colors.grey.shade500,
//                               fontSize: 13,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.lock_reset,
//                               color: primaryIndigo.withOpacity(0.7),
//                               size: 20,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xfff8fafc),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: const BorderSide(
//                                 color: accentPurple,
//                                 width: 2,
//                               ),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 28),
//
//                         // Buton Înregistrare cu gradient
//                         _isLoading
//                             ? const Center(
//                                 child: CircularProgressIndicator(
//                                   color: accentPurple,
//                                 ),
//                               )
//                             : DecoratedBox(
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     colors: [primaryIndigo, accentPurple],
//                                     begin: Alignment.centerLeft,
//                                     end: Alignment.centerRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(14),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: accentPurple.withOpacity(0.3),
//                                       blurRadius: 15,
//                                       offset: const Offset(0, 8),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ElevatedButton(
//                                   onPressed: _register,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.transparent,
//                                     foregroundColor: Colors.white,
//                                     shadowColor: Colors.transparent,
//                                     minimumSize: const Size.fromHeight(50),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                     ),
//                                   ),
//                                   child: const Text(
//                                     'Creează Contul',
//                                     style: TextStyle(
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.bold,
//                                       letterSpacing: 0.5,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                         const SizedBox(height: 24),
//
//                         // Link către Login
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               "Ai deja un cont?",
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => const LoginScreen(),
//                                   ),
//                                 );
//                               },
//                               style: TextButton.styleFrom(
//                                 foregroundColor: accentPurple,
//                               ),
//                               child: const Text(
//                                 "Autentifică-te",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Bula indigo cu toca ieșită din chenar
//                   Positioned(
//                     top: -30,
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: primaryIndigo,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: bgColor, width: 4),
//                         boxShadow: [
//                           BoxShadow(
//                             color: primaryIndigo.withOpacity(0.2),
//                             blurRadius: 12,
//                             offset: const Offset(0, 6),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.school,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
