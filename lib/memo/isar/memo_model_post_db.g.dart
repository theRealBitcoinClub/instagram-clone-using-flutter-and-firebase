// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_post_db.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMemoModelPostDbCollection on Isar {
  IsarCollection<MemoModelPostDb> get memoModelPostDbs => this.collection();
}

const MemoModelPostDbSchema = CollectionSchema(
  name: r'MemoModelPostDb',
  id: -1343087391362424624,
  properties: {
    r'cachedAt': PropertySchema(id: 0, name: r'cachedAt', type: IsarType.dateTime),
    r'createdDateTime': PropertySchema(id: 1, name: r'createdDateTime', type: IsarType.dateTime),
    r'createdString': PropertySchema(id: 2, name: r'createdString', type: IsarType.string),
    r'creatorId': PropertySchema(id: 3, name: r'creatorId', type: IsarType.string),
    r'id': PropertySchema(id: 4, name: r'id', type: IsarType.string),
    r'imgurUrl': PropertySchema(id: 5, name: r'imgurUrl', type: IsarType.string),
    r'isExpired': PropertySchema(id: 6, name: r'isExpired', type: IsarType.bool),
    r'likeCounter': PropertySchema(id: 7, name: r'likeCounter', type: IsarType.long),
    r'popularityScore': PropertySchema(id: 8, name: r'popularityScore', type: IsarType.long),
    r'replyCounter': PropertySchema(id: 9, name: r'replyCounter', type: IsarType.long),
    r'tagIds': PropertySchema(id: 10, name: r'tagIds', type: IsarType.stringList),
    r'text': PropertySchema(id: 11, name: r'text', type: IsarType.string),
    r'topicId': PropertySchema(id: 12, name: r'topicId', type: IsarType.string),
    r'youtubeId': PropertySchema(id: 13, name: r'youtubeId', type: IsarType.string),
  },

  estimateSize: _memoModelPostDbEstimateSize,
  serialize: _memoModelPostDbSerialize,
  deserialize: _memoModelPostDbDeserialize,
  deserializeProp: _memoModelPostDbDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: false,
      properties: [IndexPropertySchema(name: r'id', type: IndexType.hash, caseSensitive: true)],
    ),
    r'createdDateTime': IndexSchema(
      id: -7495820842331859050,
      name: r'createdDateTime',
      unique: false,
      replace: false,
      properties: [IndexPropertySchema(name: r'createdDateTime', type: IndexType.value, caseSensitive: false)],
    ),
    r'creatorId_createdDateTime': IndexSchema(
      id: -384750498084091462,
      name: r'creatorId_createdDateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(name: r'creatorId', type: IndexType.hash, caseSensitive: true),
        IndexPropertySchema(name: r'createdDateTime', type: IndexType.value, caseSensitive: false),
      ],
    ),
    r'topicId_createdDateTime': IndexSchema(
      id: -7365936640674833067,
      name: r'topicId_createdDateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(name: r'topicId', type: IndexType.hash, caseSensitive: true),
        IndexPropertySchema(name: r'createdDateTime', type: IndexType.value, caseSensitive: false),
      ],
    ),
    r'tagIds': IndexSchema(
      id: 4953378336043540110,
      name: r'tagIds',
      unique: false,
      replace: false,
      properties: [IndexPropertySchema(name: r'tagIds', type: IndexType.hash, caseSensitive: true)],
    ),
    r'cachedAt': IndexSchema(
      id: -699654806693614168,
      name: r'cachedAt',
      unique: false,
      replace: false,
      properties: [IndexPropertySchema(name: r'cachedAt', type: IndexType.value, caseSensitive: false)],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _memoModelPostDbGetId,
  getLinks: _memoModelPostDbGetLinks,
  attach: _memoModelPostDbAttach,
  version: '3.3.0-dev.1',
);

