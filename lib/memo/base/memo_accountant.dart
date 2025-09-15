import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_code.dart';
import 'package:mahakka/memo/base/memo_publisher.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/model/memo_tip.dart';

import '../../provider/user_provider.dart';
import '../../repositories/post_cache_repository.dart';
import '../scraper/memo_post_scraper.dart';
import 'memo_bitcoin_base.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse {
  yes(""),
  noUtxo("Transaction error (no UTXO)."),
  lowBalance("Insufficient balance."),
  dust("Transaction error (dust).");
  // failed("Transaction failed due to an unexpected error."),
  // queued("Request queued for processing.");

  const MemoAccountantResponse(this.message);
  final String message;
}

// Request types for the queue
enum MemoRequestType {
  publishReplyTopic,
  publishLike,
  publishReplyHashtags,
  publishImgurOrYoutube,
  profileSetAvatar,
  profileSetName,
  profileSetText,
}

// Request class to hold all necessary data
class MemoRequest {
  final MemoRequestType type;
  final Completer<MemoAccountantResponse> completer;
  final Map<String, dynamic> data;

  MemoRequest({required this.type, required this.completer, required this.data});
}

// Provider for MemoAccountant
final memoAccountantProvider = Provider<MemoAccountant>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) {
    throw Exception('User data not available for MemoAccountant.');
  }
  return MemoAccountant(ref, user);
});

class MemoAccountant {
  final MemoModelUser user;
  final Ref ref;

  // Request queue and processing state
  final List<MemoRequest> _requestQueue = [];
  bool _isProcessing = false;
  StreamController<MemoRequest>? _queueController;
  StreamSubscription<MemoRequest>? _queueSubscription;

  MemoAccountant(this.ref, this.user) {
    _initializeQueueProcessor();
  }

  void _initializeQueueProcessor() {
    _queueController = StreamController<MemoRequest>.broadcast();
    _queueSubscription = _queueController!.stream.listen(
      _processRequest,
      onError: (error) {
        print('Queue processor error: $error');
        _isProcessing = false;
        _processNextRequest();
      },
    );
  }

  // Add request to queue and return a future that completes when processed
  Future<MemoAccountantResponse> _enqueueRequest(MemoRequestType type, {Map<String, dynamic> data = const {}}) {
    final completer = Completer<MemoAccountantResponse>();
    final request = MemoRequest(type: type, completer: completer, data: data);

    _requestQueue.add(request);
    _processNextRequest();

    return completer.future;
  }

  void _processNextRequest() {
    if (_isProcessing || _requestQueue.isEmpty || _queueController == null) return;

    _isProcessing = true;
    final nextRequest = _requestQueue.removeAt(0);
    _queueController!.add(nextRequest);
  }

  Future<void> _processRequest(MemoRequest request) async {
    try {
      MemoAccountantResponse response;

      switch (request.type) {
        case MemoRequestType.publishReplyTopic:
          response = await _executePublishReplyTopic(request.data['post'] as MemoModelPost, request.data['postReply'] as String);
          break;

        case MemoRequestType.publishLike:
          response = await _executePublishLike(request.data['post'] as MemoModelPost);
          break;

        case MemoRequestType.publishReplyHashtags:
          response = await _executePublishReplyHashtags(request.data['post'] as MemoModelPost, request.data['text'] as String);
          break;

        case MemoRequestType.publishImgurOrYoutube:
          response = await _executePublishImgurOrYoutube(request.data['topic'] as String?, request.data['text'] as String);
          break;

        case MemoRequestType.profileSetAvatar:
          response = await _executeProfileSetAvatar(request.data['imgur'] as String);
          break;

        case MemoRequestType.profileSetName:
          response = await _executeProfileSetName(request.data['name'] as String);
          break;

        case MemoRequestType.profileSetText:
          response = await _executeProfileSetText(request.data['text'] as String);
          break;

        // default:
        //   response = MemoAccountantResponse.failed;
      }

      request.completer.complete(response);
    } catch (error) {
      print('Error processing request ${request.type}: $error');
      request.completer.complete(MemoAccountantResponse.lowBalance);
      // request.completer.complete(MemoAccountantResponse.failed);
    } finally {
      _isProcessing = false;
      _processNextRequest();
    }
  }

