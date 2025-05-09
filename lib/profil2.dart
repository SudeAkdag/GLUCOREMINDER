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
  ImageProvider? profileImage;

  @override
  void initState() {
    super.initState();
    profileImage = const AssetImage('assets/profile_placeholder.png');
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: profileImage,
                onBackgroundImageError: (exception, stackTrace) {
                  setState(() {
                    profileImage = const AssetImage('assets/fallback.png');
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField('Ad Soyad', _controllers['name']!),
              _buildTextField('Doğum Tarihi', _controllers['birthDate']!),
              _buildDropdown('Cinsiyet', gender, ['Kadın', 'Erkek'], (v) {
                if (v != null) {
                  setState(() => gender = v);
                }
              }),
              Row(
                children: [
                  Expanded(child: _buildTextField('Boy (cm)', _controllers['height']!)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Kilo (kg)', _controllers['weight']!)),
                ],
              ),
              _buildDropdown('Diyabet Tipi', diabetesType, ['Tip I', 'Tip II'], (v) {
                if (v != null) {
                  setState(() => diabetesType = v);
                }
              }),
              _buildTextField('Acil Durum Bilgisi', _controllers['emergency']!),
              _buildTextField('Kan Grubu', _controllers['blood']!),
              _buildTextField('İletişim Bilgisi', _controllers['contact']!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil Kaydedildi')),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

