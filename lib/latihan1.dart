import 'package:flutter/material.dart'; // Mengimpor pustaka Material yang menyediakan widget dan alat UI.
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor pustaka Bloc untuk manajemen state.
import 'package:http/http.dart' as http; // Mengimpor pustaka http untuk membuat permintaan jaringan, dengan alias 'http'.
import 'dart:convert'; // Mengimpor pustaka Dart untuk melakukan encoding dan decoding JSON.

// Model
class University { // Mendefinisikan kelas model 'University'.
  final String name; // Properti 'name' untuk menyimpan nama universitas.
  final String website; // Properti 'website' untuk menyimpan URL website universitas.
  University({required this.name, required this.website}); // Konstruktor dengan parameter 'name' dan 'website' yang dibutuhkan.

  factory University.fromJson(Map<String, dynamic> json) { // Factory constructor untuk membuat instance 'University' dari data JSON.
    return University(
      name: json['name'], // Mengambil nilai 'name' dari JSON.
      website: json['web_pages'][0], // Mengambil URL pertama dari array 'web_pages' di JSON.
    );
  }
}

// Cubit State
abstract class UniversityState {} // Kelas abstrak dasar untuk state universitas.
class UniversityInitial extends UniversityState {} // State awal, belum ada data yang dimuat.
class UniversityLoading extends UniversityState {} // State ketika data sedang dimuat.
class UniversityLoaded extends UniversityState { // State ketika data berhasil dimuat.
  final List<University> universities; // Daftar universitas yang dimuat.
  UniversityLoaded(this.universities); // Konstruktor untuk memasukkan data universitas.
}
class UniversityError extends UniversityState { // State ketika terjadi error saat memuat data.
  final String message; // Pesan error.
  UniversityError(this.message); // Konstruktor untuk pesan error.
}

// Cubit
class UniversityCubit extends Cubit<UniversityState> { // Kelas Cubit untuk manajemen state 'University'.
  UniversityCubit() : super(UniversityInitial()); // Inisialisasi state awal dengan 'UniversityInitial'.

  Future<void> fetchUniversities(String country) async { // Fungsi asinkron untuk memuat data universitas berdasarkan negara.
    emit(UniversityLoading()); // Mengubah state ke 'UniversityLoading'.
    try {
      final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$country')); // Membuat permintaan HTTP.
      if (response.statusCode == 200) { // Cek jika response sukses.
        final List<dynamic> universitiesJson = jsonDecode(response.body); // Decode response JSON menjadi list.
        final universities = universitiesJson.map((json) => University.fromJson(json)).toList(); // Konversi list JSON ke list objek 'University'.
        emit(UniversityLoaded(universities)); // Mengubah state ke 'UniversityLoaded' dengan data universitas.
      } else {
        emit(UniversityError("Failed to load universities")); // Mengubah state ke 'UniversityError' jika response tidak sukses.
      }
    } catch (e) {
      emit(UniversityError(e.toString())); // Mengubah state ke 'UniversityError' jika terjadi exception.
    }
  }
}

// App
void main() => runApp(MyApp()); // Fungsi utama yang menjalankan aplikasi.

class MyApp extends StatelessWidget { // Kelas 'MyApp' yang membangun aplikasi.
  @override
  Widget build(BuildContext context) { // Fungsi build untuk mengonstruksi UI.
    return MaterialApp(
      title: 'Universities by Country', // Judul aplikasi.
      theme: ThemeData(primarySwatch: Colors.blue), // Tema aplikasi dengan warna primer biru.
      home: BlocProvider( // Menggunakan BlocProvider untuk menyediakan instance 'UniversityCubit' ke tree widget.
        create: (context) => UniversityCubit(), // Membuat instance 'UniversityCubit'.
        child: UniversityList(), // Widget anak yang menggunakan data dari 'UniversityCubit'.
      ),
    );
  }
}

// UI
class UniversityList extends StatelessWidget { // Kelas widget untuk menampilkan daftar universitas.
  @override
  Widget build(BuildContext context) { // Fungsi build untuk mengonstruksi UI.
    return Scaffold(
      appBar: AppBar(title: Text('Universities by Country')), // AppBar dengan judul.
      body: Column( // Layout berupa kolom.
        children: <Widget>[
          DropdownButton<String>( // Dropdown untuk memilih negara.
            items: <String>['Indonesia', 'Malaysia', 'Singapore', 'Thailand', 'Philippines'] // Item dropdown berupa daftar negara.
                .map<DropdownMenuItem<String>>((String value) { // Membuat setiap item menjadi DropdownMenuItem.
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value), // Teks item adalah nama negara.
              );
            }).toList(),
            onChanged: (String? newValue) { // Fungsi yang dipanggil ketika item dipilih.
              context.read<UniversityCubit>().fetchUniversities(newValue!); // Memanggil fungsi untuk memuat data universitas berdasarkan negara yang dipilih.
            },
          ),
          Expanded( // Area yang diperluas untuk menampilkan daftar universitas.
            child: BlocBuilder<UniversityCubit, UniversityState>( // BlocBuilder untuk membangun UI berdasarkan state 'UniversityCubit'.
              builder: (context, state) { // Fungsi builder yang membangun UI berdasarkan state.
                if (state is UniversityLoading) { // Jika state loading, tampilkan indikator loading.
                  return Center(child: CircularProgressIndicator());
                } else if (state is UniversityLoaded) { // Jika state loaded, tampilkan daftar universitas.
                  return ListView.separated( // ListView dengan pemisah.
                    itemCount: state.universities.length, // Jumlah item adalah jumlah universitas.
                    separatorBuilder: (_, __) => Divider(height: 1), // Pembuat pemisah adalah Divider.
                    itemBuilder: (context, index) { // Pembuat item.
                      return ListTile( // ListTile untuk setiap universitas.
                        title: Text(state.universities[index].name), // Judul adalah nama universitas.
                        subtitle: Text(state.universities[index].website), // Subtitle adalah website universitas.
                      );
                    },
                  );
                } else if (state is UniversityError) { // Jika state error, tampilkan pesan error.
                  return Center(child: Text("Error: ${state.message}"));
                }
                return Center(child: Text('Please select a country')); // Pesan default jika belum ada negara yang dipilih.
              },
            ),
          ),
        ],
      ),
    );
  }
}
