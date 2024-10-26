import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  const HomeScreen({super.key, required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextEditingController _commentController = TextEditingController();
  final Location _location = Location();
  bool _isLoading = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      setState(() {
        _capturedImage = image;
      });
      _showImagePreviewModal(image);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _showImagePreviewModal(XFile image) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Wrap(
            children: [
              Image.file(File(image.path), fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(labelText: 'Add comment'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Color(0xFF000000),
                    ),
                  ),
                  onPressed: _isLoading ? null : _captureAndSend,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          'Send',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureAndSend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationData = await _location.getLocation();
      final uri = Uri.parse("https://photoupload.free.beeceptor.com");
      final request = http.MultipartRequest('POST', uri)
        ..fields['comment'] = _commentController.text
        ..fields['latitude'] = locationData.latitude.toString()
        ..fields['longitude'] = locationData.longitude.toString()
        ..files.add(
            await http.MultipartFile.fromPath('photo', _capturedImage!.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully!')),
        );

        // Clear the text field after successful upload
        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      // Closes the bottom modal
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox.expand(child: CameraPreview(_controller));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: 30.0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _captureImage,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                width: 63.0,
                height: 63.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFFFFF),
                ),
                child: Center(
                  child: Container(
                    width: 60.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2.0,
                        color: Color(0xFF000000),
                      ),
                      shape: BoxShape.circle,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
