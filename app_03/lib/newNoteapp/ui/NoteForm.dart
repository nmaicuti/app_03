import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:app_02/newNoteapp/db/NoteDatabaseHelper.dart';
import 'package:app_02/newNoteapp/model/NoteModel.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;

  const NoteFormScreen({super.key, this.note});

  @override
  _NoteFormScreenState createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late String _title;
  late String _content;
  late int _priority;
  late int _userId;
  List<String> _tags = [];
  String? _color;
  Color _selectedColor = Colors.white;
  String? _imagePath;
  File? _imageFile;
  final _tagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize values from note (if provided)
    _title = widget.note?.title ?? '';
    _content = widget.note?.content ?? '';
    _priority = widget.note?.priority ?? 1;
    _userId = widget.note?.userId ?? 1;
    _tags = widget.note?.tags ?? [];
    _color = widget.note?.color;
    _imagePath = widget.note?.imagePath;

    // Get userId from SharedPreferences
    _getUserId();

    // Handle initial color
    if (_color != null) {
      try {
        String hexColor = _color!.replaceFirst('#', '');
        if (hexColor.length == 6) {
          _selectedColor = Color(int.parse('0xff$hexColor'));
        }
      } catch (e) {
        _selectedColor = Colors.white;
      }
    }

    // Check if initial image exists
    if (_imagePath != null && File(_imagePath!).existsSync()) {
      _imageFile = File(_imagePath!);
    }

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 1;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_color == null) {
      _selectedColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choose Note Color',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (Color newColor) {
              setState(() {
                _selectedColor = newColor;
                _color = newColor.value.toRadixString(16).substring(2, 8);
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied) {
      _showErrorSnackBar('Camera permission denied. Please enable it in settings.');
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _requestPhotosPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    if (!status.isGranted && Platform.isAndroid) {
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }
    if (status.isPermanentlyDenied) {
      _showErrorSnackBar('Photo access denied. Please enable it in settings.');
      return false;
    }
    return status.isGranted;
  }

  Future<void> _deleteOldImage() async {
    if (_imagePath != null && await File(_imagePath!).exists()) {
      await File(_imagePath!).delete();
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    if (!await _requestCameraPermission()) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        await _deleteOldImage();
        final directory = await getApplicationDocumentsDirectory();
        final imageName = 'note_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newImagePath = '${directory.path}/$imageName';
        final File newImage = await File(photo.path).copy(newImagePath);
        setState(() {
          _imageFile = newImage;
          _imagePath = newImagePath;
        });
        _showSuccessSnackBar('Photo captured successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing photo: $e');
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    if (!await _requestPhotosPermission()) return;

    try {
      XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) {
        image = await _picker.pickMedia();
      }
      if (image != null) {
        await _deleteOldImage();
        final directory = await getApplicationDocumentsDirectory();
        final imageName = 'note_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newImagePath = '${directory.path}/$imageName';
        final File newImage = await File(image.path).copy(newImagePath);
        setState(() {
          _imageFile = newImage;
          _imagePath = newImagePath;
        });
        _showSuccessSnackBar('Image selected successfully');
      } else {
        _showWarningSnackBar('No image selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Image Source',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onPressed: () {
                Navigator.pop(context);
                _pickImage(context);
              },
            ),
            const SizedBox(height: 8),
            _buildDialogButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onPressed: () {
                Navigator.pop(context);
                _takePhoto(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = LinearGradient(
      colors: isDarkMode
          ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
          : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      key: _scaffoldMessengerKey,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Custom AppBar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 24),
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          widget.note == null ? 'Add Note' : 'Edit Note',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 48), // Placeholder for alignment
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Form Card
                    Container(
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
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    initialValue: _title,
                                    label: 'Title',
                                    icon: Icons.title,
                                    validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
                                    onSaved: (value) => _title = value!,
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideX(begin: -0.2),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    initialValue: _content,
                                    label: 'Content',
                                    icon: Icons.description,
                                    maxLines: 3,
                                    validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
                                    onSaved: (value) => _content = value!,
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideX(begin: -0.2),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    value: _priority,
                                    items: const [
                                      DropdownMenuItem(value: 1, child: Text('Low')),
                                      DropdownMenuItem(value: 2, child: Text('Medium')),
                                      DropdownMenuItem(value: 3, child: Text('High')),
                                    ],
                                    label: 'Priority',
                                    icon: Icons.priority_high,
                                    onChanged: (value) => setState(() => _priority = value!),
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideX(begin: -0.2),
                                  const SizedBox(height: 24),
                                  // Tags Section
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _tagController,
                                          label: 'Tag',
                                          icon: Icons.label,
                                          onSubmitted: (_) => _addTag(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _addTag,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: primaryGradient,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)).slideX(begin: -0.2),
                                  if (_tags.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _tags
                                          .map((tag) => Chip(
                                        label: Text(
                                          tag,
                                          style: GoogleFonts.poppins(
                                            color: isDarkMode ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                        backgroundColor: isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey[200],
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () => _removeTag(tag),
                                      ))
                                          .toList(),
                                    ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
                                  ],
                                  const SizedBox(height: 24),
                                  // Color Picker
                                  GestureDetector(
                                    onTap: () => _pickColor(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.white.withOpacity(0.5),
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _selectedColor,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDarkMode ? Colors.white70 : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Note Color',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 1200)).slideX(begin: -0.2),
                                  const SizedBox(height: 24),
                                  // Image Section
                                  _buildActionButton(
                                    icon: Icons.image,
                                    label: 'Add Image',
                                    onPressed: () => _showImagePickerDialog(context),
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 1400)).scale(),
                                  if (_imageFile != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.white.withOpacity(0.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                FutureBuilder<bool>(
                                                  future: _imageFile!.exists(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState ==
                                                        ConnectionState.waiting) {
                                                      return const CircularProgressIndicator(
                                                          strokeWidth: 2);
                                                    }
                                                    if (snapshot.hasData && snapshot.data == true) {
                                                      return ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.file(
                                                          _imageFile!,
                                                          height: 150,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      );
                                                    }
                                                    return Text(
                                                      'Image not found',
                                                      style: GoogleFonts.poppins(color: Colors.red),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                _buildActionButton(
                                                  icon: Icons.delete,
                                                  label: 'Remove Image',
                                                  color: Colors.red,
                                                  onPressed: () => setState(() {
                                                    _imageFile = null;
                                                    _imagePath = null;
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: const Duration(milliseconds: 1600)).scale(),
                                  ],
                                  const SizedBox(height: 24),
                                  // Save Button
                                  _buildActionButton(
                                    icon: Icons.save,
                                    label: 'Save',
                                    gradient: primaryGradient,
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        try {
                                          String? validatedColor = _color;
                                          if (validatedColor != null && validatedColor.length != 6) {
                                            validatedColor = null;
                                          }
                                          if (_imagePath != null && !await File(_imagePath!).exists()) {
                                            _imagePath = null;
                                          }

                                          final now = DateTime.now();
                                          final note = Note(
                                            id: widget.note?.id,
                                            title: _title,
                                            content: _content,
                                            priority: _priority,
                                            userId: _userId,
                                            createdAt: widget.note?.createdAt ?? now,
                                            modifiedAt: now,
                                            tags: _tags.isNotEmpty ? _tags : null,
                                            color: validatedColor,
                                            imagePath: _imagePath,
                                          );

                                          if (widget.note == null) {
                                            await NoteDatabaseHelper.instance.insertNote(note);
                                            _showSuccessSnackBar('Note added successfully');
                                          } else {
                                            await NoteDatabaseHelper.instance.updateNote(note);
                                            _showSuccessSnackBar('Note updated successfully');
                                          }
                                          Navigator.pop(context, true);
                                        } catch (e) {
                                          _showErrorSnackBar('Error saving note: $e');
                                        }
                                      }
                                    },
                                  ).animate().fadeIn(delay: const Duration(milliseconds: 1800)).scale(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildTextField({
    String? initialValue,
    TextEditingController? controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onSubmitted,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(
          color: Colors.red[300],
          fontWeight: FontWeight.w500,
        ),
      ),
      style: GoogleFonts.poppins(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      validator: validator,
      onSaved: onSaved,
      onFieldSubmitted: onSubmitted,
    );
  }

  Widget _buildDropdownField({
    required int value,
    required List<DropdownMenuItem<int>> items,
    required String label,
    required IconData icon,
    required void Function(int?) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      style: GoogleFonts.poppins(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    LinearGradient? gradient,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient ??
              LinearGradient(
                colors: [
                  color?.withOpacity(0.2) ?? Theme.of(context).primaryColor.withOpacity(0.2),
                  color?.withOpacity(0.1) ?? Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }
}