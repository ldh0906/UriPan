import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class BoardSettingsSheet extends StatelessWidget {
  const BoardSettingsSheet({
    super.key,
    required this.boardName,
    this.userName,
    this.boards = const [],
    this.activeBoardId,
    this.onSelectBoard,
    this.myProfile,
    this.onEditProfile,
    this.onEditBoard,
    required this.onSignOut,
  });

  final String boardName;
  final String? userName;
  final List<BoardSummary> boards;
  final String? activeBoardId;
  final ValueChanged<String>? onSelectBoard;
  final UserProfile? myProfile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditBoard;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final userName = this.userName;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(boardName, style: Theme.of(context).textTheme.titleLarge),
            if (userName != null && userName.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
            ],
            if (boards.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                '\uBCF4\uB4DC \uBC14\uAFB8\uAE30',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...boards.map((board) {
                final isActive = board.id == activeBoardId;
                return _BoardSwitcherRow(
                  board: board,
                  isActive: isActive,
                  onTap: isActive || onSelectBoard == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          onSelectBoard!(board.id);
                        },
                );
              }),
            ],
            if (myProfile != null && onEditProfile != null) ...[
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MemberAvatar(
                  displayName: myProfile!.displayName,
                  avatarColor: myProfile!.avatarColor,
                ),
                title: const Text('\uB0B4 \uC815\uBCF4'),
                subtitle: Text(myProfile!.displayName),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onEditProfile,
              ),
            ],
            if (_activeBoard?.isAdmin == true && onEditBoard != null) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_rounded),
                title: const Text('\uBCF4\uB4DC \uC124\uC815'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onEditBoard,
              ),
            ],
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded),
              title: const Text('\uB85C\uADF8\uC544\uC6C3'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }

  BoardSummary? get _activeBoard {
    for (final board in boards) {
      if (board.id == activeBoardId) return board;
    }
    return null;
  }
}

class EditBoardSettingsResult {
  const EditBoardSettingsResult({required this.name, required this.maxMembers});

  final String name;
  final int maxMembers;
}

class EditBoardSettingsSheet extends StatefulWidget {
  const EditBoardSettingsSheet({super.key, required this.board});

  final BoardSummary board;

  @override
  State<EditBoardSettingsSheet> createState() => _EditBoardSettingsSheetState();
}

class _EditBoardSettingsSheetState extends State<EditBoardSettingsSheet> {
  late final TextEditingController _nameController;
  late int _maxMembers;
  String? _nameErrorText;

