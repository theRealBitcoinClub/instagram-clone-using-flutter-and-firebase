import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';

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
  List<String> _hashTags = [];
  List<String> _urls = [];
  String text;

  List<String> get hashTags {
    if (_hashTags.isEmpty) {
      _hashTags = MemoScraperUtil.extractHashtags(text);
    }
    return _hashTags;
  }

  List<String> get urls {
    if (_urls.isEmpty) {
      _urls = MemoScraperUtil.extractUrls(text);
    }
    return _urls;
  }

  MemoVerifier(this.text);

  num get max_length_name => 30;

  num get min_length_name => 5;

  num get max_length_text => 100;

  num get min_length_text => 5;

  MemoVerificationResponse checkIsValidText() {
    if (hashTags.length > 3) return MemoVerificationResponse.moreThanThreeTags;
    // if (urls.length > 1 && !_urlMatchesTg() && post.imgurUrl.is) return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyUserName() {
    if (text.length > max_length_name) return MemoVerificationResponse.tooLong;

    if (text.isEmpty || text.length < min_length_name) return MemoVerificationResponse.tooShort;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyProfileText() {
    if (text.isEmpty || text.length < min_length_text) return MemoVerificationResponse.tooShort;

    if (text.length > max_length_text) return MemoVerificationResponse.tooLong;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyImgur() {
    if (!text.contains("i.imgur.com")) return MemoVerificationResponse.noImageNorVideo;

    return MemoVerificationResponse.valid;
  }
}
