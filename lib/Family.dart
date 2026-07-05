import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'sendphotos.dart';

class FamilyPage extends StatefulWidget {
  final String text;

  FamilyPage({required this.text});

  @override
  _FamilyPageState createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  List<String> _imageUrls = [];
  String? _text;

  @override
  void initState() {
    super.initState();
    _loadImagesFromFirebaseStorage();
    _text = widget.text;
  }

  void _loadImagesFromFirebaseStorage() async {
    try {
      firebase_storage.ListResult result =
          await storage.ref().child('AI_family_face').listAll();
      List<String> imageUrls = [];
      for (var imageRef in result.items) {
        String downloadUrl = await imageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      setState(() {
        _imageUrls = imageUrls;
      });
      print('從 Firebase Storage 成功下載相片');
    } catch (e) {
      print('從 Firebase Storage 下載相片時發生錯誤：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageUrls.isEmpty
                ? Text('No images')
                : Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.all(8),
                          child: Image.network(
                            _imageUrls[index],
                            width: 200,
                            height: 200,
                          ),
                        );
                      },
                    ),
                  ),
            SizedBox(height: 20),
            Text(_text ?? 'No text'),
            Positioned(
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ImageUploader()),
                      );
                    },
                    iconSize: 28,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
