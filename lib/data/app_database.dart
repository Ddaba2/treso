import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'treso.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        activity TEXT NOT NULL,
        client TEXT,
        project TEXT,
        payment_method TEXT NOT NULL,
        motif TEXT,
        observation TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    await db.insert('categories', {'name': 'Ventes', 'type': 'RECETTE', 'created_at': now});
    await db.insert('categories', {'name': 'Fournitures', 'type': 'DEPENSE', 'created_at': now});
    await db.insert('categories', {'name': 'Transport', 'type': 'DEPENSE', 'created_at': now});
    await db.insert('categories', {'name': 'Salaire', 'type': 'DEPENSE', 'created_at': now});

    await db.insert('activities', {'name': 'Menuiserie', 'created_at': now});
    await db.insert('activities', {'name': 'Peinture', 'created_at': now});
    await db.insert('activities', {'name': 'Construction', 'created_at': now});
    await db.insert('activities', {'name': 'Staff', 'created_at': now});

    await db.insert('clients', {'name': 'Client interne', 'created_at': now});
    await db.insert('projects', {'name': 'Chantier standard', 'created_at': now});
  }
}
