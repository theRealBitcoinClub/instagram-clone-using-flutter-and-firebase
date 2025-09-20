import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_code.dart';
import 'package:mahakka/memo/base/memo_publisher.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/model/memo_tip.dart';

import '../../ipfs/ipfs_pin_claim_service.dart';
import '../../provider/electrum_provider.dart';
import '../../provider/user_provider.dart';
import '../../repositories/post_cache_repository.dart';
import '../../screens/add/add_post_providers.dart';
import '../scraper/memo_post_scraper.dart';
import 'memo_bitcoin_base.dart';

enum MemoAccountType { tokens, bch, memo }

enum MemoAccountantResponse {
  yes("Successfully published!"),
  noUtxo("Transaction error (no UTXO)"),
  lowBalance("Insufficient balance!"),
  dust("Transaction error (dust)"),
  connectionError("Network connection error"),
  insufficientBalanceForIpfs("Insufficient balance for IPFS operation");

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
  pinIpfsFile,
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
        print('MemoAccountant: Queue processor error: $error');
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

        case MemoRequestType.pinIpfsFile:
          response = await _executePinIpfsFile(request.data['file'] as File, request.data['cid'] as String);
          break;

        default:
          response = MemoAccountantResponse.connectionError;
      }

      request.completer.complete(response);
    } catch (error) {
      print('MemoAccountant: Error processing request ${request.type}: $error');
      request.completer.complete(MemoAccountantResponse.connectionError);
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

  Future<MemoAccountantResponse> pinIpfsFile(File file, String cid) {
    return _enqueueRequest(MemoRequestType.pinIpfsFile, data: {'file': file, 'cid': cid});
  }

  // Balance checking method
  Future<bool> checkBalanceForIpfsOperation(double bchCost, {double tolerancePercent = 0.2}) async {
    try {
      print('MemoAccountant: Checking balance for IPFS operation with cost: $bchCost BCH');

      final bitcoinBase = await ref.read(electrumServiceProvider.future);
      final balance = await bitcoinBase.getBalances(user.legacyAddressMemoBch);

      // Convert BCH cost to satoshis
      final requiredSatoshis = (bchCost * 100000000).round();
      final requiredWithTolerance = (requiredSatoshis * (1 + tolerancePercent)).round();

      print('MemoAccountant: Current balance: ${balance.bch} sats, Required: $requiredWithTolerance sats (with $tolerancePercent% tolerance)');

      return balance.bch > requiredWithTolerance;
    } catch (e) {
      print('MemoAccountant: Error checking balance: $e');
      return false;
    }
  }

  // Actual execution methods
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

  Future<MemoAccountantResponse> _executePinIpfsFile(File file, String cid) async {
    try {
      print('MemoAccountant: Starting IPFS pin operation for CID: $cid');

      // Check balance before proceeding
      final bitcoinBase = await ref.read(electrumServiceProvider.future);
      final ipfsService = IpfsPinClaimService(bitcoinBase: bitcoinBase, serverUrl: 'https://file-stage.fullstack.cash');

      final bchCost = await ipfsService.fetchBCHWritePrice(file);
      final hasSufficientBalance = await checkBalanceForIpfsOperation(bchCost);

      if (!hasSufficientBalance) {
        return MemoAccountantResponse.insufficientBalanceForIpfs;
      }

      // Get current user for mnemonic
      final currentUser = ref.read(userProvider);
      if (currentUser == null) {
        print('MemoAccountant: No user found');
        return MemoAccountantResponse.connectionError;
      }

      // Proceed with pinning and verify the result
      final result = await ipfsService.pinClaimBCH(file, cid, currentUser.mnemonic);

      // Verify the pinClaimBCH result
      final verificationResult = _verifyPinClaimResult(result, cid);
      if (verificationResult != MemoAccountantResponse.yes) {
        return verificationResult;
      }

      // Update user with the new IPFS URL
      final resultMessage = await ref.read(userNotifierProvider.notifier).addIpfsUrlAndUpdate(cid);

      if (resultMessage != "success") {
        print('MemoAccountant: Failed to update user with CID: $resultMessage');
        return MemoAccountantResponse.connectionError;
      }

      ref.read(ipfsCidProvider.notifier).state = cid;
      print('MemoAccountant: IPFS pin successful, CID added to user: $cid');
      return MemoAccountantResponse.yes;
    } catch (e) {
      print('MemoAccountant: Error in IPFS pin operation: $e');
      return MemoAccountantResponse.connectionError;
    }
  }

  // Helper method to verify the pinClaimBCH result
  MemoAccountantResponse _verifyPinClaimResult(Map<String, String> result, String expectedCid) {
    try {
      // Check if result contains required fields
      if (result.isEmpty) {
        print('MemoAccountant: Empty result from pinClaimBCH');
        return MemoAccountantResponse.connectionError;
      }

      // Verify required transaction IDs are present
      final pobTxid = result['pobTxid'];
      final claimTxid = result['claimTxid'];

      if (pobTxid == null || pobTxid.isEmpty) {
        print('MemoAccountant: Missing or empty pobTxid in result');
        return MemoAccountantResponse.connectionError;
      }

      if (claimTxid == null || claimTxid.isEmpty) {
        print('MemoAccountant: Missing or empty claimTxid in result');
        return MemoAccountantResponse.connectionError;
      }

      // Verify transaction IDs are valid Bitcoin transaction hashes
      if (!_isValidBitcoinTxId(pobTxid)) {
        print('MemoAccountant: Invalid pobTxid format: $pobTxid');
        return MemoAccountantResponse.connectionError;
      }

      if (!_isValidBitcoinTxId(claimTxid)) {
        print('MemoAccountant: Invalid claimTxid format: $claimTxid');
        return MemoAccountantResponse.connectionError;
      }

      // Optional: Verify the transactions exist on the blockchain
      // This could be added if you want to wait for blockchain confirmation
      // await _verifyTransactionOnBlockchain(pobTxid);
      // await _verifyTransactionOnBlockchain(claimTxid);

      print('MemoAccountant: Pin claim verified successfully - pobTxid: $pobTxid, claimTxid: $claimTxid');
      return MemoAccountantResponse.yes;
    } catch (e) {
      print('MemoAccountant: Error verifying pin claim result: $e');
      return MemoAccountantResponse.connectionError;
    }
  }

  // Helper method to validate Bitcoin transaction ID format
  bool _isValidBitcoinTxId(String txid) {
    // Bitcoin transaction IDs are 64 character hexadecimal strings
    final regex = RegExp(r'^[a-fA-F0-9]{64}$');
    return regex.hasMatch(txid);
  }

  // Optional: Method to verify transaction exists on blockchain
  //   Future<bool> _verifyTransactionOnBlockchain(String txid, {int maxRetries = 3}) async {
  //     try {
  //       final bitcoinBase = await ref.read(electrumServiceProvider.future);
  //
  //       for (int attempt = 1; attempt <= maxRetries; attempt++) {
  //         try {
  //           final transaction = await bitcoinBase.getTransaction(txid);
  //           if (transaction != null) {
  //             print('MemoAccountant: Transaction $txid confirmed on blockchain');
  //             return true;
  //           }
  //
  //           if (attempt < maxRetries) {
  //             print('MemoAccountant: Transaction $txid not found yet, retrying in 5 seconds...');
  //             await Future.delayed(Duration(seconds: 5));
  //           }
  //         } catch (e) {
  //           print('MemoAccountant: Error checking transaction $txid: $e');
  //           if (attempt < maxRetries) {
  //             await Future.delayed(Duration(seconds: 5));
  //           }
  //         }
  //       }
  //
  //       print('MemoAccountant: Transaction $txid not found after $maxRetries attempts');
  //       return false;
  //     } catch (e) {
  //       print('MemoAccountant: Error in blockchain verification: $e');
  //       return false;
  //     }
  //   }

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
