import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RandevuEkleme extends StatefulWidget {
  const RandevuEkleme({Key? key}) : super(key: key);

  @override
  _RandevuEklemeState createState() => _RandevuEklemeState();
}

class _RandevuEklemeState extends State<RandevuEkleme> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _doktorAdiController = TextEditingController();
  final TextEditingController _hastaneAdiController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notlarController = TextEditingController();
  final TextEditingController _randevuTuruController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Randevu türleri listesi
  final List<String> _randevuTurleri = [
    'Hastane',
    'Klinik',
  ];

  @override
  void dispose() {
    _doktorAdiController.dispose();
    _hastaneAdiController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notlarController.dispose();
    _randevuTuruController.dispose();
    super.dispose();
  }

  // Tarih seçme fonksiyonu
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4FD2D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4FD2D2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // Saat seçme fonksiyonu
  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4FD2D2),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4FD2D2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;

        // Saat ve dakikayı iki basamaklı olarak formatla
        final String hour = pickedTime.hour.toString().padLeft(2, '0');
        final String minute = pickedTime.minute.toString().padLeft(2, '0');
        _timeController.text = '$hour:$minute';
      });
    }
  }

  // Randevu türü seçme diyaloğu
  Future<void> _showRandevuTuruDialog() async {
    FocusScope.of(context).unfocus();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Randevu Türü Seçin',
            style: TextStyle(color: Color.fromARGB(255, 69, 213, 213)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 100,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _randevuTurleri.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_randevuTurleri[index]),
                  onTap: () {
                    setState(() {
                      _randevuTuruController.text = _randevuTurleri[index];
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal',
                  style: TextStyle(color: Color.fromARGB(255, 69, 213, 213))),
            ),
          ],
        );
      },
    );
  }

  // Kaydetme fonksiyonu
  Future<void> _kaydet() async {
    // Form doğrulama
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // String tarihi DateTime'a çevir
        DateFormat format = DateFormat("dd/MM/yyyy");
        DateTime tarihDateTime = format.parse(_dateController.text);

        // Firebase Firestore'a kaydet
        await FirebaseFirestore.instance.collection('randevular').add({
          'doktorAdi': _doktorAdiController.text.trim(),
          'hastaneAdi': _hastaneAdiController.text.trim(),
          'randevuTuru': _randevuTuruController.text.trim(),
          'tarih': Timestamp.fromDate(tarihDateTime),
          'saat': _timeController.text.trim(),
          'notlar': _notlarController.text.trim(),
          'eklenmeZamani': FieldValue.serverTimestamp(),
        });

        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Önceki sayfaya geri dön
        Navigator.pop(context, true);
      } catch (e) {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Form doğrulama hatası
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm gerekli alanları doldurun.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Yeni Randevu',
          style: TextStyle(fontSize: 20, color: Colors.black87),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4FD2D2)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4FD2D2)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Randevu Bilgileri'),
                    SizedBox(height: 10),
                    _buildTextField(
                      controller: _randevuTuruController,
                      labelText: 'Randevu Türü',
                      hintText: 'Randevu türünü seçin',
                      prefixIcon: Icons.category,
                      suffixIcon: Icons.arrow_drop_down,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Randevu türü seçin';
                        }
                        return null;
                      },
                      onTap: _showRandevuTuruDialog,
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                      controller: _doktorAdiController,
                      labelText: 'Doktor Adı',
                      hintText: 'Doktor adını girin',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Doktor adı gerekli';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _hastaneAdiController,
                      labelText: 'Hastane / Klinik',
                      hintText: 'Hastane veya klinik adını girin',
                      prefixIcon: Icons.local_hospital,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Hastane/klinik adı gerekli';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    _buildSectionTitle('Randevu Zamanı'),
                    SizedBox(height: 10),
                    _buildTextField(
                      controller: _dateController,
                      labelText: 'Tarih',
                      hintText: 'Tarih seçin',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tarih seçin';
                        }
                        return null;
                      },
                      onTap: _pickDate,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _timeController,
                      labelText: 'Saat',
                      hintText: 'Saat seçin',
                      prefixIcon: Icons.access_time,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Saat seçin';
                        }
                        return null;
                      },
                      onTap: _pickTime,
                    ),
                    SizedBox(height: 24),
                    _buildSectionTitle('Ek Bilgiler'),
                    SizedBox(height: 10),
                    _buildTextField(
                      controller: _notlarController,
                      labelText: 'Notlar (İsteğe Bağlı)',
                      hintText: 'Randevu ile ilgili notlarınızı yazın',
                      prefixIcon: Icons.note,
                      maxLines: 3,
                    ),
                    SizedBox(height: 40),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2A9D9D),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Color(0xFF4FD2D2)),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Color(0xFF4FD2D2))
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF4FD2D2).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF4FD2D2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          errorStyle: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4FD2D2).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _kaydet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4FD2D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save,
              size: 22,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            SizedBox(width: 10),
            Text(
              'KAYDET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
