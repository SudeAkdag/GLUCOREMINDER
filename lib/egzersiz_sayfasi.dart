import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gluco_reminder/bisiklet.dart';
import 'package:gluco_reminder/kosu.dart';
import 'package:gluco_reminder/yurume.dart';
import 'package:gluco_reminder/yuzme.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false, // Debug bandını kaldırma
    home: EgzersizSayfasi(),
  ));
}

class EgzersizSayfasi extends StatefulWidget {
  EgzersizSayfasi({super.key});

  final List<Map<String, dynamic>> egzersizler = [
    {'icon': Icons.pool, 'name': 'Yüzme'},
    {'icon': Icons.directions_run, 'name': 'Koşu'},
    {'icon': Icons.directions_walk, 'name': 'Yürüyüş'},
    {'icon': Icons.pedal_bike, 'name': 'Bisiklet'},
  ];

  @override
  State<EgzersizSayfasi> createState() => _EgzersizSayfasi();
}

class _EgzersizSayfasi extends State<EgzersizSayfasi>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimationController;
  int? heartRate ; // Varsayılan kalp atış hızı (BPM)
  String? _latestBpm;
  double _totalCalories = 0;
  double _totalSeconds = 0;
  

@override
void initState() {
  super.initState();
  _getLatestBpm(); // Sayfa ilk açıldığında bpm kutusunu doldur
  _heartAnimationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 800),
    lowerBound: 0.0,
    upperBound: 1.0,
  )..repeat(reverse: true);

  loadWaterLevel(); 
  _fetchTodayTotals();

  // Opsiyonel: Verileri her 1 saniyede bir güncelle
  Timer.periodic(Duration(seconds: 1), (timer) {
    _fetchTodayTotals();
  });
  
}
Future<List<Map<String, dynamic>>> _getTodayDataFromCollection(String collectionName) async {
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day);
  DateTime endOfDay = startOfDay.add(Duration(days: 1));

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection(collectionName)
      .where('zaman_damgasi', isGreaterThanOrEqualTo: startOfDay)
      .where('zaman_damgasi', isLessThan: endOfDay)
      .get();

  return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
}

Future<void> _fetchTodayTotals() async {
  List<String> collections = ['bisiklet_verileri', 'yuzme_verileri', 'yurume_verileri', 'kosu_verileri'];

  int totalSeconds = 0;
  double totalCalories = 0;

  for (String col in collections) {
    List<Map<String, dynamic>> dataList = await _getTodayDataFromCollection(col);

    for (var data in dataList) {
      int sureInSeconds = (data['sure'] ?? 0); // doğrudan saniye cinsinden

      totalSeconds += sureInSeconds;
      totalCalories += (data['kalori'] ?? 0).toDouble();
    }
  }

  if (mounted) {
    setState(() {
      _totalSeconds = totalSeconds.toDouble(); // UI'da saniyeden dakika+saniyeye çevireceğiz
      _totalCalories = totalCalories;
    });
  }
}

void _getLatestBpm() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('kalp_verileri')
      .orderBy('kayitZamani', descending: true)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    setState(() {
      _latestBpm = snapshot.docs.first['kalpAtisi'].toString();
    });
  }
}


  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
    
  }

  List<Map<String, dynamic>> egzersizVerileri = [];

  double waterLevel = 0.0; // Su seviyesi (litre cinsinden)
  static const double maxWater = 2.0; // Maksimum su seviyesi (2 litre)

void _increaseWater() {
  setState(() {
    waterLevel = (waterLevel + 0.25).clamp(0.0, maxWater);
  });
  saveWaterLevel(); // Kaydı hemen veritabanına yaz
}

  Future<void> saveWaterLevel() async {
  final bugun = DateTime.now();
  final tarihStr = "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";

  await FirebaseFirestore.instance
      .collection('su_verisi')
      .doc('aktif_veri')
      .set({
        'su_seviyesi': waterLevel,
        'tarih': tarihStr,
      });
}

