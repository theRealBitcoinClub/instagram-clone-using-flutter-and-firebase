import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

part 'memo_model_creator_db.g.dart';

@Collection()
class MemoModelCreatorDb {
  Id get id => creatorId.hashCode;

  @Index(unique: true)
  late String creatorId;

  // All serializable fields from MemoModelCreator
  late String name;
  late String profileText;
  late int followerCount;
  late int actions;
  late String created;
  late String lastActionDate;
  late String? profileImgurUrl;

  // Non-serializable String and Int fields
  late int balanceBch;
  late int balanceMemo;
  late int balanceToken;
  late bool hasRegisteredAsUser;
  late String bchAddressCashtokenAware;

  // Additional cache metadata
  late DateTime lastUpdated;

  MemoModelCreatorDb();

  // Convert from app model to DB model
  factory MemoModelCreatorDb.fromAppModel(MemoModelCreator creator) {
    return MemoModelCreatorDb()
      ..creatorId = creator.id
      ..name = creator.name
      ..profileText = creator.profileText
      ..followerCount = creator.followerCount
      ..actions = creator.actions
      ..created = creator.created
      ..lastActionDate = creator.lastActionDate
      ..profileImgurUrl = creator.profileImgurUrl
      ..balanceBch = creator.balanceBch
      ..balanceMemo = creator.balanceMemo
      ..balanceToken = creator.balanceToken
      ..hasRegisteredAsUser = creator.hasRegisteredAsUser
      ..bchAddressCashtokenAware = creator.bchAddressCashtokenAware
      ..lastUpdated = DateTime.now();
  }

  // Convert back to app model
  MemoModelCreator toAppModel() {
    final creator = MemoModelCreator(
      id: creatorId,
      name: name,
      profileText: profileText,
      followerCount: followerCount,
      actions: actions,
      created: created,
      lastActionDate: lastActionDate,
      profileImgurUrl: profileImgurUrl,
    );

    // Set the non-serializable fields
    creator.balanceBch = balanceBch;
    creator.balanceMemo = balanceMemo;
    creator.balanceToken = balanceToken;
    creator.bchAddressCashtokenAware = bchAddressCashtokenAware;
    creator.hasRegisteredAsUser = hasRegisteredAsUser;

    return creator;
  }
}
