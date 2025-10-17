import 'package:mahakka/memo/memo_reg_exp.dart';

import '../model/memo_model_post.dart';

//https://beta-api.memo.cash/post/details?txHash=d2976ea1701295abe6d8d68a78fb6920465bfc1eb47eb148f5271120d9374231

class MemoModelPostAPI {
  final String txHash;
  final MemoModelCreatorApi name;
  final String message;
  final String topic;
  final String date;
  final int likes;
  final int tip;
  final int replies;

  MemoModelPostAPI({
    required this.txHash,
    required this.name,
    required this.message,
    required this.topic,
    required this.date,
    required this.likes,
    required this.tip,
    required this.replies,
  });

  factory MemoModelPostAPI.fromJson(Map<String, dynamic> json) {
    return MemoModelPostAPI(
      txHash: json['tx_hash'] as String? ?? '',
      name: MemoModelCreatorApi.fromJson(json['name'] as Map<String, dynamic>? ?? {}),
      message: _decodeMessage(json['message'] as String? ?? ''),
      topic: json['topic'] as String? ?? '',
      date: json['date'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      tip: json['tip'] as int? ?? 0,
      replies: json['replies'] as int? ?? 0,
    );
  }

  static String _decodeMessage(String encodedMessage) {
    // Decode HTML entities like &#x1F1EC; to actual characters
    return encodedMessage.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      final hexCode = match.group(1);
      if (hexCode != null) {
        final codePoint = int.parse(hexCode, radix: 16);
        return String.fromCharCode(codePoint);
      }
      return match.group(0)!;
    });
  }

  // Method to transform to MemoModelPost
  MemoModelPost toMemoModelPost() {
    final decodedMessage = message;
    final memoRegExp = MemoRegExp(decodedMessage);

    // Extract URLs generously to catch all possible media URLs
    final allUrls = MemoRegExp.extractUrlsGenerously(decodedMessage);

    // Extract specific media types
    final youtubeUrl = memoRegExp.extractYoutubeUrl();
    final imgurUrl = memoRegExp.extractValidImgurOrGiphyUrl();
    final odyseeUrl = memoRegExp.extractOdyseeUrl();
    final ipfsCid = memoRegExp.extractIpfsCid();

    // Extract first whitelisted image and video URLs
    final firstImageUrl = memoRegExp.extractFirstWhitelistedImageUrl();
    final firstVideoUrl = memoRegExp.extractFirstWhitelistedVideoUrl();

    // Extract YouTube ID from YouTube URL
    String? youtubeId;
    if (youtubeUrl.isNotEmpty) {
      final youtubeRegExp = RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)', caseSensitive: false);
      final match = youtubeRegExp.firstMatch(youtubeUrl);
      youtubeId = match?.group(1);
    }

    // Extract tags and topics
    final tags = MemoRegExp.extractHashtags(decodedMessage);
    final topics = MemoRegExp.extractTopics(decodedMessage);

    // Determine the main topic - use provided topic or extract from message
    String mainTopic = topic;
    if (mainTopic.isEmpty && topics.isNotEmpty) {
      mainTopic = topics.first;
    }

    // Parse the date
    DateTime? createdDateTime;
    try {
      createdDateTime = DateTime.parse(date).subtract(Duration(hours: 4));
    } catch (e) {
      // If parsing fails, use current date
      createdDateTime = DateTime.now();
    }

    // Clean text by removing URLs, tags, and topics
    String cleanText = decodedMessage;

    // Remove all URLs
    for (final url in allUrls) {
      cleanText = cleanText.replaceAll(url, '');
    }

    // Remove all tags
    for (final tag in tags) {
      cleanText = cleanText.replaceAll(tag, '');
    }

    // Remove all topics
    for (final topic in topics) {
      cleanText = cleanText.replaceAll(topic, '');
    }

    // Clean up extra whitespace
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Determine the best imageUrl - prioritize imgur, then other whitelisted images
    String? imageUrl;
    if (imgurUrl.isNotEmpty) {
      imageUrl = imgurUrl;
    } else if (firstImageUrl != null) {
      imageUrl = firstImageUrl;
    }

    // Determine the best videoUrl - prioritize odysee, then other whitelisted videos
    String? videoUrl;
    if (odyseeUrl.isNotEmpty) {
      videoUrl = odyseeUrl;
    } else if (firstVideoUrl != null) {
      videoUrl = firstVideoUrl;
    }

    return MemoModelPost(
      id: txHash, // Use transaction hash as ID
      text: cleanText,
      imgurUrl: imgurUrl.isNotEmpty ? imgurUrl : null,
      youtubeId: youtubeId,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      ipfsCid: ipfsCid.isNotEmpty ? ipfsCid : null,
      createdDateTime: createdDateTime,
      popularityScore: tip, // Map tip to popularity score
      likeCounter: likes,
      replyCounter: replies,
      creatorId: name.id, // Map address to creatorId
      topicId: mainTopic,
      tagIds: tags,
      urls: allUrls,
      created: date,
    );
  }
}

class MemoModelCreatorApi {
  final String name;
  final String id;
  final String? avatarType;

  MemoModelCreatorApi({required this.name, required this.id, required this.avatarType});

  factory MemoModelCreatorApi.fromJson(Map<String, dynamic> json) {
    return MemoModelCreatorApi(name: json['name'] as String, id: json['address'] as String, avatarType: json['pic'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id, 'avatarType': avatarType};
  }
}
