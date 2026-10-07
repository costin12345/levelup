import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const Color primaryIndigo = Color(0xff1e1b4b);
  static const Color accentPurple = Color(0xff7c3aed);
  static const Color bgColor = Color(0xfff8fafc);

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Te rugăm să introduci emailul și parola!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'student';
        bool hasAccess = userData['hasAccess'] ?? true;

        if ((role == 'student' || role == 'parent') && !hasAccess) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showSnackBar(
              'Contul tău așteaptă aprobarea din partea profesorului.',
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'A apărut o eroare la autentificare.';
      if (e.code == 'user-not-found') {
        message = 'Nu există niciun cont cu acest email.';
      } else if (e.code == 'wrong-password') {
        message = 'Parolă incorectă.';
      } else if (e.code == 'invalid-email') {
        message = 'Adresa de email este invalidă.';
      } else if (e.code == 'invalid-credential') {
        message = 'Datele de autentificare sunt incorecte.';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('Eroare: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryIndigo,
        toolbarHeight: 85,
        titleSpacing: 16,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'images/logo.jpg',
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
      body: Stack(
        children: [
          // 🚀 Cercuri decorative multiple cu nuanțe diferite de indigo/violet și mărimi variate
          // 1. Cerc mare în dreapta
          Positioned(
            top: 40,
            right: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentPurple.withOpacity(0.07),
              ),
            ),
          ),
          // 2. Cerc mediu sus-stânga
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryIndigo.withOpacity(0.04),
              ),
            ),
          ),
          // 3. Cerc mic jos-stânga
          Positioned(
            bottom: 40,
            left: 120,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentPurple.withOpacity(0.05),
              ),
            ),
          ),
          // 4. Cerc mediu jos-dreapta
          Positioned(
            bottom: -80,
            right: 180,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryIndigo.withOpacity(0.05),
              ),
            ),
          ),

          // Elemente matematice pe fundal
          Positioned(
            top: 60,
            left: 80,
            child: Text(
              "∑",
              style: TextStyle(
                fontSize: 70,
                color: primaryIndigo.withOpacity(0.04),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 100,
            child: Text(
              "∫",
              style: TextStyle(
                fontSize: 80,
                color: primaryIndigo.withOpacity(0.04),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: 120,
            child: Text(
              "π",
              style: TextStyle(
                fontSize: 60,
                color: primaryIndigo.withOpacity(0.04),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 100,
            child: Text(
              "√x",
              style: TextStyle(
                fontSize: 50,
                color: primaryIndigo.withOpacity(0.04),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Cardul central cu bula și toca
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.fromLTRB(40, 55, 40, 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: primaryIndigo.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Bine ai revenit!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primaryIndigo,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Autentifică-te pentru a continua.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Câmp Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: accentPurple,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Adresă de Email',
                            labelStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: primaryIndigo.withOpacity(0.7),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: accentPurple,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Câmp Parolă
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          cursorColor: accentPurple,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Parolă',
                            labelStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryIndigo.withOpacity(0.7),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: accentPurple,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Buton modern cu gradient
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: accentPurple,
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryIndigo, accentPurple],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentPurple.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Intră în Cont',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),

                        // Link Înregistrare
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Nu ai un cont încă?",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: accentPurple,
                              ),
                              child: const Text(
                                "Creează cont",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bula indigo cu toca ieșită din chenar
                  Positioned(
                    top: -30,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryIndigo,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: primaryIndigo.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
