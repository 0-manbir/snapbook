import 'dart:io';
import 'package:flutter/services.dart';
import 'package:snapbook/helper/notifications_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  late Database _database;

  Future<Database> initializeDatabase() async {
    final path = await getDatabasesPath();
    _database = await openDatabase(
      join(path, 'images.db'),
      version: 1,
      readOnly: false,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE images(
            id INTEGER PRIMARY KEY,
            path TEXT,
            date TEXT,
            caption TEXT
          )
        ''');
      },
    );

    return _database;
  }

  Future<void> saveImageToDatabase(
      String path, String date, String caption) async {
    await initializeDatabase();
    await _database.insert(
      'images',
      {
        'path': path,
        'date': date,
        'caption': caption,
      },
    );
  }

  Future<void> deleteImageFromDatabase(String filePath) async {
    await initializeDatabase();
    await _database.delete('images', where: 'path = ?', whereArgs: [filePath]);
  }

  Future<List<Map<String, dynamic>>> getAllImages() async {
    return await _database.query('images');
  }

  Future<void> exportDatabase() async {
    try {
      await initializeDatabase();

      DateTime now = DateTime.now();
      String formattedDate =
          "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}";
      String formattedTime =
          "${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}";

      String exportPath =
          'storage/emulated/0/Documents/snapbook_${formattedDate}_$formattedTime.db';
      await File(_database.path).copy(exportPath);

      NotificationsHelper notificationsHelper = NotificationsHelper();
      notificationsHelper.showNotification(
        "Database Saved!",
        "Successfully saved the database to 'Documents'.",
      );
    } catch (e) {
      NotificationsHelper notificationsHelper = NotificationsHelper();
      notificationsHelper.showNotification(
        "Export Failed!",
        "Failed to export the database: $e",
      );
    }
  }

  Future<void> importDatabase(String importPath) async {
    Database sourceDb = await openDatabase(importPath, readOnly: false);
    await initializeDatabase();

    int count = Sqflite.firstIntValue(
        await sourceDb.rawQuery('SELECT COUNT(*) FROM images'))!;

    List<Map<String, dynamic>> rows = await sourceDb.query('images');

    for (int i = 0; i < rows.length; i++) {
      Map<String, dynamic> row = rows[i];
      int id = row['id'];
      List<Map<String, Object?>> existingRow = await _database.query(
        'images',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existingRow.isEmpty) {
        await _database.insert('images', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        // Row with id already exists, let's generate a new unique id
        int newUniqueId = await _generateUniqueId();

        // Create a new map with the spread operator
        Map<String, dynamic> newRow = {...row, 'id': newUniqueId};

        // Insert the row with the new unique id
        await _database.insert('images', newRow,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    NotificationsHelper notificationsHelper = NotificationsHelper();
    notificationsHelper.showNotification(
      "Imported Successfully!",
      "$count images imported.",
    );

    await sourceDb.close();
    await initializeDatabase();
  }

  // Function to generate a new unique id
  Future<int> _generateUniqueId() async {
    List<Map<String, Object?>> result =
        await _database.rawQuery('SELECT MAX(id) as maxId FROM images');
    int maxId = result[0]['maxId'] as int? ?? 0;
    return maxId + 1;
  }

  // calendar view
  Future<List<DateTime>> getHighlightedDates() async {
    final List<Map<String, dynamic>> result = await _database.query('images');
    return result.map((map) => DateTime.parse(map['date'])).toList();
  }

  Future<ImageDetails> getDataFromDateTime(DateTime dateTime) async {
    await initializeDatabase();

    int day = dateTime.day;
    int month = dateTime.month;
    int year = dateTime.year;

    List<Map<String, dynamic>> result = await _database.rawQuery(
      "SELECT path, caption FROM images WHERE date LIKE '%$year%$month%$day%'",
    );

    if (result.isNotEmpty) {
      String imagePath = result[0]['path'];
      String caption = result[0]['caption'];

      return ImageDetails(imagePath, caption);
    } else {
      return ImageDetails("", "image not found :(");
    }
  }

  // statistics
  Future<Stats> getStats() async {
    await initializeDatabase();

    int thisMonth = 0, prevMonth = 0, thisYear = 0, prevYear = 0;
    DateTime now = DateTime.now();

    DateTime start, end;

    // THIS MONTH---------------------------------------------------------------
    if (now.month == 12) {
      end = DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1));
    } else {
      end = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));
    }
    start = DateTime(now.year, now.month, 1);

    thisMonth = await getNumberOfItems(
      start,
      end,
    );

    // PREV MONTH---------------------------------------------------------------
    if (now.month == 1) {
      start = DateTime(now.year - 1, 12, 1);
    } else {
      start = DateTime(now.year, now.month - 1, 1);
    }
    end = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));

    prevMonth = await getNumberOfItems(
      start,
      end,
    );

    thisYear = await getNumberOfItems(
      DateTime(now.year, 1, 1),
      DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1)),
    );
    prevYear = await getNumberOfItems(
      DateTime(now.year - 1, 1, 1),
      DateTime(now.year, 1, 1).subtract(const Duration(days: 1)),
    );

    return Stats(thisMonth, prevMonth, thisYear, prevYear);
  }

  Future<int> getNumberOfItems(DateTime start, DateTime end) async {
    String formattedStart = start.toIso8601String().split('T')[0];
    String formattedEnd = end.toIso8601String().split('T')[0];

    return Sqflite.firstIntValue(await _database.rawQuery(
      'SELECT COUNT(*) FROM images WHERE date BETWEEN ? AND ?',
      [formattedStart, formattedEnd],
    ))!;
  }

  String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    }
    return "0$n";
  }

  // search by caption-------------------------
  Future<List<Map<String, dynamic>>> searchImages(String searchTerm) async {
    await initializeDatabase();

    return await _database.rawQuery(
      "SELECT * FROM images WHERE caption LIKE '%$searchTerm%'",
    );
  }

  // edit caption
  Future<void> updateCaptionInDatabase(
    String path,
    String oldCaption,
    String newCaption,
  ) async {
    await initializeDatabase();

    try {
      await _database.update(
        'images',
        {'caption': newCaption},
        where: 'path = ? AND caption = ?',
        whereArgs: [path, oldCaption],
      );

      HapticFeedback.mediumImpact();
    } catch (e) {
      NotificationsHelper notificationsHelper = NotificationsHelper();
      notificationsHelper.showNotification(
        "Failed to update caption!",
        "Error: $e",
      );
    } finally {
      await _database.close();
    }
  }
}

class ImageDetails {
  final String path;
  final String caption;

  ImageDetails(this.path, this.caption);
}

class Stats {
  int thisMonth;
  int prevMonth;
  int thisYear;
  int prevYear;

  Stats(this.thisMonth, this.prevMonth, this.thisYear, this.prevYear);
}
