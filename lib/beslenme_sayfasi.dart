import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:gluco_reminder/besinler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Sistem temasını kullan
      home: BeslenmeSayfasi(),
    );
  }
}

class Tarif {
  final String isim;
  final String malzemeler;
  final String tarifAdimlari;
  final String? resimUrl;
  // Kalori bilgisi ekledim
  final int? kalori;

  Tarif({
    required this.isim,
    required this.malzemeler,
    required this.tarifAdimlari,
    this.resimUrl,
    this.kalori,
  });

  factory Tarif.fromJson(Map<String, dynamic> json) {
    // Malzemeler dizin olabilir, String'e dönüştürelim
    String malzemelerStr = '';
    if (json['ingredients'] is List) {
      final malzemelerList = json['ingredients'] as List;
      malzemelerStr = malzemelerList.map((item) => '• $item').join('\n');
    } else if (json['ingredients'] is String) {
      malzemelerStr = json['ingredients'];
    } else {
      malzemelerStr = 'Malzeme bilgisi bulunamadı';
    }

    // Tarif adımları dizin olabilir, String'e dönüştürelim
    String tarifAdimlariStr = '';
    if (json['instructions'] is List) {
      final tarifList = json['instructions'] as List;
      tarifAdimlariStr = tarifList.asMap().entries.map((entry) {
        return '${entry.key + 1}. ${entry.value}';
      }).join('\n\n');
    } else if (json['instructions'] is String) {
      tarifAdimlariStr = json['instructions'];
    } else {
      tarifAdimlariStr = 'Tarif adımları bulunamadı';
    }

    return Tarif(
      isim: json['name'] ?? 'İsimsiz Tarif',
      malzemeler: malzemelerStr,
      tarifAdimlari: tarifAdimlariStr,
      resimUrl: json['image'],
      kalori: json['calories'] is int ? json['calories'] : null,
    );
  }
}

class BeslenmeSayfasi extends StatefulWidget {
  @override
  _BeslenmeSayfasiState createState() => _BeslenmeSayfasiState();
}

class _BeslenmeSayfasiState extends State<BeslenmeSayfasi> with SingleTickerProviderStateMixin {
  List<Tarif> tarifler = [];
  bool yukleniyor = true;
  String hata = '';

  // Daily summary variables
  int toplamKalori = 0;
  int hedefKalori = 2000; // Örnek hedef kalori

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    tarifleriGetir();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Yemek eklediğimizde günlük kalori hesabını güncelleme
  void yemekEkle(int kalori) {
    setState(() {
      toplamKalori += kalori;
    });
  }

  Future<void> tarifleriGetir() async {
    try {
      final response = await http.get(
        Uri.parse('https://yemek-api-zmox.onrender.com/api/recipes'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('recipes')) {
          final List<dynamic> recipes = data['recipes'];
          setState(() {
            tarifler = recipes.map((item) => Tarif.fromJson(item)).toList();
            yukleniyor = false;
          });
        } else if (data is List) {
          setState(() {
            tarifler = data.map((item) => Tarif.fromJson(item)).toList();
            yukleniyor = false;
          });
        } else {
          setState(() {
            hata = 'Veri formatı beklenmedik şekilde: ${data.runtimeType}';
            yukleniyor = false;
          });
        }
      } else {
        setState(() {
          hata = 'Veriler yüklenemedi: HTTP ${response.statusCode}';
          yukleniyor = false;
        });
      }
    } catch (e) {
      print('API Hatası: $e');
      setState(() {
        hata = 'Bağlantı hatası: $e';
        yukleniyor = false;
      });
    }
  }

  void tarifDetayiniGoster(BuildContext context, Tarif tarif) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarif başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tarif.isim,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Tarif resmi
              if (tarif.resimUrl != null && tarif.resimUrl!.isNotEmpty)
                Hero(
                  tag: 'recipe-${tarif.isim}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      tarif.resimUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(child: Icon(Icons.image_not_supported, size: 48)),
                          ),
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Kalori bilgisi
              if (tarif.kalori != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '${tarif.kalori} kalori',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16),

