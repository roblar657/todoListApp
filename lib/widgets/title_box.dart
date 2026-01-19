import 'package:flutter/material.dart';
///Brukt for å vise en tittel (til en liste), f.eks
///fulført / ikke fulført
class TitleBox extends StatelessWidget {
  final String title;
  final bool isLandscape;

  const TitleBox({
    super.key,
    required this.title,
    this.isLandscape = true,
  });

  @override
  Widget build(BuildContext context) {
    final double height = isLandscape ? 60 : 40;
    final double width = isLandscape ? 120 : double.infinity;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      margin: isLandscape
          ? const EdgeInsets.only(right: 4)
          : const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
