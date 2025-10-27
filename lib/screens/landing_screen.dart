import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: Color.fromARGB(255, 217, 251, 229),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                          // top: ,
                          fontSize: 99,
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
                height: 300,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 270,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(47, 76, 45, 1),
                    textStyle: const TextStyle(fontSize: 32),
                  ),
                  child: Text(
                    'Log In',
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 270,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 96, 57),
                    textStyle: const TextStyle(fontSize: 32),
                  ),
                  child: Text(
                    'Sign up',
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
