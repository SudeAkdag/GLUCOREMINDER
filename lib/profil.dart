// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gluco_reminder/auth_service.dart';
import 'package:gluco_reminder/profil2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gluco_reminder/auth_wrapper.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilSayfasi(),
    theme: ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: Color(0xFFCE93D8)), // Lila-mor
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 20, color: Colors.black87),
        titleLarge: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    ),
  ));
}

// ------------------ PROFİL SAYFASI ------------------
class ProfilSayfasi extends StatelessWidget {
  final AuthService _authService = AuthService();

  ProfilSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Sayfası")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.account_circle, size: 120, color: Color(0xFFD1C4E9)),
              SizedBox(height: 30),
              Text("Kullanıcı Adı",
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 40),
              CustomBigButton(
                icon: Icons.person,
                text: "Profilim",
                color: Color(0xFFBA68C8), // Mor ton
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => Profil()));
                },
              ),
              CustomBigButton(
                icon: Icons.settings,
                text: "Ayarlar",
                color: Color(0xFFF48FB1), // Pembe ton
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AyarlarSayfasi()));
                },
              ),
              CustomBigButton(
                icon: Icons.help_outline,
                text: "Sıkça Sorulan Sorular",
                color: Color(0xFFCE93D8), // Lila ton
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => SSSSayfasi()));
                },
              ),
              CustomBigButton(
                icon: Icons.logout,
                text: "Çıkış Yap",
                color: Color(0xFFB39DDB), // Yumuşak mor
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Çıkış Yap"),
                      content: Text("Çıkmak istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Hayır"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.signOut();
                              // Force navigation to login page
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => AuthWrapper()),
                                (Route<dynamic> route) => false,
                              );
                            } catch (e) {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Çıkış yapılırken hata oluştu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text("Evet"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ AYARLAR SAYFASI ------------------
class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F5FC), // Arka plan
      appBar: AppBar(
        title: Text("Ayarlar"),
        backgroundColor: Color(0xFF9575CD), // Lavanta moru
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // ---------- BİLDİRİMLER ----------
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Color(0xFFBBDEFB), // Açık mavi
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bildirimler",
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 4),
                      Text("İlaç hatırlatıcı bildirimleri",
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Switch(value: true, onChanged: (val) {})
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // ---------- TEMA ----------
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Color(0xFFD1C4E9), // Lavanta mor
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tema", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 4),
                  Text("Uygulama temasını seçin",
                      style: TextStyle(color: Colors.black54)),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'Aydınlık',
                        items: ['Aydınlık', 'Karanlık']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // ---------- HAKKINDA ----------
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Color(0xFFE3F2FD), // Soft gökyüzü mavisi
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              leading: Icon(Icons.info_outline, color: Colors.deepPurple),
              title: Text("Uygulama Hakkında",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("GlucoReminder v1.0"),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ SSS SAYFASI ------------------
class SSSSayfasi extends StatelessWidget {
  final List<Map<String, String>> sssList = [
    {
      "soru": "1. Diyabet nedir?",
      "cevap":
          "Diyabet, kandaki glukoz seviyesinin normalin üzerine çıkmasıyla ortaya çıkan bir hastalıktır. Tip 1 ve Tip 2 olmak üzere iki ana tipi vardır."
    },
    {
      "soru": "2. Kan şekerimi ne sıklıkla ölçmeliyim?",
      "cevap":
          "Bu, diyabet tipinize ve doktorunuzun önerilerine göre değişir. Tip 1 genelde daha sık kontrol gerektirir."
    },
    {
      "soru": "3. Hipoglisemi nedir, nasıl anlaşılır?",
      "cevap":
          "Kan şekeri 70 mg/dL altına düştüğünde ortaya çıkar. Belirtileri arasında titreme, terleme ve bilinç bulanıklığı vardır."
    },
    {
      "soru": "4. Hangi gıdaları tüketmeliyim?",
      "cevap":
          "Sebzeler, kompleks karbonhidratlar ve sağlıklı yağlar önerilir. Şekerli ve işlenmiş gıdalardan kaçınılmalıdır."
    },
    {
      "soru": "5. Egzersiz yapabilir miyim?",
      "cevap":
          "Evet, egzersiz diyabet kontrolünde faydalıdır. Ancak öncesinde doktorunuza danışmalısınız."
    },
    {
      "soru": "6. İnsülin bağımlılık yapar mı?",
      "cevap":
          "Hayır. İnsülin vücudun ihtiyacını karşılayan bir hormondur, bağımlılık yapmaz."
    },
    {
      "soru": "7. Kan şekerim yüksekken ne yapmalıyım?",
      "cevap":
          "Bol su için, egzersiz yapın (keton yoksa) ve doktorunuzun önerdiği ilacı alın."
    },
    {
      "soru": "8. Diyabet geçer mi?",
      "cevap":
          "Tip 1 geçmez ama Tip 2 yaşam tarzı değişikliğiyle kontrol altına alınabilir."
    },
    {
      "soru": "9. Stres kan şekerini etkiler mi?",
      "cevap": "Evet, stres hormonu kortizol kan şekerini artırabilir."
    },
    {
      "soru": "10. Tatlandırıcılar kullanılabilir mi?",
      "cevap": "Evet, ancak doktorunuza danışarak ve ölçülü kullanmalısınız."
    },
  ];

  SSSSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sıkça Sorulan Sorular")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sssList.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color(0xFFF3E5F5), // Lila arka plan
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sssList[index]['soru']!,
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  Text(sssList[index]['cevap']!,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------ CUSTOM BUTTON ------------------
class CustomBigButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const CustomBigButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 28),
          label: Text(text, style: TextStyle(fontSize: 20)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Color(0xFFCE93D8),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor:
                color?.withOpacity(0.4) ?? Colors.purpleAccent.withOpacity(0.3),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
