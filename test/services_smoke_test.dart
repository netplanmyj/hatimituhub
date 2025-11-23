import 'package:flutter_test/flutter_test.dart';
import 'package:hatimituhub/services/invoice_service.dart';
import 'package:hatimituhub/services/invoice_template.dart';
import 'package:hatimituhub/services/firestore_service.dart';

void main() {
  group('Service class smoke tests', () {
    test('InvoiceService class exists', () {
      expect(InvoiceService, isNotNull);
    });
    test('InvoiceTemplate class exists', () {
      expect(InvoiceTemplate, isNotNull);
    });
    test('FirestoreService class exists', () {
      expect(FirestoreService, isNotNull);
    });
    // 代表的なstaticメソッドの型チェック（呼び出しはしない）
    test('InvoiceService static methods exist', () {
      expect(InvoiceService.saveAndShareInvoicePdf, isA<Function>());
      expect(InvoiceService.saveInvoicePdfToDownloads, isA<Function>());
      expect(InvoiceService.generateAndPrintInvoice, isA<Function>());
    });
    test('InvoiceTemplate.generateInvoicePDF exists', () {
      expect(InvoiceTemplate.generateInvoicePDF, isA<Function>());
    });
    test('FirestoreService.getDocumentSafely exists', () {
      expect(FirestoreService.getDocumentSafely, isA<Function>());
    });
  });
}
