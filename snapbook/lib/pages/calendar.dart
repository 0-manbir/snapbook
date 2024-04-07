import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapbook/helper/database_helper.dart';
import 'package:snapbook/helper/imageview_helper.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const Calendar());
}

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late List<DateTime> _highlightedDates;
  late DatabaseHelper _databaseHelper;
  double screenWidth = 0;
  late ImageDetails details;

  @override
  void initState() {
    super.initState();
    _highlightedDates = [];
    _databaseHelper = DatabaseHelper();

    _initHighlightedDates();
  }

  Future<void> _initHighlightedDates() async {
    await _databaseHelper.initializeDatabase();
    final highlightedDates = await _databaseHelper.getHighlightedDates();
    setState(() {
      _highlightedDates = highlightedDates;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 30,
                ),
                FutureBuilder<List<DateTime>>(
                  future: _databaseHelper.getHighlightedDates(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return TableCalendar(
                          daysOfWeekHeight: 50,
                          eventLoader: (day) => _getEvents(day, snapshot.data!),
                          calendarBuilders: CalendarBuilders(
                            // marker settings
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return const SizedBox();
                              return ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 25),
                                    padding: const EdgeInsets.all(1),
                                    child: Container(
                                      width: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },

                            defaultBuilder: (context, date, events) {
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              );
                            },

                            selectedBuilder: (context, date, events) {
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  // color: Colors.blue[200],
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            },
                            todayBuilder: (context, date, _) {
                              return Container(
                                margin: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                            ),
                            headerPadding: const EdgeInsets.all(10),
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            // day selected---------------------------------------------------------------
                            if (_getEvents(selectedDay, snapshot.data!)
                                .isNotEmpty) {
                              HapticFeedback.mediumImpact();
                              getDataFromDateTime(selectedDay, context);
                            }
                          },
                          focusedDay: DateTime.now(),
                          firstDay: DateTime(2000),
                          lastDay: DateTime(2101),
                        );
                      } else {
                        return const Text(
                          'Error: Unable to fetch highlighted dates',
                          style: TextStyle(
                            fontFamily: 'Inter',
                          ),
                        );
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDataFromDateTime(
      DateTime dateTime, BuildContext buildContext) async {
    details = await DatabaseHelper().getDataFromDateTime(dateTime);

    ImageViewHelper().showImageInBottomSheet(
      0,
      buildContext,
      screenWidth,
      details.path,
      details.caption,
      dateTime,
      false,
    );
  }

  List<dynamic> _getEvents(DateTime day, List<DateTime> highlightedDates) {
    if (highlightedDates.any((highlightedDate) =>
        highlightedDate.year == day.year &&
        highlightedDate.month == day.month &&
        highlightedDate.day == day.day)) {
      return ['highlight'];
    } else {
      return [];
    }
  }
}
