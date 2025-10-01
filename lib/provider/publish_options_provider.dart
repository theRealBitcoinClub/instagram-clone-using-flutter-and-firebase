// // Add this to your provider file (or create a new one if needed)
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/provider/translation_service.dart';
// import 'package:mahakka/screens/add_post_controller.dart';
//
// import '../memo/model/memo_model_post.dart';
//
// class PostTranslation {
//   final bool publishInBothLanguages;
//   final String translatedText;
//   final Language? originalLanguage;
//   final Language? targetLanguage;
//
//   const PostTranslation({required this.publishInBothLanguages, required this.translatedText, this.originalLanguage, this.targetLanguage});
//
//   PostTranslation copyWith({bool? publishInBothLanguages, String? translatedText, Language? originalLanguage, Language? targetLanguage}) {
//     return PostTranslation(
//       publishInBothLanguages: publishInBothLanguages ?? this.publishInBothLanguages,
//       translatedText: translatedText ?? this.translatedText,
//       originalLanguage: originalLanguage ?? this.originalLanguage,
//       targetLanguage: targetLanguage ?? this.targetLanguage,
//     );
//   }
// }
//
// // Create a provider for publish options
// final postTranslationProvider = StateProvider<PostTranslation>((ref) {
//   return const PostTranslation(publishInBothLanguages: false, translatedText: "");
// });
//
// extension PostTranslationReset on StateController<PostTranslation> {
//   void reset() {
//     state = const PostTranslation(publishInBothLanguages: false, translatedText: "", originalLanguage: null, targetLanguage: null);
//   }
// }
//
// extension PostTranslationUtils on PostTranslation {
//   MemoModelPost applyTranslationAndAppendMediaUrl({required MemoModelPost post, required ref}) {
//     final useTranslation = targetLanguage != null && targetLanguage != originalLanguage;
//     Language? lang = useTranslation ? targetLanguage! : originalLanguage ?? null;
//     String languageFlag = lang != null ? lang.flag : "";
//     final content = useTranslation ? translatedText : post.text;
//     String mediaUrl = ref.read(addPostControllerProvider.notifier).getMediaUrl();
//
//     return post.copyWith(text: "$languageFlag $content${mediaUrl}");
//   }
// }
