import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:gluco_reminder/besinler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

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

// Seçilen besinleri tutmak için sınıfı güncelleyelim - protein, yağ ve karbonhidrat ekledik
class SeciliBesin {
  final String isim;
  final int kalori;
  final int protein;
  final int yag;
  final int karbonhidrat;
  final String? resimUrl;
  final String id; // Her besin için unique ID

  SeciliBesin({
    required this.isim,
    required this.kalori,
    required this.protein,
    required this.yag,
    required this.karbonhidrat,
    this.resimUrl,
    required this.id,
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

  // Besin değerleri değişkenleri
  int toplamKalori = 0;
  int hedefKalori = 2000; // Örnek hedef kalori
  int toplamProtein = 0;
  int toplamYag = 0;
  int toplamKarbonhidrat = 0;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Seçilen besinleri tutmak için değişkenler - Artık listeler halinde
  List<SeciliBesin> kahvaltiBesinler = [];
  List<SeciliBesin> ogleYemegiBesinler = [];
  List<SeciliBesin> aksamYemegiBesinler = [];
  List<SeciliBesin> atistirmalikBesinler = [];

  // Dialog için seçili öğün
  String _seciliOgun = 'Kahvaltı';

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

  // Hedef kaloriyi değiştiren dialog
  void _hedefKaloriDegistir() {
    final TextEditingController _kaloriController = TextEditingController(text: hedefKalori.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Günlük Hedef Kalori'),
        content: TextField(
          controller: _kaloriController,
          decoration: InputDecoration(
            labelText: 'Hedef Kalori',
            hintText: 'Örn: 2000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Girilen değeri kontrol et
              final yeniHedef = int.tryParse(_kaloriController.text);
              if (yeniHedef != null && yeniHedef > 0) {
                setState(() {
                  hedefKalori = yeniHedef;
                });
                Navigator.pop(context);

                // Kullanıcıya bilgi ver
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hedef kalori $hedefKalori olarak güncellendi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // Hatalı giriş
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen geçerli bir kalori değeri girin'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Toplam değerleri hesaplayan fonksiyon
  void _toplamDegerleriHesapla() {
    toplamKalori = 0;
    toplamProtein = 0;
    toplamYag = 0;
    toplamKarbonhidrat = 0;

    // Tüm öğünlerdeki besinleri topla
    List<SeciliBesin> tumBesinler = [
      ...kahvaltiBesinler,
      ...ogleYemegiBesinler,
      ...aksamYemegiBesinler,
      ...atistirmalikBesinler,
    ];

    for (var besin in tumBesinler) {
      toplamKalori += besin.kalori;
      toplamProtein += besin.protein;
      toplamYag += besin.yag;
      toplamKarbonhidrat += besin.karbonhidrat;
    }
  }

  // Besin eklendiğinde kalori ve besin değerlerini güncelleme
  void besinEkle(String ogunTipi, String isim, int kalori, int protein, int yag, int karbonhidrat, String? resimUrl) {
    setState(() {
      // Yeni besini ekle
      final yeniBesin = SeciliBesin(
        isim: isim,
        kalori: kalori,
        protein: protein,
        yag: yag,
        karbonhidrat: karbonhidrat,
        resimUrl: resimUrl,
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      );

      // Öğün tipine göre listeye ekle
      if (ogunTipi == 'Kahvaltı') {
        kahvaltiBesinler.add(yeniBesin);
      } else if (ogunTipi == 'Öğle Yemeği') {
        ogleYemegiBesinler.add(yeniBesin);
      } else if (ogunTipi == 'Akşam Yemeği') {
        aksamYemegiBesinler.add(yeniBesin);
      } else if (ogunTipi == 'Atıştırmalık') {
        atistirmalikBesinler.add(yeniBesin);
      }

      // Toplam değerleri yeniden hesapla
      _toplamDegerleriHesapla();
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

  // Besin silme fonksiyonu
  void besinSil(String ogunTipi, String besinId) {
    setState(() {
      if (ogunTipi == 'Kahvaltı') {
        kahvaltiBesinler.removeWhere((besin) => besin.id == besinId);
      } else if (ogunTipi == 'Öğle Yemeği') {
        ogleYemegiBesinler.removeWhere((besin) => besin.id == besinId);
      } else if (ogunTipi == 'Akşam Yemeği') {
        aksamYemegiBesinler.removeWhere((besin) => besin.id == besinId);
      } else if (ogunTipi == 'Atıştırmalık') {
        atistirmalikBesinler.removeWhere((besin) => besin.id == besinId);
      }

      // Toplam değerleri yeniden hesapla
      _toplamDegerleriHesapla();
    });
  }

  // Öğündeki besinleri gösteren dialog
  void _ogunDetayGoster(String ogunTipi, List<SeciliBesin> besinler) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$ogunTipi Besinleri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(),
              // Besinler listesi
              Expanded(
                child: besinler.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz besin eklenmemiş',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: besinler.length,
                  itemBuilder: (context, index) {
                    final besin = besinler[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: besin.resimUrl != null && besin.resimUrl!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            besin.resimUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.restaurant_menu, size: 24),
                                ),
                          ),
                        )
                            : Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.restaurant_menu, size: 24),
                        ),
                        title: Text(
                          besin.isim,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${besin.kalori} kcal'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            besinSil(ogunTipi, besin.id);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              // Besin ekleme butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Yeni Besin Ekle'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _ogunBesinSec(ogunTipi);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> tarifleriGetir() async {
    try {
      final response = await http.get(
        Uri.parse('https://yemek-api-zmox.onrender.com/api/recipes'),
      ).timeout(Duration(seconds: 10));

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
                      value: _seciliOgun,
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

                      // Tarif verileri için protein, yağ ve karbonhidrat değerlerini tahmin et
                      // Gerçek projede API'dan bu değerleri alabilirsiniz
                      int tahminiProtein = (tarif.kalori! * 0.2 / 4).round(); // %20 protein
                      int tahminiYag = (tarif.kalori! * 0.3 / 9).round(); // %30 yağ
                      int tahminiKarbonhidrat = (tarif.kalori! * 0.5 / 4).round(); // %50 karbonhidrat

                      besinEkle(
                          ogun,
                          tarif.isim,
                          tarif.kalori!,
                          tahminiProtein,
                          tahminiYag,
                          tahminiKarbonhidrat,
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
          result.protein,
          result.fat,
          result.carbohydrates,
          result.imageUrl.isNotEmpty ? result.imageUrl : null
      );
    }
  }

  // Öğün Ekleme Butonları için Custom Widget - Gradient eklendi ve çoklu besin desteği
  Widget _buildMealButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required List<SeciliBesin> seciliBesinler,
  }) {
    // Her öğün için özel gradient renkleri
    List<Color> gradientColors;
    switch (text) {
      case 'Kahvaltı':
        gradientColors = [Colors.orange.shade600, Colors.orange.shade400, Colors.yellow.shade300];
        break;
      case 'Öğle Yemeği':
        gradientColors = [Colors.green.shade700, Colors.green.shade500, Colors.lightGreen.shade300];
        break;
      case 'Akşam Yemeği':
        gradientColors = [Colors.blue.shade700, Colors.blue.shade500, Colors.lightBlue.shade300];
        break;
      case 'Atıştırmalık':
        gradientColors = [Colors.purple.shade700, Colors.purple.shade500, Colors.purpleAccent.shade100];
        break;
      default:
        gradientColors = [color, color.withOpacity(0.7)];
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: seciliBesinler.isEmpty ? onPressed : () => _ogunDetayGoster(text, seciliBesinler),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (seciliBesinler.isEmpty)
                        Icon(icon, color: Colors.white),
                      if (seciliBesinler.isEmpty)
                        SizedBox(width: 8),
                      if (seciliBesinler.isEmpty)
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              Icon(icon, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${seciliBesinler.length} besin',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${seciliBesinler.fold(0, (sum, besin) => sum + besin.kalori)} kcal',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: onPressed,
                                icon: Icon(Icons.add, color: Colors.white, size: 20),
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
            ),
          ),
        );
      },
    );
  }

  // Toplam besin değerlerini gösteren widget
  Widget _buildNutritionSummary() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Protein
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center, color: Colors.blue, size: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Protein',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                '$toplamProtein g',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Yağ
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.opacity, color: Colors.yellow[700], size: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Yağ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                '$toplamYag g',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Karbonhidrat
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.grain, color: Colors.orange, size: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Karbonhidrat',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                '$toplamKarbonhidrat g',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Günlük Özet Widget - Gelişmiş gradient eklendi
  Widget _buildDailySummary() {
    double progress = toplamKalori / hedefKalori;
    if (progress > 1.0) progress = 1.0;

    return GestureDetector(
      onTap: _hedefKaloriDegistir,
      child: Card(
        elevation: 8,
        margin: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade400,
                Colors.teal.shade300,
                Colors.cyan.shade200,
                Colors.teal.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Günlük Besin Özeti',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alınan Kalori',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '$toplamKalori / $hedefKalori kcal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            color: progress > 0.9 ? Colors.orange.shade300 : Colors.white,
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
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
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

                    // Günlük Özet Paneli - Tıklanabilir
                    _buildDailySummary(),

                    // Toplam besin değerleri (protein, yağ, karbonhidrat)
                    _buildNutritionSummary(),

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
                                  seciliBesinler: kahvaltiBesinler,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Öğle Yemeği',
                                  icon: Icons.lunch_dining,
                                  color: Colors.green.shade700,
                                  onPressed: () => _ogunBesinSec('Öğle Yemeği'),
                                  seciliBesinler: ogleYemegiBesinler,
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
                                  seciliBesinler: aksamYemegiBesinler,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildMealButton(
                                  text: 'Atıştırmalık',
                                  icon: Icons.bakery_dining,
                                  color: Colors.purple.shade700,
                                  onPressed: () => _ogunBesinSec('Atıştırmalık'),
                                  seciliBesinler: atistirmalikBesinler,
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