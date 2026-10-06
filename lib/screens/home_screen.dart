import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/document_model.dart';
import '../services/document_store.dart';
import 'camera_screen.dart';
import 'document_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.store, super.key});

  final DocumentStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isBusy = false;

  Future<void> _scanWithCamera() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (!mounted || path == null) return;
    await _createDocument([path]);
  }

  Future<void> _importImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 96,
        maxWidth: 2600,
      );
      if (!mounted || images.isEmpty) return;
      await _createDocument(images.map((image) => image.path).toList());
    } catch (_) {
      if (mounted) _showMessage('No se pudieron importar las imágenes.');
    }
  }

  Future<void> _createDocument(List<String> paths) async {
    setState(() => _isBusy = true);
    try {
      final document = await widget.store.createFromFiles(paths);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentScreen(
            documentId: document.id,
            store: widget.store,
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showMessage('No se pudo guardar el documento.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openNewSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo documento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Añade una o varias páginas para empezar.',
                style: TextStyle(color: Color(0xFF6C7480)),
              ),
              const SizedBox(height: 20),
              _ActionTile(
                icon: Icons.document_scanner_outlined,
                title: 'Escanear con cámara',
                subtitle: 'Captura una página con la cámara',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanWithCamera();
                },
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Importar de la galería',
                subtitle: 'Selecciona una o varias imágenes',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ScanDocument document) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar documento?'),
        content: Text('Se eliminará “${document.title}” y sus páginas.'),
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
      await widget.store.deleteDocument(document.id);
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
        final documents = widget.store.documents;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Escáner'),
            actions: [
              IconButton(
                tooltip: 'Información',
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'Escáner',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Tus documentos se guardan en este dispositivo.',
                ),
                icon: const Icon(Icons.info_outline_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => widget.store.initialize(),
                color: const Color(0xFF2F6BFF),
                child: documents.isEmpty
                    ? _EmptyState(onCreate: _openNewSheet)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        children: [
                          const Text(
                            'Mis documentos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7A8491),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...documents.map(
                            (document) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DocumentCard(
                                document: document,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DocumentScreen(
                                      documentId: document.id,
                                      store: widget.store,
                                    ),
                                  ),
                                ),
                                onDelete: () => _confirmDelete(document),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_isBusy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withOpacity(0.78),
                    child: const Center(
                      child: _BusyIndicator(label: 'Preparando documento…'),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: documents.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: _isBusy ? null : _openNewSheet,
                  backgroundColor: const Color(0xFF17212B),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo escaneo'),
                ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFFF),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.document_scanner_outlined,
            size: 42,
            color: Color(0xFF2F6BFF),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Escanea sin complicarte',
          style: TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Convierte documentos e imágenes en un PDF limpio, listo para compartir.',
          style: TextStyle(
            color: Color(0xFF6C7480),
            height: 1.45,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear documento'),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF8C96A4)),
            SizedBox(width: 6),
            Text(
              'Todo se guarda en tu dispositivo',
              style: TextStyle(color: Color(0xFF8C96A4), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9EDF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFFF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF2F6BFF)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF7A8491), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA3AE)),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  final ScanDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final firstPage = document.pages.isEmpty ? null : document.pages.first;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 76,
                  child: firstPage == null
                      ? const ColoredBox(color: Color(0xFFEFF2F6))
                      : Image.file(
                          File(firstPage.path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEFF2F6),
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      document.pageSummary,
                      style: const TextStyle(color: Color(0xFF7A8491), fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateLabel(document.updatedAt),
                      style: const TextStyle(color: Color(0xFFA0A8B3), fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_horiz_rounded, color: Color(0xFF7A8491)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final days = today.difference(dateOnly).inDays;
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(strokeWidth: 3),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
