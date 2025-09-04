import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';

class ClaimantMasterPage extends StatefulWidget {
  const ClaimantMasterPage({super.key});

  @override
  State<ClaimantMasterPage> createState() => _ClaimantMasterPageState();
}

class _ClaimantMasterPageState extends State<ClaimantMasterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  bool _isLoading = false;
  bool _hasData = false;
  String? _claimantId;

  @override
  void initState() {
    super.initState();
    _loadClaimantData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadClaimantData() async {
    setState(() => _isLoading = true);

    try {
      final claimantCollection = FirestoreService.getTeamCollection('claimant');
      if (claimantCollection != null) {
        final querySnapshot = await claimantCollection.limit(1).get();
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          _claimantId = doc.id;
          _nameController.text = data['name'] ?? '';
          _postalCodeController.text = data['postalCode'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _contactPersonController.text = data['contactPerson'] ?? '';
          _invoiceNumberController.text = data['invoiceNumber'] ?? '';

          setState(() => _hasData = true);
        }
      }
    } catch (e) {
      _showErrorSnackBar('請求者情報の読み込みに失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveClaimantData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final claimantCollection = FirestoreService.getTeamCollection('claimant');
      if (claimantCollection == null) {
        _showErrorSnackBar('ログインが必要です');
        return;
      }

      final data = {
        'name': _nameController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'invoiceNumber': _invoiceNumberController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_hasData && _claimantId != null) {
        // 更新
        await claimantCollection.doc(_claimantId).update(data);
        _showSuccessSnackBar('請求者情報を更新しました');
      } else {
        // 新規作成
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await claimantCollection.add(data);
        _claimantId = docRef.id;
        setState(() => _hasData = true);
        _showSuccessSnackBar('請求者情報を登録しました');
      }
    } catch (e) {
      _showErrorSnackBar('保存に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('請求者情報管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveClaimantData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '基本情報',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '請求者名 *',
                                hintText: '株式会社○○',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '請求者名は必須です';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _invoiceNumberController,
                              decoration: const InputDecoration(
                                labelText: '事業者番号',
                                hintText: 'T1234567890123',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactPersonController,
                              decoration: const InputDecoration(
                                labelText: '担当者名',
                                hintText: '山田太郎',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '住所情報',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: '郵便番号',
                                hintText: '123-4567',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: '住所',
                                hintText: '東京都渋谷区○○1-2-3',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: '電話番号',
                                hintText: '03-1234-5678',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveClaimantData,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _hasData ? '更新' : '登録',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
