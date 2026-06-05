import 'package:flutter/material.dart';
import 'package:lostandfound/api_config.dart';
import 'package:lostandfound/formfound.dart';
import 'package:lostandfound/formlost.dart';
import 'package:lostandfound/listlost.dart';
import 'package:lostandfound/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost and Found',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
    );
  }
}

class GreetingCardHeader extends StatelessWidget {
  final String userName;

  const GreetingCardHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xffEAF5F2),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xffD1E7E2), width: 1.5),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xff0D7A70),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2.0),
                const Text(
                  'User dapat membuat laporan barang lengkap dengan deskripsi.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaporanScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String role;

  const LaporanScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.role,
  });

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<Map<String, dynamic>> listLaporan = [];
  bool isLoading = true;

  int _currentIndex = 0;
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    fetchDataLaporan();
  }

  Future<void> fetchDataLaporan() async {
    final url = Uri.parse('$apiBaseUrl/view.php?role=${widget.role}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> reports = decoded is List
            ? decoded
            : decoded is Map<String, dynamic> && decoded['reports'] is List
            ? decoded['reports']
            : [];

        setState(() {
          listLaporan = reports
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openReportForm() async {
    final String reportType = isAdmin && _currentIndex == 1 ? 'found' : 'lost';
    final bool? isSaved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => reportType == 'lost'
            ? FormLostPage(userId: widget.userId)
            : FormFoundPage(userId: widget.userId),
      ),
    );

    if (isSaved == true) {
      fetchDataLaporan();
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildLostPage() {
    final lostData = listLaporan
        .where((item) => item['type'] == 'lost')
        .toList();
    return Column(
      children: [
        GreetingCardHeader(userName: widget.userName),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : lostData.isEmpty
              ? const Center(child: Text('Tidak ada laporan barang.'))
              : ListView.builder(
                  itemCount: lostData.length,
                  itemBuilder: (context, index) {
                    final item = lostData[index];
                    return ItemLaporanCard(data: item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFoundPage() {
    final foundData = listLaporan
        .where((item) => item['type'] == 'found')
        .toList();
    return Column(
      children: [
        GreetingCardHeader(userName: widget.userName),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : foundData.isEmpty
              ? const Center(child: Text('Tidak ada laporan barang.'))
              : ListView.builder(
                  itemCount: foundData.length,
                  itemBuilder: (context, index) {
                    final item = foundData[index];
                    return ItemLaporanCard(data: item);
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Laporan Barang Hilang'
              : 'Laporan Barang Ditemukan',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDataLaporan,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),

      body: _currentIndex == 0 ? _buildLostPage() : _buildFoundPage(),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Lapor',
        onPressed: !isAdmin && _currentIndex == 1 ? null : _openReportForm,
        backgroundColor: !isAdmin && _currentIndex == 1
            ? Colors.grey
            : const Color(0xff0D7A70),
        shape: const CircleBorder(),
        child: const Icon(Icons.edit_note, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        color: _currentIndex == 0
                            ? const Color(0xff0D7A70)
                            : Colors.grey,
                      ),
                      Text(
                        'Lost',
                        style: TextStyle(
                          color: _currentIndex == 0
                              ? const Color(0xff0D7A70)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 40),

              Expanded(
                child: MaterialButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: _currentIndex == 1
                            ? const Color(0xff0D7A70)
                            : Colors.grey,
                      ),
                      Text(
                        'Found',
                        style: TextStyle(
                          color: _currentIndex == 1
                              ? const Color(0xff0D7A70)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
