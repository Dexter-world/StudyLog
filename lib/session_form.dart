import 'package:flutter/material.dart';

import 'study_database.dart';

/// Form used to add a new study session or to edit an existing one.
/// If [session] is null the form adds a new record, otherwise it edits it.
/// (Based on the lecturer's NewBudgetPage, with edit mode added.)
class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key, this.session});

  // The saved record to edit (a row from SQLite), or null when adding.
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

  // True when we are editing a saved record.
  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    // When editing, fill the form with the saved values first.
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
    // Only ask for confirmation after all fields pass validation.
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
    // Cancel (or tapping outside) leaves the record unchanged.
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    var saved = false;
    try {
      final title = _titleController.text.trim();
      final duration = int.parse(_durationController.text.trim());
      final notes = _notesController.text.trim();

      if (_isEditing) {
        // Update the same row in SQLite using its id.
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
    // Send the result back to the main screen, then show a message.
    final messenger = ScaffoldMessenger.of(context);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      // Stay on the form so the user does not lose what was typed.
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
          // Show the error message as soon as the user changes a field,
          // and hide it again once the value is fixed.
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
                  // Duration must be a whole number of minutes, 1 to 600.
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
