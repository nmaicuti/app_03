import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_02/newNoteapp/model/NoteAccount.dart';

class NoteAccountDatabaseHelper {
  static final NoteAccountDatabaseHelper instance = NoteAccountDatabaseHelper._init();
  static Database? _database;

  NoteAccountDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounts.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  status TEXT NOT NULL,
  lastLogin TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
''');

    // Tạo hai tài khoản mặc định sau khi bảng được tạo
    await initializeDefaultAccounts(db);
  }

  Future<void> initializeDefaultAccounts(Database db) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Tài khoản 1: Active
      final account1 = NoteAccount(
        userId: 1,
        username: 'user1',
        password: 'password123',
        status: 'active',
        lastLogin: now,
        createdAt: now,
      );

      // Tài khoản 2: Inactive
      final account2 = NoteAccount(
        userId: 2,
        username: 'user2',
        password: 'password456',
        status: 'inactive',
        lastLogin: now,
        createdAt: now,
      );

      // Chèn tài khoản 1
      await db.insert('accounts', account1.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      print('Tạo tài khoản user1 (active) thành công');

      // Chèn tài khoản 2
      await db.insert('accounts', account2.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      print('Tạo tài khoản user2 (inactive) thành công');
    } catch (e) {
      print('Lỗi khi tạo tài khoản mặc định: $e');
    }
  }

  Future<NoteAccount> createAccount(NoteAccount account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());
    return account.copyWith(id: id);
  }

  Future<List<NoteAccount>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts');
    return result.map((map) => NoteAccount.fromMap(map)).toList();
  }

  Future<NoteAccount?> getAccountById(int id) async {
    final db = await database;
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? NoteAccount.fromMap(result.first) : null;
  }

  Future<NoteAccount?> getAccountByUserId(int userId) async {
    final db = await database;
    final result = await db.query('accounts', where: 'userId = ?', whereArgs: [userId]);
    return result.isNotEmpty ? NoteAccount.fromMap(result.first) : null;
  }

  Future<NoteAccount> updateAccount(NoteAccount account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
    return account;
  }

  Future<bool> deleteAccount(int id) async {
    final db = await database;
    final result = await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  Future<int> countAccounts() async {
    final db = await database;
    final result = await db.query('accounts');
    return result.length;
  }

  Future<NoteAccount?> login(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'username = ? AND password = ? AND status = ?',
      whereArgs: [username, password, 'active'],
    );
    if (result.isNotEmpty) {
      final account = NoteAccount.fromMap(result.first);
      final updatedAccount = account.copyWith(
        lastLogin: DateTime.now().toIso8601String(),
      );
      await updateAccount(updatedAccount);
      return updatedAccount;
    }
    return null;
  }

  Future<NoteAccount> updateAccountStatus(int id, String status) async {
    final account = await getAccountById(id);
    if (account == null) throw Exception('Account not found');
    final updatedAccount = account.copyWith(status: status);
    return await updateAccount(updatedAccount);
  }

  Future<NoteAccount> changePassword(int id, String oldPassword, String newPassword) async {
    final account = await getAccountById(id);
    if (account == null) throw Exception('Account not found');
    if (account.password != oldPassword) throw Exception('Incorrect old password');
    final updatedAccount = account.copyWith(password: newPassword);
    return await updateAccount(updatedAccount);
  }

  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final result = await db.query('accounts', where: 'username = ?', whereArgs: [username]);
    return result.isNotEmpty;
  }

  Future<NoteAccount> patchAccount(int id, Map<String, dynamic> data) async {
    final account = await getAccountById(id);
    if (account == null) throw Exception('Account not found');
    final updatedMap = account.toMap()..addAll(data);
    final updatedAccount = NoteAccount.fromMap(updatedMap);
    return await updateAccount(updatedAccount);
  }

  Future<List<NoteAccount>> getAccountsByStatus(String status) async {
    final db = await database;
    final result = await db.query('accounts', where: 'status = ?', whereArgs: [status]);
    return result.map((map) => NoteAccount.fromMap(map)).toList();
  }

  Future<NoteAccount> resetPassword(int id) async {
    final account = await getAccountById(id);
    if (account == null) throw Exception('Account not found');
    final newPassword = 'Reset${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    final updatedAccount = account.copyWith(password: newPassword, status: 'active');
    return await updateAccount(updatedAccount);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}