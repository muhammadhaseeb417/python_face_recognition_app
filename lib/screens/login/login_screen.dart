import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:python_face_recognition_app/screens/home/home_screen.dart';

import '../../const_variables.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;

  // Function to choose image from gallery or camera
  Future<void> _pickImage() async {
    // Show a dialog to choose between gallery or camera
    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, ImageSource.gallery); // Select from gallery
              },
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context,
                    ImageSource.camera); // Take a photo with the camera
              },
              child: const Text('Camera'),
            ),
          ],
        );
      },
    );

    // Pick the image using the selected source
    if (pickedSource != null) {
      final pickedFile = await picker.pickImage(source: pickedSource);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  // Function to authenticate the user
  Future<void> _authenticate() async {
    setState(() {
      isLoading = true;
    });
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    final request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}/authenticate'));
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseJson = jsonDecode(responseBody); // Parse JSON
      final name = responseJson['name']; // Extract the name field
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful: ${name}')),
      );
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomeScreen(
              username: name,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? Lottie.asset('assets/authenticate.json')
                : _image != null
                    ? Image.file(_image!)
                    : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image or Take Photo'),
            ),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );
  }
}
