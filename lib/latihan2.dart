import 'package:flutter/material.dart'; // Mengimpor pustaka material design yang menyediakan widget dan alat UI.
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor pustaka flutter_bloc yang digunakan untuk manajemen state menggunakan BloC.
import 'package:http/http.dart' as http; // Mengimpor pustaka http untuk melakukan permintaan jaringan.
import 'dart:convert'; // Mengimpor pustaka dart:convert untuk mengkonversi data JSON.

// Model untuk data universitas
class University {
  final String name; // Nama universitas
  final String website; // URL website universitas
  University({required this.name, required this.website}); // Konstruktor yang menerima nama dan website
  factory University.fromJson(Map<String, dynamic> json) { // Konstruktor pabrik untuk membuat objek dari JSON
    return University(
      name: json['name'], // Mengambil nama dari JSON
      website: json['web_pages'][0], // Mengambil URL website dari JSON
    );
  }
}

// Base class untuk event BloC
abstract class UniversityEvent {}
class FetchUniversitiesByCountry extends UniversityEvent { // Event untuk meminta data universitas berdasarkan negara
  final String country; // Negara target
  FetchUniversitiesByCountry(this.country); // Konstruktor yang menerima negara
}

// State untuk BloC yang mengatur data universitas
class UniversityState {
  final List<University> universities; // Daftar universitas
  final bool isLoading; // Status loading
  final String? error; // Pesan error jika ada
  UniversityState({this.universities = const [], this.isLoading = false, this.error}); // Konstruktor state
}

// BloC untuk mengelola state dan event terkait universitas
class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  UniversityBloc() : super(UniversityState()) { // Konstruktor yang inisialisasi state awal
    on<FetchUniversitiesByCountry>(_onFetchUniversities); // Handler untuk event FetchUniversitiesByCountry
  }
  void _onFetchUniversities(FetchUniversitiesByCountry event, Emitter<UniversityState> emit) async {
    emit(UniversityState(isLoading: true)); // Emit state loading
    try {
      final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=${event.country}')); // Request HTTP
      if (response.statusCode == 200) { // Jika request sukses
        List<dynamic> universitiesJson = jsonDecode(response.body); // Decode JSON dari response
        List<University> universities = universitiesJson.map((json) => University.fromJson(json)).toList(); // Transformasi JSON ke List of University
        emit(UniversityState(universities: universities)); // Emit state baru dengan list universitas
      } else {
        emit(UniversityState(error: "Failed to fetch data.")); // Emit state error jika request gagal
      }
    } catch (e) {
      emit(UniversityState(error: e.toString())); // Emit state error jika terjadi exception
    }
  }
}

void main() {
  runApp(MyApp()); // Fungsi main yang menjalankan aplikasi MyApp
}

class MyApp extends StatelessWidget { // Aplikasi utama
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Browser', // Judul aplikasi
      home: BlocProvider( // Menyediakan BloC ke subtree
        create: (context) => UniversityBloc(), // Membuat instance dari UniversityBloc
        child: UniversityList(), // Child widget yang menggunakan BloC
      ),
    );
  }
}

class UniversityList extends StatelessWidget { // Widget untuk menampilkan daftar universitas
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universitas di ASEAN'), // Judul app bar
      ),
      body: Column(
        children: [
          DropdownButton<String>( // Dropdown untuk memilih negara
            value: 'Indonesia',
            items: <String>['Indonesia', 'Malaysia', 'Singapore', 'Thailand', 'Philippines'] // Daftar negara
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) { // Callback saat nilai dropdown berubah
              context.read<UniversityBloc>().add(FetchUniversitiesByCountry(newValue!)); // Memanggil BloC untuk mengambil data baru
            },
          ),
          Expanded( // Memperluas widget untuk menempati sisa ruang
            child: BlocBuilder<UniversityBloc, UniversityState>( // Membangun UI berdasarkan state BloC
              builder: (context, state) {
                if (state.isLoading) { // Jika loading
                  return Center(child: CircularProgressIndicator()); // Tampilkan spinner
                }
                if (state.error != null) { // Jika terdapat error
                  return Center(child: Text("Error: ${state.error}")); // Tampilkan pesan error
                }
                return ListView.builder( // ListView untuk menampilkan daftar universitas
                  itemCount: state.universities.length, // Jumlah item
                  itemBuilder: (context, index) { // Builder untuk setiap item
                    return ListTile(
                      title: Text(state.universities[index].name), // Tampilkan nama universitas
                      subtitle: Text(state.universities[index].website), // Tampilkan website universitas
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
