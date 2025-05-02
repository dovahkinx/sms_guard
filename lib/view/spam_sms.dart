import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sms_cubit.dart';

class SpamScreen extends StatelessWidget {
  const SpamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Spam Smsler",
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: BlocConsumer<SmsCubit, SmsState>(
          listener: (context, state) {},
          builder: (context, state) {
            return ListView.builder(
              itemCount: state.spam.length,
              itemBuilder: (BuildContext context, int index) {
                var spam = state.spam[index];
                return ListTile(
                    trailing: IconButton(
                      onPressed: () {
                        BlocProvider.of<SmsCubit>(context)
                            .deleteSpam(spam, context);
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    title: Text(spam.address,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    subtitle: Text(spam.message,
                        style: const TextStyle(fontWeight: FontWeight.bold)));
              },
            );
          },
        ),
      ),
    );
  }
}
