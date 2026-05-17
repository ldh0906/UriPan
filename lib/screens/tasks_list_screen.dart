import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/item_detail_edit_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({
    super.key,
    required this.boardName,
    required this.tasks,
    required this.onTaskChanged,
    required this.onTaskDeleted,
  });

  static const routeName = '/tasks';

  final String boardName;
  final List<TaskItemData> tasks;
  final void Function(TaskItemData task, bool? value) onTaskChanged;
  final ValueChanged<TaskItemData> onTaskDeleted;

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  int selectedTab = 0;
  bool isSearching = false;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredTasks = switch (selectedTab) {
      1 => widget.tasks.where((task) => !task.isDone).toList(),
      2 => widget.tasks.where((task) => task.isDone).toList(),
      _ => widget.tasks,
    };
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final visibleTasks = normalizedQuery.isEmpty
        ? filteredTasks
        : filteredTasks
            .where(
              (task) =>
                  task.title.toLowerCase().contains(normalizedQuery) ||
                  task.assignee.toLowerCase().contains(normalizedQuery) ||
                  (task.memo?.toLowerCase().contains(normalizedQuery) ?? false),
            )
            .toList();

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 2),
      floatingActionButton: const AddItemFab(
        label: 'New Task',
        itemType: BoardItemType.task,
      ),
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
                    Expanded(
                        child: Text('Tasks',
                            style: Theme.of(context).textTheme.headlineSmall)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isSearching = !isSearching;
                          if (!isSearching) {
                            searchQuery = '';
                          }
                        });
                      },
                      icon: Icon(isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded),
                    ),
                  ],
                ),
                Text(
                  'Shared with ${widget.boardName}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mutedText),
                ),
                if (isSearching) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    hint: 'Search tasks',
                    leadingIcon: Icons.search_rounded,
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ],
                const SizedBox(height: 18),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Open')),
                    ButtonSegment(value: 2, label: Text('Completed')),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (value) =>
                      setState(() => selectedTab = value.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleTasks.isEmpty
                ? const EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No tasks here',
                    message: 'New shared tasks will appear in this list.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          widget.onTaskDeleted(task);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${task.title} deleted.')),
                          );
                        },
                        child: TaskCard(
                          item: task,
                          onTap: () => Navigator.pushNamed(
                            context,
                            ItemDetailEditScreen.routeName,
                            arguments: BoardItemEditArguments.fromTask(task),
                          ),
                          onChanged: (value) =>
                              widget.onTaskChanged(task, value),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
