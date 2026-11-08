import 'package:flutter/material.dart';

import 'session_form.dart';
import 'study_database.dart';

/// Shows the saved study sessions and opens the form to add or edit one.
/// (Based on the lecturer's MainScreen, with edit and title added.)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _pageSize = 10;

  List<Map<String, Object?>> _sessions = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    // Load the saved sessions as soon as the main screen appears.
    _loadSessions();
  }

  // Read one page from SQLite and update the list, or show an error.
  Future<void> _loadSessions({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _currentPage = page;
    });

    try {
      final sessionCount = await StudyDatabase.instance.getSessionCount();
      final totalPages = (sessionCount / _pageSize).ceil().clamp(1, 1 << 31);
      // If the page no longer exists (for example after deleting the last
      // record on it), move to the nearest valid page.
      final targetPage = page.clamp(1, totalPages);
      final sessions = await StudyDatabase.instance.getSessions(
        limit: _pageSize,
        offset: (targetPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
        _currentPage = targetPage;
        _totalPages = totalPages;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // Testing helper: adds 21 sample sessions so pagination can be tested quickly.
  // It is only used for testing and demonstration (see README).
  Future<void> _addTestSessions() async {
    for (var i = 1; i <= 21; i++) {
      await StudyDatabase.instance.insertSession(
        title: 'Test session $i',
        subject: 'Other',
        duration: 10 + i,
        notes: '',
      );
    }
    if (!mounted) return;
    await _loadSessions(page: 1);
  }

  // Open the form. Pass a session to edit it, or nothing to add a new one.
  Future<void> _openSessionForm({Map<String, Object?>? session}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => SessionFormPage(session: session),
      ),
    );
    // The form returns true only after SQLite saved the record.
    if (saved != true) return;
    if (session == null) {
      // New record: go to page 1 because newest records are shown first.
      await _loadSessions(page: 1);
    } else {
      // Edited record: stay on the same page.
      await _loadSessions(page: _currentPage);
    }
  }

  Future<void> _confirmDeleteSession(Map<String, Object?> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete study session?'),
        content: const Text('This study session will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await StudyDatabase.instance.deleteSession(
        session['id'] as int,
      );
      if (!mounted) return;
      await _loadSessions(page: _currentPage);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted > 0
                ? 'Study session deleted'
                : 'Study session could not be deleted',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete study session')),
      );
    }
  }

  Future<void> _showSessionDetails(Map<String, Object?> session) async {
    final notes = session['notes'] as String;
    final createdAt = DateTime.tryParse(session['created_at'] as String);
    final formattedDate = createdAt == null
        ? session['created_at'] as String
        : createdAt.toLocal().toString().split('.').first;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session['title'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Subject', session['subject'] as String),
              _detailRow('Duration', '${session['duration']} minutes'),
              _detailRow('Notes', notes.isEmpty ? 'No notes' : notes),
              _detailRow('Created', formattedDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              // Close the details dialog first, then open the edit form.
              Navigator.of(context).pop();
              _openSessionForm(session: session);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyLog'),
        actions: [
          // Testing button (flask icon): adds 21 sample sessions.
          IconButton(
            tooltip: 'Add 21 sample sessions (testing)',
            onPressed: _isLoading ? null : _addTestSessions,
            icon: const Icon(Icons.science),
          ),
          IconButton(
            tooltip: 'Refresh study sessions',
            onPressed: _isLoading
                ? null
                : () => _loadSessions(page: _currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          // The page controls stay visible, but both buttons are disabled
          // when there is only one page or no records.
          if (!_isLoading && !_loadFailed) _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSessionForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: _currentPage > 1 && !_isLoading
                  ? () => _loadSessions(page: _currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page $_currentPage of $_totalPages'),
            IconButton(
              tooltip: 'Next page',
              onPressed: _currentPage < _totalPages && !_isLoading
                  ? () => _loadSessions(page: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load study sessions.'),
            TextButton(
              onPressed: () => _loadSessions(page: _currentPage),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return const Center(child: Text('No study sessions yet.'));
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];

        return ListTile(
          // Tap = details (with Edit), long press = delete.
          onTap: () => _showSessionDetails(session),
          onLongPress: () => _confirmDeleteSession(session),
          leading: const CircleAvatar(child: Icon(Icons.menu_book)),
          title: Text(session['title'] as String),
          subtitle: Text(session['subject'] as String),
          trailing: Text(
            '${session['duration']} min',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
