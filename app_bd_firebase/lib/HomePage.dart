import 'dart:convert';
import 'dart:typed_data';

import 'package:app_bd_firebase/auth_page.dart';
import 'package:app_bd_firebase/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _postController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  // SELECCIONAR IMAGEN
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // PUBLICAR POST
  Future<void> _addPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo o selecciona una imagen')),
      );

      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      String imageBase64 = '';

      // CONVERTIR IMAGEN A BASE64
      if (_selectedImage != null) {
        Uint8List imageBytes = await _selectedImage!.readAsBytes();

        imageBase64 = base64Encode(imageBytes);
      }

      // GUARDAR POST
      await FirebaseFirestore.instance.collection('posts').add({
        'content': _postController.text.trim(),

        'userEmail': user?.email ?? 'Usuario',

        'uid': user?.uid,

        'imageBase64': imageBase64,

        'timestamp': Timestamp.now(),
      });

      // LIMPIAR
      _postController.clear();

      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación creada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // CERRAR SESIÓN
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  // ELIMINAR POST
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  // EDITAR POST
  Future<void> _editPost(String postId, String oldContent) async {
    TextEditingController editController = TextEditingController(
      text: oldContent,
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar publicación'),

          content: TextField(controller: editController, maxLines: 4),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .update({'content': editController.text.trim()});

                if (!mounted) return;

                Navigator.pop(context);
              },

              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,

        title: const Text(
          'Publicaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          // FOTO PERFIL
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get(),

            builder: (context, snapshot) {
              String profileImage = '';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;

                profileImage = data['profileImage'] ?? '';
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },

                child: Padding(
                  padding: const EdgeInsets.only(right: 10),

                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,

                    backgroundImage: profileImage.isNotEmpty
                        ? MemoryImage(base64Decode(profileImage))
                        : null,

                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.orange)
                        : null,
                  ),
                ),
              );
            },
          ),

          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),

      body: Column(
        children: [
          // CREAR POST
          Container(
            color: Colors.white,

            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  maxLines: 3,

                  decoration: InputDecoration(
                    hintText: '¿Qué estás pensando?',

                    filled: true,

                    fillColor: Colors.grey[100],

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),

                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // PREVIEW IMAGEN
                if (_selectedImage != null)
                  FutureBuilder<Uint8List>(
                    future: _selectedImage!.readAsBytes(),

                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.memory(
                          snapshot.data!,

                          height: 200,

                          width: double.infinity,

                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,

                      icon: const Icon(Icons.image),

                      label: const Text('Imagen'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,

                        foregroundColor: Colors.white,
                      ),
                    ),

                    const Spacer(),

                    ElevatedButton(
                      onPressed: _addPost,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,

                        foregroundColor: Colors.white,
                      ),

                      child: const Text('Publicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // POSTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar posts'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(child: Text('No hay publicaciones'));
                }

                return ListView.builder(
                  itemCount: posts.length,

                  itemBuilder: (context, index) {
                    final post = posts[index];

                    final data = post.data() as Map<String, dynamic>;

                    final content = data['content'] ?? '';

                    final userEmail = data['userEmail'] ?? '';

                    final imageBase64 = data['imageBase64'] ?? '';

                    String formattedDate = '';

                    if (data['timestamp'] != null) {
                      final timestamp = (data['timestamp'] as Timestamp)
                          .toDate();

                      formattedDate = DateFormat(
                        'dd/MM/yyyy hh:mm a',
                      ).format(timestamp);
                    }

                    return Card(
                      margin: const EdgeInsets.all(8),

                      elevation: 4,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // CABECERA
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.orange,

                                  child: Text(
                                    userEmail.isNotEmpty
                                        ? userEmail[0].toUpperCase()
                                        : '?',

                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    userEmail,

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // MENU
                                if (data['uid'] == currentUser.uid)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editPost(post.id, content);
                                      }

                                      if (value == 'delete') {
                                        _deletePost(post.id);
                                      }
                                    },

                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',

                                        child: Text('Editar'),
                                      ),

                                      const PopupMenuItem(
                                        value: 'delete',

                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // TEXTO
                            if (content.isNotEmpty)
                              Text(
                                content,

                                style: const TextStyle(fontSize: 16),
                              ),

                            // IMAGEN
                            if (imageBase64.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),

                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),

                                  child: Image.memory(
                                    base64Decode(imageBase64),

                                    height: 220,

                                    width: double.infinity,

                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // FECHA
                            Text(
                              formattedDate,

                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
