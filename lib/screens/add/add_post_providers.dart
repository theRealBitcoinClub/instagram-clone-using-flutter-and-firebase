import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memo/model/memo_model_user.dart';

// State providers for each media type
final imgurUrlProvider = StateProvider<String>((ref) => '');
final youtubeVideoIdProvider = StateProvider<String>((ref) => '');
final ipfsCidProvider = StateProvider<String>((ref) => '');
final odyseeUrlProvider = StateProvider<String>((ref) => '');

// Provider for YouTube controller
// final youtubeControllerProvider = StateProvider<YoutubePlayerController?>((ref) => null);

// Provider to track publishing state
final isPublishingProvider = StateProvider<bool>((ref) => false);

// Provider for tag controller text
final tagTextProvider = StateProvider<String>((ref) => '');

final temporaryTipAmountProvider = StateProvider<TipAmount?>((ref) => null);
