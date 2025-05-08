import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RandevuEkleme(),
    );
  }
}

class RandevuEkleme extends StatefulWidget {
  const RandevuEkleme({super.key});

  @override
  _RandevuEklemeState createState() => _RandevuEklemeState();
}

class _RandevuEklemeState extends State<RandevuEkleme> {
  TextEditingController _doktorAdiController = TextEditingController();
  TextEditingController _hastaneAdiController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _notlarController = TextEditingController();
  TextEditingController _randevuTuruController = TextEditingController();

  // 📌 Tarih seçme fonksiyonu
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  // 📌 Saat seçme fonksiyonu
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = "${pickedTime.hour}:${pickedTime.minute}";
      });
    }
  }

  void _kaydet() async {
    // Eğer herhangi bir alan boşsa uyarı göster ve işlemi durdur
    if (_doktorAdiController.text.isEmpty ||
        _hastaneAdiController.text.isEmpty ||
        _randevuTuruController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }
    // String tarihi DateTime'a çevir (Firestore'da saklamak için)
    DateFormat format = DateFormat("dd/MM/yyyy");
    DateTime tarihDateTime = format.parse(_dateController.text);

    await FirebaseFirestore.instance.collection('randevular').add({
      'doktorAdi': _doktorAdiController.text,
      'hastaneAdi': _hastaneAdiController.text,
      'randevuTuru': _randevuTuruController.text,
      'tarih': Timestamp.fromDate(tarihDateTime),
      'saat': _timeController.text,
      'notlar': _notlarController.text,
      'eklenmeZamani': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Randevu Ekleme',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _doktorAdiController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210),
                      width: 2), // Normal durumdaki kenarlık rengi
                  borderRadius:
                      BorderRadius.circular(10), // Kenarları yuvarlak yap
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.green,
                      width: 2), // Tıklanınca kenarlık rengi
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Doktor Adı:",
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _hastaneAdiController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Hastane Adı:",
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _randevuTuruController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Randevu Türü:",
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: Icon(Icons.calendar_today),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Tarih",
              ),
              onTap: _pickDate,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: Icon(Icons.access_time),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Saat:",
              ),
              onTap: _pickTime,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notlarController,
              minLines: 1,
              maxLines: null, // sınırsız büyüme
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 79, 210, 210), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Notlar:",
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _kaydet,
        backgroundColor: Color.fromARGB(255, 79, 210, 210),
        child: Text('Kaydet', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
