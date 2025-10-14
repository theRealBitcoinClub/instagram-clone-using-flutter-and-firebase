// translation_cache.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/translation_sequencer.dart';
import 'package:mahakka/provider/translation_service.dart';

import '../memo/isar/cached_translation_db.dart';
import 'isar_provider.dart';

const Map<String, Map<String, String>> _staticVocabulary = {
  'cancel': {
    'zh-cn': '取消',
    'de': 'Abbrechen',
    'en': 'Cancel',
    'es': 'Cancelar',
    'tl': 'Kanselahin',
    'fr': 'Annuler',
    'it': 'Annulla',
    'ja': 'キャンセル',
    'ru': 'Отмена',
  },
  'save': {
    'zh-cn': '保存',
    'de': 'Speichern',
    'en': 'Save',
    'es': 'Guardar',
    'tl': 'I-save',
    'fr': 'Enregistrer',
    'it': 'Salva',
    'ja': '保存',
    'ru': 'Сохранить',
  },
  'reset': {
    'zh-cn': '重置',
    'de': 'Zurücksetzen',
    'en': 'Reset',
    'es': 'Reiniciar',
    'tl': 'I-reset',
    'fr': 'Réinitialiser',
    'it': 'Ripristina',
    'ja': 'リセット',
    'ru': 'Сбросить',
  },
  'create': {
    'zh-cn': '创建',
    'de': 'Erstellen',
    'en': 'Create',
    'es': 'Crear',
    'tl': 'Lumikha',
    'fr': 'Créer',
    'it': 'Crea',
    'ja': '作成',
    'ru': 'Создать',
  },
  'close': {
    'zh-cn': '关闭',
    'de': 'Schließen',
    'en': 'Close',
    'es': 'Cerrar',
    'tl': 'Isara',
    'fr': 'Fermer',
    'it': 'Chiudi',
    'ja': '閉じる',
    'ru': 'Закрыть',
  },
  'share': {
    'zh-cn': '分享',
    'de': 'Teilen',
    'en': 'Share',
    'es': 'Compartir',
    'tl': 'I-share',
    'fr': 'Partager',
    'it': 'Condividi',
    'ja': '共有',
    'ru': 'Поделиться',
  },
  'comment': {
    'zh-cn': '评论',
    'de': 'Kommentar',
    'en': 'Comment',
    'es': 'Comentario',
    'tl': 'Komento',
    'fr': 'Commentaire',
    'it': 'Commento',
    'ja': 'コメント',
    'ru': 'Комментарий',
  },
  'publish': {
    'zh-cn': '发布',
    'de': 'Veröffentlichen',
    'en': 'Publish',
    'es': 'Publicar',
    'tl': 'I-publish',
    'fr': 'Publier',
    'it': 'Pubblica',
    'ja': '公開',
    'ru': 'Опубликовать',
  },
  'link': {
    'zh-cn': '链接',
    'de': 'Link',
    'en': 'Link',
    'es': 'Enlace',
    'tl': 'Link',
    'fr': 'Lien',
    'it': 'Collegamento',
    'ja': 'リンク',
    'ru': 'Ссылка',
  },
  'yes': {'zh-cn': '是的', 'de': 'Ja', 'en': 'Yes', 'es': 'Sí', 'tl': 'Oo', 'fr': 'Oui', 'it': 'Sì', 'ja': 'はい', 'ru': 'Да'},
  'send': {
    'zh-cn': '发送',
    'de': 'Senden',
    'en': 'Send',
    'es': 'Enviar',
    'tl': 'Ipadala',
    'fr': 'Envoyer',
    'it': 'Invia',
    'ja': '送信',
    'ru': 'Отправить',
  },
  'support': {
    'zh-cn': '支持',
    'de': 'Unterstützung',
    'en': 'Support',
    'es': 'Soporte',
    'tl': 'Suporta',
    'fr': 'Support',
    'it': 'Supporto',
    'ja': 'サポート',
    'ru': 'Поддержка',
  },
  'settings': {
    'zh-cn': '设置',
    'de': 'Einstellungen',
    'en': 'Settings',
    'es': 'Configuración',
    'tl': 'Mga Setting',
    'fr': 'Paramètres',
    'it': 'Impostazioni',
    'ja': '設定',
    'ru': 'Настройки',
  },
  'donation': {
    'zh-cn': '捐赠',
    'de': 'Spende',
    'en': 'Donation',
    'es': 'Donación',
    'tl': 'Donasyon',
    'fr': 'Don',
    'it': 'Donazione',
    'ja': '寄付',
    'ru': 'Пожертвование',
  },
  'back': {
    'zh-cn': '返回',
    'de': 'Zurück',
    'en': 'Back',
    'es': 'Atrás',
    'tl': 'Bumalik',
    'fr': 'Retour',
    'it': 'Indietro',
    'ja': '戻る',
    'ru': 'Назад',
  },
  'confirm': {
    'zh-cn': '确认',
    'de': 'Bestätigen',
    'en': 'Confirm',
    'es': 'Confirmar',
    'tl': 'Kumpirmahin',
    'fr': 'Confirmer',
    'it': 'Conferma',
    'ja': '確認',
    'ru': 'Подтвердить',
  },
  'no': {'zh-cn': '没有', 'de': 'Nein', 'en': 'No', 'es': 'No', 'tl': 'Hindi', 'fr': 'Non', 'it': 'No', 'ja': 'いいえ', 'ru': 'Нет'},
  'swap': {
    'zh-cn': '交换',
    'de': 'Tauschen',
    'en': 'Swap',
    'es': 'Cambiar',
    'tl': 'Pagpalit',
    'fr': 'Échanger',
    'it': 'Scambia',
    'ja': '交換',
    'ru': 'Обмен',
  },
  'gift': {
    'zh-cn': '礼物',
    'de': 'Geschenk',
    'en': 'Gift',
    'es': 'Regalo',
    'tl': 'Regalo',
    'fr': 'Cadeau',
    'it': 'Regalo',
    'ja': '贈り物',
    'ru': 'Подарок',
  },
  'deposit': {
    'zh-cn': '存款',
    'de': 'Einzahlung',
    'en': 'Deposit',
    'es': 'Depósito',
    'tl': 'Deposito',
    'fr': 'Dépôt',
    'it': 'Deposito',
    'ja': '入金',
    'ru': 'Депозит',
  },
  'repost': {
    'zh-cn': '转发',
    'de': 'Duplikat',
    'en': 'Repost',
    'es': 'Republicar',
    'tl': 'I-repost',
    'fr': 'Republier',
    'it': 'Ripubblica',
    'ja': '再投稿',
    'ru': 'Репост',
  },
};

