import 'package:flutter_test/flutter_test.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';

void main() {
  group('MemoRegExp Unit Tests', () {
    // Test data with various URLs and content
    const testString = """
    Check out these cool links:
    - Imgur: https://i.imgur.com/abc123.jpg
    - Giphy: https://giphy.com/gifs/funny-cat-XYZ456
    - YouTube: https://youtube.com/watch?v=dQw4w9WgXcQ
    - Odysee: https://odysee.com/@channel:123/video-name:abc
    - GitHub image: https://github.com/user/repo/blob/main/image.png
    - GitLab image: https://gitlab.com/user/repo/-/raw/master/photo.jpg
    - PSF IPFS: https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
    - Not Whitelisted domain: https://example.com/path
    - Another IPFS: bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
    - Image URL: https://example.com/image.jpg
    - Video URL: https://example.com/video.mp4
    - Whitelisted: https://mahakka.com/path

    Also check @topic and #hashtag content!
    """;

    test('extractValidImgurOrGiphyUrl should extract imgur URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractValidImgurOrGiphyUrl();
      expect(result, equals('https://i.imgur.com/abc123.jpg'));
    });

    test('extractIpfsCid should extract IPFS CID', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractIpfsCid();
      expect(result, equals('bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74'));
    });

    test('extractOdyseeUrl should extract Odysee URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@channel:123/video-name:abc'));
    });

    test('extractYoutubeUrl should extract YouTube URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractYoutubeUrl();
      expect(result, equals('https://youtube.com/watch?v=dQw4w9WgXcQ'));
    });

    test('extractGithubImageUrl should extract GitHub URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractGithubImageUrl();
      expect(result, equals('https://github.com/user/repo/blob/main/image.png'));
    });

    test('extractGitlabImageUrl should extract GitLab URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractGitlabImageUrl();
      expect(result, equals('https://gitlab.com/user/repo/-/raw/master/photo.jpg'));
    });

    test('extractPsfIpfsUrl should extract PSF IPFS URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractPsfIpfsUrl();
      expect(result, equals('https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74'));
    });

    test('extractWhitelistedDomainUrl should extract whitelisted domain URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractWhitelistedDomainUrl();
      expect(result, equals('https://mahakka.com/path'));
    });

    test('hasImgurUrl should return true for imgur URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasImgurUrl(), isTrue);
    });

    test('hasGiphyUrl should return true for giphy URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasGiphyUrl(), isTrue);
    });

    test('hasOdyseeUrl should return true for odysee URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasOdyseeUrl(), isTrue);
    });

    test('hasYoutubeUrl should return true for youtube URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasYoutubeUrl(), isTrue);
    });

    test('hasGithubImageUrl should return true for github URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasGithubImageUrl(), isTrue);
    });

    test('hasGitlabImageUrl should return true for gitlab URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasGitlabImageUrl(), isTrue);
    });

    test('hasPsfIpfsUrl should return true for psf ipfs URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasPsfIpfsUrl(), isTrue);
    });

    test('hasWhitelistedDomainUrl should return true for whitelisted domain URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasWhitelistedDomainUrl(), isTrue);
    });

    test('hasAnyWhitelistedMediaUrl should return true for any whitelisted URL', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasAnyWhitelistedMediaUrl(), isTrue);
    });

    test('extractAllWhitelistedMediaUrls should extract all URLs', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();
      expect(result.length, greaterThan(0));

      expect(result, contains('https://mahakka.com/path'));
      expect(result, contains('https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74'));
      expect(result, contains('https://gitlab.com/user/repo/-/raw/master/photo.jpg'));
      expect(result, contains('https://github.com/user/repo/blob/main/image.png'));
      expect(result, contains('https://odysee.com/@channel:123/video-name:abc'));
      expect(result, contains('https://youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(result, contains('https://i.imgur.com/abc123.jpg'));
      expect(result, contains('https://giphy.com/gifs/funny-cat-XYZ456'));
    });

    test('extractAllWhitelistedImageUrls should extract image URLs', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractAllWhitelistedImageUrls();
      expect(result.length, greaterThan(0));
      expect(result, contains('https://gitlab.com/user/repo/-/raw/master/photo.jpg'));
      expect(result, contains('https://github.com/user/repo/blob/main/image.png'));
      expect(result, contains('https://i.imgur.com/abc123.jpg'));
    });

    test('extractAllWhitelistedVideoUrls should extract video URLs', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractAllWhitelistedVideoUrls();
      expect(result.length, greaterThan(0));
      expect(result, contains('https://youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(result, contains('https://odysee.com/@channel:123/video-name:abc'));
    });

    test('extractFirstWhitelistedImageUrl should return first image URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractFirstWhitelistedImageUrl();
      expect(result, isNotNull);
      expect(result, contains('https://'));
    });

    test('extractFirstWhitelistedVideoUrl should return first video URL', () {
      final memoRegExp = MemoRegExp(testString);
      final result = memoRegExp.extractFirstWhitelistedVideoUrl();
      expect(result, isNotNull);
      expect(result, contains('https://'));
    });

    test('hasAnyWhitelistedImageUrl should return true for image URLs', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasAnyWhitelistedImageUrl(), isTrue);
    });

    test('hasAnyWhitelistedVideoUrl should return true for video URLs', () {
      final memoRegExp = MemoRegExp(testString);
      expect(memoRegExp.hasAnyWhitelistedVideoUrl(), isTrue);
    });

    test('Static extractTopics should extract topics', () {
      final result = MemoRegExp.extractTopics(testString);
      expect(result, contains('@topic'));
    });

    test('Static extractUrls should extract URLs', () {
      final result = MemoRegExp.extractUrls(testString);
      expect(result.length, greaterThan(0));
    });

    test('Static extractHashtags should extract hashtags', () {
      final result = MemoRegExp.extractHashtags(testString);
      expect(result, contains('#hashtag'));
    });

    test('Static isUrlWhitelisted should validate URLs', () {
      expect(MemoRegExp.isUrlWhitelisted('https://i.imgur.com/abc.jpg'), isTrue);
      expect(MemoRegExp.isUrlWhitelisted('https://malicious.com/bad'), isFalse);
    });

    test('Static hasOnlyWhitelistedUrls should check URL list', () {
      final whitelistedUrls = ['https://i.imgur.com/abc.jpg', 'https://giphy.com/def'];
      final mixedUrls = ['https://i.imgur.com/abc.jpg', 'https://malicious.com/bad'];

      expect(MemoRegExp.hasOnlyWhitelistedUrls(whitelistedUrls), isTrue);
      expect(MemoRegExp.hasOnlyWhitelistedUrls(mixedUrls), isFalse);
    });

    test('TextFilter.findWhitelistedUrls should filter correctly', () {
      const text = "https://i.imgur.com/abc123.jpg https://malicious.com/bad";
      final result = TextFilter.findWhitelistedUrls(text);
      expect(result, contains('https://i.imgur.com/abc123.jpg'));
      expect(result, isNot(contains('https://malicious.com/bad')));
    });

    test('TextFilter.findWhitelistedImageUrls should filter image URLs', () {
      const text = "https://i.imgur.com/image.jpg https://youtube.com/video";
      final result = TextFilter.findWhitelistedImageUrls(text);
      expect(result, contains('https://i.imgur.com/image.jpg'));
    });

    test('TextFilter.findWhitelistedVideoUrls should filter video URLs', () {
      const text = "https://youtube.com/watch?v=dQw4w9WgXcQ https://youtu.be/dQw4w9WgXcQ?feature=shared https://i.imgur.com/image.jpg";
      final result = TextFilter.findWhitelistedVideoUrls(text);
      expect(result, contains('https://youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(result, contains('https://youtu.be/dQw4w9WgXcQ?feature=shared'));
      expect(result, isNot(contains('https://i.imgur.com/image.jpg')));
    });

    test('Empty text should return empty results', () {
      final memoRegExp = MemoRegExp("");
      expect(memoRegExp.extractAllWhitelistedMediaUrls(), isEmpty);
      expect(memoRegExp.hasAnyWhitelistedMediaUrl(), isFalse);
    });

    test('Text with no URLs should return empty results', () {
      const noUrlText = "Just plain text with @topic and #hashtag";
      final memoRegExp = MemoRegExp(noUrlText);
      expect(memoRegExp.extractAllWhitelistedMediaUrls(), isEmpty);
      expect(memoRegExp.hasAnyWhitelistedMediaUrl(), isFalse);
    });
  });
}
