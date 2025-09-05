import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_code.dart';
import 'package:mahakka/memo/base/memo_publisher.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/model/memo_tip.dart';
import 'package:mahakka/memo/scraper/memo_post_service.dart';

import '../../provider/user_provider.dart';
import '../../repositories/post_cache_repository.dart';
import 'memo_bitcoin_base.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse {
  yes(""),
  noUtxo("Transaction error (no UTXO)."),
  lowBalance("Insufficient balance."),
  dust("Transaction error (dust)."),
  // New case for unexpected errors from a different context
  failed("Transaction failed due to an unexpected error.");

  const MemoAccountantResponse(this.message);
  final String message;
}
//TODO TEST THIS CASE
//USERS ONLY CARE ABOUT LOW BALANCE OR YES, ON LOW BALANCE SOMETHING WENT WRONG ALREADY
// AS IT SHOULDNT BE POSSIBLE TO WRITE WITH LOW BALANCE, EXCEPT IF WALLET IS LOADED SOMEWHERE ELSE AND HAS SPENT WHILE WRITING

//TODO Accountant checks balance before user starts writing to disable all functions related to publishing,
// so then user can be redirected to the QR Code right away anytime he tries to publish
// A provider for MemoAccountant
final memoAccountantProvider = Provider<MemoAccountant>((ref) {
  // You need a user provider here. Assuming one exists.
  final user = ref.watch(userProvider);
  if (user == null) {
    // You could return null or throw an error if the user is not authenticated.
    throw Exception('User data not available for MemoAccountant.');
  }
  // Create and return the MemoAccountant instance, passing ref and the user.
  return MemoAccountant(ref, user);
});

class MemoAccountant {
  final MemoModelUser user;
  final Ref ref;

  MemoAccountant(this.ref, this.user);

  static MemoAccountantResponse checkAccount(MemoAccountType t) {
    return MemoAccountantResponse.yes;
  }

  Future<MemoAccountantResponse> publishReplyTopic(MemoModelPost post, String postReply) async {
    MemoAccountantResponse response = await _tryPublishReplyTopic(user.wifLegacy, post, postReply);

    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> publishLike(MemoModelPost post) async {
    MemoModelPost? scrapedPost = await MemoPostScraper().fetchAndParsePost(post.id!, filterOn: false);

    MemoAccountantResponse response = await _tryPublishLike(post, user.wifLegacy);

    if (response == MemoAccountantResponse.yes) {
      ref.read(postCacheRepositoryProvider).updatePopularityScore(post.id!, user.tipAmount, scrapedPost);
    }

    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> publishReplyHashtags(MemoModelPost post, String text) async {
    return _publishToMemo(MemoCode.profileMessage, text, tips: _parseTips());
  }

  Future<MemoAccountantResponse> publishImgurOrYoutube(String? topic, String text) {
    if (topic != null) {
      return _publishToMemo(MemoCode.topicMessage, text, top: topic, tips: _parseTips());
    } else {
      return _publishToMemo(MemoCode.profileMessage, text, tips: _parseTips());
    }
  }

  Future<MemoAccountantResponse> profileSetAvatar(String imgur) async {
    return _publishToMemo(MemoCode.profileImgUrl, imgur, tips: []);
  }

  Future<MemoAccountantResponse> profileSetName(String name) async {
    return _publishToMemo(MemoCode.profileName, name, tips: []);
  }

  Future<MemoAccountantResponse> profileSetText(String text) async {
    return _publishToMemo(MemoCode.profileText, text, tips: []);
  }

  //TODO ADD A RATE LIMITER TO THE LIKES BUTTON
  Future<MemoAccountantResponse> _tryPublishLike(MemoModelPost post, String wif) async {
    var mp = await MemoPublisher.create(ref, MemoBitcoinBase.reOrderTxHash(post.id!), MemoCode.postLike, wif: wif);
    List<MemoTip> tips = _parseTips(post: post);
    return mp.doPublish(tips: tips);
  }

  MemoAccountantResponse _memoAccountantResponse(MemoAccountantResponse response) =>
      response != MemoAccountantResponse.yes ? MemoAccountantResponse.lowBalance : MemoAccountantResponse.yes;

  Future<MemoAccountantResponse> _tryPublishReplyTopic(String wif, MemoModelPost post, String postReply) async {
    List<MemoTip> tips = _parseTips(post: post);

    return _publishToMemo(MemoCode.topicMessage, postReply, tips: tips, top: post.topicId);
  }

  Future<MemoAccountantResponse> _publishToMemo(MemoCode c, String text, {String? top, required List<MemoTip> tips}) async {
    MemoPublisher mp = await MemoPublisher.create(ref, text, c, wif: user.wifLegacy);
    return mp.doPublish(topic: top ?? "", tips: tips);
  }

  List<MemoTip> _parseTips({MemoModelPost? post}) {
    TipReceiver receiver = ref.read(userProvider)!.tipReceiver;
    int burnAmount = 0;
    int creatorAmount = 0;

    if (user.tipAmount == 0) return [];

    if (post == null) return [MemoTip(MemoBitcoinBase.bchBurnerAddress, user.tipAmount)];

    switch (receiver) {
      case TipReceiver.creator:
        creatorAmount = user.tipAmount;
        break;
      case TipReceiver.app:
        burnAmount = user.tipAmount;
        break;
      case TipReceiver.both:
        burnAmount = (user.tipAmount / 2).round();
        creatorAmount = (user.tipAmount / 2).round();
        break;
      case TipReceiver.burn20Creator80:
        burnAmount = (user.tipAmount * 0.2).round();
        creatorAmount = (user.tipAmount * 0.8).round();
        break;
      case TipReceiver.burn40Creator60:
        burnAmount = (user.tipAmount * 0.4).round();
        creatorAmount = (user.tipAmount * 0.6).round();
        break;
      case TipReceiver.burn60Creator40:
        burnAmount = (user.tipAmount * 0.6).round();
        creatorAmount = (user.tipAmount * 0.4).round();
        break;
      case TipReceiver.burn80Creator20:
        burnAmount = (user.tipAmount * 0.8).round();
        creatorAmount = (user.tipAmount * 0.2).round();
        break;
    }

    List<MemoTip> tips = [];
    if (burnAmount != 0) {
      tips.add(MemoTip(MemoBitcoinBase.bchBurnerAddress, burnAmount));
    }
    if (creatorAmount != 0) {
      tips.add(MemoTip(post.creatorId, creatorAmount));
    }

    return tips;
  }
}
