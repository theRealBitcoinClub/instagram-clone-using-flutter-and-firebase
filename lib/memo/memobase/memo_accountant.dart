import 'package:mahakka/memo/memobase/memo_code.dart';
import 'package:mahakka/memo/memobase/memo_publisher.dart';
import 'package:mahakka/memo/memomodel/memo_model_creator.dart';
import 'package:mahakka/memo/memomodel/memo_model_post.dart';
import 'package:mahakka/memo/memomodel/memo_model_user.dart';

import '../memomodel/memo_tip.dart';
import 'memo_bitcoin_base.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse { yes, noUtxo, lowBalance, dust }

//TODO TEST THIS CASE
//USERS ONLY CARE ABOUT LOW BALANCE OR YES, ON LOW BALANCE SOMETHING WENT WRONG ALREADY
// AS IT SHOULDNT BE POSSIBLE TO WRITE WITH LOW BALANCE, EXCEPT IF WALLET IS LOADED SOMEWHERE ELSE AND HAS SPENT WHILE WRITING

//TODO Accountant checks balance before user starts writing to disable all functions related to publishing,
// so then user can be redirected to the QR Code right away anytime he tries to publish

class MemoAccountant {
  final MemoModelUser user;

  MemoAccountant(this.user);

  static MemoAccountantResponse checkAccount(MemoAccountType t, MemoModelUser user) {
    return MemoAccountantResponse.yes;
  }

  Future<MemoAccountantResponse> publishReplyTopic(MemoModelPost post, String postReply) async {
    MemoAccountantResponse response = await _tryPublishReplyTopic(user.wifLegacy, post, postReply);

    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> publishLike(MemoModelPost post) async {
    MemoAccountantResponse response = await _tryPublishLike(post, user.wifLegacy);

    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> publishReplyHashtags(MemoModelPost post, String text) async {
    var tip = MemoTip(_getTipReceiver(post.creator!), user.tipAmount);
    return _publishToMemo(MemoCode.profileMessage, text, tip: tip);
  }

  Future<MemoAccountantResponse> publishImgurOrYoutube(String? topic, String text) {
    if (topic != null) {
      return _publishToMemo(MemoCode.topicMessage, text, top: topic);
    } else {
      return _publishToMemo(MemoCode.profileMessage, text);
    }
  }

  Future<MemoAccountantResponse> profileSetAvatar(String imgur) async {
    return _publishToMemo(MemoCode.profileImgUrl, imgur);
  }

  Future<MemoAccountantResponse> profileSetName(String name) async {
    return _publishToMemo(MemoCode.profileName, name);
  }

  Future<MemoAccountantResponse> profileSetText(String text) async {
    return _publishToMemo(MemoCode.profileText, text);
  }

  Future<MemoAccountantResponse> _tryPublishLike(MemoModelPost post, String wif) async {
    var mp = await MemoPublisher.create(MemoBitcoinBase.reOrderTxHash(post.txHash!), MemoCode.postLike, wif: wif);
    return mp.doPublish(tip: MemoTip(post.creator!.id, user.tipAmount));
  }

  MemoAccountantResponse _memoAccountantResponse(MemoAccountantResponse response) =>
      response != MemoAccountantResponse.yes ? MemoAccountantResponse.lowBalance : MemoAccountantResponse.yes;

  Future<MemoAccountantResponse> _tryPublishReplyTopic(String wif, MemoModelPost post, String postReply) async {
    var tip = MemoTip(_getTipReceiver(post.creator!), user.tipAmount);
    return _publishToMemo(MemoCode.topicMessage, postReply, tip: tip, top: post.topic!.header);
  }

  Future<MemoAccountantResponse> _publishToMemo(MemoCode c, String text, {String? top, MemoTip? tip}) async {
    MemoPublisher mp = await MemoPublisher.create(text, c, wif: user.wifLegacy);
    return mp.doPublish(topic: top ?? "", tip: tip);
  }

  String _getTipReceiver(MemoModelCreator creator) {
    return creator.id;
  }
}
