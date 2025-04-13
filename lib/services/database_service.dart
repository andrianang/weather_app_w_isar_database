import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:weather_app/models/saved_model.dart';

class DatabaseService{

  static late final Isar db;

  static Future<void> setup() async{
    final appDir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [
        SavedCitySchema,
      ], 
      directory: appDir.path,
      );
  }

  Future<List<SavedCity>> getAllCities() async{
    final isar = db;
    return await isar.savedCitys.where().findAll();
  }

  Future<void> addCity(String name) async{
    final isar = db;
    final existing = await isar.savedCitys.filter().cityNameEqualTo(name).findFirst();

    if (existing == null){
      final city = SavedCity()..cityName=name;
      await isar.writeTxn(() => isar.savedCitys.put(city));
    }
  }

  Future <void> editCity(String oldName, String newName) async{
    final isar = db;
    final city = await isar.savedCitys.filter().cityNameEqualTo(oldName).findFirst();

    if (city != null){
      city.cityName = newName;
      await isar.writeTxn(() => isar.savedCitys.put(city));
    }
  }

  Future <void> deleteCity(String name) async{
    final isar = db;
    final city = await isar.savedCitys.filter().cityNameEqualTo(name).findFirst();

    if (city != null){
      await isar.writeTxn(() => isar.savedCitys.delete(city.id));
    }
  }
}