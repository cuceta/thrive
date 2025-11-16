import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thrive/screens/landing_screen.dart';

void main() {
  // Configure a larger test screen once per suite
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

  group('LandingScreen Widget Tests', () {
    testWidgets('renders Thrive title text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      expect(find.text('Thrive'), findsOneWidget);
    });

    testWidgets('renders both Log In and Sign Up buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('navigates to /login when Log In tapped', (WidgetTester tester) async {
      bool pushedLogin = false;

      await tester.pumpWidget(MaterialApp(
        home: const LandingScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/login') pushedLogin = true;
          return MaterialPageRoute(builder: (_) => const Placeholder());
        },
      ));

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(pushedLogin, isTrue);
    });


    testWidgets('background color matches design', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor,
          const Color.fromARGB(255, 217, 251, 229)); // #D9FBE5
    });

    testWidgets('renders 5 star SVGs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      expect(find.byType(SvgPicture), findsNWidgets(5));
    });

    testWidgets('renders mascot GIF (Joey)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      final asset = imageWidget.image as AssetImage;
      expect(asset.assetName, 'assets/images/joey.GIF');
    });

    testWidgets('navigates to /register when Sign up tapped', (WidgetTester tester) async {
      bool pushedRegister = false;

      await tester.pumpWidget(MaterialApp(
        home: const LandingScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/register') pushedRegister = true;
          return MaterialPageRoute(builder: (_) => const Placeholder());
        },
      ));

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(pushedRegister, isTrue);
    });

    testWidgets('buttons have correct colors and text styles',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

      final logInButton =
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Log In'));
      final signUpButton =
          tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sign up'));

      // Background colors
      expect(logInButton.style?.backgroundColor?.resolve({}),
          const Color.fromRGBO(47, 76, 45, 1)); // #2F4C2D
      expect(signUpButton.style?.backgroundColor?.resolve({}),
          const Color.fromARGB(255, 235, 96, 57)); // #EB6039

      // Font weights
      final logInText = tester.widget<Text>(find.text('Log In'));
      final signUpText = tester.widget<Text>(find.text('Sign up'));
      expect(logInText.style?.fontWeight, FontWeight.w600);
      expect(signUpText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('animation controller runs without throwing errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

      // Let animation run for a few frames
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Still renders 5 stars → animation stable
      expect(find.byType(SvgPicture), findsNWidgets(5));
    });

    testWidgets('column layout is vertically centered',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
