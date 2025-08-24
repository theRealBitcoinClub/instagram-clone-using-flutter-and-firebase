import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';

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
  final MemoModelPost post;
  List<String> _hashTags = [];
  List<String> _urls = [];

  List<String> get hashTags {
    if (_hashTags.isEmpty) {
      _hashTags = MemoScraperUtil.extractHashtags(post.text);
    }
    return _hashTags;
  }

  List<String> get urls {
    if (_urls.isEmpty) {
      _urls = MemoScraperUtil.extractUrls(post.text);
    }
    return _urls;
  }

  MemoVerifier(this.post);

  MemoVerificationResponse checkIsValidText(String text) {
    if (hashTags.length > 3) return MemoVerificationResponse.moreThanThreeTags;
    // if (urls.length > 1 && !_urlMatchesTg() && post.imgurUrl.is) return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;

    return MemoVerificationResponse.valid;
  }
}
