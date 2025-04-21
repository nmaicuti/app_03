import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_02/newNoteapp/model/NoteModel.dart';

class NoteDatabaseHelper {
  static final NoteDatabaseHelper instance = NoteDatabaseHelper._init();
  static Database? _database;

  NoteDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority INTEGER NOT NULL,
  userId INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  modifiedAt TEXT NOT NULL,
  tags TEXT,
  color TEXT,
  imagePath TEXT
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN userId INTEGER NOT NULL DEFAULT 1');
        print('Added userId column to notes table');
      } catch (e) {
        print('Error adding userId column: $e (possibly already exists)');
      }
    }
    if (oldVersion < 3) {
      print('Upgraded to version 3');
    }
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query('notes');
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getNotesByUserId(int userId) async {
    final db = await database;
    final result = await db.query('notes', where: 'userId = ?', whereArgs: [userId]);
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final result = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Note.fromMap(result.first) : null;
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotesByPriority(int priority) async {
    final db = await database;
    final result = await db.query('notes', where: 'priority = ?', whereArgs: [priority]);
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final result = await db.query('notes');
    final allNotes = result.map((map) => Note.fromMap(map)).toList();
    return allNotes.where((note) =>
    note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.content.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}