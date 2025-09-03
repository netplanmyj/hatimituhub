import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../order_input.dart';
import '../order_list_page.dart';
import '../product_master_page.dart';
import '../customer_master_page.dart';
import '../initial_setup_page.dart';
import '../customer_type_master_page.dart';
import '../product_type_master_page.dart';
import '../product_category_master_page.dart';
import '../tax_master_page.dart';

class MainMenuWidget extends StatelessWidget {
  final User? user;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const MainMenuWidget({
    super.key,
    required this.user,
    required this.onSignIn,
    required this.onSignOut,
  });

  void showLoginRequiredSnackBar(BuildContext context) {
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインが必要です')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Googleサインインデモ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: onSignIn,
                child: const Text('Googleでログイン'),
              )
            : _buildUserContent(context),
      ),
    );
  }

  Widget _buildUserContent(BuildContext context) {
    return Column(
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
        ElevatedButton(onPressed: onSignOut, child: const Text('ログアウト')),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsItem(
              context,
              icon: Icons.percent,
              title: '税率マスタ管理',
              page: TaxMasterPage(),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.data_usage,
              title: '初期セットアップ',
              page: InitialSetupPage(),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.category,
              title: '顧客区分管理',
              page: CustomerTypeMasterPage(),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.label,
              title: '商品区分管理',
              page: ProductTypeMasterPage(),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.list,
              title: '商品種別管理',
              page: ProductCategoryMasterPage(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (user == null) {
          showLoginRequiredSnackBar(context);
          return;
        }
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  void _navigateWithAuth(BuildContext context, Widget page) {
    if (user == null) {
      showLoginRequiredSnackBar(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }
}
