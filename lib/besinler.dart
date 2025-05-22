import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Ana renk paletini tanımla - Gradient renkleri eklendi
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

  // Gradient renkleri
  static const List<Color> primaryGradient = [
    Color(0xFF6200EE),
    Color(0xFF3700B3),
    Color(0xFF03DAC6),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFBB86FC),
    Color(0xFFE1BEE7),
    Colors.white,
  ];

  static const List<Color> buttonGradient = [
    Color(0xFF6200EE),
    Color(0xFF9C27B0),
  ];
}

// Besin modeli oluşturuyoruz - veriyi daha düzenli taşımak için
class Besin {
  final String name;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbohydrates;
  final int fat;

  Besin({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
  });

  factory Besin.fromJson(Map<String, dynamic> json) {
    return Besin(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbohydrates: json['carbohydrates'] ?? 0,
      fat: json['fat'] ?? 0,
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
    };
  }
}

// Seçilen besinleri tutmak için sınıf
class SeciliBesin {
  final String isim;
  final int kalori;
  final int protein;
  final int yag;
  final int karbonhidrat;
  final String? resimUrl;
  int adet;

  SeciliBesin({
    required this.isim,
    required this.kalori,
    required this.protein,
    required this.yag,
    required this.karbonhidrat,
    this.resimUrl,
    this.adet = 1,
  });
}

// Varsayılan besin simgesi
const IconData varsayilanBesinSimgesi = Icons.restaurant_menu;

class BesinSayfasi extends StatefulWidget {
  final String ogunTuru; // Öğün türünü belirtmek için eklendi
  final List<SeciliBesin> mevcutBesinler; // Mevcut seçili besinler

  BesinSayfasi({
    this.ogunTuru = 'Kahvaltı',
    this.mevcutBesinler = const [],
  });

  @override
  _BesinSayfasiState createState() => _BesinSayfasiState();
}

class _BesinSayfasiState extends State<BesinSayfasi> with SingleTickerProviderStateMixin {
  List<Besin> yemekler = [];
  bool yukleniyor = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  TextEditingController _aramaController = TextEditingController();
  List<Besin> filtreliYemekler = [];

  // Seçilen besinleri takip etmek için
  Map<String, int> seciliBesinler = {};

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

    // Mevcut besinleri yükle
    for (var besin in widget.mevcutBesinler) {
      seciliBesinler[besin.isim] = besin.adet;
    }

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
            // API doğru veri döndürmezse boş liste
            yemekler = [];
          }
          filtreliYemekler = yemekler;
          yukleniyor = false;
        });
      } else {
        // API hatası durumunda boş liste
        setState(() {
          yemekler = [];
          filtreliYemekler = yemekler;
          yukleniyor = false;
        });
        _showApiErrorSnackbar();
      }
    } catch (e) {
      // Bağlantı hatası durumunda boş liste
      setState(() {
        yemekler = [];
        filtreliYemekler = yemekler;
        yukleniyor = false;
      });
      _showApiErrorSnackbar();
    }
  }

  void _showApiErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bir Şeyler Ters Gitti! Lütfen Sayfayı Yenileyin.'),
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
    return varsayilanBesinSimgesi;
  }

  // Besin seçildiğinde ana sayfaya dönme işlemi
  void besinSec(Besin besin) {
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

  // Besin adetini artırma/azaltma
  void besinAdetiDegistir(String besinAdi, int degisim) {
    setState(() {
      int mevcutAdet = seciliBesinler[besinAdi] ?? 0;
      int yeniAdet = mevcutAdet + degisim;

      if (yeniAdet <= 0) {
        seciliBesinler.remove(besinAdi);
      } else {
        seciliBesinler[besinAdi] = yeniAdet;
      }
    });
  }

  // Gradient Seç Butonu Widget'ı
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
    double height = 40,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Seçilen besinleri gösteren bottom panel
  Widget _buildSelectedFoodsPanel() {
    if (seciliBesinler.isEmpty) return SizedBox.shrink();

    int toplamKalori = 0;
    seciliBesinler.forEach((besinAdi, adet) {
      var besin = yemekler.firstWhere((y) => y.name == besinAdi,
          orElse: () => Besin(name: besinAdi, imageUrl: '', calories: 0, protein: 0, carbohydrates: 0, fat: 0));
      toplamKalori += besin.calories * adet;
    });

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seçilen Besinler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$toplamKalori kcal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          // Seçilen besinler listesi
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: seciliBesinler.length,
              itemBuilder: (context, index) {
                String besinAdi = seciliBesinler.keys.elementAt(index);
                int adet = seciliBesinler[besinAdi]!;
                var besin = yemekler.firstWhere(
                      (y) => y.name == besinAdi,
                  orElse: () => Besin(name: besinAdi, imageUrl: '', calories: 0, protein: 0, carbohydrates: 0, fat: 0),
                );

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Besin görseli
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryLight.withOpacity(0.3),
                              AppColors.primaryLight.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: besin.imageUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: besin.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              getBesinIkonu(besin),
                              color: AppColors.primary,
                              size: 24,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              getBesinIkonu(besin),
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        )
                            : Icon(
                          getBesinIkonu(besin),
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Besin bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              besin.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${besin.calories * adet} kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Adet kontrolleri
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.remove, color: AppColors.primary),
                              onPressed: () => besinAdetiDegistir(besinAdi, -1),
                              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 12),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: AppColors.primaryGradient),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$adet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: AppColors.primary),
                              onPressed: () => besinAdetiDegistir(besinAdi, 1),
                              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          // Geri dön butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    Colors.deepPurple,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      'Seçimi Tamamla',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text('${widget.ogunTuru} için Besin Seçin'),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Arama çubuğu - Gradient container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
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
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bir Şeyler Ters Gitti!\nLütfen Sayfayı Yenileyin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: yemekleriGetir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Yenile'),
                        ],
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
                  final secilenAdet = seciliBesinler[yemek.name] ?? 0;

                  return AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 500),
                        opacity: 1.0,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            AppColors.primaryLight.withOpacity(0.1),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            offset: Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => besinSec(yemek),
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
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryLight.withOpacity(0.3),
                                            AppColors.primaryLight.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: yemek.imageUrl.isNotEmpty
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
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
                                        // Seçilen adet göstergesi
                                        if (secilenAdet > 0)
                                          Container(
                                            margin: EdgeInsets.only(top: 4),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: AppColors.primaryGradient),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$secilenAdet adet seçildi',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Adet kontrol butonları
                                  if (secilenAdet > 0) ...[
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.remove, color: AppColors.primary),
                                            onPressed: () => besinAdetiDegistir(yemek.name, -1),
                                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(horizontal: 8),
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: AppColors.primaryGradient),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$secilenAdet',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.add, color: AppColors.primary),
                                            onPressed: () => besinAdetiDegistir(yemek.name, 1),
                                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // Besin seçme butonu - Gradient
                                    _buildGradientButton(
                                      text: "Seç",
                                      onPressed: () => besinSec(yemek),
                                      width: 60,
                                    ),
                                  ],
                                ],
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
            // Seçili besinler paneli
            _buildSelectedFoodsPanel(),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              Colors.deepPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.refresh, color: Colors.white),
          onPressed: yemekleriGetir,
        ),
      ),
    );
  }
}