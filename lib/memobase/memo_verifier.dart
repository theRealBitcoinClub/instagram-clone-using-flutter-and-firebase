enum MemoVerificationError {
  isValid,
  moreThanThreeTags,
  zeroTags,
  noTopicNorTag,
  moreThanOneTopic,
  tooLong,
  tooShort,
  minWordCountNotReached,
  offensiveWords,
  email,
  urlThatsNotTgNorImageNorVideo,
  noImageNorVideo
}

class MemoVerifier {
  MemoVerificationError checkIsValidText(String text) {
    if (_checkHasMoreThanThreeHashtags()) return MemoVerificationError.moreThanThreeTags;

    return MemoVerificationError.isValid;
  }

  _checkHasMoreThanThreeHashtags() {
     return true;
  }
}
