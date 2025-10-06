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
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'created': PropertySchema(id: 1, name: r'created', type: IsarType.string),
    r'createdDateTime': PropertySchema(
      id: 2,
      name: r'createdDateTime',
      type: IsarType.dateTime,
    ),
    r'creatorId': PropertySchema(
      id: 3,
      name: r'creatorId',
      type: IsarType.string,
    ),
    r'hideOnFeed': PropertySchema(
      id: 4,
      name: r'hideOnFeed',
      type: IsarType.bool,
    ),
    r'imageUrl': PropertySchema(
      id: 5,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'imgurUrl': PropertySchema(
      id: 6,
      name: r'imgurUrl',
      type: IsarType.string,
    ),
    r'ipfsCid': PropertySchema(id: 7, name: r'ipfsCid', type: IsarType.string),
    r'likeCounter': PropertySchema(
      id: 8,
      name: r'likeCounter',
      type: IsarType.long,
    ),
    r'popularityScore': PropertySchema(
      id: 9,
      name: r'popularityScore',
      type: IsarType.long,
    ),
    r'postId': PropertySchema(id: 10, name: r'postId', type: IsarType.string),
    r'postType': PropertySchema(id: 11, name: r'postType', type: IsarType.long),
    r'replyCounter': PropertySchema(
      id: 12,
      name: r'replyCounter',
      type: IsarType.long,
    ),
    r'showOnFeed': PropertySchema(
      id: 13,
      name: r'showOnFeed',
      type: IsarType.bool,
    ),
    r'tagIds': PropertySchema(
      id: 14,
      name: r'tagIds',
      type: IsarType.stringList,
    ),
    r'text': PropertySchema(id: 15, name: r'text', type: IsarType.string),
    r'topicId': PropertySchema(id: 16, name: r'topicId', type: IsarType.string),
    r'urls': PropertySchema(id: 17, name: r'urls', type: IsarType.stringList),
    r'videoUrl': PropertySchema(
      id: 18,
      name: r'videoUrl',
      type: IsarType.string,
    ),
    r'youtubeId': PropertySchema(
      id: 19,
      name: r'youtubeId',
      type: IsarType.string,
    ),
  },

  estimateSize: _memoModelPostDbEstimateSize,
  serialize: _memoModelPostDbSerialize,
  deserialize: _memoModelPostDbDeserialize,
  deserializeProp: _memoModelPostDbDeserializeProp,
  idName: r'id',
  indexes: {
    r'postId_postType': IndexSchema(
      id: -8326740468909595309,
      name: r'postId_postType',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'postId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'postType',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'postType': IndexSchema(
      id: -8758045082063951263,
      name: r'postType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'postType',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'createdDateTime': IndexSchema(
      id: -7495820842331859050,
      name: r'createdDateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdDateTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'creatorId_createdDateTime': IndexSchema(
      id: -384750498084091462,
      name: r'creatorId_createdDateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'creatorId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'createdDateTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'topicId_createdDateTime': IndexSchema(
      id: -7365936640674833067,
      name: r'topicId_createdDateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'topicId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'createdDateTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'tagIds': IndexSchema(
      id: 4953378336043540110,
      name: r'tagIds',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tagIds',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _memoModelPostDbGetId,
  getLinks: _memoModelPostDbGetLinks,
  attach: _memoModelPostDbAttach,
  version: '3.3.0-dev.1',
);

int _memoModelPostDbEstimateSize(
  MemoModelPostDb object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.created;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.creatorId.length * 3;
  {
    final value = object.imageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imgurUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ipfsCid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.postId.length * 3;
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
  bytesCount += 3 + object.urls.length * 3;
  {
    for (var i = 0; i < object.urls.length; i++) {
      final value = object.urls[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.videoUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.youtubeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _memoModelPostDbSerialize(
  MemoModelPostDb object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.created);
  writer.writeDateTime(offsets[2], object.createdDateTime);
  writer.writeString(offsets[3], object.creatorId);
  writer.writeBool(offsets[4], object.hideOnFeed);
  writer.writeString(offsets[5], object.imageUrl);
  writer.writeString(offsets[6], object.imgurUrl);
  writer.writeString(offsets[7], object.ipfsCid);
  writer.writeLong(offsets[8], object.likeCounter);
  writer.writeLong(offsets[9], object.popularityScore);
  writer.writeString(offsets[10], object.postId);
  writer.writeLong(offsets[11], object.postType);
  writer.writeLong(offsets[12], object.replyCounter);
  writer.writeBool(offsets[13], object.showOnFeed);
  writer.writeStringList(offsets[14], object.tagIds);
  writer.writeString(offsets[15], object.text);
  writer.writeString(offsets[16], object.topicId);
  writer.writeStringList(offsets[17], object.urls);
  writer.writeString(offsets[18], object.videoUrl);
  writer.writeString(offsets[19], object.youtubeId);
}

MemoModelPostDb _memoModelPostDbDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MemoModelPostDb();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.created = reader.readStringOrNull(offsets[1]);
  object.createdDateTime = reader.readDateTimeOrNull(offsets[2]);
  object.creatorId = reader.readString(offsets[3]);
  object.hideOnFeed = reader.readBoolOrNull(offsets[4]);
  object.id = id;
  object.imageUrl = reader.readStringOrNull(offsets[5]);
  object.imgurUrl = reader.readStringOrNull(offsets[6]);
  object.ipfsCid = reader.readStringOrNull(offsets[7]);
  object.likeCounter = reader.readLongOrNull(offsets[8]);
  object.popularityScore = reader.readLong(offsets[9]);
  object.postId = reader.readString(offsets[10]);
  object.postType = reader.readLong(offsets[11]);
  object.replyCounter = reader.readLongOrNull(offsets[12]);
  object.showOnFeed = reader.readBoolOrNull(offsets[13]);
  object.tagIds = reader.readStringList(offsets[14]) ?? [];
  object.text = reader.readStringOrNull(offsets[15]);
  object.topicId = reader.readString(offsets[16]);
  object.urls = reader.readStringList(offsets[17]) ?? [];
  object.videoUrl = reader.readStringOrNull(offsets[18]);
  object.youtubeId = reader.readStringOrNull(offsets[19]);
  return object;
}

P _memoModelPostDbDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readBoolOrNull(offset)) as P;
    case 14:
      return (reader.readStringList(offset) ?? []) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readStringList(offset) ?? []) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _memoModelPostDbGetId(MemoModelPostDb object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _memoModelPostDbGetLinks(MemoModelPostDb object) {
  return [];
}

void _memoModelPostDbAttach(
  IsarCollection<dynamic> col,
  Id id,
  MemoModelPostDb object,
) {
  object.id = id;
}

extension MemoModelPostDbByIndex on IsarCollection<MemoModelPostDb> {
  Future<MemoModelPostDb?> getByPostIdPostType(String postId, int postType) {
    return getByIndex(r'postId_postType', [postId, postType]);
  }

  MemoModelPostDb? getByPostIdPostTypeSync(String postId, int postType) {
    return getByIndexSync(r'postId_postType', [postId, postType]);
  }

  Future<bool> deleteByPostIdPostType(String postId, int postType) {
    return deleteByIndex(r'postId_postType', [postId, postType]);
  }

  bool deleteByPostIdPostTypeSync(String postId, int postType) {
    return deleteByIndexSync(r'postId_postType', [postId, postType]);
  }

  Future<List<MemoModelPostDb?>> getAllByPostIdPostType(
    List<String> postIdValues,
    List<int> postTypeValues,
  ) {
    final len = postIdValues.length;
    assert(
      postTypeValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([postIdValues[i], postTypeValues[i]]);
    }

    return getAllByIndex(r'postId_postType', values);
  }

  List<MemoModelPostDb?> getAllByPostIdPostTypeSync(
    List<String> postIdValues,
    List<int> postTypeValues,
  ) {
    final len = postIdValues.length;
    assert(
      postTypeValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([postIdValues[i], postTypeValues[i]]);
    }

    return getAllByIndexSync(r'postId_postType', values);
  }

  Future<int> deleteAllByPostIdPostType(
    List<String> postIdValues,
    List<int> postTypeValues,
  ) {
    final len = postIdValues.length;
    assert(
      postTypeValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([postIdValues[i], postTypeValues[i]]);
    }

    return deleteAllByIndex(r'postId_postType', values);
  }

  int deleteAllByPostIdPostTypeSync(
    List<String> postIdValues,
    List<int> postTypeValues,
  ) {
    final len = postIdValues.length;
    assert(
      postTypeValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([postIdValues[i], postTypeValues[i]]);
    }

    return deleteAllByIndexSync(r'postId_postType', values);
  }

  Future<Id> putByPostIdPostType(MemoModelPostDb object) {
    return putByIndex(r'postId_postType', object);
  }

  Id putByPostIdPostTypeSync(MemoModelPostDb object, {bool saveLinks = true}) {
    return putByIndexSync(r'postId_postType', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPostIdPostType(List<MemoModelPostDb> objects) {
    return putAllByIndex(r'postId_postType', objects);
  }

  List<Id> putAllByPostIdPostTypeSync(
    List<MemoModelPostDb> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'postId_postType', objects, saveLinks: saveLinks);
  }
}

extension MemoModelPostDbQueryWhereSort
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QWhere> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere> anyPostType() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'postType'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhere>
  anyCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdDateTime'),
      );
    });
  }
}

