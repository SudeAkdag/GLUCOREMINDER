// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gluco_reminder/profil.dart';

class Ilac {
  String? docId;
  String ad;
  String tur;
  String dozaj;
  String miktar;
  String zaman;
  List<String> saat;
  String aclikDurumu;
  String not;

  Ilac({
    this.docId,
    required this.ad,
    required this.tur,
    required this.dozaj,
    required this.miktar,
    required this.zaman,
    required this.saat,
    required this.aclikDurumu,
    required this.not,
  });

  factory Ilac.fromMap(Map<String, dynamic> map, String docId) {
    final dynamic saatVerisi = map['saat'];
    return Ilac(
      docId: docId, // <--- BURAYA DA EKLE
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

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'tur': tur,
      'dozaj': dozaj,
      'miktar': miktar,
      'zaman': zaman,
      'saat': saat,
      'aclikDurumu': aclikDurumu,
      'not': not,
      'eklenmeZamani': FieldValue.serverTimestamp(),
    };
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
        .map((doc) =>
            Ilac.fromMap(doc.data(), doc.id)) // 🔁 docId'yi geçiriyoruz
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
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

  Future<void> _ilacSil(int index) async {
    final ilac = ilaclar[index];

    // Firestore'dan kalıcı olarak sil
    if (ilac.docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection("ilac_verileri")
            .doc(ilac.docId)
            .delete();
      } catch (e) {
        debugPrint("Firebase'den silme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme işlemi başarısız: $e")),
        );
        return; // Hata varsa devam etme
      }
    }

    // Listeden çıkar
    setState(() {
      ilaclar.removeAt(index);
    });
  }

  void _ilacDetay(Ilac ilac, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFDF1F8),
        title: Row(
          children: [
            const Icon(Icons.medication_outlined, color: Color(0xFFB53E6B)),
            const SizedBox(width: 8),
            Text(ilac.ad,
                style: const TextStyle(
                    color: Color(0xFFB53E6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detaySatiri("💊 Tür", ilac.tur),
            _detaySatiri("📏 Dozaj", ilac.dozaj),
            _detaySatiri("💧 Miktar", ilac.miktar),
            _detaySatiri("⏰ Zaman", "${ilac.zaman} - ${ilac.saat.join(', ')}"),
            _detaySatiri("🍽️ Açlık/Tokluk", ilac.aclikDurumu),
            _detaySatiri("📝 Not", ilac.not.isEmpty ? 'Yok' : ilac.not),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, color: Colors.deepPurple),
            onPressed: () {
              Navigator.pop(context);
              _ilacEkleOrDuzenle(mevcutIlac: ilac, index: index);
            },
            label: const Text("Düzenle"),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _ilacSil(index);
            },
            label: const Text("Sil"),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$baslik: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFB53E6B)),
          ),
          Expanded(
            child: Text(
              icerik,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 246, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 244, 219, 225),
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
        title: const Text('Kullanıcı', style: TextStyle(fontSize: 16)),
        actions: const [
          Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'İlaç Sayfası',
              style: TextStyle(fontSize: 20),
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
                  fontWeight: FontWeight.w500,
                ),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  shadowColor: Colors.purpleAccent.withOpacity(0.2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE8F1), Color(0xFFE8DAF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFB53E6B),
                        child: Icon(Icons.medication, color: Colors.white),
                      ),
                      title: Text(
                        ilac.ad,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF6D2840),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ilac.zaman} - ${ilac.saat.join(', ')}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E5160),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.local_hospital,
                                    size: 16, color: Color(0xFFB53E6B)),
                                const SizedBox(width: 4),
                                Text(
                                  ilac.tur,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7B4763),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Color(0xFFBF4D90)),
                      onTap: () => _ilacDetay(ilac, index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            right: 16.0, bottom: 16.0), // Sağ ve alt boşluk
        child: GestureDetector(
          onTap: () => _ilacEkleOrDuzenle(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB53E6B), // Pembe
                  Color(0xFF8E2BC9), // Mor
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "İlaç Ekle",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    "Tablet",
    "Şurup",
    "Enjeksiyon",
    "Kapsül",
    "Fitil",
    "Krem"
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
      return TimeOfDay(
          hour: isPM && hour != 12 ? hour + 12 : hour, minute: minute);
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
          'saat': ilac.saat,
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("💊 İlaç Adı", adController),
              const SizedBox(height: 14),
              _buildDropdown("📦 Tür", turler, secilenTur,
                  (val) => setState(() => secilenTur = val)),
              const SizedBox(height: 14),
              _buildTextField("📏 Dozaj (ör: 500mg)", dozajController),
              const SizedBox(height: 14),
              _buildTextField("💧 Kullanım Miktarı", miktarController),
              const SizedBox(height: 14),
              _buildDropdown("🍽️ Aç/Tok", aclikDurumlari, aclikDurumu,
                  (val) => setState(() => aclikDurumu = val!)),
              const SizedBox(height: 14),
              _buildDropdownInt("⏱️ Günde kaç kez?", [1, 2, 3], kullanmaSayisi,
                  (val) => setState(() => kullanmaSayisi = val ?? 1)),
              const SizedBox(height: 14),
              ...List.generate(kullanmaSayisi, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: const Color(0xFFE7DFF5),
                    title: Text("Zaman ${index + 1}"),
                    subtitle: Text(
                      secilenSaatler[index] != null
                          ? _formatTimeOfDay(secilenSaatler[index]!)
                          : "Henüz seçilmedi",
                    ),
                    trailing:
                        const Icon(Icons.access_time, color: Colors.deepPurple),
                    onTap: () => _saatSec(index),
                  ),
                );
              }),
              _buildTextField("📝 Not", notController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFFB53E6B),
                  ),
                  onPressed: _onFormSubmit,
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: const Text(
                    "Kaydet",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
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
        prefixIcon: const Icon(Icons.edit_note),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFFF3EEF9),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "$label boş bırakılamaz" : null,
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();

    return DropdownButtonFormField<String>(
      value: uniqueItems.contains(selectedValue) ? selectedValue : null,
      items: uniqueItems
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFFF3EEF9),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "$label seçilmelidir" : null,
    );
  }

  Widget _buildDropdownInt(
    String label,
    List<int> items,
    int? selectedValue,
    ValueChanged<int?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();

    return DropdownButtonFormField<int>(
      value: uniqueItems.contains(selectedValue) ? selectedValue : null,
      items: uniqueItems
          .map(
              (item) => DropdownMenuItem(value: item, child: Text("$item kez")))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.repeat_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFFF3EEF9),
      ),
      validator: (value) => value == null ? "$label seçilmelidir" : null,
    );
  }
}
