import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class GamePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool isGlass;
  final VoidCallback? onTap;

  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
    this.isGlass = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return _buildGlass();
    }
    return _buildSolid();
  }

  Widget _buildSolid() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlass() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.panel.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.border.withOpacity(0.5), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