extension MemoModelPostDbQueryWhere
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QWhereClause> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause> idBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdEqualToAnyPostType(String postId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'postId_postType',
          value: [postId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdNotEqualToAnyPostType(String postId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [],
                upper: [postId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [],
                upper: [postId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdPostTypeEqualTo(String postId, int postType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'postId_postType',
          value: [postId, postType],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdEqualToPostTypeNotEqualTo(String postId, int postType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId],
                upper: [postId, postType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId, postType],
                includeLower: false,
                upper: [postId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId, postType],
                includeLower: false,
                upper: [postId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postId_postType',
                lower: [postId],
                upper: [postId, postType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdEqualToPostTypeGreaterThan(
    String postId,
    int postType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postId_postType',
          lower: [postId, postType],
          includeLower: include,
          upper: [postId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdEqualToPostTypeLessThan(
    String postId,
    int postType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postId_postType',
          lower: [postId],
          upper: [postId, postType],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postIdEqualToPostTypeBetween(
    String postId,
    int lowerPostType,
    int upperPostType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postId_postType',
          lower: [postId, lowerPostType],
          includeLower: includeLower,
          upper: [postId, upperPostType],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postTypeEqualTo(int postType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'postType', value: [postType]),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postTypeNotEqualTo(int postType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postType',
                lower: [],
                upper: [postType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postType',
                lower: [postType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postType',
                lower: [postType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'postType',
                lower: [],
                upper: [postType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postTypeGreaterThan(int postType, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postType',
          lower: [postType],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postTypeLessThan(int postType, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postType',
          lower: [],
          upper: [postType],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  postTypeBetween(
    int lowerPostType,
    int upperPostType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'postType',
          lower: [lowerPostType],
          includeLower: includeLower,
          upper: [upperPostType],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdDateTime', value: [null]),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdDateTime',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeEqualTo(DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'createdDateTime',
          value: [createdDateTime],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeNotEqualTo(DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdDateTime',
                lower: [],
                upper: [createdDateTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdDateTime',
                lower: [createdDateTime],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdDateTime',
                lower: [createdDateTime],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdDateTime',
                lower: [],
                upper: [createdDateTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeGreaterThan(
    DateTime? createdDateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdDateTime',
          lower: [createdDateTime],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeLessThan(DateTime? createdDateTime, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdDateTime',
          lower: [],
          upper: [createdDateTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  createdDateTimeBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToAnyCreatedDateTime(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'creatorId_createdDateTime',
          value: [creatorId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdNotEqualToAnyCreatedDateTime(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [],
                upper: [creatorId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [creatorId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'creatorId_createdDateTime',
                lower: [],
                upper: [creatorId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeIsNull(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'creatorId_createdDateTime',
          value: [creatorId, null],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeIsNotNull(String creatorId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'creatorId_createdDateTime',
          lower: [creatorId, null],
          includeLower: false,
          upper: [creatorId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdCreatedDateTimeEqualTo(String creatorId, DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'creatorId_createdDateTime',
          value: [creatorId, createdDateTime],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeNotEqualTo(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeGreaterThan(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeLessThan(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  creatorIdEqualToCreatedDateTimeBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToAnyCreatedDateTime(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'topicId_createdDateTime',
          value: [topicId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdNotEqualToAnyCreatedDateTime(String topicId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [topicId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'topicId_createdDateTime',
                lower: [],
                upper: [topicId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeIsNull(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'topicId_createdDateTime',
          value: [topicId, null],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeIsNotNull(String topicId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'topicId_createdDateTime',
          lower: [topicId, null],
          includeLower: false,
          upper: [topicId],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdCreatedDateTimeEqualTo(String topicId, DateTime? createdDateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'topicId_createdDateTime',
          value: [topicId, createdDateTime],
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeNotEqualTo(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeGreaterThan(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeLessThan(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  topicIdEqualToCreatedDateTimeBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  tagIdsEqualTo(List<String> tagIds) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'tagIds', value: [tagIds]),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterWhereClause>
  tagIdsNotEqualTo(List<String> tagIds) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tagIds',
                lower: [],
                upper: [tagIds],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tagIds',
                lower: [tagIds],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tagIds',
                lower: [tagIds],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tagIds',
                lower: [],
                upper: [tagIds],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MemoModelPostDbQueryFilter
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cachedAt', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  cachedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cachedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  cachedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cachedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cachedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'created'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'created'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdGreaterThan(
    String? value, {
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdLessThan(
    String? value, {
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'created', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'createdDateTime'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'createdDateTime'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdDateTime', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdDateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdDateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  createdDateTimeBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  creatorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'creatorId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  creatorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'creatorId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  hideOnFeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hideOnFeed'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  hideOnFeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hideOnFeed'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  hideOnFeedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hideOnFeed', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'imageUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'imageUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imageUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imageUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imageUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imageUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imageUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'imgurUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'imgurUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imgurUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imgurUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imgurUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  imgurUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imgurUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ipfsCid'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ipfsCid'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ipfsCid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ipfsCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ipfsCid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ipfsCid', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  ipfsCidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ipfsCid', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'likeCounter'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'likeCounter'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'likeCounter', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'likeCounter',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'likeCounter',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  likeCounterBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'likeCounter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  popularityScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'popularityScore', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  popularityScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'popularityScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  popularityScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'popularityScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  popularityScoreBetween(
    int lower,
    int upper, {
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'postId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'postId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'postType', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postTypeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'postType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postTypeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'postType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  postTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'postType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'replyCounter'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'replyCounter'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'replyCounter', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'replyCounter',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'replyCounter',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  replyCounterBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'replyCounter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  showOnFeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'showOnFeed'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  showOnFeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'showOnFeed'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  showOnFeedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'showOnFeed', value: value),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tagIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tagIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tagIds', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tagIds', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', length, true, length, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, true, 0, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', 0, true, length, include);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tagIds', length, include, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  tagIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tagIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'text'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'text'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'topicId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'topicId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  topicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'topicId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'urls',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'urls',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'urls', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'urls', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'urls', length, true, length, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'urls', 0, true, 0, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'urls', 0, false, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'urls', 0, true, length, include);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'urls', length, include, 999999, true);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  urlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'videoUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'videoUrl'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'videoUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'videoUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'videoUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  videoUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'videoUrl', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'youtubeId'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'youtubeId'),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdBetween(
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'youtubeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'youtubeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'youtubeId', value: ''),
      );
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterFilterCondition>
  youtubeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'youtubeId', value: ''),
      );
    });
  }
}

extension MemoModelPostDbQueryObject
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {}

extension MemoModelPostDbQueryLinks
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QFilterCondition> {}

extension MemoModelPostDbQuerySortBy
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QSortBy> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCreatedDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByHideOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideOnFeed', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByHideOnFeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideOnFeed', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByIpfsCid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipfsCid', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByIpfsCidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipfsCid', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByLikeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByPopularityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByPostType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postType', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByPostTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postType', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByReplyCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByShowOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnFeed', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByShowOnFeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnFeed', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> sortByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByVideoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByVideoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  sortByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension MemoModelPostDbQuerySortThenBy
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QSortThenBy> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCreatedDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdDateTime', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCreatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByCreatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByHideOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideOnFeed', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByHideOnFeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hideOnFeed', Sort.desc);
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

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByImgurUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByImgurUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imgurUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByIpfsCid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipfsCid', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByIpfsCidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ipfsCid', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByLikeCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'likeCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByPopularityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularityScore', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByPostType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postType', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByPostTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postType', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByReplyCounterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCounter', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByShowOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnFeed', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByShowOnFeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showOnFeed', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy> thenByTopicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByTopicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topicId', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByVideoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoUrl', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByVideoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoUrl', Sort.desc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QAfterSortBy>
  thenByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension MemoModelPostDbQueryWhereDistinct
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> {
  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByCreated({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByCreatedDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdDateTime');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByCreatorId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByHideOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hideOnFeed');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByImageUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByImgurUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imgurUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByIpfsCid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ipfsCid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByLikeCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'likeCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByPopularityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'popularityScore');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByPostId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByPostType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postType');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByReplyCounter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByShowOnFeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showOnFeed');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByTagIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagIds');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByTopicId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'urls');
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct> distinctByVideoUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MemoModelPostDb, MemoModelPostDb, QDistinct>
  distinctByYoutubeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'youtubeId', caseSensitive: caseSensitive);
    });
  }
}

extension MemoModelPostDbQueryProperty
    on QueryBuilder<MemoModelPostDb, MemoModelPostDb, QQueryProperty> {
  QueryBuilder<MemoModelPostDb, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MemoModelPostDb, DateTime, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> createdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created');
    });
  }

  QueryBuilder<MemoModelPostDb, DateTime?, QQueryOperations>
  createdDateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdDateTime');
    });
  }

  QueryBuilder<MemoModelPostDb, String, QQueryOperations> creatorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatorId');
    });
  }

  QueryBuilder<MemoModelPostDb, bool?, QQueryOperations> hideOnFeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hideOnFeed');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> imgurUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imgurUrl');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> ipfsCidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ipfsCid');
    });
  }

  QueryBuilder<MemoModelPostDb, int?, QQueryOperations> likeCounterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'likeCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, int, QQueryOperations>
  popularityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'popularityScore');
    });
  }

  QueryBuilder<MemoModelPostDb, String, QQueryOperations> postIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postId');
    });
  }

  QueryBuilder<MemoModelPostDb, int, QQueryOperations> postTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postType');
    });
  }

  QueryBuilder<MemoModelPostDb, int?, QQueryOperations> replyCounterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyCounter');
    });
  }

  QueryBuilder<MemoModelPostDb, bool?, QQueryOperations> showOnFeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showOnFeed');
    });
  }

  QueryBuilder<MemoModelPostDb, List<String>, QQueryOperations>
  tagIdsProperty() {
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

  QueryBuilder<MemoModelPostDb, List<String>, QQueryOperations> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'urls');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> videoUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoUrl');
    });
  }

  QueryBuilder<MemoModelPostDb, String?, QQueryOperations> youtubeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'youtubeId');
    });
  }
}
