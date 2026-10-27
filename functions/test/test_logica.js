// Teste da lógica de negócio das estatísticas
const assert = require("assert");

function isStatusLido(status) {
  if (typeof status !== "string") return false;
  const s = status.trim().toLowerCase();
  return s === "lido" || s === "lidos";
}

function calcularDeltas(beforeStatus, afterStatus, paginas) {
  if (beforeStatus === afterStatus) {
    return { deltaLivros: 0, deltaPaginas: 0, alterou: false };
  }

  const wasLido = isStatusLido(beforeStatus);
  const isNowLido = isStatusLido(afterStatus);

  if (!wasLido && !isNowLido) {
    return { deltaLivros: 0, deltaPaginas: 0, alterou: false };
  }

  const qtdPaginas = Number(paginas) > 0 ? Number(paginas) : 0;

  if (!wasLido && isNowLido) {
    return { deltaLivros: 1, deltaPaginas: qtdPaginas, alterou: true };
  } else if (wasLido && !isNowLido) {
    return { deltaLivros: -1, deltaPaginas: -qtdPaginas, alterou: true };
  }

  return { deltaLivros: 0, deltaPaginas: 0, alterou: false };
}

// Teste 1: Transição de "Lendo" para "Lidos" com 320 páginas
const t1 = calcularDeltas("Lendo", "Lidos", 320);
assert.strictEqual(t1.deltaLivros, 1, "Deve incrementar 1 livro");
assert.strictEqual(t1.deltaPaginas, 320, "Deve incrementar 320 páginas");
assert.strictEqual(t1.alterou, true);
console.log("Teste 1 (Lendo -> Lidos): PASSOU");

// Teste 2: Transição de "Quero Ler" para "Lido" (singular) com 150 páginas
const t2 = calcularDeltas("Quero Ler", "Lido", 150);
assert.strictEqual(t2.deltaLivros, 1, "Deve incrementar 1 livro");
assert.strictEqual(t2.deltaPaginas, 150, "Deve incrementar 150 páginas");
assert.strictEqual(t2.alterou, true);
console.log("Teste 2 (Quero Ler -> Lido): PASSOU");

// Teste 3: Transição de "Lidos" de volta para "Lendo" (decremento seguro)
const t3 = calcularDeltas("Lidos", "Lendo", 200);
assert.strictEqual(t3.deltaLivros, -1, "Deve decrementar 1 livro");
assert.strictEqual(t3.deltaPaginas, -200, "Deve decrementar 200 páginas");
assert.strictEqual(t3.alterou, true);
console.log("Teste 3 (Lidos -> Lendo): PASSOU");

// Teste 4: Transição de "Quero Ler" para "Lendo" (não mexe em lidos)
const t4 = calcularDeltas("Quero Ler", "Lendo", 400);
assert.strictEqual(t4.alterou, false, "Não deve alterar estatísticas");
console.log("Teste 4 (Quero Ler -> Lendo): PASSOU");

// Teste 5: Edição de dados do livro sem alterar status ("Lidos" -> "Lidos")
const t5 = calcularDeltas("Lidos", "Lidos", 300);
assert.strictEqual(t5.alterou, false, "Mesmo status não deve recalcular");
console.log("Teste 5 (Lidos -> Lidos): PASSOU");

console.log("\nTODOS OS TESTES DA LÓGICA DE NEGÓCIO PASSARAM COM SUCESSO!");

