// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter/services.dart';

class SmsRemover {
  final MethodChannel _channel = const MethodChannel('com.dovahkin.sms_guard');

  /// Removes an SMS message by its ID and thread ID
  /// 
  /// Returns a Future<String> with the result message from the native code
  Future<String> removeSmsById(String id, String threadId) async {
    try {
      final result = await _channel.invokeMethod('removeSms', {
        'id': id,
        'threadId': threadId,
      });
      return result.toString();
    } catch (e) {
      print("Error removing SMS: $e");
      return "SMS silme işlemi başarısız oldu: $e";
    }
  }
}