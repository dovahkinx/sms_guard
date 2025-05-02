// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sms_cubit.dart';
import '../services/sms_service.dart';
import 'chat_messages_view.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  TextEditingController textEditingController = TextEditingController();
  TextEditingController textController = TextEditingController();
  
  // SmsService instance
  final SmsService _smsService = SmsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text("Mesaj Gönder", style: TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocConsumer<SmsCubit, SmsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    BlocProvider.of<SmsCubit>(context)
                        .prinnt(textEditingController.text);

                    context
                        .read<SmsCubit>()
                        .resultContactWithTextEditingController(
                            textEditingController.text);
                  },
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: "Alıcı",
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.sendResult.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        onTap: () {
                          state.name = state.sendResult[index].displayName;
                          state.text =
                              state.sendResult[index].phones.first.number;

                          log(state.name!);

                          textEditingController.text =
                              state.sendResult[index].displayName == ""
                                  ? state.sendResult[index].phones.first.number
                                  : state.sendResult[index].displayName;
                          textEditingController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: textEditingController.text.length));
                          context
                              .read<SmsCubit>()
                              .resultContactWithTextEditingController("");
                        },
                        title: state.sendResult[index].displayName == ""
                            ? Text(state.sendResult[index].phones.first.number)
                            : Text(state.sendResult[index].displayName));
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              BlocConsumer<SmsCubit, SmsState>(
                listener: (context, state) {},
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 60,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Color.fromARGB(255, 240, 240, 240),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: AutoSizeTextField(
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 17),
                                maxLines: null,
                                controller: textController,
                                decoration: const InputDecoration(
                                  hintTextDirection: TextDirection.ltr,
                                  hintText: "Metin mesajı",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all(Colors.white),
                                  shape: WidgetStateProperty.all(
                                      const CircleBorder())),
                              color: Colors.grey,
                              onPressed: () async {
                                // Alıcı ve mesaj kontrolü
                                if (state.text == null || textController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lütfen alıcı numarası ve mesaj girdiğinizden emin olun'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                log("SMS gönderiliyor -> Adres: ${state.text}, Mesaj: ${textController.text}");
                                
                                // Yeni SmsService ile SMS gönderme
                                final result = await _smsService.sendSms(
                                  phoneNumber: state.text!,
                                  message: textController.text,
                                );
                                
                                // Başarılı olup olmadığını kontrol et
                                if (result.contains("başarıyla")) {
                                  // Başarılı ise yeşil bildirim göster
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  
                                  // Mesaj kutusunu temizle
                                  textController.clear();
                                  
                                  // UI'ı güncelle
                                  BlocProvider.of<SmsCubit>(context).onNewMessage(null);
                                  BlocProvider.of<SmsCubit>(context).filterMessageForAdress(state.text);
                                  
                                  log("Mesaj detay sayfasına yönlendiriliyor");
                                  
                                  // Mesaj detay sayfasına git
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessageScreen(
                                        name: state.name ?? state.text!,
                                        address: state.text!,
                                      ),
                                    ),
                                  );
                                  
                                  // State'i temizle
                                  BlocProvider.of<SmsCubit>(context).state.text = "";
                                  if (BlocProvider.of<SmsCubit>(context).state.controller != null) {
                                    BlocProvider.of<SmsCubit>(context).state.controller!.clear();
                                  }
                                } else {
                                  // Hata varsa kırmızı bildirim göster
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.send,
                                  size: 30,
                                  color: textController.text.isEmpty
                                      ? Colors.grey
                                      : Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
