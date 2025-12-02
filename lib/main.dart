import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'flavor_config.dart';
import 'widgets/main_menu_widget.dart';
import 'services/auth_service.dart';

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
      home: const HatimituhubHome.production(),
    );
  }
}

class HatimituhubHome extends StatefulWidget {
  final User? testUser;
  final bool isTestMode;
  final AuthService? authService; // テスト用

  const HatimituhubHome({super.key, this.testUser, this.authService})
    : isTestMode = true;

  const HatimituhubHome.production({super.key})
    : testUser = null,
      authService = null,
      isTestMode = false;

  @override
  State<HatimituhubHome> createState() => _HatimituhubHomeState();
}

class _HatimituhubHomeState extends State<HatimituhubHome> {
  User? _currentUser;

  @override
  Widget build(BuildContext context) {
    // テストモードの場合はtestUserを直接使用
    if (widget.isTestMode) {
      return MainMenuWidget(
        user: widget.testUser,
        authService: widget.authService,
        onSignIn: () {},
        onSignOut: () async {},
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // ユーザーが実質的に変わっていない場合は、既存のWidgetを再利用
        final bool userChanged = _currentUser?.uid != user?.uid;
        if (userChanged) {
          _currentUser = user;
        }

        return MainMenuWidget(
          key: ValueKey(_currentUser?.uid), // uidが同じなら同じインスタンスを維持
          user: user,
          onSignIn: () {}, // GoogleSignInWidgetを使わないため空実装
          onSignOut: () async {
            final authService = AuthService();
            await authService.signOut();
          },
        );
      },
    );
  }
}
