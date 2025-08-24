import 'package:instagram_clone1/memobase/memo_code.dart';
import 'package:instagram_clone1/memobase/memo_publisher.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';

import '../memomodel/memo_tip.dart';
import 'memo_bitcoin_base.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse { yes, noUtxo, lowBalance, dust }

//TODO Accountant checks balance before user starts writing to disable all functions related to publishing,
// so then user can be redirected to the QR Code right away anytime he tries to publish

class MemoAccountant {
  final MemoModelUser user;

  MemoAccountant(this.user);

  static MemoAccountantResponse checkAccount(MemoAccountType t, MemoModelUser user) {
    return MemoAccountantResponse.yes;
  }

  //TODO if it is new post then send somewhere the tip to the add or burn the tokens
  //TODO to post new content they need the tokens to be able to burn them before post
  //TODO reactions can be made with Bch only paid by memo funds or Bch funds
  String getTipReceiver(MemoModelCreator creator) {
    return creator.id;

    //TODO check if creator has BCH address, if so send him half or all of the tip
    //TODO other half goes to app or full amount goes to app if creator has only memo address funds
  }

  //TODO TEST THIS CASE
  //USERS ONLY CARE ABOUT LOW BALANCE OR YES, ON LOW BALANCE SOMETHING WENT WRONG ALREADY
  // AS IT SHOULDNT BE POSSIBLE TO WRITE WITH LOW BALANCE, EXCEPT IF WALLET IS LOADED SOMEWHERE ELSE AND HAS SPENT WHILE WRITING

  //TODO let user choose the order in which he wants to spend his balance
  //TODO tip receiver can be the user that posted or the app itself to buy and burn tokens
  Future<MemoAccountantResponse> publishReply(MemoModelPost post, MemoModelPost postReply) async {
    //Bch tx must be more expensive than token tx, always add extra fee receiver that burns tokens
    MemoAccountantResponse response = await _tryPublishReply(user.wifLegacy, post, postReply);

    if (response != MemoAccountantResponse.yes) {
      response = await _tryPublishReply(user.wifBchCashtoken, post, postReply);
    }

    //TODO let user send specific amount of tokens to manager address then pay tx with faucet funds
    //refill faucet by selling manager tokens

    return memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> publishLike(MemoModelPost post) async {
    MemoAccountantResponse response = await tryPublishLike(post, user.wifLegacy);

    if (response != MemoAccountantResponse.yes) response = await tryPublishLike(post, user.wifBchCashtoken);

    return memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> tryPublishLike(MemoModelPost post, String wif) async {
    var mp = await MemoPublisher.create(MemoBitcoinBase.reOrderTxHash(post.txHash!), MemoCode.postLike, wif: wif);
    return await mp.doPublish(tip: MemoTip(post.creator!.id, user.tipAmount));
  }

  MemoAccountantResponse memoAccountantResponse(MemoAccountantResponse response) =>
      response != MemoAccountantResponse.yes ? MemoAccountantResponse.lowBalance : MemoAccountantResponse.yes;

  Future<MemoAccountantResponse> _tryPublishReply(String wif, MemoModelPost post, MemoModelPost postReply) async {
    var mp = await MemoPublisher.create(postReply.text!, MemoCode.topicMessage, wif: wif);
    var tip = MemoTip(getTipReceiver(post.creator!), user.tipAmount);
    MemoAccountantResponse response = await mp.doPublish(topic: post.topic!.header, tip: tip);
    return response;
  }
}
