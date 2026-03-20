import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/habits_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/timer_screen.dart';
import '../screens/task_management_screen.dart';
import '../screens/history_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/training_screen.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A75E4),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7A75E4).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'FocusDay',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.list_bullet,
              title: 'Tasks (Home)',
              onTap: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.calendar,
              title: 'Calendar',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.square_list,
              title: 'Manage Tasks',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const TaskManagementScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.flame_fill,
              title: 'Habits',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const HabitsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.clock_fill,
              title: 'History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.graph_square_fill,
              title: 'Stats',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const StatsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.book_fill,
              title: 'Daily Journal',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const JournalScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.sportscourt_fill,
              title: 'Training',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const TrainingScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: CupertinoIcons.timer,
              title: 'Focus Timer',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const TimerScreen()),
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'FocusDay App v1.0\nDesigned for iOS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
