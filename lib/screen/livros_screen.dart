import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:atividade_final/models/livro_model.dart';
import 'package:atividade_final/screen/busca_livros_screen.dart';
import 'package:atividade_final/screen/estatisticas_screen.dart';

class LivrosScreen extends StatefulWidget {
  const LivrosScreen({super.key});

  @override
  State<LivrosScreen> createState() => _LivrosScreenState();
}

class _LivrosScreenState extends State<LivrosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Atualizar a estante / status do livro no Firestore
  Future<void> _moverEstante(String livroId, String novoStatus) async {
    if (_user == null) return;
    try {
      await _db
          .collection("users")
          .doc(_user.uid)
          .collection("livros")
          .doc(livroId)
          .update({
        "status": novoStatus,
        "atualizadoEm": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Livro movido para '$novoStatus'!"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao mover livro: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Deletar livro da estante
  Future<void> _deletarLivro(String livroId, String titulo) async {
    if (_user == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Livro"),
        content: Text("Deseja realmente remover '$titulo' da sua estante?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remover", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _db
            .collection("users")
            .doc(_user.uid)
            .collection("livros")
            .doc(livroId)
            .delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Livro '$titulo' removido com sucesso."),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao deletar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Modal para alterar status
  void _mostrarOpcoesMover(Livro livro) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final opcoes = [
          {"status": "Quero Ler", "icon": Icons.bookmark_border, "color": Colors.blue},
          {"status": "Lendo", "icon": Icons.auto_stories, "color": Colors.orange},
          {"status": "Lidos", "icon": Icons.check_circle_outline, "color": Colors.green},
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Mover '${livro.titulo}' para:",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...opcoes.map((opcao) {
                final statusNome = opcao["status"] as String;
                final isAtual = livro.status == statusNome || (statusNome == "Lidos" && livro.status == "Lido");
                return ListTile(
                  leading: Icon(opcao["icon"] as IconData, color: opcao["color"] as Color),
                  title: Text(
                    statusNome,
                    style: TextStyle(
                      fontWeight: isAtual ? FontWeight.bold : FontWeight.normal,
                      color: isAtual ? (opcao["color"] as Color) : Colors.black87,
                    ),
                  ),
                  trailing: isAtual
                      ? const Chip(
                          label: Text("Atual", style: TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!isAtual) {
                      _moverEstante(livro.id, statusNome);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _corDaEstante(String status) {
    switch (status) {
      case "Quero Ler":
        return Colors.blue.shade700;
      case "Lendo":
        return Colors.orange.shade800;
      case "Lidos":
      case "Lido":
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildListaLivros({String? filtroStatus}) {
    if (_user == null) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    Query query = _db
        .collection("users")
        .doc(_user.uid)
        .collection("livros")
        .orderBy("criadoEm", descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.library_books_outlined, size: 70, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sua estante no Book Nook está vazia!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Toque no botão 'Buscar Livros' abaixo para adicionar leituras via Google Books.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Filtra em memória para permitir consistência mesmo se tiver "Lido" vs "Lidos"
        final todosDocs = snapshot.data!.docs;
        final docsFiltrados = todosDocs.where((d) {
          if (filtroStatus == null) return true;
          final s = (d.data() as Map<String, dynamic>)['status'] ?? '';
          if (filtroStatus == "Lidos") {
            return s == "Lidos" || s == "Lido";
          }
          return s == filtroStatus;
        }).toList();

        if (docsFiltrados.isEmpty) {
          return Center(
            child: Text(
              "Nenhum livro na estante '$filtroStatus'.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docsFiltrados.length,
          itemBuilder: (context, index) {
            final doc = docsFiltrados[index];
            final livro = Livro.fromFirestore(doc);
            final statusColor = _corDaEstante(livro.status);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Capa do livro
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: livro.capaUrl.isNotEmpty
                          ? Image.network(
                              livro.capaUrl,
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 90,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.book, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 90,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.book, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Informações do livro
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            livro.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            livro.autores,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                livro.paginas > 0 ? "📄 ${livro.paginas} págs" : "📄 Páginas desc.",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const Spacer(),
                              // Badge de status
                              InkWell(
                                onTap: () => _mostrarOpcoesMover(livro),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        livro.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu popup de ações
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (acao) {
                        if (acao == "mover") {
                          _mostrarOpcoesMover(livro);
                        } else if (acao == "deletar") {
                          _deletarLivro(livro.id, livro.titulo);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: "mover",
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 18),
                              SizedBox(width: 8),
                              Text("Mudar Estante"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "deletar",
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text("Remover", style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.book, size: 28),
              ),
              const SizedBox(width: 10),
              const Text(
                "Book Nook",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          actions: [
            // Botão para Tela de Estatísticas
            IconButton(
              tooltip: "Minhas Estatísticas",
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EstatisticasScreen()),
                );
              },
            ),
            // Botão de Logout
            IconButton(
              tooltip: "Sair",
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Desconectar"),
                    content: const Text("Deseja sair da sua conta no Book Nook?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Sair"),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await FirebaseAuth.instance.signOut();
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: false,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Todas"),
              Tab(text: "Quero Ler"),
              Tab(text: "Lendo"),
              Tab(text: "Lidos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListaLivros(),
            _buildListaLivros(filtroStatus: "Quero Ler"),
            _buildListaLivros(filtroStatus: "Lendo"),
            _buildListaLivros(filtroStatus: "Lidos"),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuscaLivrosScreen()),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text("Buscar Livros"),
        ),
      ),
    );
  }
}
