import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gluco_reminder/profil.dart';

class BisikletSayfasi extends StatefulWidget {
  const BisikletSayfasi({super.key});

  @override
  State<BisikletSayfasi> createState() => _BisikletSayfasiState();
}

class _BisikletSayfasiState extends State<BisikletSayfasi>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  bool _isLoading = true;

  int seconds = 0;
  Timer? timer;
  double calories = 0.0;
  int kilo = 50;
  int metDegeri = 7; // Bisiklet için MET
  bool _timerRunning = false;
  DateTime? _lastSavedTime;
  int _pausedSeconds = 0;

  List<String> last7DaysNames = []; // Firebase verisi ile gelen gün isimleri
List<double> last7Calories = [];  // Firebase verisi ile gelen kalori değerleri

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();

    _kontrolVeSifirla();
    _loadLastSession();
  _loadLast7Calories(); 
  }
Future<void> _kontrolVeSifirla() async {
  final bugun = DateTime.now();
  final tarihKey = "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";

  final docRef = FirebaseFirestore.instance.collection('bisiklet_verileri').doc(tarihKey);
  final doc = await docRef.get();

  if (!doc.exists) {
    // Eğer o gün için hiç kayıt yoksa sıfırdan oluştur
    await docRef.set({
      'sure': 0,
      'kalori': 0,
      'zaman_damgasi': Timestamp.fromDate(bugun),
      'zamanlayici_durum': false,
    });

    seconds = 0;
    calories = 0.0;
    _lastSavedTime = bugun;
  } else {
    final data = doc.data()!;

    final timerRunning = (data['zamanlayici_durum'] ?? false) == true; // ← BURAYA EKLE

    seconds = int.tryParse(data['sure'].toString()) ?? 0;
    calories = double.tryParse(data['kalori'].toString()) ?? 0.0;

    _lastSavedTime = (data['zaman_damgasi'] as Timestamp?)?.toDate();

    if (timerRunning && _lastSavedTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastSavedTime!).inSeconds;
      seconds += diff;
      startTimer();
    }
  }

  setState(() {});
  await _loadLast7Calories();
}


// 📊 Son 7 gün için kalori verisini al ve gruplandır
Future<void> _loadLast7Calories() async {
  final query = await FirebaseFirestore.instance
      .collection('bisiklet_verileri')
      .orderBy('zaman_damgasi', descending: true)
      .get();

  final docs = query.docs;

  final Map<String, double> groupedCalories = {};
  final Set<String> islenmisGunler = {};

  for (var doc in docs) {
    final data = doc.data();
    final zaman = (data['zaman_damgasi'] as Timestamp).toDate();

    final dayKey = "${zaman.year}-${zaman.month.toString().padLeft(2, '0')}-${zaman.day.toString().padLeft(2, '0')}";

    final kalori = (data['kalori'] as num).toDouble();
    final zamanlayiciDurum = data.containsKey('zamanlayici_durum') ? data['zamanlayici_durum'] as bool : false;

    if (zamanlayiciDurum) {
      // Sayaç devam ediyorsa aynı güne ekle
      groupedCalories.update(dayKey, (value) => value + kalori, ifAbsent: () => kalori);
    } else {
      // Sayaç sıfırlanmışsa o gün için sadece ilk gelen değeri al
      if (!islenmisGunler.contains(dayKey)) {
        groupedCalories[dayKey] = kalori;
        islenmisGunler.add(dayKey);
      }
    }
  }
  setState(() {
    final last5Entries = groupedCalories.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final last5 = last5Entries.length > 5
        ? last5Entries.sublist(last5Entries.length - 5)
        : last5Entries;

    last7Calories = last5.map((e) => e.value).toList();
    last7DaysNames = last5.map((e) {
      final date = DateTime.parse(e.key);
      const days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
      return days[date.weekday - 1];
    }).toList();
  });
}

Future<void> _loadLastSession() async {
  final bugun = DateTime.now();
  final tarihKey = "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";
  final docRef = FirebaseFirestore.instance.collection('bisiklet_verileri').doc(tarihKey);
  final doc = await docRef.get();

  if (doc.exists) {
    final data = doc.data()!;
    _pausedSeconds = int.tryParse(data['sure'].toString()) ?? 0;
    seconds = _pausedSeconds;
    calories = double.tryParse(data['kalori'].toString()) ?? 0.0;

    _lastSavedTime = data['zaman_damgasi'] is Timestamp
        ? (data['zaman_damgasi'] as Timestamp).toDate()
        : null;

    final timerRunning = (data['zamanlayici_durum'] ?? false) == true;

    if (timerRunning && _lastSavedTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastSavedTime!).inSeconds;
      _pausedSeconds += diff;
      seconds = _pausedSeconds;
      startTimer();
    }

    setState(() {});
  }

  _isLoading = false;
  setState(() {});
}


 Future<void> _kaydetYuzmeVerisi({required bool timerRunning}) async {
  final bugun = DateTime.now();
  final tarihKey = "${bugun.year}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}";
  final docRef = FirebaseFirestore.instance.collection('bisiklet_verileri').doc(tarihKey);

  await docRef.set({
    'sure': seconds,
    'kalori': calories,
    'zaman_damgasi': Timestamp.fromDate(DateTime.now()),
    'zamanlayici_durum': timerRunning, // dışarıdan gelen parametre
  }, SetOptions(merge: true));

  _lastSavedTime = DateTime.now();
}


