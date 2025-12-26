import 'package:flutter/material.dart';
import 'offline_progress_manager.dart';

/// A dialog widget to display offline progress rewards
class OfflineProgressDialog extends StatefulWidget {
  final OfflineProgressData data;
  final Map<String, String> resourceNames;
  final Map<String, IconData>? resourceIcons;
  final VoidCallback? onClaim;
  final VoidCallback? onClaimWithBonus;
  final VoidCallback? onSkip;
  final String? bonusButtonText;
  final double bonusMultiplier;
  final Color? primaryColor;

  const OfflineProgressDialog({
    super.key,
    required this.data,
    required this.resourceNames,
    this.resourceIcons,
    this.onClaim,
    this.onClaimWithBonus,
    this.onSkip,
    this.bonusButtonText,
    this.bonusMultiplier = 2.0,
    this.primaryColor,
  });

  @override
  State<OfflineProgressDialog> createState() => _OfflineProgressDialogState();
}

class _OfflineProgressDialogState extends State<OfflineProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(primaryColor),
                const SizedBox(height: 20),

                // Offline duration
                _buildDurationInfo(),
                const SizedBox(height: 20),

                // Rewards list
                _buildRewardsList(primaryColor),
                const SizedBox(height: 24),

                // Buttons
                _buildButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.card_giftcard,
            size: 48,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'You were away for ${widget.data.formattedDuration}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(Color primaryColor) {
    if (!widget.data.hasRewards) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No resources accumulated while you were away.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.data.rewards.length,
        itemBuilder: (context, index) {
          final entry = widget.data.rewards.entries.elementAt(index);
          final resourceId = entry.key;
          final amount = entry.value;
          final name = widget.resourceNames[resourceId] ?? resourceId;
          final icon = widget.resourceIcons?[resourceId] ?? Icons.star;

          return _RewardItemRow(
            icon: icon,
            name: name,
            amount: amount,
            color: primaryColor,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        // Claim button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onClaim?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Claim',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Bonus button (if available)
        if (widget.onClaimWithBonus != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                widget.onClaimWithBonus?.call();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.play_circle_outline),
              label: Text(
                widget.bonusButtonText ??
                    'Watch Ad for ${widget.bonusMultiplier.toInt()}x',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: primaryColor),
              ),
            ),
          ),
        ],

        // Skip button
        if (widget.onSkip != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              widget.onSkip?.call();
              Navigator.of(context).pop();
            },
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ],
    );
  }
}

class _RewardItemRow extends StatefulWidget {
  final IconData icon;
  final String name;
  final int amount;
  final Color color;
  final int index;

  const _RewardItemRow({
    required this.icon,
    required this.name,
    required this.amount,
    required this.color,
    required this.index,
  });

  @override
  State<_RewardItemRow> createState() => _RewardItemRowState();
}

class _RewardItemRowState extends State<_RewardItemRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Staggered animation
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '+${_formatNumber(widget.amount)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Helper function to show the offline progress dialog
Future<void> showOfflineProgressDialog(
  BuildContext context, {
  required OfflineProgressData data,
  required Map<String, String> resourceNames,
  Map<String, IconData>? resourceIcons,
  VoidCallback? onClaim,
  VoidCallback? onClaimWithBonus,
  VoidCallback? onSkip,
  String? bonusButtonText,
  double bonusMultiplier = 2.0,
  Color? primaryColor,
  bool barrierDismissible = false,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => OfflineProgressDialog(
      data: data,
      resourceNames: resourceNames,
      resourceIcons: resourceIcons,
      onClaim: onClaim,
      onClaimWithBonus: onClaimWithBonus,
      onSkip: onSkip,
      bonusButtonText: bonusButtonText,
      bonusMultiplier: bonusMultiplier,
      primaryColor: primaryColor,
    ),
  );
}
