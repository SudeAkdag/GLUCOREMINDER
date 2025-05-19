import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BesinSayfasi extends StatefulWidget {
  @override
  _BesinSayfasiState createState() => _BesinSayfasiState();
}

class _BesinSayfasiState extends State<BesinSayfasi> {
  List<dynamic> yemekler = [];
  Map<String, dynamic>? seciliYemek;

  @override
  void initState() {
    super.initState();
    yemekleriGetir();
  }

  Future<void> yemekleriGetir() async {
    final response = await http.get(Uri.parse('https://yemek-api-zmox.onrender.com/api/recipes'));

    if (response.statusCode == 200) {
      setState(() {
        yemekler = json.decode(response.body);
      });
    } else {
      throw Exception('Yemek verileri alınamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Besin Seçin')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: yemekler.length,
              itemBuilder: (context, index) {
                final yemek = yemekler[index];
                return ListTile(
                  title: Text(yemek['name']),
                  onTap: () {
                    setState(() {
                      seciliYemek = yemek;
                    });
                  },
                );
              },
            ),
          ),
          if (seciliYemek != null)
            Card(
              margin: EdgeInsets.all(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seçilen: ${seciliYemek!['name']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Kalori: ${seciliYemek!['calories']} kcal"),
                    Text("Protein: ${seciliYemek!['protein']} g"),
                    Text("Karbonhidrat: ${seciliYemek!['carbohydrates']} g"),
                    Text("Yağ: ${seciliYemek!['fat']} g"),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}