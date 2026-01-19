import 'package:flutter/material.dart';

///En item, med justerbar bredde.
///
/// Følgende tilbys:
/// - Å toggle mellom ferdig-tilstander
/// - Fjerne item
class CheckListItem extends StatelessWidget {

  //Teksten som vises
  final String text;

  //Om item er i finished-list (har ferdig-tilstand)
  final bool isInFinishedList;

  //Hvorvidt item blir dragget
  final bool isBeingDragged;

  //Bredde til item
  final double? width;

  //Callback for å toggle mellom ferdig-tilstand
  final VoidCallback onToggle;

  //Callback for å fjerne item
  final VoidCallback onRemove;

  const CheckListItem({
    super.key,
    required this.text,
    required this.isInFinishedList,
    this.isBeingDragged = false,
    this.width,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 160,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isBeingDragged ? Colors.blue.shade200 : Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isInFinishedList,
            fillColor: WidgetStateProperty.resolveWith(
                  (states) => isInFinishedList ? Colors.green : Colors.white,
            ),
            checkColor: Colors.white,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
