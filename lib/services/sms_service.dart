import 'package:flutter/services.dart';
import 'dart:developer';

/// SMS gönderme ve yönetme işlemleri için servis sınıfı.
/// Bu sınıf, native Kotlin kodu ile iletişim kurarak SMS işlemlerini gerçekleştirir.
class SmsService {
  static const MethodChannel _channel = MethodChannel('com.dovahkin.sms_guard');
  
  /// Singleton yapı
  SmsService._privateConstructor();
  static final SmsService instance = SmsService._privateConstructor();
  
  /// SMS gönderir ve sonucu döndürür.
  /// 
  /// [phoneNumber]: SMS gönderilecek telefon numarası
  /// [message]: Gönderilecek mesaj içeriği
  /// [formatNumber]: Telefon numarasını otomatik formatla
  Future<String> sendSms({
    required String phoneNumber, 
    required String message,
    bool formatNumber = true
  }) async {
    try {
      // Telefon numarasını formatlama (opsiyonel)
      String formattedNumber = phoneNumber;
      if (formatNumber) {
        formattedNumber = _formatPhoneNumber(phoneNumber);
      }
      
      log('SMS gönderiliyor: $formattedNumber -> $message');
      
      // Native kodu çağır
      final result = await _channel.invokeMethod('sendSms', {
        'address': formattedNumber,
        'body': message,
      });
      
      log('SMS gönderme sonucu: $result');
      return result.toString();
    } on PlatformException catch (e) {
      log('SMS gönderme hatası: ${e.message}');
      return 'SMS gönderme hatası: ${e.message}';
    } catch (e) {
      log('Beklenmeyen hata: $e');
      return 'Beklenmeyen hata: $e';
    }
  }
  
  /// SMS kaydet (gönderilmiş gibi)
  Future<String> saveSmsToSent({
    required String phoneNumber,
    required String message,
    bool formatNumber = true
  }) async {
    try {
      String formattedNumber = phoneNumber;
      if (formatNumber) {
        formattedNumber = _formatPhoneNumber(phoneNumber);
      }
      
      final result = await _channel.invokeMethod('check', {
        'address': formattedNumber,
        'body': message,
      });
      
      return result.toString();
    } catch (e) {
      log('SMS kaydetme hatası: $e');
      return 'SMS kaydetme hatası: $e';
    }
  }
  
  /// SMS silme
  Future<String> deleteSms(String id, String threadId) async {
    try {
      final result = await _channel.invokeMethod('removeSms', {
        'id': id,
        'threadId': threadId,
      });
      
      return result.toString();
    } catch (e) {
      log('SMS silme hatası: $e');
      return 'SMS silme hatası: $e';
    }
  }
  
  /// Telefon numarasını Türkiye formatına çevirir
  String _formatPhoneNumber(String phoneNumber) {
    // Boşlukları ve özel karakterleri temizle
    String number = phoneNumber
        .trim()
        .replaceAll(" ", "")
        .replaceAll("-", "")
        .replaceAll("(", "")
        .replaceAll(")", "");
    
    // Türkiye telefon formatlaması
    if (number.startsWith("0")) {
      number = number.replaceFirst("0", "+90");
    }
    else if (number.startsWith("90")) {
      number = number.replaceFirst("90", "+90");
    }
    else if (number.startsWith("5")) {
      number = "+90$number";
    }
    
    return number;
  }
}