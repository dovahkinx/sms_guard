// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' show SmsMessage;
import 'package:sms_guard/services/sms_remover.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubit/sms_cubit.dart';
import '../widgets/bottom_send_messages.dart';

class MessageScreen extends StatelessWidget {
  final String name;
  final String address;
  final TextEditingController textController = TextEditingController();

  MessageScreen({super.key, required this.name, required this.address});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmsCubit, SmsState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _appbar(context),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: state.filtingMessages.length,
                  itemBuilder: (BuildContext context, int index) {
                    var message = state.filtingMessages[index];
                    
                    // Zaman damgası ekleyelim
                    final bool showDate = index == state.filtingMessages.length - 1 || 
                      _shouldShowDate(state.filtingMessages[index], 
                                     index < state.filtingMessages.length - 1 
                                       ? state.filtingMessages[index + 1] 
                                       : null);
                    
                    return Column(
                      children: [
                        if (showDate) _dateHeader(message),
                        _chatBubble(message, context),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SendingMessageBox(
                  textController: textController,
                  address: address,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _appbar(BuildContext context) {
    return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: name.startsWith(RegExp(r'[0-9]'))
            ? Text(
                name,
                style: const TextStyle(color: Colors.black87),
              )
            : ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  name,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  address,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ));
  }
  
  // Helper function to parse dates safely
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    
    // First try to parse as integer timestamp
    try {
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      
      String dateStr = dateValue.toString();
      
      // Check if the string contains a date-time format
      if (dateStr.contains('-') && dateStr.contains(':')) {
        try {
          return DateTime.parse(dateStr);
        } catch (_) {
          // If parsing as DateTime fails, continue to other methods
        }
      }
      
      // Try to parse as integer timestamp
      try {
        int timestamp = int.parse(dateStr);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (_) {
        // If all parsing fails, return current time
        return DateTime.now();
      }
    } catch (_) {
      return DateTime.now();
    }
  }
  
  // Tarih başlığını göster
  Widget _dateHeader(SmsMessage message) {
    final date = _parseDate(message.date);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    String dateText;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      dateText = "Bugün";
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateText = "Dün";
    } else {
      dateText = DateFormat('d MMMM y', 'tr_TR').format(date);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
  
  // İki mesaj arasında tarih farkı varsa tarih başlığını göstermeye karar ver
  bool _shouldShowDate(SmsMessage current, SmsMessage? previous) {
    if (previous == null) return true;
    
    final currentDate = _parseDate(current.date);
    final previousDate = _parseDate(previous.date);
    
    return currentDate.year != previousDate.year || 
           currentDate.month != previousDate.month || 
           currentDate.day != previousDate.day;
  }

  Widget _chatBubble(SmsMessage message, BuildContext context) {
    var position = Offset.zero;
    
    // Mesaj türünü belirle - Gönderilen mesajları doğru tespit için birden fazla kontrol
    final bool isSent = message.kind.toString() == "SmsMessageKind.Sent" || 
                       (message.address != null && 
                        (message.address == address || 
                         "+90$address" == message.address ||
                         message.address == "+90$address"));
    
    // Mesaj saati - Güvenli şekilde tarihi ayrıştır
    final messageTime = _parseDate(message.date);
    final formattedTime = DateFormat('HH:mm').format(messageTime);
    
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        position = details.globalPosition;
      },
      onLongPress: () {
        final screenSize = MediaQuery.of(context).size;

        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
              position.dx, position.dy, screenSize.width, 0),
          items: <PopupMenuEntry>[
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: const [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('Kopyala'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
        ).then((value) async {
          if (value == 'copy') {
            Clipboard.setData(ClipboardData(text: message.body!));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mesaj kopyalandı'),
                  backgroundColor: Colors.teal,
                  duration: Duration(seconds: 1),
                )
              );
            }
          } else if (value == 'delete') {
            try {
              final result = await SmsRemover().removeSmsById(
                message.id!.toString(), 
                message.threadId!.toString()
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result),
                    backgroundColor: Colors.teal,
                    duration: Duration(seconds: 1),
                  )
                );
                BlocProvider.of<SmsCubit>(context).onNewMessage(null);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("SMS silme hatası: $e"),
                    backgroundColor: Colors.redAccent,
                  )
                );
              }
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSent) // Gelen mesaj ise avatar göster
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 6),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: isSent ? Colors.teal.shade500 : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSent ? 16 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Linkify(
                      onOpen: (link) {
                        launchUrl(Uri.parse(link.url));
                      },
                      text: message.body ?? "",
                      style: TextStyle(
                        color: isSent ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                      linkStyle: TextStyle(
                        color: isSent ? Colors.white : Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSent ? Colors.white.withOpacity(0.8) : Colors.black45,
                            ),
                          ),
                          if (isSent) 
                            const SizedBox(width: 4),
                          if (isSent) 
                            Icon(
                              Icons.done_all,
                              size: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
