import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:atividade_final/models/livro_model.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  /// Busca livros na API do Google Books por título, autor ou termo geral.
  static Future<List<Livro>> buscarLivros(String query) async {
    final queryLimpa = query.trim();
    if (queryLimpa.isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(queryLimpa)}&maxResults=25&printType=books');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items == null || items.isEmpty) {
          return [];
        }

        return items
            .map((item) => Livro.fromGoogleBooks(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Falha ao buscar livros da Google Books API (Status: ${response.statusCode})');
      }
    } catch (e) {
      // Repassa ou formata o erro para a interface
      rethrow;
    }
  }
}

