import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザーのteamIdを取得
  static String? get currentTeamId => FirebaseAuth.instance.currentUser?.uid;

  /// team_data/{teamId}/collectionのCollectionReferenceを取得
  static CollectionReference? getTeamCollection(String collectionName) {
    final teamId = currentTeamId;
    if (teamId == null) return null;

    return _firestore
        .collection('team_data')
        .doc(teamId)
        .collection(collectionName);
  }

  /// team_data/{teamId}/collection/{docId}のDocumentReferenceを取得
  static DocumentReference? getTeamDocument(
    String collectionName,
    String docId,
  ) {
    final collection = getTeamCollection(collectionName);
    return collection?.doc(docId);
  }

  /// 顧客コレクションを取得
  static CollectionReference? get customers => getTeamCollection('customers');

  /// 商品コレクションを取得
  static CollectionReference? get products => getTeamCollection('products');

  /// 商品区分コレクションを取得
  static CollectionReference? get productTypes =>
      getTeamCollection('product_types');

  /// 顧客区分コレクションを取得
  static CollectionReference? get customerTypes =>
      getTeamCollection('customer_types');

  /// 注文コレクションを取得
  static CollectionReference? get orders => getTeamCollection('orders');

  /// 税区分コレクションを取得
  static CollectionReference? get taxes => getTeamCollection('taxes');

  /// 商品カテゴリコレクションを取得
  static CollectionReference? get productCategories =>
      getTeamCollection('product_categories');

  /// 請求者コレクションを取得
  static CollectionReference? get claimant => getTeamCollection('claimant');

  /// 特定の注文の明細コレクションを取得
  static CollectionReference? getOrderItems(String orderId) {
    final orderDoc = getTeamDocument('orders', orderId);
    return orderDoc?.collection('orderItems');
  }

  /// 請求者情報を取得（デバッグ情報付き）
  static Future<DocumentSnapshot?> getClaimantInfo() async {
    try {
      debugPrint('請求者情報取得: コレクション取得開始');
      final claimantCollection = getTeamCollection('claimant');
      if (claimantCollection == null) {
        debugPrint('請求者情報取得: claimantCollectionがnull');
        return null;
      }

      debugPrint('請求者情報取得: クエリ実行開始');
      final querySnapshot = await claimantCollection.limit(1).get();
      debugPrint('請求者情報取得: ドキュメント数 = ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        debugPrint('請求者情報取得: ドキュメントが存在しません');
        return null;
      }

      final doc = querySnapshot.docs.first;
      debugPrint('請求者情報取得: 成功 - docId = ${doc.id}');
      debugPrint('請求者情報取得: データ = ${doc.data()}');
      return doc;
    } catch (e) {
      debugPrint('請求者情報取得: エラー = $e');
      return null;
    }
  }

  /// 認証チェック付きでコレクションを取得
  static Future<QuerySnapshot?> getCollectionSafely(
    String collectionName,
  ) async {
    final collection = getTeamCollection(collectionName);
    if (collection == null) {
      debugPrint('❌ getCollectionSafely: collection is null (ユーザー未認証)');
      return null;
    }

    try {
      debugPrint('📥 getCollectionSafely: $collectionName を取得中...');
      final result = await collection.get();
      debugPrint(
        '✅ getCollectionSafely: $collectionName 取得成功 (${result.docs.length}件)',
      );
      return result;
    } catch (e) {
      debugPrint('❌ getCollectionSafely: $collectionName 取得エラー: $e');
      return null;
    }
  }

  /// 認証チェック付きでドキュメントを取得
  static Future<DocumentSnapshot?> getDocumentSafely(
    String collectionName,
    String docId,
  ) async {
    // docIdが空文字列の場合はnullを返す
    if (docId.isEmpty) return null;

    final document = getTeamDocument(collectionName, docId);
    if (document == null) return null;

    try {
      return await document.get();
    } catch (e) {
      return null;
    }
  }
}
