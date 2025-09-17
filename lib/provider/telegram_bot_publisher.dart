import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:telegram/telegram.dart';

import '../memo/model/memo_model_creator.dart';
import '../providers/creator_cache_provider.dart';
import '../widgets/popularity_score_widget.dart';
import 'bch_burner_balance_provider.dart';

final telegramBotPublisherProvider = Provider<TelegramBotPublisher>((ref) {
  return TelegramBotPublisher(ref);
});

class TelegramBotPublisher {
  final Ref ref;

  TelegramBotPublisher(this.ref);

  //TODO ADD method for likes

  Future<void> publishPost({required String postText, String? mediaUrl}) async {
    try {
      var token = dotenv.get('TELEGRAM_BOT_TOKEN');
      var chatId = dotenv.get('TELEGRAM_CHAT_ID');
      Telegram.setBotToken(token);

      var user = ref.read(userProvider)!;
      MemoModelCreator? creator = await ref.read(creatorCacheRepositoryProvider).getCreator(user.id);

      if (creator == null) {
        throw Exception('Creator not found for user ${user.id}');
      }

      await creator.refreshImageDetail();
      String name = creator.name;
      int tip = user.tipAmount;
      String tipReceiver = user.tipReceiver.displayName;
      int burnTotal = ref.read(bchBurnerBalanceProvider).value!.bch;

      // Build the message text
      final messageText = _buildMessageText(
        name: name,
        postText: postText,
        burnTotal: burnTotal,
        creator: creator,
        tip: tip,
        tipReceiver: tipReceiver,
        mediaUrl: mediaUrl,
      );

      // Send the message
      await Telegram.sendMessage(chatId: chatId, text: messageText, parseMode: 'HTML');
    } catch (e) {
      // Handle errors appropriately (log, rethrow, etc.)
      print('Error publishing to Telegram: $e');
      rethrow;
    }
  }

  String _buildMessageText({
    required String name,
    required String postText,
    required int burnTotal,
    required MemoModelCreator creator,
    required int tip,
    required String tipReceiver,
    required String? mediaUrl,
  }) {
    return '$name published: $postText, '
        '🔥 Burn total: ${PopularityScoreWidget.formatPopularityScore(burnTotal)} sats,'
        ' ${creator.profileIdShort} contributed ${PopularityScoreWidget.formatPopularityScore(tip)} sats to $tipReceiver, '
        ' ${mediaUrl ?? creator.profileImageDetail()}';
  }
}
