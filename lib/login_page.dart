import 'package:flutter/material.dart';
import 'package:gluco_reminder/auth_service.dart';
import 'package:gluco_reminder/register_page.dart';
import 'package:gluco_reminder/bottom_nav_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

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
              content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4FD2D2), // Set scaffold background
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4FD2D2),
              Color(0xFF76C7C0),
              Color(0xFF9DBEBB),
              Color(0xFFF8F9FA),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                           MediaQuery.of(context).padding.top -
                           MediaQuery.of(context).padding.bottom,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),

                    // Logo/Title with gradient
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                  Color(0xFF4FD2D2).withOpacity(0.3),
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
                              Icons.medical_services,
                              size: 60,
                              color: Color(0xFF2A9D9D),
                            ),
                          ),
                          SizedBox(height: 24),
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
                              'GlucoReminder',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A9D9D),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Hoş Geldiniz',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 50),

                    // Email Field with gradient border
                    Container(
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@email.com',
                          labelStyle: TextStyle(color: Color(0xFF2A9D9D)),
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4FD2D2), Color(0xFF2A9D9D)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.email, color: Colors.white, size: 20),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta adresi gerekli';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // Password Field with gradient border
                    Container(
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
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          hintText: 'Şifrenizi girin',
                          labelStyle: TextStyle(color: Color(0xFF2A9D9D)),
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4FD2D2), Color(0xFF2A9D9D)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.lock, color: Colors.white, size: 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Color(0xFF4FD2D2),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: 30),

                    // Login Button with gradient
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                            Color(0xFF4FD2D2).withOpacity(0.3),
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
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Color(0xFF2A9D9D))
                            : Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A9D9D),
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Register Link with gradient background
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hesabınız yok mu? ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.white.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Kaydol',
                                style: TextStyle(
                                  color: Color(0xFF2A9D9D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 60), // Extra padding at bottom
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