import 'package:flutter/material.dart';
import 'package:trackify/types/card_theme.dart';

class ColorGrid extends StatelessWidget {
  final List<CardThemeColors> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ColorGrid({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const double itemSize = 24; // circular swatch size
    const double spacing = 10;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center, // centers the row(s)
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(options.length, (i) {
              final opt = options[i];
              final isSelected = i == selectedIndex;

              return InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(itemSize),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [opt.topLeft, opt.bottomRight],
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 14),
                  )
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
