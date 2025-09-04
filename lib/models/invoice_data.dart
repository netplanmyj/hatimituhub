/// 請求書データモデル
class InvoiceData {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final CustomerInfo customer;
  final ClaimantInfo claimant;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  InvoiceData({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customer,
    required this.claimant,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
  });
}

/// 顧客情報
class CustomerInfo {
  final String name;
  final String address;
  final String? postalCode;

  CustomerInfo({required this.name, required this.address, this.postalCode});
}

/// 請求者情報
class ClaimantInfo {
  final String name;
  final String address;
  final String? phone;
  final String? invoiceNumber;
  final String? postalCode;

  ClaimantInfo({
    required this.name,
    required this.address,
    this.phone,
    this.invoiceNumber,
    this.postalCode,
  });
}

/// 請求明細アイテム
class InvoiceItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}