Future<void> loadWaterLevel() async {
  final doc = await FirebaseFirestore.instance
      .collection('su_verisi')
      .doc('aktif_veri')
      .get();

  final bugun = DateTime.now();
  final bugunStr = "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";

  if (doc.exists) {
    final data = doc.data()!;
    final firestoreTarih = data['tarih'];

    if (firestoreTarih == bugunStr) {
      setState(() {
        waterLevel = (data['su_seviyesi'] as num).toDouble();
      });
    } else {
      // Tarih değiştiyse sıfırla
      setState(() {
        waterLevel = 0.0;
      });
      // Firestore'da da sıfırlanmış olarak güncelle
      await FirebaseFirestore.instance
          .collection('su_verisi')
          .doc('aktif_veri')
          .set({
            'su_seviyesi': 0.0,
            'tarih': bugunStr,
          });
    }
  }
}
  void _egzersizSec(String egzersizAdi) {
    Widget yeniSayfa;

    switch (egzersizAdi) {
      case 'Koşu':
        yeniSayfa = KosuSayfasi();
        break;
      case 'Yüzme':
        yeniSayfa = YuzmeSayfasi();
        break;
      case 'Yürüyüş':
        yeniSayfa = YurumeSayfasi();
        break;
      case 'Bisiklet':
        yeniSayfa = BisikletSayfasi();
        break;
      default:
        return; // Geçersiz bir seçim olursa fonksiyon sonlanır
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => yeniSayfa),
    );
  }

