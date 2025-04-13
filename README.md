# weather_app_w_isar_database

Database akan digunakan untuk menyimpan kota-kota yang ingin disimpan.

Nama : Andrian
NRP : 5025211079

## Tahapan Pemrograman
### Inisialiasasi dan Setup Isar Database
Menambahkan dependencies yang dibutuhkan untuk menggunakan Isar Database
```yaml
dependencies:
  isar: ^3.1.0
  path_provider: ^2.1.0

dev_dependencies:
  build_runner: ^2.4.6
  isar_generator: ^3.1.0
```

###  Mendefinisikan Model
Mendefinisikan model SavedCity yang digunakan untuk menyimpan nama kota secara lokal di Isar.

file: `saved_model.dart`
```dart
import 'package:isar/isar.dart';

part 'saved_model.g.dart';

@Collection()
class SavedCity {
  Id id = Isar.autoIncrement;
  late String cityName;
}
```
Model ini akan menyimpan satu kolom (cityName).

### Generate File Isar
Pastikan model diberi anotasi `@Collection` dan `part 'nama_file.g.dart'` dan jalankan command di bawah ini pada terminal.
```
flutter pub run build_runner build
```

### Inisialisasi Database
Setelah melakukan inisialisaisi model, berikutnya kita perlu membuat sebuah service dimana database akan diinisialisasi dan mengimplemntasi CRUD pada database.

File `database_service.dart`


#### Insialisasi Database
```dart
class DatabaseService {
  static late final Isar db;

  static Future<void> setup() async {
    final appDir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [SavedCitySchema], //Berdasarkan nama model + Schema
      directory: appDir.path,
    );
  }
}
```

Lalu `setup()` akan dipanggil sekali saat aplikasi dimulai.

File: `main.dart`
```dart
void main() async{
  await _setup(); // DATABASE DIPANGGIL
  runApp(const MyApp());
}
```

#### Operasi CRUD
1. CREATE (Tambah Kota)

Fungsi di `DatabaseService`:
```dart
Future<void> addCity(String name) async {
  final existing = await db.savedCitys
      .filter()
      .cityNameEqualTo(name)
      .findFirst();

  if (existing == null) {
    final city = SavedCity()..cityName = name;
    await db.writeTxn(() => db.savedCitys.put(city));
  }
}
```
Pemakaian pada `saved_city_page.dart`
```dart
Future<void> _addCity(String city) async {
  await widget.dbService.addCity(city);
  await _loadCitites(); // Refresh daftar kota
}
```
Dipanggil saat pengguna menambahkan kota dari `SearchPage`:
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    String? newCity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );
    if (newCity != null && newCity.isNotEmpty) {
      _addCity(newCity); // PENAMBAHAN MODEL KE DATABASE
    }
  },
  child: Icon(Icons.search),
),
```
2. READ (Ambil Semua Kota)
Fungsi di `DatabaseService`:
```dart
Future<List<SavedCity>> getAllCities() async {
  return await db.savedCitys.where().findAll();
}
```
Pemakaian pada `saved_city_page.dart`
```dart
Future<void> _loadCitites() async {
  final cities = await widget.dbService.getAllCities();
  setState(() {
    savedCities = cities.map((e) => e.cityName).toList();
  });

  // Fetch cuaca masing-masing kota
  for (var city in savedCities) {
    await _fetchWeather(city);
  }
}

```
Dipanggil di initState() saat halaman pertama kali dimuat:
```dart
@override
void initState() {
  super.initState();
  _loadCitites();
}
```

3. UPDATE (Edit Nama Kota)
Fungsi di `DatabaseService`:
```dart
Future<void> editCity(String oldName, String newName) async {
  final city = await db.savedCitys
      .filter()
      .cityNameEqualTo(oldName)
      .findFirst();

  if (city != null) {
    city.cityName = newName;
    await db.writeTxn(() => db.savedCitys.put(city));
  }
}

```
Pemakaian pada `saved_city_page.dart`
```dart
Future<void> _editCity(int index) async {
  String oldCity = savedCities[index];
  TextEditingController cityController = TextEditingController(text: oldCity);

  String? newCity = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit City"),
        content: TextField(
          controller: cityController,
          decoration: InputDecoration(
            labelText: "Enter new city name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, cityController.text),
            child: Text("Save"),
          ),
        ],
      );
    },
  );

  if (newCity != null && newCity.isNotEmpty && newCity != oldCity) {
    await widget.dbService.editCity(oldCity, newCity);
    setState(() {
      weatherData.remove(oldCity); // Hapus data cuaca lama
    });
    await _loadCitites(); // Refresh UI
  }
}
```
Dipanggil saat tombol edit ditekan::
```dart
IconButton(
  icon: Icon(Icons.edit, color: Colors.blue),
  onPressed: () => _editCity(index),
),
```

3. DELETE (Hapus Kota)
Fungsi di `DatabaseService`:
```dart
Future<void> deleteCity(String name) async {
  final city = await db.savedCitys
      .filter()
      .cityNameEqualTo(name)
      .findFirst();

  if (city != null) {
    await db.writeTxn(() => db.savedCitys.delete(city.id));
  }
}
```
Pemakaian pada `saved_city_page.dart`
```dart
Future<void> _deleteCity(int index) async {
  final city = savedCities[index];
  await widget.dbService.deleteCity(city);
  setState(() {
    savedCities.removeAt(index);  // Hapus dari list UI
    weatherData.remove(city);     // Hapus data cuaca
  });
}

```
Dipanggil saat tombol delete ditekan::
```dart
IconButton(
  icon: Icon(Icons.delete, color: Colors.red),
  onPressed: () => _deleteCity(index),
),
```

[![Watch the demo](https://img.youtube.com/vi/BCbd58SjgcI/0.jpg)](https://youtu.be/BCbd58SjgcI)






