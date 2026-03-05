import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LpoGenerator {
  static Future<void> generateAndPrintLPO({
    required String schoolName,
    required String farmerName,
    required String farmerPhone,
    required String cropName,
    required String quantity,
    required String price,
    required String tenderId,
    required String deliveryDate, // 🔥 ADDED THIS LINE
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER & QR CODE ROW ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LOCAL PURCHASE ORDER (LPO)',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800),
                        ),
                        pw.Text('Official Government Procurement Document',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      ]),

                  // THE QR CODE
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://sokotender.co.ke/verify/$tenderId', 
                      width: 60,
                      height: 60,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // --- 2. SCHOOL & LPO DETAILS ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('From:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(schoolName,
                          style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Procurement Department'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'LPO NO: ${tenderId.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(
                          'Issue Date: ${DateTime.now().toString().split(' ')[0]}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // --- 3. FARMER DETAILS ---
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('To Authorized Supplier:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(farmerName,
                        style: pw.TextStyle(
                            fontSize: 14, color: PdfColors.blue900)),
                    pw.Text('Phone: $farmerPhone'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // --- 4. THE ORDER TABLE & DELIVERY DATE ---
              pw.Text(
                  'Please supply the following goods as per the agreed tender terms:',
                  style: const pw.TextStyle(color: PdfColors.grey800)),
              pw.SizedBox(height: 8),
              
              // 🔥 THE NEW DELIVERY DATE DISPLAY 🔥
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red200)
                ),
                child: pw.Row(
                  children: [
                    pw.Text('REQUIRED DELIVERY DATE: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 12)),
                    pw.Text(deliveryDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 12)),
                  ]
                )
              ),
              pw.SizedBox(height: 12),

              pw.Table.fromTextArray(
                headers: [
                  'Item Description',
                  'Quantity Required',
                  'Agreed Total (KES)'
                ],
                data: [
                  [cropName, quantity, price],
                ],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.green700),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300)),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(12),
              ),
              pw.SizedBox(height: 60),

              // --- 5. SIGNATURES & E-STAMP ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // School Signature Side (With the Stamp!)
                  pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      // The physical signature line
                      pw.Column(
                        children: [
                          pw.SizedBox(height: 40), // Space for the stamp
                          pw.Container(
                              width: 180, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 8),
                          pw.Text('Authorized Signature',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(schoolName,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey)),
                        ],
                      ),

                      // THE DIGITAL RED STAMP
                      pw.Positioned(
                        top: 0,
                        child: pw.Transform.rotate(
                          angle: -0.15, // Tilts the stamp slightly
                          child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.red800, width: 2),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(8)),
                              ),
                              child: pw.Column(children: [
                                pw.Text('E-APPROVED',
                                    style: pw.TextStyle(
                                        color: PdfColors.red800,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 2)),
                                pw.Text('DIGITAL PROCUREMENT SYSTEM',
                                    style: pw.TextStyle(
                                        color: PdfColors.red800, fontSize: 8)),
                              ])),
                        ),
                      ),
                    ],
                  ),

                  // Farmer Signature Side
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Container(
                          width: 180, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 8),
                      pw.Text('Supplier Signature',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sign upon delivery',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                  child: pw.Text(
                      'This document was securely generated by Soko Tender. Do not accept if tampered with.',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey500)))
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'LPO_${cropName}_$farmerName.pdf',
    );
  }
}