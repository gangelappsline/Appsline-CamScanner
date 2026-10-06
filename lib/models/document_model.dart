enum ScanFilter {
  original,
  automatic,
  grayscale,
  blackAndWhite,
}

extension ScanFilterLabel on ScanFilter {
  String get label {
    switch (this) {
      case ScanFilter.original:
        return 'Original';
      case ScanFilter.automatic:
        return 'Automático';
      case ScanFilter.grayscale:
        return 'Grises';
      case ScanFilter.blackAndWhite:
        return 'B&N';
    }
  }
}

class ScannedPage {
  ScannedPage({
    required this.id,
    required this.path,
    this.filter = ScanFilter.original,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String path;
  ScanFilter filter;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'filter': filter.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScannedPage.fromJson(Map<String, dynamic> json) {
    final filterName = json['filter'] as String?;
    final filter = ScanFilter.values.firstWhere(
      (item) => item.name == filterName,
      orElse: () => ScanFilter.original,
    );

    return ScannedPage(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      path: json['path'] as String? ?? '',
      filter: filter,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class ScanDocument {
  ScanDocument({
    required this.id,
    required this.title,
    required this.pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  final List<ScannedPage> pages;
  final DateTime createdAt;
  DateTime updatedAt;

  String get pageSummary {
    if (pages.length == 1) return '1 página';
    return '${pages.length} páginas';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pages': pages.map((page) => page.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ScanDocument.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List<dynamic>? ?? <dynamic>[];
    return ScanDocument(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Documento sin título',
      pages: rawPages
          .whereType<Map<String, dynamic>>()
          .map(ScannedPage.fromJson)
          .where((page) => page.path.isNotEmpty)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
