import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/model/set/vocab_item.dart';
import 'package:lexifold/features/main/library/screens/crud_study_set/providers/form_state_provider.dart';
import 'package:lexifold/l10n/app_localizations.dart';
import 'package:lexifold/utils/validator_utils.dart';

class VocabularyItemTile extends ConsumerStatefulWidget {
  final int index;
  final VocabItem item;
  final String setId;
  final GlobalKey<FormState> formKey;
  final bool isUpdate;

  const VocabularyItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.formKey,
    required this.isUpdate,
    required this.setId,
  });

  @override
  ConsumerState<VocabularyItemTile> createState() =>
      _VocabularyItemTileState();
}

class _VocabularyItemTileState
    extends ConsumerState<VocabularyItemTile> {
  late final TextEditingController _termController;
  late final TextEditingController _defController;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController(
      text: widget.item.vocabulary.term,
    );
    _defController = TextEditingController(
      text: widget.item.vocabulary.definition,
    );
  }

  @override
  void didUpdateWidget(covariant VocabularyItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.vocabulary.term !=
            widget.item.vocabulary.term &&
        _termController.text != widget.item.vocabulary.term) {
      _termController.text = widget.item.vocabulary.term;
    }
    if (oldWidget.item.vocabulary.definition !=
            widget.item.vocabulary.definition &&
        _defController.text != widget.item.vocabulary.definition) {
      _defController.text = widget.item.vocabulary.definition;
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    _defController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final notifier = ref.read(
      studySetFormStateProvider((
        widget.setId,
        widget.isUpdate,
      )).notifier,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      //notifier.removeCard(widget.item.vocabulary.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.textDeleteCard,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.textTerm,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _termController,
              focusNode: widget.item.termFocus,
              onChanged: (val) {
                notifier.updateTerm(widget.item.vocabulary.id, val);
              },
              style: TextStyle(color: colorScheme.primary),
              validator: (value) =>
                  Validators.checkInputNotEmpty(value, l10n),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l10n.hintEnterTerm,
                filled: true,
                fillColor: colorScheme.onPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.textDefine,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _defController,
              focusNode: widget.item.defineFocus,
              style: TextStyle(color: colorScheme.primary),
              onChanged: (val) {
                notifier.updateDefinition(
                  widget.item.vocabulary.id,
                  val,
                );
              },
              validator: (value) =>
                  Validators.checkInputNotEmpty(value, l10n),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.hintEnterDefine,
                filled: true,
                fillColor: colorScheme.onPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
