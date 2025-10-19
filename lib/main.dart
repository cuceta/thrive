import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thrive/screens/home_screen.dart';
import 'package:thrive/screens/login_screen.dart';
import 'package:thrive/screens/register_screen.dart';
import 'package:thrive/screens/landing_screen.dart';
import 'package:thrive/screens/Mood.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint("Firebase init failed: $e");
    debugPrint("$stack");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thrive',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 49, 80, 47),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LandingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/mood': (context) => const Mood(),
      },
    );
  }
}
