import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:dcdg/dcdg.dart';

class AddEventScreen extends StatefulWidget {

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  TextEditingController eventController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 3)));

  String reminder = "";
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: eventController,
                style: TextStyle(
                  fontSize: 20.0,
                ),
                decoration: InputDecoration(
                  hintText: 'ADD Event',
                  hintStyle: TextStyle(color: Color(0xFFA9A9A9)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    iconSize: 28,
                    color: Color(0xFF828282),
                    onPressed: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      String event = eventController.text;
                      String startTimeString = _startTime.format(context);
                      String endTimeString = _endTime.format(context);
                      String time = " $startTimeString - $endTimeString ";
                      if (event.isNotEmpty) {
                        setState(() {
                          saveEventToFirebase(event, time, reminder);
                        });
                      }
                      Navigator.pop(context);
                    },
                  ),
                  filled: true,
                  fillColor: Color(0xFFF1F1F1),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.access_alarms_sharp),
                    onPressed: () {
                      Navigator.pop(context);
                      addEventtime(context);
                    },
                    iconSize: 30,
                    color: Color(0xFF828282),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addEventtime(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return FractionallySizedBox(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: eventController,
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ADD Event',
                        hintStyle: TextStyle(color: Color(0xFFA9A9A9)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          iconSize: 28,
                          color: Color(0xFF828282),
                          onPressed: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            String event = eventController.text;
                            String startTimeString = _startTime.format(context);
                            String endTimeString = _endTime.format(context);
                            String time = " $startTimeString - $endTimeString ";
                            if (event.isNotEmpty) {
                              setState(() {
                                saveEventToFirebase(event, time, reminder);
                              });
                            }
                            Navigator.pop(context);
                          },
                        ),
                        filled: true,
                        fillColor: Color(0xFFF1F1F1),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.access_alarms_sharp),
                            onPressed: () {},
                            iconSize: 30,
                            color: Color(0xFF828282),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 25.0),
                            child: Text(
                              "Time",
                              style: TextStyle(
                                  color: Color(0xFF828282), fontSize: 20),
                            ),
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 19.0),
                                child: IconButton(
                                  icon: const Icon(Icons.more_time),
                                  onPressed: () {
                                    showTimeRangePicker(
                                      context: context,
                                      start: _startTime,
                                      end: _endTime,
                                      onStartChange: (start) {
                                        setState(() {
                                          _startTime = start;
                                        });
                                      },
                                      onEndChange: (end) {
                                        setState(() {
                                          _endTime = end;
                                        });
                                      },
                                    );
                                  },
                                  iconSize: 30,
                                  color: Color(0xFF828282),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 1.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showTimeRangePicker(
                                      context: context,
                                      start: _startTime,
                                      end: _endTime,
                                      onStartChange: (start) {
                                        setState(() {
                                          _startTime = start;
                                        });
                                      },
                                      onEndChange: (end) {
                                        setState(() {
                                          _endTime = end;
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text(
                                        " ${_startTime.format(context)}",
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 1.0),
                                child: Text(
                                  "-",
                                  style: TextStyle(
                                      color: Color(0xFF828282), fontSize: 20),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 1.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showTimeRangePicker(
                                      context: context,
                                      start: _startTime,
                                      end: _endTime,
                                      onStartChange: (start) {
                                        setState(() {
                                          _startTime = start;
                                        });
                                      },
                                      onEndChange: (end) {
                                        setState(() {
                                          _endTime = end;
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text(
                                        " ${_endTime.format(context)}",
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.notifications_active_outlined),
                            onPressed: () {},
                            iconSize: 30,
                            color: Color(0xFF828282),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 25.0),
                            child: Text(
                              "Reminder",
                              style: TextStyle(
                                  color: Color(0xFF828282), fontSize: 20),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.only(left: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      reminder = selectedTime.format(context);
                                    });
                                  }
                                });
                              },
                              child: Container(
                                width: 100,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    reminder.isNotEmpty ? reminder : "",
                                    style: TextStyle(
                                      color: Color(0xFF828282),
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