  int get _minMembers => widget.board.memberCount.clamp(2, 20);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.board.name);
    _maxMembers = widget.board.maxMembers.clamp(_minMembers, 20).toInt();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameErrorText =
            '\uBCF4\uB4DC \uC774\uB984\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
      });
      return;
    }
    if (name.length > 80) {
      setState(() {
        _nameErrorText =
            '\uBCF4\uB4DC \uC774\uB984\uC740 80\uC790 \uC774\uD558\uC5EC\uC57C \uD574\uC694.';
      });
      return;
    }

    Navigator.pop(
      context,
      EditBoardSettingsResult(name: name, maxMembers: _maxMembers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDecrease = _maxMembers > _minMembers;
    final canIncrease = _maxMembers < 20;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uBCF4\uB4DC \uC124\uC815',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: '\uBCF4\uB4DC \uC774\uB984',
                errorText: _nameErrorText,
                counterText: '',
              ),
              onChanged: (_) {
                if (_nameErrorText != null) {
                  setState(() => _nameErrorText = null);
                }
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\uC815\uC6D0',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '\uC815\uC6D0 \uC904\uC774\uAE30',
                  onPressed: canDecrease
                      ? () => setState(() => _maxMembers -= 1)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_maxMembers',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '\uC815\uC6D0 \uB298\uB9AC\uAE30',
                  onPressed: canIncrease
                      ? () => setState(() => _maxMembers += 1)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            Slider(
              value: _maxMembers.toDouble(),
              min: _minMembers.toDouble(),
              max: 20,
              divisions: _minMembers < 20 ? 20 - _minMembers : null,
              label: '$_maxMembers',
              onChanged: (value) {
                setState(() => _maxMembers = value.round());
              },
            ),
            Text(
              '\uD604\uC7AC \uC778\uC6D0 ${widget.board.memberCount}\uBA85',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('\uCDE8\uC18C'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _save,
                  child: const Text('\uC800\uC7A5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileResult {
  const EditProfileResult({
    required this.displayName,
    required this.avatarColor,
  });

  final String displayName;
  final String avatarColor;
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const _palette = [
    '#647D31',
    '#E7A14B',
    '#4B7BE7',
    '#C2497A',
    '#3FA796',
    '#8A6FE0',
  ];

  late final TextEditingController _displayNameController;
  late String _selectedColor;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _selectedColor = _palette.contains(widget.profile.avatarColor)
        ? widget.profile.avatarColor
        : _palette.first;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _save() {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      setState(() {
        _errorText = '\uC774\uB984\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
      });
      return;
    }
    if (displayName.length > 60) {
      setState(() {
        _errorText =
            '\uC774\uB984\uC740 60\uC790 \uC774\uD558\uC5EC\uC57C \uD574\uC694.';
      });
      return;
    }

    Navigator.pop(
      context,
      EditProfileResult(displayName: displayName, avatarColor: _selectedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _displayNameController.text.trim().isEmpty
        ? widget.profile.displayName
        : _displayNameController.text.trim();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uB0B4 \uC815\uBCF4',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                MemberAvatar(
                  displayName: previewName,
                  avatarColor: _selectedColor,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _displayNameController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: '\uC774\uB984',
                      errorText: _errorText,
                      counterText: '',
                    ),
                    onChanged: (_) {
                      if (_errorText != null) setState(() => _errorText = null);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '\uC544\uBC14\uD0C0 \uC0C9\uC0C1',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _palette
                  .map((color) {
                    final selected = color == _selectedColor;
                    return _AvatarColorButton(
                      colorHex: color,
                      selected: selected,
                      onTap: () => setState(() => _selectedColor = color),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('\uCDE8\uC18C'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _save,
                  child: const Text('\uC800\uC7A5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarColorButton extends StatelessWidget {
  const _AvatarColorButton({
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: colorHex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _colorFromHex(colorHex),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.text : Colors.white,
              width: selected ? 3 : 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }

  Color _colorFromHex(String value) {
    final hex = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return AppColors.primary;
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _BoardSwitcherRow extends StatelessWidget {
  const _BoardSwitcherRow({
    required this.board,
    required this.isActive,
    required this.onTap,
  });

  final BoardSummary board;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.primary
        : AppColors.text.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySoft : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            board.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        RoleChip(role: board.role),
                        CapacityChip(
                          count: board.memberCount,
                          max: board.maxMembers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBoardSettingsSheet(
  BuildContext context, {
  required String boardName,
  String? userName,
  List<BoardSummary> boards = const [],
  String? activeBoardId,
  ValueChanged<String>? onSelectBoard,
  UserProfile? myProfile,
  VoidCallback? onEditProfile,
  VoidCallback? onEditBoard,
  required VoidCallback onSignOut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => BoardSettingsSheet(
      boardName: boardName,
      userName: userName,
      boards: boards,
      activeBoardId: activeBoardId,
      onSelectBoard: onSelectBoard,
      myProfile: myProfile,
      onEditProfile: onEditProfile,
      onEditBoard: onEditBoard,
      onSignOut: onSignOut,
    ),
  );
}

Future<EditProfileResult?> showEditProfileSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  return showModalBottomSheet<EditProfileResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => EditProfileSheet(profile: profile),
  );
}

Future<EditBoardSettingsResult?> showEditBoardSettingsSheet(
  BuildContext context, {
  required BoardSummary board,
}) {
  return showModalBottomSheet<EditBoardSettingsResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => EditBoardSettingsSheet(board: board),
  );
}
