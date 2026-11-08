# StudyLog

StudyLog is a simple Flutter mobile app that helps a student keep a log of their study sessions. It was made for **STTPK2143 Assignment 1 (Student Life Mobile App)**. All data is saved in a local SQLite database on the phone, so the records are still there after the app is closed and opened again.

## Purpose

Students often forget how much time they spend studying each subject. With StudyLog a student can record each study session (what they studied, for which subject and for how long), look at the saved sessions, edit them and delete them.

## Record fields

| Field | Type | Required | Rule |
|-------|------|----------|------|
| Session title | Text | Yes | Cannot be empty, maximum 50 characters |
| Subject | Dropdown | Yes | Programming, Networking, Mathematics, Reading, Revision, Other |
| Duration (minutes) | Whole number | Yes | Must be a number from 1 to 600 |
| Notes | Text | No | Optional, maximum 200 characters |

## Database structure

Database file: `study_log.db`, table: `study_sessions`

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key, auto increment |
| title | TEXT | Session title |
| subject | TEXT | Chosen subject |
| duration | INTEGER | Minutes studied |
| notes | TEXT | Optional notes (empty text if none) |
| created_at | TEXT | Creation time (ISO 8601). It is not changed when a record is edited |

Records are read newest first (`ORDER BY created_at DESC, id DESC`), ten per page, using `LIMIT` and `OFFSET`.

## Main flow

1. **Splash screen** for 3 seconds, then the home screen.
2. **Home screen** shows the saved sessions, an empty message when there are none, a refresh button, a `+` button and bottom page controls (Previous / Next with "Page x of y").
3. **Add** (`+`): fill in the form, errors are shown if the input is not valid, then a confirmation dialog appears. After Confirm the record is saved in SQLite and the list reloads on page 1.
4. **Details**: tap a session to see its saved fields.
5. **Edit**: press Edit in the details dialog, change the values, confirm, and the same SQLite record is updated. Cancel keeps the old values.
6. **Delete**: long press a session, then confirm. Cancel keeps the record. If the last record on the last page is deleted, the app goes back to the nearest valid page.
7. **Refresh** reads the data from SQLite again.

## Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Starts the app and switches from the splash screen to the home screen |
| `lib/splashscreen.dart` | Splash screen |
| `lib/mainscreen.dart` | Home screen: list, details, delete, pagination, refresh |
| `lib/session_form.dart` | Form used for adding and editing a session |
| `lib/study_database.dart` | SQLite code: create table, insert, read (with paging), count, update, delete |

## Setup

1. Install Flutter and Android Studio (or VS Code with the Flutter extension).
2. Clone this repository.
3. Run `flutter pub get`.
4. Start an Android emulator or connect an Android phone with USB debugging on.
5. Run `flutter run`.

Packages used: `sqflite` (SQLite) and `path`.

## Testing helper

The flask icon in the app bar of the home screen adds 21 sample sessions at once. I used it to test pagination (3 pages) quickly. It is only for testing and can be removed without affecting the rest of the app.

## Credits

- The structure of the app (splash screen, SQLite database class, list with pagination, new record form) is based on the lecturer's example project **mysimplebudget** from <https://github.com/ahmadhanis/FlutterA261/tree/main/mysimplebudget>. I changed it into a study log and added the title field, the edit feature, the update method, extra validation and the automatic validation messages.
- Icons are from the Flutter Material icon set.
- AI assistant: I used an AI assistant (Claude) to help me with modifying and debugging the code. I tested the app myself and I can explain the code.