String _hesaplaUykuSuresi(String yatmaSaati, String uyanmaSaati) {
  final yatma = TimeOfDay(
    hour: int.parse(yatmaSaati.split(":")[0]),
    minute: int.parse(yatmaSaati.split(":")[1]),
  );
  final uyanma = TimeOfDay(
    hour: int.parse(uyanmaSaati.split(":")[0]),
    minute: int.parse(uyanmaSaati.split(":")[1]),
  );

  final yatmaDakika = yatma.hour * 60 + yatma.minute;
  final uyanmaDakika = uyanma.hour * 60 + uyanma.minute;

  int fark = uyanmaDakika - yatmaDakika;
  if (fark < 0) fark += 1440; // gece yarısı geçtiyse

  final saat = fark ~/ 60;
  final dakika = fark % 60;

  return "$saat saat $dakika dakika";
}
  @override
  Widget build(BuildContext context) {
    int minutes = (_totalSeconds ~/ 60);
    int seconds = (_totalSeconds % 60).toInt();

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
        title: Text(
          'Kullanıcı',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Egzersiz Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // İçeriğin taşmasını engellemek için kaydırılabilir alan
        child: Column(
          children: [
            // EGZERSİZLER Başlığı
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  "EGZERSİZLER",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
            // 4 Daire İçin Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.egzersizler.map((egzersiz) {
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _egzersizSec(egzersiz['name']); // Sayfaya yönlendir
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        child: Icon(egzersiz['icon'],
                            size: 24, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      egzersiz['name'],
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none, // Alt çizgi kaldırıldı
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Column(
  children: [
    Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 170,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.pink[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                  
                    "Toplam Süre",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                  
                    "$minutes dakika $seconds saniye",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(width: 30),
            Container(
              width: 170,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.pink[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Toplam Kalori",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${_totalCalories.toStringAsFixed(4)} kcal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
  ],
),

            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Su Tüketimi Container'ı
                Container(
                  width: 175, // Dar bir genişlik
                  height: 250, // Uzun bir yükseklik
                  padding: EdgeInsets.all(8), // Kenarlardan boşluk
                  decoration: BoxDecoration(
                    color: Colors.blue[200], // Su için mavi renk
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Su Tüketimi",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      60), //  Su animasyonunu biraz yukarı kaydır
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                width: 100,
                                height: 175 * (waterLevel / maxWater),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(0, 0, 255, 0.6),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                    top: Radius.circular(
                                        waterLevel > 0 ? 12 : 0),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "${(waterLevel * 1000).toStringAsFixed(0)} ml",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 1,
                              child: ElevatedButton(
                                onPressed: _increaseWater,
                                child: const Text("+250ml"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(width: 30), // Aralık
Container(
  width: 175, // Dar bir genişlik
  height: 250, // Uzun bir yükseklik
  padding: EdgeInsets.all(8), // Kenarlardan boşluk
  decoration: BoxDecoration(
    color: Colors.red[200], // Kalp atışı için kırmızı renk
    borderRadius: BorderRadius.circular(15),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Kalp Atışı Başlığı ve Ayar Butonu
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Kalp Atışı",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz), // Üç nokta ikonu gibi küçük bir buton
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // Veri giriş alanlarını burada tanımlayacağız
                  TextEditingController heartRateController = TextEditingController();
                  TextEditingController systolicController = TextEditingController();
                  TextEditingController diastolicController = TextEditingController();
                  TextEditingController measurementTimeController = TextEditingController();

                  return AlertDialog(
                    title: Text("Kalp Verileri"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: heartRateController,
                            decoration: InputDecoration(labelText: "Kalp Atışı (bpm)"),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: systolicController,
                            decoration: InputDecoration(labelText: "Büyük Tansiyon (mmHg)"),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: diastolicController,
                            decoration: InputDecoration(labelText: "Küçük Tansiyon (mmHg)"),
                            keyboardType: TextInputType.number,
                          ),
                         TextField(
  controller: measurementTimeController,
  decoration: InputDecoration(labelText: "Son Ölçüm Zamanı"),
  readOnly: true, // Kullanıcı manuel yazamasın, sadece picker'dan seçsin
  onTap: () async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Tarihi istediğin formata çeviriyoruz
        String formattedDateTime = "${fullDateTime.day.toString().padLeft(2, '0')}/"
            "${fullDateTime.month.toString().padLeft(2, '0')}/"
            "${fullDateTime.year} "
            "${pickedTime.format(context)}";

        measurementTimeController.text = formattedDateTime;
      }
    }
  },
),

                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text("İptal"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
      TextButton(
  child: Text("Kaydet"),
  onPressed: () async {
    int? kalpAtisiVerisi = int.tryParse(heartRateController.text);
    int? buyukTansiyon = int.tryParse(systolicController.text);
    int? kucukTansiyon = int.tryParse(diastolicController.text);
    String olcumZamani = measurementTimeController.text;

    if (kalpAtisiVerisi != null &&
        buyukTansiyon != null &&
        kucukTansiyon != null &&
        olcumZamani.isNotEmpty) {
      
      // Veriyi kaydet
      await FirebaseFirestore.instance.collection('kalp_verileri').add({
        'kalpAtisi': kalpAtisiVerisi,
        'buyukTansiyon': buyukTansiyon,
        'kucukTansiyon': kucukTansiyon,
        'olcumZamani': olcumZamani,
        'kayitZamani': FieldValue.serverTimestamp(),
      });

      _getLatestBpm();

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları geçerli şekilde doldurun')),
      );
    }
  },
),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      // Atan Kalp Animasyonu
      Expanded(
        child: AnimatedBuilder(
          animation: _heartAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.5 +
                  0.3 *
                      _heartAnimationController
                          .value, // Büyüyüp küçülen kalp
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 60,
              ),
            );
          },
        ),
      ),

      // Kullanıcının Kalp Atışı Değeri
   Container(
  height: 30,
  width: 100, // <<< SABİT yükseklik ekliyoruz
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
  ),
  alignment: Alignment.center, // <<< Yazıyı ortalamak için
  child: Text(
       _latestBpm != null ? '$_latestBpm bpm' : '',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),
    ],
  ),
),
              ],
            ),
            SizedBox(height: 25),
  Stack(
  children: [
    // Arka plan uyku kartı
    Container(
      height: 180,
      width: double.infinity,
      margin: EdgeInsets.only(left: 8, right: 8, top: 8), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage("assets/gece.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Uyku Süresi",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
           FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('uyku_verileri')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
      .where('timestamp', isLessThan: Timestamp.fromDate(
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1)))
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text(
        "",
        style: TextStyle(color: Colors.white, fontSize: 28),
      );
    }
                final veri = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final uykuSuresi = _hesaplaUykuSuresi(veri['yatma_saati'], veri['uyanma_saati']);
                final hedefUyku = veri['hedef_saat'] ?? "Tanımsız";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uykuSuresi,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Hedeflenen uyku: $hedefUyku",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),

    // Sağ alt köşeye ekleme butonu
    Positioned(
      right: 26,
      bottom: 16,
      child: FloatingActionButton.small(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SleepFormPopup(),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    ),
  ],
)

          ],
        ),
      ),
      
    );
  }
}
class SleepFormPopup extends StatefulWidget {
  @override
  _SleepFormPopupState createState() => _SleepFormPopupState();
}

