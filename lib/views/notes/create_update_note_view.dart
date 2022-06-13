import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({Key? key}) : super(key: key);

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService; // CRUD services
  late final TextEditingController _textController;

  // Will return either an existing note or create new note depending on the
  // arguments that were passed to the BuildContext.
  Future<DatabaseNote> _createOrGetExistingNote(BuildContext context) async {
    // Get the argument that was passed to BuildContext using our own function.
    final widgetNote = context.getArgument<DatabaseNote>();

    // If a note was passed as a BuildContext argument, update the textController
    // to hold the current text of that note and return it.
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    // Expecting a user. Even though it may crash if there is no current user,
    // we should never end up in this situation.
    final currentUser = AuthService.firebase().currentUser!;
    // Authentication must be done through email and password, so email must exist.
    final email = currentUser.email;
    final owner = await _notesService.getUser(email: email);
    final newNote = await _notesService.createNote(owner: owner);
    // It is mandatory that _note be assigned to the new note that was created,
    // or else it will not be saved and will get an error regarding a "null
    // is not a subtype of DatabaseNote in typecast".
    _note = newNote;
    return newNote;
  }

  // Notices changes made to the text and will update the note in the database
  // based on those changes.
  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }

    final text = _textController.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );
  }

  // Removes the previous textControllerListener and adds in a new one.
  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  // Saves note in the database as along as there is text in the exisiting note.
  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        // call create or get note function
        future: _createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note...',
                ),
              );

            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
