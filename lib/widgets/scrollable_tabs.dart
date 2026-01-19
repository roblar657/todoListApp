import 'package:flutter/material.dart';

/// Widget for scrollbare tabs med navigasjon
class ScrollableTabs extends StatelessWidget {
  /// Indeks på aktiv fane
  final int selectedIndex;

  /// Liste over navn på tabs
  final List<String> tabTitles;

  /// Controller for scroll av tabs
  final ScrollController scrollController;

  /// Callback når tab velges
  final ValueChanged<int> onTabSelected;

  /// Callback når aktiv tab skal slettes
  final VoidCallback onRemoveCurrentTab;

  /// Callback for scroll venstre
  final VoidCallback onScrollLeft;

  /// Callback for scroll høyre
  final VoidCallback onScrollRight;

  const ScrollableTabs({
    required this.selectedIndex,
    required this.tabTitles,
    required this.scrollController,
    required this.onTabSelected,
    required this.onRemoveCurrentTab,
    required this.onScrollLeft,
    required this.onScrollRight,
    super.key,
  });

  /// Style for rød outlined knapp
  ButtonStyle _redOutlinedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.red,
      side: const BorderSide(color: Colors.red, width: 2),
      minimumSize: const Size(80, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left_rounded, size: 36, color: Colors.black),
            onPressed: onScrollLeft,
          ),
          Expanded(
            child: tabTitles.isEmpty
                ? const Center(
              child: Text(
                'Legg til en ny liste ved å trykke på kanppen "Ny liste"',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                : SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < tabTitles.length; i++)
                    GestureDetector(
                      onTap: () => onTabSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == selectedIndex
                                  ? const Color(0xFF2E7D32)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          tabTitles[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: i == selectedIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right_rounded, size: 36, color: Colors.black),
            onPressed: onScrollRight,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: ElevatedButton(
              onPressed: onRemoveCurrentTab,
              style: _redOutlinedButtonStyle(),
              child: const Text('Slett', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}