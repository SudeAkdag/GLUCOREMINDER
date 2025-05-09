import 'package:flutter/material.dart';
import 'package:gluco_reminder/profil.dart';

class IlacSayfasi extends StatefulWidget {
  const IlacSayfasi({super.key});

  @override
  State<IlacSayfasi> createState() => _IlacSayfasiState();
}

class _IlacSayfasiState extends State<IlacSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 79, 210, 210),
            child: Icon(Icons.person, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfilSayfasi()), //profil sayfasına geçiş
            );
          },
        ),
        title: Text(
          'Kullanıcı',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'İlaç Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
