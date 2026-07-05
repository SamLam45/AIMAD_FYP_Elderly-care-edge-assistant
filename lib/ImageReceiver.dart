import 'package:flutter/material.dart';
import 'package:ladr/config/app_config.dart';
import 'dart:io';
import 'dart:typed_data';

class ImageReceiver extends StatefulWidget {
  @override
  _ImageReceiverState createState() => _ImageReceiverState();
}

class _ImageReceiverState extends State<ImageReceiver> {
  Socket? socket;
  List<int> receivedData = [];
  Image? receivedImage;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() async {
    try {
      socket = await Socket.connect(
        AppConfig.jetsonHost,
        AppConfig.jetsonPort,
      );
      print('Connected to server');

      socket!.listen(
        (List<int> data) {
          setState(() {
            receivedData.addAll(data);
          });
        },
        onDone: () {
          if (receivedData.isNotEmpty) {
            setState(() {
              receivedImage = Image.memory(Uint8List.fromList(receivedData));
              receivedData.clear();
            });
            print('Image received');
          }
        },
        onError: (error) {
          setState(() {
            errorMessage = 'Socket error: $error';
          });
        },
      );

      socket?.writeln('open camera');
    } catch (e) {
      setState(() {
        errorMessage = 'Error connecting to server: $e';
      });
      print(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Receiver'),
      ),
      body: Center(
        child: receivedImage != null
            ? Container(
                width: 300,
                height: 300,
                child: receivedImage,
              )
            : errorMessage != null
                ? Text(errorMessage!)
                : CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    socket?.destroy();
    super.dispose();
  }
}
