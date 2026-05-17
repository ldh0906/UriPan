import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ItemDetailEditScreen extends StatefulWidget {
  const ItemDetailEditScreen({super.key, required this.members});

  static const routeName = '/item-edit';

  final List<FamilyMember> members;

  @override
  State<ItemDetailEditScreen> createState() => _ItemDetailEditScreenState();
}

class _ItemDetailEditScreenState extends State<ItemDetailEditScreen> {
  int itemType = 0;
  bool important = true;
  bool requireConfirmation = false;
  bool completed = false;
  final Set<int> selectedMembers = {0, 1};

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
                    'Edit Item',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Schedule')),
                      ButtonSegment(value: 1, label: Text('Task')),
                      ButtonSegment(value: 2, label: Text('Notice')),
                    ],
                    selected: {itemType},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) => setState(() => itemType = value.first),
                  ),
                  const SizedBox(height: 18),
                  Text('Title', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const AppTextField(
                    hint: 'Enter title',
                    initialValue: 'Weekend Hiking Trip',
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Time & Date', icon: Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  const AppTextField(
                    label: 'Date',
                    hint: 'Type here...',
                    initialValue: 'Oct 24, 2023',
                    leadingIcon: Icons.event_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Start Time',
                          hint: 'Type here...',
                          initialValue: '09:00 AM',
                          leadingIcon: Icons.schedule_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'End Time',
                          hint: 'Type here...',
                          initialValue: '11:30 AM',
                          leadingIcon: Icons.schedule_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Assignees', icon: Icons.group_rounded),
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
                      for (var index = 0; index < widget.members.length; index++)
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: important,
                          onChanged: (value) => setState(() => important = value),
                          title: const Text('Mark as Important'),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: requireConfirmation,
                          onChanged: (value) => setState(() => requireConfirmation = value),
                          title: const Text('Require Confirmation'),
                          activeThumbColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          value: completed,
                          onChanged: (value) => setState(() => completed = value ?? false),
                          title: const Text('Mark as Completed'),
                          subtitle: const Text('Useful for chores and tasks'),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Notes', icon: Icons.notes_rounded),
                  const SizedBox(height: 10),
                  const AppTextField(
                    hint: 'Add extra details here...',
                    initialValue: "Meet at the trailhead by 8:45 AM. Don't forget water and snacks!",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Delete Item',
                    icon: Icons.delete_outline_rounded,
                    variant: ButtonVariant.destructive,
                    fullWidth: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMember(int index) {
    setState(() {
      if (selectedMembers.contains(index)) {
        selectedMembers.remove(index);
      } else {
        selectedMembers.add(index);
      }
    });
  }

  String _shortName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isEmpty ? fullName : parts.first;
  }
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
          border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceVariant),
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
