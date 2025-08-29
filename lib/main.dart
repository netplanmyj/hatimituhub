import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'order_input.dart';
import 'order_list_page.dart';
import 'product_master_page.dart';
import 'customer_master_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      home: const GoogleSignInDemo(),
    );
  }
}

class GoogleSignInDemo extends StatefulWidget {
  const GoogleSignInDemo({super.key});

  @override
  State<GoogleSignInDemo> createState() => _GoogleSignInDemoState();
}

class _GoogleSignInDemoState extends State<GoogleSignInDemo> {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Googleサインインデモ')),
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: signInWithGoogle,
                child: const Text('Googleでログイン'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user!.photoURL ?? ''),
                    radius: 40,
                  ),
                  const SizedBox(height: 16),
                  Text('ログイン中: ${user!.displayName ?? ''}'),
                  Text('メール: ${user!.email ?? ''}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: signOut,
                    child: const Text('ログアウト'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.list_alt),
                        tooltip: '注文一覧',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrderListPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        tooltip: '注文入力',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrderInputPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.inventory),
                        tooltip: '商品管理',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProductMasterPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.people),
                        tooltip: '顧客管理',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CustomerMasterPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  User? user;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // キャンセル時
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      setState(() {
        user = userCredential.user;
      });
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
}
