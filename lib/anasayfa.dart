import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gluco_reminder/acil_durum_sayfasi.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

  // Grafik verileri
  List<Map<String, dynamic>> _chartData = [];
  bool _isChartLoading = true;
  bool _hasChartData = false;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
    _loadChartData();
    _exerciseDataFuture = _fetchTodayTotals();
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
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('tarih', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final Timestamp tarihTimestamp = data['tarih'] as Timestamp;
        final DateTime tarih = tarihTimestamp.toDate();
        final String randevuSaat = data['saat'] ?? '';

        setState(() {
          _randevuFound = true;
          _doktorAdi = data['doktorAdi'] ?? '';
          _hastaneAdi = data['hastaneAdi'] ?? '';
          _randevuTuru = data['randevuTuru'] ?? '';
          _randevuTarih = DateFormat('dd MMMM yyyy').format(tarih);
          _randevuSaat = randevuSaat;
          _randevuDateTime = tarih; // Randevu datetime'ını saklıyoruz

          // Geri sayım metnini oluştur
          _updateCountdownText();
        });

        // Periyodik olarak geri sayımı güncelle (ama sık olmasın)
        Future.delayed(Duration(seconds: 30), () {
          if (mounted) {
            _updateCountdownText();
          }
        });
      } else {
        setState(() {
          _randevuFound = false;
          _countdownText = "Yaklaşan randevu yok";
        });
      }
    } catch (e) {
      print('Randevu getirme hatası: $e');
    } finally {
      setState(() {
        _isRandevuLoading = false;
      });
    }
  }

  // Geri sayım metnini güncelle
  void _updateCountdownText() {
    if (_randevuDateTime == null || _randevuSaat == null) return;

    final DateTime randevuTarihi = _randevuDateTime!;
    final String randevuSaat = _randevuSaat!;

    final List<String> saatParts = randevuSaat.split(':');
    DateTime randevuDateTime = randevuTarihi;

    if (saatParts.length == 2) {
      try {
        final int hour = int.parse(saatParts[0]);
        final int minute = int.parse(saatParts[1]);
        randevuDateTime = DateTime(
          randevuTarihi.year,
          randevuTarihi.month,
          randevuTarihi.day,
          hour,
          minute,
        );
      } catch (e) {
        print('Saat ayrıştırma hatası: $e');
      }
    }

    final DateTime now = DateTime.now();
    final Duration difference = randevuDateTime.difference(now);

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
          'Bugün için maksimum $typeText ölçümü sayısına ulaştınız (${maxDailyReadings} ölçüm)');
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

  late Future<Map<String, int>> _exerciseDataFuture;

  Future<Map<String, int>> _fetchTodayTotals() async {
    List<String> collections = [
      'bisiklet_verileri',
      'yuzme_verileri',
      'yurume_verileri',
      'kosu_verileri'
    ];

    int totalSeconds = 0;
    double totalCalories = 0;

    for (String col in collections) {
      if (!mounted) {
        return {
          'sure': 0,
          'kalori': 0
        }; // widget ağacında değilse işlemi iptal et
      }
      List<Map<String, dynamic>> dataList =
          await _getTodayDataFromCollection(col);

      for (var data in dataList) {
        final sureInSeconds = int.tryParse(data['sure'].toString()) ?? 0;
        totalSeconds += sureInSeconds;

        totalCalories += (data['kalori'] ?? 0).toDouble();
      }
    }

    if (!mounted) return {'sure': 0, 'kalori': 0};

    setState(() {
      _totalSeconds = totalSeconds.toDouble();
      _totalCalories = totalCalories;
    });

    // Return the values as Map<String, int>
    return {
      'sure': (totalSeconds / 60).round(), // convert seconds to minutes
      'kalori': totalCalories.round(),
    };
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
                    FutureBuilder<Map<String, int>>(
                      future: _exerciseDataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 150,
                            width: 180,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            height: 150,
                            width: 180,
                            child: Center(
                              child: Text('Hata: ${snapshot.error}'),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final kalori = data['kalori']!;
                        final totalSeconds = data['sure']!;
                        final minutes = totalSeconds ~/ 60;
                        final seconds = totalSeconds % 60;

                        return Container(
                          height: 150,
                          width: 180,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
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
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Egzersiz',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Süre: ${minutes} dk ${seconds} sn',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Kalori: $kalori kcal',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                            Colors.pinkAccent,
                            Colors.purpleAccent,
                            Colors.blueAccent,
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 50,
                              color: Colors.white,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'İlaç Takibi',
                                  style: TextStyle(
                                    fontSize: 16,
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
                            Color(0xFFF0EBE5),
                            Color(0xFF87575C),
                            Color(0xFFD1DFBB),
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_food_beverage_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'besin Takibi',
                                  style: TextStyle(
                                    fontSize: 16,
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
