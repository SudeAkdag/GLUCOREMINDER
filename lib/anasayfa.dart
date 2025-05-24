// ignore_for_file: avoid_print, deprecated_member_use, duplicate_ignore

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gluco_reminder/acil_durum_sayfasi.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Randevu {
  final String id;
  final String doktorAdi;
  final String hastaneAdi;
  final String randevuTuru;
  final DateTime tarih;
  final String saat;
  final String notlar;
  final DateTime fullDateTime;

  Randevu({
    required this.id,
    required this.doktorAdi,
    required this.hastaneAdi,
    required this.randevuTuru,
    required this.tarih,
    required this.saat,
    required this.notlar,
    required this.fullDateTime,
  });
}

//besin için veri alımı
class Besin {
  final int toplamKarbonhidrat;
  final int toplamYag;
  final int toplamProtein;

  Besin({
    required this.toplamKarbonhidrat,
    required this.toplamYag,
    required this.toplamProtein,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  bool showFastingCard = false;
  bool showPostprandialCard = false;
  final TextEditingController fastingController = TextEditingController();
  final TextEditingController postprandialController = TextEditingController();

  // Sabitler
  final double minValue = 0;
  final double maxValue = 400;
  final int maxDailyReadings = 3;

  // Randevu ile ilgili bilgiler
  String? _doktorAdi;
  String? _hastaneAdi;
  String? _randevuTuru;
  String? _randevuTarih;
  String? _randevuSaat;
  DateTime? _randevuDateTime; // Randevu için datetime objesi
  String _countdownText = "Yaklaşan randevu yok";
  bool _isRandevuLoading = true;
  bool _randevuFound = false;
  double _totalCalories = 0;
  double _totalSeconds = 0;
  double waterLevel = 0.0;
  int toplamProtein = 0;
  int toplamYag = 0;
  int toplamKarbonhidrat = 0;

  // Grafik verileri
  List<Map<String, dynamic>> _chartData = [];
  bool _isChartLoading = true;
  bool _hasChartData = false;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
    _loadChartData();
    _fetchTodayTotals();
    loadWaterLevel();
    _startCountdownTimer();
    _getNutritionData();

    // Her 5 saniyede bir verileri güncelle
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchTodayTotals();
      }
    });
  }

  void _startCountdownTimer() {
    Future.delayed(Duration(seconds: 60), () {
      if (mounted) {
        _updateCountdownText();
        _startCountdownTimer(); // Özyinelemeli çağrı
      }
    });
  }

  int _toplamProtein = 0;
  int _toplamKarbonhidrat = 0;
  int _toplamYag = 0;

  Future<void> _getNutritionData() async {
    final bugun = DateTime.now();
    final tarihKey =
        "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('gunluk_beslenme')
        .doc(tarihKey)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _toplamProtein = data['toplam_protein'] ?? 0;
        _toplamKarbonhidrat = data['toplam_karbonhidrat'] ?? 0;
        _toplamYag = data['toplam_yag'] ?? 0;
      });
    }
  }

  Future<void> loadWaterLevel() async {
    final doc = await FirebaseFirestore.instance
        .collection('su_verisi')
        .doc('aktif_veri')
        .get();

    final bugun = DateTime.now();
    final bugunStr =
        "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";

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

  // Yaklaşan randevuyu tek seferde yükle
  Future<void> _loadNextAppointment() async {
    setState(() {
      _isRandevuLoading = true;
    });
    try {
      final DateTime now = DateTime.now();
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('randevular')
          .orderBy('tarih', descending: false)
          .get();
      // Şimdi tarih ve saat birlikte değerlendirerek en yakın randevuyu bulalım
      Randevu? nextAppointment;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp tarihTimestamp = data['tarih'] as Timestamp;
        final DateTime tarih = tarihTimestamp.toDate();
        final String saat = data['saat'] ?? '';
        // Saat bilgisini ayrıştır
        DateTime fullDateTime = tarih;
        if (saat.isNotEmpty) {
          final List<String> saatParts = saat.split(':');
          if (saatParts.length == 2) {
            try {
              final int hour = int.parse(saatParts[0]);
              final int minute = int.parse(saatParts[1]);
              fullDateTime =
                  DateTime(tarih.year, tarih.month, tarih.day, hour, minute);
            } catch (e) {
              // ignore: duplicate_ignore
              // ignore: avoid_print
              print('Saat ayrıştırma hatası: $e');
            }
          }
        }
        // Şu anki zamanı geçmiş randevuları atla
        if (fullDateTime.isAfter(now)) {
          // Bir sonraki randevu olarak belirle
          nextAppointment = Randevu(
            id: doc.id,
            doktorAdi: data['doktorAdi'] ?? '',
            hastaneAdi: data['hastaneAdi'] ?? '',
            randevuTuru: data['randevuTuru'] ?? '',
            tarih: tarih,
            saat: saat,
            notlar: data['notlar'] ?? '',
            fullDateTime: fullDateTime,
          );
          break; // İlk gelecek randevu bulunduğunda döngüden çık
        }
      }
      setState(() {
        if (nextAppointment != null) {
          _randevuFound = true;
          _doktorAdi = nextAppointment.doktorAdi;
          _hastaneAdi = nextAppointment.hastaneAdi;
          _randevuTuru = nextAppointment.randevuTuru;
          _randevuTarih =
              DateFormat('dd MMMM yyyy').format(nextAppointment.tarih);
          _randevuSaat = nextAppointment.saat;
          _randevuDateTime = nextAppointment.fullDateTime;
          // Geri sayım metnini oluştur
          _updateCountdownText();
        } else {
          _randevuFound = false;
          _countdownText = "Yaklaşan randevu yok";
        }
      });
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      print('Randevu getirme hatası: $e');
    } finally {
      setState(() {
        _isRandevuLoading = false;
      });
    }
  }

  // Geri sayım metnini güncelle
  void _updateCountdownText() {
    if (_randevuDateTime == null) return;
    final DateTime now = DateTime.now();
    final Duration difference = _randevuDateTime!.difference(now);
    String text;
    if (difference.isNegative) {
      text = "Randevu zamanı geçti";
    } else {
      final int days = difference.inDays;
      final int hours = difference.inHours % 24;
      final int minutes = difference.inMinutes % 60;
      if (days > 0) {
        text = "$days gün $hours saat $minutes dk";
      } else if (hours > 0) {
        text = "$hours saat $minutes dk";
      } else {
        text = "$minutes dk";
      }
    }
    setState(() {
      _countdownText = text;
    });
  }

  // Grafik verilerini yükle
  Future<void> _loadChartData() async {
    setState(() {
      _isChartLoading = true;
    });

    try {
      final DateTime oneDayAgo = DateTime.now().subtract(Duration(days: 1));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('blood_sugar')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(oneDayAgo))
          .orderBy('timestamp', descending: false)
          .get();

      final List<Map<String, dynamic>> processedData = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = data['timestamp'] as Timestamp;

        processedData.add({
          'value': data['value'],
          'type': data['type'],
          'hour': DateFormat('HH:mm').format(timestamp.toDate()),
          'timestamp': timestamp.toDate(),
        });
      }

      setState(() {
        _chartData = processedData;
        _hasChartData = processedData.isNotEmpty;
        _isChartLoading = false;
      });
    } catch (e) {
      print('Grafik verisi getirme hatası: $e');
      setState(() {
        _isChartLoading = false;
      });
    }
  }

  // Kan şekeri ölçümü kaydet
  Future<void> _saveBloodSugar(
      String type, TextEditingController controller) async {
    if (controller.text.isEmpty) {
      _showErrorMessage('Lütfen bir değer girin');
      return;
    }

    final value = double.tryParse(controller.text);
    if (value == null) {
      _showErrorMessage('Geçerli bir sayı girin');
      return;
    }

    // Değer kontrolleri
    if (value <= minValue) {
      _showErrorMessage('Kan şekeri değeri sıfırdan büyük olmalıdır');
      return;
    }

    if (value > maxValue) {
      _showErrorMessage('Çok yüksek bir değer girdiniz. Lütfen kontrol edin');
      return;
    }

    // Günlük limit kontrolü
    final limitExceeded = await _checkDailyReadingsLimit(type);
    if (limitExceeded) {
      final typeText = type == 'fasting' ? 'açlık' : 'tokluk';
      _showErrorMessage(
          'Bugün için maksimum $typeText ölçümü sayısına ulaştınız ($maxDailyReadings ölçüm)');
      return;
    }

    try {
      // Her şey uygunsa kaydet
      await FirebaseFirestore.instance.collection('blood_sugar').add({
        'type': type,
        'value': value,
        'timestamp': Timestamp.now(),
      });

      setState(() {
        if (type == 'fasting') {
          showFastingCard = false;
          fastingController.clear();
        } else {
          showPostprandialCard = false;
          postprandialController.clear();
        }
      });

      // Grafiği yeniden yükle
      _loadChartData();

      final typeText = type == 'fasting' ? 'Açlık' : 'Tokluk';
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$typeText şekeri kaydedildi'),
          backgroundColor: Color(0xFF4FD2D2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showErrorMessage('Kayıt hatası: $e');
    }
  }

  // Günlük ölçüm sayısını kontrol et
  Future<bool> _checkDailyReadingsLimit(String type) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('blood_sugar')
          .where('type', isEqualTo: type)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return snapshot.docs.length >= maxDailyReadings;
    } catch (e) {
      print('Ölçüm limit kontrolü hatası: $e');
      return false;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    fastingController.dispose();
    postprandialController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayTotals() async {
    List<String> collections = [
      'bisiklet_verileri',
      'yuzme_verileri',
      'yurume_verileri',
      'kosu_verileri'
    ];

    int totalSeconds = 0;
    double totalCalories = 0;

    for (String col in collections) {
      if (!mounted) return;
      List<Map<String, dynamic>> dataList =
          await _getTodayDataFromCollection(col);

      for (var data in dataList) {
        int sureInSeconds = (data['sure'] ?? 0);
        totalSeconds += sureInSeconds;
        totalCalories += (data['kalori'] ?? 0).toDouble();
      }
    }

    if (!mounted) return;

    setState(() {
      _totalSeconds = totalSeconds.toDouble();
      _totalCalories = totalCalories;
    });
  }

  Future<List<Map<String, dynamic>>> _getTodayDataFromCollection(
      String collectionName) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('zaman_damgasi', isGreaterThanOrEqualTo: startOfDay)
        .where('zaman_damgasi', isLessThan: endOfDay)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
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
                  builder: (context) =>
                      ProfilSayfasi()), //profil sayfasına geçiş
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
              'Ana Sayfa',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kan şekeri grafiği
                _buildSectionTitle('Kan Şekeri Grafiği'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      height: 350,
                      child: _buildBloodSugarChart(),
                    ),
                  ),
                ),
                // Kan şekeri ölçüm butonları
                _buildBloodSugarActions(),
                if (showFastingCard)
                  _buildInputCard(
                    title: 'Açlık Şekeri Girin',
                    controller: fastingController,
                    onSave: () => _saveBloodSugar('fasting', fastingController),
                    onCancel: () {
                      setState(() {
                        showFastingCard = false;
                      });
                    },
                  ),
                if (showPostprandialCard)
                  _buildInputCard(
                    title: 'Tokluk Şekeri Girin',
                    controller: postprandialController,
                    onSave: () =>
                        _saveBloodSugar('postprandial', postprandialController),
                    onCancel: () {
                      setState(() {
                        showPostprandialCard = false;
                      });
                    },
                  ),

                // Yaklaşan randevu
                _buildNextAppointmentCard(),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 150,
                      width: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.redAccent,
                            Colors.pinkAccent,
                            Colors.orangeAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AcilDurumSayfasi()),
                                );
                              },
                              icon: const Icon(
                                Icons.warning_amber_rounded,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Acil Durum Sayfası',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 150,
                      width: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.greenAccent,
                            Colors.green,
                            Colors.blueAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Egzersiz Takibi",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 55,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${_totalCalories.toStringAsFixed(4)} kcal",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "${(_totalSeconds ~/ 60)} dakika ${(_totalSeconds % 60).toInt()} sn",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 150,
                      width: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.greenAccent,
                            Colors.blueAccent,
                            Colors.greenAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${(waterLevel * 1000).toStringAsFixed(0)} ml",
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 150,
                      width: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blueAccent,
                            Colors.purpleAccent,
                            const Color.fromARGB(255, 139, 153, 160),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildNutritionPieChart(
                            _toplamProtein, _toplamKarbonhidrat, _toplamYag),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodSugarActions() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Açlık Şekeri',
                  icon: Icons.medication_liquid_rounded,
                  backgroundColor: Colors.pinkAccent,
                  onPressed: () {
                    setState(() {
                      showFastingCard = !showFastingCard;
                      showPostprandialCard = false;
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  title: 'Tokluk Şekeri',
                  icon: Icons.medication_liquid_rounded,
                  backgroundColor: Colors.orangeAccent,
                  onPressed: () {
                    setState(() {
                      showPostprandialCard = !showPostprandialCard;
                      showFastingCard = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5CDB8),
                Colors.pinkAccent,
                Colors.purpleAccent,
                Color(0xFFECF6C7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Yaklaşan Randevunuz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_isRandevuLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else if (!_randevuFound)
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Yaklaşan randevunuz bulunmuyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _randevuTuru!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _doktorAdi!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _hastaneAdi!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$_randevuTarih | $_randevuSaat',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Geri sayım
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kalan zaman: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _countdownText,
                              style: TextStyle(
                                color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
                  size: 28,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Eklemek için tıklayın',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Değer (mg/dL)',
                  hintText: 'Örn: 120',
                  suffixText: 'mg/dL',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4FD2D2),
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FD2D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodSugarChart() {
    if (_isChartLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FD2D2)),
        ),
      );
    }

    if (!_hasChartData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.show_chart, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz ölçüm eklenmemiş',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Grafiği görmek için ölçüm ekleyin',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    // Saatlere göre veriyi grupla
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in _chartData) {
      final String hour = item['hour'] as String;
      grouped.putIfAbsent(hour, () => []);
      grouped[hour]!.add(item);
    }

    // Grupları kronolojik sırala
    final List<String> sortedHours = grouped.keys.toList()
      ..sort((a, b) =>
          DateFormat('HH:mm').parse(a).compareTo(DateFormat('HH:mm').parse(b)));

    final List<BarChartGroupData> barGroups = [];
    int x = 0;

    // Her saat grubu için çubuk oluştur
    for (final hour in sortedHours) {
      final readings = grouped[hour]!;

      final List<BarChartRodData> rods = readings.map((r) {
        final bool isFasting = r['type'] == 'fasting';
        return BarChartRodData(
          toY: (r['value'] as num).toDouble(),
          width: 15,
          color: isFasting
              ? const Color.fromARGB(255, 241, 166, 193)
              : Colors.orangeAccent,
          borderRadius: BorderRadius.circular(4),
        );
      }).toList();

      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: rods,
          barsSpace: 20,
        ),
      );

      x++;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildLegendItem(
                  const Color.fromARGB(255, 241, 166, 193), 'Açlık'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.orangeAccent, 'Tokluk'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              children: [
                SizedBox(
                  width: max(barGroups.length * 70,
                      MediaQuery.of(context).size.width - 40),
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.white,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < sortedHours.length) {
                                final hour = sortedHours[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    hour,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.grey.withOpacity(0.4)),
                          bottom:
                              BorderSide(color: Colors.grey.withOpacity(0.4)),
                        ),
                      ),
                      groupsSpace: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

Widget _buildNutritionPieChart(
    int toplamProtein, int toplamKarbonhidrat, int toplamYag) {
  // Toplam besin değerleri
  final double total =
      (toplamProtein + toplamKarbonhidrat + toplamYag).toDouble();

  // Eğer hiç veri yoksa basit bir mesaj göster
  if (total <= 0) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_food_beverage_rounded,
              size: 50, color: Colors.white),
          SizedBox(height: 8),
          Text(
            'Bugünkü besin verisi yok',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  return Row(
    children: [
      // Sol tarafta pie chart
      Expanded(
        flex: 3,
        child: SizedBox(
          height: 100,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 15,
              sections: [
                // Protein dilimi
                PieChartSectionData(
                  color: const Color.fromARGB(255, 248, 118, 161),
                  value: toplamProtein.toDouble(),
                  title: 'P',
                  radius: 30,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Karbonhidrat dilimi
                PieChartSectionData(
                  color: const Color.fromARGB(255, 140, 214, 178),
                  value: toplamKarbonhidrat.toDouble(),
                  title: 'K',
                  radius: 30,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Yağ dilimi
                PieChartSectionData(
                  color: Color(0xFFFFC68C),
                  value: toplamYag.toDouble(),
                  title: 'Y',
                  radius: 30,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Sağ tarafta değer listesi
      Expanded(
        flex: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: const Color.fromARGB(255, 248, 118, 161),
                ),
                SizedBox(width: 4),
                Text(
                  'P: ${toplamProtein}g',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: const Color.fromARGB(255, 140, 214, 178),
                ),
                SizedBox(width: 4),
                Text(
                  'K: ${toplamKarbonhidrat}g',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: Color(0xFFFFC68C),
                ),
                SizedBox(width: 4),
                Text(
                  'Y: ${toplamYag}g',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
