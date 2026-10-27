import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EstatisticasScreen extends StatelessWidget {
  const EstatisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = FirebaseFirestore.instance;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Minhas Estatísticas")),
        body: const Center(child: Text("Usuário não autenticado.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Estatísticas"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho de Boas-Vindas ao Clube
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 75,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.auto_stories,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Book Nook",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Clube Leitores & Cia.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? "Membro do Clube",
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Sincronização Cloud Function",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Métricas Principais",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // StreamBuilder lendo o documento de estatísticas atualizado pela Cloud Function
            StreamBuilder<DocumentSnapshot>(
              stream: db.collection("users").doc(user.uid).collection("stats").doc("resumo").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                int livrosLidos = 0;
                int paginasLidas = 0;
                bool docExiste = false;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  livrosLidos = (data['livrosLidos'] is num) ? (data['livrosLidos'] as num).toInt() : 0;
                  paginasLidas = (data['paginasLidas'] is num) ? (data['paginasLidas'] as num).toInt() : 0;
                  docExiste = true;
                }

                // Se o documento no Firestore ainda não existe (ex: antes do primeiro gatilho de backend),
                // realiza agregação segura a partir da lista de livros do usuário
                if (!docExiste) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: db.collection("users").doc(user.uid).collection("livros").snapshots(),
                    builder: (context, livrosSnap) {
                      int fallbackLivros = 0;
                      int fallbackPaginas = 0;
                      if (livrosSnap.hasData) {
                        for (var doc in livrosSnap.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final st = (data['status'] ?? '').toString().toLowerCase();
                          if (st == 'lido' || st == 'lidos') {
                            fallbackLivros++;
                            final p = data['paginas'];
                            if (p is num) fallbackPaginas += p.toInt();
                          }
                        }
                      }
                      return _buildMetricasView(context, fallbackLivros, fallbackPaginas, sincronizado: false);
                    },
                  );
                }

                return _buildMetricasView(context, livrosLidos, paginasLidas, sincronizado: true);
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "Distribuição pelas Estantes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // StreamBuilder para contar livros em cada estante em tempo real
            StreamBuilder<QuerySnapshot>(
              stream: db.collection("users").doc(user.uid).collection("livros").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final docs = snapshot.data!.docs;
                int queroLerCount = 0;
                int lendoCount = 0;
                int lidosCount = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  if (status == 'Quero Ler') queroLerCount++;
                  if (status == 'Lendo') lendoCount++;
                  if (status == 'Lidos' || status == 'Lido') lidosCount++;
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEstanteItem(
                          icon: Icons.bookmark_border,
                          color: Colors.blue,
                          label: "Quero Ler",
                          count: queroLerCount,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        _buildEstanteItem(
                          icon: Icons.auto_stories,
                          color: Colors.orange,
                          label: "Lendo",
                          count: lendoCount,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        _buildEstanteItem(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          label: "Lidos",
                          count: lidosCount,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasView(BuildContext context, int livrosLidos, int paginasLidas, {required bool sincronizado}) {
    final mediaPaginas = livrosLidos > 0 ? (paginasLidas / livrosLidos).toStringAsFixed(1) : "0";

    return Column(
      children: [
        Row(
          children: [
            // Card de Livros Lidos
            Expanded(
              child: _buildMetricCard(
                context: context,
                icon: Icons.menu_book,
                iconColor: Colors.deepPurple,
                title: "Livros Lidos",
                value: "$livrosLidos",
                subtitle: sincronizado ? "Via Cloud Function" : "Calculado",
              ),
            ),
            const SizedBox(width: 12),
            // Card de Páginas Lidas
            Expanded(
              child: _buildMetricCard(
                context: context,
                icon: Icons.description,
                iconColor: Colors.teal,
                title: "Páginas Lidas",
                value: "$paginasLidas",
                subtitle: sincronizado ? "Via Cloud Function" : "Calculado",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card de Média
        _buildMetricCard(
          context: context,
          icon: Icons.calculate,
          iconColor: Colors.amber.shade800,
          title: "Média por Livro",
          value: "$mediaPaginas págs",
          subtitle: "Média de extensão das leituras concluídas",
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstanteItem({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          "$count",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
