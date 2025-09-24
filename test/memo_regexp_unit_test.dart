import 'package:flutter_test/flutter_test.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';

void main() {
  group('MemoRegExp Unit Tests', () {
    // Test data with various URLs and content
    const testString = """
    Check out these cool links:
    - Imgur: /nhttps://i.imgur.com/abc123.jpg
    - Giphy: noihttps://i.giphy.com/funny-cat-XYZ456.jpg
      -- https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbjJhZXpsczhmOGtjYjJoa3IzZmV3ZzFjZm80YTRjczU1d20wbWJkNSZlcD12MV9naWZzX3RyZW5kaW5nJmN0PWc/WZZ2EUCJdl2g9JKYD8/giphy.webp
    - YouTube:--https://youtube.com/watch?v=dQw4w9WgXcQ
    - Odysee:___https://odysee.com/@channel:123/video-name:8378
    - GitHub image:nciuewhttps://github.com/user/repo/blob/main/image.png
    - GitLab image:acshttps://gitlab.com/user/repo/-/raw/master/photo.jpg
    - PSF IPFS:\$https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
    - Not Whitelisted domain:https://example.com/path
    - Another IPFS:bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
    - Image URL: https://example.com/image.jpg
    - Video URL: https://example.com/video.mp4
    - Whitelisted: https://mahakka.com/path
    https://github.com/video.mp4

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
      var memoRegExp = MemoRegExp(testString);
      var result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@channel:123/video-name:8378'));
      memoRegExp = MemoRegExp("dfsjfhdskjdshttps://odysee.com/@SomeOrdinaryGamers:6/they-just-released-the-epstein-birthday:0 dfsfdskds");
      result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@SomeOrdinaryGamers:6/they-just-released-the-epstein-birthday:0'));
      memoRegExp = MemoRegExp("dfsjfhdskjdshttps://odysee.com/@SomeOrdinaryGamers:6/they-just-released-the-epstein-birthday:21\n");
      result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@SomeOrdinaryGamers:6/they-just-released-the-epstein-birthday:21'));
      memoRegExp = MemoRegExp("      https://odysee.com/@pandasub2000:b/psvr2kthgmadsnvrp05fnl:6");
      result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@pandasub2000:b/psvr2kthgmadsnvrp05fnl:6'));
      memoRegExp = MemoRegExp("\n\nhttps://odysee.com/@pandasub2000:b/psvr2kthgmadsnvrp05fnl:6");
      result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@pandasub2000:b/psvr2kthgmadsnvrp05fnl:6'));
      memoRegExp = MemoRegExp("https://odysee.com/@CageGaming:1/Chili-_--mrcagegaming-on--Twitch:e");
      result = memoRegExp.extractOdyseeUrl();
      expect(result, equals('https://odysee.com/@CageGaming:1/Chili-_--mrcagegaming-on--Twitch:e'));
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
      final memoRegExp2 = MemoRegExp("https://free-bch.fullstack.cash/ipfs/view/bafkreibefriydc7opoqhvzp6ymktynmzlkv24eqlzioo3no7q4j4wdyc2i");
      final result2 = memoRegExp2.extractPsfIpfsUrl();

      expect(result2, equals("https://free-bch.fullstack.cash/ipfs/view/bafkreibefriydc7opoqhvzp6ymktynmzlkv24eqlzioo3no7q4j4wdyc2i"));
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
      expect(result, contains('https://odysee.com/@channel:123/video-name:8378'));
      expect(result, contains('https://youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(result, contains('https://i.imgur.com/abc123.jpg'));
      expect(
        result,
        contains(
          'https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbjJhZXpsczhmOGtjYjJoa3IzZmV3ZzFjZm80YTRjczU1d20wbWJkNSZlcD12MV9naWZzX3RyZW5kaW5nJmN0PWc/WZZ2EUCJdl2g9JKYD8/giphy.webp',
        ),
      );
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
      // const urls = """
      // https://github.com/user/repo/blob/main/image.png
      // https://raw.githubusercontent.com/user/repo/main/vid.avi
      // https://user-images.githubusercontent.com/123456/abc123.png
      // https://github.com/user/repo/raw/main/image.webp
      // """;
      // final memoRegExp = MemoRegExp(urls);
      final memoRegExp = MemoRegExp(
        "fdsfdshttps://mahakka.com/video.mp4 https://odysee.com/@channel:123/video-name:8378 https://raw.githubusercontent.com/user/repo/main/vid.avi",
      );
      final result = memoRegExp.extractAllWhitelistedVideoUrls();
      expect(result.length, equals(2));
      expect(result, contains('https://raw.githubusercontent.com/user/repo/main/vid.avi'));
      expect(result, contains('https://mahakka.com/video.mp4'));
      expect(result, isNot(contains('https://odysee.com/@channel:123/video-name:8378')));
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
      var result = MemoRegExp.extractTopics(testString);
      expect(result, contains('@topic'));
      result = MemoRegExp.extractTopics(
        "#odysee lets get this party https://odysee.com/@ClownfishTV:b/youtube-admits-they-censored:5 started @Flavour_Trip oh yeah http://havingfun.com why not #bchbankrun",
      );
      expect(result, contains('@Flavour_Trip'));
      expect(result.length, equals(1));
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
      final whitelistedUrls = [
        'https://i.imgur.com/abc.jpg',
        "https://i.giphy.com/WZZ2EUCJdl2g9JKYD8.webp",
        "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExeG4wNjRnNmF5cDFoM3pjcHFzbjd2cTk0czZ1ODJyN3dqcTZrZjZ6byZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/PRMG2CC7WlBcgYtYLl/giphy.gif",
      ];
      final mixedUrls = ['https://i.imgur.com/abc.jpg', 'https://giphy.com/def'];

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
      const text =
          "https://raw.githubusercontent.com/user/repo/main/vid.avi https://github.com/video.mp4 https://youtube.com/watch?v=dQw4w9WgXcQ https://youtu.be/dQw4w9WgXcQ?feature=shared https://i.imgur.com/image.jpg";
      final result = TextFilter.findWhitelistedVideoUrls(text);
      expect(result, contains('https://raw.githubusercontent.com/user/repo/main/vid.avi'));
      expect(result, contains('https://github.com/video.mp4'));
      expect(result, isNot(contains('https://youtube.com/watch?v=dQw4w9WgXcQ')));
      expect(result, isNot(contains('https://youtu.be/dQw4w9WgXcQ?feature=shared')));
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

    // ========== EDGE CASE TESTS ==========

    test('extractIpfsCid should extract multiple IPFS CIDs and return first', () {
      const textWithMultipleCids = """
      IPFS CIDs: QmXyZ123abcDEF456ghiJKL789mnoPQRstuVWXyz 
      and bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi
      """;
      final memoRegExp = MemoRegExp(textWithMultipleCids);
      final result = memoRegExp.extractIpfsCid();
      expect(result, equals('bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi'));
    });

    test('extractValidImgurOrGiphyUrl should prioritize imgur over giphy', () {
      const textWithBoth = "https://i.imgur.com/abc123.jpg https://giphy.com/gif/xyz";
      final memoRegExp = MemoRegExp(textWithBoth);
      final result = memoRegExp.extractValidImgurOrGiphyUrl();
      expect(result, equals('https://i.imgur.com/abc123.jpg'));
    });

    test('extractValidImgurOrGiphyUrl should return giphy if no imgur', () {
      const textWithGiphyOnly = "Only giphy: https://i.giphy.com/xyz.jpg";
      final memoRegExp = MemoRegExp(textWithGiphyOnly);
      final result = memoRegExp.extractValidImgurOrGiphyUrl();
      expect(result, equals('https://i.giphy.com/xyz.jpg'));
    });

    test('YouTube regex should handle various YouTube URL formats', () {
      const youtubeUrls = """
      https://youtube.com/watch?v=dQw4w9WgXcQ
      https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=shared
      https://m.youtube.com/watch?v=dQw4w9WgXcQ
      https://youtu.be/dQw4w9WgXcQ
      https://youtube.com/embed/dQw4w9WgXcQ
      https://youtube.com/v/dQw4w9WgXcQ
      https://youtube.com/shorts/dQw4w9WgXcQ
      """;

      final memoRegExp = MemoRegExp(youtubeUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, greaterThanOrEqualTo(7));
      expect(result.every((url) => url.contains('dQw4w9WgXcQ')), isTrue);
    });

    test('GitHub regex should match various GitHub image formats', () {
      const githubUrls = """
      https://github.com/user/repo/blob/main/image.png
      https://raw.githubusercontent.com/user/repo/main/image.jpg
      https://user-images.githubusercontent.com/123456/abc123.png
      https://github.com/user/repo/raw/main/image.webp
      """;

      final memoRegExp = MemoRegExp(githubUrls);
      final result = memoRegExp.extractAllWhitelistedImageUrls();

      expect(result.length, 4);
    });

    test('IPFS regex should handle various IPFS URL formats', () {
      const ipfsUrls = """
      https://free-bch.fullstack.cash/ipfs/view/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
      https://free-bch.fullstack.cash/ipfs/view/QmXyZ123abcDEF456ghiJKL789mnoPQRstuVWXyz
      https://ipfs.io/ipfs/bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74
      """;

      final memoRegExp = MemoRegExp(ipfsUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 1); // Only free-bch URLs should match psfIpfs pattern
    });

    test('Odysee regex should handle various Odysee URL formats', () {
      const odyseeUrls = """
      https://odysee.com/@channel:123/video-name:8378
      https://www.odysee.com/@channel:123/video-name:8378
      https://odysee.com/@DrBerg:4/how-to-never-get-a-kidney-stone-(20:9
      https://odysee.com/@CancelThisPodcast:a/S06E42--In-Memory-of-Charlie-Kirk--Is-American-Culture-At-a--Turning-Point--:4
      https://odysee.com/video-name:abc
      https://odysee.com/embed/video-name:abc
      https://odysee.com/@videobuck:8/sole-survivor-%281983%29-la-muerte-no:c
      """;

      final memoRegExp = MemoRegExp(odyseeUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result[0], contains("https://odysee.com/@channel:123/video-name:8378"));
      expect(result[1], contains("https://www.odysee.com/@channel:123/video-name:8378"));
      expect(result[2], contains("https://odysee.com/@DrBerg:4/how-to-never-get-a-kidney-stone-(20:9"));
      expect(
        result[3],
        contains("https://odysee.com/@CancelThisPodcast:a/S06E42--In-Memory-of-Charlie-Kirk--Is-American-Culture-At-a--Turning-Point--:4"),
      );

      expect(result[4], contains("https://odysee.com/@videobuck:8/sole-survivor-%281983%29-la-muerte-no:c"));

      expect(result.length, 5);
    });

    test('Twitter regex should handle various Twitter URL formats', () {
      const twitterUrls = """
      https://twitter.com/user/status/1234567890
      https://x.com/user/status/1234567890
      https://twitter.com/user/
      https://t.co/abc123
      https://pbs.twimg.com/media/abc123.jpg
      https://pbs.twimg.com/media/G0ZZQzKWMAAC7K8.jpg
      """;

      final memoRegExp = MemoRegExp(twitterUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 6);
    });

    test('Reddit regex should handle various Reddit URL formats', () {
      const redditUrls = """
      https://www.reddit.com/r/subreddit/comments/abc123/post_title/
      https://np.reddit.com/r/subreddit/comments/abc123/post_title/
      https://i.redd.it/abc123.jpg
      https://preview.redd.it/abc123.png
      """;

      final memoRegExp = MemoRegExp(redditUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 4);
    });

    test('Telegram regex should handle various Telegram URL formats', () {
      const telegramUrls = """
      https://t.me/channel/123
      https://telegram.me/channel
      https://web.telegram.org/
      https://telesco.pe/channel/123
      """;

      final memoRegExp = MemoRegExp(telegramUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 4);
    });

    test('URLs with query parameters should be handled correctly', () {
      const urlsWithParams = """
      https://i.imgur.com/abc123.jpg?width=200&height=200
      https://youtube.com/watch?v=dQw4w9WgXcQ&t=120
      https://github.com/user/repo/blob/main/image.png?raw=true
      """;

      final memoRegExp = MemoRegExp(urlsWithParams);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 3);
      expect(result[0], equals('https://i.imgur.com/abc123.jpg'));
      expect(result[1], equals('https://youtube.com/watch?v=dQw4w9WgXcQ&t=120'));
      expect(result[2], equals('https://github.com/user/repo/blob/main/image.png?raw=true'));
    });

    test('URLs with special characters should be handled', () {
      const urlsWithSpecialChars = """
      https://github.com/user/repo/blob/main/image-with-dashes.png
      https://imgur.com/gallery/image_with_underscores
      https://example.com/path-with-dashes_and_underscores
      """;

      final memoRegExp = MemoRegExp(urlsWithSpecialChars);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, greaterThan(0));
    });

    test('Mixed content with URLs at different positions', () {
      const mixedContent = """
      Start with URL: https://i.imgur.com/abc123.jpg
      Middle https://youtube.com/watch?v=dQw4w9WgXcQ content
      End with URL https://github.com/image.png
      """;

      final memoRegExp = MemoRegExp(mixedContent);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 3);
    });

    test('Very long URLs should be handled', () {
      const longUrl =
          "https://github.com/user/very/long/path/to/the/image/file/with/many/subdirectories/and_a_very_long_file_name_that_goes_on_and_on.png";

      final memoRegExp = MemoRegExp(longUrl);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 1);
      expect(result[0], equals(longUrl));
    });

    test('URLs with encoded characters should be handled', () {
      const encodedUrls = """
      https://github.com/user/repo/blob/main/image%20with%20spaces.png
      https://example.com/path%20with%20encoded%20chars
      """;

      final memoRegExp = MemoRegExp(encodedUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, greaterThan(0));
    });

    test('Case insensitive matching should work', () {
      const mixedCaseUrls = """
      HTTPS://I.IMGUR.COM/ABC123.JPG
      http://GITHUB.COM/user/repo/blob/main/IMAGE.PNG
      https://YOUTUBE.COM/WATCH?V=DQW4W9WGXCQ
      """;

      final memoRegExp = MemoRegExp(mixedCaseUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 3);
    });

    test('URLs without protocol should NOT be matched', () {
      const noProtocolUrls = """
      i.imgur.com/abc123.jpg
      www.youtube.com/watch?v=dQw4w9WgXcQ
      github.com/user/repo/blob/main/image.png
      http://github.com/user/repo/blob/main/image.png
      """;

      final memoRegExp = MemoRegExp(noProtocolUrls);
      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      expect(result.length, 1);
    });

    test('TextFilter methods should handle complex text with mixed content', () {
      const complexText = """
      Check this out: https://i.imgur.com/abc123.jpg and also 
      https://youtube.com/watch?v=dQw4w9WgXcQ but ignore 
      https://malicious.com/bad and also consider 
      https://github.com/user/repo/blob/main/image.png
      https://memo.cash/video.mp4
      """;

      final allUrls = TextFilter.findWhitelistedUrls(complexText);
      final imageUrls = TextFilter.findWhitelistedImageUrls(complexText);
      final videoUrls = TextFilter.findWhitelistedVideoUrls(complexText);

      expect(allUrls.length, 4);
      expect(imageUrls.length, 2);
      expect(videoUrls.length, 1);
      expect(allUrls, isNot(contains('https://malicious.com/bad')));
    });

    test('hasOnlyWhitelistedUrls should handle empty list', () {
      expect(MemoRegExp.hasOnlyWhitelistedUrls([]), isTrue);
    });

    test('hasOnlyWhitelistedUrls should handle mixed protocols', () {
      final mixedProtocols = ['https://i.imgur.com/abc.jpg', 'http://giphy.com/gif', 'https://malicious.com/bad'];

      expect(MemoRegExp.hasOnlyWhitelistedUrls(mixedProtocols), isFalse);
    });

    test('extractTopics should handle multiple topics', () {
      const multipleTopics = "Hello @topic1 and @topic2 @@@TOPIC@ @TOPIC_ and @another_topic more @mahakka.com last @mahakka_yes-topic";
      final result = MemoRegExp.extractTopics(multipleTopics);

      expect(result.length, 7);
      expect(result, contains('@mahakka.com'));
      expect(result, contains('@mahakka_yes-topic'));
      expect(result, contains('@topic1'));
      expect(result, contains('@topic2'));
      expect(result, contains('@another_topic'));
      expect(result, contains('@TOPIC'));
      expect(result, contains('@TOPIC_'));
    });

    test('extractHashtags should handle multiple hashtags', () {
      const multipleHashtags = "#flutter@ #dart- #testing_ #unit_tests! fhkjds#cxz @#njk fhkjds#cxzaf@gufd @#njk_";
      final result = MemoRegExp.extractHashtags(multipleHashtags);

      expect(result.length, 8);
      expect(result, contains('#flutter'));
      expect(result, contains('#dart'));
      expect(result, contains('#testing_'));
      expect(result, contains('#unit_tests'));
      expect(result, contains('#cxz'));
      expect(result, contains('#njk'));
      expect(result, contains('#cxzaf'));
      expect(result, contains('#njk_'));
    });

    test('extractUrls should handle complex text with various URLs', () {
      const complexText = """
      Multiple URLs: https://example.com, http://test.org, 
      www.google.com, and also ftp://old.protocol but only 
      http and https should be matched.
      https://www.mintme.com/dsfsdfds/vcs
      """;

      final result = MemoRegExp.extractUrls(complexText);

      // Should match https://example.com, http://test.org
      expect(result, contains('https://www.mintme.com/dsfsdfds/vcs'));
      expect(result, isNot(contains('www.dfdfd.com')));
      expect(result, contains('www.google.com'));
      expect(result, contains('https://www.mintme.com/dsfsdfds/vcs'));
      expect(result, isNot(contains('ftp://old.protocol')));
      expect(result.length, 4);
    });

    test('Performance test with large text', () {
      // Generate large text with many URLs
      final largeText = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        largeText.writeln("URL https://mahakka.com/$i and text content");
      }

      final memoRegExp = MemoRegExp(largeText.toString());
      final stopwatch = Stopwatch()..start();

      final result = memoRegExp.extractAllWhitelistedMediaUrls();

      stopwatch.stop();
      print('Extracted ${result.length} URLs in ${stopwatch.elapsedMilliseconds}ms');

      expect(result.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });
  });
}
