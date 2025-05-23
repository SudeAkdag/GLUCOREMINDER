import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gluco_reminder/bottom_nav_bar.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String newText = newValue.text;

    // If user tries to delete the leading 0, prevent it
    if (newText.isEmpty || !newText.startsWith('0')) {
      return TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    // Ensure maximum 11 digits
    if (newText.length > 11) {
      newText = newText.substring(0, 11);
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class RegisterPage2 extends StatefulWidget {
  final String email;

  const RegisterPage2({super.key, required this.email});

  @override
  State<RegisterPage2> createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _iletisimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set initial value for phone number with leading 0
    _iletisimController.text = '0';
  }
  final _acilDurumController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedDiabetesType;
  String? _selectedBloodType;

  bool _isLoading = false;

  final List<String> _genderOptions = ['Erkek', 'Kadın'];
  final List<String> _diabetesTypes = ['Tip 1', 'Tip 2'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'];

  @override
  void dispose() {
    _adSoyadController.dispose();
    _boyController.dispose();
    _kiloController.dispose();
    _iletisimController.dispose();
    _acilDurumController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE91E63),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('profil_verileri').add({
          'email': widget.email,
          'ad_soyad': _adSoyadController.text.trim(),
          'boy': int.parse(_boyController.text.trim()),
          'kilo': double.parse(_kiloController.text.trim()),
          'cinsiyet': _selectedGender,
          'diyabet_tipi': _selectedDiabetesType,
          'kan_grubu': _selectedBloodType,
          'dogum_tarihi': _selectedDate,
          'iletisim': int.parse(_iletisimController.text.trim()),
          'acil_durum': _acilDurumController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigationSayfa()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil kaydedilirken hata oluştu: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: Color(0xFFE91E63)),
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: Color(0xFFE91E63)),
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: FormField<DateTime>(
        validator: (value) {
          if (_selectedDate == null) {
            return 'Doğum tarihi seçilmeli';
          }
          return null;
        },
        builder: (FormFieldState<DateTime> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Doğum tarihi seçiniz'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Color(0xFFE91E63)),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9C27B0),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF9C27B0),
              Color(0xFFE91E63),
              Color(0xFFFF5722),
              Color(0xFFFFC107),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                  Colors.orange.withOpacity(0.3),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 40,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              'Profil Bilgileri',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Lütfen profil bilgilerinizi tamamlayın',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Ad Soyad Field
                    _buildTextFormField(
                      controller: _adSoyadController,
                      labelText: 'Ad Soyad',
                      hintText: 'Adınız ve soyadınız',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad soyad gerekli';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Boy Field
                    _buildTextFormField(
                      controller: _boyController,
                      labelText: 'Boy (cm)',
                      hintText: 'Örn: 175',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Boy bilgisi gerekli';
                        }
                        int? height = int.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Geçerli bir boy değeri girin (100-250)';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Kilo Field
                    _buildTextFormField(
                      controller: _kiloController,
                      labelText: 'Kilo (kg)',
                      hintText: 'Örn: 70.5',
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kilo bilgisi gerekli';
                        }
                        double? weight = double.tryParse(value);
                        if (weight == null || weight < 30 || weight > 300) {
                          return 'Geçerli bir kilo değeri girin (30-300)';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Cinsiyet Dropdown
                    _buildDropdownField(
                      labelText: 'Cinsiyet',
                      hintText: 'Cinsiyetinizi seçin',
                      icon: Icons.people,
                      items: _genderOptions,
                      value: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Cinsiyet seçilmeli';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Diyabet Tipi Dropdown
                    _buildDropdownField(
                      labelText: 'Diyabet Tipi',
                      hintText: 'Diyabet tipinizi seçin',
                      icon: Icons.medical_information,
                      items: _diabetesTypes,
                      value: _selectedDiabetesType,
                      onChanged: (value) {
                        setState(() {
                          _selectedDiabetesType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Diyabet tipi seçilmeli';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Kan Grubu Dropdown
                    _buildDropdownField(
                      labelText: 'Kan Grubu',
                      hintText: 'Kan grubunuzu seçin',
                      icon: Icons.bloodtype,
                      items: _bloodTypes,
                      value: _selectedBloodType,
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Kan grubu seçilmeli';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Doğum Tarihi Field
                    _buildDateField(),

                    SizedBox(height: 20),

                    // İletişim Field
                    _buildTextFormField(
                      controller: _iletisimController,
                      labelText: 'İletişim',
                      hintText: '05xxxxxxxxx',
                      icon: Icons.phone,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        PhoneNumberFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'İletişim bilgisi gerekli';
                        }
                        if (value.length != 11) {
                          return 'Telefon numarası 11 haneli olmalı';
                        }
                        if (!value.startsWith('0')) {
                          return 'Telefon numarası 0 ile başlamalı';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Acil Durum Field
                    _buildTextFormField(
                      controller: _acilDurumController,
                      labelText: 'Acil Durum İletişim',
                      hintText: 'Acil durumda aranacak kişi',
                      icon: Icons.emergency,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Acil durum iletişim bilgisi gerekli';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 30),

                    // Save Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                            Color(0xFFFF5722).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Color(0xFFE91E63))
                            : Text(
                          'Profili Kaydet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}