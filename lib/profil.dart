import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil2.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilSayfasi(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFB0D0D3)), // Buz mavisi
      scaffoldBackgroundColor: Color(0xFFF5F9FA), // Açık mavi-gri arka plan
      useMaterial3: true,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 20, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    ),
  ));
}

// ------------------ PROFİL SAYFASI ------------------
class ProfilSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Sayfası")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.account_circle, size: 120, color: Color(0xFF9DBEBB)),
              SizedBox(height: 30),
              Text("Kullanıcı Adı", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 40),
              CustomBigButton(icon: Icons.person, text: "Profilim", onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => Profil()));
              }),
              CustomBigButton(icon: Icons.settings, text: "Ayarlar", onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AyarlarSayfasi()));
              }),
              CustomBigButton(icon: Icons.help_outline, text: "Sıkça Sorulan Sorular", onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SSSSayfasi()));
              }),
              CustomBigButton(
                icon: Icons.logout,
                text: "Çıkış Yap",
                color: Color(0xFF7C9A9A), // Yumuşak çıkış rengi
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Çıkış Yap"),
                      content: Text("Çıkmak istediğinize emin misiniz?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text("Hayır")),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilSayfasi()));
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bildirim Ayarları", style: Theme.of(context).textTheme.titleLarge),
            Switch(value: true, onChanged: (val) {}),
            SizedBox(height: 20),
            Text("Tema Ayarları", style: Theme.of(context).textTheme.titleLarge),
            DropdownButton<String>(
              value: 'Aydınlık',
              items: ['Aydınlık', 'Karanlık'].map((e) => DropdownMenuItem(child: Text(e), value: e)).toList(),
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ SSS SAYFASI ------------------
class SSSSayfasi extends StatelessWidget {
  final List<Map<String, String>> sssList = [
    {
      "soru": "1. Diyabet nedir?",
      "cevap": "Diyabet, kandaki glukoz seviyesinin normalin üzerine çıkmasıyla ortaya çıkan bir hastalıktır. Tip 1 ve Tip 2 olmak üzere iki ana tipi vardır."
    },
    {
      "soru": "2. Kan şekerimi ne sıklıkla ölçmeliyim?",
      "cevap": "Bu, diyabet tipinize ve doktorunuzun önerilerine göre değişir. Tip 1 genelde daha sık kontrol gerektirir."
    },
    {
      "soru": "3. Hipoglisemi nedir, nasıl anlaşılır?",
      "cevap": "Kan şekeri 70 mg/dL altına düştüğünde ortaya çıkar. Belirtileri arasında titreme, terleme ve bilinç bulanıklığı vardır."
    },
    {
      "soru": "4. Hangi gıdaları tüketmeliyim?",
      "cevap": "Sebzeler, kompleks karbonhidratlar ve sağlıklı yağlar önerilir. Şekerli ve işlenmiş gıdalardan kaçınılmalıdır."
    },
    {
      "soru": "5. Egzersiz yapabilir miyim?",
      "cevap": "Evet, egzersiz diyabet kontrolünde faydalıdır. Ancak öncesinde doktorunuza danışmalısınız."
    },
    {
      "soru": "6. İnsülin bağımlılık yapar mı?",
      "cevap": "Hayır. İnsülin vücudun ihtiyacını karşılayan bir hormondur, bağımlılık yapmaz."
    },
    {
      "soru": "7. Kan şekerim yüksekken ne yapmalıyım?",
      "cevap": "Bol su için, egzersiz yapın (keton yoksa) ve doktorunuzun önerdiği ilacı alın."
    },
    {
      "soru": "8. Diyabet geçer mi?",
      "cevap": "Tip 1 geçmez ama Tip 2 yaşam tarzı değişikliğiyle kontrol altına alınabilir."
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sıkça Sorulan Sorular")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sssList.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color(0xFFE6F1F3), // Hafif gri-buz tonu
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sssList[index]['soru']!, style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  Text(sssList[index]['cevap']!, style: Theme.of(context).textTheme.bodyLarge),
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
            backgroundColor: color ?? Color(0xFF9DBEBB), // Buton rengi
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