class TranslationCache {
  static const int _maxSize = 20000;
  static const int _cleanupThreshold = 24000; // ~20% tolerance

  TranslationCache(this.ref);
  final Ref ref;

  // Use the public method from the model class
  String _generateKey(String key, String languageCode) {
    return CachedTranslationDb.generateCacheKey(key, languageCode);
  }

  Future<String?> get(String key, String languageCode) async {
    // First check static vocabulary
    final staticTranslation = _getStaticTranslation(key, languageCode);
    if (staticTranslation != null) {
      return staticTranslation;
    }

    // Fall back to cache
    final isar = await ref.read(unifiedIsarProvider.future);
    final cacheKey = _generateKey(key, languageCode);

    final cached = await isar.cachedTranslationDbs.where().cacheKeyEqualTo(cacheKey).findFirst();

    return cached?.translatedText;
  }

  String? _getStaticTranslation(String key, String languageCode) {
    if (key.length > 20) return null;
    // Normalize the key to lowercase for case-insensitive matching
    final normalizedKey = key.toLowerCase().trim();

    // Check if the key exists in our static vocabulary
    final languageTranslations = _staticVocabulary[normalizedKey];
    if (languageTranslations != null) {
      // Return the translation for the specific language
      return languageTranslations[languageCode];
    }

    return null;
  }

  // Future<String?> get(String key, String languageCode) async {
  //   final isar = await ref.read(unifiedIsarProvider.future);
  //   final cacheKey = _generateKey(key, languageCode);
  //
  //   final cached = await isar.cachedTranslationDbs.where().cacheKeyEqualTo(cacheKey).findFirst();
  //
  //   return cached?.translatedText;
  // }

