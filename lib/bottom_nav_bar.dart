import 'package:flutter/material.dart';
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
  int secilenIndeks = 2;

  final List<Widget> sayfalar = [
    IlacSayfasi(),
    EgzersizSayfasi(),
    HomeScreen(),
    BeslenmeSayfasi(),
    RandevuSayfasi(),
  ];

  final List<Color> seciliRenkler = [
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.orange,
    Colors.purple,
  ];

  final List<IconData> ikonlar = [
    Icons.medication,
    Icons.fitness_center,
    Icons.home,
    Icons.coffee,
    Icons.calendar_today,
  ];

  final List<String> etiketler = [
    "İlaç",
    "Egzersiz",
    "Anasayfa",
    "Beslenme",
    "Randevu",
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Eğer kullanıcı anasayfada değilse, anasayfaya geri dön
        if (secilenIndeks != 2) {
          setState(() {
            secilenIndeks = 2;
          });
          return false; // Geri çıkışı engelle
        }
        return true; // Anasayfadaysa çıkışı izin ver
      },
      child: Scaffold(
        body: sayfalar[secilenIndeks],
        bottomNavigationBar: secilenIndeks == 2
            ? Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BottomAppBar(
                    color: const Color.fromARGB(255, 244, 237, 237),
                    child: SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(5, (index) {
                          final bool secili = index == secilenIndeks;
                          final Color renk =
                              secili ? seciliRenkler[index] : Colors.black;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                secilenIndeks = index;
                              });
                            },
                            child: SizedBox(
                              width: 60,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ikonlar[index],
                                    size: secili ? 28 : 22,
                                    color: renk,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    etiketler[index],
                                    style: TextStyle(
                                      color: renk,
                                      fontSize: secili ? 13 : 11,
                                      fontWeight: secili
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
