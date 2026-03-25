import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/tryon_providers.dart';
import '../../wardrobe/data/wardrobe_providers.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  File? _bodyImage;
  int? _selectedClothingId;
  File? _tryOnResult;
  bool _isProcessing = false;
  String? _error;

  Future<void> _pickBodyImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() {
      _bodyImage = File(picked.path);
      _tryOnResult = null;
      _error = null;
    });
  }

  Future<void> _runTryOn() async {
    if (_bodyImage == null || _selectedClothingId == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await ref.read(
        performTryOnProvider(
          bodyImage: _bodyImage!,
          clothingItemId: _selectedClothingId!,
        ).future,
      );
      setState(() {
        _tryOnResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clothingItems = ref.watch(clothingItemsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Try-On')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Body photo section
            Text('Your Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _pickBodyImage,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _bodyImage != null
                      ? Image.file(_bodyImage!, fit: BoxFit.cover)
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_alt_1,
                                size: 48,
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to take a body photo',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Clothing selector
            Text('Select Clothing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: clothingItems.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Add clothes to your wardrobe first',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = _selectedClothingId == item.id;
                      final imagePath = item.croppedImagePath ?? item.imagePath;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedClothingId = item.id;
                          _tryOnResult = null;
                        }),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),

            const SizedBox(height: 24),

            // Try-on button
            FilledButton.icon(
              onPressed: _bodyImage != null && _selectedClothingId != null && !_isProcessing
                  ? _runTryOn
                  : null,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isProcessing ? 'Processing...' : 'Try It On'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],

            // Result
            if (_tryOnResult != null) ...[
              const SizedBox(height: 24),
              Text('Result', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Image.file(_tryOnResult!, fit: BoxFit.contain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
