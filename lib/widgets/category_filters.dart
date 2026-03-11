import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class CategoryFilters extends StatelessWidget {
  const CategoryFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = ['All', 'Health', 'Work', 'Study', 'Personal'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = categories[index];
          final isSelected = appState.selectedFilter == filter;

          return GestureDetector(
            onTap: () => appState.setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
