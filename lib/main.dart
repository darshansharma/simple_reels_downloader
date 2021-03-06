import 'package:flutter/material.dart';
import 'package:simple_reels_downloader/reels_downloader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Simple Reels Downloader',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ReelsDownloader());
  }
}
