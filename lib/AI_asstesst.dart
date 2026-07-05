import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ladr/config/secrets.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:rhino_flutter/rhino.dart';

class AI_asstesst extends StatefulWidget {
  @override
  _AI_asstesstState createState() => _AI_asstesstState();
}

class _AI_asstesstState extends State<AI_asstesst> {
  bool _listeningForCommand = false;
  PicovoiceManager? _picovoiceManager;
  final String accessKey = Secrets.picovoiceAccessKey;

  @override
  void initState() {
    super.initState();
    _initPicovoice();
  }

  void _initPicovoice() async {
    String platform = Platform.isAndroid ? "android" : "ios";
    String keywordPath = "assets/$platform/Sam-Lam_en_${platform}_v3_0_0.ppn";
    String contextPath =
        "assets/$platform/TO-DO-LIST_en_${platform}_v3_0_0.rhn";

    try {
      _picovoiceManager = await PicovoiceManager.create(accessKey, keywordPath,
          _wakeWordCallback, contextPath, _inferenceCallback);
      _picovoiceManager?.start();
    } on PicovoiceException catch (ex) {
      print(ex);
    }
  }

  void _wakeWordCallback() {
    setState(() {
      _listeningForCommand = true;
    });
  }

  void _inferenceCallback(RhinoInference inference) {
    print(inference);
    if (inference.isUnderstood!) {
      Map<String, String> slots = inference.slots!;
      if (inference.intent == 'setEvent') {
        _performToDoListCommand(slots);
      }
    } else {
      Fluttertoast.showToast(
          msg: "Didn't understand command!\n" +
              "You can try say Set [event] from [hour] [am/pm] to [hour] [am/pm] Set a reminder for [hour] [am/pm] ",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 10,
          backgroundColor: Color.fromRGBO(55, 125, 255, 1),
          textColor: Colors.white,
          fontSize: 16.0);
    }
    setState(() {
      _listeningForCommand = false;
    });
  }

  void saveEventToFirebase(String event, String time, String reminder) {
    final databaseReference = FirebaseDatabase.instance.reference();

    var newEventRef = databaseReference.child('events').push();

    newEventRef.set({
      'event': event,
      'time': time,
      'reminder': reminder,
    }).then((_) {
      print('Event and time saved successfully.');
    }).catchError((error) {
      print('Failed to save event and time: $error');
    });
  }

  void _performToDoListCommand(Map<String, String> slots) {
    int hour = 0;
    int hours = 0;
    int hourss = 0;
    int minute = 0;
    int minute1 = 0;
    int minute2 = 0;
    String event = "";
    String PMAM = "";
    String PMAM1 = "";
    String PMAM2 = "";

    if (slots['event'] != null) {
      event = slots['event']!;
    }

    if (slots['hour'] != null) {
      hour = int.parse(slots['hour']!);
    }
    if (slots['min'] != null) {
      minute = int.parse(slots['min']!);
    } else {}

    if (slots['hours'] != null) {
      hours = int.parse(slots['hours']!);
    }
    if (slots['mins'] != null) {
      minute1 = int.parse(slots['mins']!);
    } else {}

    if (slots['hourss'] != null) {
      hourss = int.parse(slots['hourss']!);
    }
    if (slots['minss'] != null) {
      minute2 = int.parse(slots['minss']!);
    } else {}

    if (slots['ampm'] != null) {
      PMAM = slots['ampm']!;
    }
    if (slots['pmam'] != null) {
      PMAM1 = slots['pmam']!;
    }

    if (slots['pmamm'] != null) {
      PMAM2 = slots['pmamm']!;
    }

    if (slots['ampm'] == "PM") hour += 12;
    if (slots['pmam'] == "PM") hours += 12;
    if (slots['pmamm'] == "PM") hourss += 12;

    if (hour == 12 && slots['ampm'] == "am") hour = 0;
    if (hours == 12 && slots['pmam'] == "am") hours = 0;
    if (hourss == 12 && slots['pmamm'] == "am") hourss = 0;

    if (hour == 24) hour = 12;
    if (hours == 24) hours = 12;
    if (hourss == 24) hourss = 12;

    if (hour >= 24 ||
        hours >= 24 ||
        hourss >= 24 ||
        minute >= 60 ||
        minute1 >= 60 ||
        minute2 >= 60) {
      Fluttertoast.showToast(
          msg: "$hour:$minute is an invalid time.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 2,
          backgroundColor: Color.fromRGBO(55, 125, 255, 1),
          textColor: Colors.white,
          fontSize: 16.0);
      Fluttertoast.showToast(
          msg: "Didn't understand command!\n" + "save in firebase ",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 10,
          backgroundColor: Color.fromRGBO(55, 125, 255, 1),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    String time = hour.toString().padLeft(2, '0') +
        ":" +
        minute.toString().padLeft(2, '0') +
        "-" +
        hours.toString().padLeft(2, '0') +
        ":" +
        minute1.toString().padLeft(2, '0');
    String reminder = hourss.toString().padLeft(2, '0') +
        ":" +
        minute2.toString().padLeft(2, '0');
    if (event.isNotEmpty) {
      setState(() {
        saveEventToFirebase(event, time, reminder);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 17,
          right: 17,
          child: Container(
            child: _listeningForCommand
                ? Icon(Icons.mic,
                    size: 50,
                    color: Color.fromARGB(255, 207, 207, 207)) // 修改為白色
                : Icon(Icons.mic_none,
                    size: 50,
                    color: Color.fromARGB(255, 242, 242, 242)), // 修改為白色
          ),
        ),
      ],
    );
  }
}
