# Chiikawa Study App

A cozy little Flutter app for **reviewing notes** — turn your notes into flashcards, flip through them, and test yourself with quizzes.

The interface is inspired by Chiikawa: a grassy background, doodle-style typography, and a confused little Chiikawa to keep you company while you study.

---

## Table of contents

- [Purpose](#purpose)
- [Features](#features)
- [How it works](#how-it-works)
- [Project status](#project-status)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Data model](#data-model)
- [Design notes](#design-notes)
- [Roadmap](#roadmap)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

---

## Purpose

Chiikawa Study App is a note-review tool. Instead of re-reading pages of notes, you enter each note as a **flashcard** and review it by active recall:

1. Write the **front** (the title or prompt).
2. Write the **back** (the description or answer).
3. Review the cards, flip them, and take quizzes to check what you remember.

Everything is centered on short, snackable review sessions rather than long study marathons.

## Features

### Flashcards

- Each note is stored as a card with two sides:
  - **Front** — the title / question / prompt.
  - **Back** — the description / answer / explanation.
- Cards can be flipped to reveal the back.
- Cards can be reviewed one at a time, at your own pace.

### Quizzes

- Quizzes are built from the notes you have entered.
- Use them to test recall instead of simply re-reading cards.
- Intended to give a quick score or feedback loop so you know what to review next.

### Note entry

- Notes are added from the front of the app.
- The input form has two fields: **Title (front)** and **Description (back)**.
- No separate "editor" mode is needed — adding a note is the same as creating a flashcard.

## How it works

The intended user flow is:

```
Home
 ├── Add note  →  enter front (title) + back (description)  →  saved as a flashcard
 ├── Review    →  flip through saved flashcards
 └── Quiz      →  answer questions generated from saved flashcards  →  see results
```

## Project status

This project is in an early stage. The current code contains the **visual scaffold only**:

- A single home screen with the grassy background, the "There's nothing here..." message, the Chiikawa illustration, and a plus button in the bottom-right corner.
- Registered image and font assets.
- Android, web, and Windows targets configured.

The flashcard, quiz, and note-entry features described above are the **planned behavior** for this app; the screens and storage layer still need to be implemented. See the [Roadmap](#roadmap).

> The default widget test (`test/widget_test.dart`) is still the Flutter counter template and does not match the current UI. It will need to be replaced alongside the first real screen.

## Tech stack

| Piece | Choice |
| --- | --- |
| Framework | Flutter (stable, currently tested with 3.44.9) |
| Language | Dart (SDK `^3.12.2`) |
| UI | Material |
| Platforms | Android, Web, Windows |
| Fonts | `Doodle_Head`, `Mix Doodle` (bundled in `assets/fonts/`) |
| Art | Chiikawa-themed PNGs in `assets/images/` |

No state-management, database, or networking packages are included yet.

## Getting started

### Prerequisites

- Flutter SDK 3.44 or newer with Dart 3.12 or newer
- A target device/emulator, or Chrome/Edge for web, or a Windows desktop toolchain

Check your setup:

```bash
flutter doctor
```

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
# Default/attached device
flutter run

# Web
flutter run -d chrome

# Windows desktop
flutter run -d windows

# Android (with an emulator running or device attached)
flutter run -d <device-id>
```

### Quality checks

```bash
flutter analyze   # static analysis
flutter test      # widget/unit tests
```

## Data model

The minimum information needed for a flashcard is:

| Field | Type | Description |
| --- | --- | --- |
| `id` | string / int | Unique identifier for the card |
| `front` | string | Title of the card — the prompt or question |
| `back` | string | Description — the answer or explanation |

Optional fields worth considering as the app grows:

| Field | Type | Description |
| --- | --- | --- |
| `createdAt` | datetime | When the note was added |
| `lastReviewedAt` | datetime | Last review, for scheduling |
| `timesCorrect` | int | Quiz performance tracking |
| `timesIncorrect` | int | Quiz performance tracking |

Persistence has not been chosen yet. A local key-value store (e.g. `shared_preferences` with JSON), a lightweight database (e.g. `sqflite`/`drift`), or `hive` would all fit the small scope.

## Design notes

- **Fonts**
  - `Doodle_Head` — headings and the main message text.
  - `Mix Doodle` — available for secondary/doodle text.
- **Assets**: images are registered individually in `pubspec.yaml`; add new files there before using them.
- **Background**: the grass PNG keeps its own aspect ratio and scale, and its visible green edge is placed exactly on Chiikawa's feet (both PNGs have padding, so the layout compensates for it). She therefore always appears to stand on top of the grass, at any window size. Adjust `_grassLineFactor` on `HomeScreen` to move the grass edge up or down.
- **Layout**: `lib/main.dart` uses `LayoutBuilder`; tweak `_chiikawaWidthFactor` and `_feetOffsetFactor` on `HomeScreen` to change how big Chiikawa is and how high she stands above the bottom.
- **Tone**: friendly, soft, and playful. Keep copy short and avoid dense text blocks.

## Roadmap

- [ ] Note-entry form (front/title + back/description) with validation
- [ ] Local persistence for cards
- [ ] Flashcard review screen with flip animation
- [ ] Card list / manage screen (edit, delete, search)
- [ ] Quiz mode with scoring and answer feedback
- [ ] Empty, loading, and error states using the bundled Chiikawa art
- [ ] Replace the default counter widget test with tests for the real screens
- [ ] Polish: transitions, sounds, and accessibility labels

## Documentation

- [User Guide](docs/USER_GUIDE.md) — how to add notes, review flashcards, and take quizzes.
- [Developer Guide](docs/DEVELOPER_GUIDE.md) — project layout, data model, and implementation notes.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `Unable to load asset` | Make sure the file is listed under `flutter.assets` in `pubspec.yaml`, then restart (not just hot reload). |
| Fonts look like the default font | Check the `family` name in `pubspec.yaml` matches the `fontFamily` used in code, then fully restart the app. |
| `flutter doctor` complains about a platform | Install the missing SDK/toolchain, or run on a platform that is already configured (web is the quickest). |
| Widget test fails | Expected — the test still targets the old counter sample. Update it when the first real screen lands. |
