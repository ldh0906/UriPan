import 'package:flutter/material.dart';

import '../models/board_item.dart';

Future<BoardItemDraft?> showAddItemSheet(
  BuildContext context, {
  BoardItemType? initialType,
}) {
  return showModalBottomSheet<BoardItemDraft>(
    context: context,
    showDragHandle: true,
    builder: (context) => AddItemSheet(initialType: initialType),
  );
}

class CreateBoardResult {
  const CreateBoardResult(this.name, this.maxMembers);

  final String name;
  final int maxMembers;
}

class CreateBoardDialog extends StatefulWidget {
  const CreateBoardDialog({super.key});

  @override
  State<CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends State<CreateBoardDialog> {
  final _nameController = TextEditingController(text: '\uC6B0\uB9AC\uC9D1');
  double _maxMembers = 4;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('\uBCF4\uB4DC \uB9CC\uB4E4\uAE30'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '\uBCF4\uB4DC \uC774\uB984',
            ),
          ),
          const SizedBox(height: 16),
          Text('\uCD5C\uB300 \uC778\uC6D0 ${_maxMembers.round()}\uBA85'),
          Slider(
            value: _maxMembers,
            min: 2,
            max: 20,
            divisions: 18,
            label: _maxMembers.round().toString(),
            onChanged: (value) => setState(() => _maxMembers = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            CreateBoardResult(_nameController.text.trim(), _maxMembers.round()),
          ),
          child: const Text('\uB9CC\uB4E4\uAE30'),
        ),
      ],
    );
  }
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, this.initialType});

  final BoardItemType? initialType;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late BoardItemType _type = widget.initialType ?? BoardItemType.task;
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  late TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPinned = false;
  bool _requiresConfirmation = true;

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uAC00\uC871 \uD56D\uBAA9 \uCD94\uAC00',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<BoardItemType>(
              segments: BoardItemType.values
                  .map(
                    (type) =>
                        ButtonSegment(value: type, label: Text(type.label)),
                  )
                  .toList(),
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() => _type = values.single);
              },
            ),
            const SizedBox(height: 12),
            if (_type == BoardItemType.schedule ||
                _type == BoardItemType.task) ...[
              _DateTimePickerRow(
                label: _type == BoardItemType.schedule
                    ? '\uC77C\uC815 \uB0A0\uC9DC'
                    : '\uB9C8\uAC10 \uB0A0\uC9DC',
                date: _selectedDate,
                time: _selectedTime,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '\uC81C\uBAA9'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(labelText: '\uBA54\uBAA8'),
            ),
            if (_type == BoardItemType.notice) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _requiresConfirmation,
                onChanged: (value) =>
                    setState(() => _requiresConfirmation = value),
                title: const Text(
                  '\uD655\uC778\uC774 \uD544\uC694\uD55C \uACF5\uC9C0',
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value),
              title: const Text('\uC704\uC5D0 \uACE0\uC815'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                final selectedDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );
                Navigator.pop(
                  context,
                  BoardItemDraft(
                    type: _type,
                    title: title,
                    detail: _detailController.text.trim(),
                    startsAt: _type == BoardItemType.schedule
                        ? selectedDateTime
                        : null,
                    dueAt: _type == BoardItemType.task
                        ? selectedDateTime
                        : null,
                    requiresConfirmation:
                        _type == BoardItemType.notice && _requiresConfirmation,
                    isPinned: _isPinned,
                  ),
                );
              },
              child: const Text('\uCD94\uAC00'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }
}

class _DateTimePickerRow extends StatelessWidget {
  const _DateTimePickerRow({
    required this.label,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(dateLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(timeLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
