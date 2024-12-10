import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:python_face_recognition_app/const_variables.dart';
import 'package:python_face_recognition_app/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  File? _image;
  final picker = ImagePicker();
  final _nameController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (_image == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide name and image')),
      );
      return;
    }

    final request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}/upload'));
    request.fields['name'] = _nameController.text;
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User registered successfully')),
      );
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return HomeScreen();
        },
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to upload data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 20),
              _image != null ? Image.file(_image!) : Text('No image selected'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('Camera'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('Gallery'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
