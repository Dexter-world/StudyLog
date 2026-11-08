import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database and has the insert, read, update and delete
/// methods for study sessions.
/// (Structure based on the lecturer's example BudgetDatabase class.)
class StudyDatabase {
  StudyDatabase._();

  // One shared object so the whole app uses the same database connection.
  static final StudyDatabase instance = StudyDatabase._();
  static const _databaseName = 'study_log.db';
  static const _tableName = 'study_sessions';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // If the database file does not exist yet, openDatabase creates it
    // and onCreate builds the table.
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            duration INTEGER NOT NULL,
            notes TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  // CREATE: add a new study session. Returns the new row id.
  Future<int> insertSession({
    required String title,
    required String subject,
    required int duration,
    required String notes,
  }) async {
    final db = await database;
    return db.insert(_tableName, {
      'title': title,
      'subject': subject,
      'duration': duration,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // READ: get one page of sessions, newest first.
  Future<List<Map<String, Object?>>> getSessions({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    // LIMIT and OFFSET make SQLite return only the rows for one page.
    return db.query(
      _tableName,
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Count all sessions so we can work out the total number of pages.
  Future<int> getSessionCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $_tableName',
    );
    return (result.first['count'] as num).toInt();
  }

  // UPDATE: change the fields of one session. created_at is not changed.
  // Returns how many rows were updated (1 if it worked).
  Future<int> updateSession({
    required int id,
    required String title,
    required String subject,
    required int duration,
    required String notes,
  }) async {
    final db = await database;
    return db.update(
      _tableName,
      {
        'title': title,
        'subject': subject,
        'duration': duration,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: remove one session by its id.
  Future<int> deleteSession(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
