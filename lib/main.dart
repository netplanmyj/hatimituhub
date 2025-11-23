import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'flavor_config.dart';
import 'widgets/google_sign_in_widget.dart';
import 'widgets/main_menu_widget.dart';

void main() async {
  // Flavorの初期化
  const String flavorString = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );
  final Flavor flavor = flavorString == 'prod' ? Flavor.prod : Flavor.dev;
  FlavorConfig.initialize(flavor: flavor);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    return MaterialApp(
      title: config.isDev ? 'はちみつハブ (Dev)' : 'はちみつハブ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HatimituhubHome(),
    );
  }
}

class HatimituhubHome extends StatefulWidget {
  final User? testUser;
  const HatimituhubHome({super.key, this.testUser});

  @override
  State<HatimituhubHome> createState() => _HatimituhubHomeState();
}

class _HatimituhubHomeState extends State<HatimituhubHome> {
  final GlobalKey<GoogleSignInWidgetState> _signInKey =
      GlobalKey<GoogleSignInWidgetState>();

  @override
  Widget build(BuildContext context) {
    return GoogleSignInWidget(
      key: _signInKey,
      testUser: widget.testUser,
      childBuilder: (user) {
        return MainMenuWidget(
          user: user,
          onSignIn: () => _signInKey.currentState?.signInWithGoogle(),
          onSignOut: () => _signInKey.currentState?.signOut(),
        );
      },
    );
  }
}
