import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/model/result/base_result.dart';
import 'package:lexifold/features/main/library/screens/crud_study_set/providers/crud_study_set_provider.dart';
import 'package:lexifold/features/main/library/screens/crud_study_set/providers/form_state_provider.dart';
import 'package:lexifold/features/main/library/widgets/vocab/vocabulary_item.dart';
import 'package:lexifold/utils/show_progress_dialog.dart';
import 'package:lexifold/utils/show_snackbar.dart';

import '../../../../../l10n/app_localizations.dart';

class AddOrUpdateSetScreen extends ConsumerStatefulWidget {
  static String KEY_IS_UPDATE = "AddOrUpdateSetScreen.KEY_IS_UPDATE";
  static String KEY_ID_SET = "AddOrUpdateSetScreen.KEY_ID_SET";

  const AddOrUpdateSetScreen();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AddOrUpdateSetState();
  }
}

class _AddOrUpdateSetState
    extends ConsumerState<AddOrUpdateSetScreen> {
  late ScrollController _scrollController;
  late GlobalKey<FormState> _vocabulariesKey;
  final _idSet = uuid.v4();

  IconData getIconByVisibility(bool isPublic) {
    return isPublic ? Icons.public : Icons.public_off;
  }

  void _addCard((String, bool) args) {
    ref.read(studySetFormStateProvider(args).notifier).addCard();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref
          .read(studySetFormStateProvider(args))
          .valueOrNull;
      if (formState != null && formState.cards.isNotEmpty) {
        final lastCard = formState.cards.last;

        lastCard.termFocus?.requestFocus();

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _addOrUpdateStudySets((String, bool) args) {
    if (_vocabulariesKey.currentState != null &&
        _vocabulariesKey.currentState!.validate()) {
      final crudStudySetNotifier = ref.read(
        crudStudySetProvider.notifier,
      );
      crudStudySetNotifier.addOrUpdateStudySets(args);
    }
  }

  void _handleListenCrudStudySet(
    AsyncValue<BaseResult?>? prev,
    AsyncValue<BaseResult?> next,
    AppLocalizations l10n,
  ) {
    //Tắt loading trước đó
    if (prev != null && prev.isLoading) {
      ShowProgressDialog.hideDialogLoading(context);
    }

    //Hiển thị progress loading
    if (next.isLoading) {
      ShowProgressDialog.showDialogLoading(context);
      return;
    }

    //Crud có dữ liệu trả về
    if (next.hasValue && next.value is BaseResult) {
      final successData = next.value as BaseResult;
      ShowSnackbar.showBaseSnackbar(
        context,
        successData.success
            ? l10n.textHandleSuccess
            : l10n.textHandleFailed,
      );
    }
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _vocabulariesKey = GlobalKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final args =
        ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>;
    final bool isUpdate = args[AddOrUpdateSetScreen.KEY_IS_UPDATE];
    final String idSetArg = args[AddOrUpdateSetScreen.KEY_ID_SET];
    final String idSet = idSetArg.isEmpty ? _idSet : idSetArg;
    //watch study set form
    final studySetForm = ref.watch(
      studySetFormStateProvider((idSet, isUpdate)),
    );

    //listen crud study set
    ref.listen(crudStudySetProvider, (prev, next) {
      _handleListenCrudStudySet(prev, next, l10n);
    });

    return studySetForm.when(
      data: (formData) {
        final argsFormState = (formData.studySetData.id, isUpdate);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.clear),
            ),
            title: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formData.studySetData.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getIconByVisibility(
                            formData.studySetData.isPublic,
                          ),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          formData.studySetData.isPublic
                              ? l10n.textPublic
                              : l10n.textPrivate,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              //Save
              IconButton(
                onPressed: () => _addOrUpdateStudySets(argsFormState),
                icon: Icon(Icons.save_outlined),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () {
              _addCard(argsFormState);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.primaryContainer,
              ),
              child: Text(
                l10n.textAddCard,
                textAlign: TextAlign.center,
                style: TextStyle(
                  overflow: TextOverflow.visible,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          body: Form(
            key: _vocabulariesKey,
            child: ListView.builder(
              itemCount: formData.cards.length,
              addAutomaticKeepAlives: true,
              controller: _scrollController,
              itemBuilder: (ctx, index) {
                final card = formData.cards[index];
                return VocabularyItemTile(
                  key: ValueKey(card.vocabulary.id),
                  index: index,
                  isUpdate: isUpdate,
                  setId: formData.studySetData.id,
                  item: card,
                  formKey: _vocabulariesKey,
                );
              },
            ),
          ),
        );
      },
      error: (err, stack) =>
          Center(child: Text(l10n.textErrorDuringProgress)),
      loading: () => ShowProgressDialog.dialogLoadingWidget(context),
    );
  }
}
