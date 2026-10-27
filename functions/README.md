# Cloud Functions - Clube do Livro "Leitores & Cia."

Backend automatizado com Cloud Functions (TypeScript / Node.js) e Firebase Admin SDK.

## 🎯 Objetivo e Foco da Avaliação
Atualizar automaticamente os contadores agregados de estatísticas de leitura do usuário sempre que o status de um livro for alterado para **"Lido"** (ou "Lidos").

---

## 🛠️ Funções Implementadas

### 1. `atualizarEstatisticasLivro` (Gatilho: `onUpdate` / `onDocumentUpdated`)
- **Document Path:** `users/{userId}/livros/{livroId}`
- **Lógica de Negócio:**
  - Compara `before.status` e `after.status`.
  - Se o livro transitou para `"Lido"`:
    - Incrementa `livrosLidos` em `+1`.
    - Incrementa `paginasLidas` com o número de páginas do livro lido (`+paginas`).
  - Se o livro saiu de `"Lido"` para outra estante ("Quero Ler" ou "Lendo"):
    - Decrementa `livrosLidos` em `-1`.
    - Decrementa `paginasLidas` com `-paginas`.
  - Se a alteração não envolveu o status "Lido" (ex: "Quero Ler" -> "Lendo"), nenhuma alteração é feita.
  - Se foram alterados outros campos mantendo o mesmo status, nenhuma alteração é feita.
  - Utiliza `admin.firestore.FieldValue.increment()` garantindo atomicidade e segurança contra condições de corrida (*race conditions*).
  - Atualiza o documento em `/users/{userId}/stats/resumo` com `merge: true`.

### 2. `onLivroCriado` (Gatilho: `onCreate` / `onDocumentCreated`)
- Garante consistência caso o membro do clube adicione um livro diretamente na estante de "Lidos".

---

## 🧪 Testes Automatizados da Lógica
Para rodar os testes unitários da regra de negócio:
```bash
npm test
```

## 🚀 Como Executar / Emular Localmente
Para iniciar as Cloud Functions no Firebase Emulator:
```bash
npm run build
firebase emulators:start --only functions
```

## ☁️ Deploy para o Firebase
```bash
npm run deploy
# ou a partir da raiz:
firebase deploy --only functions
```
*(Nota: O deploy na nuvem do Google Cloud requer o plano Blaze habilitado no console do projeto)*.

