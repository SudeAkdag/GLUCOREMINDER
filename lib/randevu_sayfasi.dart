import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gluco_reminder/profil.dart';
import 'package:intl/intl.dart';
import "package:gluco_reminder/randevu_ekleme.dart";

class Randevu {
  final String id;
  final String doktorAdi;
  final String hastaneAdi;
  final String randevuTuru; // Now only "Hastane" or "Klinik"
  final DateTime tarih;
  final String saat;
  final String notlar;
  final Timestamp? eklenmeZamani;
  final DateTime fullDateTime; // Tam tarih ve saat için

  Randevu({
    required this.id,
    required this.doktorAdi,
    required this.hastaneAdi,
    required this.randevuTuru,
    required this.tarih,
    required this.saat,
    required this.notlar,
    this.eklenmeZamani,
    required this.fullDateTime,
  });

  factory Randevu.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final DateTime tarih = data['tarih'] != null
        ? (data['tarih'] as Timestamp).toDate()
        : DateTime.now();
    final String saat = data['saat'] ?? '';

    // Saat bilgisini ayrıştır ve tam DateTime oluştur
    DateTime fullDateTime = tarih;
    if (saat.isNotEmpty) {
      final List<String> saatParts = saat.split(':');
      if (saatParts.length == 2) {
        try {
          final int hour = int.parse(saatParts[0]);
          final int minute = int.parse(saatParts[1]);
          fullDateTime =
              DateTime(tarih.year, tarih.month, tarih.day, hour, minute);
        } catch (e) {
          print('Saat ayrıştırma hatası: $e');
        }
      }
    }

    return Randevu(
      id: doc.id,
      doktorAdi: data['doktorAdi'] ?? '',
      hastaneAdi: data['hastaneAdi'] ?? '',
      randevuTuru: data['randevuTuru'] ?? 'Hastane', // Default to "Hastane"
      tarih: tarih,
      saat: saat,
      notlar: data['notlar'] ?? '',
      eklenmeZamani: data['eklenmeZamani'] as Timestamp?,
      fullDateTime: fullDateTime,
    );
  }
}

enum RandevuFiltre { gecmis, yaklasan }

class RandevuSayfasi extends StatefulWidget {
  @override
  _RandevuSayfasiState createState() => _RandevuSayfasiState();
}

