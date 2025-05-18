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
  Widget _buildTextField(String label, TextEditingController controller) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      fillColor: Color(0xFFF2F0F3),
      filled: true,
    ),
    validator: (value) =>
        value == null || value.isEmpty ? "$label boş bırakılamaz" : null,
  );
}

Widget _buildDropdown(
    String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
  return DropdownButtonFormField<String>(
    value: selectedValue,
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Color(0xFFF2F0F3),
    ),
  );
}

Widget _buildDropdownInt(
    String label, List<int> items, int selectedValue, ValueChanged<int?> onChanged) {
  return DropdownButtonFormField<int>(
    value: selectedValue,
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text("$item kez")))
        .toList(),
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Color(0xFFF2F0F3),
    ),
  );
}


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
    );
    if (picked != null) {
      setState(() {
        secilenSaatler[index] = picked;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(
      top: 24,
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medication_liquid, size: 48, color: Color(0xFFB53E6B)),
              const SizedBox(height: 8),
              Text(
                widget.ilac == null ? "Yeni İlaç Ekle" : "İlaç Düzenle",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB53E6B),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField("İlaç Adı", adController),
              const SizedBox(height: 12),

              _buildDropdown("İlaç Türü", turler, secilenTur, (val) {
                setState(() => secilenTur = val);
              }),
              const SizedBox(height: 12),

              _buildTextField("Dozaj", dozajController),
              const SizedBox(height: 12),

              _buildTextField("Kullanım Miktarı", miktarController),
              const SizedBox(height: 12),

              _buildDropdown("Açlık Durumu", aclikDurumlari, aclikDurumu, (val) {
                setState(() => aclikDurumu = val ?? "Aç");
              }),
              const SizedBox(height: 12),

              _buildDropdownInt("Günde Kaç Kez?", [1, 2, 3], kullanmaSayisi, (val) {
                setState(() {
                  kullanmaSayisi = val!;
                });
              }),
              const SizedBox(height: 12),

              ...List.generate(kullanmaSayisi, (index) {
                final zamanEtiketi = zamanlar[index];
                final saat = secilenSaatler[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.schedule, color: Color(0xFF6D2840)),
                    title: Text("$zamanEtiketi Saati"),
                    trailing: TextButton(
                      onPressed: () => _saatSec(index),
                      child: Text(
                        saat != null ? saat.format(context) : "Saat Seç",
                        style: const TextStyle(color: Color(0xFF6D2840)),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              _buildTextField("Not", notController),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String zaman = zamanlar.take(kullanmaSayisi).join(", ");
                    String saat = secilenSaatler
                        .take(kullanmaSayisi)
                        .map((s) => s!.format(context))
                        .join(", ");

                    final yeniIlac = Ilac(
                      ad: adController.text,
                      tur: secilenTur ?? "",
                      dozaj: dozajController.text,
                      miktar: miktarController.text,
                      zaman: zaman,
                      saat: saat,
                      aclikDurumu: aclikDurumu,
                      not: notController.text,
                    );
                    Navigator.pop(context, yeniIlac);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Kaydet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB53E6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}