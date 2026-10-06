import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';
import 'image_service.dart';

class DocumentStore extends ChangeNotifier {
  DocumentStore._();

  static final DocumentStore instance = DocumentStore._();

  final List<ScanDocument> _documents = <ScanDocument>[];
  Directory? _rootDirectory;
  bool _isReady = false;

  List<ScanDocument> get documents => List.unmodifiable(_documents);
  bool get isReady => _isReady;

  Future<void> initialize() async {
    if (_isReady) return;

    final appDirectory = await getApplicationDocumentsDirectory();
    _rootDirectory = Directory(p.join(appDirectory.path, 'scans'));
    await _rootDirectory!.create(recursive: true);
    final metadata = File(p.join(_rootDirectory!.path, 'documents.json'));

    if (await metadata.exists()) {
      try {
        final content = await metadata.readAsString();
        final decoded = jsonDecode(content) as List<dynamic>;
        _documents
          ..clear()
          ..addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map(ScanDocument.fromJson)
                .where((document) => document.pages.isNotEmpty),
          );
      } on FormatException {
        // A corrupt index should not prevent the user from opening the app.
        _documents.clear();
      }
    }

    _isReady = true;
    notifyListeners();
  }

  ScanDocument? findById(String id) {
    for (final document in _documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Future<ScanDocument> createFromFiles(
    List<String> sourcePaths, {
    String? title,
  }) async {
    _assertReady();
    final pages = <ScannedPage>[];
    for (final sourcePath in sourcePaths) {
      final normalizedPath = await ImageService.normalizeToJpeg(
        sourcePath: sourcePath,
        destination: _rootDirectory!,
      );
      pages.add(
        ScannedPage(
          id: _newId(),
          path: normalizedPath,
        ),
      );
    }

    final now = DateTime.now();
    final document = ScanDocument(
      id: _newId(),
      title: title ?? 'Documento sin título',
      pages: pages,
      createdAt: now,
      updatedAt: now,
    );
    _documents.insert(0, document);
    await _persist();
    notifyListeners();
    return document;
  }

  Future<ScannedPage?> addPageFromFile(String documentId, String sourcePath) async {
    _assertReady();
    final document = findById(documentId);
    if (document == null) return null;

    final normalizedPath = await ImageService.normalizeToJpeg(
      sourcePath: sourcePath,
      destination: _rootDirectory!,
    );
    final page = ScannedPage(id: _newId(), path: normalizedPath);
    document.pages.add(page);
    document.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
    return page;
  }

  Future<void> replacePageImage(
    String documentId,
    String pageId,
    String newPath,
    ScanFilter filter,
  ) async {
    _assertReady();
    final document = findById(documentId);
    if (document == null) return;
    ScannedPage? page;
    for (final candidate in document.pages) {
      if (candidate.id == pageId) {
        page = candidate;
        break;
      }
    }
    if (page == null) return;

    final oldPath = page.path;
    page.path = newPath;
    page.filter = filter;
    document.updatedAt = DateTime.now();
    await _persist();
    if (oldPath != newPath) {
      await _deleteIfExists(oldPath);
    }
    notifyListeners();
  }

  Future<void> reorderPages(String documentId, int oldIndex, int newIndex) async {
    final document = findById(documentId);
    if (document == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final page = document.pages.removeAt(oldIndex);
    document.pages.insert(newIndex, page);
    document.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> deletePage(String documentId, String pageId) async {
    final document = findById(documentId);
    if (document == null) return;
    final index = document.pages.indexWhere((page) => page.id == pageId);
    if (index == -1) return;
    final page = document.pages.removeAt(index);
    await _deleteIfExists(page.path);
    document.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> rename(String documentId, String title) async {
    final document = findById(documentId);
    if (document == null) return;
    document.title = title.trim().isEmpty ? 'Documento sin título' : title.trim();
    document.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteDocument(String documentId) async {
    final index = _documents.indexWhere((document) => document.id == documentId);
    if (index == -1) return;
    final document = _documents.removeAt(index);
    for (final page in document.pages) {
      await _deleteIfExists(page.path);
    }
    await _persist();
    notifyListeners();
  }

  Future<Directory> get storageDirectory async {
    _assertReady();
    return _rootDirectory!;
  }

  Future<Directory> get exportsDirectory async {
    _assertReady();
    final directory = Directory(p.join(_rootDirectory!.path, 'exports'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _persist() async {
    final metadata = File(p.join(_rootDirectory!.path, 'documents.json'));
    await metadata.writeAsString(
      jsonEncode(_documents.map((document) => document.toJson()).toList()),
      flush: true,
    );
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_documents.length}';

  void _assertReady() {
    if (!_isReady || _rootDirectory == null) {
      throw StateError('DocumentStore todavía no está inicializado');
    }
  }
}
