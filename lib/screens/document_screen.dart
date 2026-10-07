import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_model.dart';
import '../services/document_store.dart';
import '../services/pdf_service.dart';
import 'camera_screen.dart';
import 'editor_screen.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({
    required this.documentId,
    required this.store,
    super.key,
  });

  final String documentId;
  final DocumentStore store;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isWorking = false;

  ScanDocument? get document => widget.store.findById(widget.documentId);

  Future<void> _addFromCamera() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (!mounted || path == null) return;
    await _saveNewPage(path);
  }

  Future<void> _addFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 96, maxWidth: 2600);
      if (!mounted || image == null) return;
      await _saveNewPage(image.path);
    } catch (_) {
      if (mounted) _showMessage('No se pudo importar la imagen.');
    }
  }

  Future<void> _saveNewPage(String path) async {
    setState(() => _isWorking = true);
    try {
      await widget.store.addPageFromFile(widget.documentId, path);
    } catch (_) {
      if (mounted) _showMessage('No se pudo añadir la página.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _openAddPageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Añadir página',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SheetIcon(icon: Icons.document_scanner_outlined),
                title: const Text('Escanear con cámara'),
                subtitle: const Text('Captura otra página'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addFromCamera();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SheetIcon(icon: Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                subtitle: const Text('Usa una imagen del dispositivo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPage(ScannedPage page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          store: widget.store,
          documentId: widget.documentId,
          page: page,
        ),
      ),
    );
  }

  Future<void> _deletePage(ScannedPage page) async {
    final current = document;
    if (current == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar página?'),
        content: const Text('Esta página se quitará del documento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC9364D)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await widget.store.deletePage(current.id, page.id);
    }
  }

  Future<void> _rename() async {
    final current = document;
    if (current == null) return;
    final controller = TextEditingController(text: current.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renombrar documento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Facturas octubre'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null) await widget.store.rename(current.id, newTitle);
  }

  Future<void> _exportPdf() async {
    final current = document;
    if (current == null || current.pages.isEmpty || _isWorking) return;
    setState(() => _isWorking = true);
    try {
      final exportsDirectory = await widget.store.exportsDirectory;
      final path = await PdfService.createPdf(current, exportsDirectory);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        subject: current.title,
        text: 'Documento escaneado: ${current.title}',
      );
    } catch (_) {
      if (mounted) _showMessage('No se pudo crear el PDF.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final current = document;
        if (current == null) {
          return const Scaffold(body: Center(child: Text('Documento no encontrado')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              current.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Renombrar',
                onPressed: _rename,
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 126),
                itemCount: current.pages.length,
                onReorder: (oldIndex, newIndex) =>
                    widget.store.reorderPages(current.id, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final page = current.pages[index];
                  return Padding(
                    key: ValueKey(page.id),
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PageCard(
                      page: page,
                      number: index + 1,
                      onTap: () => _editPage(page),
                      onDelete: () => _deletePage(page),
                    ),
                  );
                },
              ),
              if (_isWorking)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.78),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isWorking ? null : _openAddPageSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir página'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isWorking ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Compartir PDF'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.number,
    required this.onTap,
    required this.onDelete,
  });

  final ScannedPage page;
  final int number;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.file(
                File(page.path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 36),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE8ECF2))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      page.filter.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.drag_indicator_rounded, color: Color(0xFFA0A8B3)),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Eliminar página')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.more_horiz_rounded, color: Color(0xFF7A8491)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  const _SheetIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFFF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: const Color(0xFF2F6BFF)),
    );
  }
}
