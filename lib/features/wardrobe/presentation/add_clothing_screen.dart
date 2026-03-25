import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/wardrobe_providers.dart';

class AddClothingScreen extends ConsumerStatefulWidget {
  const AddClothingScreen({super.key});

  @override
  ConsumerState<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends ConsumerState<AddClothingScreen> {
  File? _selectedImage;
  File? _processedImage;
  bool _isProcessing = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _processedImage = null;
      _error = null;
    });

    await _processImage();
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ref.read(
        processClothingImageProvider(_selectedImage!).future,
      );
      setState(() {
        _processedImage = result.croppedImage;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveItem() async {
    if (_selectedImage == null) return;

    try {
      await ref.read(saveClothingItemProvider(
        imagePath: _selectedImage!.path,
        croppedImagePath: _processedImage?.path,
        classification: const {},
      ).future);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clothing'),
        actions: [
          if (_selectedImage != null && !_isProcessing)
            TextButton(
              onPressed: _saveItem,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage == null) ...[
              const SizedBox(height: 40),
              _ImageSourceCard(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _ImageSourceCard(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ] else ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _isProcessing
                      ? Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Removing background...'),
                              ],
                            ),
                          ),
                        )
                      : Image.file(
                          _processedImage ?? _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Backend unavailable. Item will be saved without processing.\n$_error',
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedImage = null;
                  _processedImage = null;
                  _error = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Choose Different Photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageSourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

