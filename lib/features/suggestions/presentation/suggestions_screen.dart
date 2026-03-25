import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/suggestions_providers.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  String? _selectedOccasion;

  final _occasions = [
    'Casual',
    'Formal',
    'Party',
    'Date Night',
    'Work',
    'Gym',
    'Outdoor',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = _selectedOccasion != null
        ? ref.watch(outfitSuggestionsProvider(occasion: _selectedOccasion!))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Outfit Suggestions')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Occasion chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s the occasion?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _occasions.map((occasion) {
                    final isSelected = _selectedOccasion == occasion;
                    return FilterChip(
                      label: Text(occasion),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedOccasion = selected ? occasion : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(),

          // Suggestions list
          Expanded(
            child: suggestions == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select an occasion to get suggestions',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : suggestions.when(
                    data: (outfits) {
                      if (outfits.isEmpty) {
                        return Center(
                          child: Text(
                            'No outfit suggestions available.\nAdd more clothes to your wardrobe!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: outfits.length,
                        itemBuilder: (context, index) {
                          final outfit = outfits[index];
                          return _OutfitCard(outfit: outfit);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final Map<String, dynamic> outfit;

  const _OutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    final items = (outfit['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final score = outfit['score'] as num? ?? 0;
    final reason = outfit['reason'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Outfit ${outfit['name'] ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(score * 100).toInt()}% match',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final imagePath = items[i]['image_path'] as String? ?? '';
                  return Container(
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imagePath.isNotEmpty
                        ? Image.file(File(imagePath), fit: BoxFit.cover)
                        : const Icon(Icons.checkroom),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
