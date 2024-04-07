import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:snapbook/helper/database_helper.dart';

void main() {
  runApp(const Settings());
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    getStats();
    getUserName();
    getMonthNames();
  }

  // variables-------------------------------------------------------------
  String username = "";

  int statsThisMonth = 0;
  int statsThisYear = 0;
  int statsLastMonth = 0;
  int statsLastYear = 0;

  String thisMonth = "", lastMonth = "", thisYear = "", lastYear = "";

  void getMonthNames() {
    DateTime now = DateTime.now();

    // this month--------
    thisMonth = DateFormat('MMMM').format(now).toLowerCase();

    // last month--------
    if (now.month == DateTime.january) {
      lastMonth = 'december';
    } else {
      lastMonth = DateFormat('MMMM')
          .format(DateTime(now.year, now.month - 1, 1))
          .toLowerCase();
    }

    // this year---------
    thisYear = "year '${(now.year).toString().substring(2)}";

    // last year---------
    lastYear = "year '${(now.year - 1).toString().substring(2)}";

    setState(() {});
  }

  Future<void> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString('username') ?? 'user';
    });
  }

  Future<void> getStats() async {
    Stats stats = await DatabaseHelper().getStats();
    setState(() {
      statsThisMonth = stats.thisMonth;
      statsThisYear = stats.thisYear;
      statsLastMonth = stats.prevMonth;
      statsLastYear = stats.prevYear;
    });
  }

  String getUserNameDecoration() {
    String out = "";
    for (int i = 0; i < username.length; i++) {
      out += "${username[i]} ";
    }
    return out.trim();
  }

  void saveUserName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', name);

    setState(() {
      getUserName();
    });
  }

  void downloadAllData() async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.exportDatabase();
  }

  void importDatabase() async {
    // pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.importDatabase(result.files.single.path!);
  }

  @override
  Widget build(BuildContext context) {
    // variables-------------------------------------------------------------
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double paddingSides = 32.0;

    // interface-------------------------------------------------------------
    return Padding(
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Scaffold(
        body: Column(
          children: [
            // top icons-----------------------------------------------------
            SizedBox(
              height: screenHeight * 0.075,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                // icons----------------------------------------
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // space
                    Container(
                      width: 2,
                    ),

                    // edit name icon---------------------
                    SizedBox(
                      height: 60,
                      width: 50,
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                        ),

                        child: Icon(
                          Icons.mode_edit_outline_rounded,
                          size: 32,
                          color: Colors.grey[600],
                        ),

                        // show bottom sheet (to edit name)--
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  color: Colors.grey[200],
                                ),
                                width: screenWidth,
                                height: screenHeight / 1.75,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Container(height: 10),

                                      Text(
                                        "edit name:",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 24,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),

                                      Container(height: 20),

                                      // text box for changing name
                                      TextField(
                                        textAlign: TextAlign.start,
                                        controller: TextEditingController(
                                          text: username,
                                        ),
                                        maxLength: 10,
                                        cursorColor: Colors.grey[500],
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.grey[700],
                                          fontSize: 18,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "enter your name...",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide(
                                                color: Colors.grey[500]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide(
                                                color: Colors.grey[500]!),
                                          ),
                                          labelStyle: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.grey[500],
                                            fontSize: 18,
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          saveUserName(value);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    Expanded(child: Container()),

                    // export icon-------------------
                    SizedBox(
                      height: 60,
                      width: 50,
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          Icons.file_download_outlined,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          downloadAllData();
                        },
                      ),
                    ),

                    // import icon-------------------
                    SizedBox(
                      height: 60,
                      width: 50,
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          Icons.file_upload_outlined,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          importDatabase();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                color: Colors.grey[300],
                height: 3.0,
              ),
            ),

            // welcome text-------------------------------------------------
            SizedBox(
              height: screenHeight * 0.15,
              child: Container(
                width: screenWidth,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: paddingSides),
                child: Column(
                  // settings
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // welcome----------------------
                    Text(
                      "welcome,",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),

                    // name of the person-----------
                    Text(
                      getUserNameDecoration(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        color: Colors.grey[800],
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              height: 10,
            ),

            // statistics---------------------------------------------------
            Expanded(
              child: GridView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                children: [
                  // this month------------------------------------------
                  SizedBox(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 38,
                                color: Colors.blue[300],
                              ),
                              Container(
                                width: 7.5,
                              ),
                              Text(
                                statsThisMonth.toString(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              thisMonth,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // this year------------------------------------------
                  SizedBox(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 38,
                                color: Colors.purple[300],
                              ),
                              Container(
                                width: 7.5,
                              ),
                              Text(
                                statsThisYear.toString(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              thisYear,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // last month------------------------------------------
                  SizedBox(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 38,
                                color: Colors.red[300],
                              ),
                              Container(
                                width: 7.5,
                              ),
                              Text(
                                statsLastMonth.toString(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              lastMonth,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // last year------------------------------------------
                  SizedBox(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 38,
                                color: Colors.lightGreen[300],
                              ),
                              Container(
                                width: 7.5,
                              ),
                              Text(
                                statsLastYear.toString(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 5),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              lastYear,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
