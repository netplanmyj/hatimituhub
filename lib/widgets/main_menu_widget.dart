import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../order_input.dart';
import '../order_list_page.dart';
import '../product_master_page.dart';
import '../customer_master_page.dart';
import '../initial_setup_page.dart';
import '../customer_type_master_page.dart';
import '../product_type_master_page.dart';
import '../product_category_master_page.dart';
import '../tax_master_page.dart';
import '../claimant_master_page.dart';
import '../flavor_config.dart';
import '../services/auth_service.dart';

class MainMenuWidget extends StatefulWidget {
  final User? user;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final AuthService? authService; // テスト用

  const MainMenuWidget({
    super.key,
    required this.user,
    required this.onSignIn,
    required this.onSignOut,
    this.authService,
  });

  @override
  State<MainMenuWidget> createState() => _MainMenuWidgetState();
}

class _MainMenuWidgetState extends State<MainMenuWidget> {
  late final AuthService _authService;
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _checkAppleSignInAvailability();
  }

  @override
  void didUpdateWidget(MainMenuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ユーザーのUIDが同じ場合は、実質的な変更がないので何もしない
    // これによりBottomSheetが開いている間の不要な再ビルドを防ぐ
    if (oldWidget.user?.uid == widget.user?.uid) {
      return;
    }
    debugPrint(
      '🔄 MainMenuWidget: user actually changed from ${oldWidget.user?.email} to ${widget.user?.email}',
    );
  }

  Future<void> _checkAppleSignInAvailability() async {
    final isAvailable = await _authService.isAppleSignInAvailable();
    setState(() {
      _isAppleSignInAvailable = isAvailable;
    });
  }

  Future<void> _handleAppleSignIn() async {
    final userCredential = await _authService.signInWithApple();
    if (userCredential != null && mounted) {
      // サインイン成功、画面は自動的に更新される
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appleサインインに失敗しました')));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final userCredential = await _authService.signInWithGoogle();
    if (userCredential != null && mounted) {
      // サインイン成功、画面は自動的に更新される
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Googleサインインに失敗しました')));
    }
  }

  void showLoginRequiredSnackBar(BuildContext context) {
    if (widget.user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(config.isDev ? 'はちみつハブ (Dev)' : 'はちみつハブ'),
        actions: widget.user != null
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsMenu(context),
                ),
              ]
            : null,
      ),
      body: Center(
        child: widget.user == null
            ? _buildLoginButtons()
            : _buildUserContent(context),
      ),
    );
  }

  Widget _buildLoginButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Apple Sign-in button (iOS only)
        if (_isAppleSignInAvailable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: SignInWithAppleButton(
              onPressed: _handleAppleSignIn,
              text: 'Appleでログイン',
              height: 50,
            ),
          ),

        // Google Sign-in button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: ElevatedButton(
            onPressed: _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Googleでログイン'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage:
              (widget.user!.photoURL != null &&
                  widget.user!.photoURL!.isNotEmpty)
              ? NetworkImage(widget.user!.photoURL!)
              : null,
          radius: 40,
          child:
              (widget.user!.photoURL == null || widget.user!.photoURL!.isEmpty)
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 16),
        Text('ログイン中: ${widget.user!.displayName ?? ''}'),
        Text('メール: ${widget.user!.email ?? ''}'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: widget.onSignOut, child: const Text('ログアウト')),
        const SizedBox(height: 24),
        _buildMainButtons(context),
      ],
    );
  }

  Widget _buildMainButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: '注文一覧',
          onPressed: () => _navigateWithAuth(context, const OrderListPage()),
        ),
        IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          tooltip: '注文入力',
          onPressed: () => _navigateWithAuth(context, const OrderInputPage()),
        ),
        IconButton(
          icon: const Icon(Icons.inventory),
          tooltip: '商品管理',
          onPressed: () =>
              _navigateWithAuth(context, const ProductMasterPage()),
        ),
        IconButton(
          icon: const Icon(Icons.people),
          tooltip: '顧客管理',
          onPressed: () =>
              _navigateWithAuth(context, const CustomerMasterPage()),
        ),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context) {
    if (widget.user == null) {
      showLoginRequiredSnackBar(context);
      return;
    }

    // BottomSheetの代わりに通常のページとして表示
    // これなら親widgetのrebuildの影響を受けない
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const _SettingsMenuPage()));
  }

  void _navigateWithAuth(BuildContext context, Widget page) {
    if (widget.user == null) {
      showLoginRequiredSnackBar(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }
}

// 設定メニューページ（通常のページとして表示）
class _SettingsMenuPage extends StatelessWidget {
  const _SettingsMenuPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          _buildSettingsItem(
            context: context,
            icon: Icons.receipt_long,
            title: '請求者情報管理',
            page: ClaimantMasterPage(),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.percent,
            title: '税率マスタ管理',
            page: TaxMasterPage(),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.data_usage,
            title: '初期セットアップ',
            page: InitialSetupPage(),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.category,
            title: '顧客区分管理',
            page: CustomerTypeMasterPage(),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.label,
            title: '商品区分管理',
            page: ProductTypeMasterPage(),
          ),
          _buildSettingsItem(
            context: context,
            icon: Icons.list,
            title: '商品種別管理',
            page: ProductCategoryMasterPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
