import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snapbook/helper/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ImageViewHelper {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  late Database _database;
  late List<Map<String, dynamic>> entries;

  Future<void> _initDatabase() async {
    _database = await _databaseHelper.initializeDatabase();
    entries =
        await _database.rawQuery("SELECT * FROM images ORDER BY date DESC;");
  }

  Widget buildMonthImageGrid(
      List<Map<String, dynamic>> monthEntries, double screenWidth) {
    return SizedBox(
      height: 76.0 *
          (monthEntries.length % 5 != 0
              ? (monthEntries.length ~/ 5) + 1
              : monthEntries.length ~/ 5),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1,
          crossAxisCount: 5,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: monthEntries.length,
        itemBuilder: (context, index) {
          // if image exists
          File file = File(monthEntries[index]['path']);
          if (!file.existsSync()) {
            deleteImageFromDatabase(
                monthEntries[index]['path'], context, false);
          }

          // item data
          final String path = monthEntries[index]['path'];
          String caption = monthEntries[index]['caption'];
          String date = monthEntries[index]['date'];
          DateTime dateTime = DateTime.parse(date);

          // if not a new year, continue displaying images-----
          return GestureDetector(
            onTap: () {
              // image clicked from view-----------------
              HapticFeedback.mediumImpact();

              showImageInBottomSheet(
                index,
                context,
                screenWidth,
                path,
                caption,
                dateTime,
                true,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.file(
                File(path),
                height: 10,
                width: 10,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                cacheHeight: 150,
              ),
            ),
          );
        },
      ),
    );
  }

  void showImageInBottomSheet(
    int index,
    BuildContext context,
    double screenWidth,
    String path,
    String caption,
    DateTime dateTime,
    bool editable,
  ) {
    String formattedTime = dateTime.hour > 12
        ? "    ${dateTime.hour - 12}:${_twoDigits(dateTime.minute)} PM"
        : "    ${dateTime.hour}:${_twoDigits(dateTime.minute)} AM";

    if (dateTime.hour == 0 && dateTime.minute == 0) {
      formattedTime = "";
    }

    String formattedDate =
        "${dateTime.day} ${DateFormat.MMM().format(DateTime(dateTime.year, dateTime.month, 1))} '${dateTime.year.toString().substring(2)}$formattedTime";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            width: screenWidth,
            padding: EdgeInsets.all(screenWidth * .05),
            child: Column(
              children: [
                Stack(
                  alignment: AlignmentDirectional.bottomEnd,
                  children: [
                    // image view full ---------------------------------
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        child: Image.file(
                          File(path),
                          width: screenWidth * .95,
                          height: screenWidth * .95,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.none,
                          cacheHeight: 1000,
                        ),
                        onTap: () {
                          // open image in external gallery--------------
                          openImageInGallery(path);
                        },
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // EDIT CAPTION BUTTON--------------------------------
                        editable
                            ? GestureDetector(
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.grey[800],
                                    size: 26,
                                  ),
                                ),
                                onTap: () {
                                  // edit caption pressed----------
                                  updateCaption(
                                    path,
                                    caption,
                                    index,
                                    context,
                                    screenWidth,
                                  );
                                  _initDatabase();
                                },
                              )
                            : Container(),

                        // SHARE BUTTON------------------------------------------
                        GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              color: Colors.grey[800],
                              size: 26,
                            ),
                          ),
                          onTap: () {
                            // share button pressed----------
                            Share.shareXFiles(
                              [XFile(path)],
                              subject: caption,
                              text: caption,
                            );
                          },
                        ),

                        // DELETE BUTTON-------------------------------------
                        GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.delete_rounded,
                              color: Colors.grey[800],
                              size: 26,
                            ),
                          ),
                          onTap: () {
                            // delete button pressed----------
                            deleteImageFromDatabase(
                              path,
                              context,
                              true,
                            );
                            _initDatabase();
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                Container(
                  height: 10,
                ),

                // date of the item------------------------
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),

                Container(
                  height: 15,
                ),

                // caption of the item---------------------
                Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          caption.contains("#")
                              ? "${caption.substring(0, caption.indexOf("#")).trim()}\n\n\n\n\n\n\n\n${caption.substring(caption.indexOf("#"))}"
                              : caption.trim(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            color: Colors.grey[800],
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // helper methods
  String generateAndroidStyleFileName() {
    DateTime now = DateTime.now();
    String formattedDate =
        "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}";
    String formattedTime =
        "${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}";
    return 'IMG_${formattedDate}_$formattedTime.jpg';
  }

  Future<void> openImageInGallery(String imageUrl) async {
    await OpenFile.open(imageUrl);
  }

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

  String getMonthDisplay(String date) {
    DateTime dateTime = DateTime.parse(date);
    return "${DateFormat.MMM().format(DateTime(dateTime.year, dateTime.month, 1))}, ${dateTime.year.toString().substring(2)}";
  }

  Future<void> deleteFromDatabase(String filePath) async {
    await _databaseHelper.deleteImageFromDatabase(filePath);
  }

  void deleteImageFromDatabase(
      String path, BuildContext context, bool deleteImage) {
    if (deleteImage) {
      File file = File(path);
      file.delete();
    }

    deleteFromDatabase(path);

    Navigator.pop(context);

    HapticFeedback.mediumImpact();
  }

  TextEditingController _newCaptionController = TextEditingController();

  void updateCaption(
    String path,
    String caption,
    int index,
    BuildContext context,
    double screenWidth,
  ) {
    // set previous caption
    _newCaptionController.text = caption;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: .7,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: screenWidth,
              child: Column(
                children: [
                  Container(
                    height: 10,
                  ),
                  Text(
                    "(changes will apply upon app restart)",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    "edit the caption: ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      color: Colors.grey[600],
                    ),
                  ),

                  Container(
                    height: 20,
                  ),

                  // new caption text box-------------------------------
                  TextField(
                    controller: _newCaptionController,
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

                  Container(
                    height: 30,
                  ),

                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.grey[700]),
                    ),
                    onPressed: () {
                      // save caption
                      updateCaptionInDatabase(
                        path,
                        caption,
                        _newCaptionController.text,
                      );

                      Navigator.pop(context);
                      Navigator.pop(context);

                      _initDatabase();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "save",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          color: Colors.grey[200],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> updateCaptionInDatabase(
    String path,
    String oldCaption,
    String newCaption,
  ) async {
    await DatabaseHelper()
        .updateCaptionInDatabase(path, oldCaption, newCaption);
  }
}
