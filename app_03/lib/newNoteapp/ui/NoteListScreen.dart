import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Ensure this import is present
import 'package:app_02/newNoteapp/model/NoteModel.dart';
import 'package:app_02/newNoteapp/db/NoteDatabaseHelper.dart';
import 'package:app_02/newNoteapp/ui/NoteForm.dart';
import 'package:app_02/newNoteapp/ui/NoteItem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteListScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final bool isDarkMode;
  final Function(BuildContext) onLogout;

  const NoteListScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> with TickerProviderStateMixin {
  late Future<List<Note>> _notesFuture;
  bool isGridView = false;
  bool _isSearching = false;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _userId;
  String _sortOption = 'date'; // Default sorting by date
  int? _priorityFilter; // Filter by priority (null = no filter, 1 = Low, 2 = Medium, 3 = High)
  String _tagFilter = ''; // Filter by tag

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _refreshNotes();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    _refreshNotes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotes() async {
    if (_userId == null) {
      setState(() {
        _notesFuture = Future.value([]);
      });
      return;
    }
    setState(() {
      _notesFuture = NoteDatabaseHelper.instance.getNotesByUserId(_userId!);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _searchQuery = '';
      _priorityFilter = null;
      _tagFilter = '';
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDarkMode = widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Lọc ghi chú',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ưu tiên:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                DropdownButton<int?>(
                  value: _priorityFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 1, child: Text('Thấp')),
                    DropdownMenuItem(value: 2, child: Text('Trung bình')),
                    DropdownMenuItem(value: 3, child: Text('Cao')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _priorityFilter = value;
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhãn:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _tagFilter = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Nhập nhãn (rỗng để bỏ lọc)',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.grey[200],
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Đóng',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final primaryGradient = LinearGradient(
      colors: isDarkMode
          ? [const Color(0xFF00DDEB), const Color(0xFF8B5CF6)] // Cyan to electric purple
          : [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4)], // Coral to teal
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm ghi chú...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
            ),
          ),
        )
            : const Text(
          'Ghi Chú Của Bạn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                key: ValueKey<bool>(_isSearching),
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Hủy tìm kiếm' : 'Tìm kiếm ghi chú',
          ),
          if (_isSearching)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: _showFilterDialog,
              tooltip: 'Lọc ghi chú',
            ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                key: ValueKey<bool>(isDarkMode),
                color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
              ),
            ),
            onPressed: widget.onThemeChanged,
            tooltip: isDarkMode ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối',
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isGridView ? Icons.list : Icons.grid_view,
                key: ValueKey<bool>(isGridView),
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            onPressed: () => setState(() => isGridView = !isGridView),
            tooltip: isGridView ? 'Chuyển sang dạng danh sách' : 'Chuyển sang dạng lưới',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _refreshNotes,
            tooltip: 'Làm mới danh sách',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              } else if (value == 'sort_date') {
                setState(() {
                  _sortOption = 'date';
                });
              } else if (value == 'sort_priority') {
                setState(() {
                  _sortOption = 'priority';
                });
              }
            },
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
                    ),
                    const SizedBox(width: 8),
                    const Text('Sắp xếp theo ngày'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_priority',
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
                    ),
                    const SizedBox(width: 8),
                    const Text('Sắp xếp theo ưu tiên'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Color(0xFFFF4D4D)),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)] // Slate to deep blue
                : [const Color(0xFFF1F5F9), const Color(0xFFE0F2FE)], // Light gray to sky blue
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Note>>(
            future: _notesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Đã xảy ra lỗi: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add,
                        size: 80,
                        color: isDarkMode ? Colors.white54 : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có ghi chú nào\nNhấn nút + để thêm ghi chú mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Filter notes
                final notes = snapshot.data!.where((note) {
                  bool matchesSearch = true;
                  bool matchesPriority = true;
                  bool matchesTag = true;

                  // Filter by search query (title, content)
                  if (_searchQuery.isNotEmpty) {
                    matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        note.content.toLowerCase().contains(_searchQuery.toLowerCase());
                  }

                  // Filter by priority
                  if (_priorityFilter != null) {
                    matchesPriority = note.priority == _priorityFilter;
                  }

                  // Filter by tag
                  if (_tagFilter.isNotEmpty) {
                    matchesTag = note.tags?.any((tag) => tag.toLowerCase().contains(_tagFilter.toLowerCase())) ?? false;
                  }

                  return matchesSearch && matchesPriority && matchesTag;
                }).toList();

                // Sort notes
                if (_sortOption == 'date') {
                  notes.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
                } else if (_sortOption == 'priority') {
                  notes.sort((a, b) => b.priority.compareTo(a.priority)); // Highest priority first
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy ghi chú nào',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshNotes,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isGridView
                        ? GridView.builder(
                      key: const ValueKey<String>('grid'),
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95),
                          child: NoteItem(
                            note: notes[index],
                            onDelete: _refreshNotes,
                          ),
                        ).animate().fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: Duration(milliseconds: 100 * index),
                        ).slideY(
                          begin: 0.2,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        );
                      },
                    )
                        : ListView.builder(
                      key: const ValueKey<String>('list'),
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: NoteItem(
                            note: notes[index],
                            onDelete: _refreshNotes,
                          ),
                        ).animate().fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: Duration(milliseconds: 100 * index),
                        ).slideY(
                          begin: 0.2,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton(
          backgroundColor: isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFFF6B6B),
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoteFormScreen()),
            );
            if (created == true) {
              _refreshNotes();
            }
          },
          tooltip: 'Thêm ghi chú mới',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDarkMode = widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xác nhận đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF00DDEB) : const Color(0xFF4ECDC4),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onLogout(context);
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Color(0xFFFF4D4D)),
              ),
            ),
          ],
        );
      },
    );
  }
}