class _RandevuSayfasiState extends State<RandevuSayfasi>
    with SingleTickerProviderStateMixin {
  RandevuFiltre seciliFiltre = RandevuFiltre.yaklasan;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          seciliFiltre = _tabController.index == 0
              ? RandevuFiltre.yaklasan
              : RandevuFiltre.gecmis;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Randevu>> randevulariGetir(RandevuFiltre filtre) {
    // Tüm randevuları getir ve daha sonra tarih ve saat'e göre filtreleyeceğiz
    return FirebaseFirestore.instance
        .collection('randevular')
        .orderBy('tarih', descending: false)
        .snapshots()
        .map((snapshot) {
      final List<Randevu> randevular =
          snapshot.docs.map((doc) => Randevu.fromFirestore(doc)).toList();

      // Şimdiki zaman
      final DateTime now = DateTime.now();

      // Tüm randevuları filtreleme (tarih VE saat bilgisine göre)
      if (filtre == RandevuFiltre.yaklasan) {
        // Şu andan sonraki randevular (yaklaşan)
        return randevular
            .where((randevu) => randevu.fullDateTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.fullDateTime
              .compareTo(b.fullDateTime)); // Artan sıralama (en yakın önce)
      } else {
        // Şu andan önceki randevular (geçmiş)
        return randevular
            .where((randevu) => randevu.fullDateTime.isBefore(now))
            .toList()
          ..sort((a, b) => b.fullDateTime
              .compareTo(a.fullDateTime)); // Azalan sıralama (en son önce)
      }
    });
  }

  Future<void> randevuSil(String docId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('randevular')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Randevu başarıyla silindi'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Randevu silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Kullanıcı', style: TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Randevu Sayfası',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 79, 210, 210),
            child: Icon(Icons.person, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilSayfasi()),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF4FD2D2),
          labelColor: Color(0xFF4FD2D2),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Icon(Icons.event_available),
              text: 'Yaklaşan',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Geçmiş',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4FD2D2)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRandevuListesi(RandevuFiltre.yaklasan),
                _buildRandevuListesi(RandevuFiltre.gecmis),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RandevuEkleme()),
          );

          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Randevu başarıyla eklendi!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        backgroundColor: Color(0xFF4FD2D2),
        icon: Icon(Icons.add),
        label: Text('Yeni Randevu'),
        elevation: 4,
      ),
    );
  }

  Widget _buildRandevuListesi(RandevuFiltre filtre) {
    return StreamBuilder<List<Randevu>>(
      stream: randevulariGetir(filtre),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FD2D2)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Bir hata oluştu: ${snapshot.error}'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Yenile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4FD2D2),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(filtre);
        }

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final randevu = snapshot.data![index];
            return _buildRandevuCard(context, randevu);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(RandevuFiltre filtre) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filtre == RandevuFiltre.yaklasan
                ? Icons.event_available
                : Icons.history,
            size: 80,
            color: Color(0xFF4FD2D2).withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            filtre == RandevuFiltre.yaklasan
                ? 'Yaklaşan randevunuz bulunmuyor'
                : 'Geçmiş randevunuz bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRandevuCard(BuildContext context, Randevu randevu) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRandevuDetay(context, randevu),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRandevuIcon(randevu.randevuTuru),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            randevu.randevuTuru,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2A9D9D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            randevu.doktorAdi,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            randevu.hastaneAdi,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      text: DateFormat('dd/MM/yyyy').format(randevu.tarih),
                    ),
                    _buildInfoChip(
                      icon: Icons.access_time,
                      text: randevu.saat,
                    ),
                    _buildActionButton(
                      icon: Icons.visibility,
                      text: 'Detay',
                      onTap: () => _showRandevuDetay(context, randevu),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRandevuIcon(String randevuTuru) {
    IconData icon =
        randevuTuru == 'Klinik' ? Icons.medical_services : Icons.local_hospital;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF4FD2D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 28,
        color: Color(0xFF4FD2D2),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Color(0xFF4FD2D2),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF4FD2D2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Color(0xFF4FD2D2),
            ),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4FD2D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRandevuDetay(BuildContext context, Randevu randevu) {
    final isGecmis = randevu.fullDateTime.isBefore(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Randevu Detayları',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A9D9D),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildDetayItem(
                  'Randevu Türü', randevu.randevuTuru, Icons.category),
              SizedBox(height: 12),
              _buildDetayItem('Doktor', randevu.doktorAdi, Icons.person),
              SizedBox(height: 12),
              _buildDetayItem(
                  'Hastane/Klinik', randevu.hastaneAdi, Icons.local_hospital),
              SizedBox(height: 12),
              _buildDetayItem(
                  'Tarih',
                  DateFormat('dd MMMM yyyy').format(randevu.tarih),
                  Icons.calendar_today),
              SizedBox(height: 12),
              _buildDetayItem('Saat', randevu.saat, Icons.access_time),
              if (randevu.notlar.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildDetayItem('Notlar', randevu.notlar, Icons.note,
                    alignTop: true),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSilOnayDialog(context, randevu.id);
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Randevuyu Sil',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetayItem(String label, String value, IconData icon,
      {bool alignTop = false}) {
    return Row(
      crossAxisAlignment:
          alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF4FD2D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF4FD2D2),
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: alignTop ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<DetailItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF4FD2D2), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              if (item.isNote) {
                return Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.title}: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showSilOnayDialog(BuildContext context, String randevuId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Randevu Sil'),
        content: Text('Bu randevu kaydını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              randevuSil(randevuId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailItem {
  final String? title;
  final String content;
  final bool isNote;

  DetailItem({
    this.title,
    required this.content,
    this.isNote = false,
  });
}
