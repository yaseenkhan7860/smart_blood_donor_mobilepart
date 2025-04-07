import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _tableName = 'users';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('Initializing database...'); // Debug print
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'blood_donation.db');
    print('Database path: $path'); // Debug print

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        print('Database opened successfully'); // Debug print
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...'); // Debug print
    await _createTables(db);
    print('Database tables created successfully'); // Debug print
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion'); // Debug print
    if (oldVersion < 2) {
      try {
        // Create a new table without username column
        await db.execute('''
          CREATE TABLE users_new(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            bloodGroup TEXT,
            token TEXT,
            created_at TEXT
          )
        ''');

        // Copy data from old table to new table, excluding username
        await db.execute('''
          INSERT INTO users_new (id, email, password, name, bloodGroup, token, created_at)
          SELECT id, email, password, name, bloodGroup, token, created_at
          FROM $_tableName
        ''');

        // Drop the old table
        await db.execute('DROP TABLE $_tableName');

        // Rename the new table
        await db.execute('ALTER TABLE users_new RENAME TO $_tableName');

        print('Database upgraded successfully'); // Debug print
      } catch (e) {
        print('Error upgrading database: $e'); // Debug print
        // If the upgrade fails, try to create the table from scratch
        await _createTables(db);
      }
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        bloodGroup TEXT,
        token TEXT,
        created_at TEXT
      )
    ''');
    print('Users table created successfully'); // Debug print
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    print('Inserting user: $user'); // Debug print
    await db.insert(_tableName, user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    print('Querying user by email: $email'); // Debug print
    final List<Map<String, dynamic>> results = await db.query(
      _tableName,
      where: 'email = ?',
      whereArgs: [email],
    );
    print('Query results for $email: $results'); // Debug print
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByIdentifier(String identifier) async {
    final db = await database;
    print('Querying user by identifier: $identifier'); // Debug print
    final List<Map<String, dynamic>> results = await db.query(
      _tableName,
      where: 'email = ?',
      whereArgs: [identifier],
    );
    print('Query results for $identifier: $results'); // Debug print
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateUserToken(String email, String token) async {
    Database db = await database;
    await db.update(
      _tableName,
      {'token': token},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> deleteUser(String email) async {
    final db = await database;
    print('Deleting user: $email'); // Debug print
    await db.delete(
      _tableName,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps;
  }
} 