  Future<void> put(String key, String languageCode, String translatedText) async {
    final isar = await ref.read(unifiedIsarProvider.future);

    await isar.writeTxn(() async {
      final cacheKey = _generateKey(key, languageCode);

      // Check if exists using indexed cacheKey
      final existing = await isar.cachedTranslationDbs.where().cacheKeyEqualTo(cacheKey).findFirst();

      if (existing != null) {
        // Update existing
        existing.translatedText = translatedText;
        await isar.cachedTranslationDbs.put(existing);
      } else {
        // Create new entry
        final newEntry = CachedTranslationDb.fromTranslation(key, languageCode, translatedText);
        await isar.cachedTranslationDbs.put(newEntry);

        // Only enforce size limit when we're over tolerance threshold
        await _enforceSizeLimitIfNeeded(isar);
      }
    });
  }

  Future<void> clear() async {
    final isar = await ref.read(unifiedIsarProvider.future);
    await isar.writeTxn(() async {
      await isar.cachedTranslationDbs.clear();
    });
  }

  Future<int> get size async {
    final isar = await ref.read(unifiedIsarProvider.future);
    return await isar.cachedTranslationDbs.count();
  }

  /// Enforce FIFO size limit only when significantly over limit
  Future<void> _enforceSizeLimitIfNeeded(Isar isar) async {
    final currentSize = await isar.cachedTranslationDbs.count();
    if (currentSize <= _cleanupThreshold) return;

    final entriesToRemove = currentSize - _maxSize;

    // Auto-increment IDs are naturally ordered by insertion order (FIFO)
    // Just get the first N entries - they're the oldest
    final oldEntries = await isar.cachedTranslationDbs
        .where()
        .limit(entriesToRemove) // No sort needed - natural order is FIFO!
        .findAll();

    await isar.cachedTranslationDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 TranslationCache: Removed $entriesToRemove entries (was $currentSize)');
  }

  @override
  String toString() {
    return 'TranslationCache(maxSize: $_maxSize, cleanupThreshold: $_cleanupThreshold)';
  }
}

// Provider for the cache
final translationCacheProvider = Provider<TranslationCache>((ref) {
  return TranslationCache(ref);
});

// The rest of your existing code remains the same:
class PostTranslationParams {
  final MemoModelPost post;
  final bool doTranslate;
  // final String text;
  // final BuildContext context;
  final String languageCode;

  const PostTranslationParams({
    required this.post,
    required this.doTranslate,
    // required this.text,
    // required this.context,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostTranslationParams &&
          runtimeType == other.runtimeType &&
          post.id == other.post.id &&
          doTranslate == other.doTranslate &&
          // text == other.text &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(post.id, doTranslate, languageCode);
}

final postTranslationViewerProvider = FutureProvider.family<String, PostTranslationParams>((ref, params) async {
  final translationService = ref.read(translationServiceProvider);
  final translationCache = ref.read(translationCacheProvider);
  final sequencer = ref.read(translationSequencerProvider);

  // Check cache first
  final cachedTranslation = await translationCache.get(params.post.id!, params.languageCode);
  if (cachedTranslation != null) {
    print("📚 TranslationCache: Cache HIT for post: ${params.post.id}, lang: ${params.languageCode}");
    return cachedTranslation;
  }

  print("📚 TranslationCache: Cache MISS for post: ${params.post.id}, lang: ${params.languageCode}");

  final requestId = '${params.post.id}|${params.languageCode}';

  return sequencer.enqueue(requestId, () async {
    // print("🎯 SEQUENCER: Processing translation for post: ${params.post.id}");

    final result = await translationService.translatePostForViewer(
      params.post,
      params.doTranslate,
      // params.text,
      // params.context,
      params.languageCode,
    );

    // Store result in cache
    await translationCache.put(params.post.id!, params.languageCode, result);

    // print("🎯 SEQUENCER: Completed translation for post: ${params.post.id}");
    return result;
  });
});

final translationSequencerProvider = Provider<TranslationSequencer>((ref) {
  return TranslationSequencer();
});
