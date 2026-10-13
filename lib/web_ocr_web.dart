import 'dart:typed_data';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

// Legătura interop către funcția globală din window.runOcrOnImage
@JS('runOcrOnImage')
external JSPromise _runOcrOnImage(JSString dataUrl);

Future<String> recognizeTextOnWeb(Uint8List bytes) async {
  try {
    final String base64Image = base64Encode(bytes);
    final String dataUrl = 'data:image/jpeg;base64,$base64Image';

    // Apelăm funcția din JS și o transformăm în Future
    final JSPromise promise = _runOcrOnImage(dataUrl.toJS);
    final JSAny? result = await promise.toDart;

    return (result as JSString?)?.toDart ?? '';
  } catch (e) {
    debugPrint("Eroare la apelul OCR în browser: $e");
    return '';
  }
}
