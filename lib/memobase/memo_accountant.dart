enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse { yes, noUtxo, lowBalance, dust }

//TODO Accountant checks balance before user starts writing to disable all functions related to publishing,
// so then user can be redirected to the QR Code right away anytime he tries to publish

class MemoAccountant {
  MemoAccountantResponse checkAccount(MemoAccountType t) {
    return MemoAccountantResponse.yes;
  }
}
