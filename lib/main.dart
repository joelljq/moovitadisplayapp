import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:movitabusapp/ipsettings.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyMain());
}

class MyMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      routes: {
        '/': (context) => MyApp(),
        '/second': (context) => MyIP(),
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MqttServerClient client =
      MqttServerClient('test.mosquitto.org', '1883');
  String json1 = '';
  String json2 = '';
  String json3 = '';
  String message1 = '';
  String message2 = '';
  String message3 = '';
  String message4 = '';
  List bslist = [
    "King Albert Park",
    "Main Entrance",
    "Block 23",
    "Block 20",
    "SIT",
    "Block 43",
    "Block 37",
    "Block 51",
    "Block 81",
    "Block 83",
    "Block 73",
    "",
    ""
  ];
  String choice = "API";
  String RTC = "";
  String _RTC = "";
  String _HC = '';
  String Status = "";
  String CurrentBS = '';
  String CurrentBSS = '';
  String HC = "";
  late String ETA;
  int currentbsindex = 0;
  int secbsindex = 0;
  int thirdbsindex = 0;
  Color ArrivalStatus = Colors.orange;
  bool second = false;
  String IP = "192.168.2.105:5000";

  // Function to connect to MQTT and subscribe to the relevant topics
  void connect() async {
    try {
      await client.connect();
      print('MQTT client connected');
      client.subscribe('/CurrentBusStop', MqttQos.exactlyOnce);
      client.subscribe('/ETA', MqttQos.exactlyOnce);
      client.subscribe('/RTC', MqttQos.exactlyOnce);
      client.subscribe('/HC', MqttQos.exactlyOnce);
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttMessage recMess =
            c[0].payload; // set recMess to payload variable
        final String topic = c[0]
            .topic; // getting the topic name and set as string variable topic
        final MqttPublishMessage publishMessage = recMess as MqttPublishMessage;
        final String message = utf8.decode(
            publishMessage.payload.message); // convert payload into string

        if (topic == '/CurrentBusStop') {
          setState(() {
            json1 = message;
            Map<String, dynamic> jsonBS = jsonDecode(message);
            message1 = jsonBS["Name"];
            print(message1);
            getdisplayindex(
                jsonBS["Name"]); // Calling the bus stop display function
          });
        } else if (topic == '/ETA') {
          setState(() {
            json2 = message;
            Map<String, dynamic> jsoneta = jsonDecode(message);
            message2 = jsoneta["ETA"];
            getBusStatus(jsoneta["ETA"]); // Calling the ETA function
            ETA = message2;
          });
        } else if (topic == '/RTC') {
          setState(() {
            json3 = message;
            Map<String, dynamic> jsonrtc =
                jsonDecode(message); //Set data as a json Map
            getRTC(
                (jsonrtc["RTC"]).substring(0, 5)); // Calling the RTC function
          });
        } else if (topic == '/HC') {
          setState(() {
            message4 = message;
            getHC(message4);
          });
        }
      });
    } catch (e) {
      print('MQTT client connection failed: $e');
    }
  }

  Future<String> getCurrentBS() async {
    try {
      var link = Uri.parse('http://$IP/CurrentBusStop');
      var currentbusdata = await http.get(link);
      setState(() {
        Map<String, dynamic> busstopjson =
            json.decode(currentbusdata.body); //Set data as a json Map
        CurrentBS = busstopjson["Name"];
        getdisplayindex(CurrentBS);
      });
    } catch (e) {
      CurrentBS = '';
    }
    return CurrentBS;
  }

  // API function to retrieve RTC data
  Future<String> getCurrentETA() async {
    try {
      var link = Uri.parse('http://$IP/ETA');
      var ETAdata = await http.get(link);
      // final etadata = await rootBundle.loadString('jsonfile/ETA.json');
      setState(() {
        Map<String, dynamic> etajson =
            json.decode(ETAdata.body); //Set data as a json Map
        ETA = etajson["ETA"];
        getBusStatus(ETA);
      });
    } catch (e) {
      ETA = '';
    }
    return ETA;
  }

  // API function to retrieve RTC data
  Future<String> getCurrentRTC() async {
    try {
      var link = Uri.parse('http://$IP/RTC');
      var RTCdata = await http.get(link);
      // final rtcdata = await rootBundle.loadString('jsonfile/RTC.json');
      setState(() {
        Map<String, dynamic> rtcjson = json.decode(RTCdata.body);
        _RTC = (rtcjson["RTC"]).substring(0, 5);
        getRTC(_RTC);
      });
    } catch (e) {
      _RTC = '';
      getRTC(_RTC);
    }
    return _RTC;
  }

  Future<String> getHeadCount() async {
    try {
      var link = Uri.parse('http://$IP/Headcount');
      var HCdata = await http.get(link);
      // final rtcdata = await rootBundle.loadString('jsonfile/RTC.json');
      setState(() {
        Map<String, dynamic> HCjson = json.decode(HCdata.body);
        _HC = (HCjson["Headcount"]).toString();
        if (_HC == "-1") {
          _HC = "--";
          getHC(_HC);
        } else {
          getHC(_HC);
        }
      });
    } catch (e) {
      // Return empty string if API call fails
      _HC = '';
    }
    return _HC;
  }

  // Function to set the logic for ETA
  getBusStatus(String ETAA) {
    if (ETAA == "00:00") {
      ArrivalStatus = Colors.red;
      Status = "Arrived";
    } else {
      Status = "Next Stop";
      ArrivalStatus = Colors.orange;
    }
  }

  // Function to set RTC variable
  getRTC(String RTCC) {
    if (RTCC.isNotEmpty) {
      RTC = RTCC;
    }
  }

  // Function to set HeadCount variable
  getHC(String HCC) {
    HC = HCC;
  }

  // For the 3 bus stops display indexes
  getdisplayindex(String CBS) {
    CurrentBSS = CBS; // Declare global variable to CBS
    // If the bus stop payload is empty or 0, put the current bus index as 0
    if (CBS == "0" || CBS.isEmpty) {
      currentbsindex = int.parse(CBS);
      secbsindex = currentbsindex + 1;
      thirdbsindex = currentbsindex + 2;
    }
    // In case payload comes as "\11"
    else if (CBS.contains('\"')) {
      currentbsindex = int.parse(CBS.substring(0, 1)) - 1;
      secbsindex = currentbsindex + 1;
      thirdbsindex = currentbsindex + 2;
    }
    // If there isn't any \ in front of the bus stop number payload
    else {
      currentbsindex = int.parse(CBS) - 1;
      secbsindex = currentbsindex + 1;
      thirdbsindex = currentbsindex + 2;
    }
  }

  // Function for calling the API functions
  void API() {
    getCurrentBS();
    getCurrentRTC();
    getCurrentETA();
    getHeadCount();
    bstimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentBS();
    });
    rtctimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentRTC();
    });
    etatimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentETA();
    });
    hctimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getHeadCount();
    });
  }

  // Timers for the different functions
  late Timer bstimer;
  late Timer etatimer;
  late Timer rtctimer;
  late Timer hctimer;

  @override
  void initState() {
    super.initState();
    // When user chooses the different choices from the settings page
    if (choice == "API") {
      setState(() {
        API();
      });
    } else if (choice == "MQTT") {
      setState(() {
        connect();
      });
    }
    // Lock orientation to always landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _loadIPAddress();
  }

  // Dispose the timers
  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    bstimer.cancel();
    etatimer.cancel();
    rtctimer.cancel();
    hctimer.cancel();
    super.dispose();
  }

  // SharedPreference to load the previously set IP address for API
  _loadIPAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      IP = (prefs.getString('ip_address') ?? '');
    });
  }

  // Save the IP address to persistent storage
  _saveIPAddress(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('ip_address', value);
    setState(() {
      IP = (prefs.getString('ip_address') ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'ClinicaPro',
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            FractionallySizedBox(
              heightFactor: 1.0,
              widthFactor: 1.0,
              child: Image.asset(
                "images/background2.jpg",
                fit: BoxFit.contain,
              ),
            ),
            // Positioned icon button For the Settings page
            Positioned(
              top: 50,
              right: 50,
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.black, size: 50),
                onPressed: () async {
                  bstimer.cancel();
                  etatimer.cancel();
                  rtctimer.cancel();
                  hctimer.cancel();
                  dynamic result =
                      await Navigator.pushNamed(context, '/second');
                  // Set the relevant choices and ip addresses from settings page
                  setState(() {
                    if (result[0] != '') {
                      IP = result[0];
                      choice = result[1];
                      _saveIPAddress(IP);
                    } else {
                      choice = result[1];
                    }
                    if (choice == "API") {
                      API();
                    } else if (choice == "MQTT") {
                      connect();
                    }
                  });
                },
              ),
            ),
            Positioned(
              top: 165,
              right: 279,
              child: Container(
                height: 72,
                width: 72,
                margin: EdgeInsets.all(100.0),
                decoration:
                    BoxDecoration(color: ArrivalStatus, shape: BoxShape.circle),
              ),
            ),
            Positioned(
                top: 250,
                left: 280,
                // Ternary logic if Bus is next stop or arrived
                child: Status == 'Next Stop'
                    ? Image.asset(
                        "images/arrow1.gif", // Animated Arrow
                        scale: 6,
                      )
                    : Image.asset(
                        "images/arrow1.png", // Static Arrow
                        scale: 6,
                      )),
            Positioned(
              top: 260,
              left: 10,
              child: Container(
                height: 70,
                width: 280,
                // Ternary Logic to return spinning ring if status data isn't retrieved yet
                child: Align(
                  alignment: Alignment.center,
                  child: Status.isEmpty
                      ? Center(
                          child: SpinKitDualRing(
                            color: Colors.white,
                            size: 40.0,
                          ),
                        )
                      : Text(
                          Status,
                          style: TextStyle(
                              fontSize: 60,
                              color: Colors.cyanAccent,
                              fontFamily: 'ClinicaPro'),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 430,
              left: 110,
              // Ternary Logic to return spinning ring if RTC data isn't retrieved yet
              child: RTC.isEmpty
                  ? Center(
                      child: SpinKitDualRing(
                        color: Colors.white,
                        size: 70.0,
                      ),
                    )
                  : Text(
                      RTC,
                      style: TextStyle(fontSize: 70, color: Colors.cyanAccent),
                    ),
            ),
            // Widget for Passenger Counter
            Positioned(
              top: 560,
              left: 20,
              child: Text(
                "Passengers\nCounter : ${HC}",
                style: TextStyle(
                  fontSize: 60,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
            Positioned(
              top: 265,
              right: 450,
              child: Container(
                height: 65,
                width: 450,
                // Ternary logic to return 1st bus stop name if Current Bus Stop status is not empty
                child: CurrentBSS.isEmpty
                    ? Center(
                        child: SpinKitDualRing(
                          color: Colors.white,
                          size: 40.0,
                        ),
                      )
                    : Text(
                        bslist[currentbsindex],
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start,
                      ),
              ),
            ),
            Positioned(
              top: 435,
              right: 400,
              child: Container(
                height: 65,
                width: 450,
                // Ternary logic to return 2nd bus stop name if Current Bus Stop status is not empty
                child: CurrentBSS.isEmpty
                    ? Center(
                        child: SpinKitDualRing(
                          color: Colors.white,
                          size: 40.0,
                        ),
                      )
                    : Text(bslist[secbsindex],
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start),
              ),
            ),
            Positioned(
              top: 605,
              right: 360,
              child: Container(
                height: 65,
                width: 450,
                // Ternary logic to return 3rd bus stop name if Current Bus Stop status is not empty
                child: CurrentBSS.isEmpty
                    ? Center(
                        child: SpinKitDualRing(
                          color: Colors.white,
                          size: 40.0,
                        ),
                      )
                    : Text(bslist[thirdbsindex],
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start),
              ),
            ),
            Positioned(
              top: 779,
              right: 10,
              child: Container(
                  height: 60,
                  width: 1330,
                  // Ternary logic to return Marquee text if Current Bus Stop status is not empty
                  child: CurrentBSS.isEmpty
                      ? Center(
                          child: SpinKitDualRing(
                            color: Colors.white,
                            size: 40.0,
                          ),
                        )
                      : Marquee(
                          text:
                              'Please keep your seat belt fastened at all times.',
                          style: TextStyle(fontSize: 50),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          blankSpace: 1330.0,
                          velocity: 100.0,
                          startPadding: 10.0,
                          accelerationDuration: Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