int _memoModelPostDbEstimateSize(MemoModelPostDb object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  {
    final value = object.createdString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.creatorId.length * 3;
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.imgurUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tagIds.length * 3;
  {
    for (var i = 0; i < object.tagIds.length; i++) {
      final value = object.tagIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.text;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.topicId.length * 3;
  {
    final value = object.youtubeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _memoModelPostDbSerialize(MemoModelPostDb object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeDateTime(offsets[1], object.createdDateTime);
  writer.writeString(offsets[2], object.createdString);
  writer.writeString(offsets[3], object.creatorId);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.imgurUrl);
  writer.writeBool(offsets[6], object.isExpired);
  writer.writeLong(offsets[7], object.likeCounter);
  writer.writeLong(offsets[8], object.popularityScore);
  writer.writeLong(offsets[9], object.replyCounter);
  writer.writeStringList(offsets[10], object.tagIds);
  writer.writeString(offsets[11], object.text);
  writer.writeString(offsets[12], object.topicId);
  writer.writeString(offsets[13], object.youtubeId);
}

MemoModelPostDb _memoModelPostDbDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = MemoModelPostDb();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.createdDateTime = reader.readDateTimeOrNull(offsets[1]);
  object.createdString = reader.readStringOrNull(offsets[2]);
  object.creatorId = reader.readString(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.imgurUrl = reader.readStringOrNull(offsets[5]);
  object.likeCounter = reader.readLongOrNull(offsets[7]);
  object.popularityScore = reader.readLong(offsets[8]);
  object.replyCounter = reader.readLongOrNull(offsets[9]);
  object.tagIds = reader.readStringList(offsets[10]) ?? [];
  object.text = reader.readStringOrNull(offsets[11]);
  object.topicId = reader.readString(offsets[12]);
  object.youtubeId = reader.readStringOrNull(offsets[13]);
  return object;
}

P _memoModelPostDbDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringList(offset) ?? []) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _memoModelPostDbGetId(MemoModelPostDb object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _memoModelPostDbGetLinks(MemoModelPostDb object) {
  return [];
}

void _memoModelPostDbAttach(IsarCollection<dynamic> col, Id id, MemoModelPostDb object) {}

extension MemoModelPostDbByIndex on IsarCollection<MemoModelPostDb> {
  Future<MemoModelPostDb?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  MemoModelPostDb? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<MemoModelPostDb?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<MemoModelPostDb?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(MemoModelPostDb object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(MemoModelPostDb object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<MemoModelPostDb> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<MemoModelPostDb> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension MemoModelPostDbQueryWhereSort on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QWhere> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere> anyCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IndexWhereClause.any(indexName: r'createdDateTime'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere> anyCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IndexWhereClause.any(indexName: r'cachedAt'));
    });
  }
}

extension MemoModelPostDbQueryWhere on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QWhereClause> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: isarId, upper: isarId));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false))
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false));
      } else {
        return query
            .addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: false))
            .addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: isarId, includeLower: include));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: isarId, includeUpper: include));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: lowerIsarId, includeLower: includeLower, upper: upperIsarId, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'id', value: [id]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'id', lower: [], upper: [id], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'id', lower: [id], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'id', lower: [id], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'id', lower: [], upper: [id], includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'createdDateTime', value: [null]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(indexName: r'createdDateTime', lower: [null], includeLower: false, upper: []));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeEqualTo(DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'createdDateTime', value: [createdDateTime]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeNotEqualTo(DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'createdDateTime', lower: [], upper: [createdDateTime], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'createdDateTime', lower: [createdDateTime], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'createdDateTime', lower: [createdDateTime], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'createdDateTime', lower: [], upper: [createdDateTime], includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeGreaterThan(
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'createdDateTime', lower: [createdDateTime], includeLower: include, upper: []),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeLessThan(DateTime? createdDateTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'createdDateTime', lower: [], upper: [createdDateTime], includeUpper: include),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> createdDateTimeBetween(
    DateTime? lowerCreatedDateTime,
    DateTime? upperCreatedDateTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdDateTime',
          lower: [lowerCreatedDateTime],
          includeLower: includeLower,
          upper: [upperCreatedDateTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToAnyCreatedDateTime(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'creatorId_createdDateTime', value: [creatorId]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdNotEqualToAnyCreatedDateTime(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(indexName: r'creatorId_createdDateTime', lower: [], upper: [creatorId], includeUpper: false),
            )
            .addWhereClause(
              IndexWhereClause.between(indexName: r'creatorId_createdDateTime', lower: [creatorId], includeLower: false, upper: []),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(indexName: r'creatorId_createdDateTime', lower: [creatorId], includeLower: false, upper: []),
            )
            .addWhereClause(
              IndexWhereClause.between(indexName: r'creatorId_createdDateTime', lower: [], upper: [creatorId], includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeIsNull(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'creatorId_createdDateTime', value: [creatorId, null]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeIsNotNull(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'creatorId_createdDateTime', lower: [creatorId, null], includeLower: false, upper: [creatorId]),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdCreatedDateTimeEqualTo(
    String creatorId,
    DateTime? createdDateTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'creatorId_createdDateTime', value: [creatorId, createdDateTime]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeNotEqualTo(
    String creatorId,
    DateTime? createdDateTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId],
                upper: [creatorId, createdDateTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId, createdDateTime],
                includeLower: false,
                upper: [creatorId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId, createdDateTime],
                includeLower: false,
                upper: [creatorId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId],
                upper: [creatorId, createdDateTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeGreaterThan(
    String creatorId,
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creatorId_createdDateTime',
          lower: [creatorId, createdDateTime],
          includeLower: include,
          upper: [creatorId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeLessThan(
    String creatorId,
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creatorId_createdDateTime',
          lower: [creatorId],
          upper: [creatorId, createdDateTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> creatorIdEqualToCreatedDateTimeBetween(
    String creatorId,
    DateTime? lowerCreatedDateTime,
    DateTime? upperCreatedDateTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creatorId_createdDateTime',
          lower: [creatorId, lowerCreatedDateTime],
          includeLower: includeLower,
          upper: [creatorId, upperCreatedDateTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToAnyCreatedDateTime(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'topicId_createdDateTime', value: [topicId]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdNotEqualToAnyCreatedDateTime(String topicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'topicId_createdDateTime', lower: [], upper: [topicId], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'topicId_createdDateTime', lower: [topicId], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'topicId_createdDateTime', lower: [topicId], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'topicId_createdDateTime', lower: [], upper: [topicId], includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeIsNull(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'topicId_createdDateTime', value: [topicId, null]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeIsNotNull(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(indexName: r'topicId_createdDateTime', lower: [topicId, null], includeLower: false, upper: [topicId]),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdCreatedDateTimeEqualTo(String topicId, DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'topicId_createdDateTime', value: [topicId, createdDateTime]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeNotEqualTo(
    String topicId,
    DateTime? createdDateTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId],
                upper: [topicId, createdDateTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId, createdDateTime],
                includeLower: false,
                upper: [topicId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId, createdDateTime],
                includeLower: false,
                upper: [topicId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId],
                upper: [topicId, createdDateTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeGreaterThan(
    String topicId,
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_createdDateTime',
          lower: [topicId, createdDateTime],
          includeLower: include,
          upper: [topicId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeLessThan(
    String topicId,
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_createdDateTime',
          lower: [topicId],
          upper: [topicId, createdDateTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> topicIdEqualToCreatedDateTimeBetween(
    String topicId,
    DateTime? lowerCreatedDateTime,
    DateTime? upperCreatedDateTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_createdDateTime',
          lower: [topicId, lowerCreatedDateTime],
          includeLower: includeLower,
          upper: [topicId, upperCreatedDateTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> tagIdsEqualTo(List<String> tagIds) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'tagIds', value: [tagIds]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> tagIdsNotEqualTo(List<String> tagIds) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'tagIds', lower: [], upper: [tagIds], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'tagIds', lower: [tagIds], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'tagIds', lower: [tagIds], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'tagIds', lower: [], upper: [tagIds], includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> cachedAtEqualTo(DateTime cachedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'cachedAt', value: [cachedAt]));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> cachedAtNotEqualTo(DateTime cachedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [], upper: [cachedAt], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [cachedAt], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [cachedAt], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [], upper: [cachedAt], includeUpper: false));
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> cachedAtGreaterThan(DateTime cachedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [cachedAt], includeLower: include, upper: []));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> cachedAtLessThan(DateTime cachedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(indexName: r'cachedAt', lower: [], upper: [cachedAt], includeUpper: include));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> cachedAtBetween(
    DateTime lowerCachedAt,
    DateTime upperCachedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'cachedAt',
          lower: [lowerCachedAt],
          includeLower: includeLower,
          upper: [upperCachedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MemoModelPostDbQueryFilter on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> cachedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> cachedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(property: r'cachedAt', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'createdDateTime'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'createdDateTime'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'createdDateTime', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'createdDateTime', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'createdDateTime', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdDateTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdDateTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'createdString'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'createdString'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'createdString', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'createdString', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'createdString', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdString',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'createdString', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'createdString', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'createdString', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'createdString', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'createdString', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> createdStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'createdString', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'creatorId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'creatorId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'creatorId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'creatorId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'creatorId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'creatorId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'creatorId', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'creatorId', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> creatorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'creatorId', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'id', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'id', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'id', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'id', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'id', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'id', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'id', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'id', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'id', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'imgurUrl'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'imgurUrl'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'imgurUrl', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'imgurUrl', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'imgurUrl', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imgurUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'imgurUrl', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'imgurUrl', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'imgurUrl', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'imgurUrl', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'imgurUrl', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> imgurUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'imgurUrl', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isExpired', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'isarId', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'isarId', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(property: r'isarId', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'likeCounter'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'likeCounter'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'likeCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'likeCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'likeCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> likeCounterBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(property: r'likeCounter', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'popularityScore'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'popularityScore'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'popularityScore', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'popularityScore', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'popularityScore', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> popularityScoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'popularityScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'replyCounter'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'replyCounter'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'replyCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'replyCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'replyCounter', value: value));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> replyCounterBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(property: r'replyCounter', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'tagIds', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'tagIds', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'tagIds', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tagIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'tagIds', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'tagIds', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'tagIds', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'tagIds', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'tagIds', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'tagIds', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', length, true, length, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, true, 0, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, true, length, include);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', length, include, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> tagIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'text'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'text'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'text', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'text', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'text', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'text', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'text', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'text', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'text', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'text', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'text', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'topicId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'topicId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'topicId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'topicId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'topicId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'topicId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'topicId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'topicId', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'topicId', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'topicId', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'youtubeId'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'youtubeId'));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'youtubeId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(include: include, property: r'youtubeId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(include: include, property: r'youtubeId', value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'youtubeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'youtubeId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'youtubeId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'youtubeId', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'youtubeId', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'youtubeId', value: ''));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition> youtubeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'youtubeId', value: ''));
    });
  }
}

extension MemoModelPostDbQueryObject on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {}

extension MemoModelPostDbQueryLinks on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {}

extension MemoModelPostDbQuerySortBy on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QSortBy> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatedDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatedString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdString', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatedStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdString', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByLikeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByPopularityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByReplyCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension MemoModelPostDbQuerySortThenBy on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QSortThenBy> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatedDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatedString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdString', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatedStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdString', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByLikeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByPopularityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByReplyCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension MemoModelPostDbQueryWhereDistinct on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdDateTime');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByCreatedString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByCreatorId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByImgurUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imgurUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'likeCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'popularityScore');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByTagIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagIds');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByTopicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByYoutubeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'youtubeId', caseSensitive: caseSensitive);
    });
  }
}

extension MemoModelPostDbQueryProperty on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QQueryProperty> {
  QueryBuilder<MemoModelPostDb, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<MemoModelPostDb, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<MemoModelPostDb, DateTime?, QQueryOperations> createdDateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdDateTime');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> createdStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdString');
    });
  }

  QueryBuilder<MemoModelPostDb, String, QQueryOperations> creatorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatorId');
    });
  }

  QueryBuilder<MemoModelPostDb, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> imgurUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imgurUrl');
    });
  }

  QueryBuilder<MemoModelPostDb, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<MemoModelPostDb, int?, QQueryOperations> likeCounterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'likeCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, int?, QQueryOperations> popularityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'popularityScore');
    });
  }

  QueryBuilder<MemoModelPostDb, int?, QQueryOperations> replyCounterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, List<String>, QQueryOperations> tagIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagIds');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<MemoModelPostDb, String, QQueryOperations> topicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topicId');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> youtubeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'youtubeId');
    });
  }
}
