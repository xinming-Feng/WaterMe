import 'package:flutter/material.dart';

class PixelTitle extends StatelessWidget {
  final bool centerTitle;
  final double height;
  
  const PixelTitle({
    Key? key, 
    this.centerTitle = false, 
    this.height = 40
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
      child: Image.asset(
        'assets/images/waterme_title.png',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
} 