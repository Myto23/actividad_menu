import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'productos.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo TEXT NOT NULL,
            descripcion TEXT NOT NULL,
            activo TEXT NOT NULL,
            bodega TEXT,
            precio REAL 
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE productos ADD COLUMN precio REAL");
        }
      },
    );
  }

  Future<void> insertarProducto(Map<String, dynamic> producto) async {
    final db = await database;
    await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> buscarProductos(String? codigo, String? descripcion) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <String>[];

    if (codigo != null && codigo.isNotEmpty) {
      whereClauses.add('codigo LIKE ?');
      whereArgs.add('%$codigo%');
    }
    if (descripcion != null && descripcion.isNotEmpty) {
      whereClauses.add('descripcion LIKE ?');
      whereArgs.add('%$descripcion%');
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    return await db.query('productos', where: whereString, whereArgs: whereArgs);
  }
}
