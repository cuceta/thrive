import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thrive/screens/home_screen.dart';
import 'firebase_options.dart';

// import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(MyApp());
  } catch (e, stack) {
    debugPrint("Firebase init failed: $e");
    debugPrint("$stack");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',

      theme: ThemeData(
        useMaterial3: true,
        // canvasColor: Color.fromARGB(255, 219, 249, 230),

        colorSchemeSeed: const Color.fromARGB(255, 49, 80, 47),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // '/': (context) => AuthWrapper(), // <- check login state here
        '/': (context) => LandingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
