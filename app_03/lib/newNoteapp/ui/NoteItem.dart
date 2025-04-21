import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_02/newNoteapp/db/NoteDatabaseHelper.dart';
import "package:app_02/newNoteapp/model/NoteModel.dart";
import "package:app_02/newNoteapp/ui/NoteDetailScreen.dart";
import "package:app_02/newNoteapp/ui/NoteForm.dart";

class NoteItem extends StatefulWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteItem({super.key, required this.note, required this.onDelete});

  @override
  _NoteItemState createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color priorityColor = widget.note.priority == 1
        ? Colors.green
        : widget.note.priority == 2
        ? Colors.orange
        : Colors.red;

    Color backgroundColor;
    try {
      backgroundColor = widget.note.color != null
          ? Color(int.parse(widget.note.color!.replaceFirst('#', ''), radix: 16) + 0xFF000000)
          : Theme.of(context).cardTheme.color ?? Colors.white;
    } catch (e) {
      backgroundColor = Theme.of(context).cardTheme.color ?? Colors.white;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dismissible(
        key: Key(widget.note.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: const Text('Bạn có chắc muốn xóa ghi chú này không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          await NoteDatabaseHelper.instance.deleteNote(widget.note.id!);
          widget.onDelete();
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoteDetailScreen(note: widget.note)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [backgroundColor, backgroundColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, color: isDarkMode ? Colors.white70 : Colors.grey, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.note.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: priorityColor),
                          ),
                          child: Text(
                            widget.note.priority == 1
                                ? "Thấp"
                                : widget.note.priority == 2
                                ? "Trung bình"
                                : "Cao",
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.note.imagePath != null)
                          FutureBuilder<bool>(
                            future: File(widget.note.imagePath!).exists(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }
                              if (snapshot.hasData && snapshot.data == true) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(widget.note.imagePath!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                                    },
                                  ),
                                );
                              }
                              return const SizedBox(width: 40, height: 40);
                            },
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.note.content.length > 50
                                ? '${widget.note.content.substring(0, 50)}...'
                                : widget.note.content,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Thêm phần hiển thị tags nếu có
                    if (widget.note.tags != null && widget.note.tags!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.note.tags!
                            .map((tag) => Chip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          backgroundColor: priorityColor.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 70,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteFormScreen(note: widget.note),
                                ),
                              );
                              if (result == true) {
                                widget.onDelete();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              foregroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 70,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              bool? confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Xác nhận xóa'),
                                  content: const Text('Bạn có chắc muốn xóa ghi chú này không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await NoteDatabaseHelper.instance.deleteNote(widget.note.id!);
                                widget.onDelete();
                              }
                            },
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}