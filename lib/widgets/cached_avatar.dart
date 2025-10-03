// lib/widgets/cached_avatar.dart

import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/widgets/image_detail_dialog.dart';

import '../provider/mute_creator_provider.dart';
import '../providers/avatar_refresh_provider.dart';
import '../providers/navigation_providers.dart';
import 'muted_creators_dialog.dart';

class CachedAvatar extends ConsumerStatefulWidget {
  final String creatorId;
  final double radius;
  final bool showBadge;
  final bool showMuteBadge; // New parameter for mute badge
  final bool enableNavigation;
  final String fallbackAsset;
  final Duration registrationCheckInterval;

  const CachedAvatar({
    Key? key,
    required this.creatorId,
    this.radius = 24,
    this.showBadge = true,
    this.showMuteBadge = true, // Default to true
    this.enableNavigation = true,
    this.fallbackAsset = "assets/images/default_profile.png",
    this.registrationCheckInterval = const Duration(minutes: 30),
  }) : super(key: key);

  @override
  _CachedAvatarState createState() => _CachedAvatarState();
}

class _CachedAvatarState extends ConsumerState<CachedAvatar> {
  late Future<MemoModelCreator?> _creatorFuture;
  Timer? _registrationCheckTimer;
  final Map<String, DateTime> _lastRegistrationChecks = {};
  bool _showMute = true;

  @override
  void initState() {
    super.initState();
    if (ref.read(userProvider)!.id == widget.creatorId) {
      setState(() {
        _showMute = false;
      });
    } else {
      _showMute = widget.showMuteBadge;
    }

    _loadCreator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAvatar();
    });

    _startRegistrationCheckTimer();
  }

  @override
  void didUpdateWidget(CachedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creatorId != widget.creatorId) {
      _loadCreator();
    }
  }

  @override
  void dispose() {
    _registrationCheckTimer?.cancel();
    super.dispose();
  }

  void _loadCreator() {
    _creatorFuture = ref.read(creatorRepositoryProvider).getCreator(widget.creatorId, saveToFirebase: false);
  }

  void _startRegistrationCheckTimer() {
    _registrationCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkRegistrationStatus();
    });
  }

  Future<void> _checkRegistrationStatus() async {
    final now = DateTime.now();
    final lastCheck = _lastRegistrationChecks[widget.creatorId];

    if (lastCheck != null && now.difference(lastCheck) < widget.registrationCheckInterval) {
      return;
    }

    try {
      final creator = await _creatorFuture;
      if (creator != null && !creator.hasRegisteredAsUserFixed) {
        await _refreshUserRegistration(creator);
        _lastRegistrationChecks[widget.creatorId] = now;
      }
    } catch (e) {
      print("Error checking registration status: $e");
    }
  }

  Future<void> _refreshUserRegistration(MemoModelCreator creator) async {
    try {
      await ref.read(creatorRepositoryProvider).refreshUserHasRegistered(creator);
      final updatedCreator = creator.copyWith(lastRegisteredCheck: DateTime.now());
      await ref.read(creatorRepositoryProvider).saveToCache(updatedCreator, saveToFirebase: false);
      _loadCreator();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error refreshing user registration: $e");
    }
  }

  Future<void> _refreshAvatar() async {
    if (!mounted) return;
    var notifier = ref.read(avatarRefreshStateProvider.notifier);
    final isAlreadyRefreshing = notifier.isRefreshing(widget.creatorId);

    if (isAlreadyRefreshing) {
      return;
    }

    try {
      notifier.setRefreshing(widget.creatorId, true);
      await ref.read(creatorRepositoryProvider).refreshAndCacheAvatar(widget.creatorId);
      _loadCreator();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error refreshing avatar: $e");
    } finally {
      notifier.completeRefresh(widget.creatorId);
    }
  }

  void _navigateToProfile(MemoModelCreator? creator) async {
    if (!widget.enableNavigation && creator != null) {
      showCreatorImageDetail(context: context, creator: creator);
    }
    ref.read(navigationStateProvider.notifier).navigateFromAvatarToProfile(widget.creatorId);
  }

  // New method to handle mute action
  void _handleMuteAction() {
    final isCurrentlyMuted = ref.read(muteCreatorProvider).contains(widget.creatorId);

    if (isCurrentlyMuted) {
      // Already muted - show dialog to manage muted creators
      showMutedCreatorsDialog(context);
    } else {
      // Mute the creator
      ref
          .read(muteCreatorProvider.notifier)
          .muteCreator(
            widget.creatorId,
            onMuteSuccess: () {
              showMutedCreatorsDialog(context);
            },
            onMutedAlready: () {
              showMutedCreatorsDialog(context);
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarRefreshState = ref.watch(avatarRefreshStateProvider);
    final isRefreshing = avatarRefreshState[widget.creatorId] ?? false;
    final mutedCreators = ref.watch(muteCreatorProvider);
    final isMuted = mutedCreators.contains(widget.creatorId);

    return FutureBuilder<MemoModelCreator?>(
      future: _creatorFuture,
      builder: (context, snapshot) {
        final creator = snapshot.data;
        final avatarUrl = creator?.profileImageAvatar() ?? '';
        final hasRegistered = creator?.hasRegisteredAsUserFixed ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: () => _navigateToProfile(creator),
          onLongPress: _refreshAvatar,
          child: _buildAvatarWithBadges(context, avatarUrl, hasRegistered, isLoading, isRefreshing, isMuted),
        );
      },
    );
  }

  Widget _buildFallbackImage() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      backgroundImage: AssetImage(widget.fallbackAsset),
    );
  }

  Widget _buildAvatarWithBadges(BuildContext context, String avatarUrl, bool hasRegistered, bool isLoading, bool isRefreshing, bool isMuted) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: colorScheme.surfaceVariant,
      child: avatarUrl.isEmpty
          ? _buildFallbackImage()
          : CachedNetworkImage(
              imageUrl: avatarUrl,
              imageBuilder: (context, imageProvider) =>
                  CircleAvatar(radius: widget.radius, backgroundImage: imageProvider, backgroundColor: colorScheme.surfaceVariant),
              placeholder: (context, url) => _buildFallbackImage(),
              errorWidget: (context, url, error) => _buildFallbackImage(),
            ),
    );

    // Start with the base avatar
    Widget finalAvatar = avatar;

    // Add registration badge (top right) if needed
    if (widget.showBadge && hasRegistered) {
      finalAvatar = badges.Badge(
        position: badges.BadgePosition.topEnd(top: -2, end: -6),
        showBadge: true,
        onTap: () {},
        badgeContent: Icon(Icons.currency_bitcoin_rounded, color: colorScheme.onPrimary, size: widget.radius / 2),
        badgeStyle: badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          badgeColor: colorScheme.primary,
          padding: EdgeInsets.all(1.5),
          borderSide: BorderSide(color: colorScheme.onSurface, width: 0.8),
          elevation: 0,
        ),
        child: finalAvatar,
      );
    }

    // Add mute badge (top left) if needed
    if (_showMute) {
      finalAvatar = badges.Badge(
        position: badges.BadgePosition.topStart(top: -3, start: -9),
        showBadge: true,
        onTap: _handleMuteAction,
        badgeContent: Icon(Icons.block_outlined, color: colorScheme.error.withAlpha(210), size: widget.radius / 2 * 1.35),
        badgeStyle: badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          badgeColor: colorScheme.onSurface.withAlpha(33),
          padding: EdgeInsets.all(0.1),
          // borderSide: BorderSide(color: colorScheme.outline, width: 0),
          elevation: 1,
        ),
        child: finalAvatar,
      );
    }

    return finalAvatar;
  }
}
