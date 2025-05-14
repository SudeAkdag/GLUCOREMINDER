import 'package:flutter/material.dart';
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

  final double minValue = 0; // Kan şekeri alt limiti
  final double maxValue = 400; // Kan şekeri üst limiti
  final int maxDailyReadings = 3; // Günlük maksimum okuma sayısı

  // Günlük ölçüm sayısını kontrol et
  Future<bool> _checkDailyReadingsLimit(String type) async {
    // Bugünün başlangıç zamanını al
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Bugünün ölçümlerini sorgula
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('blood_sugar')
        .where('type', isEqualTo: type)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    // Eğer günlük limit aşıldıysa true döndür
    return snapshot.docs.length >= maxDailyReadings;
  }

  void _saveFastingReading() async {
    if (fastingController.text.isEmpty) {
      _showErrorMessage('Lütfen bir değer girin');
      return;
    }

    final value = double.tryParse(fastingController.text);
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
    final limitExceeded = await _checkDailyReadingsLimit('fasting');
    if (limitExceeded) {
      _showErrorMessage(
          'Bugün için maksimum açlık ölçümü sayısına ulaştınız (${maxDailyReadings} ölçüm)');
      return;
    }

    // Her şey uygunsa kaydet
    FirebaseFirestore.instance.collection('blood_sugar').add({
      'type': 'fasting',
      'value': value,
      'timestamp': Timestamp.now(),
    });

    setState(() {
      showFastingCard = false;
      fastingController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Açlık şekeri kaydedildi'),
        backgroundColor: Color(0xFF4FD2D2),
      ),
    );
  }

  void _savePostprandialReading() async {
    if (postprandialController.text.isEmpty) {
      _showErrorMessage('Lütfen bir değer girin');
      return;
    }

    final value = double.tryParse(postprandialController.text);
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
    final limitExceeded = await _checkDailyReadingsLimit('postprandial');
    if (limitExceeded) {
      _showErrorMessage(
          'Bugün için maksimum tokluk ölçümü sayısına ulaştınız (${maxDailyReadings} ölçüm)');
      return;
    }

    // Her şey uygunsa kaydet
    FirebaseFirestore.instance.collection('blood_sugar').add({
      'type': 'postprandial',
      'value': value,
      'timestamp': Timestamp.now(),
    });

    setState(() {
      showPostprandialCard = false;
      postprandialController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tokluk şekeri kaydedildi'),
        backgroundColor: Color(0xFF4FD2D2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    fastingController.dispose();
    postprandialController.dispose();
    super.dispose();
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
              MaterialPageRoute(builder: (context) => ProfilSayfasi()),
            );
          },
        ),
        title: Text('Kullanıcı', style: TextStyle(fontSize: 16)),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Grafik - Şimdi üstte
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Kan Şekeri Grafiği',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: _buildBloodSugarChart(),
                    ),
                  ],
                ),
              ),
            ),

            // Butonlar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: 'Açlık Şekeri',
                      backgroundColor: const Color.fromARGB(255, 57, 217, 226),
                      onPressed: () {
                        setState(() {
                          showFastingCard = !showFastingCard;
                          showPostprandialCard = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      title: 'Tokluk Şekeri',
                      backgroundColor: const Color.fromARGB(255, 234, 86, 236),
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
            ),

            // Veri girişi kartları
            if (showFastingCard)
              _buildInputCard(
                title: 'Açlık Şekeri Girin',
                controller: fastingController,
                onSave: _saveFastingReading,
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
                onSave: _savePostprandialReading,
                onCancel: () {
                  setState(() {
                    showPostprandialCard = false;
                  });
                },
              ),

            // Diğer özellikler
            SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blood_sugar')
          .orderBy('timestamp', descending: false)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data?.docs ?? [];
        if (documents.isEmpty) {
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

        // Veriyi günlere göre grupla
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var doc in documents) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final dateKey = DateFormat('dd/MM').format(timestamp);

          grouped.putIfAbsent(dateKey, () => []);
          grouped[dateKey]!.add({
            'value': data['value'],
            'type': data['type'],
            'timestamp': timestamp,
          });
        }

        List<BarChartGroupData> barGroups = [];
        List<String> dateLabels = [];
        int x = 0;

        grouped.forEach((date, readings) {
          // Saat sırasına göre sırala
          readings.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

          // Her ölçüm için bir çubuk
          final rods = readings.map((r) {
            final isFasting = r['type'] == 'fasting';
            return BarChartRodData(
              toY: (r['value'] as num).toDouble(),
              width: 15,
              color: isFasting
                  ? Color.fromARGB(255, 57, 217, 226)
                  : Color.fromARGB(255, 234, 86, 236),
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

          dateLabels.add(date);
          x++;
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildLegendItem(Color.fromARGB(255, 57, 217, 226), 'Açlık'),
                  const SizedBox(width: 24),
                  _buildLegendItem(Color.fromARGB(255, 234, 86, 236), 'Tokluk'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
                              return Text(
                                value.toStringAsFixed(
                                    0), // veya '${value.toInt()}'
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
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
                            getTitlesWidget: (value, meta) {
                              return Text(
                                dateLabels[value.toInt()],
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 1000,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      groupsSpace: 32,
                    ),
                  )),
            ),
          ],
        );
      },
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

  Widget _buildActionCard({
    required String title,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
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
        elevation: 4,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4FD2D2),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FD2D2),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
