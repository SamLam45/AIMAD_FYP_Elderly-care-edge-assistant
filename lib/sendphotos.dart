import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ladr/config/app_config.dart';
import 'dart:convert';

import 'Family.dart';
import 'ImageReceiver.dart';

class DataSender {
  final String text;
  final File image;

  DataSender(this.text, this.image);

  Future<void> sendDataToJetsonNano() async {
    try {
      Socket socket = await Socket.connect(
        AppConfig.jetsonHost,
        AppConfig.jetsonPort,
      );

      // send the command to indicate image and name will be sent
      socket.writeln('send image and name');

      // send text data
      socket.writeln(text);

      // get image to base64
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // send image data
      socket.writeln(base64Image);

      socket.close();
      print("資料已成功傳送至 Jetson Nano");
    } catch (e) {
      print("傳送資料時發生錯誤：$e");
    }
  }

  Future<void> sendtrainingtoJetsonNano() async {
    try {
      Socket socket = await Socket.connect(
        AppConfig.jetsonHost,
        AppConfig.jetsonPort,
      );

      // send text data
      socket.writeln('train data');

      socket.close();
      print("資料已成功傳送至 Jetson Nano");
    } catch (e) {
      print("傳送資料時發生錯誤：$e");
    }
  }
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _image;
  String? _text;
  final ImagePicker picker = ImagePicker();

  //select image
  Future<void> _getImageFromGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      // upload to Firebase Storage
      await _uploadImageToFirebaseStorage(_image!);
    }
  }

  //take image
  Future<void> _getImageFromCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      // upload to Firebase Storage
      await _uploadImageToFirebaseStorage(_image!);
    }
  }

  Future<void> _uploadImageToFirebaseStorage(File imageFile) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      Reference reference = storage.ref().child('AI_family_face/$fileName');
      await reference.putFile(imageFile);
      print('照片已成功上傳到 Firebase Storage');
    } catch (e) {
      print('上傳照片到 Firebase Storage 時發生錯誤：$e');
    }
  }

  void _setText(String newText) {
    setState(() {
      _text = newText;
    });
  }

  void _sendDataToJetsonNano() async {
    if (_text != null && _image != null) {
      DataSender dataSender = DataSender(_text!, _image!);
      await dataSender.sendDataToJetsonNano();
      setState(() {
        _image = null;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FamilyPage(text: _text!)),
      );
    } else {
      print("please select image and write text");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Sender'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _image == null
                ? Text('image')
                : Image.file(
                    _image!,
                    width: 200,
                    height: 200,
                  ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getImageFromGallery,
            child: Text('select photo'),
          ),
          ElevatedButton(
            onPressed: _getImageFromCamera,
            child: Text('take photo'),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              onChanged: _setText,
              decoration: InputDecoration(
                labelText: 'Family name',
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sendDataToJetsonNano,
            child: Text('Send Life Assistant'),
          ),
          ElevatedButton(
            onPressed: () async {
              DataSender dataSender = DataSender('', File(''));
              await dataSender.sendtrainingtoJetsonNano();
            },
            child: Text('start training model'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImageReceiver()),
              );
            },
            child: Text('start  model'),
          ),
        ],
      ),
    );
  }
}
