import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Ana renk paletini tanımla
class AppColors {
  static const primary = Color(0xFF6200EE);
  static const primaryLight = Color(0xFFBB86FC);
  static const secondary = Color(0xFF03DAC6);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFB00020);
  static const onPrimary = Colors.white;
  static const onBackground = Colors.black87;
  static const onSurface = Colors.black87;
  static const onError = Colors.white;
}

// Besin modeli oluşturuyoruz - veriyi daha düzenli taşımak için
class Besin {
  final String name;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbohydrates;
  final int fat;
  final String category;

  Besin({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.category,
  });

  factory Besin.fromJson(Map<String, dynamic> json) {
    return Besin(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbohydrates: json['carbohydrates'] ?? 0,
      fat: json['fat'] ?? 0,
      category: json['category'] ?? 'default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'category': category,
    };
  }
}

// Besin kategorileri için simgeler
final Map<String, IconData> besinSimgeleri = {
  'meyve': Icons.apple,
  'sebze': Icons.eco,
  'et': Icons.restaurant,
  'süt': Icons.local_cafe,
  'tahıl': Icons.grass,
  'atıştırmalık': Icons.bakery_dining,
  'içecek': Icons.local_drink,
  'tatlı': Icons.cake,
  'default': Icons.restaurant_menu,
};

class BesinSayfasi extends StatefulWidget {
  final String ogunTuru; // Öğün türünü belirtmek için eklendi (kahvaltı, öğle, akşam)

  BesinSayfasi({this.ogunTuru = 'Kahvaltı'});

  @override
  _BesinSayfasiState createState() => _BesinSayfasiState();
}

class _BesinSayfasiState extends State<BesinSayfasi> with SingleTickerProviderStateMixin {
  List<Besin> yemekler = [];
  Besin? seciliYemek;
  bool yukleniyor = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  TextEditingController _aramaController = TextEditingController();
  List<Besin> filtreliYemekler = [];

