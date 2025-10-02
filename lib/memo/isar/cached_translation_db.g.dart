// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_translation_db.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedTranslationDbCollection on Isar {
  IsarCollection<CachedTranslationDb> get cachedTranslationDbs =>
      this.collection();
}

const CachedTranslationDbSchema = CollectionSchema(
  name: r'CachedTranslationDb',
  id: 3702366925611836459,
  properties: {
    r'cacheKey': PropertySchema(
      id: 0,
      name: r'cacheKey',
      type: IsarType.string,
    ),
    r'languageCode': PropertySchema(
      id: 1,
      name: r'languageCode',
      type: IsarType.string,
    ),
    r'postId': PropertySchema(id: 2, name: r'postId', type: IsarType.string),
    r'translatedText': PropertySchema(
      id: 3,
      name: r'translatedText',
      type: IsarType.string,
    ),
  },

  estimateSize: _cachedTranslationDbEstimateSize,
  serialize: _cachedTranslationDbSerialize,
  deserialize: _cachedTranslationDbDeserialize,
  deserializeProp: _cachedTranslationDbDeserializeProp,
  idName: r'id',
  indexes: {
    r'cacheKey': IndexSchema(
      id: 5885332021012296610,
      name: r'cacheKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'cacheKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _cachedTranslationDbGetId,
  getLinks: _cachedTranslationDbGetLinks,
  attach: _cachedTranslationDbAttach,
  version: '3.3.0-dev.1',
);

int _cachedTranslationDbEstimateSize(
  CachedTranslationDb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cacheKey.length * 3;
  bytesCount += 3 + object.languageCode.length * 3;
  bytesCount += 3 + object.postId.length * 3;
  bytesCount += 3 + object.translatedText.length * 3;
  return bytesCount;
}

void _cachedTranslationDbSerialize(
  CachedTranslationDb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cacheKey);
  writer.writeString(offsets[1], object.languageCode);
  writer.writeString(offsets[2], object.postId);
  writer.writeString(offsets[3], object.translatedText);
}

CachedTranslationDb _cachedTranslationDbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedTranslationDb();
  object.cacheKey = reader.readString(offsets[0]);
  object.id = id;
  object.languageCode = reader.readString(offsets[1]);
  object.postId = reader.readString(offsets[2]);
  object.translatedText = reader.readString(offsets[3]);
  return object;
}

P _cachedTranslationDbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedTranslationDbGetId(CachedTranslationDb object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedTranslationDbGetLinks(
  CachedTranslationDb object,
) {
  return [];
}

void _cachedTranslationDbAttach(
  IsarCollection<dynamic> col,
  Id id,
  CachedTranslationDb object,
) {
  object.id = id;
}

extension CachedTranslationDbByIndex on IsarCollection<CachedTranslationDb> {
  Future<CachedTranslationDb?> getByCacheKey(String cacheKey) {
    return getByIndex(r'cacheKey', [cacheKey]);
  }

  CachedTranslationDb? getByCacheKeySync(String cacheKey) {
    return getByIndexSync(r'cacheKey', [cacheKey]);
  }

  Future<bool> deleteByCacheKey(String cacheKey) {
    return deleteByIndex(r'cacheKey', [cacheKey]);
  }

  bool deleteByCacheKeySync(String cacheKey) {
    return deleteByIndexSync(r'cacheKey', [cacheKey]);
  }

  Future<List<CachedTranslationDb?>> getAllByCacheKey(
    List<String> cacheKeyValues,
  ) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'cacheKey', values);
  }

  List<CachedTranslationDb?> getAllByCacheKeySync(List<String> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cacheKey', values);
  }

  Future<int> deleteAllByCacheKey(List<String> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cacheKey', values);
  }

  int deleteAllByCacheKeySync(List<String> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cacheKey', values);
  }

  Future<Id> putByCacheKey(CachedTranslationDb object) {
    return putByIndex(r'cacheKey', object);
  }

  Id putByCacheKeySync(CachedTranslationDb object, {bool saveLinks = true}) {
    return putByIndexSync(r'cacheKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCacheKey(List<CachedTranslationDb> objects) {
    return putAllByIndex(r'cacheKey', objects);
  }

  List<Id> putAllByCacheKeySync(
    List<CachedTranslationDb> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'cacheKey', objects, saveLinks: saveLinks);
  }
}

extension CachedTranslationDbQueryWhereSort
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QWhere> {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedTranslationDbQueryWhere
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QWhereClause> {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  cacheKeyEqualTo(String cacheKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'cacheKey', value: [cacheKey]),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterWhereClause>
  cacheKeyNotEqualTo(String cacheKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [],
                upper: [cacheKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [cacheKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [cacheKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [],
                upper: [cacheKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CachedTranslationDbQueryFilter
    on
        QueryBuilder<
          CachedTranslationDb,
          CachedTranslationDb,
          QFilterCondition
        > {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cacheKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cacheKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cacheKey', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  cacheKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cacheKey', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'languageCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'languageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'languageCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'languageCode', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  languageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'languageCode', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'postId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'postId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'postId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'postId', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  postIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'postId', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translatedText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translatedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translatedText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translatedText', value: ''),
      );
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterFilterCondition>
  translatedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'translatedText', value: ''),
      );
    });
  }
}

extension CachedTranslationDbQueryObject
    on
        QueryBuilder<
          CachedTranslationDb,
          CachedTranslationDb,
          QFilterCondition
        > {}

extension CachedTranslationDbQueryLinks
    on
        QueryBuilder<
          CachedTranslationDb,
          CachedTranslationDb,
          QFilterCondition
        > {}

extension CachedTranslationDbQuerySortBy
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QSortBy> {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByLanguageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageCode', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByLanguageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageCode', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByTranslatedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  sortByTranslatedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.desc);
    });
  }
}

extension CachedTranslationDbQuerySortThenBy
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QSortThenBy> {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByLanguageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageCode', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByLanguageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languageCode', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByTranslatedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.asc);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QAfterSortBy>
  thenByTranslatedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.desc);
    });
  }
}

extension CachedTranslationDbQueryWhereDistinct
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QDistinct> {
  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QDistinct>
  distinctByCacheKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QDistinct>
  distinctByLanguageCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'languageCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QDistinct>
  distinctByPostId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedTranslationDb, CachedTranslationDb, QDistinct>
  distinctByTranslatedText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translatedText',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension CachedTranslationDbQueryProperty
    on QueryBuilder<CachedTranslationDb, CachedTranslationDb, QQueryProperty> {
  QueryBuilder<CachedTranslationDb, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedTranslationDb, String, QQueryOperations>
  cacheKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheKey');
    });
  }

  QueryBuilder<CachedTranslationDb, String, QQueryOperations>
  languageCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'languageCode');
    });
  }

  QueryBuilder<CachedTranslationDb, String, QQueryOperations> postIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postId');
    });
  }

  QueryBuilder<CachedTranslationDb, String, QQueryOperations>
  translatedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translatedText');
    });
  }
}
