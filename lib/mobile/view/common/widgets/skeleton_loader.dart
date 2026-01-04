import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shape;

  const SkeletonWidget.rectangular({
    super.key,
    this.width,
    this.height,
  }) : shape = const RoundedRectangleBorder(), borderRadius = 0;

  const SkeletonWidget.circular({
    super.key,
    this.width,
    this.height,
  }) : shape = const CircleBorder(), borderRadius = 0;

  const SkeletonWidget.rounded({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
  }) : shape = const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)));

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[300],
          shape: shape is RoundedRectangleBorder && borderRadius != 0 
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius))
              : shape,
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget itemTemplate;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: itemTemplate,
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final Widget itemTemplate;
  final int crossAxisCount;
  final double childAspectRatio;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    required this.itemTemplate,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => itemTemplate,
    );
  }
}