  // Public methods that now enqueue requests
  Future<MemoAccountantResponse> publishReplyTopic(MemoModelPost post) {
    return _enqueueRequest(MemoRequestType.publishReplyTopic, data: {'post': post, 'postReply': post.text});
  }

  Future<MemoAccountantResponse> publishLike(MemoModelPost post) {
    return _enqueueRequest(MemoRequestType.publishLike, data: {'post': post});
  }

  Future<MemoAccountantResponse> publishReplyHashtags(MemoModelPost post) {
    return _enqueueRequest(MemoRequestType.publishReplyHashtags, data: {'post': post, 'text': post.text});
  }

  Future<MemoAccountantResponse> publishImgurOrYoutube(String? topic, String text) {
    return _enqueueRequest(MemoRequestType.publishImgurOrYoutube, data: {'topic': topic, 'text': text});
  }

  Future<MemoAccountantResponse> profileSetAvatar(String imgur) {
    return _enqueueRequest(MemoRequestType.profileSetAvatar, data: {'imgur': imgur});
  }

  Future<MemoAccountantResponse> profileSetName(String name) {
    return _enqueueRequest(MemoRequestType.profileSetName, data: {'name': name});
  }

  Future<MemoAccountantResponse> profileSetText(String text) {
    return _enqueueRequest(MemoRequestType.profileSetText, data: {'text': text});
  }

