import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/core/utils/uuid.dart';
import 'package:gitartha/data/local/database/converters.dart';

void main() {
  group('UtcTimestampConverter', () {
    const converter = UtcTimestampConverter();

    test('writes fixed-width UTC ISO 8601 with microseconds', () {
      expect(
        converter.toSql(DateTime.utc(2026, 11, 23, 9, 12)),
        '2026-11-23T09:12:00.000000Z',
      );
      expect(
        converter.toSql(DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7)),
        '2026-01-02T03:04:05.006007Z',
      );
    });

    test('converts local times to UTC before writing', () {
      final local = DateTime(2026, 6, 1, 12);
      expect(converter.toSql(local), converter.toSql(local.toUtc()));
    });

    test('reads back UTC, including Supabase-style offsets', () {
      final parsed = converter.fromSql('2026-11-23T09:12:00.123456Z');
      expect(parsed.isUtc, isTrue);
      expect(parsed, DateTime.utc(2026, 11, 23, 9, 12, 0, 123, 456));
      expect(
        converter.fromSql('2026-11-23T14:42:00.5+05:30'),
        DateTime.utc(2026, 11, 23, 9, 12, 0, 500),
      );
    });

    test('text order equals chronological order', () {
      final times = [
        DateTime.utc(2026, 1, 1, 0, 0, 0, 123),
        DateTime.utc(2026, 1, 1, 0, 0, 0, 123, 456),
        DateTime.utc(2026, 1, 1, 0, 0, 1),
        DateTime.utc(2025, 12, 31, 23, 59, 59, 999, 999),
      ];
      final byText = [...times]
        ..sort((a, b) => converter.toSql(a).compareTo(converter.toSql(b)));
      expect(byText, [...times]..sort());
    });
  });

  test('StringListConverter round-trips JSON arrays', () {
    const converter = StringListConverter();
    const topics = ['Duty', 'धर्म', 'with "quotes"'];
    expect(converter.fromSql(converter.toSql(topics)), topics);
    expect(() => converter.fromSql('{}'), throwsFormatException);
  });

  test('generateUuidV4 produces unique canonical v4 UUIDs', () {
    final ids = {for (var i = 0; i < 2000; i++) generateUuidV4()};
    expect(ids, hasLength(2000));
    for (final id in ids.take(50)) {
      expect(isCanonicalUuid(id), isTrue, reason: id);
      expect(id[14], '4');
      expect('89ab', contains(id[19]));
    }
  });
}
