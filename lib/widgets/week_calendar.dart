import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class WeekCalendar extends StatefulWidget {
  const WeekCalendar({super.key});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  late ScrollController _scrollController;
  static const double _itemWidth = 60.0;
  // Show today + 59 future days (60 total)
  static const int _totalDays = 60;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _totalDays,
        itemBuilder: (context, index) {
          final date = _today.add(Duration(days: index));
          final isToday = index == 0;
          final isSelected =
              date.year == appState.selectedDate.year &&
              date.month == appState.selectedDate.month &&
              date.day == appState.selectedDate.day;

          return GestureDetector(
            onTap: () => appState.setDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: _itemWidth - 4,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isToday
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3)
                            : Theme.of(context).cardTheme.color!),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday
                        ? 'Today'
                        : DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: isToday ? 11 : 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  // Task indicator dots
                  Builder(
                    builder: (context) {
                      final dayTasks = appState.taskBox.values
                          .where(
                            (t) =>
                                t.date.year == date.year &&
                                t.date.month == date.month &&
                                t.date.day == date.day,
                          )
                          .toList();

                      if (dayTasks.isEmpty) {
                        return const SizedBox(height: 8); // Maintain spacing
                      }

                      // Gather up to 3 unique category colors
                      final primaryColor = Theme.of(
                        context,
                      ).colorScheme.primary;
                      final catColors = dayTasks
                          .map((t) {
                            final cat = appState.categoryBox.values
                                .where((c) => c.title == t.type)
                                .firstOrNull;
                            return cat != null
                                ? Color(cat.colorValue)
                                : primaryColor;
                          })
                          .toSet()
                          .take(3)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: catColors
                              .map(
                                (color) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
