import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lostandfound/api_config.dart';

class FormLostPage extends StatelessWidget {
  final int userId;

  const FormLostPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ReportFormPage(
      type: 'lost',
      title: 'Lapor Barang Hilang',
      userId: userId,
    );
  }
}

class ReportFormPage extends StatefulWidget {
  final String type;
  final String title;
  final int userId;

  const ReportFormPage({
    super.key,
    required this.type,
    required this.title,
    required this.userId,
  });

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedCode = 'wallet';

  final List<Map<String, dynamic>> _categories = [
    {
      'code': 'wallet',
      'name': 'Dompet',
      'icon': Icons.account_balance_wallet_outlined,
      'fields': [
        {'key': 'warna', 'label': 'Warna dompet', 'type': 'text'},
        {'key': 'bahan', 'label': 'Bahan', 'type': 'text'},
        {'key': 'ciri', 'label': 'Ciri khusus', 'type': 'textarea'},
      ],
    },
    {
      'code': 'key',
      'name': 'Kunci',
      'icon': Icons.key,
      'fields': [
        {'key': 'merk_motor', 'label': 'Merk motor', 'type': 'text'},
        {'key': 'tipe_motor', 'label': 'Tipe motor', 'type': 'text'},
        {'key': 'gantungan', 'label': 'Gantungan kunci', 'type': 'text'},
      ],
    },
    {
      'code': 'phone',
      'name': 'Handphone',
      'icon': Icons.phone_android,
      'fields': [
        {'key': 'merk', 'label': 'Merk handphone', 'type': 'text'},
        {'key': 'tipe', 'label': 'Tipe handphone', 'type': 'text'},
        {'key': 'warna', 'label': 'Warna', 'type': 'text'},
      ],
    },
  ];

  Map<String, dynamic> get _selectedCategory {
    return _categories.firstWhere((item) => item['code'] == _selectedCode);
  }

  List<Map<String, String>> get _selectedFields {
    return (_selectedCategory['fields'] as List)
        .map((field) => Map<String, String>.from(field))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _submitReport() async {
    final details = _selectedFields.map((field) {
      return {
        'field_key': field['key'],
        'field_label': field['label'],
        'field_value': _controllerFor(field['key']!).text,
      };
    }).toList();

    String combinedText = _selectedFields
        .map((field) {
          String value = _controllerFor(field['key']!).text;
          return "${field['label']}: $value";
        })
        .join(", ");

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse('$apiBaseUrl/insert.php'),
        body: {
          'user_id': widget.userId.toString(),
          'type': widget.type,
          'category_code': _selectedCode,
          'details': jsonEncode(details),
          'combined_text': combinedText,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);

        if (resData['success'] == true || resData['status'] == 'success') {
          List matches =
              resData['matches_found'] ??
              resData['matches'] ??
              resData['barang_mirip'] ??
              [];

          if (widget.type == 'lost' && matches.isNotEmpty) {
            _showMatchDialog(matches);
          } else {
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resData['message'] ?? 'Gagal menyimpan laporan'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  void _showMatchDialog(List matches) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: const [
              Icon(Icons.gpp_maybe_outlined, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text(
                'Barang Mirip Ditemukan!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistem mendeteksi ada barang dengan deskripsi yang mirip dengan laporanmu. Untuk keamanan, detail barang ditemukan tidak ditampilkan.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final item = matches[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xffEAF5F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.manage_search_outlined,
                            color: Color(0xff0D7A70),
                          ),
                          title: Text(
                            'Kemiripan: ${item['kemiripan']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0D7A70),
                            ),
                          ),
                          subtitle: const Text(
                            'Silakan datang ke bagian Lost and Found untuk verifikasi kepemilikan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(this.context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff087A70),
              ),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7FBFA),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xffF7FBFA),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
          children: [
            const Text(
              'Jenis barang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: _categories.map((category) {
                final bool isSelected = category['code'] == _selectedCode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCode = category['code'];
                        });
                      },
                      icon: Icon(category['icon'], size: 18),
                      label: Text(category['name']),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: isSelected
                            ? const Color(0xffCFEDEA)
                            : Colors.transparent,
                        foregroundColor: isSelected
                            ? const Color(0xff0D7A70)
                            : Colors.black87,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xffCFEDEA)
                              : const Color(0xffAAB8B6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            ..._selectedFields.map((field) {
              final bool isTextarea = field['type'] == 'textarea';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _controllerFor(field['key']!),
                  minLines: isTextarea ? 4 : 1,
                  maxLines: isTextarea ? 5 : 1,
                  decoration: InputDecoration(
                    hintText: field['label'],
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _submitReport,
            icon: const Icon(Icons.send_outlined),
            label: Text(
              widget.type == 'lost'
                  ? 'Kirim Laporan Hilang'
                  : 'Kirim Laporan Ditemukan',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              backgroundColor: const Color(0xff087A70),
            ),
          ),
        ),
      ),
    );
  }
}
