// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'email': TextEditingController(),
    'name': TextEditingController(),
    'birthDate': TextEditingController(),
    'height': TextEditingController(),
    'weight': TextEditingController(),
    'emergency': TextEditingController(),
    'blood': TextEditingController(),
    'contact': TextEditingController(),
  };

  String gender = 'Kadın';
  String diabetesType = 'Tip I';
  String? documentId;

  @override
  void initState() {
    super.initState();
    _loadProfileFromFirestore();
  }

  Future<void> _loadProfileFromFirestore() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      _controllers['email']!.text = userEmail;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('profil_verileri')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        documentId = doc.id;

        setState(() {
          _controllers['name']!.text = data['ad_soyad'] ?? '';
          _controllers['birthDate']!.text = data['dogum_tarihi'] ?? '';
          gender = data['cinsiyet'] ?? gender;
          _controllers['height']!.text = data['boy'] ?? '';
          _controllers['weight']!.text = data['kilo'] ?? '';
          diabetesType = data['diyabet_tipi'] ?? diabetesType;
          _controllers['emergency']!.text = data['acil_durum'] ?? '';
          _controllers['blood']!.text = data['kan_grubu'] ?? '';
          _controllers['contact']!.text = data['iletisim'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Profil yüklenemedi: $e');
    }
  }

  Future<void> _saveProfileToFirestore() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      final data = {
        'email': userEmail,
        'ad_soyad': _controllers['name']!.text,
        'dogum_tarihi': _controllers['birthDate']!.text,
        'cinsiyet': gender,
        'boy': _controllers['height']!.text,
        'kilo': _controllers['weight']!.text,
        'diyabet_tipi': diabetesType,
        'acil_durum': _controllers['emergency']!.text,
        'kan_grubu': _controllers['blood']!.text,
        'iletisim': _controllers['contact']!.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (documentId != null) {
        await FirebaseFirestore.instance
            .collection('profil_verileri')
            .doc(documentId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi')),
        );
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('profil_verileri')
            .add(data);
        documentId = doc.id;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil oluşturuldu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt sırasında hata: $e')),
      );
    }
  }

  final Color softPink = const Color(0xFFF8E1F4);
  final Color softPurple = const Color(0xFFD7B3E6);
  final Color pastelPurple = const Color(0xFFBFA2DB);
  final Color pastelText = const Color(0xFF6D4C8A);
  final Color borderColor = const Color(0xFFCEB9DE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: pastelPurple,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              _buildTextField('E-posta', _controllers['email']!,
                  icon: Icons.email_outlined, enabled: false),
              _buildTextField('Ad Soyad', _controllers['name']!,
                  icon: Icons.person_outline),
              _buildTextField('Doğum Tarihi', _controllers['birthDate']!,
                  icon: Icons.calendar_today_outlined),
              _buildDropdown('Cinsiyet', gender, ['Kadın', 'Erkek'], (v) {
                if (v != null) setState(() => gender = v);
              }, icon: Icons.wc_outlined),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Boy (cm)', _controllers['height']!,
                        icon: Icons.height_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('Kilo (kg)', _controllers['weight']!,
                        icon: Icons.monitor_weight_outlined),
                  ),
                ],
              ),
              _buildDropdown('Diyabet Tipi', diabetesType, ['Tip I', 'Tip II'],
                  (v) {
                if (v != null) setState(() => diabetesType = v);
              }, icon: Icons.bloodtype_outlined),
              _buildTextField('Acil Durum Bilgisi', _controllers['emergency']!,
                  icon: Icons.warning_amber_outlined),
              _buildTextField('Kan Grubu', _controllers['blood']!,
                  icon: Icons.invert_colors_outlined),
              _buildTextField('İletişim Bilgisi', _controllers['contact']!,
                  icon: Icons.phone_outlined),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _saveProfileToFirestore();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pastelPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [softPurple, softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: pastelPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: CircleAvatar(
        radius: 52,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 48,
          backgroundColor: softPink,
          child: Icon(
            Icons.person_outline,
            size: 58,
            color: pastelText.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: pastelText) : null,
          filled: true,
          fillColor: softPink,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: pastelPurple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        style: TextStyle(color: pastelText),
        validator: (value) {
          if (enabled && (value == null || value.isEmpty)) {
            return 'Bu alan boş olamaz';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        iconEnabledColor: pastelPurple,
        dropdownColor: Colors.white,
        style: TextStyle(color: pastelText, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: pastelText) : null,
          filled: true,
          fillColor: softPink,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: pastelPurple, width: 2),
          ),
        ),
        items: options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt, style: TextStyle(color: pastelText)),
          );
        }).toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return options.map((opt) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                opt,
                style: TextStyle(
                  color: pastelText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
