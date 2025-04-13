import 'package:isar/isar.dart';

part 'saved_model.g.dart';

@Collection()
class SavedCity{
  Id id = Isar.autoIncrement;

  late String cityName;
}