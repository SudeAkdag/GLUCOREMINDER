import 'package:flutter/material.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
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

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Soft pastel pembe ve mor tonları
  final Color softPink = const Color(0xFFF8E1F4);
  final Color softPurple = const Color(0xFFD7B3E6);
  final Color pastelPurple = const Color(0xFFBFA2DB);
  final Color pastelText = const Color(0xFF6D4C8A);
  final Color borderColor = const Color(0xFFCEB9DE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Beyaz arka plan
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
              // Profil avatarı: soft tonlarda, mat ve sade
              Container(
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
              ),
              const SizedBox(height: 24),

              _buildTextField('Ad Soyad', _controllers['name']!, icon: Icons.person_outline),
              _buildTextField('Doğum Tarihi', _controllers['birthDate']!, icon: Icons.calendar_today_outlined),
              _buildDropdown(
                'Cinsiyet',
                gender,
                ['Kadın', 'Erkek'],
                (v) {
                  if (v != null) setState(() => gender = v);
                },
                icon: Icons.wc_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Boy (cm)', _controllers['height']!, icon: Icons.height_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('Kilo (kg)', _controllers['weight']!, icon: Icons.monitor_weight_outlined),
                  ),
                ],
              ),
              _buildDropdown(
                'Diyabet Tipi',
                diabetesType,
                ['Tip I', 'Tip II'],
                (v) {
                  if (v != null) setState(() => diabetesType = v);
                },
                icon: Icons.bloodtype_outlined,
              ),
              _buildTextField('Acil Durum Bilgisi', _controllers['emergency']!, icon: Icons.warning_amber_outlined),
              _buildTextField('Kan Grubu', _controllers['blood']!, icon: Icons.invert_colors_outlined),
              _buildTextField('İletişim Bilgisi', _controllers['contact']!, icon: Icons.phone_outlined),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil Kaydedildi')),
                    );
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

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
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
          if (value == null || value.isEmpty) {
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
        items: options
            .map(
              (opt) => DropdownMenuItem<String>(
                value: opt,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(opt, style: TextStyle(color: pastelText)),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        // Aşağıdaki dekorasyon dropdown açılırken de geçerli olması için
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
