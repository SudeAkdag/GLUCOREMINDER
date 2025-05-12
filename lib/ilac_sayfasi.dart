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
        title: Text(ilac.ad),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tür: ${ilac.tur}"),
            Text("Dozaj: ${ilac.dozaj}"),
            Text("Miktar: ${ilac.miktar}"),
            Text("Zaman: ${ilac.zaman} - ${ilac.saat}"),
            Text("Açlık/Tokluk: ${ilac.aclikDurumu}"),
            Text("Not: ${ilac.not.isEmpty ? 'Yok' : ilac.not}"),
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF7F5FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD8C6F1),
          foregroundColor: Colors.black,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF815AC0),
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
              child: Text('İlaç Sayfası', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        body: ilaclar.isEmpty
            ? const Center(child: Text("Henüz ilaç eklenmedi."))
            : ListView.builder(
                itemCount: ilaclar.length,
                itemBuilder: (context, index) {
                  final ilac = ilaclar[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(ilac.ad),
                      subtitle: Text("${ilac.zaman} - ${ilac.saat}"),
                      onTap: () => _ilacDetay(ilac, index),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _ilacEkleOrDuzenle(),
          icon: const Icon(Icons.add),
          label: const Text("İlaç Ekle"),
          backgroundColor: const Color(0xFF815AC0),
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
}

class _IlacFormState extends State<IlacForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController adController;
  late TextEditingController turController;
  late TextEditingController dozajController;
  late TextEditingController miktarController;
  late TextEditingController saatController;
  late TextEditingController notController;
  String secilenZaman = 'Sabah';
  String aclikDurumu = 'Aç';

  @override
  void initState() {
    super.initState();
    adController = TextEditingController(text: widget.ilac?.ad ?? '');
    turController = TextEditingController(text: widget.ilac?.tur ?? '');
    dozajController = TextEditingController(text: widget.ilac?.dozaj ?? '');
    miktarController = TextEditingController(text: widget.ilac?.miktar ?? '');
    saatController = TextEditingController(text: widget.ilac?.saat ?? '');
    notController = TextEditingController(text: widget.ilac?.not ?? '');
    secilenZaman = widget.ilac?.zaman ?? 'Sabah';
    aclikDurumu = widget.ilac?.aclikDurumu ?? 'Aç';
  }

  @override
  void dispose() {
    adController.dispose();
    turController.dispose();
    dozajController.dispose();
    miktarController.dispose();
    saatController.dispose();
    notController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 16, right: 16, top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(widget.ilac != null ? "İlaç Düzenle" : "Yeni İlaç Ekle", style: const TextStyle(fontSize: 18)),
              TextFormField(controller: adController, decoration: const InputDecoration(labelText: "İlaç Adı")),
              TextFormField(controller: turController, decoration: const InputDecoration(labelText: "İlaç Türü")),
              TextFormField(controller: dozajController, decoration: const InputDecoration(labelText: "Dozaj")),
              TextFormField(controller: miktarController, decoration: const InputDecoration(labelText: "Kullanım Miktarı")),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: secilenZaman,
                      items: ['Sabah', 'Öğle', 'Akşam']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => secilenZaman = val);
                      },
                      decoration: const InputDecoration(labelText: "Zaman"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: saatController,
                      decoration: const InputDecoration(labelText: "Saat (örn: 08:00)"),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: aclikDurumu,
                items: ['Aç', 'Tok', 'Fark etmez']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => aclikDurumu = val);
                },
                decoration: const InputDecoration(labelText: "Açlık/Tokluk Durumu"),
              ),
              TextFormField(
                controller: notController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Not"),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İptal"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(
                            context,
                            Ilac(
                              ad: adController.text,
                              tur: turController.text,
                              dozaj: dozajController.text,
                              miktar: miktarController.text,
                              zaman: secilenZaman,
                              saat: saatController.text,
                              aclikDurumu: aclikDurumu,
                              not: notController.text,
                            ),
                          );
                        }
                      },
                      child: const Text("Kaydet"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}    




