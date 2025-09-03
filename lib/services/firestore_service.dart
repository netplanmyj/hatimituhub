import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// 特定の注文の明細コレクションを取得
  static CollectionReference? getOrderItems(String orderId) {
    final orderDoc = getTeamDocument('orders', orderId);
    return orderDoc?.collection('orderItems');
  }

  /// 認証チェック付きでコレクションを取得
  static Future<QuerySnapshot?> getCollectionSafely(
    String collectionName,
  ) async {
    final collection = getTeamCollection(collectionName);
    if (collection == null) return null;

    try {
      return await collection.get();
    } catch (e) {
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
