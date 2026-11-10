import 'package:flutter/material.dart';

import 'study_database.dart';

// Form to add a new session or edit an old one.
// If session is null it adds, if not it edits.
// Based on the lecturer's form, I added edit mode.
class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key, this.session});

  // The record to edit (null when adding).
  final Map<String, Object?>? session;

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  String? _subject;
  bool _isSaving = false;

  static const List<String> _subjects = [
    'Programming',
    'Networking',
    'Mathematics',
    'Reading',
    'Revision',
    'Other',
  ];

  // True when we are editing.
  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    // When editing, put the old values in the fields.
    final session = widget.session;
    if (session != null) {
      _titleController.text = session['title'] as String;
      _subject = session['subject'] as String;
      _durationController.text = (session['duration'] as int).toString();
      _notesController.text = session['notes'] as String;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmSession() async {
    // Check the fields first, then ask for confirmation.
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Confirm update' : 'Confirm save'),
        content: Text(
          _isEditing
              ? 'Save the changes to this study session?'
              : 'Save this study session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    // Cancel means no change.
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    var saved = false;
    try {
      final title = _titleController.text.trim();
      final duration = int.parse(_durationController.text.trim());
      final notes = _notesController.text.trim();

      if (_isEditing) {
        // Update the row that has this id.
        final rows = await StudyDatabase.instance.updateSession(
          id: widget.session!['id'] as int,
          title: title,
          subject: _subject!,
          duration: duration,
          notes: notes,
        );
        saved = rows > 0;
      } else {
        await StudyDatabase.instance.insertSession(
          title: title,
          subject: _subject!,
          duration: duration,
          notes: notes,
        );
        saved = true;
      }
    } catch (_) {
      saved = false;
    }

    if (!mounted) return;
    // Go back to the main screen and show a message.
    final messenger = ScaffoldMessenger.of(context);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      // Stay on the form so the typed data is not lost.
      setState(() => _isSaving = false);
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? (_isEditing
                    ? 'Study session updated'
                    : 'Study session saved')
              : 'Failed to save study session',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Study Session' : 'New Study Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          // Show errors while the user types,
          // and remove them when the value is correct.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) return 'Enter a session title';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Session title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                value: _subject,
                validator: (value) => value == null ? 'Select a subject' : null,
                items: _subjects
                    .map(
                      (subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _subject = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Duration must be a whole number from 1 to 600.
                  final minutes = int.tryParse(value?.trim() ?? '');
                  if (minutes == null) return 'Enter the duration as a number';
                  if (minutes <= 0) return 'Duration must be greater than 0';
                  if (minutes > 600) return 'Duration cannot be over 600 minutes';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _confirmSession,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditing ? 'Save changes' : 'Add session'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
