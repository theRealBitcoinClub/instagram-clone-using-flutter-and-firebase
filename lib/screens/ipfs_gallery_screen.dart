import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class IpfsConfig {
  static const String preferredNode = 'https://free-bch.fullstack.cash/ipfs/view/';
}

class IPFSGalleryScreen extends StatefulWidget {
  final List<String> ipfsCids;

  const IPFSGalleryScreen({Key? key, required this.ipfsCids}) : super(key: key);

  @override
  State<IPFSGalleryScreen> createState() => _IPFSGalleryScreenState();
}

class _IPFSGalleryScreenState extends State<IPFSGalleryScreen> {
  String? _selectedCid;
  bool get _hasSelection => _selectedCid != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasSelection ? 'Selected: ${_selectedCid!.substring(0, 8)}...' : 'My IPFS Gallery'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_hasSelection)
            IconButton(
              icon: Icon(Icons.add, color: colorScheme.primary),
              onPressed: _createNewIpfsPin,
              tooltip: 'Create new IPFS pin',
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.error),
              onPressed: _clearSelection,
              tooltip: 'Clear selection',
            ),
        ],
      ),
      body: Column(
        children: [
          // IPFS Images ListView
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: widget.ipfsCids.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: widget.ipfsCids.length,
                        itemBuilder: (context, index) {
                          final cid = widget.ipfsCids[index];
                          final isSelected = _selectedCid == cid;
                          return _buildImageCard(cid, isSelected, theme, colorScheme);
                        },
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Button Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AnimatedGrowFadeIn(
              show: !_hasSelection,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _createNewIpfsPin,
                  child: const Text('Create New IPFS Pin'),
                ),
              ),
            ),
          ),

          AnimatedGrowFadeIn(
            show: _hasSelection,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _clearSelection,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _shareImage,
                      child: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _reuseImage,
                      child: const Text('Reuse'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No IPFS images found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first IPFS pin to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String cid, bool isSelected, ThemeData theme, ColorScheme colorScheme) {
    final imageUrl = '${IpfsConfig.preferredNode}$cid';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: colorScheme.primary, width: 2) : BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () => _selectImage(cid),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                // Image
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: colorScheme.surfaceVariant,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceVariant,
                      child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary))),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.errorContainer,
                      child: Center(child: Icon(Icons.broken_image_outlined, size: 48, color: colorScheme.onErrorContainer)),
                    ),
                  ),
                ),

                // Selection badge
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Icon(Icons.check, size: 20, color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),

            // URL info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CID: ${cid.substring(0, 12)}...',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontFamily: 'Monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageUrl,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectImage(String cid) {
    setState(() {
      _selectedCid = cid;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCid = null;
    });
  }

  void _createNewIpfsPin() {
    Navigator.pop(context); // Return to create new IPFS pin screen
  }

  void _shareImage() {
    if (_selectedCid == null) return;

    final shareUrl = '${IpfsConfig.preferredNode}$_selectedCid';
    // Implement share functionality here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sharing: $_selectedCid'), backgroundColor: Theme.of(context).colorScheme.secondary));
  }

  void _reuseImage() {
    if (_selectedCid == null) return;

    Navigator.pop(context, _selectedCid);
  }
}

// AnimatedGrowFadeIn widget (as provided)
class AnimatedGrowFadeIn extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Duration delay;
  final Curve sizeCurve;
  final Curve fadeCurve;
  final AlignmentGeometry alignment;

  const AnimatedGrowFadeIn({
    Key? key,
    required this.child,
    required this.show,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.sizeCurve = Curves.fastOutSlowIn,
    this.fadeCurve = Curves.easeIn,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  State<AnimatedGrowFadeIn> createState() => _AnimatedGrowFadeInState();
}

class _AnimatedGrowFadeInState extends State<AnimatedGrowFadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: widget.duration, value: widget.show ? 1.0 : 0.0);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: widget.fadeCurve));
  }

  @override
  void didUpdateWidget(AnimatedGrowFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        if (widget.delay == Duration.zero) {
          _animationController.forward();
        } else {
          Future.delayed(widget.delay, () {
            if (mounted) _animationController.forward();
          });
        }
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedSize(
        duration: widget.duration,
        curve: widget.sizeCurve,
        alignment: widget.alignment,
        child: widget.show ? widget.child : Container(width: double.infinity),
      ),
    );
  }
}
