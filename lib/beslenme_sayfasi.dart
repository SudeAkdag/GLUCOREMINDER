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

// Seçilen besinleri tutmak için sınıf
class SeciliBesin {
  final String isim;
  final int kalori;
  final String? resimUrl;

  SeciliBesin({
    required this.isim,
    required this.kalori,
    this.resimUrl,
  });
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

  // Seçilen besinleri tutmak için değişkenler
  SeciliBesin? kahvaltiBesin;
  SeciliBesin? ogleYemegiBesin;
  SeciliBesin? aksamYemegiBesin;
  SeciliBesin? atistirmalikBesin;

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

  // Besin eklendiğinde kalori hesabını güncelleme
  void besinEkle(String ogunTipi, String isim, int kalori, String? resimUrl) {
    setState(() {
      // Önceki besin varsa, toplam kaloriden çıkar
      if (ogunTipi == 'Kahvaltı' && kahvaltiBesin != null) {
        toplamKalori -= kahvaltiBesin!.kalori;
      } else if (ogunTipi == 'Öğle Yemeği' && ogleYemegiBesin != null) {
        toplamKalori -= ogleYemegiBesin!.kalori;
      } else if (ogunTipi == 'Akşam Yemeği' && aksamYemegiBesin != null) {
        toplamKalori -= aksamYemegiBesin!.kalori;
      } else if (ogunTipi == 'Atıştırmalık' && atistirmalikBesin != null) {
        toplamKalori -= atistirmalikBesin!.kalori;
      }

      // Yeni besini ekle ve toplam kaloriyi güncelle
      if (ogunTipi == 'Kahvaltı') {
        kahvaltiBesin = SeciliBesin(isim: isim, kalori: kalori, resimUrl: resimUrl);
      } else if (ogunTipi == 'Öğle Yemeği') {
        ogleYemegiBesin = SeciliBesin(isim: isim, kalori: kalori, resimUrl: resimUrl);
      } else if (ogunTipi == 'Akşam Yemeği') {
        aksamYemegiBesin = SeciliBesin(isim: isim, kalori: kalori, resimUrl: resimUrl);
      } else if (ogunTipi == 'Atıştırmalık') {
        atistirmalikBesin = SeciliBesin(isim: isim, kalori: kalori, resimUrl: resimUrl);
      }

      // Toplam kaloriye yeni besinin kalorisini ekle
      toplamKalori += kalori;
    });

    // Kullanıcıya geri bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$isim $ogunTipi öğününüze eklendi'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {},
        ),
      ),
    );
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

              // Öğün seçme menüsü ekle
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Öğün Seç',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: 'Kahvaltı',
                      items: [
                        DropdownMenuItem(value: 'Kahvaltı', child: Text('Kahvaltı')),
                        DropdownMenuItem(value: 'Öğle Yemeği', child: Text('Öğle Yemeği')),
                        DropdownMenuItem(value: 'Akşam Yemeği', child: Text('Akşam Yemeği')),
                        DropdownMenuItem(value: 'Atıştırmalık', child: Text('Atıştırmalık')),
                      ],
                      onChanged: (value) {
                        // Seçilen öğünü kaydet
                        setState(() {
                          _seciliOgun = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Yemeği ekleme butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Öğüne Ekle'),
                  onPressed: () {
                    // Tarif eklenince öğüne göre uygun değişkene ata ve toplamKalori'yi güncelle
                    if (tarif.kalori != null) {
                      String ogun = _seciliOgun;
                      besinEkle(
                          ogun,
                          tarif.isim,
                          tarif.kalori!,
                          tarif.resimUrl
                      );
                    }
                    Navigator.of(context).pop();
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

  // Dialog için seçili öğün
  String _seciliOgun = 'Kahvaltı';

  // Öğün için besin seçme fonksiyonu
  Future<void> _ogunBesinSec(String ogunTipi) async {
    // Besinler sayfasına git
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BesinSayfasi(ogunTuru: ogunTipi),
      ),
    );

    // Eğer sonuç dönerse (null değilse yani bir besin seçilmişse)
    if (result != null) {
      // Dönen besin verisini işle - besinler.dart'tan Besin nesnesi dönecek
      besinEkle(
          ogunTipi,
          result.name,
          result.calories,
          result.imageUrl.isNotEmpty ? result.imageUrl : null
      );
    }
  }

  // Öğün Ekleme Butonları için Custom Widget
  Widget _buildMealButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    SeciliBesin? seciliBesin,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            height: 60,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero, // İçerik için padding kaldırıldı
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (seciliBesin == null)
                    Icon(icon, color: Colors.white),
                  if (seciliBesin == null)
                    SizedBox(width: 8),
                  if (seciliBesin == null)
                    Text(text, textAlign: TextAlign.center)
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: seciliBesin.resimUrl != null && seciliBesin.resimUrl!.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                seciliBesin.resimUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(icon, color: Colors.white, size: 20),
                                    ),
                              ),
                            )
                                : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seciliBesin.isim,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${seciliBesin.kalori} kcal',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Besini değiştirmek için tekrar aynı sayfaya git
                              _ogunBesinSec(text);
                            },
                            icon: Icon(Icons.edit, color: Colors.white, size: 20),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                ],
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

  // Bu kod beslenme_sayfasi.dart dosyasının devamıdır - @override Widget build metodu

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
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Kahvaltı',
                                  icon: Icons.free_breakfast,
                                  color: Colors.orange.shade700,
                                  onPressed: () => _ogunBesinSec('Kahvaltı'),
                                  seciliBesin: kahvaltiBesin,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Öğle Yemeği',
                                  icon: Icons.lunch_dining,
                                  color: Colors.green.shade700,
                                  onPressed: () => _ogunBesinSec('Öğle Yemeği'),
                                  seciliBesin: ogleYemegiBesin,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Akşam Yemeği',
                                  icon: Icons.dinner_dining,
                                  color: Colors.blue.shade700,
                                  onPressed: () => _ogunBesinSec('Akşam Yemeği'),
                                  seciliBesin: aksamYemegiBesin,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Atıştırmalık',
                                  icon: Icons.bakery_dining,
                                  color: Colors.purple.shade700,
                                  onPressed: () => _ogunBesinSec('Atıştırmalık'),
                                  seciliBesin: atistirmalikBesin,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Tarif resmi
                                        Expanded(
                                          flex: 3,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: tarif.resimUrl != null && tarif.resimUrl!.isNotEmpty
                                                ? Image.network(
                                              tarif.resimUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey[300],
                                                    child: Center(child: Icon(Icons.restaurant, size: 36)),
                                                  ),
                                            )
                                                : Container(
                                              color: Colors.grey[300],
                                              child: Center(child: Icon(Icons.restaurant, size: 36)),
                                            ),
                                          ),
                                        ),
                                        // Tarif bilgileri
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  tarif.isim,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (tarif.kalori != null)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.local_fire_department,
                                                        color: Colors.orange,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '${tarif.kalori} kcal',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
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