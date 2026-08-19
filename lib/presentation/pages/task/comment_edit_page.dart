import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/domain/entities/task_comment.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/task_comments_controller.dart';

String stripHtml(String html) {
  if (html.isEmpty) return html;
  var text = html;
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAll(RegExp(r'&nbsp;'), ' ');
  text = text.replaceAll(RegExp(r'&amp;'), '&');
  text = text.replaceAll(RegExp(r'&lt;'), '<');
  text = text.replaceAll(RegExp(r'&gt;'), '>');
  text = text.replaceAll(RegExp(r'&quot;'), '"');
  text = text.replaceAll(RegExp(r'&#39;'), "'");
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

class CommentEditPage extends ConsumerStatefulWidget {
  final int taskId;
  final TaskComment? comment;

  const CommentEditPage({super.key, required this.taskId, this.comment});

  @override
  ConsumerState<CommentEditPage> createState() => _CommentEditPageState();
}

class _CommentEditPageState extends ConsumerState<CommentEditPage> {
  late TextEditingController _controller;
  bool _isSaving = false;
  bool _hasHtml = false;

  bool get _isEditMode => widget.comment != null;

  @override
  void initState() {
    super.initState();
    final text = widget.comment?.comment ?? '';
    _hasHtml = text.contains('<');
    _controller = TextEditingController(
      text: _hasHtml ? stripHtml(text) : text,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final text = _controller.text;

    if (text.trim().isEmpty) {
      setState(() => _isSaving = false);
      var buildContext = context;
      if (buildContext.mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(buildContext).commentCannotBeEmpty,
            ),
          ),
        );
      }
      return;
    }

    final controller = ref.read(
      taskCommentsControllerProvider(widget.taskId).notifier,
    );

    final bool success;
    if (_isEditMode) {
      success = await controller.updateComment(widget.comment!, text);
    } else {
      success = await controller.addComment(text);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, text);
    } else {
      setState(() => _isSaving = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? l10n.commentUpdateError : l10n.commentAddError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editCommentTitle : l10n.addCommentTitle),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: !_isSaving ? _save : null,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasHtml)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.editDescriptionWarning,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.commentInputHint,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}