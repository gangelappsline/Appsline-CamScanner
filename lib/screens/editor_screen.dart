import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../services/document_store.dart';
import '../services/image_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    required this.store,
    required this.documentId,
    required this.page,
    super.key,
  });

  final DocumentStore store;
  final String documentId;
  final ScannedPage page;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ScanFilter _selectedFilter;
  Uint8List? _previewBytes;
  bool _isProcessing = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.page.filter;
    _loadPreview(_selectedFilter);
  }

  Future<void> _loadPreview(ScanFilter filter) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final bytes = filter == ScanFilter.original
          ? await File(widget.page.path).readAsBytes()
          : await ImageService.renderFilter(widget.page.path, filter);
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _error = 'No se pudo procesar esta imagen.';
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving || _isProcessing) return;
    setState(() => _isSaving = true);
    try {
      final newPath = _selectedFilter == ScanFilter.original
          ? widget.page.path
          : await ImageService.saveFiltered(
              sourcePath: widget.page.path,
              filter: _selectedFilter,
              destination: await widget.store.storageDirectory,
              baseName: 'page_${DateTime.now().microsecondsSinceEpoch}',
            );
      await widget.store.replacePageImage(
        widget.documentId,
        widget.page.id,
        newPath,
        _selectedFilter,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage('No se pudo guardar el ajuste.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Mejorar imagen'),
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving || _isProcessing ? null : _save,
            child: const Text('Guardar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1B222B),
              padding: const EdgeInsets.all(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_previewBytes != null)
                    Image.memory(
                      _previewBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white),
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (_isSaving)
                    ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 14),
                            Text('Guardando…', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mejorar calidad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Elige un ajuste para que el documento se lea mejor.',
                  style: TextStyle(color: Color(0xFF7A8491), fontSize: 13),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ScanFilter.values
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter.label),
                              selected: _selectedFilter == filter,
                              onSelected: _isProcessing || _isSaving
                                  ? null
                                  : (_) {
                                      if (_selectedFilter != filter) {
                                        setState(() => _selectedFilter = filter);
                                        _loadPreview(filter);
                                      }
                                    },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
