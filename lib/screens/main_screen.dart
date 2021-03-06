import 'dart:async';
import 'dart:io';
import 'dart:ui' as prefix0;
import 'package:drink_remainder/components/route.dart';
import 'package:drink_remainder/store/water_day_record.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as prefix1;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'setting.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int go = 0;
  List<WaterDayRecord> recordList = List<WaterDayRecord>();
  int delay = 1;

  double sofar = 0;
  int streak = 0;
  var recordSoup;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  double percent = 0;
  Timer _timer;

  int count = 0;

  @override
  void initState() {
    super.initState();
    _getPref();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  ect(double top) => Container(margin: EdgeInsets.only(top: top));
  ecl(double left) => Container(margin: EdgeInsets.only(left: left));

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: _layout(),
        resizeToAvoidBottomPadding: false,
      ),
    );
  }

  Widget _layout() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[_full()],
          ),
        ),
        Column(
          children: <Widget>[
            Spacer(),
            Container(
                margin: EdgeInsets.only(bottom: 16), child: _bottomCard()),
          ],
        )
      ],
    );
  }

  Widget _full() {
    return Expanded(
      flex: 1,
      child: ListView(
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          ect(40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[_setting()],
          ),
          _todayProgressText(),
          Row(
            children: <Widget>[
              _inTakeAmount(),
              ecl(20),
              Column(children: <Widget>[ect(20), _overAllAmount()]),
            ],
          ),
          _progress(),
          ect(30),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _statusWidget(
                    _statusCount("$streak"), _statusText("day streak"),
                    color: Color.fromRGBO(255, 159, 159, 0.51)),
                _statusWidget(
                  _statusCount((sofar).toStringAsFixed(1)),
                  _statusText("litres drank\nso far"),
                  color: Color.fromRGBO(0, 128, 255, 0.2),
                )
              ]),
          ect(30),
          _previousRecords(),
        ],
      ),
    );
  }

  Widget _setting() {
    return Container(
        child: InkWell(
            child: Icon(Icons.settings),
            onTap: () {
              Navigator.push(context, FadeRoute(page: Setting()));
            }));
  }

  Widget _todayProgressText() {
    return Text(
      "Today's progress",
      style: TextStyle(
          color: Color.fromRGBO(0, 128, 255, 1),
          fontSize: 24,
          fontFamily: 'Muli-Bold'),
    );
  }

  Widget _inTakeAmount() {
    return Text(
      "$count ml",
      style: TextStyle(fontSize: 48, fontFamily: 'Muli-Bold'),
    );
  }

  Widget _overAllAmount() {
    return Text(
      "/ $go ml",
      style: TextStyle(
          color: Color.fromRGBO(143, 143, 143, 1),
          fontSize: 18,
          fontFamily: 'Muli-Bold'),
    );
  }

  Widget _progress() {
    return Padding(
        padding: EdgeInsets.all(5),
        child: LinearPercentIndicator(
          lineHeight: 25.0,
          backgroundColor: Color.fromRGBO(223, 223, 223, 0.45),
          progressColor: Colors.blueAccent,
          percent: percent,
        ));
  }

  Widget _statusWidget(Widget count, Widget text, {color}) {
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10),
      width: 140.0,
      height: 190.0,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: <Widget>[ect(20), count, ect(30), text],
        ),
      ),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : color,
          blurRadius: 16.0,
        ),
      ]),
    );
  }

  Widget _statusText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18, fontFamily: 'Muli-Bold'),
    );
  }

  Widget _statusCount(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 48, fontFamily: 'Muli-Bold'),
    );
  }

  Widget _previousRecords() {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(0, 10, 0, 30),
          width: MediaQuery.of(context).size.width,
          height: 280.0,
          child: Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color.fromRGBO(52, 52, 52, 1)
                : Color.fromRGBO(255, 255, 255, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ect(20),
                    _statsText(),
                    ect(30),
                    ...handleStats()
                  ],
                )),
          ),
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.16),
              blurRadius: 16.0,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _statsText() {
    return Text(
      "Your stats",
      style: TextStyle(
          color: Color.fromRGBO(152, 152, 152, 1),
          fontSize: 18,
          fontFamily: 'Muli-Bold'),
    );
  }

  _getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int goal = prefs.getInt('goal');
    int delayF = prefs.getInt('delay');
    String recordData = prefs.getString('records');
    int s = prefs.getInt('streak');
    setState(() {
      if (recordData != null) {
        recordList = parseRecordListFromString(recordData);
        recordSoup = recordData.split('\n');
        recordSoup.removeLast();
        recordList.forEach((_record) {
          sofar += (_record.intake / 1000);
        });
      } else {
        recordList.add(WaterDayRecord(DateTime.now(), 0));
        updateSharedPrefRecord(recordList);
      }
    });
    setState(() {
      streak = s;
      go = goal * 1000;
      delay = delayF;
      count = getTodayFromRecordList(recordList).intake;
      if (count > go) {
        percent = 1.0;
        streak = 1;
      } else {
        percent = count / go;
        streak = 0;
      }
    });
    handleStreak();
  }

  Widget _bottomCard() {
    return Center(
        child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: prefix0.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(color: Color.fromRGBO(0, 128, 255, 0.4)),
          width: 330.0,
          height: 100.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[_addingItems()],
          ),
        ),
      ),
    ));
  }

  Widget _addingItems() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _addEntryButton(100, "assets/images/onezerozero.svg"),
        _addEntryButton(200, "assets/images/twozerozero.svg"),
        _addEntryButton(1000, "assets/images/onezerozerozero.svg")
      ],
    );
  }

  Widget _addEntryButton(int ml, String svg) {
    return Container(
        height: 65,
        width: 65,
        child: RawMaterialButton(
          shape: CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.white,
          padding: EdgeInsets.all(15.0),
          onPressed: () {
            setState(() {
              sofar += ml / 1000;
              count += ml;
              print("Entered");
              if (count > go) {
                percent = 1.0;
                setState(() {
                  streak = 1;
                });
              } else {
                percent = count / go;
              }
              recordList = updateTodayIntakeInRecordList(count, recordList);
              print('${recordList.last.date} ${recordList.last.intake}');
              updateSharedPrefRecord(recordList);
            });
            print(delay);
            _scheduleNotify();
          },
          child: Column(
            children: <Widget>[
              SvgPicture.asset(
                "$svg",
                height: 21,
                width: 20,
              ),
              ect(2),
              Text(
                "$ml ml",
                style: TextStyle(
                    fontSize: 8, fontFamily: 'Muli-Bold', color: Colors.black),
              )
            ],
          ),
        ));
  }

  Future<bool> _exitApp(BuildContext context) {
    return showDialog(
          context: context,
          child: AlertDialog(
            title: Text('Do you want to exit this application?'),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              FlatButton(
                onPressed: () => exit(0),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void updateSharedPrefRecord(List<WaterDayRecord> recordList) async {
    String recordAsString = convertRecordListToString(recordList);
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setInt('streak', streak);
    pref.setString('records', recordAsString);
    print("Updated record string in shared: $recordAsString");
    pref.commit();
  }

  _scheduleNotify() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/logo');
    var ios = IOSInitializationSettings();
    var initsetting = InitializationSettings(android, ios);
    flutterLocalNotificationsPlugin.initialize(initsetting);
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(hours: delay));
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your other channel id',
        'your other channel name',
        'your other channel description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(0, "It's time to drink",
        "Be Hydrate", scheduledNotificationDateTime, platformChannelSpecifics);
  }

  void handleStreak() {
    streak = 0;
    recordList.forEach((record) {
      print("Evaluating record: Date: ${record.date} Intake: ${record.date}");
      setState(() {
        if (record.intake >= go) {
          streak += 1;
        } else {
          streak = 0;
        }
      });
    });
  }

  List<Widget> handleStats() {
    List<Widget> itemsToDisplay = [];

    recordList.forEach((record) {
      itemsToDisplay.add(Row(
        children: <Widget>[
          Text(
            '${record.date.day <= 9 ? '0' + record.date.day.toString() : record.date.day}/${record.date.month <= 9 ? '0' + record.date.month.toString() : record.date.month}/${record.date.year} ',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 3.0,
              fontFamily: 'Muli-Bold',
            ),
          ),
          Spacer(),
          Text(
            '${record.intake / 1000} litres',
            style: TextStyle(
              fontFamily: 'Muli-Bold',
              fontSize: 16,
              letterSpacing: 3.0,
            ),
          )
        ],
      ));
    });
    return itemsToDisplay.reversed.toList();
  }
}
