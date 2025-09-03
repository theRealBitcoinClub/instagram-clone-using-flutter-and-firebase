// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_creator_db.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMemoModelCreatorDbCollection on Isar {
  IsarCollection<MemoModelCreatorDb> get memoModelCreatorDbs =>
      this.collection();
}

const MemoModelCreatorDbSchema = CollectionSchema(
  name: r'MemoModelCreatorDb',
  id: 5548915274647387217,
  properties: {
    r'actions': PropertySchema(id: 0, name: r'actions', type: IsarType.long),
    r'balanceBch': PropertySchema(
      id: 1,
      name: r'balanceBch',
      type: IsarType.long,
    ),
    r'balanceMemo': PropertySchema(
      id: 2,
      name: r'balanceMemo',
      type: IsarType.long,
    ),
    r'balanceToken': PropertySchema(
      id: 3,
      name: r'balanceToken',
      type: IsarType.long,
    ),
    r'bchAddressCashtokenAware': PropertySchema(
      id: 4,
      name: r'bchAddressCashtokenAware',
      type: IsarType.string,
    ),
    r'created': PropertySchema(id: 5, name: r'created', type: IsarType.string),
    r'creatorId': PropertySchema(
      id: 6,
      name: r'creatorId',
      type: IsarType.string,
    ),
    r'followerCount': PropertySchema(
      id: 7,
      name: r'followerCount',
      type: IsarType.long,
    ),
    r'hasRegisteredAsUser': PropertySchema(
      id: 8,
      name: r'hasRegisteredAsUser',
      type: IsarType.bool,
    ),
    r'lastActionDate': PropertySchema(
      id: 9,
      name: r'lastActionDate',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 10,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(id: 11, name: r'name', type: IsarType.string),
    r'profileImgurUrl': PropertySchema(
      id: 12,
      name: r'profileImgurUrl',
      type: IsarType.string,
    ),
    r'profileText': PropertySchema(
      id: 13,
      name: r'profileText',
      type: IsarType.string,
    ),
  },

  estimateSize: _memoModelCreatorDbEstimateSize,
  serialize: _memoModelCreatorDbSerialize,
  deserialize: _memoModelCreatorDbDeserialize,
  deserializeProp: _memoModelCreatorDbDeserializeProp,
  idName: r'id',
  indexes: {
    r'creatorId': IndexSchema(
      id: 8469841690643490241,
      name: r'creatorId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'creatorId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _memoModelCreatorDbGetId,
  getLinks: _memoModelCreatorDbGetLinks,
  attach: _memoModelCreatorDbAttach,
  version: '3.3.0-dev.1',
);

int _memoModelCreatorDbEstimateSize(
  MemoModelCreatorDb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bchAddressCashtokenAware.length * 3;
  bytesCount += 3 + object.created.length * 3;
  bytesCount += 3 + object.creatorId.length * 3;
  bytesCount += 3 + object.lastActionDate.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.profileImgurUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.profileText.length * 3;
  return bytesCount;
}

void _memoModelCreatorDbSerialize(
  MemoModelCreatorDb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.actions);
  writer.writeLong(offsets[1], object.balanceBch);
  writer.writeLong(offsets[2], object.balanceMemo);
  writer.writeLong(offsets[3], object.balanceToken);
  writer.writeString(offsets[4], object.bchAddressCashtokenAware);
  writer.writeString(offsets[5], object.created);
  writer.writeString(offsets[6], object.creatorId);
  writer.writeLong(offsets[7], object.followerCount);
  writer.writeBool(offsets[8], object.hasRegisteredAsUser);
  writer.writeString(offsets[9], object.lastActionDate);
  writer.writeDateTime(offsets[10], object.lastUpdated);
  writer.writeString(offsets[11], object.name);
  writer.writeString(offsets[12], object.profileImgurUrl);
  writer.writeString(offsets[13], object.profileText);
}

MemoModelCreatorDb _memoModelCreatorDbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MemoModelCreatorDb();
  object.actions = reader.readLong(offsets[0]);
  object.balanceBch = reader.readLong(offsets[1]);
  object.balanceMemo = reader.readLong(offsets[2]);
  object.balanceToken = reader.readLong(offsets[3]);
  object.bchAddressCashtokenAware = reader.readString(offsets[4]);
  object.created = reader.readString(offsets[5]);
  object.creatorId = reader.readString(offsets[6]);
  object.followerCount = reader.readLong(offsets[7]);
  object.hasRegisteredAsUser = reader.readBool(offsets[8]);
  object.lastActionDate = reader.readString(offsets[9]);
  object.lastUpdated = reader.readDateTime(offsets[10]);
  object.name = reader.readString(offsets[11]);
  object.profileImgurUrl = reader.readStringOrNull(offsets[12]);
  object.profileText = reader.readString(offsets[13]);
  return object;
}

P _memoModelCreatorDbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _memoModelCreatorDbGetId(MemoModelCreatorDb object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _memoModelCreatorDbGetLinks(
  MemoModelCreatorDb object,
) {
  return [];
}

void _memoModelCreatorDbAttach(
  IsarCollection<dynamic> col,
  Id id,
  MemoModelCreatorDb object,
) {}

extension MemoModelCreatorDbByIndex on IsarCollection<MemoModelCreatorDb> {
  Future<MemoModelCreatorDb?> getByCreatorId(String creatorId) {
    return getByIndex(r'creatorId', [creatorId]);
  }

  MemoModelCreatorDb? getByCreatorIdSync(String creatorId) {
    return getByIndexSync(r'creatorId', [creatorId]);
  }

  Future<bool> deleteByCreatorId(String creatorId) {
    return deleteByIndex(r'creatorId', [creatorId]);
  }

  bool deleteByCreatorIdSync(String creatorId) {
    return deleteByIndexSync(r'creatorId', [creatorId]);
  }

  Future<List<MemoModelCreatorDb?>> getAllByCreatorId(
    List<String> creatorIdValues,
  ) {
    final values = creatorIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'creatorId', values);
  }

  List<MemoModelCreatorDb?> getAllByCreatorIdSync(
    List<String> creatorIdValues,
  ) {
    final values = creatorIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'creatorId', values);
  }

  Future<int> deleteAllByCreatorId(List<String> creatorIdValues) {
    final values = creatorIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'creatorId', values);
  }

  int deleteAllByCreatorIdSync(List<String> creatorIdValues) {
    final values = creatorIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'creatorId', values);
  }

  Future<Id> putByCreatorId(MemoModelCreatorDb object) {
    return putByIndex(r'creatorId', object);
  }

  Id putByCreatorIdSync(MemoModelCreatorDb object, {bool saveLinks = true}) {
    return putByIndexSync(r'creatorId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCreatorId(List<MemoModelCreatorDb> objects) {
    return putAllByIndex(r'creatorId', objects);
  }

  List<Id> putAllByCreatorIdSync(
    List<MemoModelCreatorDb> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'creatorId', objects, saveLinks: saveLinks);
  }
}

