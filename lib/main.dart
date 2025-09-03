import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'widgets/google_sign_in_widget.dart';
import 'widgets/main_menu_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honeysales',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HoneysalesHome(),
    );
  }
}

class HoneysalesHome extends StatefulWidget {
  final User? testUser;
  const HoneysalesHome({super.key, this.testUser});

  @override
  State<HoneysalesHome> createState() => _HoneysalesHomeState();
}

class _HoneysalesHomeState extends State<HoneysalesHome> {
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
