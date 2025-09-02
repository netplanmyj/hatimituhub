import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'order_input.dart';
import 'order_list_page.dart';
import 'product_master_page.dart';
import 'customer_master_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'initial_setup_page.dart';
import 'customer_type_master_page.dart';
import 'product_type_master_page.dart';
import 'product_category_master_page.dart';
import 'tax_master_page.dart';

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
  final User? testUser;
  const GoogleSignInDemo({super.key, this.testUser});

  @override
  State<GoogleSignInDemo> createState() => _GoogleSignInDemoState();
}

class _GoogleSignInDemoState extends State<GoogleSignInDemo> {
  User? user;

  void showLoginRequiredSnackBar(BuildContext context, User? user) {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.testUser != null) {
      user = widget.testUser;
    }
  }

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
      appBar: AppBar(
        title: const Text('Googleサインインデモ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.percent),
                        title: const Text('税率マスタ管理'),
                        onTap: () {
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaxMasterPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.data_usage),
                        title: const Text('初期セットアップ'),
                        onTap: () {
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InitialSetupPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('顧客区分管理'),
                        onTap: () {
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerTypeMasterPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.label),
                        title: const Text('商品区分管理'),
                        onTap: () {
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductTypeMasterPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list),
                        title: const Text('商品種別管理'),
                        onTap: () {
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductCategoryMasterPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
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
                    backgroundImage:
                        (user!.photoURL != null && user!.photoURL!.isNotEmpty)
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    radius: 40,
                    child: (user!.photoURL == null || user!.photoURL!.isEmpty)
                        ? const Icon(Icons.person, size: 40)
                        : null,
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
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
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
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
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
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
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
                          if (user == null) {
                            showLoginRequiredSnackBar(context, user);
                            return;
                          }
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