  // Actual execution methods (moved from original public methods)
  Future<MemoAccountantResponse> _executePublishReplyTopic(MemoModelPost post, String postReply) async {
    MemoAccountantResponse response = await _tryPublishReplyTopic(user.wifLegacy, post, postReply);
    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> _executePublishLike(MemoModelPost post) async {
    MemoModelPost? scrapedPost = await MemoPostScraper().fetchAndParsePost(post.id!, filterOn: false);
    MemoAccountantResponse response = await _tryPublishLike(post, user.wifLegacy);

    if (response == MemoAccountantResponse.yes) {
      ref.read(postCacheRepositoryProvider).updatePopularityScore(post.id!, user.tipAmount, scrapedPost);
    }

    return _memoAccountantResponse(response);
  }

  Future<MemoAccountantResponse> _executePublishReplyHashtags(MemoModelPost post, String text) async {
    return _publishToMemo(MemoCode.profileMessage, text, tips: parseTips());
  }

  Future<MemoAccountantResponse> _executePublishImgurOrYoutube(String? topic, String text) async {
    if (topic != null) {
      return _publishToMemo(MemoCode.topicMessage, text, top: topic, tips: parseTips());
    } else {
      return _publishToMemo(MemoCode.profileMessage, text, tips: parseTips());
    }
  }

  Future<MemoAccountantResponse> _executeProfileSetAvatar(String imgur) async {
    return _publishToMemo(MemoCode.profileImgUrl, imgur, tips: []);
  }

  Future<MemoAccountantResponse> _executeProfileSetName(String name) async {
    return _publishToMemo(MemoCode.profileName, name, tips: []);
  }

  Future<MemoAccountantResponse> _executeProfileSetText(String text) async {
    return _publishToMemo(MemoCode.profileText, text, tips: []);
  }

  // Original helper methods (unchanged)
  Future<MemoAccountantResponse> _tryPublishLike(MemoModelPost post, String wif) async {
    var mp = await MemoPublisher.create(ref, MemoBitcoinBase.reOrderTxHash(post.id!), MemoCode.postLike, wif: wif);
    List<MemoTip> tips = parseTips(post: post);
    return mp.doPublish(tips: tips);
  }

  MemoAccountantResponse _memoAccountantResponse(MemoAccountantResponse response) =>
      response != MemoAccountantResponse.yes ? MemoAccountantResponse.lowBalance : MemoAccountantResponse.yes;

  Future<MemoAccountantResponse> _tryPublishReplyTopic(String wif, MemoModelPost post, String postReply) async {
    List<MemoTip> tips = parseTips(post: post);
    return _publishToMemo(MemoCode.topicMessage, postReply, tips: tips, top: post.topicId);
  }

  Future<MemoAccountantResponse> _publishToMemo(MemoCode c, String text, {String? top, required List<MemoTip> tips}) async {
    MemoPublisher mp = await MemoPublisher.create(ref, text, c, wif: user.wifLegacy);
    return mp.doPublish(topic: top ?? "", tips: tips);
  }

  List<MemoTip> parseTips({MemoModelPost? post, TipAmount? tipTotalAmountArg, TipReceiver? receiverArg}) {
    var user = ref.read(userProvider)!;
    TipReceiver receiver = receiverArg ?? user.temporaryTipReceiver ?? user.tipReceiver;
    TipAmount tipAmount = tipTotalAmountArg ?? user.temporaryTipAmount ?? user.tipAmountEnum;
    int tipTotalAmount = tipAmount.value;

    if (tipTotalAmount == 0) return [];

    if (post == null) return [MemoTip(MemoBitcoinBase.bchBurnerAddress, tipTotalAmount)];

    // Use the enum's built-in percentage calculation
    final (burnAmount, creatorAmount) = receiver.calculateAmounts(tipTotalAmount);

    List<MemoTip> tips = [];
    if (burnAmount != 0) {
      tips.add(MemoTip(MemoBitcoinBase.bchBurnerAddress, burnAmount));
    }
    if (creatorAmount != 0) {
      tips.add(MemoTip(post.creatorId, creatorAmount));
    }

    return tips;
  }

  //
  // List<MemoTip> parseTips({MemoModelPost? post}) {
  //   // ... unchanged implementation
  //   TipReceiver receiver = ref.read(userProvider)!.tipReceiver;
  //   int burnAmount = 0;
  //   int creatorAmount = 0;
  //   int tipTotalAmount = ref.read(temporaryTipAmountProvider) != null ? ref.read(temporaryTipAmountProvider)!.value : user.tipAmount;
  //
  //   if (tipTotalAmount == 0) return [];
  //
  //   if (post == null) return [MemoTip(MemoBitcoinBase.bchBurnerAddress, tipTotalAmount)];
  //
  //   switch (receiver) {
  //     case TipReceiver.creator:
  //       creatorAmount = tipTotalAmount;
  //       break;
  //     case TipReceiver.app:
  //       burnAmount = tipTotalAmount;
  //       break;
  //     case TipReceiver.both:
  //       burnAmount = (tipTotalAmount / 2).round();
  //       creatorAmount = (tipTotalAmount / 2).round();
  //       break;
  //     case TipReceiver.burn20Creator80:
  //       burnAmount = (tipTotalAmount * 0.2).round();
  //       creatorAmount = (tipTotalAmount * 0.8).round();
  //       break;
  //     case TipReceiver.burn40Creator60:
  //       burnAmount = (tipTotalAmount * 0.4).round();
  //       creatorAmount = (tipTotalAmount * 0.6).round();
  //       break;
  //     case TipReceiver.burn60Creator40:
  //       burnAmount = (tipTotalAmount * 0.6).round();
  //       creatorAmount = (tipTotalAmount * 0.4).round();
  //       break;
  //     case TipReceiver.burn80Creator20:
  //       burnAmount = (tipTotalAmount * 0.8).round();
  //       creatorAmount = (tipTotalAmount * 0.2).round();
  //       break;
  //   }
  //
  //   List<MemoTip> tips = [];
  //   if (burnAmount != 0) {
  //     tips.add(MemoTip(MemoBitcoinBase.bchBurnerAddress, burnAmount));
  //   }
  //   if (creatorAmount != 0) {
  //     tips.add(MemoTip(post.creatorId, creatorAmount));
  //   }
  //
  //   return tips;
  // }

  // Cleanup method to dispose resources
  void dispose() {
    _queueSubscription?.cancel();
    _queueController?.close();
    _requestQueue.clear();
  }

  // Optional: Get queue status for UI feedback
  int get queueLength => _requestQueue.length;
  bool get isProcessing => _isProcessing;
  bool get hasPendingRequests => _requestQueue.isNotEmpty || _isProcessing;
}
