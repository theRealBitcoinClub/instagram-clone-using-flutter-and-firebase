// lib/widgets/cached_avatar.dart

import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/widgets/image_detail_dialog.dart';

import '../providers/avatar_refresh_provider.dart';

class CachedAvatar extends ConsumerStatefulWidget {
  final String creatorId;
  final double radius;
  final bool showBadge;
  final bool enableNavigation;
  final String fallbackAsset;
  final Duration registrationCheckInterval;

  const CachedAvatar({
    Key? key,
    required this.creatorId,
    this.radius = 24,
    this.showBadge = true,
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

  @override
  void initState() {
    super.initState();
    _loadCreator();

    // _creatorFuture.then((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAvatar();
    });
    // _refreshAvatar();
    // });

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
    _creatorFuture = ref
        .read(creatorRepositoryProvider)
        .getCreator(
          widget.creatorId,
          saveToFirebase: false, // Never save to Firebase from here
        );
  }

  void _startRegistrationCheckTimer() {
    _registrationCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkRegistrationStatus();
    });
  }

  Future<void> _checkRegistrationStatus() async {
    final now = DateTime.now();
    final lastCheck = _lastRegistrationChecks[widget.creatorId];

    // Check if enough time has passed since last check
    if (lastCheck != null && now.difference(lastCheck) < widget.registrationCheckInterval) {
      return;
    }

    try {
      final creator = await _creatorFuture;
      if (creator != null && !creator.hasRegisteredAsUser) {
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
      // await creator.refreshUserHasRegistered(ref);

      // Update local cache with new registration status
      final updatedCreator = creator.copyWith(lastRegisteredCheck: DateTime.now());

      await ref
          .read(creatorRepositoryProvider)
          .saveToCache(
            updatedCreator,
            saveToFirebase: false, // Never save to Firebase
          );

      // Reload the creator to get updated data
      _loadCreator();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error refreshing user registration: $e");
    }
  }

  // In CachedAvatar's _refreshAvatar method
  Future<void> _refreshAvatar() async {
    if (!mounted) return;
    var notifier = ref.read(avatarRefreshStateProvider.notifier);
    final isAlreadyRefreshing = notifier.isRefreshing(widget.creatorId);

    if (isAlreadyRefreshing) {
      // Another CachedAvatar is already refreshing this creator, just wait for it
      return;
    }

    try {
      // Mark as refreshing
      notifier.setRefreshing(widget.creatorId, true);

      await ref.read(creatorRepositoryProvider).refreshAndCacheAvatar(widget.creatorId);

      _loadCreator();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error refreshing avatar: $e");
    } finally {
      // Always mark as not refreshing
      notifier.completeRefresh(widget.creatorId);
    }
  }

  void _navigateToProfile(MemoModelCreator? creator) async {
    if (!widget.enableNavigation && creator != null) {
      showCreatorImageDetail(context: context, creator: creator);
    }

    // Set the target profile ID
    ref.read(profileTargetIdProvider.notifier).state = widget.creatorId;
    // Switch to the profile tab
    ref.read(tabIndexProvider.notifier).setTab(AppTab.profile.tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final avatarRefreshState = ref.watch(avatarRefreshStateProvider);
    final isRefreshing = avatarRefreshState[widget.creatorId] ?? false;

    return FutureBuilder<MemoModelCreator?>(
      future: _creatorFuture,
      builder: (context, snapshot) {
        final creator = snapshot.data;
        final avatarUrl = creator?.profileImageAvatar() ?? '';
        final hasRegistered = creator?.hasRegisteredAsUser ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: () => _navigateToProfile(creator),
          onLongPress: _refreshAvatar,
          child: _buildAvatarWithBadge(context, avatarUrl, hasRegistered, isLoading, isRefreshing),
        );
      },
    );
  }

  Widget _buildFallbackImage() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      backgroundImage: AssetImage(widget.fallbackAsset),
      // child: Icon(Icons.person, size: widget.radius),
    );
  }

  Widget _buildAvatarWithBadge(BuildContext context, String avatarUrl, bool hasRegistered, bool isLoading, bool isRefreshing) {
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      child: avatarUrl.isEmpty
          ? _buildFallbackImage()
          : CachedNetworkImage(
              imageUrl: avatarUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: widget.radius,
                backgroundImage: imageProvider,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              placeholder: (context, url) => _buildFallbackImage(),
              errorWidget: (context, url, error) => _buildFallbackImage(),
            ),
    );

    // CircleAvatar(
    //   radius: widget.radius,
    //   backgroundColor: theme.colorScheme.surfaceVariant,
    //   backgroundImage: avatarUrl.isEmpty ? AssetImage(widget.fallbackAsset) as ImageProvider : CachedNetworkImageProvider(avatarUrl),
    //   onBackgroundImageError: (exception, stackTrace) {
    //     print("Error loading avatar image: $exception");
    //   },
    //   child: isLoading || isRefreshing ? Icon(Icons.person, size: widget.radius) : null,
    // );

    if (!widget.showBadge || !hasRegistered) {
      return avatar;
    }

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -2, end: -6),
      showBadge: true,
      onTap: () {},
      badgeContent: Icon(Icons.currency_bitcoin_rounded, color: theme.colorScheme.onPrimary, size: 15),
      badgeAnimation: badges.BadgeAnimation.fade(
        animationDuration: Duration(milliseconds: 5000),
        loopAnimation: true,
        colorChangeAnimationCurve: Curves.fastOutSlowIn,
      ),
      badgeStyle: badges.BadgeStyle(
        shape: badges.BadgeShape.circle,
        badgeColor: theme.colorScheme.primary,
        padding: EdgeInsets.all(1.5),
        borderSide: BorderSide(color: theme.colorScheme.onSurface, width: 0.8),
        elevation: 0,
      ),
      child: avatar,
    );
  }
}