void startTimer() {
  if (_timerRunning) return;

  setState(() {
    _timerRunning = true;
    seconds = _pausedSeconds;
  });

  timer?.cancel();

  timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      seconds++;
      _pausedSeconds = seconds;
      calculateCalories();
    });
  });

  _kaydetYuzmeVerisi(timerRunning: true); // ZAMANLAYICI DURUMU TRUE
}

void stopTimer() {
  if (!_timerRunning) return;

  timer?.cancel();
  setState(() {
    _timerRunning = false;
    _pausedSeconds = seconds;
  });

  _kaydetYuzmeVerisi(timerRunning: false); // ZAMANLAYICI DURUMU FALSE
}


  void resetTimer() {
    stopTimer();
  setState(() {
    seconds = 0;
    _pausedSeconds=0;// Zamanı sıfırlıyoruz
    calories = 0.0; // Kaloriyi sıfırlıyoruz
  });
}


  void calculateCalories() {
    double minutes = seconds / 60.0;
    calories = (metDegeri * kilo * 3.5 / 200) * minutes;
  }

  String get formattedTime {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    if (_timerRunning) {
      _kaydetYuzmeVerisi(timerRunning: true);
    }
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {

 if (last7Calories.isEmpty) {
    return Center(child: CircularProgressIndicator()); // Veya boş veri mesajı
  }
    final maxYValue = last7Calories.reduce(max);
double dynamicInterval(double maxValue) {
  if (maxValue <= 100) return 20;
  if (maxValue <= 300) return 50;
  if (maxValue <= 600) return 100;
  return 200;
}

final interval = dynamicInterval(maxYValue);
final adjustedMaxY = ((maxYValue + interval) / interval).ceil() * interval;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilSayfasi()),
                  );
                },
                  child:CircleAvatar(
                    backgroundColor: Colors.cyan,
                    child: Icon(Icons.person, color: Colors.white),
                  ),),
                  SizedBox(width: 8),
                  Text('Kullanıcı', style: TextStyle(color: Colors.black)),
                  
                ],
              ),
              Text('Yürüme Sayfası', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
  children: [
    Center(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return CustomPaint(
            painter: RingPainter(_progress.value),
            child: SizedBox(
              width: 170,
              height: 170,
              child: Center(
                child: Icon(
                  Icons.pedal_bike,
                  size: 60,
                  color: Colors.purpleAccent,
                ),
              ),
            ),
          );
        },
      ),
    ),
    SizedBox(height: 30),
    Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(12),
            ),
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Süre", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text(formattedTime, style: TextStyle(fontSize: 26)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: startTimer,
                    ),
                    IconButton(
                      icon: Icon(Icons.pause),
                      onPressed: stopTimer,
                    ),
                  
                  ],
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(12),
            ),
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Kalori", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("${calories.toStringAsFixed(4)} kcal",
                    style: TextStyle(fontSize: 26)),
              ],
            ),
          ),
        ),
      ],
    ),
    SizedBox(height: 30),
    Text(
      "Son 5 Günlük Kalori Takibi",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 10),
    
  
  Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Container(
      height: 250,
      child: last7Calories.isEmpty || last7DaysNames.isEmpty
          ? Center(child: CircularProgressIndicator())  // Yükleniyor ekranı
          : LineChart(
              LineChartData(
                minX: 0,
                maxX: (last7Calories.length - 1).toDouble(),
                minY: 0,
                maxY:  adjustedMaxY,
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(
                        "Kalori (kcal)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    axisNameSize: 30,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Günler",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    axisNameSize: 30,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= last7DaysNames.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          last7DaysNames[index],
                          style: TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: List.generate(
                      last7Calories.length,
                      (index) => FlSpot(index.toDouble(), last7Calories[index]),
                    ),
                    barWidth: 3,
                    color: Colors.orange,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
    ),
  ),
)

  ],
)

      ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;

  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = Colors.purple.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi / 2, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}