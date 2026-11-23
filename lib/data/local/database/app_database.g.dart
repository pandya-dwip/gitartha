// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalChaptersTable extends LocalChapters
    with TableInfo<$LocalChaptersTable, LocalChapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => ComparableExpr(id).isBetweenValues(1, 18),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sanskritNameMeta = const VerificationMeta(
    'sanskritName',
  );
  @override
  late final GeneratedColumn<String> sanskritName = GeneratedColumn<String>(
    'sanskrit_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hindiNameMeta = const VerificationMeta(
    'hindiName',
  );
  @override
  late final GeneratedColumn<String> hindiName = GeneratedColumn<String>(
    'hindi_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishNameMeta = const VerificationMeta(
    'englishName',
  );
  @override
  late final GeneratedColumn<String> englishName = GeneratedColumn<String>(
    'english_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _introductionMeta = const VerificationMeta(
    'introduction',
  );
  @override
  late final GeneratedColumn<String> introduction = GeneratedColumn<String>(
    'introduction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _centralThemeMeta = const VerificationMeta(
    'centralTheme',
  );
  @override
  late final GeneratedColumn<String> centralTheme = GeneratedColumn<String>(
    'central_theme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> keyTopics =
      GeneratedColumn<String>(
        'key_topics',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<String>?>($LocalChaptersTable.$converterkeyTopicsn);
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conclusionMeta = const VerificationMeta(
    'conclusion',
  );
  @override
  late final GeneratedColumn<String> conclusion = GeneratedColumn<String>(
    'conclusion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LocalChaptersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LocalChaptersTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($LocalChaptersTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sanskritName,
    hindiName,
    englishName,
    introduction,
    overview,
    centralTheme,
    keyTopics,
    summary,
    conclusion,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalChapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sanskrit_name')) {
      context.handle(
        _sanskritNameMeta,
        sanskritName.isAcceptableOrUnknown(
          data['sanskrit_name']!,
          _sanskritNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sanskritNameMeta);
    }
    if (data.containsKey('hindi_name')) {
      context.handle(
        _hindiNameMeta,
        hindiName.isAcceptableOrUnknown(data['hindi_name']!, _hindiNameMeta),
      );
    } else if (isInserting) {
      context.missing(_hindiNameMeta);
    }
    if (data.containsKey('english_name')) {
      context.handle(
        _englishNameMeta,
        englishName.isAcceptableOrUnknown(
          data['english_name']!,
          _englishNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishNameMeta);
    }
    if (data.containsKey('introduction')) {
      context.handle(
        _introductionMeta,
        introduction.isAcceptableOrUnknown(
          data['introduction']!,
          _introductionMeta,
        ),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('central_theme')) {
      context.handle(
        _centralThemeMeta,
        centralTheme.isAcceptableOrUnknown(
          data['central_theme']!,
          _centralThemeMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('conclusion')) {
      context.handle(
        _conclusionMeta,
        conclusion.isAcceptableOrUnknown(data['conclusion']!, _conclusionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalChapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sanskritName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sanskrit_name'],
      )!,
      hindiName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hindi_name'],
      )!,
      englishName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_name'],
      )!,
      introduction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}introduction'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      centralTheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}central_theme'],
      ),
      keyTopics: $LocalChaptersTable.$converterkeyTopicsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}key_topics'],
        ),
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      conclusion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conclusion'],
      ),
      createdAt: $LocalChaptersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $LocalChaptersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $LocalChaptersTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $LocalChaptersTable createAlias(String alias) {
    return $LocalChaptersTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterkeyTopics =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $converterkeyTopicsn =
      NullAwareTypeConverter.wrap($converterkeyTopics);
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterdeletedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime?, String?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
  @override
  bool get isStrict => true;
}

class LocalChapter extends DataClass implements Insertable<LocalChapter> {
  final int id;
  final String sanskritName;
  final String hindiName;
  final String englishName;
  final String? introduction;
  final String? overview;
  final String? centralTheme;

  /// JSON array of strings, e.g. `["Duty","Grief"]`.
  final List<String>? keyTopics;
  final String? summary;
  final String? conclusion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const LocalChapter({
    required this.id,
    required this.sanskritName,
    required this.hindiName,
    required this.englishName,
    this.introduction,
    this.overview,
    this.centralTheme,
    this.keyTopics,
    this.summary,
    this.conclusion,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sanskrit_name'] = Variable<String>(sanskritName);
    map['hindi_name'] = Variable<String>(hindiName);
    map['english_name'] = Variable<String>(englishName);
    if (!nullToAbsent || introduction != null) {
      map['introduction'] = Variable<String>(introduction);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || centralTheme != null) {
      map['central_theme'] = Variable<String>(centralTheme);
    }
    if (!nullToAbsent || keyTopics != null) {
      map['key_topics'] = Variable<String>(
        $LocalChaptersTable.$converterkeyTopicsn.toSql(keyTopics),
      );
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || conclusion != null) {
      map['conclusion'] = Variable<String>(conclusion);
    }
    {
      map['created_at'] = Variable<String>(
        $LocalChaptersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $LocalChaptersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $LocalChaptersTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  LocalChaptersCompanion toCompanion(bool nullToAbsent) {
    return LocalChaptersCompanion(
      id: Value(id),
      sanskritName: Value(sanskritName),
      hindiName: Value(hindiName),
      englishName: Value(englishName),
      introduction: introduction == null && nullToAbsent
          ? const Value.absent()
          : Value(introduction),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      centralTheme: centralTheme == null && nullToAbsent
          ? const Value.absent()
          : Value(centralTheme),
      keyTopics: keyTopics == null && nullToAbsent
          ? const Value.absent()
          : Value(keyTopics),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      conclusion: conclusion == null && nullToAbsent
          ? const Value.absent()
          : Value(conclusion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalChapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChapter(
      id: serializer.fromJson<int>(json['id']),
      sanskritName: serializer.fromJson<String>(json['sanskritName']),
      hindiName: serializer.fromJson<String>(json['hindiName']),
      englishName: serializer.fromJson<String>(json['englishName']),
      introduction: serializer.fromJson<String?>(json['introduction']),
      overview: serializer.fromJson<String?>(json['overview']),
      centralTheme: serializer.fromJson<String?>(json['centralTheme']),
      keyTopics: serializer.fromJson<List<String>?>(json['keyTopics']),
      summary: serializer.fromJson<String?>(json['summary']),
      conclusion: serializer.fromJson<String?>(json['conclusion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sanskritName': serializer.toJson<String>(sanskritName),
      'hindiName': serializer.toJson<String>(hindiName),
      'englishName': serializer.toJson<String>(englishName),
      'introduction': serializer.toJson<String?>(introduction),
      'overview': serializer.toJson<String?>(overview),
      'centralTheme': serializer.toJson<String?>(centralTheme),
      'keyTopics': serializer.toJson<List<String>?>(keyTopics),
      'summary': serializer.toJson<String?>(summary),
      'conclusion': serializer.toJson<String?>(conclusion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalChapter copyWith({
    int? id,
    String? sanskritName,
    String? hindiName,
    String? englishName,
    Value<String?> introduction = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> centralTheme = const Value.absent(),
    Value<List<String>?> keyTopics = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<String?> conclusion = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalChapter(
    id: id ?? this.id,
    sanskritName: sanskritName ?? this.sanskritName,
    hindiName: hindiName ?? this.hindiName,
    englishName: englishName ?? this.englishName,
    introduction: introduction.present ? introduction.value : this.introduction,
    overview: overview.present ? overview.value : this.overview,
    centralTheme: centralTheme.present ? centralTheme.value : this.centralTheme,
    keyTopics: keyTopics.present ? keyTopics.value : this.keyTopics,
    summary: summary.present ? summary.value : this.summary,
    conclusion: conclusion.present ? conclusion.value : this.conclusion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalChapter copyWithCompanion(LocalChaptersCompanion data) {
    return LocalChapter(
      id: data.id.present ? data.id.value : this.id,
      sanskritName: data.sanskritName.present
          ? data.sanskritName.value
          : this.sanskritName,
      hindiName: data.hindiName.present ? data.hindiName.value : this.hindiName,
      englishName: data.englishName.present
          ? data.englishName.value
          : this.englishName,
      introduction: data.introduction.present
          ? data.introduction.value
          : this.introduction,
      overview: data.overview.present ? data.overview.value : this.overview,
      centralTheme: data.centralTheme.present
          ? data.centralTheme.value
          : this.centralTheme,
      keyTopics: data.keyTopics.present ? data.keyTopics.value : this.keyTopics,
      summary: data.summary.present ? data.summary.value : this.summary,
      conclusion: data.conclusion.present
          ? data.conclusion.value
          : this.conclusion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChapter(')
          ..write('id: $id, ')
          ..write('sanskritName: $sanskritName, ')
          ..write('hindiName: $hindiName, ')
          ..write('englishName: $englishName, ')
          ..write('introduction: $introduction, ')
          ..write('overview: $overview, ')
          ..write('centralTheme: $centralTheme, ')
          ..write('keyTopics: $keyTopics, ')
          ..write('summary: $summary, ')
          ..write('conclusion: $conclusion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sanskritName,
    hindiName,
    englishName,
    introduction,
    overview,
    centralTheme,
    keyTopics,
    summary,
    conclusion,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChapter &&
          other.id == this.id &&
          other.sanskritName == this.sanskritName &&
          other.hindiName == this.hindiName &&
          other.englishName == this.englishName &&
          other.introduction == this.introduction &&
          other.overview == this.overview &&
          other.centralTheme == this.centralTheme &&
          other.keyTopics == this.keyTopics &&
          other.summary == this.summary &&
          other.conclusion == this.conclusion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalChaptersCompanion extends UpdateCompanion<LocalChapter> {
  final Value<int> id;
  final Value<String> sanskritName;
  final Value<String> hindiName;
  final Value<String> englishName;
  final Value<String?> introduction;
  final Value<String?> overview;
  final Value<String?> centralTheme;
  final Value<List<String>?> keyTopics;
  final Value<String?> summary;
  final Value<String?> conclusion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const LocalChaptersCompanion({
    this.id = const Value.absent(),
    this.sanskritName = const Value.absent(),
    this.hindiName = const Value.absent(),
    this.englishName = const Value.absent(),
    this.introduction = const Value.absent(),
    this.overview = const Value.absent(),
    this.centralTheme = const Value.absent(),
    this.keyTopics = const Value.absent(),
    this.summary = const Value.absent(),
    this.conclusion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  LocalChaptersCompanion.insert({
    this.id = const Value.absent(),
    required String sanskritName,
    required String hindiName,
    required String englishName,
    this.introduction = const Value.absent(),
    this.overview = const Value.absent(),
    this.centralTheme = const Value.absent(),
    this.keyTopics = const Value.absent(),
    this.summary = const Value.absent(),
    this.conclusion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  }) : sanskritName = Value(sanskritName),
       hindiName = Value(hindiName),
       englishName = Value(englishName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalChapter> custom({
    Expression<int>? id,
    Expression<String>? sanskritName,
    Expression<String>? hindiName,
    Expression<String>? englishName,
    Expression<String>? introduction,
    Expression<String>? overview,
    Expression<String>? centralTheme,
    Expression<String>? keyTopics,
    Expression<String>? summary,
    Expression<String>? conclusion,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sanskritName != null) 'sanskrit_name': sanskritName,
      if (hindiName != null) 'hindi_name': hindiName,
      if (englishName != null) 'english_name': englishName,
      if (introduction != null) 'introduction': introduction,
      if (overview != null) 'overview': overview,
      if (centralTheme != null) 'central_theme': centralTheme,
      if (keyTopics != null) 'key_topics': keyTopics,
      if (summary != null) 'summary': summary,
      if (conclusion != null) 'conclusion': conclusion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  LocalChaptersCompanion copyWith({
    Value<int>? id,
    Value<String>? sanskritName,
    Value<String>? hindiName,
    Value<String>? englishName,
    Value<String?>? introduction,
    Value<String?>? overview,
    Value<String?>? centralTheme,
    Value<List<String>?>? keyTopics,
    Value<String?>? summary,
    Value<String?>? conclusion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return LocalChaptersCompanion(
      id: id ?? this.id,
      sanskritName: sanskritName ?? this.sanskritName,
      hindiName: hindiName ?? this.hindiName,
      englishName: englishName ?? this.englishName,
      introduction: introduction ?? this.introduction,
      overview: overview ?? this.overview,
      centralTheme: centralTheme ?? this.centralTheme,
      keyTopics: keyTopics ?? this.keyTopics,
      summary: summary ?? this.summary,
      conclusion: conclusion ?? this.conclusion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sanskritName.present) {
      map['sanskrit_name'] = Variable<String>(sanskritName.value);
    }
    if (hindiName.present) {
      map['hindi_name'] = Variable<String>(hindiName.value);
    }
    if (englishName.present) {
      map['english_name'] = Variable<String>(englishName.value);
    }
    if (introduction.present) {
      map['introduction'] = Variable<String>(introduction.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (centralTheme.present) {
      map['central_theme'] = Variable<String>(centralTheme.value);
    }
    if (keyTopics.present) {
      map['key_topics'] = Variable<String>(
        $LocalChaptersTable.$converterkeyTopicsn.toSql(keyTopics.value),
      );
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (conclusion.present) {
      map['conclusion'] = Variable<String>(conclusion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $LocalChaptersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $LocalChaptersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $LocalChaptersTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChaptersCompanion(')
          ..write('id: $id, ')
          ..write('sanskritName: $sanskritName, ')
          ..write('hindiName: $hindiName, ')
          ..write('englishName: $englishName, ')
          ..write('introduction: $introduction, ')
          ..write('overview: $overview, ')
          ..write('centralTheme: $centralTheme, ')
          ..write('keyTopics: $keyTopics, ')
          ..write('summary: $summary, ')
          ..write('conclusion: $conclusion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalShlokasTable extends LocalShlokas
    with TableInfo<$LocalShlokasTable, LocalShloka> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShlokasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_chapters (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _verseNumberMeta = const VerificationMeta(
    'verseNumber',
  );
  @override
  late final GeneratedColumn<int> verseNumber = GeneratedColumn<int>(
    'verse_number',
    aliasedName,
    false,
    check: () => ComparableExpr(verseNumber).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexTitleMeta = const VerificationMeta(
    'indexTitle',
  );
  @override
  late final GeneratedColumn<String> indexTitle = GeneratedColumn<String>(
    'index_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexSummaryMeta = const VerificationMeta(
    'indexSummary',
  );
  @override
  late final GeneratedColumn<String> indexSummary = GeneratedColumn<String>(
    'index_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sanskritTextMeta = const VerificationMeta(
    'sanskritText',
  );
  @override
  late final GeneratedColumn<String> sanskritText = GeneratedColumn<String>(
    'sanskrit_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transliterationMeta = const VerificationMeta(
    'transliteration',
  );
  @override
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
    'transliteration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hindiMeaningMeta = const VerificationMeta(
    'hindiMeaning',
  );
  @override
  late final GeneratedColumn<String> hindiMeaning = GeneratedColumn<String>(
    'hindi_meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hindiMeaningNoteMeta = const VerificationMeta(
    'hindiMeaningNote',
  );
  @override
  late final GeneratedColumn<String> hindiMeaningNote = GeneratedColumn<String>(
    'hindi_meaning_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _englishMeaningMeta = const VerificationMeta(
    'englishMeaning',
  );
  @override
  late final GeneratedColumn<String> englishMeaning = GeneratedColumn<String>(
    'english_meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lifeLessonMeta = const VerificationMeta(
    'lifeLesson',
  );
  @override
  late final GeneratedColumn<String> lifeLesson = GeneratedColumn<String>(
    'life_lesson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spiritualMeaningMeta = const VerificationMeta(
    'spiritualMeaning',
  );
  @override
  late final GeneratedColumn<String> spiritualMeaning = GeneratedColumn<String>(
    'spiritual_meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reflectionQuestionMeta =
      const VerificationMeta('reflectionQuestion');
  @override
  late final GeneratedColumn<String> reflectionQuestion =
      GeneratedColumn<String>(
        'reflection_question',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LocalShlokasTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LocalShlokasTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($LocalShlokasTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    verseNumber,
    reference,
    indexTitle,
    indexSummary,
    sanskritText,
    transliteration,
    hindiMeaning,
    hindiMeaningNote,
    englishMeaning,
    context,
    lifeLesson,
    spiritualMeaning,
    reflectionQuestion,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shlokas';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShloka> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('verse_number')) {
      context.handle(
        _verseNumberMeta,
        verseNumber.isAcceptableOrUnknown(
          data['verse_number']!,
          _verseNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verseNumberMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('index_title')) {
      context.handle(
        _indexTitleMeta,
        indexTitle.isAcceptableOrUnknown(data['index_title']!, _indexTitleMeta),
      );
    }
    if (data.containsKey('index_summary')) {
      context.handle(
        _indexSummaryMeta,
        indexSummary.isAcceptableOrUnknown(
          data['index_summary']!,
          _indexSummaryMeta,
        ),
      );
    }
    if (data.containsKey('sanskrit_text')) {
      context.handle(
        _sanskritTextMeta,
        sanskritText.isAcceptableOrUnknown(
          data['sanskrit_text']!,
          _sanskritTextMeta,
        ),
      );
    }
    if (data.containsKey('transliteration')) {
      context.handle(
        _transliterationMeta,
        transliteration.isAcceptableOrUnknown(
          data['transliteration']!,
          _transliterationMeta,
        ),
      );
    }
    if (data.containsKey('hindi_meaning')) {
      context.handle(
        _hindiMeaningMeta,
        hindiMeaning.isAcceptableOrUnknown(
          data['hindi_meaning']!,
          _hindiMeaningMeta,
        ),
      );
    }
    if (data.containsKey('hindi_meaning_note')) {
      context.handle(
        _hindiMeaningNoteMeta,
        hindiMeaningNote.isAcceptableOrUnknown(
          data['hindi_meaning_note']!,
          _hindiMeaningNoteMeta,
        ),
      );
    }
    if (data.containsKey('english_meaning')) {
      context.handle(
        _englishMeaningMeta,
        englishMeaning.isAcceptableOrUnknown(
          data['english_meaning']!,
          _englishMeaningMeta,
        ),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('life_lesson')) {
      context.handle(
        _lifeLessonMeta,
        lifeLesson.isAcceptableOrUnknown(data['life_lesson']!, _lifeLessonMeta),
      );
    }
    if (data.containsKey('spiritual_meaning')) {
      context.handle(
        _spiritualMeaningMeta,
        spiritualMeaning.isAcceptableOrUnknown(
          data['spiritual_meaning']!,
          _spiritualMeaningMeta,
        ),
      );
    }
    if (data.containsKey('reflection_question')) {
      context.handle(
        _reflectionQuestionMeta,
        reflectionQuestion.isAcceptableOrUnknown(
          data['reflection_question']!,
          _reflectionQuestionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {chapterId, verseNumber},
  ];
  @override
  LocalShloka map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShloka(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      verseNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse_number'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      indexTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}index_title'],
      ),
      indexSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}index_summary'],
      ),
      sanskritText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sanskrit_text'],
      ),
      transliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transliteration'],
      ),
      hindiMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hindi_meaning'],
      ),
      hindiMeaningNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hindi_meaning_note'],
      ),
      englishMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_meaning'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      lifeLesson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}life_lesson'],
      ),
      spiritualMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spiritual_meaning'],
      ),
      reflectionQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection_question'],
      ),
      createdAt: $LocalShlokasTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $LocalShlokasTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $LocalShlokasTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $LocalShlokasTable createAlias(String alias) {
    return $LocalShlokasTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterdeletedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime?, String?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
  @override
  bool get isStrict => true;
}

class LocalShloka extends DataClass implements Insertable<LocalShloka> {
  final String id;
  final int chapterId;
  final int verseNumber;

  /// `"<chapter>.<verse>"`, e.g. `1.41`. A table CHECK keeps it consistent
  /// with [chapterId] and [verseNumber], like Supabase's generated column.
  final String reference;
  final String? indexTitle;
  final String? indexSummary;
  final String? sanskritText;
  final String? transliteration;
  final String? hindiMeaning;

  /// Optional note on the Hindi wording. Never merged into [hindiMeaning].
  final String? hindiMeaningNote;
  final String? englishMeaning;
  final String? context;
  final String? lifeLesson;
  final String? spiritualMeaning;
  final String? reflectionQuestion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const LocalShloka({
    required this.id,
    required this.chapterId,
    required this.verseNumber,
    required this.reference,
    this.indexTitle,
    this.indexSummary,
    this.sanskritText,
    this.transliteration,
    this.hindiMeaning,
    this.hindiMeaningNote,
    this.englishMeaning,
    this.context,
    this.lifeLesson,
    this.spiritualMeaning,
    this.reflectionQuestion,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['verse_number'] = Variable<int>(verseNumber);
    map['reference'] = Variable<String>(reference);
    if (!nullToAbsent || indexTitle != null) {
      map['index_title'] = Variable<String>(indexTitle);
    }
    if (!nullToAbsent || indexSummary != null) {
      map['index_summary'] = Variable<String>(indexSummary);
    }
    if (!nullToAbsent || sanskritText != null) {
      map['sanskrit_text'] = Variable<String>(sanskritText);
    }
    if (!nullToAbsent || transliteration != null) {
      map['transliteration'] = Variable<String>(transliteration);
    }
    if (!nullToAbsent || hindiMeaning != null) {
      map['hindi_meaning'] = Variable<String>(hindiMeaning);
    }
    if (!nullToAbsent || hindiMeaningNote != null) {
      map['hindi_meaning_note'] = Variable<String>(hindiMeaningNote);
    }
    if (!nullToAbsent || englishMeaning != null) {
      map['english_meaning'] = Variable<String>(englishMeaning);
    }
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || lifeLesson != null) {
      map['life_lesson'] = Variable<String>(lifeLesson);
    }
    if (!nullToAbsent || spiritualMeaning != null) {
      map['spiritual_meaning'] = Variable<String>(spiritualMeaning);
    }
    if (!nullToAbsent || reflectionQuestion != null) {
      map['reflection_question'] = Variable<String>(reflectionQuestion);
    }
    {
      map['created_at'] = Variable<String>(
        $LocalShlokasTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $LocalShlokasTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $LocalShlokasTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  LocalShlokasCompanion toCompanion(bool nullToAbsent) {
    return LocalShlokasCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      verseNumber: Value(verseNumber),
      reference: Value(reference),
      indexTitle: indexTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(indexTitle),
      indexSummary: indexSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(indexSummary),
      sanskritText: sanskritText == null && nullToAbsent
          ? const Value.absent()
          : Value(sanskritText),
      transliteration: transliteration == null && nullToAbsent
          ? const Value.absent()
          : Value(transliteration),
      hindiMeaning: hindiMeaning == null && nullToAbsent
          ? const Value.absent()
          : Value(hindiMeaning),
      hindiMeaningNote: hindiMeaningNote == null && nullToAbsent
          ? const Value.absent()
          : Value(hindiMeaningNote),
      englishMeaning: englishMeaning == null && nullToAbsent
          ? const Value.absent()
          : Value(englishMeaning),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      lifeLesson: lifeLesson == null && nullToAbsent
          ? const Value.absent()
          : Value(lifeLesson),
      spiritualMeaning: spiritualMeaning == null && nullToAbsent
          ? const Value.absent()
          : Value(spiritualMeaning),
      reflectionQuestion: reflectionQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(reflectionQuestion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalShloka.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShloka(
      id: serializer.fromJson<String>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      verseNumber: serializer.fromJson<int>(json['verseNumber']),
      reference: serializer.fromJson<String>(json['reference']),
      indexTitle: serializer.fromJson<String?>(json['indexTitle']),
      indexSummary: serializer.fromJson<String?>(json['indexSummary']),
      sanskritText: serializer.fromJson<String?>(json['sanskritText']),
      transliteration: serializer.fromJson<String?>(json['transliteration']),
      hindiMeaning: serializer.fromJson<String?>(json['hindiMeaning']),
      hindiMeaningNote: serializer.fromJson<String?>(json['hindiMeaningNote']),
      englishMeaning: serializer.fromJson<String?>(json['englishMeaning']),
      context: serializer.fromJson<String?>(json['context']),
      lifeLesson: serializer.fromJson<String?>(json['lifeLesson']),
      spiritualMeaning: serializer.fromJson<String?>(json['spiritualMeaning']),
      reflectionQuestion: serializer.fromJson<String?>(
        json['reflectionQuestion'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'verseNumber': serializer.toJson<int>(verseNumber),
      'reference': serializer.toJson<String>(reference),
      'indexTitle': serializer.toJson<String?>(indexTitle),
      'indexSummary': serializer.toJson<String?>(indexSummary),
      'sanskritText': serializer.toJson<String?>(sanskritText),
      'transliteration': serializer.toJson<String?>(transliteration),
      'hindiMeaning': serializer.toJson<String?>(hindiMeaning),
      'hindiMeaningNote': serializer.toJson<String?>(hindiMeaningNote),
      'englishMeaning': serializer.toJson<String?>(englishMeaning),
      'context': serializer.toJson<String?>(context),
      'lifeLesson': serializer.toJson<String?>(lifeLesson),
      'spiritualMeaning': serializer.toJson<String?>(spiritualMeaning),
      'reflectionQuestion': serializer.toJson<String?>(reflectionQuestion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalShloka copyWith({
    String? id,
    int? chapterId,
    int? verseNumber,
    String? reference,
    Value<String?> indexTitle = const Value.absent(),
    Value<String?> indexSummary = const Value.absent(),
    Value<String?> sanskritText = const Value.absent(),
    Value<String?> transliteration = const Value.absent(),
    Value<String?> hindiMeaning = const Value.absent(),
    Value<String?> hindiMeaningNote = const Value.absent(),
    Value<String?> englishMeaning = const Value.absent(),
    Value<String?> context = const Value.absent(),
    Value<String?> lifeLesson = const Value.absent(),
    Value<String?> spiritualMeaning = const Value.absent(),
    Value<String?> reflectionQuestion = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalShloka(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    verseNumber: verseNumber ?? this.verseNumber,
    reference: reference ?? this.reference,
    indexTitle: indexTitle.present ? indexTitle.value : this.indexTitle,
    indexSummary: indexSummary.present ? indexSummary.value : this.indexSummary,
    sanskritText: sanskritText.present ? sanskritText.value : this.sanskritText,
    transliteration: transliteration.present
        ? transliteration.value
        : this.transliteration,
    hindiMeaning: hindiMeaning.present ? hindiMeaning.value : this.hindiMeaning,
    hindiMeaningNote: hindiMeaningNote.present
        ? hindiMeaningNote.value
        : this.hindiMeaningNote,
    englishMeaning: englishMeaning.present
        ? englishMeaning.value
        : this.englishMeaning,
    context: context.present ? context.value : this.context,
    lifeLesson: lifeLesson.present ? lifeLesson.value : this.lifeLesson,
    spiritualMeaning: spiritualMeaning.present
        ? spiritualMeaning.value
        : this.spiritualMeaning,
    reflectionQuestion: reflectionQuestion.present
        ? reflectionQuestion.value
        : this.reflectionQuestion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalShloka copyWithCompanion(LocalShlokasCompanion data) {
    return LocalShloka(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      verseNumber: data.verseNumber.present
          ? data.verseNumber.value
          : this.verseNumber,
      reference: data.reference.present ? data.reference.value : this.reference,
      indexTitle: data.indexTitle.present
          ? data.indexTitle.value
          : this.indexTitle,
      indexSummary: data.indexSummary.present
          ? data.indexSummary.value
          : this.indexSummary,
      sanskritText: data.sanskritText.present
          ? data.sanskritText.value
          : this.sanskritText,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      hindiMeaning: data.hindiMeaning.present
          ? data.hindiMeaning.value
          : this.hindiMeaning,
      hindiMeaningNote: data.hindiMeaningNote.present
          ? data.hindiMeaningNote.value
          : this.hindiMeaningNote,
      englishMeaning: data.englishMeaning.present
          ? data.englishMeaning.value
          : this.englishMeaning,
      context: data.context.present ? data.context.value : this.context,
      lifeLesson: data.lifeLesson.present
          ? data.lifeLesson.value
          : this.lifeLesson,
      spiritualMeaning: data.spiritualMeaning.present
          ? data.spiritualMeaning.value
          : this.spiritualMeaning,
      reflectionQuestion: data.reflectionQuestion.present
          ? data.reflectionQuestion.value
          : this.reflectionQuestion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShloka(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('verseNumber: $verseNumber, ')
          ..write('reference: $reference, ')
          ..write('indexTitle: $indexTitle, ')
          ..write('indexSummary: $indexSummary, ')
          ..write('sanskritText: $sanskritText, ')
          ..write('transliteration: $transliteration, ')
          ..write('hindiMeaning: $hindiMeaning, ')
          ..write('hindiMeaningNote: $hindiMeaningNote, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('context: $context, ')
          ..write('lifeLesson: $lifeLesson, ')
          ..write('spiritualMeaning: $spiritualMeaning, ')
          ..write('reflectionQuestion: $reflectionQuestion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    verseNumber,
    reference,
    indexTitle,
    indexSummary,
    sanskritText,
    transliteration,
    hindiMeaning,
    hindiMeaningNote,
    englishMeaning,
    context,
    lifeLesson,
    spiritualMeaning,
    reflectionQuestion,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShloka &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.verseNumber == this.verseNumber &&
          other.reference == this.reference &&
          other.indexTitle == this.indexTitle &&
          other.indexSummary == this.indexSummary &&
          other.sanskritText == this.sanskritText &&
          other.transliteration == this.transliteration &&
          other.hindiMeaning == this.hindiMeaning &&
          other.hindiMeaningNote == this.hindiMeaningNote &&
          other.englishMeaning == this.englishMeaning &&
          other.context == this.context &&
          other.lifeLesson == this.lifeLesson &&
          other.spiritualMeaning == this.spiritualMeaning &&
          other.reflectionQuestion == this.reflectionQuestion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalShlokasCompanion extends UpdateCompanion<LocalShloka> {
  final Value<String> id;
  final Value<int> chapterId;
  final Value<int> verseNumber;
  final Value<String> reference;
  final Value<String?> indexTitle;
  final Value<String?> indexSummary;
  final Value<String?> sanskritText;
  final Value<String?> transliteration;
  final Value<String?> hindiMeaning;
  final Value<String?> hindiMeaningNote;
  final Value<String?> englishMeaning;
  final Value<String?> context;
  final Value<String?> lifeLesson;
  final Value<String?> spiritualMeaning;
  final Value<String?> reflectionQuestion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const LocalShlokasCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.verseNumber = const Value.absent(),
    this.reference = const Value.absent(),
    this.indexTitle = const Value.absent(),
    this.indexSummary = const Value.absent(),
    this.sanskritText = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.hindiMeaning = const Value.absent(),
    this.hindiMeaningNote = const Value.absent(),
    this.englishMeaning = const Value.absent(),
    this.context = const Value.absent(),
    this.lifeLesson = const Value.absent(),
    this.spiritualMeaning = const Value.absent(),
    this.reflectionQuestion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShlokasCompanion.insert({
    required String id,
    required int chapterId,
    required int verseNumber,
    required String reference,
    this.indexTitle = const Value.absent(),
    this.indexSummary = const Value.absent(),
    this.sanskritText = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.hindiMeaning = const Value.absent(),
    this.hindiMeaningNote = const Value.absent(),
    this.englishMeaning = const Value.absent(),
    this.context = const Value.absent(),
    this.lifeLesson = const Value.absent(),
    this.spiritualMeaning = const Value.absent(),
    this.reflectionQuestion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chapterId = Value(chapterId),
       verseNumber = Value(verseNumber),
       reference = Value(reference),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalShloka> custom({
    Expression<String>? id,
    Expression<int>? chapterId,
    Expression<int>? verseNumber,
    Expression<String>? reference,
    Expression<String>? indexTitle,
    Expression<String>? indexSummary,
    Expression<String>? sanskritText,
    Expression<String>? transliteration,
    Expression<String>? hindiMeaning,
    Expression<String>? hindiMeaningNote,
    Expression<String>? englishMeaning,
    Expression<String>? context,
    Expression<String>? lifeLesson,
    Expression<String>? spiritualMeaning,
    Expression<String>? reflectionQuestion,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (verseNumber != null) 'verse_number': verseNumber,
      if (reference != null) 'reference': reference,
      if (indexTitle != null) 'index_title': indexTitle,
      if (indexSummary != null) 'index_summary': indexSummary,
      if (sanskritText != null) 'sanskrit_text': sanskritText,
      if (transliteration != null) 'transliteration': transliteration,
      if (hindiMeaning != null) 'hindi_meaning': hindiMeaning,
      if (hindiMeaningNote != null) 'hindi_meaning_note': hindiMeaningNote,
      if (englishMeaning != null) 'english_meaning': englishMeaning,
      if (context != null) 'context': context,
      if (lifeLesson != null) 'life_lesson': lifeLesson,
      if (spiritualMeaning != null) 'spiritual_meaning': spiritualMeaning,
      if (reflectionQuestion != null) 'reflection_question': reflectionQuestion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShlokasCompanion copyWith({
    Value<String>? id,
    Value<int>? chapterId,
    Value<int>? verseNumber,
    Value<String>? reference,
    Value<String?>? indexTitle,
    Value<String?>? indexSummary,
    Value<String?>? sanskritText,
    Value<String?>? transliteration,
    Value<String?>? hindiMeaning,
    Value<String?>? hindiMeaningNote,
    Value<String?>? englishMeaning,
    Value<String?>? context,
    Value<String?>? lifeLesson,
    Value<String?>? spiritualMeaning,
    Value<String?>? reflectionQuestion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalShlokasCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      verseNumber: verseNumber ?? this.verseNumber,
      reference: reference ?? this.reference,
      indexTitle: indexTitle ?? this.indexTitle,
      indexSummary: indexSummary ?? this.indexSummary,
      sanskritText: sanskritText ?? this.sanskritText,
      transliteration: transliteration ?? this.transliteration,
      hindiMeaning: hindiMeaning ?? this.hindiMeaning,
      hindiMeaningNote: hindiMeaningNote ?? this.hindiMeaningNote,
      englishMeaning: englishMeaning ?? this.englishMeaning,
      context: context ?? this.context,
      lifeLesson: lifeLesson ?? this.lifeLesson,
      spiritualMeaning: spiritualMeaning ?? this.spiritualMeaning,
      reflectionQuestion: reflectionQuestion ?? this.reflectionQuestion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (verseNumber.present) {
      map['verse_number'] = Variable<int>(verseNumber.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (indexTitle.present) {
      map['index_title'] = Variable<String>(indexTitle.value);
    }
    if (indexSummary.present) {
      map['index_summary'] = Variable<String>(indexSummary.value);
    }
    if (sanskritText.present) {
      map['sanskrit_text'] = Variable<String>(sanskritText.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (hindiMeaning.present) {
      map['hindi_meaning'] = Variable<String>(hindiMeaning.value);
    }
    if (hindiMeaningNote.present) {
      map['hindi_meaning_note'] = Variable<String>(hindiMeaningNote.value);
    }
    if (englishMeaning.present) {
      map['english_meaning'] = Variable<String>(englishMeaning.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (lifeLesson.present) {
      map['life_lesson'] = Variable<String>(lifeLesson.value);
    }
    if (spiritualMeaning.present) {
      map['spiritual_meaning'] = Variable<String>(spiritualMeaning.value);
    }
    if (reflectionQuestion.present) {
      map['reflection_question'] = Variable<String>(reflectionQuestion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $LocalShlokasTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $LocalShlokasTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $LocalShlokasTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShlokasCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('verseNumber: $verseNumber, ')
          ..write('reference: $reference, ')
          ..write('indexTitle: $indexTitle, ')
          ..write('indexSummary: $indexSummary, ')
          ..write('sanskritText: $sanskritText, ')
          ..write('transliteration: $transliteration, ')
          ..write('hindiMeaning: $hindiMeaning, ')
          ..write('hindiMeaningNote: $hindiMeaningNote, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('context: $context, ')
          ..write('lifeLesson: $lifeLesson, ')
          ..write('spiritualMeaning: $spiritualMeaning, ')
          ..write('reflectionQuestion: $reflectionQuestion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionsTable extends Reflections
    with TableInfo<$ReflectionsTable, Reflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shlokaIdMeta = const VerificationMeta(
    'shlokaId',
  );
  @override
  late final GeneratedColumn<String> shlokaId = GeneratedColumn<String>(
    'shloka_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shlokas (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReflectionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReflectionsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shlokaId,
    answer,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shloka_id')) {
      context.handle(
        _shlokaIdMeta,
        shlokaId.isAcceptableOrUnknown(data['shloka_id']!, _shlokaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shlokaIdMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shlokaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shloka_id'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      createdAt: $ReflectionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ReflectionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReflectionsTable createAlias(String alias) {
    return $ReflectionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class Reflection extends DataClass implements Insertable<Reflection> {
  final String id;

  /// RESTRICT: cached scripture is never physically deleted, so this only
  /// ever blocks a mistake that would orphan or destroy personal data.
  final String shlokaId;
  final String answer;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Reflection({
    required this.id,
    required this.shlokaId,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shloka_id'] = Variable<String>(shlokaId);
    map['answer'] = Variable<String>(answer);
    {
      map['created_at'] = Variable<String>(
        $ReflectionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $ReflectionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionsCompanion(
      id: Value(id),
      shlokaId: Value(shlokaId),
      answer: Value(answer),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reflection(
      id: serializer.fromJson<String>(json['id']),
      shlokaId: serializer.fromJson<String>(json['shlokaId']),
      answer: serializer.fromJson<String>(json['answer']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shlokaId': serializer.toJson<String>(shlokaId),
      'answer': serializer.toJson<String>(answer),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Reflection copyWith({
    String? id,
    String? shlokaId,
    String? answer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Reflection(
    id: id ?? this.id,
    shlokaId: shlokaId ?? this.shlokaId,
    answer: answer ?? this.answer,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reflection copyWithCompanion(ReflectionsCompanion data) {
    return Reflection(
      id: data.id.present ? data.id.value : this.id,
      shlokaId: data.shlokaId.present ? data.shlokaId.value : this.shlokaId,
      answer: data.answer.present ? data.answer.value : this.answer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reflection(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('answer: $answer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shlokaId, answer, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reflection &&
          other.id == this.id &&
          other.shlokaId == this.shlokaId &&
          other.answer == this.answer &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReflectionsCompanion extends UpdateCompanion<Reflection> {
  final Value<String> id;
  final Value<String> shlokaId;
  final Value<String> answer;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReflectionsCompanion({
    this.id = const Value.absent(),
    this.shlokaId = const Value.absent(),
    this.answer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionsCompanion.insert({
    required String id,
    required String shlokaId,
    required String answer,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shlokaId = Value(shlokaId),
       answer = Value(answer),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reflection> custom({
    Expression<String>? id,
    Expression<String>? shlokaId,
    Expression<String>? answer,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shlokaId != null) 'shloka_id': shlokaId,
      if (answer != null) 'answer': answer,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? shlokaId,
    Value<String>? answer,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReflectionsCompanion(
      id: id ?? this.id,
      shlokaId: shlokaId ?? this.shlokaId,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shlokaId.present) {
      map['shloka_id'] = Variable<String>(shlokaId.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ReflectionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $ReflectionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('answer: $answer, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalNotesTable extends PersonalNotes
    with TableInfo<$PersonalNotesTable, PersonalNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shlokaIdMeta = const VerificationMeta(
    'shlokaId',
  );
  @override
  late final GeneratedColumn<String> shlokaId = GeneratedColumn<String>(
    'shloka_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shlokas (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PersonalNotesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PersonalNotesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shlokaId,
    title,
    content,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shloka_id')) {
      context.handle(
        _shlokaIdMeta,
        shlokaId.isAcceptableOrUnknown(data['shloka_id']!, _shlokaIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shlokaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shloka_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: $PersonalNotesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $PersonalNotesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $PersonalNotesTable createAlias(String alias) {
    return $PersonalNotesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class PersonalNote extends DataClass implements Insertable<PersonalNote> {
  final String id;
  final String? shlokaId;
  final String? title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PersonalNote({
    required this.id,
    this.shlokaId,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || shlokaId != null) {
      map['shloka_id'] = Variable<String>(shlokaId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    {
      map['created_at'] = Variable<String>(
        $PersonalNotesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $PersonalNotesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  PersonalNotesCompanion toCompanion(bool nullToAbsent) {
    return PersonalNotesCompanion(
      id: Value(id),
      shlokaId: shlokaId == null && nullToAbsent
          ? const Value.absent()
          : Value(shlokaId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PersonalNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalNote(
      id: serializer.fromJson<String>(json['id']),
      shlokaId: serializer.fromJson<String?>(json['shlokaId']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shlokaId': serializer.toJson<String?>(shlokaId),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PersonalNote copyWith({
    String? id,
    Value<String?> shlokaId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PersonalNote(
    id: id ?? this.id,
    shlokaId: shlokaId.present ? shlokaId.value : this.shlokaId,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PersonalNote copyWithCompanion(PersonalNotesCompanion data) {
    return PersonalNote(
      id: data.id.present ? data.id.value : this.id,
      shlokaId: data.shlokaId.present ? data.shlokaId.value : this.shlokaId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalNote(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shlokaId, title, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalNote &&
          other.id == this.id &&
          other.shlokaId == this.shlokaId &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PersonalNotesCompanion extends UpdateCompanion<PersonalNote> {
  final Value<String> id;
  final Value<String?> shlokaId;
  final Value<String?> title;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PersonalNotesCompanion({
    this.id = const Value.absent(),
    this.shlokaId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalNotesCompanion.insert({
    required String id,
    this.shlokaId = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PersonalNote> custom({
    Expression<String>? id,
    Expression<String>? shlokaId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shlokaId != null) 'shloka_id': shlokaId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalNotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? shlokaId,
    Value<String?>? title,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PersonalNotesCompanion(
      id: id ?? this.id,
      shlokaId: shlokaId ?? this.shlokaId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shlokaId.present) {
      map['shloka_id'] = Variable<String>(shlokaId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $PersonalNotesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $PersonalNotesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalNotesCompanion(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shlokaIdMeta = const VerificationMeta(
    'shlokaId',
  );
  @override
  late final GeneratedColumn<String> shlokaId = GeneratedColumn<String>(
    'shloka_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES local_shlokas (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BookmarksTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, shlokaId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shloka_id')) {
      context.handle(
        _shlokaIdMeta,
        shlokaId.isAcceptableOrUnknown(data['shloka_id']!, _shlokaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shlokaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shlokaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shloka_id'],
      )!,
      createdAt: $BookmarksTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String shlokaId;
  final DateTime createdAt;
  const Bookmark({
    required this.id,
    required this.shlokaId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shloka_id'] = Variable<String>(shlokaId);
    {
      map['created_at'] = Variable<String>(
        $BookmarksTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      shlokaId: Value(shlokaId),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      shlokaId: serializer.fromJson<String>(json['shlokaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shlokaId': serializer.toJson<String>(shlokaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({String? id, String? shlokaId, DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        shlokaId: shlokaId ?? this.shlokaId,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      shlokaId: data.shlokaId.present ? data.shlokaId.value : this.shlokaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shlokaId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.shlokaId == this.shlokaId &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> shlokaId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.shlokaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String shlokaId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shlokaId = Value(shlokaId),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? shlokaId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shlokaId != null) 'shloka_id': shlokaId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? shlokaId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      shlokaId: shlokaId ?? this.shlokaId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shlokaId.present) {
      map['shloka_id'] = Variable<String>(shlokaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $BookmarksTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shlokaIdMeta = const VerificationMeta(
    'shlokaId',
  );
  @override
  late final GeneratedColumn<String> shlokaId = GeneratedColumn<String>(
    'shloka_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES local_shlokas (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReadingStatus>($ReadingProgressTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> firstOpenedAt =
      GeneratedColumn<String>(
        'first_opened_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReadingProgressTable.$converterfirstOpenedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> lastOpenedAt =
      GeneratedColumn<String>(
        'last_opened_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReadingProgressTable.$converterlastOpenedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> studiedAt =
      GeneratedColumn<String>(
        'studied_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReadingProgressTable.$converterstudiedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> reflectedAt =
      GeneratedColumn<String>(
        'reflected_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReadingProgressTable.$converterreflectedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReadingProgressTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shlokaId,
    status,
    firstOpenedAt,
    lastOpenedAt,
    studiedAt,
    reflectedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shloka_id')) {
      context.handle(
        _shlokaIdMeta,
        shlokaId.isAcceptableOrUnknown(data['shloka_id']!, _shlokaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shlokaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shlokaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shloka_id'],
      )!,
      status: $ReadingProgressTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      firstOpenedAt: $ReadingProgressTable.$converterfirstOpenedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}first_opened_at'],
        )!,
      ),
      lastOpenedAt: $ReadingProgressTable.$converterlastOpenedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_opened_at'],
        )!,
      ),
      studiedAt: $ReadingProgressTable.$converterstudiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}studied_at'],
        ),
      ),
      reflectedAt: $ReadingProgressTable.$converterreflectedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reflected_at'],
        ),
      ),
      updatedAt: $ReadingProgressTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }

  static TypeConverter<ReadingStatus, String> $converterstatus =
      const SqlEnumConverter<ReadingStatus>(ReadingStatus.values);
  static TypeConverter<DateTime, String> $converterfirstOpenedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterlastOpenedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime, String> $converterstudiedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime?, String?> $converterstudiedAtn =
      NullAwareTypeConverter.wrap($converterstudiedAt);
  static TypeConverter<DateTime, String> $converterreflectedAt =
      const UtcTimestampConverter();
  static TypeConverter<DateTime?, String?> $converterreflectedAtn =
      NullAwareTypeConverter.wrap($converterreflectedAt);
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class ReadingProgressEntry extends DataClass
    implements Insertable<ReadingProgressEntry> {
  final String id;
  final String shlokaId;
  final ReadingStatus status;
  final DateTime firstOpenedAt;
  final DateTime lastOpenedAt;
  final DateTime? studiedAt;
  final DateTime? reflectedAt;
  final DateTime updatedAt;
  const ReadingProgressEntry({
    required this.id,
    required this.shlokaId,
    required this.status,
    required this.firstOpenedAt,
    required this.lastOpenedAt,
    this.studiedAt,
    this.reflectedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shloka_id'] = Variable<String>(shlokaId);
    {
      map['status'] = Variable<String>(
        $ReadingProgressTable.$converterstatus.toSql(status),
      );
    }
    {
      map['first_opened_at'] = Variable<String>(
        $ReadingProgressTable.$converterfirstOpenedAt.toSql(firstOpenedAt),
      );
    }
    {
      map['last_opened_at'] = Variable<String>(
        $ReadingProgressTable.$converterlastOpenedAt.toSql(lastOpenedAt),
      );
    }
    if (!nullToAbsent || studiedAt != null) {
      map['studied_at'] = Variable<String>(
        $ReadingProgressTable.$converterstudiedAtn.toSql(studiedAt),
      );
    }
    if (!nullToAbsent || reflectedAt != null) {
      map['reflected_at'] = Variable<String>(
        $ReadingProgressTable.$converterreflectedAtn.toSql(reflectedAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $ReadingProgressTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      id: Value(id),
      shlokaId: Value(shlokaId),
      status: Value(status),
      firstOpenedAt: Value(firstOpenedAt),
      lastOpenedAt: Value(lastOpenedAt),
      studiedAt: studiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(studiedAt),
      reflectedAt: reflectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reflectedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressEntry(
      id: serializer.fromJson<String>(json['id']),
      shlokaId: serializer.fromJson<String>(json['shlokaId']),
      status: serializer.fromJson<ReadingStatus>(json['status']),
      firstOpenedAt: serializer.fromJson<DateTime>(json['firstOpenedAt']),
      lastOpenedAt: serializer.fromJson<DateTime>(json['lastOpenedAt']),
      studiedAt: serializer.fromJson<DateTime?>(json['studiedAt']),
      reflectedAt: serializer.fromJson<DateTime?>(json['reflectedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shlokaId': serializer.toJson<String>(shlokaId),
      'status': serializer.toJson<ReadingStatus>(status),
      'firstOpenedAt': serializer.toJson<DateTime>(firstOpenedAt),
      'lastOpenedAt': serializer.toJson<DateTime>(lastOpenedAt),
      'studiedAt': serializer.toJson<DateTime?>(studiedAt),
      'reflectedAt': serializer.toJson<DateTime?>(reflectedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingProgressEntry copyWith({
    String? id,
    String? shlokaId,
    ReadingStatus? status,
    DateTime? firstOpenedAt,
    DateTime? lastOpenedAt,
    Value<DateTime?> studiedAt = const Value.absent(),
    Value<DateTime?> reflectedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => ReadingProgressEntry(
    id: id ?? this.id,
    shlokaId: shlokaId ?? this.shlokaId,
    status: status ?? this.status,
    firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    studiedAt: studiedAt.present ? studiedAt.value : this.studiedAt,
    reflectedAt: reflectedAt.present ? reflectedAt.value : this.reflectedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingProgressEntry copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressEntry(
      id: data.id.present ? data.id.value : this.id,
      shlokaId: data.shlokaId.present ? data.shlokaId.value : this.shlokaId,
      status: data.status.present ? data.status.value : this.status,
      firstOpenedAt: data.firstOpenedAt.present
          ? data.firstOpenedAt.value
          : this.firstOpenedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      studiedAt: data.studiedAt.present ? data.studiedAt.value : this.studiedAt,
      reflectedAt: data.reflectedAt.present
          ? data.reflectedAt.value
          : this.reflectedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressEntry(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('status: $status, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('studiedAt: $studiedAt, ')
          ..write('reflectedAt: $reflectedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shlokaId,
    status,
    firstOpenedAt,
    lastOpenedAt,
    studiedAt,
    reflectedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressEntry &&
          other.id == this.id &&
          other.shlokaId == this.shlokaId &&
          other.status == this.status &&
          other.firstOpenedAt == this.firstOpenedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.studiedAt == this.studiedAt &&
          other.reflectedAt == this.reflectedAt &&
          other.updatedAt == this.updatedAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressEntry> {
  final Value<String> id;
  final Value<String> shlokaId;
  final Value<ReadingStatus> status;
  final Value<DateTime> firstOpenedAt;
  final Value<DateTime> lastOpenedAt;
  final Value<DateTime?> studiedAt;
  final Value<DateTime?> reflectedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.id = const Value.absent(),
    this.shlokaId = const Value.absent(),
    this.status = const Value.absent(),
    this.firstOpenedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.studiedAt = const Value.absent(),
    this.reflectedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String id,
    required String shlokaId,
    required ReadingStatus status,
    required DateTime firstOpenedAt,
    required DateTime lastOpenedAt,
    this.studiedAt = const Value.absent(),
    this.reflectedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shlokaId = Value(shlokaId),
       status = Value(status),
       firstOpenedAt = Value(firstOpenedAt),
       lastOpenedAt = Value(lastOpenedAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingProgressEntry> custom({
    Expression<String>? id,
    Expression<String>? shlokaId,
    Expression<String>? status,
    Expression<String>? firstOpenedAt,
    Expression<String>? lastOpenedAt,
    Expression<String>? studiedAt,
    Expression<String>? reflectedAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shlokaId != null) 'shloka_id': shlokaId,
      if (status != null) 'status': status,
      if (firstOpenedAt != null) 'first_opened_at': firstOpenedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (studiedAt != null) 'studied_at': studiedAt,
      if (reflectedAt != null) 'reflected_at': reflectedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? id,
    Value<String>? shlokaId,
    Value<ReadingStatus>? status,
    Value<DateTime>? firstOpenedAt,
    Value<DateTime>? lastOpenedAt,
    Value<DateTime?>? studiedAt,
    Value<DateTime?>? reflectedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      id: id ?? this.id,
      shlokaId: shlokaId ?? this.shlokaId,
      status: status ?? this.status,
      firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      studiedAt: studiedAt ?? this.studiedAt,
      reflectedAt: reflectedAt ?? this.reflectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shlokaId.present) {
      map['shloka_id'] = Variable<String>(shlokaId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ReadingProgressTable.$converterstatus.toSql(status.value),
      );
    }
    if (firstOpenedAt.present) {
      map['first_opened_at'] = Variable<String>(
        $ReadingProgressTable.$converterfirstOpenedAt.toSql(
          firstOpenedAt.value,
        ),
      );
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<String>(
        $ReadingProgressTable.$converterlastOpenedAt.toSql(lastOpenedAt.value),
      );
    }
    if (studiedAt.present) {
      map['studied_at'] = Variable<String>(
        $ReadingProgressTable.$converterstudiedAtn.toSql(studiedAt.value),
      );
    }
    if (reflectedAt.present) {
      map['reflected_at'] = Variable<String>(
        $ReadingProgressTable.$converterreflectedAtn.toSql(reflectedAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $ReadingProgressTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('status: $status, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('studiedAt: $studiedAt, ')
          ..write('reflectedAt: $reflectedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingHistoryTable extends ReadingHistory
    with TableInfo<$ReadingHistoryTable, ReadingHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.length.equals(36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shlokaIdMeta = const VerificationMeta(
    'shlokaId',
  );
  @override
  late final GeneratedColumn<String> shlokaId = GeneratedColumn<String>(
    'shloka_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shlokas (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingActivity, String> action =
      GeneratedColumn<String>(
        'action',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReadingActivity>($ReadingHistoryTable.$converteraction);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> occurredAt =
      GeneratedColumn<String>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReadingHistoryTable.$converteroccurredAt);
  @override
  List<GeneratedColumn> get $columns => [id, shlokaId, action, occurredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shloka_id')) {
      context.handle(
        _shlokaIdMeta,
        shlokaId.isAcceptableOrUnknown(data['shloka_id']!, _shlokaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shlokaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shlokaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shloka_id'],
      )!,
      action: $ReadingHistoryTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action'],
        )!,
      ),
      occurredAt: $ReadingHistoryTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
    );
  }

  @override
  $ReadingHistoryTable createAlias(String alias) {
    return $ReadingHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<ReadingActivity, String> $converteraction =
      const SqlEnumConverter<ReadingActivity>(ReadingActivity.values);
  static TypeConverter<DateTime, String> $converteroccurredAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class ReadingHistoryEntry extends DataClass
    implements Insertable<ReadingHistoryEntry> {
  final String id;
  final String shlokaId;
  final ReadingActivity action;
  final DateTime occurredAt;
  const ReadingHistoryEntry({
    required this.id,
    required this.shlokaId,
    required this.action,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shloka_id'] = Variable<String>(shlokaId);
    {
      map['action'] = Variable<String>(
        $ReadingHistoryTable.$converteraction.toSql(action),
      );
    }
    {
      map['occurred_at'] = Variable<String>(
        $ReadingHistoryTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    return map;
  }

  ReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return ReadingHistoryCompanion(
      id: Value(id),
      shlokaId: Value(shlokaId),
      action: Value(action),
      occurredAt: Value(occurredAt),
    );
  }

  factory ReadingHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      shlokaId: serializer.fromJson<String>(json['shlokaId']),
      action: serializer.fromJson<ReadingActivity>(json['action']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shlokaId': serializer.toJson<String>(shlokaId),
      'action': serializer.toJson<ReadingActivity>(action),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  ReadingHistoryEntry copyWith({
    String? id,
    String? shlokaId,
    ReadingActivity? action,
    DateTime? occurredAt,
  }) => ReadingHistoryEntry(
    id: id ?? this.id,
    shlokaId: shlokaId ?? this.shlokaId,
    action: action ?? this.action,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  ReadingHistoryEntry copyWithCompanion(ReadingHistoryCompanion data) {
    return ReadingHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      shlokaId: data.shlokaId.present ? data.shlokaId.value : this.shlokaId,
      action: data.action.present ? data.action.value : this.action,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryEntry(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('action: $action, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shlokaId, action, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingHistoryEntry &&
          other.id == this.id &&
          other.shlokaId == this.shlokaId &&
          other.action == this.action &&
          other.occurredAt == this.occurredAt);
}

class ReadingHistoryCompanion extends UpdateCompanion<ReadingHistoryEntry> {
  final Value<String> id;
  final Value<String> shlokaId;
  final Value<ReadingActivity> action;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const ReadingHistoryCompanion({
    this.id = const Value.absent(),
    this.shlokaId = const Value.absent(),
    this.action = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingHistoryCompanion.insert({
    required String id,
    required String shlokaId,
    required ReadingActivity action,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shlokaId = Value(shlokaId),
       action = Value(action),
       occurredAt = Value(occurredAt);
  static Insertable<ReadingHistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? shlokaId,
    Expression<String>? action,
    Expression<String>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shlokaId != null) 'shloka_id': shlokaId,
      if (action != null) 'action': action,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? shlokaId,
    Value<ReadingActivity>? action,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return ReadingHistoryCompanion(
      id: id ?? this.id,
      shlokaId: shlokaId ?? this.shlokaId,
      action: action ?? this.action,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shlokaId.present) {
      map['shloka_id'] = Variable<String>(shlokaId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(
        $ReadingHistoryTable.$converteraction.toSql(action.value),
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(
        $ReadingHistoryTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryCompanion(')
          ..write('id: $id, ')
          ..write('shlokaId: $shlokaId, ')
          ..write('action: $action, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    check: () => ComparableExpr(key.length).isBiggerThanValue(0),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LocalSettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: $LocalSettingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const LocalSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    {
      map['updated_at'] = Variable<String>(
        $LocalSettingsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      LocalSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $LocalSettingsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    check: () => ComparableExpr(key.length).isBiggerThanValue(0),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SyncMetadataTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: $SyncMetadataTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterupdatedAt =
      const UtcTimestampConverter();
  @override
  bool get isStrict => true;
}

class SyncMetadataEntry extends DataClass
    implements Insertable<SyncMetadataEntry> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SyncMetadataEntry({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    {
      map['updated_at'] = Variable<String>(
        $SyncMetadataTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncMetadataEntry copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => SyncMetadataEntry(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncMetadataEntry copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMetadataEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $SyncMetadataTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalChaptersTable localChapters = $LocalChaptersTable(this);
  late final $LocalShlokasTable localShlokas = $LocalShlokasTable(this);
  late final $ReflectionsTable reflections = $ReflectionsTable(this);
  late final $PersonalNotesTable personalNotes = $PersonalNotesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $ReadingHistoryTable readingHistory = $ReadingHistoryTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final Index localChaptersUpdatedAtIdx = Index(
    'local_chapters_updated_at_idx',
    'CREATE INDEX local_chapters_updated_at_idx ON local_chapters (updated_at, id)',
  );
  late final Index localShlokasReferenceIdx = Index(
    'local_shlokas_reference_idx',
    'CREATE INDEX local_shlokas_reference_idx ON local_shlokas (reference)',
  );
  late final Index localShlokasUpdatedAtIdx = Index(
    'local_shlokas_updated_at_idx',
    'CREATE INDEX local_shlokas_updated_at_idx ON local_shlokas (updated_at, id)',
  );
  late final Index reflectionsShlokaCreatedIdx = Index(
    'reflections_shloka_created_idx',
    'CREATE INDEX reflections_shloka_created_idx ON reflections (shloka_id, created_at)',
  );
  late final Index reflectionsCreatedIdx = Index(
    'reflections_created_idx',
    'CREATE INDEX reflections_created_idx ON reflections (created_at)',
  );
  late final Index personalNotesShlokaUpdatedIdx = Index(
    'personal_notes_shloka_updated_idx',
    'CREATE INDEX personal_notes_shloka_updated_idx ON personal_notes (shloka_id, updated_at)',
  );
  late final Index personalNotesUpdatedIdx = Index(
    'personal_notes_updated_idx',
    'CREATE INDEX personal_notes_updated_idx ON personal_notes (updated_at)',
  );
  late final Index bookmarksCreatedIdx = Index(
    'bookmarks_created_idx',
    'CREATE INDEX bookmarks_created_idx ON bookmarks (created_at)',
  );
  late final Index readingHistoryShlokaOccurredIdx = Index(
    'reading_history_shloka_occurred_idx',
    'CREATE INDEX reading_history_shloka_occurred_idx ON reading_history (shloka_id, occurred_at)',
  );
  late final Index readingHistoryOccurredIdx = Index(
    'reading_history_occurred_idx',
    'CREATE INDEX reading_history_occurred_idx ON reading_history (occurred_at)',
  );
  late final ChapterDao chapterDao = ChapterDao(this as AppDatabase);
  late final ShlokaDao shlokaDao = ShlokaDao(this as AppDatabase);
  late final ReflectionDao reflectionDao = ReflectionDao(this as AppDatabase);
  late final PersonalNoteDao personalNoteDao = PersonalNoteDao(
    this as AppDatabase,
  );
  late final BookmarkDao bookmarkDao = BookmarkDao(this as AppDatabase);
  late final ReadingProgressDao readingProgressDao = ReadingProgressDao(
    this as AppDatabase,
  );
  late final ReadingHistoryDao readingHistoryDao = ReadingHistoryDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final SyncMetadataDao syncMetadataDao = SyncMetadataDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localChapters,
    localShlokas,
    reflections,
    personalNotes,
    bookmarks,
    readingProgress,
    readingHistory,
    localSettings,
    syncMetadata,
    localChaptersUpdatedAtIdx,
    localShlokasReferenceIdx,
    localShlokasUpdatedAtIdx,
    reflectionsShlokaCreatedIdx,
    reflectionsCreatedIdx,
    personalNotesShlokaUpdatedIdx,
    personalNotesUpdatedIdx,
    bookmarksCreatedIdx,
    readingHistoryShlokaOccurredIdx,
    readingHistoryOccurredIdx,
  ];
}

typedef $$LocalChaptersTableCreateCompanionBuilder =
    LocalChaptersCompanion Function({
      Value<int> id,
      required String sanskritName,
      required String hindiName,
      required String englishName,
      Value<String?> introduction,
      Value<String?> overview,
      Value<String?> centralTheme,
      Value<List<String>?> keyTopics,
      Value<String?> summary,
      Value<String?> conclusion,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$LocalChaptersTableUpdateCompanionBuilder =
    LocalChaptersCompanion Function({
      Value<int> id,
      Value<String> sanskritName,
      Value<String> hindiName,
      Value<String> englishName,
      Value<String?> introduction,
      Value<String?> overview,
      Value<String?> centralTheme,
      Value<List<String>?> keyTopics,
      Value<String?> summary,
      Value<String?> conclusion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$LocalChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $LocalChaptersTable, LocalChapter> {
  $$LocalChaptersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalShlokasTable, List<LocalShloka>>
  _localShlokasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localShlokas,
    aliasName: 'local_chapters__id__local_shlokas__chapter_id',
  );

  $$LocalShlokasTableProcessedTableManager get localShlokasRefs {
    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_localShlokasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalChaptersTable> {
  $$LocalChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sanskritName => $composableBuilder(
    column: $table.sanskritName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hindiName => $composableBuilder(
    column: $table.hindiName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get introduction => $composableBuilder(
    column: $table.introduction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get centralTheme => $composableBuilder(
    column: $table.centralTheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get keyTopics => $composableBuilder(
    column: $table.keyTopics,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> localShlokasRefs(
    Expression<bool> Function($$LocalShlokasTableFilterComposer f) f,
  ) {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalChaptersTable> {
  $$LocalChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sanskritName => $composableBuilder(
    column: $table.sanskritName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hindiName => $composableBuilder(
    column: $table.hindiName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get introduction => $composableBuilder(
    column: $table.introduction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get centralTheme => $composableBuilder(
    column: $table.centralTheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyTopics => $composableBuilder(
    column: $table.keyTopics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalChaptersTable> {
  $$LocalChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sanskritName => $composableBuilder(
    column: $table.sanskritName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hindiName =>
      $composableBuilder(column: $table.hindiName, builder: (column) => column);

  GeneratedColumn<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get introduction => $composableBuilder(
    column: $table.introduction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get centralTheme => $composableBuilder(
    column: $table.centralTheme,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>?, String> get keyTopics =>
      $composableBuilder(column: $table.keyTopics, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> localShlokasRefs<T extends Object>(
    Expression<T> Function($$LocalShlokasTableAnnotationComposer a) f,
  ) {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalChaptersTable,
          LocalChapter,
          $$LocalChaptersTableFilterComposer,
          $$LocalChaptersTableOrderingComposer,
          $$LocalChaptersTableAnnotationComposer,
          $$LocalChaptersTableCreateCompanionBuilder,
          $$LocalChaptersTableUpdateCompanionBuilder,
          (LocalChapter, $$LocalChaptersTableReferences),
          LocalChapter,
          PrefetchHooks Function({bool localShlokasRefs})
        > {
  $$LocalChaptersTableTableManager(_$AppDatabase db, $LocalChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sanskritName = const Value.absent(),
                Value<String> hindiName = const Value.absent(),
                Value<String> englishName = const Value.absent(),
                Value<String?> introduction = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> centralTheme = const Value.absent(),
                Value<List<String>?> keyTopics = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> conclusion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LocalChaptersCompanion(
                id: id,
                sanskritName: sanskritName,
                hindiName: hindiName,
                englishName: englishName,
                introduction: introduction,
                overview: overview,
                centralTheme: centralTheme,
                keyTopics: keyTopics,
                summary: summary,
                conclusion: conclusion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sanskritName,
                required String hindiName,
                required String englishName,
                Value<String?> introduction = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> centralTheme = const Value.absent(),
                Value<List<String>?> keyTopics = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> conclusion = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => LocalChaptersCompanion.insert(
                id: id,
                sanskritName: sanskritName,
                hindiName: hindiName,
                englishName: englishName,
                introduction: introduction,
                overview: overview,
                centralTheme: centralTheme,
                keyTopics: keyTopics,
                summary: summary,
                conclusion: conclusion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localShlokasRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (localShlokasRefs) db.localShlokas],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localShlokasRefs)
                    await $_getPrefetchedData<
                      LocalChapter,
                      $LocalChaptersTable,
                      LocalShloka
                    >(
                      currentTable: table,
                      referencedTable: $$LocalChaptersTableReferences
                          ._localShlokasRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalChaptersTableReferences(
                            db,
                            table,
                            p0,
                          ).localShlokasRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.chapterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalChaptersTable,
      LocalChapter,
      $$LocalChaptersTableFilterComposer,
      $$LocalChaptersTableOrderingComposer,
      $$LocalChaptersTableAnnotationComposer,
      $$LocalChaptersTableCreateCompanionBuilder,
      $$LocalChaptersTableUpdateCompanionBuilder,
      (LocalChapter, $$LocalChaptersTableReferences),
      LocalChapter,
      PrefetchHooks Function({bool localShlokasRefs})
    >;
typedef $$LocalShlokasTableCreateCompanionBuilder =
    LocalShlokasCompanion Function({
      required String id,
      required int chapterId,
      required int verseNumber,
      required String reference,
      Value<String?> indexTitle,
      Value<String?> indexSummary,
      Value<String?> sanskritText,
      Value<String?> transliteration,
      Value<String?> hindiMeaning,
      Value<String?> hindiMeaningNote,
      Value<String?> englishMeaning,
      Value<String?> context,
      Value<String?> lifeLesson,
      Value<String?> spiritualMeaning,
      Value<String?> reflectionQuestion,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalShlokasTableUpdateCompanionBuilder =
    LocalShlokasCompanion Function({
      Value<String> id,
      Value<int> chapterId,
      Value<int> verseNumber,
      Value<String> reference,
      Value<String?> indexTitle,
      Value<String?> indexSummary,
      Value<String?> sanskritText,
      Value<String?> transliteration,
      Value<String?> hindiMeaning,
      Value<String?> hindiMeaningNote,
      Value<String?> englishMeaning,
      Value<String?> context,
      Value<String?> lifeLesson,
      Value<String?> spiritualMeaning,
      Value<String?> reflectionQuestion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$LocalShlokasTableReferences
    extends BaseReferences<_$AppDatabase, $LocalShlokasTable, LocalShloka> {
  $$LocalShlokasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalChaptersTable _chapterIdTable(_$AppDatabase db) => db
      .localChapters
      .createAlias('local_shlokas__chapter_id__local_chapters__id');

  $$LocalChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$LocalChaptersTableTableManager(
      $_db,
      $_db.localChapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReflectionsTable, List<Reflection>>
  _reflectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reflections,
    aliasName: 'local_shlokas__id__reflections__shloka_id',
  );

  $$ReflectionsTableProcessedTableManager get reflectionsRefs {
    final manager = $$ReflectionsTableTableManager(
      $_db,
      $_db.reflections,
    ).filter((f) => f.shlokaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reflectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonalNotesTable, List<PersonalNote>>
  _personalNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personalNotes,
    aliasName: 'local_shlokas__id__personal_notes__shloka_id',
  );

  $$PersonalNotesTableProcessedTableManager get personalNotesRefs {
    final manager = $$PersonalNotesTableTableManager(
      $_db,
      $_db.personalNotes,
    ).filter((f) => f.shlokaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_personalNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'local_shlokas__id__bookmarks__shloka_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.shlokaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingProgressTable, List<ReadingProgressEntry>>
  _readingProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingProgress,
    aliasName: 'local_shlokas__id__reading_progress__shloka_id',
  );

  $$ReadingProgressTableProcessedTableManager get readingProgressRefs {
    final manager = $$ReadingProgressTableTableManager(
      $_db,
      $_db.readingProgress,
    ).filter((f) => f.shlokaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingHistoryTable, List<ReadingHistoryEntry>>
  _readingHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingHistory,
    aliasName: 'local_shlokas__id__reading_history__shloka_id',
  );

  $$ReadingHistoryTableProcessedTableManager get readingHistoryRefs {
    final manager = $$ReadingHistoryTableTableManager(
      $_db,
      $_db.readingHistory,
    ).filter((f) => f.shlokaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalShlokasTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShlokasTable> {
  $$LocalShlokasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexSummary => $composableBuilder(
    column: $table.indexSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sanskritText => $composableBuilder(
    column: $table.sanskritText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hindiMeaning => $composableBuilder(
    column: $table.hindiMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hindiMeaningNote => $composableBuilder(
    column: $table.hindiMeaningNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifeLesson => $composableBuilder(
    column: $table.lifeLesson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spiritualMeaning => $composableBuilder(
    column: $table.spiritualMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflectionQuestion => $composableBuilder(
    column: $table.reflectionQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalChaptersTableFilterComposer get chapterId {
    final $$LocalChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.localChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalChaptersTableFilterComposer(
            $db: $db,
            $table: $db.localChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reflectionsRefs(
    Expression<bool> Function($$ReflectionsTableFilterComposer f) f,
  ) {
    final $$ReflectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableFilterComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personalNotesRefs(
    Expression<bool> Function($$PersonalNotesTableFilterComposer f) f,
  ) {
    final $$PersonalNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalNotes,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalNotesTableFilterComposer(
            $db: $db,
            $table: $db.personalNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingProgressRefs(
    Expression<bool> Function($$ReadingProgressTableFilterComposer f) f,
  ) {
    final $$ReadingProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableFilterComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingHistoryRefs(
    Expression<bool> Function($$ReadingHistoryTableFilterComposer f) f,
  ) {
    final $$ReadingHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableFilterComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalShlokasTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShlokasTable> {
  $$LocalShlokasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexSummary => $composableBuilder(
    column: $table.indexSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sanskritText => $composableBuilder(
    column: $table.sanskritText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hindiMeaning => $composableBuilder(
    column: $table.hindiMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hindiMeaningNote => $composableBuilder(
    column: $table.hindiMeaningNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifeLesson => $composableBuilder(
    column: $table.lifeLesson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spiritualMeaning => $composableBuilder(
    column: $table.spiritualMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflectionQuestion => $composableBuilder(
    column: $table.reflectionQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalChaptersTableOrderingComposer get chapterId {
    final $$LocalChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.localChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.localChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalShlokasTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShlokasTable> {
  $$LocalShlokasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indexSummary => $composableBuilder(
    column: $table.indexSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sanskritText => $composableBuilder(
    column: $table.sanskritText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hindiMeaning => $composableBuilder(
    column: $table.hindiMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hindiMeaningNote => $composableBuilder(
    column: $table.hindiMeaningNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get lifeLesson => $composableBuilder(
    column: $table.lifeLesson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spiritualMeaning => $composableBuilder(
    column: $table.spiritualMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reflectionQuestion => $composableBuilder(
    column: $table.reflectionQuestion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LocalChaptersTableAnnotationComposer get chapterId {
    final $$LocalChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.localChapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.localChapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reflectionsRefs<T extends Object>(
    Expression<T> Function($$ReflectionsTableAnnotationComposer a) f,
  ) {
    final $$ReflectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reflections,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReflectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.reflections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personalNotesRefs<T extends Object>(
    Expression<T> Function($$PersonalNotesTableAnnotationComposer a) f,
  ) {
    final $$PersonalNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalNotes,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.personalNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingProgressRefs<T extends Object>(
    Expression<T> Function($$ReadingProgressTableAnnotationComposer a) f,
  ) {
    final $$ReadingProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingHistoryRefs<T extends Object>(
    Expression<T> Function($$ReadingHistoryTableAnnotationComposer a) f,
  ) {
    final $$ReadingHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingHistory,
      getReferencedColumn: (t) => t.shlokaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.readingHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalShlokasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShlokasTable,
          LocalShloka,
          $$LocalShlokasTableFilterComposer,
          $$LocalShlokasTableOrderingComposer,
          $$LocalShlokasTableAnnotationComposer,
          $$LocalShlokasTableCreateCompanionBuilder,
          $$LocalShlokasTableUpdateCompanionBuilder,
          (LocalShloka, $$LocalShlokasTableReferences),
          LocalShloka,
          PrefetchHooks Function({
            bool chapterId,
            bool reflectionsRefs,
            bool personalNotesRefs,
            bool bookmarksRefs,
            bool readingProgressRefs,
            bool readingHistoryRefs,
          })
        > {
  $$LocalShlokasTableTableManager(_$AppDatabase db, $LocalShlokasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShlokasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShlokasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShlokasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int> verseNumber = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String?> indexTitle = const Value.absent(),
                Value<String?> indexSummary = const Value.absent(),
                Value<String?> sanskritText = const Value.absent(),
                Value<String?> transliteration = const Value.absent(),
                Value<String?> hindiMeaning = const Value.absent(),
                Value<String?> hindiMeaningNote = const Value.absent(),
                Value<String?> englishMeaning = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> lifeLesson = const Value.absent(),
                Value<String?> spiritualMeaning = const Value.absent(),
                Value<String?> reflectionQuestion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShlokasCompanion(
                id: id,
                chapterId: chapterId,
                verseNumber: verseNumber,
                reference: reference,
                indexTitle: indexTitle,
                indexSummary: indexSummary,
                sanskritText: sanskritText,
                transliteration: transliteration,
                hindiMeaning: hindiMeaning,
                hindiMeaningNote: hindiMeaningNote,
                englishMeaning: englishMeaning,
                context: context,
                lifeLesson: lifeLesson,
                spiritualMeaning: spiritualMeaning,
                reflectionQuestion: reflectionQuestion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int chapterId,
                required int verseNumber,
                required String reference,
                Value<String?> indexTitle = const Value.absent(),
                Value<String?> indexSummary = const Value.absent(),
                Value<String?> sanskritText = const Value.absent(),
                Value<String?> transliteration = const Value.absent(),
                Value<String?> hindiMeaning = const Value.absent(),
                Value<String?> hindiMeaningNote = const Value.absent(),
                Value<String?> englishMeaning = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> lifeLesson = const Value.absent(),
                Value<String?> spiritualMeaning = const Value.absent(),
                Value<String?> reflectionQuestion = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShlokasCompanion.insert(
                id: id,
                chapterId: chapterId,
                verseNumber: verseNumber,
                reference: reference,
                indexTitle: indexTitle,
                indexSummary: indexSummary,
                sanskritText: sanskritText,
                transliteration: transliteration,
                hindiMeaning: hindiMeaning,
                hindiMeaningNote: hindiMeaningNote,
                englishMeaning: englishMeaning,
                context: context,
                lifeLesson: lifeLesson,
                spiritualMeaning: spiritualMeaning,
                reflectionQuestion: reflectionQuestion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalShlokasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                chapterId = false,
                reflectionsRefs = false,
                personalNotesRefs = false,
                bookmarksRefs = false,
                readingProgressRefs = false,
                readingHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reflectionsRefs) db.reflections,
                    if (personalNotesRefs) db.personalNotes,
                    if (bookmarksRefs) db.bookmarks,
                    if (readingProgressRefs) db.readingProgress,
                    if (readingHistoryRefs) db.readingHistory,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (chapterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.chapterId,
                                    referencedTable:
                                        $$LocalShlokasTableReferences
                                            ._chapterIdTable(db),
                                    referencedColumn:
                                        $$LocalShlokasTableReferences
                                            ._chapterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reflectionsRefs)
                        await $_getPrefetchedData<
                          LocalShloka,
                          $LocalShlokasTable,
                          Reflection
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShlokasTableReferences
                              ._reflectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShlokasTableReferences(
                                db,
                                table,
                                p0,
                              ).reflectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shlokaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personalNotesRefs)
                        await $_getPrefetchedData<
                          LocalShloka,
                          $LocalShlokasTable,
                          PersonalNote
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShlokasTableReferences
                              ._personalNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShlokasTableReferences(
                                db,
                                table,
                                p0,
                              ).personalNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shlokaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          LocalShloka,
                          $LocalShlokasTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShlokasTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShlokasTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shlokaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingProgressRefs)
                        await $_getPrefetchedData<
                          LocalShloka,
                          $LocalShlokasTable,
                          ReadingProgressEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShlokasTableReferences
                              ._readingProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShlokasTableReferences(
                                db,
                                table,
                                p0,
                              ).readingProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shlokaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingHistoryRefs)
                        await $_getPrefetchedData<
                          LocalShloka,
                          $LocalShlokasTable,
                          ReadingHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LocalShlokasTableReferences
                              ._readingHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalShlokasTableReferences(
                                db,
                                table,
                                p0,
                              ).readingHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shlokaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalShlokasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShlokasTable,
      LocalShloka,
      $$LocalShlokasTableFilterComposer,
      $$LocalShlokasTableOrderingComposer,
      $$LocalShlokasTableAnnotationComposer,
      $$LocalShlokasTableCreateCompanionBuilder,
      $$LocalShlokasTableUpdateCompanionBuilder,
      (LocalShloka, $$LocalShlokasTableReferences),
      LocalShloka,
      PrefetchHooks Function({
        bool chapterId,
        bool reflectionsRefs,
        bool personalNotesRefs,
        bool bookmarksRefs,
        bool readingProgressRefs,
        bool readingHistoryRefs,
      })
    >;
typedef $$ReflectionsTableCreateCompanionBuilder =
    ReflectionsCompanion Function({
      required String id,
      required String shlokaId,
      required String answer,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReflectionsTableUpdateCompanionBuilder =
    ReflectionsCompanion Function({
      Value<String> id,
      Value<String> shlokaId,
      Value<String> answer,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReflectionsTableReferences
    extends BaseReferences<_$AppDatabase, $ReflectionsTable, Reflection> {
  $$ReflectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalShlokasTable _shlokaIdTable(_$AppDatabase db) =>
      db.localShlokas.createAlias('reflections__shloka_id__local_shlokas__id');

  $$LocalShlokasTableProcessedTableManager get shlokaId {
    final $_column = $_itemColumn<String>('shloka_id')!;

    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shlokaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalShlokasTableFilterComposer get shlokaId {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShlokasTableOrderingComposer get shlokaId {
    final $$LocalShlokasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableOrderingComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReflectionsTable> {
  $$ReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalShlokasTableAnnotationComposer get shlokaId {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReflectionsTable,
          Reflection,
          $$ReflectionsTableFilterComposer,
          $$ReflectionsTableOrderingComposer,
          $$ReflectionsTableAnnotationComposer,
          $$ReflectionsTableCreateCompanionBuilder,
          $$ReflectionsTableUpdateCompanionBuilder,
          (Reflection, $$ReflectionsTableReferences),
          Reflection,
          PrefetchHooks Function({bool shlokaId})
        > {
  $$ReflectionsTableTableManager(_$AppDatabase db, $ReflectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shlokaId = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion(
                id: id,
                shlokaId: shlokaId,
                answer: answer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shlokaId,
                required String answer,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReflectionsCompanion.insert(
                id: id,
                shlokaId: shlokaId,
                answer: answer,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReflectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shlokaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shlokaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shlokaId,
                                referencedTable: $$ReflectionsTableReferences
                                    ._shlokaIdTable(db),
                                referencedColumn: $$ReflectionsTableReferences
                                    ._shlokaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReflectionsTable,
      Reflection,
      $$ReflectionsTableFilterComposer,
      $$ReflectionsTableOrderingComposer,
      $$ReflectionsTableAnnotationComposer,
      $$ReflectionsTableCreateCompanionBuilder,
      $$ReflectionsTableUpdateCompanionBuilder,
      (Reflection, $$ReflectionsTableReferences),
      Reflection,
      PrefetchHooks Function({bool shlokaId})
    >;
typedef $$PersonalNotesTableCreateCompanionBuilder =
    PersonalNotesCompanion Function({
      required String id,
      Value<String?> shlokaId,
      Value<String?> title,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PersonalNotesTableUpdateCompanionBuilder =
    PersonalNotesCompanion Function({
      Value<String> id,
      Value<String?> shlokaId,
      Value<String?> title,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PersonalNotesTableReferences
    extends BaseReferences<_$AppDatabase, $PersonalNotesTable, PersonalNote> {
  $$PersonalNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShlokasTable _shlokaIdTable(_$AppDatabase db) => db.localShlokas
      .createAlias('personal_notes__shloka_id__local_shlokas__id');

  $$LocalShlokasTableProcessedTableManager? get shlokaId {
    final $_column = $_itemColumn<String>('shloka_id');
    if ($_column == null) return null;
    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shlokaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonalNotesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalNotesTable> {
  $$PersonalNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalShlokasTableFilterComposer get shlokaId {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalNotesTable> {
  $$PersonalNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShlokasTableOrderingComposer get shlokaId {
    final $$LocalShlokasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableOrderingComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalNotesTable> {
  $$PersonalNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalShlokasTableAnnotationComposer get shlokaId {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalNotesTable,
          PersonalNote,
          $$PersonalNotesTableFilterComposer,
          $$PersonalNotesTableOrderingComposer,
          $$PersonalNotesTableAnnotationComposer,
          $$PersonalNotesTableCreateCompanionBuilder,
          $$PersonalNotesTableUpdateCompanionBuilder,
          (PersonalNote, $$PersonalNotesTableReferences),
          PersonalNote,
          PrefetchHooks Function({bool shlokaId})
        > {
  $$PersonalNotesTableTableManager(_$AppDatabase db, $PersonalNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> shlokaId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalNotesCompanion(
                id: id,
                shlokaId: shlokaId,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> shlokaId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonalNotesCompanion.insert(
                id: id,
                shlokaId: shlokaId,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonalNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shlokaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shlokaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shlokaId,
                                referencedTable: $$PersonalNotesTableReferences
                                    ._shlokaIdTable(db),
                                referencedColumn: $$PersonalNotesTableReferences
                                    ._shlokaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonalNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalNotesTable,
      PersonalNote,
      $$PersonalNotesTableFilterComposer,
      $$PersonalNotesTableOrderingComposer,
      $$PersonalNotesTableAnnotationComposer,
      $$PersonalNotesTableCreateCompanionBuilder,
      $$PersonalNotesTableUpdateCompanionBuilder,
      (PersonalNote, $$PersonalNotesTableReferences),
      PersonalNote,
      PrefetchHooks Function({bool shlokaId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String shlokaId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> shlokaId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalShlokasTable _shlokaIdTable(_$AppDatabase db) =>
      db.localShlokas.createAlias('bookmarks__shloka_id__local_shlokas__id');

  $$LocalShlokasTableProcessedTableManager get shlokaId {
    final $_column = $_itemColumn<String>('shloka_id')!;

    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shlokaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalShlokasTableFilterComposer get shlokaId {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShlokasTableOrderingComposer get shlokaId {
    final $$LocalShlokasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableOrderingComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalShlokasTableAnnotationComposer get shlokaId {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool shlokaId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shlokaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                shlokaId: shlokaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shlokaId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                shlokaId: shlokaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shlokaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shlokaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shlokaId,
                                referencedTable: $$BookmarksTableReferences
                                    ._shlokaIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._shlokaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool shlokaId})
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      required String id,
      required String shlokaId,
      required ReadingStatus status,
      required DateTime firstOpenedAt,
      required DateTime lastOpenedAt,
      Value<DateTime?> studiedAt,
      Value<DateTime?> reflectedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<String> id,
      Value<String> shlokaId,
      Value<ReadingStatus> status,
      Value<DateTime> firstOpenedAt,
      Value<DateTime> lastOpenedAt,
      Value<DateTime?> studiedAt,
      Value<DateTime?> reflectedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReadingProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressEntry
        > {
  $$ReadingProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShlokasTable _shlokaIdTable(_$AppDatabase db) => db.localShlokas
      .createAlias('reading_progress__shloka_id__local_shlokas__id');

  $$LocalShlokasTableProcessedTableManager get shlokaId {
    final $_column = $_itemColumn<String>('shloka_id')!;

    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shlokaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReadingStatus, ReadingStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get firstOpenedAt => $composableBuilder(
    column: $table.firstOpenedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get lastOpenedAt =>
      $composableBuilder(
        column: $table.lastOpenedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get studiedAt =>
      $composableBuilder(
        column: $table.studiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get reflectedAt =>
      $composableBuilder(
        column: $table.reflectedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalShlokasTableFilterComposer get shlokaId {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstOpenedAt => $composableBuilder(
    column: $table.firstOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studiedAt => $composableBuilder(
    column: $table.studiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflectedAt => $composableBuilder(
    column: $table.reflectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShlokasTableOrderingComposer get shlokaId {
    final $$LocalShlokasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableOrderingComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get firstOpenedAt =>
      $composableBuilder(
        column: $table.firstOpenedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, String> get lastOpenedAt =>
      $composableBuilder(
        column: $table.lastOpenedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get studiedAt =>
      $composableBuilder(column: $table.studiedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get reflectedAt =>
      $composableBuilder(
        column: $table.reflectedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalShlokasTableAnnotationComposer get shlokaId {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressEntry,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (ReadingProgressEntry, $$ReadingProgressTableReferences),
          ReadingProgressEntry,
          PrefetchHooks Function({bool shlokaId})
        > {
  $$ReadingProgressTableTableManager(
    _$AppDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shlokaId = const Value.absent(),
                Value<ReadingStatus> status = const Value.absent(),
                Value<DateTime> firstOpenedAt = const Value.absent(),
                Value<DateTime> lastOpenedAt = const Value.absent(),
                Value<DateTime?> studiedAt = const Value.absent(),
                Value<DateTime?> reflectedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                id: id,
                shlokaId: shlokaId,
                status: status,
                firstOpenedAt: firstOpenedAt,
                lastOpenedAt: lastOpenedAt,
                studiedAt: studiedAt,
                reflectedAt: reflectedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shlokaId,
                required ReadingStatus status,
                required DateTime firstOpenedAt,
                required DateTime lastOpenedAt,
                Value<DateTime?> studiedAt = const Value.absent(),
                Value<DateTime?> reflectedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                id: id,
                shlokaId: shlokaId,
                status: status,
                firstOpenedAt: firstOpenedAt,
                lastOpenedAt: lastOpenedAt,
                studiedAt: studiedAt,
                reflectedAt: reflectedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shlokaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shlokaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shlokaId,
                                referencedTable:
                                    $$ReadingProgressTableReferences
                                        ._shlokaIdTable(db),
                                referencedColumn:
                                    $$ReadingProgressTableReferences
                                        ._shlokaIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressTable,
      ReadingProgressEntry,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (ReadingProgressEntry, $$ReadingProgressTableReferences),
      ReadingProgressEntry,
      PrefetchHooks Function({bool shlokaId})
    >;
typedef $$ReadingHistoryTableCreateCompanionBuilder =
    ReadingHistoryCompanion Function({
      required String id,
      required String shlokaId,
      required ReadingActivity action,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$ReadingHistoryTableUpdateCompanionBuilder =
    ReadingHistoryCompanion Function({
      Value<String> id,
      Value<String> shlokaId,
      Value<ReadingActivity> action,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

final class $$ReadingHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryEntry
        > {
  $$ReadingHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShlokasTable _shlokaIdTable(_$AppDatabase db) => db.localShlokas
      .createAlias('reading_history__shloka_id__local_shlokas__id');

  $$LocalShlokasTableProcessedTableManager get shlokaId {
    final $_column = $_itemColumn<String>('shloka_id')!;

    final manager = $$LocalShlokasTableTableManager(
      $_db,
      $_db.localShlokas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shlokaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReadingActivity, ReadingActivity, String>
  get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$LocalShlokasTableFilterComposer get shlokaId {
    final $$LocalShlokasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableFilterComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShlokasTableOrderingComposer get shlokaId {
    final $$LocalShlokasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableOrderingComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingActivity, String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );

  $$LocalShlokasTableAnnotationComposer get shlokaId {
    final $$LocalShlokasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shlokaId,
      referencedTable: $db.localShlokas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShlokasTableAnnotationComposer(
            $db: $db,
            $table: $db.localShlokas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryEntry,
          $$ReadingHistoryTableFilterComposer,
          $$ReadingHistoryTableOrderingComposer,
          $$ReadingHistoryTableAnnotationComposer,
          $$ReadingHistoryTableCreateCompanionBuilder,
          $$ReadingHistoryTableUpdateCompanionBuilder,
          (ReadingHistoryEntry, $$ReadingHistoryTableReferences),
          ReadingHistoryEntry,
          PrefetchHooks Function({bool shlokaId})
        > {
  $$ReadingHistoryTableTableManager(
    _$AppDatabase db,
    $ReadingHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shlokaId = const Value.absent(),
                Value<ReadingActivity> action = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion(
                id: id,
                shlokaId: shlokaId,
                action: action,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shlokaId,
                required ReadingActivity action,
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion.insert(
                id: id,
                shlokaId: shlokaId,
                action: action,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shlokaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shlokaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shlokaId,
                                referencedTable: $$ReadingHistoryTableReferences
                                    ._shlokaIdTable(db),
                                referencedColumn:
                                    $$ReadingHistoryTableReferences
                                        ._shlokaIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingHistoryTable,
      ReadingHistoryEntry,
      $$ReadingHistoryTableFilterComposer,
      $$ReadingHistoryTableOrderingComposer,
      $$ReadingHistoryTableAnnotationComposer,
      $$ReadingHistoryTableCreateCompanionBuilder,
      $$ReadingHistoryTableUpdateCompanionBuilder,
      (ReadingHistoryEntry, $$ReadingHistoryTableReferences),
      ReadingHistoryEntry,
      PrefetchHooks Function({bool shlokaId})
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataEntry,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataTable,
              SyncMetadataEntry
            >,
          ),
          SyncMetadataEntry,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataEntry,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataEntry,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataEntry>,
      ),
      SyncMetadataEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalChaptersTableTableManager get localChapters =>
      $$LocalChaptersTableTableManager(_db, _db.localChapters);
  $$LocalShlokasTableTableManager get localShlokas =>
      $$LocalShlokasTableTableManager(_db, _db.localShlokas);
  $$ReflectionsTableTableManager get reflections =>
      $$ReflectionsTableTableManager(_db, _db.reflections);
  $$PersonalNotesTableTableManager get personalNotes =>
      $$PersonalNotesTableTableManager(_db, _db.personalNotes);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(_db, _db.readingHistory);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