class _SleepFormPopupState extends State<SleepFormPopup> {

  @override
  void dispose() {
   // hedefSaatController.dispose();
   _hedefSaatiGetir();
    super.dispose();
  }
  Future<void> _hedefSaatiGetir() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('uyku_verileri')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final veri = snapshot.docs.first.data();
    setState(() {
      hedefSaatController.text = veri['hedef_saat'] ?? '';
    });
  }
}

Future<void> _uykuVerisiniKaydet() async {
  if (bedTime != null && wakeTime != null && hedefSaatController.text.isNotEmpty) {
    try {
      final now = DateTime.now();
      final bugunBaslangic = DateTime(now.year, now.month, now.day);
      final bugunBitis = bugunBaslangic.add(Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('uyku_verileri')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(bugunBaslangic))
          .where('timestamp', isLessThan: Timestamp.fromDate(bugunBitis))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bugün için zaten bir veri eklediniz.")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('uyku_verileri').add({
        'yatma_saati': bedTime!.format(context),
        'uyanma_saati': wakeTime!.format(context),
        'mood': mood,
        'hedef_saat': hedefSaatController.text,
        'timestamp': Timestamp.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Lütfen tüm alanları doldurun")),
    );
  }
}

  TimeOfDay? bedTime;
  TimeOfDay? wakeTime;
  String mood = "İyi";
  TextEditingController hedefSaatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("🛏 Uyku Verisi Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),

          ListTile(
            leading: Icon(Icons.bed),
            title: Text(bedTime == null ? "Yatma saati" : bedTime!.format(context)),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 23, minute: 0),
              );
              if (picked != null) setState(() => bedTime = picked);
            },
          ),

          ListTile(
            leading: Icon(Icons.wb_sunny),
            title: Text(wakeTime == null ? "Uyanma saati" : wakeTime!.format(context)),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 7, minute: 0),
              );
              if (picked != null) setState(() => wakeTime = picked);
            },
          ),

          DropdownButtonFormField<String>(
            value: mood,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.sentiment_satisfied),
              labelText: "Ruh Hali",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: ["Harika", "İyi", "Orta", "Kötü"].map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => mood = val);
            },
          ),
              SizedBox(height: 16),
TextFormField(
  controller: hedefSaatController,
  decoration: InputDecoration(
    labelText: "Hedeflenen Uyku Süresi",
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    prefixIcon: Icon(Icons.schedule),
  ),
),
          SizedBox(height: 16),
         ElevatedButton.icon(
  onPressed: _uykuVerisiniKaydet,
  icon: Icon(Icons.save),
  label: Text("Kaydet"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  ),
),
        ],
      ),
    );
  }
}