import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snapbook/helper/notifications_helper.dart';
import 'package:snapbook/pages/calendar.dart';
import 'package:snapbook/pages/gallery.dart';
import 'package:snapbook/pages/settings.dart';
import 'package:snapbook/pages/throwback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsHelper().init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _checkAndRequestPermissions() async {
    if (await Permission.photos.isGranted &&
        await Permission.notification.isGranted) return;

    await Permission.photos.request();
    await Permission.notification.request();

    setState(() {});
  }

  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  void _onPageChanged(index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // interface-----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ask for perms
    _checkAndRequestPermissions();

    return MaterialApp(
      // app settings
      debugShowCheckedModeBanner: false,
      title: 'SnapBook',

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
      ),

      home: Scaffold(
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 0.4,
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              child: SizedBox(
                height: 80.0,
                child: BottomNavigationBar(
                  // nav bar settings
                  currentIndex: _selectedIndex,
                  iconSize: 32,
                  selectedFontSize: 14,
                  showUnselectedLabels: false,
                  unselectedItemColor: Colors.grey[300],
                  selectedItemColor: Colors.grey[700],
                  backgroundColor: Colors.transparent,

                  selectedLabelStyle: const TextStyle(
                    fontFamily: 'inter',
                    fontWeight: FontWeight.w600,
                  ),

                  // nav bar items
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.photo_library_rounded),
                      label: "gallery",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_toggle_off_rounded),
                      label: "throwback",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month),
                      label: "calendar",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_rounded),
                      label: "settings",
                    ),
                  ],

                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastEaseInToSlowEaseOut,
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: const [
            Gallery(),
            Throwback(),
            Calendar(),
            Settings(),
          ],
        ),
      ),
    );
  }
}