              // Akordiyon yapı için Expanded içinde SingleChildScrollView kullan
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Malzemeler bölümü - Kart içinde
                      Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            'Malzemeler',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(tarif.malzemeler),
                            ),
                          ],
                        ),
                      ),

                      // Hazırlanışı bölümü - Kart içinde
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            'Hazırlanışı',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(tarif.tarifAdimlari),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Yemeği ekleme butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Öğüne Ekle'),
                  onPressed: () {
                    // Tarif eklenince toplamKalori'yi güncelle
                    if (tarif.kalori != null) {
                      yemekEkle(tarif.kalori!);
                    }
                    Navigator.of(context).pop();

                    // Kullanıcıya geri bildirim göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${tarif.isim} öğününüze eklendi'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Tamam',
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Öğün Ekleme Butonları için Custom Widget
  Widget _buildMealButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: 150,
            height: 60,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ElevatedButton.icon(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
              label: Text(text),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Günlük Özet Widget
  Widget _buildDailySummary() {
    double progress = toplamKalori / hedefKalori;
    if (progress > 1.0) progress = 1.0;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.6),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'Günlük Besin Özeti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alınan Kalori',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        )),
                    Text(
                      '$toplamKalori / $hedefKalori kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade300,
                        color: progress > 0.9 ? Colors.orange : Theme.of(context).primaryColor,
                      ),
                      Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: Hero(
          tag: 'profile-icon',
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => ProfilSayfasi(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          'Kullanıcı',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Beslenme Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Text(
                          'Beslenmelerim',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Günlük Özet Paneli
                    _buildDailySummary(),

                    // Öğün Ekleme Butonları
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 12.0,
                      children: [
                        _buildMealButton(
                          text: 'Kahvaltı Ekle',
                          icon: Icons.free_breakfast,
                          color: Colors.orange.shade700,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BesinSayfasi()),
                            );
                          },
                        ),
                        _buildMealButton(
                          text: 'Öğle Yemeği Ekle',
                          icon: Icons.lunch_dining,
                          color: Colors.green.shade700,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BesinSayfasi()),
                            );
                          },
                        ),
                        _buildMealButton(
                          text: 'Akşam Yemeği Ekle',
                          icon: Icons.dinner_dining,
                          color: Colors.blue.shade700,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BesinSayfasi()),
                            );
                          },
                        ),
                        _buildMealButton(
                          text: 'Atıştırmalık Ekle',
                          icon: Icons.bakery_dining,
                          color: Colors.purple.shade700,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BesinSayfasi()),
                            );
                          },
                        ),
                      ],
                    ),

                    // Yemek tarifleri başlığı
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 2,
                            width: 40,
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'Yemek Tarifleri',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            height: 2,
                            width: 40,
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),

                    // Yemek tarifleri listesi
                    Expanded(
                      child: yukleniyor
                          ? Center(child: CircularProgressIndicator())
                          : hata.isNotEmpty
                          ? Center(child: Text(hata, style: TextStyle(color: Colors.red)))
                          : tarifler.isEmpty
                          ? Center(child: Text('Tarif bulunamadı'))
                          : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: tarifler.length,
                        itemBuilder: (context, index) {
                          final tarif = tarifler[index];
                          return Hero(
                            tag: 'recipe-${tarif.isim}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: () => tarifDetayiniGoster(context, tarif),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Tarif resmi
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              child: tarif.resimUrl != null && tarif.resimUrl!.isNotEmpty
                                                  ? Image.network(
                                                tarif.resimUrl!,
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Container(
                                                      height: 120,
                                                      color: Colors.grey[300],
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.restaurant,
                                                          size: 40,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ),
                                              )
                                                  : Container(
                                                height: 120,
                                                width: double.infinity,
                                                color: Colors.grey[300],
                                                child: Center(
                                                  child: Icon(
                                                    Icons.restaurant,
                                                    size: 40,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Kalori göstergesi
                                            if (tarif.kalori != null)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.local_fire_department,
                                                        color: Colors.orange,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '${tarif.kalori}',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),

                                        // Tarif bilgileri
                                        Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tarif.isim,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                tarif.malzemeler.split('\n').take(2).join(', '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        Spacer(),

                                        // Detay butonu
                                        Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(16),
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            'Detayları Gör',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}