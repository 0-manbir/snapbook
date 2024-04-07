import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapbook/helper/database_helper.dart';
import 'package:snapbook/helper/imageview_helper.dart';
import 'package:snapbook/helper/notifications_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:native_exif/native_exif.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Gallery());
}

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  // take and save picture ----------------------------------------------------------------------------
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _searchBoxController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Database _database;
  List<Map<String, dynamic>> _images = [];
  DateTime selectedDate = DateTime.now();
  DateTime? dateOfCapture;

  final TextEditingController _dateEditController = TextEditingController();
  final TextEditingController _monthEditController = TextEditingController();
  final TextEditingController _yearEditController = TextEditingController();
  final TextEditingController _hourEditController = TextEditingController();
  final TextEditingController _minuteEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await _databaseHelper.initializeDatabase();

    List<Map<String, dynamic>> entries =
        await _database.rawQuery("SELECT * FROM images ORDER BY date DESC;");

    setState(() {
      _images = entries;
    });
  }

  Future<void> takePicture(bool takePicture) async {
    String snapBookDirectory = '/storage/emulated/0/Pictures/SnapBook';
    await Directory(snapBookDirectory).create(recursive: true);
    String filePath =
        '$snapBookDirectory/${ImageViewHelper().generateAndroidStyleFileName()}';

    if (takePicture) {
      // take picture
      ImagePicker imagePicker = ImagePicker();
      XFile? photo = await imagePicker.pickImage(source: ImageSource.camera);
      dateOfCapture = DateTime.now();

      if (photo == null) {
        return;
      }

      File file = File(photo.path);
      await file.copy(filePath);
    } else {
      // pick picture from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (img == null) return;

      // get date of creation
      File file = File(img.path);
      final exif = await Exif.fromPath(img.path);
      dateOfCapture = await exif.getOriginalDate();

      if (dateOfCapture == null) {
        if (img.path.contains("WA")) {
          String dateTime = img.name.substring(
            img.name.indexOf("-") + 1,
            img.name.lastIndexOf("-"),
          );
          dateOfCapture = DateTime(
            int.parse(dateTime.substring(0, 4)),
            int.parse(dateTime.substring(4, 6)),
            int.parse(dateTime.substring(6)),
          );
        }
      }
      await file.copy(filePath);
    }

    // input a caption for the image
    _dateEditController.text = dateOfCapture == null
        ? DateTime.now().day.toString()
        : dateOfCapture!.day.toString();
    _monthEditController.text = dateOfCapture == null
        ? DateTime.now().month.toString()
        : dateOfCapture!.month.toString();
    _yearEditController.text = dateOfCapture == null
        ? DateTime.now().year.toString()
        : dateOfCapture!.year.toString();

    _hourEditController.text = dateOfCapture == null
        ? DateTime.now().hour.toString()
        : dateOfCapture!.hour.toString();
    _minuteEditController.text = dateOfCapture == null
        ? DateTime.now().minute.toString()
        : dateOfCapture!.minute.toString();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: .85,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  color: Colors.grey[200],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "create new snap:",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      Container(height: 20),

                      // caption text box --------------------
                      TextField(
                        controller: _captionController,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                        cursorColor: Colors.grey[500],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey[700],
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: "enter a caption...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey[500]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey[500]!),
                          ),
                          labelStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey[500],
                            fontSize: 18,
                          ),
                        ),
                      ),

                      Container(height: 20),

                      // date text field---------------------------------------------------------------------
                      Row(
                        children: [
                          Container(
                            width: 30,
                          ),

                          // date edit-------------------------------------------
                          Expanded(
                            child: TextField(
                              controller: _dateEditController,
                              maxLines: 1,
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              cursorColor: Colors.grey[500],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                alignLabelWithHint: true,
                                labelText: "DD",
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 25,
                          ),

                          // month edit--------------------------------------------
                          Expanded(
                            child: TextField(
                              controller: _monthEditController,
                              maxLines: 1,
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              cursorColor: Colors.grey[500],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                alignLabelWithHint: true,
                                labelText: "MM",
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 25,
                          ),

                          // year edit--------------------------------------------
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _yearEditController,
                              maxLines: 1,
                              maxLength: 4,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              cursorColor: Colors.grey[500],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                alignLabelWithHint: true,
                                labelText: "YYYY",
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(width: 20),
                      // time text field--------------------------------------------------------------------
                      Row(
                        children: [
                          Container(
                            width: 100,
                          ),

                          // hour edit-------------------------------------------
                          Expanded(
                            child: TextField(
                              controller: _hourEditController,
                              maxLines: 1,
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              cursorColor: Colors.grey[500],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                alignLabelWithHint: true,
                                labelText: "HH",
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 25,
                          ),

                          // minute--------------------------------------------
                          Expanded(
                            child: TextField(
                              controller: _minuteEditController,
                              maxLines: 1,
                              maxLength: 2,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              cursorColor: Colors.grey[500],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                alignLabelWithHint: true,
                                labelText: "MM",
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[500],
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                          ),
                        ],
                      ),

                      Container(height: 25),

                      // save snap button-----------------------
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.grey[700]!,
                          ),
                        ),
                        onPressed: () {
                          // done button pressed---------------------
                          try {
                            saveImageToDatabase(
                              File(filePath),
                              DateTime(
                                int.parse(_yearEditController.text),
                                int.parse(_monthEditController.text),
                                int.parse(_dateEditController.text),
                                int.parse(_hourEditController.text),
                                int.parse(_minuteEditController.text),
                              ),
                              _captionController.text,
                            );

                            setState(() {
                              _initDatabase();
                            });

                            HapticFeedback.mediumImpact();
                            sleep(const Duration(milliseconds: 200));
                            HapticFeedback.heavyImpact();
                          } catch (e) {
                            // failed to save image
                            NotificationsHelper notificationsHelper =
                                NotificationsHelper();
                            notificationsHelper.showNotification(
                              "Failed to save!",
                              e.toString(),
                            );
                          }
                          Navigator.pop(context);
                          _captionController.text = '';
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: Text(
                            "save",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey[100],
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> saveImageToDatabase(
      File image, DateTime date, String caption) async {
    await _databaseHelper.saveImageToDatabase(
      image.path,
      // DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString(),
      "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}:${_twoDigits(date.second)}",
      caption,
    );
  }

  Future<void> deleteFromDatabase(String filePath) async {
    await _databaseHelper.deleteImageFromDatabase(filePath);
  }

  void deleteImageFromDatabase(
      String path, BuildContext context, bool deleteImage) {
    if (deleteImage) {
      // delete file
      File file = File(path);
      file.delete();
    }

    // delete from database
    deleteFromDatabase(path);

    // close sheet
    Navigator.pop(context);

    HapticFeedback.mediumImpact();
  }

  late double screenWidth;

  @override
  Widget build(BuildContext context) {
    // variables-----------------------------------------
    double statusBarHeight = MediaQuery.of(context).padding.top;
    screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;

    // interface--------------------------------------------------------------------------------------
    return Padding(
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Scaffold(
        // floating action button------------------------------
        floatingActionButton: GestureDetector(
          child: FloatingActionButton(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.grey[300],
            shape: const CircleBorder(),
            onPressed: () {
              // take a picture now---------------------------
              HapticFeedback.mediumImpact();
              takePicture(true);
            },
            child: const Icon(
              Icons.add_rounded,
              size: 40,
            ),
          ),
          onLongPress: () {
            // select from gallery-----------------------------
            HapticFeedback.heavyImpact();
            takePicture(false);
          },
        ),

        // main body---------------------------------------------------------------------------------
        body: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Column(
            children: [
              // search bar----------------------------------------
              SizedBox(
                height: 100,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                    color: Colors.grey[200],
                  ),
                  child: Row(
                    children: [
                      // space at left------------
                      Container(width: 10),

                      // search box---------------
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchBoxController,
                            cursorColor: Colors.grey[500],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey[700],
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              labelText: "search by caption...",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              border: InputBorder.none,
                              labelStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey[500],
                                fontSize: 20,
                              ),
                            ),
                            onSubmitted: (value) {
                              startSearch(context);
                            },
                          ),
                        ),
                      ),

                      // search icon----------------
                      GestureDetector(
                        child: Icon(
                          Icons.search_rounded,
                          size: 32,
                          color: Colors.grey[700],
                        ),
                        onTap: () {
                          startSearch(context);
                        },
                      ),

                      // space at right-------------
                      Container(width: 25),
                    ],
                  ),
                ),
              ),
              buildImageGrid(),
            ],
          ),
        ),
      ),
    );
  }

  void startSearch(BuildContext buildContext) {
    if (_searchBoxController.text.trim() == "") return;

    showImagesBottomSheet(buildContext, _searchBoxController.text);
    _searchBoxController.text = "";
  }

  Widget buildImageGrid() {
    // Group images by month
    Map<String, List<Map<String, dynamic>>> groupedImages = {};

    for (var image in _images) {
      String date = image['date'];
      String monthYear = ImageViewHelper().getMonthYear(date);

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
                ImageViewHelper()
                    .getMonthDisplay(monthImages.first['date'])
                    .toLowerCase(),
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

  // search by caption ---------------------------------------------------------------------------------
  void showImagesBottomSheet(BuildContext context, String searchTerm) async {
    List<Map<String, dynamic>> imagesList =
        await DatabaseHelper().searchImages(searchTerm);

    // if there are on elements
    if (imagesList.isEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "snaps captioned '$searchTerm'",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  height: 25,
                ),
                const Text(
                  "no images found :(",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                  ),
                ),
                Container(
                  height: 50,
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // Show the bottom sheet with the list of images
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: .86,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "snaps captioned '$searchTerm'",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[700],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),

                // build grid of images with matching search
                Expanded(
                  child: ListView.builder(
                    itemCount: imagesList.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // GridView for images of the current month
                            ImageViewHelper()
                                .buildMonthImageGrid(imagesList, screenWidth),
                          ],
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    }
    return "0$n";
  }
}