extension MemoModelCreatorDbQueryWhereSort
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QWhere> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MemoModelCreatorDbQueryWhere
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QWhereClause> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
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

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
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

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
  creatorIdEqualTo(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'creatorId', value: [creatorId]),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterWhereClause>
  creatorIdNotEqualTo(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId',
                lower: [],
                upper: [creatorId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId',
                lower: [creatorId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId',
                lower: [creatorId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId',
                lower: [],
                upper: [creatorId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MemoModelCreatorDbQueryFilter
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QFilterCondition> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  actionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'actions', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  actionsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actions',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  actionsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actions',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  actionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceBchEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'balanceBch', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceBchGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceBch',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceBchLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceBch',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceBchBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceBch',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceMemoEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'balanceMemo', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceMemoGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceMemo',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceMemoLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceMemo',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceMemoBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceMemo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceTokenEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'balanceToken', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceTokenGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balanceToken',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceTokenLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balanceToken',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  balanceTokenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balanceToken',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bchAddressCashtokenAware',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'bchAddressCashtokenAware',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'bchAddressCashtokenAware',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bchAddressCashtokenAware',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  bchAddressCashtokenAwareIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'bchAddressCashtokenAware',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'created',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'created',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'created',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  createdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'created', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'creatorId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'creatorId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'creatorId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'creatorId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  creatorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'creatorId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  followerCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'followerCount', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  followerCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'followerCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  followerCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'followerCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  followerCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'followerCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  hasRegisteredAsUserEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasRegisteredAsUser', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastActionDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastActionDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastActionDate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastActionDate', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastActionDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastActionDate', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdated', value: value),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastUpdatedGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUpdated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastUpdatedLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUpdated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUpdated',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'profileImgurUrl'),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'profileImgurUrl'),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profileImgurUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'profileImgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'profileImgurUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'profileImgurUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileImgurUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'profileImgurUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profileText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'profileText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'profileText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'profileText', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterFilterCondition>
  profileTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'profileText', value: ''),
      );
    });
  }
}

