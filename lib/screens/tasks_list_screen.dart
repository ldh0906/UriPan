import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({
    super.key,
    required this.tasks,
    required this.onTaskChanged,
  });

  static const routeName = '/tasks';

  final List<TaskItemData> tasks;
  final void Function(TaskItemData task, bool? value) onTaskChanged;

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = switch (selectedTab) {
      1 => widget.tasks.where((task) => !task.isDone).toList(),
      2 => widget.tasks.where((task) => task.isDone).toList(),
      _ => widget.tasks,
    };

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 2),
      floatingActionButton: const AddItemFab(label: 'New Task'),
      safeBottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Tasks', style: Theme.of(context).textTheme.headlineSmall)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                Text(
                  'Shared with Family Board',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 18),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Mine')),
                    ButtonSegment(value: 2, label: Text('Completed')),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (value) => setState(() => selectedTab = value.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
              itemCount: visibleTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = visibleTasks[index];
                return TaskCard(
                  item: task,
                  onChanged: (value) => widget.onTaskChanged(task, value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
