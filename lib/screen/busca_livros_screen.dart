import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:atividade_final/models/livro_model.dart';
import 'package:atividade_final/services/google_books_service.dart';

class BuscaLivrosScreen extends StatefulWidget {
  const BuscaLivrosScreen({super.key});

  @override
  State<BuscaLivrosScreen> createState() => _BuscaLivrosScreenState();
}

class _BuscaLivrosScreenState extends State<BuscaLivrosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  List<Livro> _livros = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  Future<void> _realizarBusca() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final resultados = await GoogleBooksService.buscarLivros(query);
      setState(() {
        _livros = resultados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao buscar livros: $e";
        _isLoading = false;
      });
    }
  }

  void _abrirModalAdicionarLivro(Livro livro) {
    String estanteSelecionada = "Quero Ler";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Adicionar à sua Estante",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: livro.capaUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              livro.capaUrl,
                              width: 45,
                              height: 65,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 40),
                            ),
                          )
                        : const Icon(Icons.book, size: 40),
                    title: Text(
                      livro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${livro.autores} • ${livro.paginas} págs"),
                  ),
                  const Divider(height: 24),
                  const Text(
                    "Escolha a Estante:",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: estanteSelecionada,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Quero Ler",
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Quero Ler"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Lendo",
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories, color: Colors.orange),
                            SizedBox(width: 8),
                            Text("Lendo"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Lidos",
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Lidos"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (novo) {
                      if (novo != null) {
                        setModalState(() {
                          estanteSelecionada = novo;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Confirmar e Salvar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _salvarLivroNoFirestore(livro, estanteSelecionada);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _salvarLivroNoFirestore(Livro livro, String estante) async {
    if (_user == null) return;

    try {
      final docData = livro.toFirestoreMap();
      docData['status'] = estante;

      await _db
          .collection("users")
          .doc(_user.uid)
          .collection("livros")
          .add(docData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("O livro '${livro.titulo}' foi adicionado em '$estante'!"),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar livro: $e"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar Livros (Google Books)"),
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Digite título ou autor...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _realizarBusca(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _realizarBusca,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Buscar"),
                ),
              ],
            ),
          ),

          // Área de Resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : !_hasSearched
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 85,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.menu_book, size: 70, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    "Pesquise livros para adicionar ao Book Nook",
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _livros.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nenhum livro encontrado para esta busca.",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _livros.length,
                                itemBuilder: (context, index) {
                                  final livro = _livros[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(10),
                                      leading: livro.capaUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.network(
                                                livro.capaUrl,
                                                width: 50,
                                                height: 75,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 50,
                                                  height: 75,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.book, color: Colors.grey),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 50,
                                              height: 75,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.book, color: Colors.grey),
                                            ),
                                      title: Text(
                                        livro.titulo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            livro.autores,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey.shade700),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            livro.paginas > 0
                                                ? "📄 ${livro.paginas} páginas"
                                                : "📄 Páginas não informadas",
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      trailing: ElevatedButton.icon(
                                        onPressed: () => _abrirModalAdicionarLivro(livro),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("Adicionar"),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
