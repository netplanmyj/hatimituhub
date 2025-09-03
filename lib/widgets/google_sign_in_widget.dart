import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInWidget extends StatefulWidget {
  final User? testUser;
  final Widget Function(User? user) childBuilder;

  const GoogleSignInWidget({
    super.key,
    this.testUser,
    required this.childBuilder,
  });

  @override
  State<GoogleSignInWidget> createState() => GoogleSignInWidgetState();
}

class GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  User? user;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    user = widget.testUser; // testUserが設定されていればそれを使用（nullでもOK）
    _initializeGoogleSignIn();
  }

  bool _isFlutterTest() {
    // Flutter Test環境かどうかを判定する複数の方法
    try {
      // WidgetsBindingのタイプをチェック
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      if (bindingType.contains('Test')) return true;

      // 環境変数をチェック
      if (const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)) {
        return true;
      }

      // 開発環境でのテスト実行をチェック
      return kDebugMode && bindingType.contains('AutomatedTest');
    } catch (e) {
      // エラーが発生した場合は安全側に倒してテスト環境として扱う
      return true;
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    // テスト環境では初期化をスキップ
    if (_isFlutterTest()) {
      _isInitialized = true;
      return;
    }

    try {
      await GoogleSignIn.instance.initialize();
      _isInitialized = true;
      // 軽量認証を試行
      await _attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  Future<void> _attemptLightweightAuthentication() async {
    if (!_isInitialized) return;

    try {
      final result = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (result is Future) {
        await result;
      }
      // authenticationEventsストリームを監視
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            setState(() {
              // Firebase Authと連携する場合は別途処理
              // user = event.user; // これはGoogleSignInUserなので、Firebase Userに変換が必要
            });
          }
        },
        onError: (error) {
          debugPrint('Authentication event error: $error');
        },
      );
    } catch (e) {
      debugPrint('Lightweight authentication failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In is not initialized')),
      );
      return;
    }

    try {
      // 認証実行
      final googleUser = await GoogleSignIn.instance.authenticate();

      // Firebase Auth連携にはIDトークンのみを使用
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      setState(() {
        user = userCredential.user;
      });
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      String message = 'Sign-in failed';
      if (e.code == GoogleSignInExceptionCode.canceled) {
        message = 'Sign-in was canceled';
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('サインインエラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ログインエラー'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (_isInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(user);
  }
}
