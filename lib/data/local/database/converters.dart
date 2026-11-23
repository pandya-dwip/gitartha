import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a [DateTime] as a fixed-width UTC ISO 8601 string with microsecond
/// precision, e.g. `2026-11-23T09:12:00.123456Z`.
///
/// Why not Drift's built-in DateTime column:
///  * every timestamp in the database uses one exact format, so plain text
///    comparison and `ORDER BY` give chronological order;
///  * microsecond precision preserves Supabase `timestamptz` values exactly,
///    which the future sync milestone uses as cursors;
///  * values are always UTC on disk. Convert to local time only for display.
///
/// Values read back are UTC [DateTime]s.
class UtcTimestampConverter extends TypeConverter<DateTime, String> {
  const UtcTimestampConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toUtc();

  @override
  String toSql(DateTime value) => formatUtcTimestamp(value);
}

/// Formats [value] (converted to UTC) the way the database stores it.
String formatUtcTimestamp(DateTime value) {
  final utc = value.toUtc();
  if (utc.year < 0 || utc.year > 9999) {
    throw ArgumentError.value(value, 'value', 'year must be 0000-9999');
  }
  String two(int n) => n.toString().padLeft(2, '0');
  final micros = (utc.millisecond * 1000 + utc.microsecond).toString().padLeft(
    6,
    '0',
  );
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:'
      '${two(utc.second)}.${micros}Z';
}

/// Stores a list of strings as a JSON array (`["Duty","Grief"]`).
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      throw FormatException('Expected a JSON array, found: $fromDb');
    }
    return List<String>.unmodifiable(decoded.cast<String>());
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// An enum that is persisted using an explicit, stable text value.
///
/// The stored values must never change once released. Rename the Dart
/// identifier freely, but keep [sqlValue].
abstract interface class SqlEnum implements Enum {
  String get sqlValue;
}

/// Stores a [SqlEnum] as its [SqlEnum.sqlValue].
class SqlEnumConverter<T extends SqlEnum> extends TypeConverter<T, String> {
  const SqlEnumConverter(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) => values.firstWhere(
    (v) => v.sqlValue == fromDb,
    orElse: () => throw FormatException('Unknown $T value "$fromDb"'),
  );

  @override
  String toSql(T value) => value.sqlValue;
}
