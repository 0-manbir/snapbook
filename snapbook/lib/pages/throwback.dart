import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snapbook/helper/database_helper.dart';
import 'package:snapbook/helper/imageview_helper.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const Throwback());
}

class Throwback extends StatefulWidget {
  const Throwback({super.key});

  @override
  State<Throwback> createState() => _ThrowbackState();
}

class _ThrowbackState extends State<Throwback> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Database _database;
  late double screenWidth;
  List<Map<String, dynamic>> _images = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      setState(() {
        _initDatabase();
      });
    }
  }

  Future<void> _initDatabase() async {
    _database = await _databaseHelper.initializeDatabase();

    // List<Map<String, dynamic>> entries = await _database.rawQuery(
    //     "SELECT * FROM images WHERE strftime('%m-%d', date) = strftime('%m-%d', CURRENT_DATE);");

    String formattedDate =
        "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    List<Map<String, dynamic>> entries = await _database.rawQuery(
        "SELECT * FROM images WHERE strftime('%m-%d', date) = '$formattedDate';");

    setState(() {
      _images = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    // variables------------------------------------------------------------------------
    double statusBarHeight = MediaQuery.of(context).padding.top;
    screenWidth = MediaQuery.of(context).size.width;

    // interface------------------------------------------------------------------------
    return Scaffold(
      body: Padding(
        padding:
            EdgeInsets.only(top: statusBarHeight, left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            GestureDetector(
              child: SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: screenWidth * .75,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: Colors.grey[200],
                    ),
                    child: Text(
                      DateFormat('dd-MM-yyyy').format(selectedDate).toString(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () {
                pickDate(context);
              },
            ),

            // throwback - grid view--------------------------------------------------------
            buildImageGrid(),
          ],
        ),
      ),
    );
  }

  Widget buildImageGrid() {
    // not images found
    if (_images.isEmpty) {
      return Container(
        width: screenWidth,
        height: 150,
        alignment: Alignment.center,
        child: Text(
          "no images found :(",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Group images by month
    Map<String, List<Map<String, dynamic>>> groupedImages = {};

    for (var image in _images) {
      String date = image['date'];
      String monthYear = getMonthYear(date);

      if (!groupedImages.containsKey(monthYear)) {
        groupedImages[monthYear] = [];
      }

      groupedImages[monthYear]!.add(image);
    }

    return Expanded(
      child: ListView.builder(
        itemCount: groupedImages.length,
        itemBuilder: (context, index) {
          String monthYear = groupedImages.keys.toList()[index];
          List<Map<String, dynamic>> monthImages = groupedImages[monthYear]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 10),
              // Month and year text
              Text(
                DateTime.parse(monthImages.first['date']).year.toString(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),

              Container(height: 5),

              // GridView for images of the current month
              ImageViewHelper().buildMonthImageGrid(monthImages, screenWidth),
            ],
          );
        },
      ),
    );
  }

  // helper methods
  String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    }
    return "0$n";
  }

  String getMonthYear(String date) {
    DateTime dateTime = DateTime.parse(date);
    return '${dateTime.month}/${dateTime.year}';
  }
}
