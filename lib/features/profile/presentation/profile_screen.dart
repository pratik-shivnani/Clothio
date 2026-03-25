import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings/app_settings.dart';
import '../data/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _setBodyPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    try {
      await ref.read(saveBodyPhotoProvider(File(picked.path)).future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final stats = ref.watch(wardrobeStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Body photo card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Body Reference Photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  profile.when(
                    data: (p) {
                      if (p == null) {
                        return Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No body photo set',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(p.bodyImagePath),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _setBodyPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Body Photo'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Wardrobe stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wardrobe Stats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  stats.when(
                    data: (s) => Column(
                      children: [
                        _StatRow(
                          icon: Icons.checkroom,
                          label: 'Total Items',
                          value: '${s.totalItems}',
                        ),
                        _StatRow(
                          icon: Icons.category,
                          label: 'Categories',
                          value: '${s.categories}',
                        ),
                        _StatRow(
                          icon: Icons.favorite,
                          label: 'Favorite Outfits',
                          value: '${s.favoriteOutfits}',
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Backend connection
          _BackendSettingsCard(),
        ],
      ),
    );
  }
}

class _BackendSettingsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BackendSettingsCard> createState() => _BackendSettingsCardState();
}

class _BackendSettingsCardState extends ConsumerState<_BackendSettingsCard> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    await ref.read(backendUrlProvider.notifier).setUrl(url);
    ref.invalidate(backendHealthProvider);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final backendUrl = ref.watch(backendUrlProvider);
    final health = ref.watch(backendHealthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Backend Connection',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                health.when(
                  data: (ok) => Icon(
                    ok ? Icons.check_circle : Icons.error,
                    color: ok ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            backendUrl.when(
              data: (url) {
                if (!_editing) {
                  return InkWell(
                    onTap: () {
                      _controller.text = url;
                      setState(() => _editing = true);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              url,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Backend URL',
                        hintText: 'http://192.168.1.100:8000',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.url,
                      autofocus: true,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _editing = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _save,
                          child: const Text('Save & Test'),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 8),
            Text(
              'Set this to your laptop\'s IP to connect from your phone',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
