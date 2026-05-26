enum BoardItemType { schedule, task, notice }

class BoardItem {
  const BoardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.owner,
    required this.timeLabel,
    this.isDone = false,
    this.isPinned = false,
  });

  final String id;
  final BoardItemType type;
  final String title;
  final String detail;
  final String owner;
  final String timeLabel;
  final bool isDone;
  final bool isPinned;
}
