import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthWrapper will automatically navigate to HomeScreen
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  late final AnimationController _controller;

  // Fixed positions & sizes of stars
  final List<Offset> starPositions = [
    Offset(265, 35),
    Offset(0, 0),
    Offset(145, 85),
    Offset(45, 65),
    Offset(100, 30),
  ];
  final List<double> starSizes = [18, 30, 20, 15, 23];

  @override
  void initState() {
    super.initState();

    // Controller for scaling animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double textAreaWidth = 300;
    const double textAreaHeight = 120;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 219, 249, 230),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 110),
              SizedBox(
                width: textAreaWidth,
                height: textAreaHeight,
                child: Stack(
                  children: [
                    // Sparkling stars
                    ...List.generate(starPositions.length, (index) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          double scale = 0.8 + _controller.value * 0.4;
                          return Positioned(
                            left: starPositions[index].dx,
                            top: starPositions[index].dy,
                            child: Transform.scale(
                              scale: scale,
                              child: SvgPicture.asset(
                                'assets/images/star.svg',
                                width: starSizes[index],
                                height: starSizes[index],
                                color: const Color.fromARGB(255, 236, 165, 84),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    // Text
                    Center(
                      child: Text(
                        "Thrive",
                        style: GoogleFonts.fredoka(
                          fontSize: 96,
                          color: const Color.fromARGB(255, 235, 96, 57),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Image.asset(
                'assets/images/joey.GIF',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              ),
              
              // const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 270,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 235, 96, 57),
                          textStyle: const TextStyle(fontSize: 32),
                        ),
                        child: Text(
                          "Sign up",
                          style: GoogleFonts.fredoka(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(
                  "Got an account? Log in!",
                  style: GoogleFonts.fredoka(
                    color: const Color.fromRGBO(47, 76, 45, 1),
                    // decoration: TextDecoration.underline,
                  ),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
