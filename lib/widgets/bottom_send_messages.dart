// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sms_cubit.dart';

class SendingMessageBox extends StatelessWidget {
  SendingMessageBox({
    super.key,
    required this.textController,
    required this.address,
  });

  TextEditingController textController;

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AutoSizeTextField(
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16),
                maxLines: 5,
                minLines: 1,
                controller: textController,
                decoration: const InputDecoration(
                  hintText: "Mesajınızı yazın...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: textController.text.isEmpty ? Colors.grey.shade300 : Colors.teal,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                log("address: $address");
                log("text: ${textController.text}");
                
                // Telefon numarası veya mesaj boş ise işlemi durdur
                if (address.isEmpty || textController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen alıcı numarası ve mesaj girdiğinizden emin olun'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                
                try {
                  // Method Channel ile Kotlin kodunu çağır
                  var channel = const MethodChannel('com.dovahkin.sms_guard');
                  
                  // SMS gönder
                  final result = await channel.invokeMethod('sendSms', {
                    "address": address,
                    "body": textController.text
                  });
                  
                  log("SMS gönderme sonucu: $result");
                  
                  // Başarılı bildirim göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } catch (e) {
                  // Hata durumunda bildirim göster
                  log("SMS gönderme hatası: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("SMS gönderme hatası: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return; // Hata durumunda diğer işlemleri yapma
                }
                
                // SMS'i gönderildikten sonra veritabanına kaydet
                textController.clear();
                BlocProvider.of<SmsCubit>(context).onNewMessage(null);
                BlocProvider.of<SmsCubit>(context)
                    .filterMessageForAdress(address);
                BlocProvider.of<SmsCubit>(context).state.text = "";
              },
              icon: Icon(
                Icons.send_rounded,
                color: textController.text.isEmpty ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
