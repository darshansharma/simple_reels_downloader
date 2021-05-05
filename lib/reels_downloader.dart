import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:simple_reels_downloader/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ReelsDownloader extends StatefulWidget {
  @override
  _ReelsDownloaderState createState() => _ReelsDownloaderState();
}

class _ReelsDownloaderState extends State<ReelsDownloader> {
  bool isDownloadVideoLoading = false;
  bool getVideoLoadingStatus = false;
  String videoStatus;
  String urlStatus;
  bool isDownloadVideoOperationSuccessfull = false;
  String imageUrl;
  String videoUrl;

  loadProgressBar() {
    setState(() {
      isDownloadVideoLoading = true;
    });
  }

  unloadProgressBar() {
    setState(() {
      isDownloadVideoLoading = false;
    });
  }

  Future<String> transformReelsURL(String url) async {
    setState(() {
      getVideoLoadingStatus = true;
    });
    if (url == null) return 'Please give a URL';
    var urlEdit = url.replaceAll(" ", "").split("/");
    var newUrl =
        '${urlEdit[0]}//${urlEdit[2]}/${urlEdit[3]}/${urlEdit[4]}' + "/?__a=1";
    try {
      var response = await http.get(Uri.parse(newUrl));
      var responseBody = json.decode(response.body);
      if (responseBody != null &&
          responseBody['graphql'] != null &&
          responseBody['graphql']['shortcode_media'] != null) {
        var graphql = responseBody['graphql']['shortcode_media'];
        imageUrl = graphql['display_url'];
        videoUrl = graphql['video_url'];
      } else {
        setState(() {
          getVideoLoadingStatus = false;
        });
        urlStatus = 'Invalid URL';
        throw new ErrorHint('unable to reach instagram\'s graphql json code');
      }
    } catch (error) {
      urlStatus = 'Error occured. Please try again later';
      print(error);
    }

    setState(() {
      getVideoLoadingStatus = false;
    });
    return imageUrl;
  }

  Future<void> downloadVideo() async {
    String filePath;
    loadProgressBar();
    HttpClient httpClient = new HttpClient();
    File file;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Directory appDir = await getExternalStorageDirectory();
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    }
    try {
      Directory dir =
          await new Directory('${appDir.path}/reels').create(recursive: true);
      // var downloadsFolderPath =
      //     await ExtStorage.getExternalStoragePublicDirectory(
      //         ExtStorage.DIRECTORY_MOVIES);
      filePath = Path.join(dir.path, '$fileName.mp4');
    } catch (error) {
      print(error);
    }
    print('filePath $filePath');
    try {
      var request = await httpClient.getUrl(Uri.parse(videoUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        file = File(filePath);
        await file.writeAsBytes(bytes);
        print('Video downloaded successfully');
        ImageGallerySaver.saveFile(filePath);
        setState(() {
          isDownloadVideoOperationSuccessfull = true;
        });
        videoStatus = 'Video downloaded successfully';
      } else {
        print('Some error occurred');
        print('Error status code - ${response.statusCode}');
        videoStatus = 'Some error occurred';
        setState(() {
          isDownloadVideoOperationSuccessfull = false;
        });
      }
      setState(() {
        isDownloadVideoLoading = false;
      });
    } catch (error) {
      setState(() {
        isDownloadVideoLoading = false;
        isDownloadVideoOperationSuccessfull = false;
      });
      print('Unable to fetch url');
      print('Error - $error');
      videoStatus = 'Error while downloading. Try again later';
    }
  }

  Widget downloadVideoButton(String btnText, Function btnFunction) {
    return ElevatedButton(
      onPressed: btnFunction,
      child: Text(
        btnText,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        backgroundColor: MaterialStateProperty.all<Color>(
          BUTTON_GREEN,
        ),
        padding: MaterialStateProperty.all(
          EdgeInsets.all(15),
        ),
      ),
    );
  }

  TextEditingController linkController = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    var deviceHeight = MediaQuery.of(context).size.height;
    var deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(APP_NAME),
        centerTitle: true,
        backgroundColor: BUTTON_GREEN,
      ),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              imageUrl == null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                    )
                  : SizedBox(
                      height: deviceHeight * 0.03,
                    ),
              imageUrl != null
                  ? Column(
                      children: [
                        ClipRRect(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: deviceHeight * 0.3,
                            width: deviceWidth * 0.99,
                          ),
                        ),
                        SizedBox(
                          height: deviceHeight * 0.01,
                        ),
                        isDownloadVideoLoading
                            ? CircularProgressIndicator()
                            : downloadVideoButton(
                                'Download Video',
                                () async {
                                  setState(() {
                                    urlStatus = null;
                                    videoStatus = null;
                                  });
                                  await this.downloadVideo();
                                  linkController.clear();
                                },
                              ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        videoStatus != null && videoStatus.isNotEmpty
                            ? Text(
                                this.videoStatus,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isDownloadVideoOperationSuccessfull
                                      ? Colors.green[400]
                                      : Color(0xffed3b3b),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Container()
                      ],
                    )
                  : Container(),
              imageUrl != null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                    )
                  : Container(),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'Paste link here',
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.07,
              ),
              getVideoLoadingStatus
                  ? CircularProgressIndicator()
                  : downloadVideoButton(
                      'Get Video',
                      () async {
                        setState(() {
                          urlStatus = null;
                          videoStatus = null;
                        });
                        imageUrl =
                            await this.transformReelsURL(linkController.text);
                        linkController.clear();
                      },
                    ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.03,
              ),
              urlStatus != null && urlStatus.isNotEmpty
                  ? Text(
                      this.urlStatus,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xffed3b3b),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
