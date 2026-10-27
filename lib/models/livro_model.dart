import 'package:cloud_firestore/cloud_firestore.dart';

class Livro {
  final String id;
  final String titulo;
  final String autores;
  final int paginas;
  final String capaUrl;
  final String descricao;
  final String status; // 'Quero Ler', 'Lendo', 'Lidos'
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  Livro({
    required this.id,
    required this.titulo,
    required this.autores,
    required this.paginas,
    required this.capaUrl,
    this.descricao = '',
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
  });

  // Cria um objeto a partir do Firestore
  factory Livro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Livro(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sem título',
      autores: data['autores'] ?? data['autor'] ?? 'Autor desconhecido',
      paginas: (data['paginas'] is num) ? (data['paginas'] as num).toInt() : 0,
      capaUrl: data['capaUrl'] ?? '',
      descricao: data['descricao'] ?? '',
      status: data['status'] ?? 'Quero Ler',
      criadoEm: parseDate(data['criadoEm']),
      atualizadoEm: parseDate(data['atualizadoEm']),
    );
  }

  // Cria um objeto a partir da Google Books API
  factory Livro.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    
    // Tratamento dos autores
    String autoresFormatados = 'Autor desconhecido';
    if (volumeInfo['authors'] is List && (volumeInfo['authors'] as List).isNotEmpty) {
      autoresFormatados = (volumeInfo['authors'] as List).join(', ');
    }

    // Tratamento da capa (garantir https)
    String capa = '';
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    if (imageLinks != null) {
      capa = imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'] ?? '';
      if (capa.startsWith('http://')) {
        capa = capa.replaceFirst('http://', 'https://');
      }
    }

    // Quantidade de páginas
    int pageCount = 0;
    if (volumeInfo['pageCount'] is num) {
      pageCount = (volumeInfo['pageCount'] as num).toInt();
    }

    return Livro(
      id: json['id'] ?? '',
      titulo: volumeInfo['title'] ?? 'Sem título',
      autores: autoresFormatados,
      paginas: pageCount,
      capaUrl: capa,
      descricao: volumeInfo['description'] ?? '',
      status: 'Quero Ler',
    );
  }

  // Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'titulo': titulo,
      'autores': autores,
      'paginas': paginas,
      'capaUrl': capaUrl,
      'descricao': descricao,
      'status': status,
      'criadoEm': criadoEm != null ? Timestamp.fromDate(criadoEm!) : FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }
}

