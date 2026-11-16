import 'dart:async';

import 'package:flutter/services.dart';

import 'session.dart';

/// ملف اختاره المستخدم (content:// URI).
class PickedFile {
  const PickedFile(this.uri, this.name, this.size);

  final String uri;
  final String name;
  final int? size;

  static PickedFile? fromMap(Object? o) {
    if (o is! Map) return null;
    return PickedFile(o['uri'] as String, o['name'] as String? ?? 'file', (o['size'] as num?)?.toInt());
  }
}

/// حاجة جاية من تطبيق تاني (Share / افتح بـ).
class Incoming {
  const Incoming.text(this.text) : file = null;
  const Incoming.file(this.file) : text = null;

  final String? text;
  final PickedFile? file;
}

/// قناة `shen/system`: الملفات، المشاركة، الحافظة، QR.
class SystemBridge {
  SystemBridge._();

  static const _channel = MethodChannel('shen/system');
  static final _incoming = StreamController<void>.broadcast();

  /// بيرن لما يوصل Share / "افتح بـ" والتطبيق مفتوح.
  static Stream<void> get incomingEvents => _incoming.stream;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'incoming') _incoming.add(null);
      return null;
    });
  }

  /// النوافذ دي بتخلي التطبيق يروح في الخلفية — القفل التلقائي يستنى لحد ما ترجع.
  static Future<T> _outside<T>(Future<T> Function() f) => Session.instance.outside(f);

  static Future<PickedFile?> pickOpen() => _outside(() async => PickedFile.fromMap(await _channel.invokeMethod('pickOpen')));

  static Future<PickedFile?> pickCreate(String name, {String mime = 'application/octet-stream'}) =>
      _outside(() async => PickedFile.fromMap(await _channel.invokeMethod('pickCreate', {'name': name, 'mime': mime})));

  static Future<Uint8List?> readUri(String uri, {int max = 8 * 1024 * 1024}) =>
      _channel.invokeMethod<Uint8List>('readUri', {'uri': uri, 'max': max});

  static Future<void> writeUri(String uri, Uint8List data) => _channel.invokeMethod('writeUri', {'uri': uri, 'data': data});

  static Future<void> shareText(String text, String title) =>
      _outside(() async => _channel.invokeMethod('shareText', {'text': text, 'title': title}));

  /// [sensitive]: بيتمسح من الحافظة بعد [clearAfter] ثانية وميظهرش في معاينة الحافظة.
  static Future<void> copy(String text, {bool sensitive = true, int clearAfter = 45}) =>
      _channel.invokeMethod('copy', {'text': text, 'sensitive': sensitive, 'clearAfter': clearAfter});

  static Future<Incoming?> takeIncoming() async {
    final m = await _channel.invokeMethod<Map>('takeIncoming');
    if (m == null) return null;
    if (m['kind'] == 'text') return Incoming.text(m['text'] as String? ?? '');
    final f = PickedFile.fromMap(m);
    return f == null ? null : Incoming.file(f);
  }

  static Future<String?> scanQr() => _outside(() => _channel.invokeMethod<String>('scanQr'));

  static Future<void> openUrl(String url) => _outside(() async => _channel.invokeMethod('openUrl', {'url': url}));
}
