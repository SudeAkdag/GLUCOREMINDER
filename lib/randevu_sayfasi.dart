import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:gluco_reminder/randevu_ekleme.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RandevuSayfasi(),
    );
  }
}

enum RandevuFiltre { gecmis, yaklasan }

class Randevu {
  final String id; // Firestore doküman ID'si
  final String doktorAdi;
  final String hastaneAdi;
  final String randevuTuru;
  final String tarih;
  final String saat;
  final String notlar;

  Randevu({
    required this.id,
    required this.doktorAdi,
    required this.hastaneAdi,
    required this.randevuTuru,
    required this.tarih,
    required this.saat,
    required this.notlar,
  });
}

class RandevuSayfasi extends StatefulWidget {
  @override
  _RandevuSayfasiState createState() => _RandevuSayfasiState();
}

class _RandevuSayfasiState extends State<RandevuSayfasi> {
  final Color randevuRenk = Color.fromARGB(255, 79, 210, 210);
  RandevuFiltre seciliFiltre = RandevuFiltre.yaklasan;

  // Firestore'dan randevuları filtreye göre çek
  Stream<List<Randevu>> randevulariGetir(RandevuFiltre filtre) {
    Query query = FirebaseFirestore.instance.collection('randevular');

    DateTime simdi = DateTime.now();
    Timestamp simdiTimestamp = Timestamp.fromDate(simdi);

    if (filtre == RandevuFiltre.yaklasan) {
      query = query.where('tarih', isGreaterThanOrEqualTo: simdiTimestamp);
    } else if (filtre == RandevuFiltre.gecmis) {
      query = query.where('tarih', isLessThan: simdiTimestamp);
    }

    query = query.orderBy('tarih', descending: filtre == RandevuFiltre.gecmis);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Randevu(
              id: doc.id,
              doktorAdi: doc['doktorAdi'],
              hastaneAdi: doc['hastaneAdi'],
              randevuTuru: doc['randevuTuru'],
              tarih: DateFormat('dd/MM/yyyy')
                  .format((doc['tarih'] as Timestamp).toDate()),
              saat: doc['saat'],
              notlar: doc['notlar'],
            ))
        .toList());
  }

  // Randevu silme
  void randevuSil(String docId) async {
    await FirebaseFirestore.instance
        .collection('randevular')
        .doc(docId)
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
              MaterialPageRoute(builder: (context) => Profil()),
            );
          },
        ),
        title: Text('Kullanıcı', style: TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Randevu Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    seciliFiltre = RandevuFiltre.yaklasan;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: seciliFiltre == RandevuFiltre.yaklasan
                      ? Colors.teal
                      : Color.fromARGB(255, 79, 210, 210),
                ),
                child: Text(
                  "Yaklaşan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    seciliFiltre = RandevuFiltre.gecmis;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: seciliFiltre == RandevuFiltre.gecmis
                      ? Colors.teal
                      : Color.fromARGB(255, 79, 210, 210),
                ),
                child: Text(
                  "Geçmiş",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Randevu>>(
              stream: randevulariGetir(seciliFiltre),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Randevu bulunamadı"));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final randevu = snapshot.data![index];
                    return Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: randevuRenk,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Randevu Türü: ${randevu.randevuTuru}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              Text('Tarih: ${randevu.tarih}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              Text('Saat: ${randevu.saat}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RandevuDetaySayfasi(
                                    randevu: randevu,
                                    onSil: () {
                                      randevuSil(randevu.id);
                                      Navigator.pop(
                                          context); // Detay sayfasından çık
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RandevuEkleme()),
          );
        },
        backgroundColor: Color.fromARGB(255, 79, 210, 210),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class RandevuDetaySayfasi extends StatelessWidget {
  final Randevu randevu;
  final VoidCallback onSil;

  const RandevuDetaySayfasi(
      {super.key, required this.randevu, required this.onSil});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Randevu Detayı")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                    20.0), // metinleri kenarlardan içeri alır
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // sola hizalama
                  children: [
                    Text('Doktor Adı: ${randevu.doktorAdi}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                    SizedBox(height: 15),
                    Text('Hastane Adı: ${randevu.hastaneAdi}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                    SizedBox(height: 15),
                    Text('Randevu Türü: ${randevu.randevuTuru}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                    SizedBox(height: 15),
                    Text('Tarih: ${randevu.tarih}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                    SizedBox(height: 15),
                    Text('Saat: ${randevu.saat}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                    SizedBox(height: 15),
                    Text('Notlar: ${randevu.notlar}',
                        style: TextStyle(color: Colors.black, fontSize: 20)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    onSil(); // Randevuyu silmek için callback'i çağır
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 182, 60, 90),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        "Randevuyu Sil",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
