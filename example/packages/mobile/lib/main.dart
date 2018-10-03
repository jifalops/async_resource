import 'package:flutter/material.dart';
import 'package:async_resource_flutter/async_resource_flutter.dart';
import 'package:async_resource_example/config.dart';
import 'src/resources.dart';
import 'src/post_widgets.dart';

void main() => runApp(MaterialApp(
    title: appName,
    home: FutureHandler(
      // This looks up the application documents directory so network requests
      // know where to cache results.
      future: MobileResources.init(),
      handler: (context, resources) => HomePage(),
    )));

class HomePage extends StatefulWidget {
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const lightBg = Color(0xFFfefefe);
  static const darkBg = Color(0xFF333333);

  int selectedPage = 0;
  Color bgColor = lightBg;

  @override
  void initState() {
    super.initState();
    resources.darkBackground.get().then((dark) => setState(() {
          bgColor = dark ? darkBg : lightBg;
          textColor = dark ? Colors.white : Colors.black;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(appName),
        actions: <Widget>[
          Switch(value: bgColor == darkBg, onChanged: (_) => toggleColor())
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedPage,
        onTap: (index) {
          if (index != selectedPage) setState(() => selectedPage = index);
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit), title: Text('Streamed\nHelpers')),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_remote),
              title: Text('Future\nHelpers')),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_input_antenna),
              title: Text('Streamed')),
          BottomNavigationBarItem(
              icon: Icon(Icons.shuffle), title: Text('Future')),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (selectedPage) {
      case 1:
        return PostsWithHelpers();
      case 2:
        return StreamedPostsWithoutHelpers();
      case 3:
        return PostsWithoutHelpers();
      case 0:
      default:
        return StreamedPostsWithHelpers();
    }
  }

  void toggleColor() => setState(() {
        final turningDark = bgColor == lightBg;
        bgColor = turningDark ? darkBg : lightBg;
        textColor = turningDark ? Colors.white : Colors.black;
        resources.darkBackground.write(turningDark);
      });
}
