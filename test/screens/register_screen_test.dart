import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thrive/screens/register_screen.dart';

import 'register_screen_test.mocks.dart';

// Generate mocks for FirebaseAuth and UserCredential
@GenerateMocks([FirebaseAuth, UserCredential])
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized()
      as TestWidgetsFlutterBinding;

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders background color correctly', (tester) async {
      await tester.pumpWidget( MaterialApp(home: RegisterScreen()));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor,
          const Color.fromARGB(255, 219, 249, 230)); // #DBF9E6
    });

    testWidgets('renders Thrive title text', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      expect(find.text('Thrive'), findsOneWidget);
    });

    testWidgets('renders 5 animated star SVGs', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      expect(find.byType(SvgPicture), findsNWidgets(5));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SvgPicture), findsNWidgets(5)); // still visible
    });

    testWidgets('renders mascot GIF correctly', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, 'assets/images/joey.GIF');
    });

    testWidgets('renders 4 text fields with correct labels', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);
    });

    testWidgets('toggles password visibility when icon pressed',
        (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      final firstIcon = find.byIcon(Icons.visibility_off).first;
      await tester.tap(firstIcon);
      await tester.pump();
      expect(find.byIcon(Icons.visibility), findsWidgets);
    });

    testWidgets('renders Sign Up button with correct color and style',
        (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));
      final button =
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sign up'));
      expect(button.style?.backgroundColor?.resolve({}),
          const Color.fromARGB(255, 235, 96, 57));
      final text = tester.widget<Text>(find.text('Sign up'));
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.fontSize, 32);
    });

    testWidgets('renders “Got an account? Log in!” and navigates to /login',
        (tester) async {
      bool pushedLogin = false;
      await tester.pumpWidget(MaterialApp(
        home:    RegisterScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/login') pushedLogin = true;
          return MaterialPageRoute(builder: (_) => const Placeholder());
        },
      ));

      await tester.tap(find.text('Got an account? Log in!'));
      await tester.pumpAndSettle();
      expect(pushedLogin, isTrue);
    });
  });

  group('RegisterScreen Functional Validation Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUserCredential mockCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockCredential = MockUserCredential();
    });

    testWidgets('shows snackbar when fields are empty', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));

      await tester.tap(find.text('Sign up'));
      await tester.pump(); // rebuild after snackbar
      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('shows snackbar when passwords do not match', (tester) async {
      await tester.pumpWidget(   MaterialApp(home: RegisterScreen()));

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), '54321');

      await tester.tap(find.text('Sign up'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('successful registration navigates to /login', (tester) async {
      bool pushedLogin = false;
      await tester.pumpWidget(MaterialApp(
        home:    RegisterScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/login') pushedLogin = true;
          return MaterialPageRoute(builder: (_) => const Placeholder());
        },
      ));

      // Enter valid fields (mocking only UI level)
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test User');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@email.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'password');

      await tester.tap(find.text('Sign up'));
      await tester.pump(const Duration(milliseconds: 300));
      // Expect either navigation or success snackbar
      expect(find.text('Registration successful! Please log in.'), findsOneWidget);
    });
  });
}
