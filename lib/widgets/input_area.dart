import 'package:flutter/material.dart';

///Sammenhengende område for håndtering av
///input interaksjon, som tekstfelt og
///diverse knapper
class InputArea extends StatelessWidget {
  // Callback når 'nytt mål' knapp trykkes på
  final VoidCallback onAddNewGoalBtnPressed;

  // Callback når 'ny liste' knapp trykkes på
  final VoidCallback onAddNewListBtnPressed;

  // Controller for tekstfeltet
  final TextEditingController textController;

  // Focus node for tekstfeltet
  final FocusNode focusNode;

  // Feilmelding som skal vises
  final String? errorText;

  // Om en er i landskap-modus
  final bool isLandscape;

  // Offset for landskap-layout
  final double landscapeOffset;

  // Callback når tekst endres i tekstfeltet
  final Function(String) onTextChanged;

  const InputArea({
    super.key,
    required this.onAddNewGoalBtnPressed,
    required this.onAddNewListBtnPressed,
    required this.textController,
    required this.focusNode,
    required this.isLandscape,
    this.errorText,
    this.landscapeOffset = 10,
    required this.onTextChanged,
  });

  /// Style for grønn outlined knapp
  ButtonStyle _greenOutlinedButtonStyle({double? width}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.green, width: 2),
      minimumSize: Size(width ?? 0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  /// Style for gul outlined knapp
  ButtonStyle _yellowOutlinedButtonStyle({double? width}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      side: BorderSide(color: Colors.yellow, width: 2),
      minimumSize: Size(width ?? 0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  /// Bygger tekstfelt
  Widget _constructTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey, width: 2),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Skriv inn nytt mål',
              hintStyle: TextStyle(color: Colors.black45),
              border: InputBorder.none,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAddNewGoalBtnPressed(),
            onChanged: (value) {
              if (errorText != null) onTextChanged(value);
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final newGoalBtn = ElevatedButton(
      onPressed: onAddNewGoalBtnPressed,
      style: _greenOutlinedButtonStyle(),
      child: const Text('Nytt mål'),
    );

    final newListBtn = ElevatedButton(
      onPressed: onAddNewListBtnPressed,
      style: _yellowOutlinedButtonStyle(),
      child: const Text('Ny liste'),
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: landscapeOffset),
            Expanded(child: _constructTextField()),
            const SizedBox(width: 8),
            newGoalBtn,
            const SizedBox(width: 8),
            newListBtn,
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _constructTextField(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: newGoalBtn),
                const SizedBox(width: 8),
                Expanded(child: newListBtn),
              ],
            ),
          ],
        ),
      );
    }
  }
}