  // Demo besinleri (API çalışmazsa kullanmak için)
  final List<Besin> demoBesinler = [
    Besin(
      name: 'Yulaf Ezmesi',
      imageUrl: 'https://images.unsplash.com/photo-1517093157656-b9eccef01cb1',
      calories: 150,
      protein: 6,
      carbohydrates: 27,
      fat: 3,
      category: 'kahvaltı',
    ),
    Besin(
      name: 'Tam Tahıllı Ekmek',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff',
      calories: 80,
      protein: 4,
      carbohydrates: 15,
      fat: 1,
      category: 'kahvaltı',
    ),
    Besin(
      name: 'Izgara Tavuk',
      imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b',
      calories: 165,
      protein: 31,
      carbohydrates: 0,
      fat: 3,
      category: 'et',
    ),
    Besin(
      name: 'Yeşil Salata',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
      calories: 45,
      protein: 2,
      carbohydrates: 7,
      fat: 0,
      category: 'sebze',
    ),
    Besin(
      name: 'Muz',
      imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919',
      calories: 105,
      protein: 1,
      carbohydrates: 27,
      fat: 0,
      category: 'meyve',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    yemekleriGetir();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> yemekleriGetir() async {
    setState(() {
      yukleniyor = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://yemek-api-zmox.onrender.com/api/recipes'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          if (data is Map && data.containsKey('recipes')) {
            yemekler = (data['recipes'] as List).map((item) => Besin.fromJson(item)).toList();
          } else if (data is List) {
            yemekler = data.map((item) => Besin.fromJson(item)).toList();
          } else {
            // API doğru veri döndürmezse demo verileri kullan
            yemekler = demoBesinler;
          }
          filtreliYemekler = yemekler;
          yukleniyor = false;
        });
      } else {
        // API hatası durumunda demo verileri kullan
        setState(() {
          yemekler = demoBesinler;
          filtreliYemekler = yemekler;
          yukleniyor = false;
        });
        _showApiErrorSnackbar();
      }
    } catch (e) {
      // Bağlantı hatası durumunda demo verileri kullan
      setState(() {
        yemekler = demoBesinler;
        filtreliYemekler = yemekler;
        yukleniyor = false;
      });
      _showApiErrorSnackbar();
    }
  }

  void _showApiErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API\'ye bağlanılamadı. Demo veriler gösteriliyor.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void yemekFiltrele(String aranan) {
    setState(() {
      if (aranan.isEmpty) {
        filtreliYemekler = yemekler;
      } else {
        filtreliYemekler = yemekler
            .where((yemek) =>
            yemek.name.toLowerCase().contains(aranan.toLowerCase()))
            .toList();
      }
    });
  }

  IconData getBesinIkonu(Besin yemek) {
    return besinSimgeleri[yemek.category.toLowerCase()] ?? besinSimgeleri['default']!;
  }

  // Besin seçildiğinde ana sayfaya dönme işlemi
  void besinSec(Besin besin) {
    setState(() {
      seciliYemek = besin;
    });

    // Seçilen besini ana sayfaya döndür ve navigator'ı kapat
    Navigator.pop(context, besin);

    // Kullanıcıya bilgi verme amacıyla snackbar göster (opsiyonel)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${besin.name} seçildi'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  // Besin detaylarını gösteren kart
  Widget besinDetayKarti() {
    if (seciliYemek == null) return SizedBox.shrink();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık ve kapatma butonu
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  seciliYemek!.name,
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.onPrimary),
                  onPressed: () {
                    setState(() {
                      seciliYemek = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Besin görseli
          Hero(
            tag: 'besin_${seciliYemek!.name}',
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: seciliYemek!.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: seciliYemek!.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Icon(
                  getBesinIkonu(seciliYemek!),
                  size: 80,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              )
                  : Icon(
                getBesinIkonu(seciliYemek!),
                size: 80,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
          ),
          // Besin değerleri
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Besin Değerleri",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 16),
                besinDegeriSatiri(
                  "Kalori",
                  "${seciliYemek!.calories} kcal",
                  Icons.local_fire_department,
                  Colors.red[400]!,
                ),
                besinDegeriSatiri(
                  "Protein",
                  "${seciliYemek!.protein} g",
                  Icons.fitness_center,
                  Colors.blue[400]!,
                ),
                besinDegeriSatiri(
                  "Karbonhidrat",
                  "${seciliYemek!.carbohydrates} g",
                  Icons.grain,
                  Colors.amber[600]!,
                ),
                besinDegeriSatiri(
                  "Yağ",
                  "${seciliYemek!.fat} g",
                  Icons.opacity,
                  Colors.yellow[600]!,
                ),
              ],
            ),
          ),
          // Bu besini seçme butonu
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => besinSec(seciliYemek!),
              child: Text("${widget.ogunTuru} için Seç"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Besin değeri satırı
  Widget besinDegeriSatiri(String baslik, String deger, IconData ikon, Color renk) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ikon, color: renk, size: 24),
          ),
          SizedBox(width: 16),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onBackground,
            ),
          ),
          Spacer(),
          Text(
            deger,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.ogunTuru} için Besin Seçin'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Arama çubuğu
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _aramaController,
                  onChanged: yemekFiltrele,
                  decoration: InputDecoration(
                    hintText: 'Besin ara...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // Yükleniyor göstergesi veya liste
            Expanded(
              child: yukleniyor
                  ? Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(height: 100),
                      );
                    },
                  ),
                ),
              )
                  : filtreliYemekler.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_food,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Hiç besin bulunamadı',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filtreliYemekler.length,
                itemBuilder: (context, index) {
                  final yemek = filtreliYemekler[index];
                  return AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 500),
                        opacity: 1.0,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          seciliYemek = yemek;
                        });
                        _animationController.reset();
                        _animationController.forward();
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  seciliYemek = yemek;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Besin ikonu veya görseli
                                    Hero(
                                      tag: 'besin_${yemek.name}',
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: yemek.imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                          imageUrl: yemek.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) => Icon(
                                            getBesinIkonu(yemek),
                                            size: 36,
                                            color: AppColors.primary,
                                          ),
                                        )
                                            : Icon(
                                          getBesinIkonu(yemek),
                                          size: 36,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    // Besin bilgileri
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            yemek.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.local_fire_department,
                                                size: 16,
                                                color: Colors.red[400],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "${yemek.calories} kcal",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(
                                                Icons.fitness_center,
                                                size: 16,
                                                color: Colors.blue[400],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "${yemek.protein} g",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Besin seçme butonu
                                    ElevatedButton(
                                      onPressed: () => besinSec(yemek),
                                      child: Text("Seç"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Seçili yemek detayları
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: seciliYemek != null ? besinDetayKarti() : SizedBox.shrink(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: Icon(Icons.refresh),
        onPressed: yemekleriGetir,
      ),
    );
  }
}