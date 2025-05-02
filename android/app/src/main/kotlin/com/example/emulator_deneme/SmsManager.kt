package com.dovahkin.sms_guard

import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import android.util.Log

/**
 * Bu sınıf SMS gönderme ve yönetme işlemlerini native olarak gerçekleştirir.
 * Flutter tarafından Method Channel üzerinden çağrılır.
 */
class SmsManager {
    companion object {
        private const val TAG = "SmsManager"
        
        /**
         * SMS gönderir ve sonucu döndürür.
         * @param context Uygulama context'i
         * @param phoneNumber SMS gönderilecek telefon numarası
         * @param message Gönderilecek mesaj içeriği
         * @return Gönderim sonucunu içeren Map
         */
        fun sendSms(context: Context, phoneNumber: String, message: String): Map<String, Any> {
            val resultMap = mutableMapOf<String, Any>()
            
            try {
                // İzin kontrolü
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                    context.checkSelfPermission(android.Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                    Log.e(TAG, "SMS permission not granted")
                    resultMap["success"] = false
                    resultMap["message"] = "SMS izni verilmedi"
                    return resultMap
                }
                
                // Android versiyonuna göre SmsManager alınması
                val androidSmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.getSystemService(android.telephony.SmsManager::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    android.telephony.SmsManager.getDefault()
                }
                
                // Uzun mesajları parçalama ve gönderme
                if (message.length > 160) {
                    val messageParts = androidSmsManager.divideMessage(message)
                    androidSmsManager.sendMultipartTextMessage(
                        phoneNumber,
                        null,
                        messageParts,
                        null,
                        null
                    )
                } else {
                    // Kısa mesajları doğrudan gönderme
                    androidSmsManager.sendTextMessage(phoneNumber, null, message, null, null)
                }
                
                // Gönderilen mesajı cihaz SMS veritabanına kaydetme
                saveToSentBox(context, phoneNumber, message)
                
                Log.i(TAG, "SMS sent successfully to $phoneNumber")
                resultMap["success"] = true
                resultMap["message"] = "SMS başarıyla gönderildi"
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send SMS: ${e.message}")
                e.printStackTrace()
                resultMap["success"] = false
                resultMap["message"] = "SMS gönderme hatası: ${e.message}"
            }
            
            return resultMap
        }
        
        /**
         * Gönderilen mesajı cihaz SMS veritabanına kaydeder
         */
        fun saveToSentBox(context: Context, address: String?, message: String?) {
            try {
                val smsValues = ContentValues().apply {
                    put(Telephony.Sms.ADDRESS, address)
                    put(Telephony.Sms.BODY, message)
                    put(Telephony.Sms.DATE, System.currentTimeMillis())
                    put(Telephony.Sms.READ, 1)
                    put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_SENT)
                }
                
                context.contentResolver.insert(Uri.parse("content://sms/sent"), smsValues)
                Log.i(TAG, "SMS saved to sent box")
            } catch (e: Exception) {
                Log.e(TAG, "Error saving SMS to sent box: ${e.message}")
                e.printStackTrace()
            }
        }
        
        /**
         * SMS'i siler
         */
        fun deleteSms(context: Context, id: String?, threadId: String?): Int {
            if (id == null || threadId == null) {
                Log.e(TAG, "Cannot delete SMS: id or threadId is null")
                return 0
            }
            
            return try {
                // content://sms URI'sini kullan
                val uri = Uri.parse("content://sms")
                
                // Sorgu kriterlerini belirle
                val selection = "${Telephony.Sms._ID} = ? AND ${Telephony.Sms.THREAD_ID} = ?"
                val selectionArgs = arrayOf(id, threadId)
                
                // Silme işlemini yap ve silinen satır sayısını döndür
                val deletedRows = context.contentResolver.delete(uri, selection, selectionArgs)
                
                if (deletedRows > 0) {
                    Log.i(TAG, "SMS deleted successfully: id=$id, threadId=$threadId")
                } else {
                    Log.w(TAG, "No SMS deleted with id=$id, threadId=$threadId")
                }
                
                deletedRows
            } catch (e: Exception) {
                Log.e(TAG, "Error deleting SMS: ${e.message}")
                e.printStackTrace()
                0
            }
        }
    }
}