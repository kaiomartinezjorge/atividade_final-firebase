# Clube do Livro "Leitores & Cia." - Atividade Final

Aplicativo Flutter integrado ao Firebase com backend automatizado via **Cloud Functions** para o gerenciamento de estantes virtuais e painel de estatísticas em tempo real.

---

## 📌 Escopo e Funcionalidades Implementadas

### 1. 🔍 API: Integração com Google Books API
- Busca em tempo real de livros por **título** ou **autor**.
- Mapeamento de capas de alta resolução (`https`), autores formatados, número de páginas e descrições.
- Adição rápida com seleção da estante desejada.

### 2. 🔐 Autenticação de Membros
- Registro de novos leitores com validação de credenciais e senha segura.
- Login com Firebase Auth e persistência de sessão.
- Logout com confirmação.

### 3. 📚 Gerenciamento de Estantes
- Três estantes virtuais organizadas em abas:
  - **"Quero Ler"**
  - **"Lendo"**
  - **"Lidos"**
- Movimentação fácil de livros entre as estantes via menu contextual e chips interativos.
- Sincronização em tempo real via Firestore (`/users/{userId}/livros/{livroId}`).
- Exclusão com diálogo de confirmação.

### 4. ⚡ Backend com Cloud Functions (`onUpdate`)
- Cloud Function em **TypeScript** acionada sempre que o status de um livro é alterado para **"Lido"**.
- Incremento atômico seguro (`FieldValue.increment`) de:
  - `livrosLidos` (`+1`)
  - `paginasLidas` (`+paginas`)
- Decremento seguro caso o usuário desmarque um livro de lido para outra estante.
- Documento de estatísticas em `/users/{userId}/stats/resumo`.

### 5. 📊 Painel "Minhas Estatísticas"
- Leitura em tempo real (`StreamBuilder`) dos dados agregados no Firestore.
- Exibição de cards de métricas:
  - Total de Livros Lidos
  - Total de Páginas Lidas
  - Média de Páginas por Livro
  - Distribuição quantitativa de livros em cada uma das 3 estantes.

---

## 🏗️ Estrutura do Projeto

```
atividade_final/
├── firestore.rules               # Regras de segurança do Firestore
├── firebase.json                 # Configuração do Firebase e Emuladores
├── functions/                    # Backend Cloud Functions
│   ├── src/
│   │   └── index.ts              # Função onUpdate (atualizarEstatisticasLivro) e onCreate
│   ├── test/
│   │   └── test_logica.js        # Testes automatizados da regra de negócio
│   ├── package.json              # Dependências e scripts de build/deploy
│   └── tsconfig.json             # Configurações do TypeScript
└── lib/
    ├── firebase_options.dart     # Configurações do Firebase para o Flutter
    ├── main.dart                 # Inicialização com tema "Leitores & Cia."
    ├── models/
    │   └── livro_model.dart      # Modelo de dados (Google Books + Firestore)
    ├── services/
    │   └── google_books_service.dart # Integração HTTP com Google Books API
    └── screen/
        ├── auth_screen.dart          # Gerenciamento do estado de login
        ├── login_screen.dart         # Tela de login
        ├── registro_screen.dart      # Tela de cadastro de membro
        ├── livros_screen.dart        # Gerenciamento de estantes em abas
        ├── busca_livros_screen.dart  # Busca na Google Books API
        └── estatisticas_screen.dart  # Painel de estatísticas agregadas
```

---

## 🚀 Como Executar

### App Flutter
```bash
flutter pub get
flutter run
```

### Cloud Functions (Testes e Emulador)
```bash
cd functions
npm test        # Executa testes unitários da regra de negócio
npm run build   # Compila TypeScript para lib/index.js
```
