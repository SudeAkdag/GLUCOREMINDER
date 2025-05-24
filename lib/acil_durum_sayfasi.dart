import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gluco_reminder/profil.dart';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AcilDurumSayfasi(),
  ));
}

class AcilDurumSayfasi extends StatefulWidget {
  const AcilDurumSayfasi({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AcilDurumSayfasiState createState() => _AcilDurumSayfasiState();
}

class _AcilDurumSayfasiState extends State<AcilDurumSayfasi> {
  final Color primaryColor = const Color(0xFF76C7C0);
  final Color bgColor = const Color(0xFFFFF8E1); // Krem rengi

  final List<Map<String, Color>> renkListesi = [
    {
      'bgColor': Colors.blue.shade100,
      'textColor': Colors.blue.shade800,
    },
    {
      'bgColor': Colors.orange.shade100,
      'textColor': Colors.orange.shade800,
    },
    {
      'bgColor': Colors.green.shade100,
      'textColor': Colors.green.shade800,
    },
    {
      'bgColor': Colors.purple.shade100,
      'textColor': Colors.purple.shade800,
    },
  ];

  Map<String, dynamic> rastgeleRenk() {
    return renkListesi[Random().nextInt(renkListesi.length)];
  }

  void kisiEkle() {
    String ad = '';
    String soyad = '';
    String yakinlik = '';
    String telefon = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text("Acil Durum Kişisi", style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: "Ad",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ad = value,
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Soyad",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => soyad = value,
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Yakınlık Derecesi",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => yakinlik = value,
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Telefon Numarası",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => telefon = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("İptal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text("Ekle"),
              onPressed: () async {
                if (ad.isNotEmpty &&
                    soyad.isNotEmpty &&
                    yakinlik.isNotEmpty &&
                    telefon.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('acil_kisiler')
                      .add({
                    "ad": ad,
                    "soyad": soyad,
                    "yakinlik": yakinlik,
                    "telefon": telefon,
                  });
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void kisiSil(String kisiId) async {
    await FirebaseFirestore.instance
        .collection('acil_kisiler')
        .doc(kisiId)
        .delete();
  }

  void kisiSecenekleri(BuildContext context, Map<String, dynamic> kisi) {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[400],
                    child: Icon(Icons.call, color: Colors.white),
                  ),
                  title: Text("Ara"),
                  onTap: () async {
                    final telUrl = Uri.parse("tel:${kisi['telefon']}");
                    if (await canLaunchUrl(telUrl)) {
                      await launchUrl(telUrl);
                    } else {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Arama başlatılamadı')),
                      );
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[400],
                    child: Icon(Icons.message, color: Colors.white),
                  ),
                  title: Text("Mesaj Gönder"),
                  onTap: () async {
                    final smsUrl = Uri.parse("sms:${kisi['telefon']}");
                    if (await canLaunchUrl(smsUrl)) {
                      await launchUrl(smsUrl);
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          padding: EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 12),
          color: bgColor, // Sadece renk veriyoruz, border yok
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilSayfasi()),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.teal),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Kullanıcı",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "Acil Durum Sayfası",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('acil_kisiler').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
              "Kayıtlı acil durum kişisi yok.",
              style: TextStyle(fontSize: 16),
            ));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var kisi = snapshot.data!.docs[index];
              final renk = renkListesi[index % renkListesi.length];

              var veri = kisi.data() as Map<String, dynamic>;

              return Card(
                color: renk['bgColor'],
                elevation: 6,
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  leading: CircleAvatar(
                    backgroundColor: renk['textColor'],
                    radius: 26,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    "${veri['ad']} ${veri['soyad']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: renk['textColor'],
                    ),
                  ),
                  subtitle: Text(
                    "${veri['yakinlik']} • ${veri['telefon']}",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => kisiSil(kisi.id),
                  ),
                  onTap: () => kisiSecenekleri(context, veri),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: kisiEkle,
        backgroundColor: primaryColor,
        icon: Icon(Icons.add),
        label: Text("Kişi Ekle"),
      ),
    );
  }
}
