import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/invoice_data.dart';
import 'invoice_template.dart';
import 'firestore_service.dart';

class InvoiceService {
  /// PDFを保存し、共有ダイアログを表示（Android: Downloads, iOS: Documents）
  static Future<void> saveAndShareInvoicePdf(String orderId) async {
    try {
      final filePath = await saveInvoicePdfToDownloads(orderId);
      if (filePath == null) {
        debugPrint('PDF保存に失敗しました');
        return;
      }
      final params = ShareParams(
        files: [XFile(filePath)],
        text: '請求書PDFを共有します',
      );
      await SharePlus.instance.share(params);
      debugPrint('共有ダイアログを表示しました: $filePath');
    } catch (e) {
      debugPrint('PDF保存・共有エラー: $e');
    }
  }

  /// 請求書データを生成（デバッグ情報付き）
  static Future<InvoiceData?> createInvoiceFromOrder(String orderId) async {
    try {
      debugPrint('請求書生成開始: orderId = $orderId');

      // 注文情報を取得
      final orderDoc = await FirestoreService.getDocumentSafely(
        'orders',
        orderId,
      );
      if (orderDoc == null || !orderDoc.exists) {
        debugPrint('注文情報が見つかりません: orderId = $orderId');
        return null;
      }
      debugPrint('注文情報取得成功');

      final orderData = orderDoc.data() as Map<String, dynamic>;

      // 顧客情報を取得
      final customerId = orderData['customerId'] ?? '';
      debugPrint('顧客ID: $customerId');
      final customerDoc = await FirestoreService.getDocumentSafely(
        'customers',
        customerId,
      );
      if (customerDoc == null || !customerDoc.exists) {
        debugPrint('顧客情報が見つかりません: customerId = $customerId');
        return null;
      }
      debugPrint('顧客情報取得成功');

      final customerData = customerDoc.data() as Map<String, dynamic>;

      // 請求者情報を取得
      debugPrint('請求者情報取得開始...');
      final claimantDoc = await FirestoreService.getClaimantInfo();
      if (claimantDoc == null) {
        debugPrint('請求者情報がnullです');
        return null;
      }
      if (!claimantDoc.exists) {
        debugPrint('請求者情報のドキュメントが存在しません');
        return null;
      }
      debugPrint('請求者情報取得成功');

      final claimantData = claimantDoc.data() as Map<String, dynamic>;
      debugPrint('請求者データ: $claimantData');

      // 注文明細を取得
      final orderItemsRef = FirestoreService.getOrderItems(orderId);
      if (orderItemsRef == null) return null;

      final orderItemsSnapshot = await orderItemsRef.get();
      final items = <InvoiceItem>[];
      double subtotal = 0.0;

      for (final itemDoc in orderItemsSnapshot.docs) {
        final itemData = itemDoc.data() as Map<String, dynamic>;
        final productId = itemData['productId'] ?? '';
        final quantity = itemData['quantity'] ?? 0;

        // 商品情報を取得
        final productDoc = await FirestoreService.getDocumentSafely(
          'products',
          productId,
        );
        if (productDoc != null && productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          final productName = productData['name'] ?? '商品名不明';
          final unitPrice = (productData['price'] ?? 0).toDouble();
          final totalPrice = unitPrice * quantity;

          items.add(
            InvoiceItem(
              productName: productName,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            ),
          );

          subtotal += totalPrice;
        }
      }

      // 消費税計算（10%固定、将来的には税率マスタから取得）
      final taxRate = 0.10;
      final taxAmount = subtotal * taxRate;
      final totalAmount = subtotal + taxAmount;

      // 請求書番号生成（注文日 + 注文ID）
      final orderDate =
          (orderData['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final invoiceNumber =
          'INV-${_formatDateForInvoiceNumber(orderDate)}-${orderId.substring(0, 6).toUpperCase()}';

      return InvoiceData(
        invoiceNumber: invoiceNumber,
        invoiceDate: DateTime.now(),
        customer: CustomerInfo(
          name: customerData['name'] ?? '顧客名不明',
          address: customerData['address'] ?? '',
          postalCode: customerData['postalCode'],
        ),
        claimant: ClaimantInfo(
          name: claimantData['name'] ?? '請求者名不明',
          address: claimantData['address'] ?? '',
          phone: claimantData['phone'],
          invoiceNumber: claimantData['invoiceNumber'],
          postalCode: claimantData['postalCode'],
        ),
        items: items,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
      );
    } catch (e) {
      debugPrint('請求書データ生成エラー: $e');
      return null;
    }
  }

  /// 請求書PDFを生成して印刷/共有
  static Future<bool> generateAndPrintInvoice(String orderId) async {
    try {
      debugPrint('PDF生成開始: orderId = $orderId');

      // 請求書データを作成
      final invoiceData = await createInvoiceFromOrder(orderId);
      if (invoiceData == null) {
        debugPrint('請求書データがnullです');
        return false;
      }
      debugPrint('請求書データ作成成功');

      // PDFを生成
      debugPrint('PDFテンプレート生成開始...');
      final pdfData = await InvoiceTemplate.generateInvoicePDF(invoiceData);
      debugPrint('PDFデータ生成完了: ${pdfData.length} bytes');

      // 印刷/共有ダイアログを表示
      debugPrint('印刷ダイアログ表示開始...');
      await Printing.layoutPdf(
        onLayout: (_) async => pdfData,
        name: '請求書_${invoiceData.customer.name}_${invoiceData.invoiceNumber}',
      );
      debugPrint('印刷ダイアログ表示完了');

      return true;
    } catch (e) {
      debugPrint('PDF生成・印刷エラー: $e');
      debugPrint('エラースタックトレース: ${StackTrace.current}');
      return false;
    }
  }

  /// 請求書PDFデータを取得（ファイル保存用）
  static Future<Uint8List?> generateInvoicePdfData(String orderId) async {
    try {
      final invoiceData = await createInvoiceFromOrder(orderId);
      if (invoiceData == null) return null;

      return await InvoiceTemplate.generateInvoicePDF(invoiceData);
    } catch (e) {
      debugPrint('PDF生成エラー: $e');
      return null;
    }
  }

  /// 請求書PDFをファイルとして保存
  static Future<String?> saveInvoicePdfToFile(String orderId) async {
    try {
      final invoiceData = await createInvoiceFromOrder(orderId);
      if (invoiceData == null) return null;

      final pdfData = await InvoiceTemplate.generateInvoicePDF(invoiceData);

      // ファイル名を生成
      final fileName =
          '請求書_${invoiceData.customer.name}_${invoiceData.invoiceNumber}.pdf';

      // Documents ディレクトリに保存
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfData);

      debugPrint('請求書PDFを保存しました: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('PDF保存エラー: $e');
      return null;
    }
  }

  /// 請求書PDFをダウンロードフォルダに保存（Android/iOS対応）
  static Future<String?> saveInvoicePdfToDownloads(String orderId) async {
    try {
      final invoiceData = await createInvoiceFromOrder(orderId);
      if (invoiceData == null) return null;

      final pdfData = await InvoiceTemplate.generateInvoicePDF(invoiceData);

      // ファイル名を生成
      final fileName =
          '請求書_${invoiceData.customer.name}_${invoiceData.invoiceNumber}.pdf';

      Directory? directory;

      if (Platform.isAndroid) {
        // Android: Downloads フォルダ
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // 外部ストレージが利用できない場合はアプリのドキュメントフォルダ
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS: アプリのドキュメントフォルダ
        directory = await getApplicationDocumentsDirectory();
      } else {
        // その他のプラットフォーム
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfData);

      debugPrint('請求書PDFをダウンロードフォルダに保存しました: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('PDF保存エラー: $e');
      return null;
    }
  }

  /// 請求書番号用の日付フォーマット
  static String _formatDateForInvoiceNumber(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
