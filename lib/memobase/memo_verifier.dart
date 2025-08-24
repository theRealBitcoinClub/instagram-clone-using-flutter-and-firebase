enum MemoVerificationResponse {
  valid,
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
  noImageNorVideo,
}

class MemoVerifier {
  MemoVerificationResponse checkIsValidText(String text) {
    if (_checkHasMoreThanThreeHashtags()) return MemoVerificationResponse.moreThanThreeTags;

    return MemoVerificationResponse.valid;
  }

  _checkHasMoreThanThreeHashtags() {
    return true;
  }
}
