import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Message.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Initialize the binding for the Flutter app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String? token = await FirebaseMessaging.instance.getToken();
  print('Firebase Cloud Messaging Token: $token');

  MessagingService messagingService = MessagingService();
  messagingService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gradient Background',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
      },
    );
  }
}
