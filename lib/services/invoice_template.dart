import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_data.dart';

class InvoiceTemplate {
  static pw.Font? _japaneseFont;
  static bool _fontLoadingAttempted = false;

  static Future<pw.Font?> _loadJapaneseFont() async {
    if (_fontLoadingAttempted) {
      return _japaneseFont;
    }
    _fontLoadingAttempted = true;

    final fontUrls = [
      'https://fonts.gstatic.com/s/notosansjp/v52/noto-sans-jp-v52-latin_japanese-regular.ttf',
      'https://fonts.gstatic.com/s/notosansjp/v52/noto-sans-jp-v52-japanese-regular.ttf',
      'https://github.com/google/fonts/raw/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf',
      'https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400&display=swap',
    ];

    for (int i = 0; i < fontUrls.length; i++) {
      try {
        debugPrint('フォント取得試行 ${i + 1}/${fontUrls.length}: ${fontUrls[i]}');

        final response = await http
            .get(
              Uri.parse(fontUrls[i]),
              headers: {'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)'},
            )
            .timeout(const Duration(seconds: 30));

        debugPrint(
          'フォント応答: status=${response.statusCode}, size=${response.bodyBytes.length}',
        );

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          // TTFフォーマットのチェック（TTFは0x00010000または'true'で始まる）
          final bytes = response.bodyBytes;
          if (bytes.length > 4) {
            final header = bytes.take(4).toList();
            final isTTF =
                (header[0] == 0x00 &&
                    header[1] == 0x01 &&
                    header[2] == 0x00 &&
                    header[3] == 0x00) ||
                (header[0] == 0x74 &&
                    header[1] == 0x72 &&
                    header[2] == 0x75 &&
                    header[3] == 0x65); // 'true'

            if (isTTF) {
              debugPrint('TTFフォント検出、読み込み試行中...');
              try {
                _japaneseFont = pw.Font.ttf(bytes.buffer.asByteData());
                debugPrint('日本語フォント読み込み成功');
                return _japaneseFont;
              } catch (e) {
                debugPrint('フォント読み込みエラー: $e');
                continue;
              }
            } else {
              debugPrint('非TTFフォーマット検出、スキップ');
              continue;
            }
          }
        } else {
          debugPrint(
            'フォント取得失敗: status=${response.statusCode}, size=${response.bodyBytes.length}',
          );
        }
      } catch (e) {
        debugPrint('フォント取得エラー ${i + 1}: $e');
      }
    }

    debugPrint('全てのフォント取得に失敗、デフォルトフォントを使用');
    return null;
  }

  static Future<Uint8List> generateInvoicePDF(InvoiceData invoiceData) async {
    debugPrint('PDF生成開始');

    final pdf = pw.Document();

    // 日本語フォントの読み込み試行
    final japaneseFont = await _loadJapaneseFont();
    final textStyle = japaneseFont != null
        ? pw.TextStyle(font: japaneseFont, fontSize: 12)
        : const pw.TextStyle(fontSize: 12);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ヘッダー
              pw.Text(
                '請求書',
                style: japaneseFont != null
                    ? pw.TextStyle(
                        font: japaneseFont,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
              ),
              pw.SizedBox(height: 30),

              // 請求書番号と発行日（右上配置）
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '請求書番号: ${invoiceData.invoiceNumber}',
                        style: pw.TextStyle(
                          font: japaneseFont,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '発行日: ${invoiceData.invoiceDate.toString().split(' ')[0]}',
                        style: textStyle,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // お客様情報と請求者情報（2カラムレイアウト）
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // お客様情報（左カラム）
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'お客様情報',
                          style: pw.TextStyle(
                            font: japaneseFont,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                invoiceData.customer.name,
                                style: textStyle,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '住所: ${invoiceData.customer.address}',
                                style: textStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // 請求者情報（右カラム）
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '請求者情報',
                          style: pw.TextStyle(
                            font: japaneseFont,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                invoiceData.claimant.name,
                                style: textStyle,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '住所: ${invoiceData.claimant.address}',
                                style: textStyle,
                              ),
                              if (invoiceData.claimant.phone != null) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '電話: ${invoiceData.claimant.phone}',
                                  style: textStyle,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // 商品明細
              pw.Text(
                '商品明細',
                style: pw.TextStyle(
                  font: japaneseFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              // テーブルヘッダー（背景色付き）
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        '商品名',
                        style: pw.TextStyle(
                          font: japaneseFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        '数量',
                        style: pw.TextStyle(
                          font: japaneseFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '単価',
                        style: pw.TextStyle(
                          font: japaneseFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '金額',
                        style: pw.TextStyle(
                          font: japaneseFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // 商品行（改善された行間とアライメント）
              ...invoiceData.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                    border: pw.Border(
                      left: const pw.BorderSide(color: PdfColors.grey400),
                      right: const pw.BorderSide(color: PdfColors.grey400),
                      bottom: const pw.BorderSide(color: PdfColors.grey400),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(item.productName, style: textStyle),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}',
                          style: textStyle,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '¥${item.unitPrice.toStringAsFixed(0)}',
                          style: textStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '¥${item.totalPrice.toStringAsFixed(0)}',
                          style: textStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 30),

              // 合計セクション（右寄せでより見やすく）
              pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.SizedBox()),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('小計:', style: textStyle),
                              pw.Text(
                                '¥${invoiceData.subtotal.toStringAsFixed(0)}',
                                style: textStyle,
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('消費税:', style: textStyle),
                              pw.Text(
                                '¥${invoiceData.taxAmount.toStringAsFixed(0)}',
                                style: textStyle,
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  color: PdfColors.grey600,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  '合計金額:',
                                  style: pw.TextStyle(
                                    font: japaneseFont,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '¥${invoiceData.totalAmount.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                    font: japaneseFont,
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
            ],
          );
        },
      ),
    );

    debugPrint('PDF生成完了');
    return await pdf.save();
  }
}
