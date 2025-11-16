import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thrive/screens/login_screen.dart';

import 'login_screen_test.mocks.dart';


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

  group('LoginScreen Widget Tests', () {
    testWidgets('renders background color correctly', (tester) async {
      await tester.pumpWidget( MaterialApp(home: LoginScreen()));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor,
          const Color.fromARGB(255, 219, 249, 230)); // #DBF9E6
    });

    testWidgets('renders Thrive title text', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      expect(find.text('Thrive'), findsOneWidget);
    });

    testWidgets('renders 5 animated star SVGs', (tester) async {
      await tester.pumpWidget( MaterialApp(home: LoginScreen()));
      expect(find.byType(SvgPicture), findsNWidgets(5));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SvgPicture), findsNWidgets(5)); // still visible after animation
    });

    testWidgets('renders mascot GIF', (tester) async {
      await tester.pumpWidget( MaterialApp(home: LoginScreen()));
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, 'assets/images/joey.GIF');
    });

    testWidgets('renders email and password TextFields', (tester) async {
      await tester.pumpWidget( MaterialApp(home: LoginScreen()));
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('renders Log In and Sign Up buttons', (tester) async {
      await tester.pumpWidget( MaterialApp(home: LoginScreen()));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('No account? Sign up!'), findsOneWidget);
    });

    testWidgets('Sign up button navigates to /register', (tester) async {
      bool pushedRegister = false;
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/register') pushedRegister = true;
          return MaterialPageRoute(builder: (_) => const Placeholder());
        },
      ));

      await tester.tap(find.text('No account? Sign up!'));
      await tester.pumpAndSettle();
      expect(pushedRegister, isTrue);
    });

    testWidgets('Log In button has correct color and style', (tester) async {
      await tester.pumpWidget(  MaterialApp(home: LoginScreen()));
      final logInButton =
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Log In'));

      expect(
        logInButton.style?.backgroundColor?.resolve({}),
        const Color.fromRGBO(47, 76, 45, 1),
      );

      final logInText = tester.widget<Text>(find.text('Log In'));
      expect(logInText.style?.fontWeight, FontWeight.w600);
      expect(logInText.style?.fontSize, 32);
    });

    testWidgets('column layout is scrollable and vertically centered',
        (tester) async {
      await tester.pumpWidget(  MaterialApp(home: LoginScreen()));
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

  });

  group('LoginScreen Functional Tests (mocked FirebaseAuth)', () {
    late MockFirebaseAuth mockAuth;
    late MockUserCredential mockCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockCredential = MockUserCredential();
    });
  });
}
