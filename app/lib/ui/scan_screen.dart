import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import 'widgets.dart';

/// EAN/UPC scanner (zxing-cpp, no Google ML Kit). Pops with the barcode digits.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.scanBarcode)),
      body: ReaderWidget(
        codeFormat: Format.linearCodes,
        showGallery: false,
        showToggleCamera: false,
        tryHarder: true,
        onScan: (code) {
          final text = code.text;
          if (_done || !code.isValid || text == null || !RegExp(r'^\d{6,20}$').hasMatch(text)) return;
          _done = true;
          Navigator.pop(context, text);
        },
      ),
    );
  }
}
