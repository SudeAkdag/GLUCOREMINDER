import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil.dart';

class Ilac {
  String ad;
  String tur;
  String dozaj;
  String miktar;
  String zaman;
  String saat;
  String aclikDurumu;
  String not;

  Ilac({
    required this.ad,
    required this.tur,
    required this.dozaj,
    required this.miktar,
    required this.zaman,
    required this.saat,
    required this.aclikDurumu,
    required this.not,
  });
}

class IlacSayfasi extends StatefulWidget {
  const IlacSayfasi({super.key});

  @override
  State<IlacSayfasi> createState() => _IlacSayfasiState();
}

class _IlacSayfasiState extends State<IlacSayfasi> {
  List<Ilac> ilaclar = [];

  void _ilacEkleOrDuzenle({Ilac? mevcutIlac, int? index}) async {
    final Ilac? yeniIlac = await showModalBottomSheet<Ilac>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return IlacForm(ilac: mevcutIlac);
      },
    );

    if (yeniIlac != null) {
      setState(() {
        if (mevcutIlac != null && index != null) {
          ilaclar[index] = yeniIlac;
        } else {
          ilaclar.add(yeniIlac);
        }
      });
    }
  }

  void _ilacSil(int index) {
    setState(() {
      ilaclar.removeAt(index);
    });
  }

  void _ilacDetay(Ilac ilac, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFDEEF8),
        title: Text(ilac.ad,
            style: const TextStyle(
                color: Color(0xFFB53E6B), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detaySatiri("Tür", ilac.tur),
            _detaySatiri("Dozaj", ilac.dozaj),
            _detaySatiri("Miktar", ilac.miktar),
            _detaySatiri("Zaman", "${ilac.zaman} - ${ilac.saat}"),
            _detaySatiri("Açlık/Tokluk", ilac.aclikDurumu),
            _detaySatiri("Not", ilac.not.isEmpty ? 'Yok' : ilac.not),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ilacEkleOrDuzenle(mevcutIlac: ilac, index: index);
            },
            child: const Text("Düzenle"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ilacSil(index);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  Widget _detaySatiri(String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
                text: "$baslik: ",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB53E6B))),
            TextSpan(text: icerik),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFFDFA6B9),
        scaffoldBackgroundColor: const Color(0xFFFDEEF8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4C6D1),
          foregroundColor: Color(0xFF6D2840),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF6D2840)),
          titleTextStyle: TextStyle(
            color: Color(0xFF6D2840),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFB53E6B),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFFF8D7E0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9E6ED),
          labelStyle: const TextStyle(color: Color(0xFFB53E6B)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFB53E6B), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFDFA6B9)),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIconColor: const Color(0xFFB53E6B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB53E6B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF6D2840)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFB53E6B),
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilSayfasi()),
              );
            },
          ),
          title: const Text('İlaç Takip'),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'İlaçlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: ilaclar.isEmpty
            ? const Center(
                child: Text(
                  "Henüz ilaç eklenmedi.",
                  style: TextStyle(
                      color: Color(0xFFB53E6B),
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
              )
            : ListView.builder(
                itemCount: ilaclar.length,
                itemBuilder: (context, index) {
                  final ilac = ilaclar[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        ilac.ad,
                        style: const TextStyle(
                            color: Color(0xFF6D2840),
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${ilac.zaman} - ${ilac.saat}",
                        style: const TextStyle(color: Color(0xFF9E5160)),
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_right,
                          color: Color(0xFFB53E6B)),
                      onTap: () => _ilacDetay(ilac, index),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _ilacEkleOrDuzenle(),
          icon: const Icon(Icons.add),
          label: const Text("İlaç Ekle"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class IlacForm extends StatefulWidget {
  final Ilac? ilac;

  const IlacForm({super.key, this.ilac});

  @override
  State<IlacForm> createState() => _IlacFormState();
  
  void onSubmit(Ilac yeniIlac) {}
}

class _IlacFormState extends State<IlacForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController adController;
  late TextEditingController dozajController;
  String? secilenTur;
  String aclikDurumu = "Aç";
  String secilenZaman = "Sabah"; // Bu artık tam olarak kullanılmayacak, çoklu zaman var
  late TextEditingController miktarController;
  late TextEditingController notController;

  final List<String> turler = [
    "Tablet",
    "Şurup",
    "Enjeksiyon",
    "Kapsül",
    "Fitil",
    "Krem",
  ];

  final List<String> zamanlar = ["Sabah", "Öğle", "Akşam"];
  final List<String> aclikDurumlari = ["Aç", "Tok", "Aç ve Tok"];

  // Yeni: Günde kaç kez kullanılacak? 1-3 arası seçim
  int kullanmaSayisi = 1;

  // Her zaman için seçilen saatleri tutalım
  List<TimeOfDay?> secilenSaatler = [null, null, null];

  @override
  void initState() {
    super.initState();
    final ilac = widget.ilac;
    adController = TextEditingController(text: ilac?.ad ?? "");
    dozajController = TextEditingController(text: ilac?.dozaj ?? "");
    miktarController = TextEditingController(text: ilac?.miktar ?? "");
    notController = TextEditingController(text: ilac?.not ?? "");
    secilenTur = ilac?.tur ?? turler[0];
    aclikDurumu = ilac?.aclikDurumu ?? aclikDurumlari[0];
    kullanmaSayisi = 1; // Varsayılan 1

    // Saat bilgisi varsa onu da parse et (ilk saat için)
    if (ilac?.saat != null && ilac!.saat.isNotEmpty) {
      final parts = ilac.saat.split(":");
      if (parts.length == 2) {
        secilenSaatler[0] = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    // Eğer daha önce birden fazla saat seçilmişse, onu burada handle etmek için
    // ilac sınıfını da buna göre genişletmek lazım, şimdilik ilk saati alıyoruz
    for (int i = 0; i < kullanmaSayisi; i++) {
      secilenSaatler[i] ??= const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _saatSec(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: secilenSaatler[index] ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB53E6B),
              onPrimary: Colors.white,
              onSurface: Color(0xFFB53E6B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB53E6B),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        secilenSaatler[index] = picked;
      });
    }
  }

  @override
  void dispose() {
    adController.dispose();
    dozajController.dispose();
    miktarController.dispose();
    notController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String saatMetni(int index) => secilenSaatler[index]?.format(context) ?? "Saat Seçiniz";

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.ilac == null ? "Yeni İlaç Ekle" : "İlaç Düzenle",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB53E6B)),
              ),
              const SizedBox(height: 16),

              // İlaç Adı
              TextFormField(
                controller: adController,
                decoration: const InputDecoration(
                  labelText: "İlaç Adı",
                  prefixIcon: Icon(Icons.medication, color: Color(0xFFB53E6B)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "İlaç adı boş olamaz";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // İlaç Türü Dropdown
              DropdownButtonFormField<String>(
                value: secilenTur,
                decoration: const InputDecoration(
                  labelText: "İlaç Türü",
                  prefixIcon: Icon(Icons.category, color: Color(0xFFB53E6B)),
                ),
                items: turler
                    .map((tur) =>
                        DropdownMenuItem(value: tur, child: Text(tur)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    secilenTur = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Dozaj
              TextFormField(
                controller: dozajController,
                decoration: const InputDecoration(
                  labelText: "Dozaj (örn: 2 tablet)",
                  prefixIcon: Icon(Icons.scale, color: Color(0xFFB53E6B)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Dozaj boş olamaz";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Miktar
              TextFormField(
                controller: miktarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Miktar (adet/mL)",
                  prefixIcon:
                      Icon(Icons.confirmation_num, color: Color(0xFFB53E6B)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Miktar boş olamaz";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Günde kaç kez kullanılacak? Dropdown
              DropdownButtonFormField<int>(
                value: kullanmaSayisi,
                decoration: const InputDecoration(
                  labelText: "Günde kaç kez kullanılacak?",
                  prefixIcon: Icon(Icons.repeat, color: Color(0xFFB53E6B)),
                ),
                items: [1, 2, 3]
                    .map((sayi) =>
                        DropdownMenuItem(value: sayi, child: Text("$sayi kez")))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      kullanmaSayisi = value;
                      // Eksik saatleri default 8:00 olarak ata
                      for (int i = 0; i < kullanmaSayisi; i++) {
                        secilenSaatler[i] ??= const TimeOfDay(hour: 8, minute: 0);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Dinamik saat seçimleri
              Column(
                children: List.generate(kullanmaSayisi, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          index == 0
                              ? Icons.wb_sunny
                              : index == 1
                                  ? Icons.brightness_high
                                  : Icons.nightlight_round,
                          color: const Color(0xFFB53E6B),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          zamanlar[index],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
fontSize: 16),
),
const SizedBox(width: 24),
Expanded(
child: InkWell(
onTap: () => _saatSec(index),
child: InputDecorator(
decoration: InputDecoration(
labelText: "Saat Seçiniz",
prefixIcon: const Icon(Icons.access_time_filled,
color: Color(0xFFB53E6B)),
enabledBorder: OutlineInputBorder(
borderSide:
const BorderSide(color: Color(0xFFDFA6B9)),
borderRadius:
const BorderRadius.all(Radius.circular(12)),
),
focusedBorder: OutlineInputBorder(
borderSide: const BorderSide(
color: Color(0xFFB53E6B), width: 2),
borderRadius:
const BorderRadius.all(Radius.circular(12)),
),
),
child: Text(saatMetni(index)),
),
),
),
],
),
);
}),
),

          // Açlık durumu
          DropdownButtonFormField<String>(
            value: aclikDurumu,
            decoration: const InputDecoration(
              labelText: "Açlık Durumu",
              prefixIcon: Icon(Icons.restaurant, color: Color(0xFFB53E6B)),
            ),
            items: aclikDurumlari
                .map((aclik) =>
                    DropdownMenuItem(value: aclik, child: Text(aclik)))
                .toList(),
            onChanged: (value) {
              setState(() {
                aclikDurumu = value!;
              });
            },
          ),
          const SizedBox(height: 12),

          // Not
          TextFormField(
            controller: notController,
            decoration: const InputDecoration(
              labelText: "Notlar",
              prefixIcon: Icon(Icons.note, color: Color(0xFFB53E6B)),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB53E6B),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // İlac objesi oluştur, saatleri stringe dönüştür
                final saatStr =
                    secilenSaatler.take(kullanmaSayisi).map((saat) {
                  if (saat == null) return "08:00";
                  final h = saat.hour.toString().padLeft(2, '0');
                  final m = saat.minute.toString().padLeft(2, '0');
                  return "$h:$m";
                }).join(","); // Virgülle ayırıyoruz

                final yeniIlac = Ilac(
                  ad: adController.text.trim(),
                  tur: secilenTur!,
                  dozaj: dozajController.text.trim(),
                  miktar: miktarController.text.trim(),
                  zaman: kullanmaSayisi == 1
                      ? zamanlar[0]
                      : "$kullanmaSayisi kez/gün",
                  saat: saatStr,
                  aclikDurumu: aclikDurumu,
                  not: notController.text.trim(),
                );

                widget.onSubmit(yeniIlac);
                Navigator.of(context).pop();
              }
            },
            child: Text(
              widget.ilac == null ? "Ekle" : "Güncelle",
              style: const TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    ),
  ),
);
  }
}