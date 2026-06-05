import 'package:flutter/material.dart';

class ItemLaporanCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemLaporanCard({super.key, required this.data});

  IconData getIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'hp':
      case 'handphone':
      case 'phone':
        return Icons.phone_android;
      case 'dompet':
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'kunci':
      case 'key':
        return Icons.vpn_key_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String judul = data['category_name'] ?? data['kategori'] ?? 'Barang';
    final String kodeKategori = data['category_code'] ?? judul;
    final List details = data['details'] is List ? data['details'] : [];
    final List<String> detailRows = details
        .whereType<Map>()
        .map((detail) {
          final label = detail['field_label'] ?? detail['field_key'] ?? '';
          final value = detail['field_value'] ?? '';
          return label.toString().isEmpty ? value.toString() : '$label: $value';
        })
        .where((text) => text.trim().isNotEmpty)
        .take(3)
        .toList();
    final bool isHiddenFoundDetail =
        data['type'] == 'found' && detailRows.isEmpty;
    final String baris1 =
        data['detail_1'] ??
        (isHiddenFoundDetail
            ? 'Deskripsi disembunyikan.'
            : detailRows.isNotEmpty
            ? detailRows[0]
            : '');
    final String baris2 =
        data['detail_2'] ??
        (isHiddenFoundDetail
            ? 'Silakan datang ke bagian Lost and Found.'
            : detailRows.length > 1
            ? detailRows[1]
            : '');
    final String baris3 =
        data['detail_3'] ?? (detailRows.length > 2 ? detailRows[2] : '');
    final String username = data['username'] ?? data['user_name'] ?? '-';
    final String tanggal = data['tanggal'] ?? data['created_at'] ?? '-';
    final String infoUserTgl = "$username - $tanggal";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xffF7FAFA),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xffE2EAEA), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xffE0ECE9),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              getIcon(kodeKategori),
              color: const Color(0xff0D7A70),
              size: 26,
            ),
          ),
          const SizedBox(width: 14.0),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      getIcon(kodeKategori),
                      size: 14,
                      color: const Color(0xff0D7A70),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      judul,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  baris1,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  baris2,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  baris3,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12.0),
                // Nama User & Waktu
                Text(
                  infoUserTgl,
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: data['type'] == 'lost'
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data['type'] == 'lost' ? 'LOST' : 'FOUND',
              style: TextStyle(
                color: data['type'] == 'lost' ? Colors.red : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
