import 'package:flutter/material.dart';

import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Widget getWebIframe(String viewId, String url) {
  String finalUrl = url;
  if (url.contains('src="')) {
    final RegExp regExp = RegExp(r'src="([^"]+)"');
    final Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      finalUrl = match.group(1)!;
    }
  }

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final html.IFrameElement iframe = html.IFrameElement()
      ..src = finalUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute(
        'allow',
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
      )
      ..setAttribute('allowfullscreen', 'true');
    return iframe;
  });

  return HtmlElementView(viewType: viewId);
}
