import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';


import '../../../models/order_detail_model.dart';
import '../../../utils/formatter.dart';

class InvoiceScreen extends StatelessWidget {
  final OrderDetailModel order;

  const InvoiceScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hóa đơn #${order.orderId}'),
        backgroundColor: Colors.blue,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, order),
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowSharing: true,
        allowPrinting: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'HoaDon_${order.orderId}.pdf',
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, OrderDetailModel order) async {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(context, order, ttf, ttfBold),
                pw.SizedBox(height: 20),
                _buildRecipientInfo(context, order, ttf, ttfBold),
                pw.SizedBox(height: 20),
                _buildItemsTable(context, order, ttf, ttfBold),
                pw.SizedBox(height: 10),
                pw.Divider(),
                _buildTotals(context, order, ttf, ttfBold),
                pw.SizedBox(height: 40),
                _buildFooter(context, ttf),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Context context, OrderDetailModel order, pw.Font ttf, pw.Font ttfBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fashion Store', style: pw.TextStyle(font: ttfBold, fontSize: 20, color: PdfColors.black)),
              pw.Text('HÓA ĐƠN BÁN HÀNG', style: pw.TextStyle(font: ttfBold, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Text('Mã đơn hàng: #${order.orderId}', style: pw.TextStyle(font: ttf)),
              pw.Text(
                'Ngày đặt: ${order.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!) : 'Chưa có'}',
                style: pw.TextStyle(font: ttf),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Align(
            alignment: pw.Alignment.topRight,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: 'Order ID: ${order.orderId}',
              width: 60,
              height: 60,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRecipientInfo(pw.Context context, OrderDetailModel order, pw.Font ttf, pw.Font ttfBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('THÔNG TIN KHÁCH HÀNG:', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
        pw.SizedBox(height: 5),
        pw.Text('Người nhận: ${order.shippingAddress?.fullNameReceiver}', style: pw.TextStyle(font: ttf)),
        pw.Text('SĐT: ${order.shippingAddress?.phoneReceiver}', style: pw.TextStyle(font: ttf)),
        pw.Text('Địa chỉ: ${order.shippingAddress?.fullAddressString}', style: pw.TextStyle(font: ttf)),
        pw.Text('Phương thức thanh toán: ${order.paymentMethod ?? "Chưa có"}', style: pw.TextStyle(font: ttf)), // ✅ thêm dòng này
      ],
    );
  }



  pw.Widget _buildItemsTable(pw.Context context, OrderDetailModel order, pw.Font ttf, pw.Font ttfBold) {
    final headers = ['STT', 'Tên sản phẩm', 'SL', 'Đơn giá', 'Thành tiền'];
    final data = order.items.asMap().entries.map((entry) {
      int index = entry.key;
      var item = entry.value;
      return [
        (index + 1).toString(),
        '${item.productName}\nSize: ${item.size ?? "N/A"}, Màu: ${item.color ?? "N/A"}',
        item.quantity.toString(),
        currencyFormatter.format(item.priceAtPurchase),
        currencyFormatter.format(item.subTotal),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
      headerStyle: pw.TextStyle(font: ttfBold, fontSize: 12),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(0.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
      },
    );
  }

  pw.Widget _buildTotals(pw.Context context, OrderDetailModel order, pw.Font ttf, pw.Font ttfBold) {
    final isVietQR = order.paymentMethod?.toUpperCase() == 'VIETQR';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Expanded(child: pw.SizedBox()),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tổng tiền hàng:', style: pw.TextStyle(font: ttf)),
                  pw.Text(currencyFormatter.format(order.subtotalAmount), style: pw.TextStyle(font: ttfBold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Phí vận chuyển:', style: pw.TextStyle(font: ttf)),
                  pw.Text(currencyFormatter.format(order.shippingFee), style: pw.TextStyle(font: ttfBold)),
                ],
              ),
              if ((order.voucherDiscountAmount ?? 0) > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Giảm giá voucher:', style: pw.TextStyle(font: ttf)),
                    pw.Text(
                      '-${currencyFormatter.format(order.voucherDiscountAmount)}',
                      style: pw.TextStyle(font: ttfBold),
                    ),
                  ],
                ),
              if (isVietQR)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),

                  child: pw.Text(
                    'Khách đã chuyển khoản qua VietQR.',
                    style: pw.TextStyle(font: ttf, color: PdfColors.black, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TỔNG CỘNG:', style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.black)),
                  pw.Text(
                    isVietQR
                        ? currencyFormatter.format(0)
                        : currencyFormatter.format(order.totalAmount),
                    style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'Cảm ơn quý khách đã mua hàng tại Fashion Store!',
            style: pw.TextStyle(
              font: ttf,
              fontStyle: pw.FontStyle.italic,
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Mọi chi tiết xin liên hệ qua \nemail: admin@shop.com hoặc sđt: 0987654321',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 13,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

}
