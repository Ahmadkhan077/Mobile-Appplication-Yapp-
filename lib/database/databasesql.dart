import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class YappDatabase {
  static final YappDatabase instance = YappDatabase._init();
  static Database? _database;

  YappDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('yapps.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE yapps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        videoPath TEXT NOT NULL,
        creationDate TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertYapp(Map<String, dynamic> yapp) async {
    final db = await instance.database;
    return await db.insert('yapps', yapp);
  }

  Future<List<Map<String, dynamic>>> fetchYapps() async {
    final db = await instance.database;
    return await db.query('yapps');
  }

  Future<void> deleteYapp(String id) async {
    final db = await instance.database;
    await db.delete(
      'yapps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateYappName(String id, String newName) async {
    final db = await instance.database;
    await db.update(
      'yapps',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
