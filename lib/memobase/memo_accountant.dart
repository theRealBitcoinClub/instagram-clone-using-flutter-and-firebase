import 'package:instagram_clone1/memobase/memo_code.dart';
import 'package:instagram_clone1/memobase/memo_publisher.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse { yes, noUtxo, lowBalance, dust }

//TODO Accountant checks balance before user starts writing to disable all functions related to publishing,
// so then user can be redirected to the QR Code right away anytime he tries to publish

class MemoAccountant {
  final MemoModelUser user;
  final MemoModelCreator creator;
  final String text;

  MemoAccountant(this.user, this.creator, this.text);

  static MemoAccountantResponse checkAccount(MemoAccountType t, MemoModelUser user) {
    return MemoAccountantResponse.yes;
  }

  String getTipReceiver() {
    return creator.id;

    //TODO check if creator has BCH address, if so send him half or all of the tip
    //TODO other half goes to app or full amount goes to app if creator has only memo address funds
  }

  //TODO TEST THIS CASE
  //USERS ONLY CARE ABOUT LOW BALANCE OR YES, ON LOW BALANCE SOMETHING WENT WRONG ALREADY
  // AS IT SHOULDNT BE POSSIBLE TO WRITE WITH LOW BALANCE, EXCEPT IF WALLET IS LOADED SOMEWHERE ELSE AND HAS SPENT WHILE WRITING

  //TODO let user choose the order in which he wants to spend his balance
  //TODO tip receiver can be the user that posted or the app itself to buy and burn tokens
  Future<MemoAccountantResponse> publishReply(String topic) async {
    //Bch tx must be more expensive than token tx, always add extra fee receiver that burns tokens
    MemoAccountantResponse response = await tryPublish(topic, user.wifLegacy);

    if (response != MemoAccountantResponse.yes) {
      response = await tryPublish(topic, user.wifBchCashtoken);
    }

    //TODO let user send specific amount of tokens to manager address then pay tx with faucet funds
    //refill faucet by selling manager tokens

    return response != MemoAccountantResponse.yes ? MemoAccountantResponse.lowBalance : MemoAccountantResponse.yes;
  }

  Future<MemoAccountantResponse> tryPublish(String topic, String wif) async {
    MemoAccountantResponse response = await MemoPublisher().doMemoAction(
      text,
      MemoCode.topicMessage,
      topic: topic,
      wif: wif,
      tipReceiver: getTipReceiver(),
      tipAmount: user.tipAmount,
    );
    return response;
  }
}
