import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;

  final ImagePicker _picker = ImagePicker();

  // CAMBIAR FOTO
  Future<void> _changeProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile == null) return;

      Uint8List imageBytes = await pickedFile.readAsBytes();

      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImage': base64Image},
      );

      setState(() {});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text('Mi Perfil'),

        backgroundColor: Colors.orange,

        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final name = data?['name'] ?? 'Usuario';

          final email = data?['email'] ?? user.email ?? '';

          final profileImage = data?['profileImage'] ?? '';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // FOTO
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.orange,

                        backgroundImage: profileImage.isNotEmpty
                            ? MemoryImage(base64Decode(profileImage))
                            : null,

                        child: profileImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white,
                              )
                            : null,
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,

                        child: InkWell(
                          onTap: _changeProfileImage,

                          child: Container(
                            padding: const EdgeInsets.all(10),

                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // NOMBRE
                  Text(
                    name,

                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // EMAIL
                  Text(
                    email,

                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // TARJETA INFO
                  Card(
                    elevation: 5,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.orange,
                            ),

                            title: const Text('Nombre'),

                            subtitle: Text(name),
                          ),

                          const Divider(),

                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: Colors.orange,
                            ),

                            title: const Text('Correo'),

                            subtitle: Text(email),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
