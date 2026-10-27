import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Inicializa o SDK do Firebase Admin
admin.initializeApp();
const db = admin.firestore();

/**
 * Função utilitária para identificar se o status representa que o livro foi lido.
 * Aceita tanto "Lido" quanto "Lidos".
 */
function isStatusLido(status: unknown): boolean {
  if (typeof status !== "string") return false;
  const s = status.trim().toLowerCase();
  return s === "lido" || s === "lidos";
}

/**
 * CLOUD FUNCTION PRINCIPAL: atualizarEstatisticasLivro (onUpdate)
 * 
 * Acionada automaticamente sempre que o documento de um livro de um usuário
 * é atualizado em: users/{userId}/livros/{livroId}
 * 
 * Regra de negócio:
 * 1. Se o status foi alterado para "Lido":
 *    - Incrementa livrosLidos em +1
 *    - Incrementa paginasLidas com o número de páginas do livro
 * 2. Se o status saiu de "Lido" para outro (ex: "Quero Ler" ou "Lendo"):
 *    - Decrementa livrosLidos em -1
 *    - Decrementa paginasLidas com o número de páginas do livro
 * 3. Utiliza FieldValue.increment() para operações atômicas seguras no Firestore.
 */
export const atualizarEstatisticasLivro = onDocumentUpdated(
  "users/{userId}/livros/{livroId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Validação dos dados
    if (!beforeData || !afterData) {
      logger.warn("Documento antes ou depois não encontrado no evento.");
      return;
    }

    const { userId, livroId } = event.params;
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    logger.info(`Livro ${livroId} atualizado para o usuário ${userId}. Status anterior: '${beforeStatus}', Novo status: '${afterStatus}'`);

    // Se o status não foi alterado, encerra sem modificar estatísticas
    if (beforeStatus === afterStatus) {
      logger.info("O status do livro não foi modificado. Nenhuma alteração necessária nas estatísticas.");
      return;
    }

    const wasLido = isStatusLido(beforeStatus);
    const isNowLido = isStatusLido(afterStatus);

    // Se a mudança não envolveu o status "Lido" (ex: mudou de "Quero Ler" para "Lendo"), nada a alterar
    if (!wasLido && !isNowLido) {
      logger.info("A transição de status não envolveu a estante 'Lidos'.");
      return;
    }

    // Obtém o número de páginas de forma segura (tratando strings, números ou ausência)
    const rawPaginas = afterData.paginas ?? beforeData.paginas ?? 0;
    const paginas = Number(rawPaginas) > 0 ? Number(rawPaginas) : 0;

    let deltaLivros = 0;
    let deltaPaginas = 0;

    if (!wasLido && isNowLido) {
      // O livro foi marcado como "Lido" -> INCREMENTA
      deltaLivros = 1;
      deltaPaginas = paginas;
      logger.info(`Incrementando estatísticas: +1 livro, +${paginas} páginas.`);
    } else if (wasLido && !isNowLido) {
      // O livro foi desmarcado de "Lido" -> DECREMENTA
      deltaLivros = -1;
      deltaPaginas = -paginas;
      logger.info(`Decrementando estatísticas: -1 livro, -${paginas} páginas.`);
    }

    // Referência ao documento de estatísticas do usuário
    const statsDocRef = db.collection("users").doc(userId).collection("stats").doc("resumo");

    try {
      await statsDocRef.set(
        {
          livrosLidos: admin.firestore.FieldValue.increment(deltaLivros),
          paginasLidas: admin.firestore.FieldValue.increment(deltaPaginas),
          ultimaAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
          userId: userId,
        },
        { merge: true }
      );

      logger.info(`Estatísticas do usuário ${userId} atualizadas com sucesso!`);
    } catch (error) {
      logger.error(`Erro ao atualizar estatísticas do usuário ${userId}:`, error);
      throw error;
    }
  }
);

/**
 * CLOUD FUNCTION COMPLEMENTAR: onLivroCriado (onCreate)
 * 
 * Caso o usuário adicione o livro DIRETAMENTE na estante "Lidos",
 * essa função garante que as estatísticas também sejam devidamente incrementadas.
 */
export const onLivroCriado = onDocumentCreated(
  "users/{userId}/livros/{livroId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { userId, livroId } = event.params;
    const status = data.status;

    if (isStatusLido(status)) {
      const paginas = Number(data.paginas) > 0 ? Number(data.paginas) : 0;
      logger.info(`Livro ${livroId} criado diretamente com status 'Lido'. Incrementando +1 livro e +${paginas} páginas.`);

      const statsDocRef = db.collection("users").doc(userId).collection("stats").doc("resumo");

      try {
        await statsDocRef.set(
          {
            livrosLidos: admin.firestore.FieldValue.increment(1),
            paginasLidas: admin.firestore.FieldValue.increment(paginas),
            ultimaAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
            userId: userId,
          },
          { merge: true }
        );
      } catch (error) {
        logger.error(`Erro ao incrementar livro criado para o usuário ${userId}:`, error);
        throw error;
      }
    }
  }
);

