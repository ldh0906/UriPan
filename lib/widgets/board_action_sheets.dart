import 'package:flutter/material.dart';

import '../models/board_item.dart';

Future<BoardItemDraft?> showAddItemSheet(
  BuildContext context, {
  BoardItemType? initialType,
  List<BoardMember> members = const [],
  DateTime? initialDateTime,
}) {
  return showModalBottomSheet<BoardItemDraft>(
    context: context,
    builder: (context) => AddItemSheet(
      initialType: initialType,
      members: members,
      initialDateTime: initialDateTime,
    ),
  );
}

Future<BoardItemDraft?> showEditItemSheet(
  BuildContext context,
  BoardItem item, {
  List<BoardMember> members = const [],
}) {
  return showModalBottomSheet<BoardItemDraft>(
    context: context,
    builder: (context) => AddItemSheet(initialItem: item, members: members),
  );
}

DateTimeRange selectableDatePickerRange(DateTime initialDate, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final defaultFirstDate = today.subtract(const Duration(days: 365));
  final defaultLastDate = today.add(const Duration(days: 365 * 3));
  final initialDay = _dateOnly(initialDate);

  return DateTimeRange(
    start: initialDay.isBefore(defaultFirstDate)
        ? initialDay
        : defaultFirstDate,
    end: initialDay.isAfter(defaultLastDate) ? initialDay : defaultLastDate,
  );
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
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
  String? _nameError;

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
            decoration: InputDecoration(
              labelText: '\uBCF4\uB4DC \uC774\uB984',
              errorText: _nameError,
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
          onPressed: _submit,
          child: const Text('\uB9CC\uB4E4\uAE30'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(
        () => _nameError =
            '\uBCF4\uB4DC \uC774\uB984\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.',
      );
      return;
    }

    Navigator.pop(context, CreateBoardResult(name, _maxMembers.round()));
  }
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    this.initialType,
    this.initialItem,
    this.members = const [],
    this.initialDateTime,
  });

  final BoardItemType? initialType;
  final BoardItem? initialItem;
  final List<BoardMember> members;
  final DateTime? initialDateTime;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late BoardItemType _type;
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _tagController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _hasEndDate = false;
  bool _isPinned = false;
  bool _requiresConfirmation = true;
  String? _assignedToId;
  String? _titleError;
  String? _dateTimeError;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final initialItem = widget.initialItem;
    _type = initialItem?.type ?? widget.initialType ?? BoardItemType.task;
    final dateTime =
        initialItem?.startsAt ??
        initialItem?.dueAt ??
        widget.initialDateTime ??
        DateTime.now();
    _selectedDate = dateTime;
    _selectedTime = TimeOfDay.fromDateTime(dateTime);
    final endDateTime = initialItem?.type == BoardItemType.schedule
        ? initialItem?.dueAt
        : null;
    _hasEndDate = endDateTime != null;
    _endDate = endDateTime ?? dateTime;
    _endTime = TimeOfDay.fromDateTime(endDateTime ?? dateTime);

    if (initialItem != null) {
      _titleController.text = initialItem.title;
      _detailController.text = initialItem.detail;
      _tagController.text = initialItem.tags.join(', ');
      _isPinned = initialItem.isPinned;
      _requiresConfirmation = initialItem.requiresConfirmation;
      _assignedToId = initialItem.assignedToId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _tagController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing
                    ? '\uD56D\uBAA9 \uC218\uC815'
                    : '\uAC00\uC871 \uD56D\uBAA9 \uCD94\uAC00',
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
                onSelectionChanged: _isEditing
                    ? null
                    : (values) {
                        setState(() {
                          _type = values.single;
                          _dateTimeError = null;
                          if (_type == BoardItemType.schedule && !_hasEndDate) {
                            _endDate = _selectedDate;
                            _endTime = _selectedTime;
                          }
                        });
                      },
              ),
              const SizedBox(height: 12),
              if (_type == BoardItemType.schedule ||
                  _type == BoardItemType.task) ...[
                _DateTimePickerRow(
                  label: _type == BoardItemType.schedule
                      ? '\uC2DC\uC791'
                      : '\uB9C8\uAC10 \uB0A0\uC9DC',
                  date: _selectedDate,
                  time: _selectedTime,
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                ),
                if (_type == BoardItemType.schedule) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hasEndDate,
                    onChanged: (value) {
                      setState(() {
                        _hasEndDate = value;
                        _dateTimeError = null;
                        if (value) {
                          _endDate = _selectedDate;
                          _endTime = _selectedTime;
                        }
                      });
                    },
                    title: const Text('\uC885\uB8CC(\uC120\uD0DD)'),
                  ),
                  if (_hasEndDate) ...[
                    const SizedBox(height: 8),
                    _DateTimePickerRow(
                      label: '\uC885\uB8CC(\uC120\uD0DD)',
                      date: _endDate,
                      time: _endTime,
                      onPickDate: _pickEndDate,
                      onPickTime: _pickEndTime,
                    ),
                  ],
                ],
                if (_dateTimeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _dateTimeError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if (_type == BoardItemType.task &&
                  (widget.members.isNotEmpty || _assignedToId != null)) ...[
                DropdownButtonFormField<String>(
                  initialValue: _assigneeDropdownValue,
                  decoration: const InputDecoration(
                    labelText: '\uB2F4\uB2F9\uC790',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(
                        _hasMissingAssignee
                            ? '\uB2F4\uB2F9\uC790 \uC5C6\uC74C\uC73C\uB85C \uBCC0\uACBD'
                            : '\uB2F4\uB2F9\uC790 \uC5C6\uC74C',
                      ),
                    ),
                    ...widget.members.map(
                      (member) => DropdownMenuItem(
                        value: member.userId,
                        child: Text(member.effectiveName),
                      ),
                    ),
                    if (_hasMissingAssignee)
                      DropdownMenuItem(
                        value: _assignedToId,
                        child: const Text(
                          '\uD0C8\uD1F4\uD55C \uBA64\uBC84 \uC720\uC9C0 \uC911',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _assignedToId = value == null || value.isEmpty
                          ? null
                          : value;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '\uC81C\uBAA9',
                  errorText: _titleError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: '\uBA54\uBAA8'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: '\uD0DC\uADF8',
                  hintText:
                      '\uC608: \uBCD1\uC6D0, \uC900\uBE44\uBB3C, \uC5C4\uB9C8',
                  helperText:
                      '\uC27C\uD45C\uB098 \uACF5\uBC31\uC73C\uB85C \uCD5C\uB300 5\uAC1C',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_parsedTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _parsedTags
                      .map(
                        (tag) => InputChip(
                          label: Text('#$tag'),
                          onDeleted: () => _removeTag(tag),
                        ),
                      )
                      .toList(),
                ),
              ],
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
                onPressed: _submit,
                child: Text(_isEditing ? '\uC800\uC7A5' : '\uCD94\uAC00'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(
        () => _titleError =
            '\uC81C\uBAA9\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.',
      );
      return;
    }

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (_type == BoardItemType.schedule &&
        _hasEndDate &&
        endDateTime.isBefore(selectedDateTime)) {
      setState(
        () => _dateTimeError =
            '\uC885\uB8CC\uB294 \uC2DC\uC791\uBCF4\uB2E4 \uBE60\uB97C \uC218 \uC5C6\uC5B4\uC694.',
      );
      return;
    }
    if (!_isEditing &&
        (_type == BoardItemType.schedule || _type == BoardItemType.task) &&
        selectedDateTime.isBefore(
          DateTime.now().subtract(const Duration(minutes: 1)),
        )) {
      setState(
        () => _dateTimeError =
            '\uC9C0\uB09C \uC2DC\uAC04\uC740 \uC120\uD0DD\uD560 \uC218 \uC5C6\uC5B4\uC694.',
      );
      return;
    }

    Navigator.pop(
      context,
      BoardItemDraft(
        type: _type,
        title: title,
        detail: _detailController.text.trim(),
        startsAt: _type == BoardItemType.schedule ? selectedDateTime : null,
        dueAt: _type == BoardItemType.task
            ? selectedDateTime
            : _type == BoardItemType.schedule && _hasEndDate
            ? endDateTime
            : null,
        assignedTo: _type == BoardItemType.task ? _assignedToId : null,
        requiresConfirmation:
            _type == BoardItemType.notice && _requiresConfirmation,
        isPinned: _isPinned,
        tags: _parsedTags,
      ),
    );
  }

  List<String> get _parsedTags {
    return normalizeBoardItemTags(_tagController.text.split(RegExp(r'[,\s]+')));
  }

  String get _assigneeDropdownValue {
    final assignedToId = _assignedToId;
    if (assignedToId == null) return '';
    return assignedToId;
  }

  bool get _hasMissingAssignee {
    final assignedToId = _assignedToId;
    return assignedToId != null &&
        !widget.members.any((member) => member.userId == assignedToId);
  }

  void _removeTag(String tag) {
    final tags = _parsedTags.where((value) => value != tag).toList();
    _tagController.text = tags.join(', ');
    _tagController.selection = TextSelection.collapsed(
      offset: _tagController.text.length,
    );
    setState(() {});
  }

  Future<void> _pickDate() async {
    final range = selectableDatePickerRange(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOnly(_selectedDate),
      firstDate: range.start,
      lastDate: range.end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateTimeError = null;
      if (_type == BoardItemType.schedule && !_hasEndDate) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedTime = picked;
      _dateTimeError = null;
      if (_type == BoardItemType.schedule && !_hasEndDate) {
        _endTime = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final range = selectableDatePickerRange(_endDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOnly(_endDate),
      firstDate: range.start,
      lastDate: range.end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endDate = picked;
      _dateTimeError = null;
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endTime = picked;
      _dateTimeError = null;
    });
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
