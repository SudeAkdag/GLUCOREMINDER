import 'package:flutter/material.dart';
import 'package:gluco_reminder/bottom_nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // bunu ekle

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null); // Türkçe yerelleştirmeyi yükle
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: BottomNavigationSayfa(),
    );
  }
}
