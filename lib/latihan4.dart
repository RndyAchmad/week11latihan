import 'package:flutter/material.dart'; // Mengimpor pustaka Material Design dari Flutter.
import 'package:http/http.dart' as http; // Mengimpor pustaka http dan memberi alias 'http' untuk mengakses fungsi-fungsi HTTP.
import 'dart:convert'; // Mengimpor pustaka dart:convert untuk melakukan operasi konversi data (misalnya JSON parsing).
import 'package:provider/provider.dart'; // Mengimpor pustaka provider untuk manajemen state dalam aplikasi Flutter.

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => UniversityModel(), // Membuat instance dari UniversityModel yang akan digunakan sebagai state provider.
    child: MyApp(), // Menentukan widget MyApp sebagai child dari Provider.
  ),
);

class MyApp extends StatelessWidget { // Mendefinisikan kelas MyApp yang mengextend StatelessWidget.
  @override
  Widget build(BuildContext context) { // Method build untuk membangun UI.
    return MaterialApp(
      title: 'Universities in ASEAN', // Judul aplikasi.
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema utama aplikasi, dengan warna biru sebagai warna dasar.
      ),
      home: UniversityList(), // Widget utama yang ditampilkan di home adalah UniversityList.
    );
  }
}

class University { // Mendefinisikan kelas University untuk menyimpan data universitas.
  final String name; // Variabel final untuk menyimpan nama universitas.
  final String website; // Variabel final untuk menyimpan website universitas.

  University({required this.name, required this.website}); // Constructor dengan parameter nama dan website yang wajib diisi.

  factory University.fromJson(Map<String, dynamic> json) { // Factory constructor untuk membuat objek University dari JSON.
    return University(
      name: json['name'], // Mengambil nama dari JSON.
      website: json['web_pages'][0], // Mengambil website dari JSON, diasumsikan website ada di index 0.
    );
  }
}

class UniversityList extends StatelessWidget { // Mendefinisikan kelas UniversityList yang mengextend StatelessWidget.
  @override
  Widget build(BuildContext context) { // Method build untuk membangun UI.
    var universityModel = Provider.of<UniversityModel>(context); // Mengakses model UniversityModel dari provider.
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities in ${universityModel.currentCountry}'), // Judul AppBar menampilkan negara saat ini.
      ),
      body: Column(
        children: [
          DropdownButton<String>( // Dropdown untuk memilih negara.
            value: universityModel.currentCountry, // Nilai yang dipilih saat ini berdasarkan currentCountry.
            onChanged: (String? newValue) { // Fungsi yang dijalankan ketika item dropdown dipilih.
              if (newValue != null) {
                universityModel.setCountry(newValue); // Memperbarui negara yang dipilih.
              }
            },
            items: universityModel.countries // Membuat list item dropdown dari daftar negara yang tersedia.
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value, // Nilai dari item dropdown.
                child: Text(value), // Teks yang ditampilkan dari item dropdown.
              );
            }).toList(),
          ),
          Expanded(
            child: ListView.builder( // ListView untuk menampilkan daftar universitas.
              itemCount: universityModel.universities.length, // Jumlah item berdasarkan jumlah universitas yang ada.
              itemBuilder: (context, index) { // Membangun tampilan untuk setiap universitas.
                University uni = universityModel.universities[index]; // Mengakses universitas berdasarkan index.
                return ListTile(
                  title: Text(uni.name), // Menampilkan nama universitas.
                  subtitle: Text(uni.website), // Menampilkan website universitas.
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UniversityModel with ChangeNotifier { // Kelas model UniversityModel dengan ChangeNotifier untuk notifikasi ke UI.
  String currentCountry = 'Indonesia'; // Negara saat ini, default adalah Indonesia.
  List<University> universities = []; // Daftar untuk menyimpan universitas.
  final List<String> countries = [ // Daftar negara yang tersedia.
    'Indonesia', 'Malaysia', 'Singapore', 'Thailand', 'Philippines', 'Brunei', 'Vietnam', 'Laos', 'Myanmar', 'Cambodia'
  ];

  UniversityModel() { // Constructor dari UniversityModel.
    fetchUniversities(currentCountry); // Memanggil fungsi fetchUniversities saat pertama kali model dibuat.
  }

  void setCountry(String country) { // Fungsi untuk mengatur negara dan memanggil fungsi fetchUniversitas berdasarkan negara.
    currentCountry = country; // Mengatur negara saat ini.
    fetchUniversities(country); // Memanggil fungsi fetchUniversities.
  }

  Future<void> fetchUniversities(String country) async { // Fungsi untuk mengambil data universitas dari API berdasarkan negara.
    try {
      final response = await http.get( // Melakukan panggilan HTTP GET.
        Uri.parse('http://universities.hipolabs.com/search?country=$country')
      );

      if (response.statusCode == 200) { // Jika respons berhasil dengan status code 200.
        List<dynamic> universitiesJson = jsonDecode(response.body); // Dekode respons JSON.
        universities = universitiesJson.map((json) => University.fromJson(json)).toList(); // Mengubah JSON menjadi objek University.
      } else {
        universities = []; // Mengosongkan daftar universitas jika respons gagal.
        throw Exception('Failed to load universities with status code: ${response.statusCode}');
      }
    } catch (e) {
      universities = []; // Mengosongkan daftar universitas jika terjadi exception.
      print('Failed to load universities: $e'); // Mencetak pesan error.
    }
    notifyListeners(); // Memberitahu listeners tentang perubahan yang terjadi.
  }
}