extension MemoModelCreatorDbQueryObject
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QFilterCondition> {}

extension MemoModelCreatorDbQueryLinks
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QFilterCondition> {}

extension MemoModelCreatorDbQuerySortBy
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QSortBy> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByActions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actions', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByActionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actions', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceBch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceBch', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceBchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceBch', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceMemo', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceMemo', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceToken', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBalanceTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceToken', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBchAddressCashtokenAware() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bchAddressCashtokenAware', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByBchAddressCashtokenAwareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bchAddressCashtokenAware', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByFollowerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followerCount', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByFollowerCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followerCount', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByHasRegisteredAsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRegisteredAsUser', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByHasRegisteredAsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRegisteredAsUser', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByLastActionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActionDate', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByLastActionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActionDate', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByProfileImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileImgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByProfileImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileImgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByProfileText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileText', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  sortByProfileTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileText', Sort.desc);
    });
  }
}

extension MemoModelCreatorDbQuerySortThenBy
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QSortThenBy> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByActions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actions', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByActionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actions', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceBch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceBch', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceBchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceBch', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceMemo', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceMemo', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceToken', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBalanceTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balanceToken', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBchAddressCashtokenAware() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bchAddressCashtokenAware', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByBchAddressCashtokenAwareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bchAddressCashtokenAware', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByFollowerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followerCount', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByFollowerCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followerCount', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByHasRegisteredAsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRegisteredAsUser', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByHasRegisteredAsUserDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasRegisteredAsUser', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByLastActionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActionDate', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByLastActionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastActionDate', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByProfileImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileImgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByProfileImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileImgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByProfileText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileText', Sort.asc);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QAfterSortBy>
  thenByProfileTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileText', Sort.desc);
    });
  }
}

extension MemoModelCreatorDbQueryWhereDistinct
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct> {
  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByActions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actions');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByBalanceBch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceBch');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByBalanceMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceMemo');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByBalanceToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balanceToken');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByBchAddressCashtokenAware({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'bchAddressCashtokenAware',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByCreated({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByCreatorId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByFollowerCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followerCount');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByHasRegisteredAsUser() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasRegisteredAsUser');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByLastActionDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastActionDate',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByProfileImgurUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'profileImgurUrl',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QDistinct>
  distinctByProfileText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileText', caseSensitive: caseSensitive);
    });
  }
}

extension MemoModelCreatorDbQueryProperty
    on QueryBuilder<MemoModelCreatorDb, MemoModelCreatorDb, QQueryProperty> {
  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations> actionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actions');
    });
  }

  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations> balanceBchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceBch');
    });
  }

  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations>
  balanceMemoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceMemo');
    });
  }

  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations>
  balanceTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balanceToken');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations>
  bchAddressCashtokenAwareProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bchAddressCashtokenAware');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations> createdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations>
  creatorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatorId');
    });
  }

  QueryBuilder<MemoModelCreatorDb, int, QQueryOperations>
  followerCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followerCount');
    });
  }

  QueryBuilder<MemoModelCreatorDb, bool, QQueryOperations>
  hasRegisteredAsUserProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasRegisteredAsUser');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations>
  lastActionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastActionDate');
    });
  }

  QueryBuilder<MemoModelCreatorDb, DateTime, QQueryOperations>
  lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String?, QQueryOperations>
  profileImgurUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileImgurUrl');
    });
  }

  QueryBuilder<MemoModelCreatorDb, String, QQueryOperations>
  profileTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileText');
    });
  }
}
