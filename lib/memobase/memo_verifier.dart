import 'package:mahakka/memoscraper/memo_scraper_utils.dart';

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

  MemoVerificationResponse checkIsValidText() {
    if (hashTags.length > 3) return MemoVerificationResponse.moreThanThreeTags;
    // if (urls.length > 1 && !_urlMatchesTg() && post.imgurUrl.is) return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;

    return MemoVerificationResponse.valid;
  }
}
