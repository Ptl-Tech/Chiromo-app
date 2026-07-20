import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: child,
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  
  const ShimmerCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  
  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ShimmerCard(height: itemHeight),
    );
  }
}
