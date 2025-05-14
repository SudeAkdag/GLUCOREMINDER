import 'package:flutter/material.dart';
import 'package:gluco_reminder/acil_durum_sayfasi.dart';
import 'package:gluco_reminder/anasayfa.dart';
import 'package:gluco_reminder/beslenme_sayfasi.dart';
import 'package:gluco_reminder/egzersiz_sayfasi.dart';
import 'package:gluco_reminder/ilac_sayfasi.dart';
import 'package:gluco_reminder/randevu_sayfasi.dart';

class BottomNavigationSayfa extends StatefulWidget {
  const BottomNavigationSayfa({super.key});

  @override
  State<BottomNavigationSayfa> createState() => _BottomNavigationSayfaState();
}

class _BottomNavigationSayfaState extends State<BottomNavigationSayfa> {
  int secilenIndeks = 0;

  final List<Widget> sayfalar = [
    IlacSayfasi(),
    EgzersizSayfasi(),
    BeslenmeSayfasi(),
    HomeScreen(),
    RandevuSayfasi(),
    AcilDurumSayfasi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: sayfalar[secilenIndeks],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
            bottom: 10, left: 15, right: 15), // Boşluk eklendi
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30), // Yuvarlatılmış kenarlar
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.medication), label: "İlaç"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center), label: "Egzersiz"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.coffee), label: "Beslenme"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Anasayfa"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: "Randevu"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.warning), label: "Acil Durum"),
            ],
            currentIndex: secilenIndeks,
            onTap: (index) {
              setState(() {
                secilenIndeks = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[700], // Arka plan rengi
            selectedItemColor: Colors.white, // Seçili ikon rengi
            unselectedItemColor: Colors.white70, // Seçili olmayan ikon rengi
          ),
        ),
      ),
    );
  }
}
