import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gluco_reminder/profil.dart';

class Ilac {
  String ad;
  String tur;
  String dozaj;
  String miktar;
  String zaman;
  List<String> saat;
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

  factory Ilac.fromMap(Map<String, dynamic> map) {
    final dynamic saatVerisi = map['saat'];
    return Ilac(
      ad: map['ad'] ?? '',
      tur: map['tur'] ?? '',
      dozaj: map['dozaj'] ?? '',
      miktar: map['miktar'] ?? '',
      zaman: map['zaman'] ?? '',
      saat: saatVerisi is String
          ? saatVerisi.split(',').map((e) => e.trim()).toList()
          : List<String>.from(saatVerisi ?? []),
      aclikDurumu: map['aclikDurumu'] ?? '',
      not: map['not'] ?? '',
    );
  }
}

class IlacSayfasi extends StatefulWidget {
  const IlacSayfasi({super.key});

  @override
  State<IlacSayfasi> createState() => _IlacSayfasiState();
}

class _IlacSayfasiState extends State<IlacSayfasi> {
  List<Ilac> ilaclar = [];

  @override
  void initState() {
    super.initState();
    verileriGetir();
  }

  Future<void> verileriGetir() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("ilac_verileri").get();

    final List<Ilac> geciciListe = querySnapshot.docs
        .map((doc) => Ilac.fromMap(doc.data()))
        .toList();

    setState(() {
      ilaclar = geciciListe;
    });
  }

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
            _detaySatiri("Zaman", "${ilac.zaman} - ${ilac.saat.join(', ')}"),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFB53E6B))),
            TextSpan(text: icerik),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF8),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 245, 157, 179),
        foregroundColor: const Color.fromARGB(255, 177, 64, 103),
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 203, 95, 136),
            child: Icon(Icons.person, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilSayfasi()),
            );
          },
        ),
        title: const Text('Kullanıcı',style: TextStyle(fontSize:16) ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.medication, color: Color(0xFF6D2840)),
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  color: const Color(0xFFF8D7E0),
                  child: ListTile(
                    title: Text(
                      ilac.ad,
                      style: const TextStyle(
                          color: Color(0xFF6D2840),
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${ilac.zaman} - ${ilac.saat.join(', ')}",
                      style: const TextStyle(color: Color(0xFF9E5160)),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_right,
                        color: Color.fromARGB(255, 239, 129, 171)),
                    onTap: () => _ilacDetay(ilac, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ilacEkleOrDuzenle(),
        icon: const Icon(Icons.add),
        label: const Text("İlaç Ekle"),
        backgroundColor: const Color.fromARGB(255, 218, 92, 140),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
class IlacForm extends StatefulWidget {
  final Ilac? ilac;

  const IlacForm({super.key, this.ilac});

  @override
  State<IlacForm> createState() => _IlacFormState();
}

class _IlacFormState extends State<IlacForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController adController;
  late TextEditingController dozajController;
  late TextEditingController miktarController;
  late TextEditingController notController;

  String? secilenTur;
  String aclikDurumu = "Aç";
  int kullanmaSayisi = 1;
  List<TimeOfDay?> secilenSaatler = [null, null, null];

  final List<String> turler = [
    "Tablet", "Şurup", "Enjeksiyon", "Kapsül", "Fitil", "Krem"
  ];
  final List<String> aclikDurumlari = ["Aç", "Tok", "Aç veya Tok"];

  @override
  void initState() {
    super.initState();
    adController = TextEditingController(text: widget.ilac?.ad ?? '');
    dozajController = TextEditingController(text: widget.ilac?.dozaj ?? '');
    miktarController = TextEditingController(text: widget.ilac?.miktar ?? '');
    notController = TextEditingController(text: widget.ilac?.not ?? '');
    secilenTur = widget.ilac?.tur;
    aclikDurumu = widget.ilac?.aclikDurumu ?? "Aç";

    if (widget.ilac != null && widget.ilac!.saat.isNotEmpty) {
      final saatListesi = widget.ilac!.saat;
      kullanmaSayisi = saatListesi.length;
      secilenSaatler = List.generate(3, (index) {
        if (index < saatListesi.length) {
          final time = _parseTimeOfDay(saatListesi[index]);
          return time;
        }
        return null;
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

  TimeOfDay? _parseTimeOfDay(String input) {
    try {
      final parts = input.split(' ');
      final saatDakika = parts[0].split(':');
      final hour = int.parse(saatDakika[0]);
      final minute = int.parse(saatDakika[1]);
      final isPM = parts[1].toUpperCase() == 'PM';
      return TimeOfDay(hour: isPM && hour != 12 ? hour + 12 : hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saatSec(int index) async {
    final TimeOfDay? secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (secilen != null) {
      setState(() {
        secilenSaatler[index] = secilen;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:${tod.minute.toString().padLeft(2, '0')} $period";
  }

  void _onFormSubmit() async {
    if (_formKey.currentState!.validate()) {
      final ilac = Ilac(
        ad: adController.text,
        tur: secilenTur ?? '',
        dozaj: dozajController.text,
        miktar: miktarController.text,
        zaman: kullanmaSayisi == 1 ? "Tek Zaman" : "Çoklu Zaman",
        saat: secilenSaatler
            .where((saat) => saat != null)
            .map((saat) => _formatTimeOfDay(saat!))
            .toList(),
        aclikDurumu: aclikDurumu,
        not: notController.text,
      );

      try {
        await FirebaseFirestore.instance.collection("ilac_verileri").add({
          'ad': ilac.ad,
          'tur': ilac.tur,
          'dozaj': ilac.dozaj,
          'miktar': ilac.miktar,
          'zaman': ilac.zaman,
          'saat': ilac.saat, // artık liste olarak kaydediliyor
          'aclikDurumu': ilac.aclikDurumu,
          'not': ilac.not,
          'eklenmeZamani': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context, ilac);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt hatası: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("İlaç Adı", adController),
              const SizedBox(height: 12),
              _buildDropdown("İlaç Türü", turler, secilenTur,
                  (val) => setState(() => secilenTur = val)),
              const SizedBox(height: 12),
              _buildTextField("Dozaj (örn: 500mg)", dozajController),
              const SizedBox(height: 12),
              _buildTextField("Kullanım Miktarı", miktarController),
              const SizedBox(height: 12),
              _buildDropdown("Aç/Tok", aclikDurumlari, aclikDurumu,
                  (val) => setState(() => aclikDurumu = val!)),
              const SizedBox(height: 12),
              _buildDropdownInt("Günde kaç kez?", [1, 2, 3], kullanmaSayisi,
                  (val) => setState(() => kullanmaSayisi = val ?? 1)),
              const SizedBox(height: 12),

              ...List.generate(kullanmaSayisi, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text("Zaman ${index + 1} saati seç"),
                    subtitle: Text(
                      secilenSaatler[index] != null
                          ? _formatTimeOfDay(secilenSaatler[index]!)
                          : "Henüz seçilmedi",
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _saatSec(index),
                  ),
                );
              }),

              _buildTextField("Not", notController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onFormSubmit,
                child: const Text("Kaydet"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF2F0F3),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "$label boş bırakılamaz" : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items:
          items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF2F0F3),
      ),
    );
  }

  Widget _buildDropdownInt(String label, List<int> items, int selectedValue,
      ValueChanged<int?> onChanged) {
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
        fillColor: const Color(0xFFF2F0F3),
      ),
    );
  }
}