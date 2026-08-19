import 'package:flutter/material.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';

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

class EditDescription extends StatefulWidget {
  final String? initialText;

  const EditDescription({super.key, required this.initialText});

  @override
  EditDescriptionState createState() => EditDescriptionState();
}

class EditDescriptionState extends State<EditDescription> {
  late TextEditingController _controller;
  bool _hasHtml = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialText ?? '';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editDescriptionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
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
                  hintText: 'Your text here...',
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