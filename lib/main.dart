import 'dart:async';
import 'dart:io';

import 'package:another_telephony/telephony.dart' show Telephony;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import 'cubit/sms_cubit.dart';
import 'view/home_view.dart';

// Global erişim için GetIt örneği
final getIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // SmsCubit'in kaydı
  final smsCubit = SmsCubit();
  getIt.registerSingleton<SmsCubit>(smsCubit);

  // SMS ve telefon izinleri
  if (await Telephony.instance.requestPhoneAndSmsPermissions == false) {
    await Telephony.instance.requestPhoneAndSmsPermissions;
  }
  
  // Android 13+ için bildirim izni
  if (Platform.isAndroid) {
    // Bildirim iznini sorgula
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      // Bildirim izni yoksa iste
      await Permission.notification.request();
      print("Bildirim izni durumu: ${await Permission.notification.status}");
    }
  }

  // Method channel işlemleri
  var channel = const MethodChannel('com.dovahkin.sms_guard');
  await channel.invokeMethod('bert').then((value) => print("value: $value"));
  
  // Event channel ile SMS alımı - Doğrudan native'den bildirim almak için
  const EventChannel eventChannel = EventChannel('com.dovahkin.sms_guard/sms');
  eventChannel.receiveBroadcastStream().listen((dynamic message) {
    print("EventChannel'dan SMS alındı: $message");
    
    // SMS'i SmsCubit'e iletiyoruz
    getIt<SmsCubit>().onNewMessage(message);
    
  }, onError: (dynamic error) {
    print("EventChannel hatası: $error");
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SmsCubit>(
          create: (context) => getIt<SmsCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'SMS Guard',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[50],
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 1,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.teal),
            titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
