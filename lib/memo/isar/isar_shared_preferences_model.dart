// lib/storage/isar_preferences_model.dart
import 'package:isar_community/isar.dart';

part 'isar_shared_preferences_model.g.dart';

@Collection()
class IsarPreference {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
  late int? intValue;
  late double? doubleValue;
  late bool? boolValue;
  late List<String>? stringListValue;
  late int timestamp;

  IsarPreference({
    required this.key,
    required this.value,
    this.intValue,
    this.doubleValue,
    this.boolValue,
    this.stringListValue,
    required this.timestamp,
  });
}
