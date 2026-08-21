import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers/word_classify_controller.dart';

/// "Name, Place, Animal, Thing" screen: type one Sanskrit word, see which of
/// the four categories it falls into plus one grounded example sentence.
class WordClassifyScreen extends ConsumerStatefulWidget {
  const WordClassifyScreen({super.key});

  @override
  ConsumerState<WordClassifyScreen> createState() => _WordClassifyScreenState();
}

class _WordClassifyScreenState extends ConsumerState<WordClassifyScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(wordClassifyControllerProvider.notifier).classify(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordClassifyControllerProvider);
    final isLoading = state.status == WordClassifyStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Name, Place, Animal, Thing')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter one Sanskrit word to see whether it names a person, a '
                  'place, an animal, or a thing — with an example sentence.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(hintText: 'e.g. गजः'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Classify'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state.status == WordClassifyStatus.error)
                  _ErrorCard(message: state.errorMessage ?? 'Something went wrong.')
                else if (state.status == WordClassifyStatus.loaded && state.result != null)
                  _ResultCard(result: state.result!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final WordClassificationResponse result;

  static const _categoryLabels = {
    WordCategory.name: 'Name',
    WordCategory.place: 'Place',
    WordCategory.animal: 'Animal',
    WordCategory.thing: 'Thing',
  };

  static const _categoryIcons = {
    WordCategory.name: Icons.badge_outlined,
    WordCategory.place: Icons.place_outlined,
    WordCategory.animal: Icons.pets_outlined,
    WordCategory.thing: Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(result.word, style: theme.textTheme.headlineSmall),
              if (result.iast.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  result.iast,
                  style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          if (result.englishMeaning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(result.englishMeaning, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_categoryIcons[result.category], size: 16),
                const SizedBox(width: 6),
                Text(_categoryLabels[result.category] ?? result.category.value),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Example', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(result.exampleSanskrit, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(result.exampleEnglish, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: error),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: error))),
        ],
      ),
    );
  }
}
