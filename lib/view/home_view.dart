import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' show SmsQuery;

import 'package:sms_guard/constant/constant.dart';
import 'package:sms_guard/services/sms_remover.dart';
import 'package:sms_guard/view/chat_messages_view.dart';
import 'package:sms_guard/view/send_sms_view.dart';
import 'package:sms_guard/view/spam_sms.dart';
import 'package:sms_guard/widgets/search_button.dart';
import '../cubit/sms_cubit.dart';

import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // isloading getir
      if (context.read<SmsCubit>().state.isInit == false) {
        print("resumed");
        context.read<SmsCubit>().getMessages();
      }
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      print("paused");
      // isloading getir
      context.read<SmsCubit>().state.isInit = false;
    }
    super.didChangeAppLifecycleState(state);
  }

  bool visible = true;

  late final ScrollController controller = ScrollController()
    ..addListener(() {
      //add more logic for your case
      if (controller.position.userScrollDirection == ScrollDirection.reverse &&
          visible) {
        visible = false;
        setState(() {
          print("visible: $visible");
        });
      }
      if (controller.position.userScrollDirection == ScrollDirection.forward &&
          !visible) {
        visible = true;
        setState(() {});
      }
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1.0 : 0.0,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SendScreen(),
              ),
            );
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.message),
        ),
      ),
      appBar: appbar(context),
      body: Center(
          child: BlocConsumer<SmsCubit, SmsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : Column(
                  children: [
                    Visibility(visible: visible, child: const SearchButton()),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: state.myMessages.length,
                        itemBuilder: (context, index) {
                          var position = Offset.zero;
                          var thread = state.myMessages[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: GestureDetector(
                              onLongPressStart:
                                  (LongPressStartDetails details) {
                                position = details.globalPosition;
                              },
                              onLongPress: () {
                                final screenSize = MediaQuery.of(context).size;

                                showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(position.dx,
                                      position.dy, screenSize.width, 0),
                                  items: <PopupMenuEntry>[
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text('Sil'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).then((value) async {
                                  if (value == 'delete') {
                                    SmsQuery query = SmsQuery();
                                    var list = await query.querySms(
                                      threadId: thread.threadId,
                                    );

                                    for (var item in list) {
                                      await SmsRemover()
                                          .removeSmsById(
                                              item.id!.toString(), 
                                              item.threadId!.toString()
                                          )
                                          .then((value) => 
                                              print("value: $value"));
                                    }

                                    if (context.mounted) {
                                      context
                                          .read<SmsCubit>()
                                          .onNewMessage(null);
                                    }
                                  }
                                });
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                onTap: () {
                                  context
                                      .read<SmsCubit>()
                                      .filterMessageForAdress(thread.address);
                                  _navigateToChatScreen(
                                      thread.address, thread.name);
                                },
                                leading: CircleAvatar(
                                  radius:
                                      MediaQuery.of(context).size.width * 0.06,
                                  backgroundColor: Colors.teal,
                                  child: thread.name == ""
                                      ? _circleAvatarText("aaaa")
                                      : _circleAvatarText(thread.name),
                                ),
                                trailing: Text(
                                  _dateConvert(thread.date.toString()),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                title: Text(
                                  thread.name!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle:
                                    Text(_subtitleConvert(thread.lastMessage),
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
        },
      )),
    );
  }

  _navigateToChatScreen(address, name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          address: address,
          name: name,
        ),
      ),
    );
  }

  appbar(BuildContext context) {
    return AppBar(
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SpamScreen(),
              ),
            );
          },
          icon: const Icon(Icons.block, color: Colors.red),
        ),
      ],
      title: const Text(
        Constant.homeTitle,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  _circleAvatarText(text) {
    if (text.toString().startsWith(RegExp(r'[0-9]')) ||
        text.toString().startsWith("+")) {
      return const Icon(
        Icons.person,
        color: Colors.white,
        size: 30,
      );
    } else {
      return Text(text.toString().substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 20));
    }
  }

  _subtitleConvert(text) {
    if (text.toString().split(" ").length > 8) {
      return "${text.toString().split(" ").sublist(0, 8).join(" ")}...";
    } else {
      return text.toString();
    }
  }

  _dateConvert(date) {
    DateTime messageDate = DateTime.parse(date);
    DateTime now = DateTime.now();

    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      // Bugün gönderilmiş bir mesaj
      return '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day - 1) {
      // Dün gönderilmiş bir mesaj
      return 'Dün ${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.year == now.year) {
      // Aynı yıl içindeki önceki günlerde gönderilmiş bir mesaj
      String monthName = DateFormat.MMMM('tr_TR').format(messageDate);
      return '${messageDate.day} $monthName ';
    } else {
      // Farklı yıllarda gönderilmiş bir mesaj
      return '${messageDate.year}-${messageDate.month.toString().padLeft(2, '0')}-${messageDate.day.toString().padLeft(2, '0')} ${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    }
  }
}
