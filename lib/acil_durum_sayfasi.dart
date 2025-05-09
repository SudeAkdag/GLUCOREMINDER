import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gluco_reminder/profil.dart';

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
  void kisiEkle() {
    String ad = '';
    String soyad = '';
    String yakinlik = '';
    String telefon = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Acil Durum Kişisi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Ad"),
                onChanged: (value) => ad = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Soyad"),
                onChanged: (value) => soyad = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Yakınlık Derecesi"),
                onChanged: (value) => yakinlik = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Telefon Numarası"),
                keyboardType: TextInputType.phone,
                onChanged: (value) => telefon = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("İptal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 79, 210, 210),
            child: Icon(Icons.person, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfilSayfasi()), //profil sayfasına geçiş
            );
          },
        ),
        title: Text('Kullanıcı', style: TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Acil Durum Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('acil_kisiler').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Kayıtlı acil durum kişisi yok."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var kisi = snapshot.data!.docs[index];
              return Card(
                color: Colors.teal[100],
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("${kisi['ad']} ${kisi['soyad']}"),
                  subtitle: Text("${kisi['yakinlik']} - ${kisi['telefon']}"),
                  leading: Icon(Icons.person),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => kisiSil(kisi.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: kisiEkle,
        child: Icon(Icons.add),
      ),
    );
  }
}
