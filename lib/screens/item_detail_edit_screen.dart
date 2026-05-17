import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ItemDetailEditScreen extends StatefulWidget {
  const ItemDetailEditScreen({
    super.key,
    required this.members,
    required this.onSave,
    this.initialType = BoardItemType.schedule,
    this.editingItem,
    this.defaultRequireConfirmation = true,
  });

  static const routeName = '/item-edit';

  final List<FamilyMember> members;
  final BoardItemType initialType;
  final BoardItemEditArguments? editingItem;
  final ValueChanged<BoardItemDraft> onSave;
  final bool defaultRequireConfirmation;

  @override
  State<ItemDetailEditScreen> createState() => _ItemDetailEditScreenState();
}

class _ItemDetailEditScreenState extends State<ItemDetailEditScreen> {
  late BoardItemType itemType = widget.initialType;
  late final TextEditingController titleController;
  late final TextEditingController dateController;
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;
  late final TextEditingController notesController;
  late DateTime selectedDate;
  TimeOfDay selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay selectedEndTime = const TimeOfDay(hour: 10, minute: 0);

  bool important = true;
  bool requireConfirmation = false;
  bool completed = false;
  final Set<int> selectedMembers = {0};

  @override
  void initState() {
    super.initState();
    final editingItem = widget.editingItem;
    titleController = TextEditingController(
      text: editingItem?.title ?? _defaultTitle(widget.initialType),
    );
    selectedDate = DateTime.now();
    dateController = TextEditingController(
      text: editingItem?.date ?? _formatDate(selectedDate),
    );
    startTimeController = TextEditingController(
      text: editingItem?.startTime.isNotEmpty == true
          ? editingItem!.startTime
          : _formatTime(selectedStartTime),
    );
    endTimeController = TextEditingController(
      text: editingItem?.endTime.isNotEmpty == true
          ? editingItem!.endTime
          : _formatTime(selectedEndTime),
    );
    notesController = TextEditingController(
      text: editingItem?.notes ?? _defaultNotes(widget.initialType),
    );
    important = editingItem?.isImportant ??
        (widget.initialType == BoardItemType.notice);
    requireConfirmation = editingItem?.requiresConfirmation ??
        (widget.initialType == BoardItemType.notice &&
            widget.defaultRequireConfirmation);
    completed = editingItem?.isCompleted ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    '${widget.editingItem == null ? 'New' : 'Edit'} ${_typeLabel(itemType)}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<BoardItemType>(
                    segments: const [
                      ButtonSegment(
                          value: BoardItemType.schedule,
                          label: Text('Schedule')),
                      ButtonSegment(
                          value: BoardItemType.task, label: Text('Task')),
                      ButtonSegment(
                          value: BoardItemType.notice, label: Text('Notice')),
                    ],
                    selected: {itemType},
                    showSelectedIcon: false,
                    onSelectionChanged: widget.editingItem == null
                        ? (value) {
                            setState(() {
                              itemType = value.first;
                              important = itemType == BoardItemType.notice
                                  ? true
                                  : important;
                              requireConfirmation =
                                  itemType == BoardItemType.notice;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Text('Title', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Enter title',
                    controller: titleController,
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(
                      title: 'Time & Date', icon: Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: itemType == BoardItemType.task ? 'Due Date' : 'Date',
                    hint: 'Type here...',
                    controller: dateController,
                    leadingIcon: Icons.event_rounded,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                  if (itemType != BoardItemType.notice) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Start Time',
                            hint: 'Type here...',
                            controller: startTimeController,
                            leadingIcon: Icons.schedule_rounded,
                            readOnly: true,
                            onTap: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'End Time',
                            hint: 'Type here...',
                            controller: endTimeController,
                            leadingIcon: Icons.schedule_rounded,
                            readOnly: true,
                            onTap: _pickEndTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: itemType == BoardItemType.notice
                        ? 'Audience'
                        : 'Assignees',
                    icon: Icons.group_rounded,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MemberChip(
                        label: 'Me',
                        initials: 'ME',
                        color: AppColors.primary,
                        selected: selectedMembers.contains(0),
                        onTap: () => _toggleMember(0),
                      ),
                      for (var index = 0;
                          index < widget.members.length;
                          index++)
                        _MemberChip(
                          label: _shortName(widget.members[index].name),
                          initials: widget.members[index].initials,
                          color: widget.members[index].color,
                          selected: selectedMembers.contains(index + 1),
                          onTap: () => _toggleMember(index + 1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SoftCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: important,
                          onChanged: (value) =>
                              setState(() => important = value),
                          title: const Text('Mark as Important'),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: requireConfirmation,
                          onChanged: (value) =>
                              setState(() => requireConfirmation = value),
                          title: const Text('Require Confirmation'),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (itemType == BoardItemType.task) ...[
                          const Divider(height: 1),
                          CheckboxListTile(
                            value: completed,
                            onChanged: (value) =>
                                setState(() => completed = value ?? false),
                            title: const Text('Mark as Completed'),
                            subtitle: const Text('Useful for chores and tasks'),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(
                      title: 'Notes', icon: Icons.notes_rounded),
                  const SizedBox(height: 10),
                  AppTextField(
                    hint: 'Add extra details here...',
                    controller: notesController,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save ${_typeLabel(itemType)}',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;
    setState(() {
      selectedDate = date;
      dateController.text = _formatDate(date);
    });
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
    );
    if (time == null) return;
    setState(() {
      selectedStartTime = time;
      startTimeController.text = _formatTime(time);
    });
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );
    if (time == null) return;
    setState(() {
      selectedEndTime = time;
      endTimeController.text = _formatTime(time);
    });
  }

  void _save() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    final member = _selectedMember();
    widget.onSave(
      BoardItemDraft(
        id: widget.editingItem?.id,
        type: itemType,
        title: title,
        date: _fallback(dateController.text, 'Today'),
        startTime: _fallback(startTimeController.text, '09:00 AM'),
        endTime: _fallback(endTimeController.text, '10:00 AM'),
        assignee: member.name,
        initials: member.initials,
        color: member.color,
        isImportant: important,
        requiresConfirmation: requireConfirmation,
        isCompleted: completed,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_typeLabel(itemType)} ${widget.editingItem == null ? 'saved' : 'updated'}.',
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      _destinationRoute(itemType),
      (route) => route.isFirst,
    );
  }

  void _toggleMember(int index) {
    setState(() {
      if (selectedMembers.contains(index)) {
        selectedMembers.remove(index);
      } else {
        selectedMembers.add(index);
      }
      if (selectedMembers.isEmpty) {
        selectedMembers.add(0);
      }
    });
  }

  _DraftMember _selectedMember() {
    final selected = selectedMembers.first;
    if (selected == 0) {
      return const _DraftMember(
        name: 'Me',
        initials: 'ME',
        color: AppColors.primary,
      );
    }

    final index = selected - 1;
    if (index >= 0 && index < widget.members.length) {
      final member = widget.members[index];
      return _DraftMember(
        name: _shortName(member.name),
        initials: member.initials,
        color: member.color,
      );
    }

    return const _DraftMember(
      name: 'Me',
      initials: 'ME',
      color: AppColors.primary,
    );
  }

  String _shortName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isEmpty ? fullName : parts.first;
  }

  String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }

  String _typeLabel(BoardItemType type) {
    return switch (type) {
      BoardItemType.schedule => 'Schedule',
      BoardItemType.task => 'Task',
      BoardItemType.notice => 'Notice',
    };
  }

  String _destinationRoute(BoardItemType type) {
    return switch (type) {
      BoardItemType.schedule => '/calendar',
      BoardItemType.task => '/tasks',
      BoardItemType.notice => '/notices',
    };
  }

  String _defaultTitle(BoardItemType type) {
    return switch (type) {
      BoardItemType.schedule => 'Weekend Hiking Trip',
      BoardItemType.task => 'Prepare dinner groceries',
      BoardItemType.notice => 'Weekend Trip Reminder',
    };
  }

  String _defaultNotes(BoardItemType type) {
    return switch (type) {
      BoardItemType.schedule =>
        "Meet at the trailhead by 8:45 AM. Don't forget water and snacks!",
      BoardItemType.task => 'Add any details needed to finish this task.',
      BoardItemType.notice => 'Share the details everyone should read.',
    };
  }
}

class _DraftMember {
  const _DraftMember({
    required this.name,
    required this.initials,
    required this.color,
  });

  final String name;
  final String initials;
  final Color color;
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.initials,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String initials;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberAvatar(initials: initials, color: color, size: 28),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
