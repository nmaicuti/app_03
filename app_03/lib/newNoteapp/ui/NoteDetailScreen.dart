import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:app_02/newNoteapp/model/NoteModel.dart';
import 'package:app_02/newNoteapp/db/NoteAccountDatabaseHelper.dart';
import 'package:app_02/newNoteapp/ui/NoteForm.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  String? _username;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);

    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final account = await NoteAccountDatabaseHelper.instance.getAccountByUserId(widget.note.userId);
    setState(() {
      _username = account?.username ?? 'Unknown';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareNote() {
    final String shareText = '''
Title: ${widget.note.title}
Content: ${widget.note.content}
Created by: $_username
Priority: ${widget.note.priority == 1 ? "Low" : widget.note.priority == 2 ? "Medium" : "High"}
Created at: ${widget.note.createdAt}
Modified at: ${widget.note.modifiedAt}
Tags: ${widget.note.tags?.join(', ') ?? 'No tags'}
    ''';
    if (widget.note.imagePath != null && File(widget.note.imagePath!).existsSync()) {
      Share.shareFiles([widget.note.imagePath!], text: shareText, subject: widget.note.title);
    } else {
      Share.share(shareText, subject: widget.note.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color? noteColor;
    try {
      noteColor = widget.note.color != null
          ? Color(int.parse(widget.note.color!.replaceFirst('#', ''), radix: 16) + 0xFF000000)
          : null;
    } catch (e) {
      noteColor = null;
    }

    final primaryGradient = LinearGradient(
      colors: isDarkMode
          ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
          : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFE5E7EB), const Color(0xFFBFDBFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.note.title.isEmpty ? 'Untitled' : widget.note.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: noteColor != null
                            ? [noteColor.withOpacity(0.8), noteColor.withOpacity(0.3)]
                            : primaryGradient.colors,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareNote,
                    tooltip: 'Share Note',
                  ).animate().scale(duration: const Duration(milliseconds: 200)),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(
                          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  icon: Icons.person,
                                  label: 'Created by',
                                  value: _username ?? 'Loading...',
                                  context: context,
                                ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.2),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.description,
                                  label: 'Content',
                                  value: widget.note.content.isEmpty ? 'No content' : widget.note.content,
                                  context: context,
                                ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideY(begin: 0.2),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.priority_high,
                                  label: 'Priority',
                                  value: widget.note.priority == 1
                                      ? 'Low'
                                      : widget.note.priority == 2
                                      ? 'Medium'
                                      : 'High',
                                  color: widget.note.priority == 1
                                      ? Colors.green
                                      : widget.note.priority == 2
                                      ? Colors.orange
                                      : Colors.red,
                                  context: context,
                                ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideY(begin: 0.2),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.event,
                                  label: 'Created at',
                                  value: widget.note.createdAt.toString(),
                                  context: context,
                                ).animate().fadeIn(delay: const Duration(milliseconds: 800)).slideY(begin: 0.2),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  icon: Icons.update,
                                  label: 'Modified at',
                                  value: widget.note.modifiedAt.toString(),
                                  context: context,
                                ).animate().fadeIn(delay: const Duration(milliseconds: 1000)).slideY(begin: 0.2),
                                if (widget.note.tags != null && widget.note.tags!.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    'Tags',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.note.tags!
                                        .map(
                                          (tag) => Chip(
                                        label: Text(
                                          tag,
                                          style: GoogleFonts.poppins(
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: noteColor?.withOpacity(0.3) ??
                                            Theme.of(context).primaryColor.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: isDarkMode
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                    )
                                        .toList(),
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 1200)).scale(),
                                ],
                                if (widget.note.color != null) ...[
                                  const SizedBox(height: 24),
                                  _buildInfoRow(
                                    icon: Icons.color_lens,
                                    label: 'Color',
                                    value: widget.note.color!,
                                    color: noteColor,
                                    context: context,
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 1400)).slideY(begin: 0.2),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.note.imagePath != null && widget.note.imagePath!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attached Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FutureBuilder<bool>(
                                    future: File(widget.note.imagePath!).exists(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                      }
                                      if (snapshot.hasData && snapshot.data == true) {
                                        return Hero(
                                          tag: 'note_image_${widget.note.id}',
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => FullScreenImage(
                                                    imagePath: widget.note.imagePath!,
                                                    noteId: widget.note.id!,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.file(
                                                File(widget.note.imagePath!),
                                                height: 300,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Text(
                                                    'Unable to load image',
                                                    style: GoogleFonts.poppins(color: Colors.red),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Text(
                                        'Image not found',
                                        style: GoogleFonts.poppins(color: Colors.red),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 1600)).scale(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NoteFormScreen(note: widget.note)),
            );
            if (result == true && mounted) {
              Navigator.of(context).pop(true); // Refresh NoteListScreen
            }
          },
          tooltip: 'Edit Note',
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ).animate().fadeIn(delay: const Duration(milliseconds: 1800)),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: color ?? (isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final int noteId;

  const FullScreenImage({super.key, required this.imagePath, required this.noteId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFE5E7EB), const Color(0xFFBFDBFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: 'note_image_$noteId',
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Unable to load image',
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      size: 20,
                    ),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)).scale(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}