import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class LoggerIcon extends StatelessWidget {
  final String assetPath;
  final double height;
  final double width;
  final Color? color;

  const LoggerIcon({
    super.key,
    required this.assetPath,
    this.height = 20,
    this.width = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      height: height,
      width: width,
      colorFilter: ColorFilter.mode(
        color ?? Get.theme.iconTheme.color!,
        BlendMode.color,
      ),
      fit: BoxFit.scaleDown,
    );
  }
}
