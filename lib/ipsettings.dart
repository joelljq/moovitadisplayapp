import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyIP extends StatefulWidget {
  const MyIP({Key? key}) : super(key: key);

  @override
  State<MyIP> createState() => _MyIPState();
}

class _MyIPState extends State<MyIP> {
  String IP = '';
  String IPInput = '';
  String choiceselect = 'API';
  String choice = '';
  late SharedPreferences _prefs;
  final nameField = TextEditingController();

  @override
  void initState() {
    _loadIPAddress();
    super.initState();
    // Lock orientation to always landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _loadIPAddress();
  }

  // Load the IP address from persistent storage
  void _loadIPAddress() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      IP = _prefs.getString('ip_address')!;
    });
    nameField.text = IP;
  }

  // Save the IP address to persistent storage
  _saveIPAddress() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString('ip_address', IPInput);
    setState(() {
      IP = IPInput;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Set IP Address",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange,
        ),
        body: Align(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: choiceselect,
                onChanged: (String? newValue) {
                  setState(() {
                    choiceselect = newValue!;
                  });
                },
                items: <String>['API', 'MQTT']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              Text(
                "Current API Link is http://$IP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: nameField,
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter IP Address"),
                  onChanged: (value) {
                    IPInput = value;
                  },
                ),
              ),
              Center(
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    setState(() {
                      _saveIPAddress(); //Shared Preference for saving ip address
                      IP = IPInput;
                      choice = choiceselect;
                      print(IP + choice);
                      // Pass the data to the first route and pop the second route off the stack
                      // Sent over IP address and choice of either API or MQTT to main page
                      Navigator.pop(context, [IP, choice]);
                    });
                  },
                  child: Text('Set IP Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
