# Nebo Symbol and Operator Registry

**Documento ID:** `NEBO-SYMBOL-AND-OPERATOR-REGISTRY`  
**Versão:** `1.0`  
**Data:** `2026-08-09`  
**Projeto:** Nebo Native Assembly Compiler  
**Tipo:** registo normativo de símbolos, operadores, fixity, precedência, aliases e fronteiras de domínio  
**Estado:** `CANONICAL_DESIGN_REGISTRY_NOT_IMPLEMENTED_IN_FULL`  
**Implementação de produto autorizada por este documento:** `NO`  
**Criação automática de roadmap ou frente:** `NO`  
**Nova sintaxe ativada por este documento:** `NO`  
**API `.print()` introduzida:** `NO`  
**Saída canónica preservada:** `console()`  

**Path recomendado:**

```text
docs/specifications/nebo-language/
NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.md
```

**Companion machine-readable registry:**

```text
NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0.tsv
```

---

# 1. Finalidade

Este documento cria a autoridade única para responder, antes de qualquer implementação:

```text
qual símbolo existe;
em que contexto existe;
se é núcleo, alias, domain-gated, reservado ou rejeitado;
qual é a sua fixity;
qual é a sua aridade;
qual é a sua precedência;
qual é a sua associatividade;
que tipos admite;
que tipo produz;
em que ordem avalia;
se faz short-circuit;
como falha;
como baixa para HIR/LIR/runtime;
como o formatter e o LSP o tratam;
que substratos RF27/RF46/RF52/RF84 exige;
se já está materialmente ativo ou é apenas uma decisão futura.
```

O registo impede que a presença de um símbolo num documento histórico seja confundida com implementação, e impede que diferentes grupos atribuam significados concorrentes ao mesmo lexema.

---

# 2. Fontes e fronteira de autoridade

## 2.1. Pesquisa histórica

```text
SOURCE=
RELATORIO-PESQUISA-PROFUNDA-SIMBOLOGIA-OPERADORES-E-PRECEDENCIA-NEBO-C.md

SOURCE_SHA256=
2ab3ea68036042e1b106f89681855d812896c52e443b3a24bc0762b07f23b04b

ROLE=
HISTORICAL_EXTRACTION_AND_CONFLICT_INVENTORY

AUTHORITY_OVER_CURRENT_ASSEMBLY=
NO
```

O relatório histórico percorreu 3 040 ficheiros Markdown, separou núcleo flow-first, formas parse-only, perfil C-compatible e mini-linguagens de Text. Ele recomenda exatamente um registo com lexeme, token kind, contexto, fixity, precedência, tipos, avaliação, lowering, diagnostics, estado e proveniência.

## 2.2. Auditoria do compilador Assembly

```text
SOURCE=
AUDITORIA-PROFUNDA-NEBO-ASSEMBLY-ESTADO-DE-IMPLEMENTACAO-2026-08-09.md

SOURCE_SHA256=
fc1f74d81baebd60b54a0748b330bcda00ce497b270e66b7777daa35db47879c

ROLE=
CURRENT_IMPLEMENTATION_BASELINE_WITH_SNAPSHOT_LIMIT

CURRENT_LIVE_HEAD_FULL_SOURCE_AVAILABLE=
NO
```

A auditoria confirmou como ativos no snapshot/evidence:

```text
+ - * / %
< <= > >=
== !=
&& || !
.
= += -=
Result propagation ?
match arm ->
```

Também confirmou:

```text
Int / Int = signed integer division, truncate toward zero;
bitwise público = métodos bitAnd/bitOr/bitXor/bitNot/shiftLeft/shiftRight;
ternário = inativo;
bitwise infix = inativo;
range literal 1..10 = inativo;
Range API = ativa;
general bracket indexing = inativo; usar at/get;
<. e <.> = inativos;
interpolação = inativa.
```

Estas claims são baseline auditada, não substituem replay no HEAD vivo.

## 2.3. Regra de precedência

```text
1. decisão humana atual;
2. este Registry depois de integrado e hash-validado;
3. Git/código/testes do HEAD vivo;
4. decisões RF27/RF46/RF52/RF84 mais específicas que não contradigam este Registry;
5. relatório histórico apenas como proveniência.
```

Nenhum roadmap pode ativar um símbolo classificado `RESERVED` ou `REJECTED` sem uma nova versão explícita deste Registry.

---

# 3. Classes normativas

| Classe | Significado |
|---|---|
| `CORE_ALWAYS_ON` | Forma canónica universal. Quando implementada, não depende de import, feature flag, target visual ou módulo científico; a aplicabilidade ainda é validada pelos tipos. |
| `UNICODE_ALIAS` | Alias exato de uma forma canónica já existente. Possui o mesmo TokenKind semântico, precedência, tipos, avaliação, failure policy e lowering. Não cria uma segunda engine. |
| `DOMAIN_GATED` | Só é aceite num módulo, tipo, grammar context ou capability explícita. O lexer pode reconhecer o code point, mas parser/typechecker devem provar o domínio. |
| `RESERVED` | Code point/lexema protegido para decisão futura. Não possui semântica executável e deve produzir diagnóstico estável. |
| `REJECTED` | Forma deliberadamente não canónica. Deve continuar rejeitada, normalmente com alternativa ou quick fix. |

As classes são primárias e mutuamente exclusivas por **lexema + contexto + fixity**. O mesmo code point pode aparecer em contextos diferentes, como:

```text
% infix   = remainder, CORE_ALWAYS_ON
% postfix = Percent, CORE_ALWAYS_ON
%s        = format placeholder, DOMAIN_GATED

! prefix  = logical NOT, CORE_ALWAYS_ON
! postfix = factorial, DOMAIN_GATED
```

---

# 4. Estados de implementação

```text
ACTIVE_CURRENT
PARTIAL_ACTIVE_CURRENT
METHOD_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE
NATIVE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE
RANGE_API_ACTIVE_SYMBOL_INACTIVE
INACTIVE_CURRENT
UNSUPPORTED_CURRENT
HISTORICAL_ONLY
```

Um estado atual nunca altera a classe normativa. Por exemplo:

```text
^ = CORE_ALWAYS_ON + INACTIVE_CURRENT
```

significa que a decisão é canónica, mas ainda não foi implementada.

---

# 5. Invariantes globais

```text
EVALUATION_DEFAULT=LEFT_TO_RIGHT_EXACTLY_ONCE
SHORT_CIRCUIT_ONLY_WHEN_REGISTRY_SAYS_YES
ASSIGNMENT_TARGET_EVALUATION=EXACTLY_ONCE
ASSIGNMENT_RHS_EVALUATION=EXACTLY_ONCE_OR_LAZY_WHEN_EXPLICIT
STORE_POLICY=ONE_STORE_ON_SUCCESS_ZERO_ON_FAILURE
OVERFLOW_DEFAULT=CHECKED
HIDDEN_NUMERIC_COERCION=FORBIDDEN
HIDDEN_TEXT_COERCION=FORBIDDEN
HIDDEN_TOLERANCE=FORBIDDEN
HIDDEN_PARALLELISM=FORBIDDEN
HIDDEN_RANDOMNESS=FORBIDDEN
HIDDEN_IO=FORBIDDEN
USER_DEFINED_NEW_LEXEMES=FORBIDDEN
USER_TYPES_IMPLEMENT_KNOWN_PROTOCOLS=ALLOWED
NFKC_OPERATOR_NORMALIZATION=FORBIDDEN
UNREGISTERED_UNICODE_CONFUSABLES=REJECTED
FORMATTER_SEMANTIC_REWRITE=FORBIDDEN_BY_DEFAULT
```

## 5.1. Short-circuit autorizado

```text
&&
||
?
??
?.
??=
```

`xor`, `⊻`, `⊼` e `⊽` não fazem short-circuit.

## 5.2. Checked arithmetic

Por defeito:

```text
Int addition/subtraction/multiplication/power/factorial/sum/product
=> checked

division by zero
=> checked failure

INT_MIN / -1
=> checked failure
```

Alternativas são métodos explícitos:

```nebo
value.wrappingAdd(other)
value.saturatingAdd(other)
value.checkedAdd(other)
```

---

# 6. Tabela-alvo de precedência

Os números são internos ao parser; a relação é normativa.

| Nível | Família | Formas |
|---:|---|---|
| 180 | suffix/call/member | `.`, `()`, `?.`, future bracket suffix |
| 170 | postfix values | Result `?`, postfix `%`, `°`, factorial `!`, `ᵀ`, `†`, `⁻¹` |
| 160 | power | `^`, right-associative |
| 150 | prefix | unary `+`, unary `-`, logical `!`, `√`, `∛`, `∜`, `∇`, `Δ` |
| 145 | composition | `∘`, right-associative |
| 140 | multiplicative/domain product | `*`, `/`, infix `%`, `·`, `×`, `⊙`, `⊗`, `∩` |
| 130 | additive/domain sum | `+`, `-`, `±`, `⧺`, `∪`, `∖`, `△`, `⊕` |
| 125 | range | `…`, `…<`, `<…`, `<…<` |
| 120 | relational/membership | `<`, `<=`, `>`, `>=`, `<=>`, `∈`, `∉`, `⊂`, `⊆`, `⊃`, `⊇`, `∣`, `∤` |
| 110 | equality/pattern relation | `==`, `!=`, `≈`, `≉`, `≡`, `=~`, `!~` |
| 100 | XOR | `xor`, `⊻` |
| 90 | AND | `&&`, `∧`, formal `⊼` |
| 80 | OR | `||`, `∨`, formal `⊽` |
| 70 | implication | `⇒` |
| 60 | equivalence | `⇔` |
| 50 | Option coalescing | `??` |
| 20 | assignment statements | `=`, `+=`, `-=`, `*=`, `/=`, `%=`, `^=`, `??=` |

As formas binder:

```text
∑ ∏ ∫ ∬ ∭ ∮ ∂ ∀ ∃ ∄
```

usam gramática própria e não participam como prefixos comuns.

O lateral flow `..` também usa uma forma gramatical própria:

```nebo
value .. {
    // shared observation
}
```

---

# 7. Maximal munch obrigatório

O lexer deve testar primeiro as formas maiores relevantes:

```text
<…<
<.>
??=
<=>
...
…<
<…
?.
??
<=
>=
==
!=
&&
||
->
::
=~
!~
∇·
∇×
⁻¹
°C
°F
```

Reconhecer um token não concede semântica quando a classe é `RESERVED` ou o domínio não está ativo.

---

# 8. `CORE_ALWAYS_ON`

Contagem: **47**

| ID | Símbolo/forma | Nome | Contexto/fixity | Precedência | Regra de tipos e resultado | Avaliação/falha | Estado atual → alvo | Dependências | Descrição |
|---|---|---|---|---|---|---|---|---|---|
| `NSR-CORE-001` | `.` | flow/member/call/binding dot | expression, receiver-first call and terminal binding; postfix/contextual | `P180_SUFFIX` / left/contextual | receiver or value followed by a valid member, call, pipeline stage or binding terminal → member/call result, transformed receiver, or a new binding | receiver exactly once; stages left-to-right; short-circuit=NO; type/resolution error before codegen; no hidden fallback | ACTIVE_CURRENT → CANONICAL | RF27-G02/G03/G06; RF52-G47/G48 | The visual and semantic center of Nebo: member access, fluent call, pipeline continuation and value-first binding are decided by parser context. |
| `NSR-CORE-002` | `()` | grouping and call delimiters | expressions and argument lists; delimited/postfix | `P180_SUFFIX` / left | groupable expression or callable plus typed arguments → grouped value or callable result | callee once, arguments left-to-right exactly once; short-circuit=NO; arity/type/effect diagnostics; no call on failure | ACTIVE_CURRENT → CANONICAL | RF27-G03; RF52-G47/G48 | Groups expressions and invokes callables. Nested calls reuse the general expression grammar. |
| `NSR-CORE-003` | `{}` | block delimiters | function, control-flow, match, struct and domain bodies; delimited | `STRUCTURAL` / N/A | context-specific statements or fields → block value only where a construct defines one | source order; short-circuit=NO; unclosed or invalid-context diagnostic | ACTIVE_CURRENT → CANONICAL | RF27-G02/G03/G05/G06 | Delimits lexical blocks and structured bodies; the lexer does not assign a single semantic meaning. |
| `NSR-CORE-004` | `[]` | array/list/type delimiters | Array literals, bounded collection forms and type syntax; delimited | `P180_SUFFIX_WHEN_INDEXING_EXISTS` / left/contextual | context-specific elements or type arguments → Array/collection/type value; general indexing is separately RESERVED | elements left-to-right exactly once; short-circuit=NO; bounds and shape diagnostics; no partial aggregate | PARTIAL_ACTIVE_CURRENT → CANONICAL_DELIMITERS | RF27-G06/G07; RF52-G47/G48 | The delimiters are core. General `expr[index]` semantics are not implied by their presence. |
| `NSR-CORE-005` | `<...>` | generic type argument delimiters | type context only; delimited/contextual | `TYPE_GRAMMAR` / N/A | generic type constructor plus valid type arguments → instantiated type | compile-time only; short-circuit=NO; generic arity/constraint diagnostic | ACTIVE_CURRENT → CANONICAL | RF27-G06; RF52-G47/G48 | Angle brackets in type context are distinct from relational operators in expression context. |
| `NSR-CORE-006` | `,` | separator | arguments, elements, fields, bindings and tuples; separator | `STRUCTURAL` / N/A | context-specific list members → no value of its own | source order; short-circuit=NO; missing-element or trailing-comma policy diagnostic | ACTIVE_CURRENT → CANONICAL_SEPARATOR | RF27-G03/G06; RF52-G48 | Comma is a separator, never a free expression operator. |
| `NSR-CORE-007` | `;` | statement terminator | statement and selected arm termination; terminator | `STRUCTURAL` / N/A | completed statement → no value | N/A; short-circuit=NO; missing/extra terminator diagnostic | ACTIVE_CURRENT → CANONICAL | RF27-G02/G03/G05 | Terminates statements. It is not an operator and cannot be overloaded. |
| `NSR-CORE-008` | `:` | typed/named separator | type annotations, named arguments, fields and schemas; separator/contextual | `STRUCTURAL` / N/A | name/type or name/value according to context → annotation or association | compile-time only; short-circuit=NO; context-specific diagnostic; `=` is not a named-argument separator | ACTIVE_CURRENT → CANONICAL | RF27-G03/G06/G10; RF52-G47/G48 | Separates names from types or values. It is not the C ternary separator in the canonical language. |
| `NSR-CORE-009` | `->` | return-type and match-arm arrow | function signatures and match arms; separator/contextual | `STRUCTURAL` / right/contextual | signature type relation or pattern/body relation → type declaration or selected arm result | compile-time dispatch; selected arm once; short-circuit=MATCH_ONLY; invalid-context diagnostic; member-arrow meaning is rejected | ACTIVE_CURRENT → CANONICAL_CONTEXTUAL | RF27-G03/G05; RF52-G47/G48 | The current Assembly language uses `->` for bounded match arms and return-type context; it is not pointer member access. |
| `NSR-CORE-010` | `_` | wildcard and ignored binding | patterns and explicitly ignored names; atomic/contextual | `STRUCTURAL` / N/A | pattern or binding context → no bound value unless a future pattern says otherwise | compile-time only; short-circuit=NO; invalid-position diagnostic | ACTIVE_CURRENT → CANONICAL_CONTEXTUAL | RF27-G05; RF52-G48 | Matches or ignores without introducing a normal binding. |
| `NSR-CORE-011` | `//` | line comment introducer | lexer outside Text/Char/raw literals; lexical | `LEXICAL` / N/A | any source bytes until newline or EOF → no token stream output | lexical skip; short-circuit=NO; none unless encoding/source controls are invalid | ACTIVE_CURRENT → CANONICAL | RF27 frontend; RF52-G47 | Begins a line comment. It also permanently prevents `//` from becoming integer division. |
| `NSR-CORE-012` | `+` | addition | numeric expression; infix | `P130_ADDITIVE` / left | same-type numeric operands or an explicitly registered Add protocol with no implicit unsafe coercion → numeric or protocol-declared result | left then right exactly once; short-circuit=NO; checked overflow by default; invalid type rejected | ACTIVE_CURRENT_INT_FLOAT_BOUNDED → CANONICAL | RF27 core/G14; RF52-G47/G49 | Adds numeric values. Text concatenation is not implicit and belongs to the domain-gated `⧺` operator. |
| `NSR-CORE-013` | `-` | subtraction | numeric expression; infix | `P130_ADDITIVE` / left | same-type numeric operands or Subtract protocol → numeric or protocol-declared result | left then right exactly once; short-circuit=NO; checked overflow by default | ACTIVE_CURRENT_INT_FLOAT_BOUNDED → CANONICAL | RF27 core/G14; RF52-G47/G49 | Subtracts the right operand from the left. |
| `NSR-CORE-014` | `*` | multiplication | numeric expression; infix | `P140_MULTIPLICATIVE` / left | same-type numeric operands or Multiply protocol → numeric or protocol-declared result | left then right exactly once; short-circuit=NO; checked overflow by default | ACTIVE_CURRENT_INT_FLOAT_BOUNDED → CANONICAL | RF27 core/G14; RF52-G47/G49 | Scalar multiplication. Vector cross, Cartesian product and tensor products use distinct domain symbols. |
| `NSR-CORE-015` | `/` | division | numeric expression; infix | `P140_MULTIPLICATIVE` / left | compatible numeric operands; no implicit Int/Float coercion unless a future numeric policy explicitly allows it → Int for Int/Int; Float for supported Float profiles | left then right exactly once; short-circuit=NO; division-by-zero and signed overflow checked; Int division truncates toward zero | ACTIVE_CURRENT_INT_FLOAT_BOUNDED → CANONICAL_INT_TRUNCATE_TOWARD_ZERO | RF27 core/G14; RF52-G47/G49 | Preserves the Assembly compiler decision: signed integer division truncates toward zero. |
| `NSR-CORE-016` | `%` | remainder | between expressions; infix | `P140_MULTIPLICATIVE` / left | Int operands in the current profile; future types require a Remainder protocol → Int or protocol-declared result | left then right exactly once; short-circuit=NO; zero divisor checked; result obeys the signed division identity | ACTIVE_CURRENT_INT → CANONICAL_INFIX | RF27 core; RF52-G47 | In infix position `%` means remainder. Template placeholders and postfix percentage are separate contexts. |
| `NSR-CORE-017` | `^` | power | numeric or algebraic expression; infix | `P160_POWER` / right | Power protocol; initial core profiles Int^nonnegative-Int and Float-compatible powers → type-specific numeric/algebraic result | base then exponent exactly once; short-circuit=NO; checked overflow/domain policy; negative Int exponent requires explicit promotion | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G14/G15/G16; RF46-G35/G36; RF52-G47/G48 | Canonical exponentiation. It is intentionally not XOR. |
| `NSR-CORE-018` | `+` | unary plus | prefix numeric expression; prefix | `P150_PREFIX` / right | numeric operand → same type | operand exactly once; short-circuit=NO; invalid type rejected | INACTIVE_OR_PROFILE_LIMITED → APPROVED_CANONICAL | RF27 core; RF52-G47 | Explicit numeric identity, primarily useful for generated and mathematical source. |
| `NSR-CORE-019` | `-` | unary negation | prefix numeric expression; prefix | `P150_PREFIX` / right | signed numeric operand or Negate protocol → same or declared result type | operand exactly once; short-circuit=NO; checked overflow for minimum signed integer | ACTIVE_CURRENT_INT → CANONICAL | RF27 core/G14; RF52-G47 | Negates a value. Power binds more tightly: `-2 ^ 2` means `-(2 ^ 2)`. |
| `NSR-CORE-020` | `!` | logical NOT | prefix Boolean expression; prefix | `P150_PREFIX` / right | Bool only → Bool | operand exactly once; short-circuit=NO; non-Bool rejected; no truthiness | ACTIVE_CURRENT → CANONICAL_PREFIX | RF27 core; RF52-G47 | Boolean negation. Postfix factorial is a separate domain-gated context. |
| `NSR-CORE-021` | `&&` | logical AND | Boolean expression; infix | `P090_AND` / left | Bool and Bool → Bool | left once; right only when left is true; short-circuit=YES_RIGHT_LAZY; non-Bool rejected; no truthiness | ACTIVE_CURRENT → CANONICAL | RF27 core; RF52-G47 | Short-circuit conjunction. |
| `NSR-CORE-022` | `\|\|` | logical OR | Boolean expression; infix | `P080_OR` / left | Bool and Bool → Bool | left once; right only when left is false; short-circuit=YES_RIGHT_LAZY; non-Bool rejected; no truthiness | ACTIVE_CURRENT → CANONICAL | RF27 core; RF52-G47 | Short-circuit disjunction. |
| `NSR-CORE-023` | `xor` | typed XOR | Boolean, Int or Bytes expression; infix keyword | `P100_XOR` / left | Bool/Bool, Int/Int or equal-length Bytes/Bytes → Bool, Int or Bytes matching the operand domain | left then right exactly once; short-circuit=NO; type/length mismatch rejected; no padding or truncation | METHOD_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_CANONICAL_ASCII | RF27-G01/G08; RF52-G47/G48 | Canonical XOR spelling. Existing `bitXor()` remains an exact method form. |
| `NSR-CORE-024` | `<` | less than | ordered expression; infix | `P120_RELATIONAL` / non-associative | same compatible Comparable domain → Bool | left then right exactly once; short-circuit=NO; unsupported comparison rejected | ACTIVE_CURRENT_INT → CANONICAL | RF27 core/G06; RF52-G47 | Strict ordering. Chained comparisons are rejected; use explicit conjunction. |
| `NSR-CORE-025` | `<=` | less than or equal | ordered expression; infix | `P120_RELATIONAL` / non-associative | same compatible Comparable domain → Bool | left then right exactly once; short-circuit=NO; unsupported comparison rejected | ACTIVE_CURRENT_INT → CANONICAL | RF27 core/G06; RF52-G47 | Inclusive upper-order comparison. |
| `NSR-CORE-026` | `>` | greater than | ordered expression; infix | `P120_RELATIONAL` / non-associative | same compatible Comparable domain → Bool | left then right exactly once; short-circuit=NO; unsupported comparison rejected | ACTIVE_CURRENT_INT → CANONICAL | RF27 core/G06; RF52-G47 | Strict reverse ordering. |
| `NSR-CORE-027` | `>=` | greater than or equal | ordered expression; infix | `P120_RELATIONAL` / non-associative | same compatible Comparable domain → Bool | left then right exactly once; short-circuit=NO; unsupported comparison rejected | ACTIVE_CURRENT_INT → CANONICAL | RF27 core/G06; RF52-G47 | Inclusive lower-order comparison. |
| `NSR-CORE-028` | `==` | equality | equality expression; infix | `P110_EQUALITY` / non-associative | same Eq domain; no implicit cross-type coercion → Bool | left then right exactly once; short-circuit=NO; unsupported equality rejected | ACTIVE_CURRENT_INT_BOOL_TEXT_BOUNDED → CANONICAL | RF27 core/G06; RF52-G47 | Typed equality. Current-head Char uniformity must be replayed before extending claims. |
| `NSR-CORE-029` | `!=` | inequality | equality expression; infix | `P110_EQUALITY` / non-associative | same Eq domain → Bool | left then right exactly once; short-circuit=NO; unsupported equality rejected | ACTIVE_CURRENT_INT_BOOL_TEXT_BOUNDED → CANONICAL | RF27 core/G06; RF52-G47 | Logical negation of typed equality without re-evaluating operands. |
| `NSR-CORE-030` | `<=>` | three-way comparison | ordered expression; infix | `P120_RELATIONAL` / non-associative | same Comparable domain → Ordering { LESS, EQUAL, GREATER } | left then right exactly once; short-circuit=NO; unsupported domain rejected | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G06; RF52-G47/G48 | Returns a typed Ordering rather than an Int sentinel. |
| `NSR-CORE-031` | `=` | assignment statement | statement to an existing mutable lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue and type-compatible RHS → no value | target once, RHS once, one store on success; short-circuit=NO; zero store on rejection/failure | ACTIVE_CURRENT → CANONICAL_STATEMENT | RF27-G02/G04; RF52-G47 | Assignment never creates a new binding and is not equality. |
| `NSR-CORE-032` | `+=` | checked add assignment | statement to an existing mutable numeric lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Add and compatible RHS → no value | target once, old value once, RHS once, one store on success; short-circuit=NO; checked overflow; zero store on failure | ACTIVE_CURRENT_INT → CANONICAL | RF27-G02/G04; RF52-G47 | Compound assignment with exactly-once lvalue and RHS evaluation. |
| `NSR-CORE-033` | `-=` | checked subtract assignment | statement to an existing mutable numeric lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Subtract → no value | target once, old value once, RHS once, one store on success; short-circuit=NO; checked overflow; zero store on failure | ACTIVE_CURRENT_INT → CANONICAL | RF27-G02/G04; RF52-G47 | Checked subtraction assignment. |
| `NSR-CORE-034` | `*=` | checked multiply assignment | statement to an existing mutable numeric lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Multiply → no value | target once, old value once, RHS once, one store on success; short-circuit=NO; checked overflow; zero store on failure | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G02/G04; RF52-G47 | Future checked multiplication assignment. |
| `NSR-CORE-035` | `/=` | checked divide assignment | statement to an existing mutable numeric lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Divide → no value | target once, old value once, RHS once, one store on success; short-circuit=NO; zero divisor/overflow checked; zero store on failure | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G02/G04; RF52-G47 | Future checked division assignment. |
| `NSR-CORE-036` | `%=` | checked remainder assignment | statement to an existing mutable Int-like lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Remainder → no value | target once, old value once, RHS once, one store on success; short-circuit=NO; zero divisor checked; zero store on failure | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G02/G04; RF52-G47 | Future checked remainder assignment. |
| `NSR-CORE-037` | `^=` | checked power assignment | statement to an existing mutable power-capable lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable lvalue supporting Power → no value | target once, old value once, exponent once, one store on success; short-circuit=NO; overflow/domain checked; zero store on failure | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G02/G14; RF52-G47 | Power assignment; XOR assignment uses no `^=` interpretation. |
| `NSR-CORE-038` | `?` | Result propagation | postfix on Result in a compatible Result-returning context; postfix | `P170_POSTFIX` / left | Result<T,E> with an enclosing compatible Result<_,E> → T on Ok; early return of the exact E on Err | operand once; cleanup exactly once before early return; short-circuit=YES_ERR_EARLY_RETURN; type/context mismatch diagnostic; no artifact on rejection | ACTIVE_CURRENT_BOUNDED → CANONICAL_CONTEXTUAL | RF27-G04/G05; RF52-G47 | Propagates typed Result errors. It is not a ternary marker. |
| `NSR-CORE-039` | `??` | Option coalescing | infix on Option; infix | `P050_COALESCE` / right | Option<T> on the left and a T-compatible fallback on the right → T | left once; fallback only for None; short-circuit=YES_RIGHT_LAZY; type mismatch rejected | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G05; RF52-G47/G48 | Returns the contained value or lazily evaluates the fallback. |
| `NSR-CORE-040` | `?.` | Option-safe member/call chain | suffix on Option; postfix/contextual | `P180_SUFFIX` / left | Option<T> followed by a valid T member or call → Option<U> | receiver once; member/call only for Some; short-circuit=YES_CHAIN_LAZY; invalid member/type diagnostic | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G03/G05; RF52-G47/G48 | Safe Option chaining; it does not catch arbitrary errors. |
| `NSR-CORE-041` | `??=` | assign when None | statement to mutable Option lvalue; statement operator | `P020_ASSIGNMENT` / right/statement | mutable Option<T> lvalue and T-compatible RHS → no value | target once; RHS only when None; one store on success; short-circuit=YES_RIGHT_LAZY; zero store on failure | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G02/G05; RF52-G47/G48 | Conditionally initializes a mutable Option without duplicating target evaluation. |
| `NSR-CORE-042` | `%` | typed percentage | immediately after a numeric expression without an intervening operator; postfix | `P170_POSTFIX` / left | exact numeric literal/value accepted by Percent constructor → Percent exact ratio scaled by 1/100 | operand once; short-circuit=NO; range policy is type-defined; never silently becomes raw Float | INACTIVE_CURRENT → APPROVED_CANONICAL_POSTFIX | RF46-G35; RF52-G47/G48 | Postfix `%` constructs a typed Percent. Infix `%` remains remainder. |
| `NSR-CORE-043` | `…` | inclusive range | between ordered endpoints; infix | `P125_RANGE` / non-associative | compatible ordered step-capable endpoints → Range<T> inclusive at both ends | start then end exactly once; short-circuit=NO; invalid direction/step handled by Range policy | RANGE_API_ACTIVE_SYMBOL_INACTIVE → APPROVED_CANONICAL | RF27-G06; RF52-G47/G48 | Uses the single ellipsis U+2026 so ASCII `..` remains available for lateral flow. |
| `NSR-CORE-044` | `…<` | range excluding end | between ordered endpoints; infix | `P125_RANGE` / non-associative | compatible ordered step-capable endpoints → Range<T> including start and excluding end | start then end exactly once; short-circuit=NO; Range policy | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G06; RF52-G47/G48 | Half-open range `[start,end)`. |
| `NSR-CORE-045` | `<…` | range excluding start | between ordered endpoints; infix | `P125_RANGE` / non-associative | compatible ordered step-capable endpoints → Range<T> excluding start and including end | start then end exactly once; short-circuit=NO; Range policy | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G06; RF52-G47/G48 | Half-open range `(start,end]`. |
| `NSR-CORE-046` | `<…<` | exclusive range | between ordered endpoints; infix | `P125_RANGE` / non-associative | compatible ordered step-capable endpoints → Range<T> excluding both ends | start then end exactly once; short-circuit=NO; Range policy | INACTIVE_CURRENT → APPROVED_CANONICAL | RF27-G06; RF52-G47/G48 | Open range `(start,end)`. |
| `NSR-CORE-047` | `..` | lateral flow/tap | expression followed by a lateral block; special flow form | `SPECIAL_LATERAL_FLOW` / non-associative | any receiver; first profile lends a shared read-only view to the block → the original receiver | receiver once; block once; block result discarded; short-circuit=NO; move/escape/mutation conflicts rejected; no hidden parallelism | INACTIVE_CURRENT → APPROVED_CANONICAL_BOUNDED | RF27-G03/G04; RF52-G47/G48 | Observes or derives from a value without replacing the main pipeline receiver. |

---

# 9. `UNICODE_ALIAS`

Contagem: **9**

| ID | Símbolo/forma | Nome | Contexto/fixity | Precedência | Regra de tipos e resultado | Avaliação/falha | Estado atual → alvo | Dependências | Descrição |
|---|---|---|---|---|---|---|---|---|---|
| `NSR-UA-001` | `−` | Unicode minus | prefix or infix numeric expression; alias | `SAME_AS_ASCII` / same as `-` | same as ASCII `-` → same as ASCII `-` | identical lowering; short-circuit=NO; identical failure policy | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | U+2212 is an exact source alias for ASCII hyphen-minus in operator context. |
| `NSR-UA-002` | `÷` | Unicode division | infix numeric expression; alias | `SAME_AS_ASCII` / left | same as `/` → same as `/` | identical lowering; short-circuit=NO; identical failure policy | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | U+00F7 aliases `/`; U+2215 and other slash confusables do not. |
| `NSR-UA-003` | `≤` | Unicode less-or-equal | relational expression; alias | `SAME_AS_ASCII` / non-associative | same as `<=` → Bool | identical lowering; short-circuit=NO; identical diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact alias for `<=`. |
| `NSR-UA-004` | `≥` | Unicode greater-or-equal | relational expression; alias | `SAME_AS_ASCII` / non-associative | same as `>=` → Bool | identical lowering; short-circuit=NO; identical diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact alias for `>=`. |
| `NSR-UA-005` | `≠` | Unicode not-equal | equality expression; alias | `SAME_AS_ASCII` / non-associative | same as `!=` → Bool | identical lowering; short-circuit=NO; identical diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact alias for `!=`; it is not symbolic inequivalence beyond typed inequality. |
| `NSR-UA-006` | `∧` | Unicode logical AND | Boolean expression; alias | `SAME_AS_ASCII` / left | Bool and Bool → Bool | same short-circuit as `&&`; short-circuit=YES_RIGHT_LAZY; same diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact short-circuit alias for `&&`. |
| `NSR-UA-007` | `∨` | Unicode logical OR | Boolean expression; alias | `SAME_AS_ASCII` / left | Bool and Bool → Bool | same short-circuit as `\|\|`; short-circuit=YES_RIGHT_LAZY; same diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact short-circuit alias for `\|\|`. |
| `NSR-UA-008` | `¬` | Unicode logical NOT | prefix Boolean expression; alias | `SAME_AS_ASCII` / right | Bool → Bool | identical lowering; short-circuit=NO; same diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF52-G47/G48/G51 | Exact alias for prefix logical `!`. |
| `NSR-UA-009` | `⊻` | Unicode XOR | Bool, Int or Bytes expression; alias | `SAME_AS_ASCII` / left | same as `xor` → same as `xor` | identical lowering; short-circuit=NO; same diagnostics | INACTIVE_CURRENT → APPROVED_EXACT_ALIAS | RF27-G01; RF52-G47/G48/G51 | Exact alias for the canonical ASCII keyword `xor`. |

## 9.1. Regra de alias

Um alias Unicode:

```text
não cria novo AST kind semântico;
não muda precedência;
não muda associatividade;
não muda overload resolution;
não muda diagnostics de tipo;
não muda HIR/LIR;
não muda bytes do resultado, exceto source-map;
```

O formatter pode oferecer:

```bash
neboc format --symbols=preserve
neboc format --symbols=ascii
neboc format --symbols=math
```

`preserve` é o default. Conversão só é permitida quando o alias é semanticamente exato.

---

# 10. `DOMAIN_GATED`

Contagem: **80**

| ID | Símbolo/forma | Nome | Contexto/fixity | Precedência | Regra de tipos e resultado | Avaliação/falha | Estado atual → alvo | Dependências | Descrição |
|---|---|---|---|---|---|---|---|---|---|
| `NSR-DOM-001` | `√` | square root | numeric/math profile; prefix | `P150_PREFIX` / right | Sqrt protocol or supported numeric/symbolic type → type-specific root or Result | operand once; short-circuit=NO; domain/precision policy is explicit | RUNTIME_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14; RF46-G35/G36; RF52-G47/G48 | Square-root operator; negative real input never silently becomes an untyped NaN. |
| `NSR-DOM-002` | `∛` | cube root | numeric/math profile; prefix | `P150_PREFIX` / right | CubeRoot protocol → type-specific root or Result | operand once; short-circuit=NO; domain and precision explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14; RF46-G35/G36; RF52-G47/G48 | Cube root with exact/approximate behavior determined by the numeric type. |
| `NSR-DOM-003` | `∜` | fourth root | numeric/math profile; prefix | `P150_PREFIX` / right | FourthRoot protocol → type-specific root or Result | operand once; short-circuit=NO; domain and precision explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35/G36; RF52-G47/G48 | Fourth root. |
| `NSR-DOM-004` | `!` | factorial | postfix in combinatorics profile; postfix | `P170_POSTFIX` / left | nonnegative integral domain or Factorial protocol → checked Int/BigInt/domain result | operand once; short-circuit=NO; negative input and overflow rejected or returned as typed failure | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_POSTFIX | RF46-G35; RF52-G47/G48 | Postfix factorial; prefix `!` remains core logical NOT. |
| `NSR-DOM-005` | `∞` | typed infinity literal | extended numeric, interval and calculus profiles; literal | `LITERAL` / N/A | context must admit infinity → Float infinity, unbounded interval endpoint or symbolic infinity | compile-time literal; short-circuit=NO; Int context rejected | INACTIVE_CURRENT → APPROVED_CONTEXTUAL_LITERAL | RF46-G35/G36; RF52-G47/G51 | Infinity is contextual and never a universal untyped value. |
| `NSR-DOM-006` | `π` | pi constant | math/angle profile; literal constant | `LITERAL` / N/A | context supporting the selected precision → typed constant | compile-time or canonical constant load; short-circuit=NO; precision profile explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_CONSTANT | RF27-G14; RF46-G35; RF52-G47 | Unicode constant alias with an ASCII `PI` name in the math module. |
| `NSR-DOM-007` | `τ` | tau constant | math/angle profile; literal constant | `LITERAL` / N/A | context supporting the selected precision → typed constant | compile-time or canonical constant load; short-circuit=NO; precision profile explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_CONSTANT | RF27-G14; RF46-G35; RF52-G47 | Circle constant equal to two pi in the selected precision domain. |
| `NSR-DOM-008` | `∑` | summation binder | finite collection/range reduction; binder | `BINDER` / N/A | finite iterable plus a summable mapped expression → type-specific sum or reduction report | domain once; iteration order explicit and deterministic by default; short-circuit=NO; overflow, cancellation and floating reduction policy explicit | NATIVE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED_BINDER | RF27-G07/G10/G14/G16; RF52-G47/G49 | Summation with a dedicated binder grammar; it never hides nondeterministic parallel reduction. |
| `NSR-DOM-009` | `∏` | product binder | finite collection/range reduction; binder | `BINDER` / N/A | finite iterable plus multiplicative expression → type-specific product or reduction report | domain once; explicit deterministic order; short-circuit=NO; checked overflow and empty-domain identity policy | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF27-G07/G14; RF52-G47/G49 | Product reduction. |
| `NSR-DOM-010` | `±` | value with symmetric uncertainty | measurement/interval profile; infix | `P130_ADDITIVE` / left | compatible scalar value and nonnegative uncertainty → Uncertain<T> or Measurement<T> | left then right once; short-circuit=NO; invalid uncertainty rejected; propagation policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35/G36; RF52-G47/G48 | Constructs a typed uncertain value, not an implicit tuple of two branches. |
| `NSR-DOM-011` | `≈` | approximate equality | numeric/measurement profile; infix with required tolerance contract | `P110_EQUALITY` / non-associative | comparable approximate domain plus explicit tolerance or an uncertainty-bearing type → Bool | operands once; tolerance once; short-circuit=NO; hidden global epsilon forbidden | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35/G36; RF52-G47/G48 | Approximate equality is valid only with explicit tolerance or intrinsic uncertainty. |
| `NSR-DOM-012` | `≉` | not approximately equal | numeric/measurement profile; infix with required tolerance contract | `P110_EQUALITY` / non-associative | same as `≈` → Bool | operands once; tolerance once; short-circuit=NO; hidden epsilon forbidden | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35/G36; RF52-G47/G48 | Typed negation of approximate equality. |
| `NSR-DOM-013` | `≡` | symbolic or structural equivalence | symbolic/formal profile; infix | `P110_EQUALITY` / non-associative | symbolic expressions or explicitly registered equivalence domain → Bool or ProofObligation | operands once; short-circuit=NO; must not collapse to ordinary `==` | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G35; RF52-G47 | Represents semantic/symbolic equivalence, distinct from runtime typed equality. |
| `NSR-DOM-014` | `∣` | divides | integer/number-theory profile; infix | `P120_RELATIONAL` / non-associative | integral operands → Bool | left then right once; short-circuit=NO; zero divisor convention explicitly defined | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35; RF52-G47 | Tests divisibility. |
| `NSR-DOM-015` | `∤` | does not divide | integer/number-theory profile; infix | `P120_RELATIONAL` / non-associative | integral operands → Bool | left then right once; short-circuit=NO; same policy as `∣` | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G35; RF52-G47 | Negates divisibility. |
| `NSR-DOM-016` | `⌊x⌋` | floor delimiters | numeric profile; delimited prefix/postfix pair | `DELIMITER_OPERATOR` / N/A | ordered fractional numeric value → integral or domain-declared result | operand once; short-circuit=NO; overflow/conversion policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14; RF52-G47/G48 | Mathematical floor delimiters. |
| `NSR-DOM-017` | `⌈x⌉` | ceiling delimiters | numeric profile; delimited prefix/postfix pair | `DELIMITER_OPERATOR` / N/A | ordered fractional numeric value → integral or domain-declared result | operand once; short-circuit=NO; overflow/conversion policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14; RF52-G47/G48 | Mathematical ceiling delimiters. |
| `NSR-DOM-018` | `∝` | proportional to | symbolic/measurement profile; infix | `P120_RELATIONAL` / non-associative | symbolic expressions, quantities or datasets with a declared proportionality model → Bool, relation or constraint | operands once; short-circuit=NO; model/units must be explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G35; RF52-G47 | Creates or tests a typed proportionality relation. |
| `NSR-DOM-019` | `°` | degree suffix | angle/units profile; postfix | `P170_POSTFIX` / left | numeric value → Angle | operand once; short-circuit=NO; range normalization is type-defined | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_POSTFIX | RF46-G35/G41/G42; RF52-G47/G48 | Constructs a typed angle, never a plain number. |
| `NSR-DOM-020` | `‰` | per-mille suffix | ratio/units profile; postfix | `P170_POSTFIX` / left | exact numeric value → PerMille exact ratio scaled by 1/1000 | operand once; short-circuit=NO; no implicit Float conversion | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_POSTFIX | RF46-G35; RF52-G47/G48 | Typed per-mille ratio. |
| `NSR-DOM-021` | `‱` | basis-point suffix | finance/ratio profile; postfix | `P170_POSTFIX` / left | exact numeric value → BasisPoints exact ratio scaled by 1/10000 | operand once; short-circuit=NO; no implicit Float conversion | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_POSTFIX | RF46-G35; RF52-G47/G48 | Typed basis-point ratio. |
| `NSR-DOM-022` | `°C` | Celsius suffix | temperature/units profile; postfix unit suffix | `P170_POSTFIX` / left | numeric value → Temperature | operand once; short-circuit=NO; affine-unit arithmetic rules enforced | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_SUFFIX | RF46-G35/G41; RF52-G47/G48 | Constructs an affine Celsius temperature. |
| `NSR-DOM-023` | `°F` | Fahrenheit suffix | temperature/units profile; postfix unit suffix | `P170_POSTFIX` / left | numeric value → Temperature | operand once; short-circuit=NO; affine-unit arithmetic rules enforced | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_SUFFIX | RF46-G35/G41; RF52-G47/G48 | Constructs an affine Fahrenheit temperature. |
| `NSR-DOM-024` | `∈` | membership | set/collection profile; infix | `P120_RELATIONAL` / non-associative | value and compatible Set/collection → Bool | container and value once; short-circuit=NO; type mismatch rejected | COLLECTION_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Tests whether a value belongs to a set or explicitly opted-in collection. |
| `NSR-DOM-025` | `∉` | non-membership | set/collection profile; infix | `P120_RELATIONAL` / non-associative | value and compatible Set/collection → Bool | container and value once; short-circuit=NO; same as membership | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Negates membership. |
| `NSR-DOM-026` | `∪` | set union | set profile; infix | `P130_ADDITIVE` / left | compatible Set operands → Set | left then right once; short-circuit=NO; allocation/budget failure explicit | SET_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Returns the union without mutating either operand. |
| `NSR-DOM-027` | `∩` | set intersection | set profile; infix | `P140_MULTIPLICATIVE` / left | compatible Set operands → Set | left then right once; short-circuit=NO; allocation/budget failure explicit | SET_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Returns the intersection. |
| `NSR-DOM-028` | `∖` | set difference | set profile; infix | `P130_ADDITIVE` / left | compatible Set operands → Set | left then right once; short-circuit=NO; allocation/budget failure explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Elements of the left set that are not in the right. |
| `NSR-DOM-029` | `△` | symmetric difference | set profile; infix | `P130_ADDITIVE` / left | compatible Set operands → Set | left then right once; short-circuit=NO; allocation/budget failure explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Elements present in exactly one operand. |
| `NSR-DOM-030` | `⊆` | subset or equal | set profile; infix | `P120_RELATIONAL` / non-associative | compatible Set operands → Bool | left then right once; short-circuit=NO; type mismatch rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Inclusive subset relation. |
| `NSR-DOM-031` | `⊂` | proper subset | set profile; infix | `P120_RELATIONAL` / non-associative | compatible Set operands → Bool | left then right once; short-circuit=NO; type mismatch rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Strict subset relation. |
| `NSR-DOM-032` | `⊇` | superset or equal | set profile; infix | `P120_RELATIONAL` / non-associative | compatible Set operands → Bool | left then right once; short-circuit=NO; type mismatch rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Inclusive superset relation. |
| `NSR-DOM-033` | `⊃` | proper superset | set profile; infix | `P120_RELATIONAL` / non-associative | compatible Set operands → Bool | left then right once; short-circuit=NO; type mismatch rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Strict superset relation. |
| `NSR-DOM-034` | `×` | Cartesian product | set profile; infix | `P140_MULTIPLICATIVE` / left | finite compatible Sets/collections → Set<Tuple<A,B>> or bounded product view | left then right once; pair order deterministic; short-circuit=NO; cardinality/budget checked | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Cartesian product. In vector context the same code point means cross product via type-directed domain resolution. |
| `NSR-DOM-035` | `∅` | empty set literal | set profile; literal | `LITERAL` / N/A | context supplies the element type or an explicit type is required → Set<T> | compile-time literal; short-circuit=NO; ambiguous element type rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_LITERAL | RF27-G08/G09; RF46-G30/G34; RF52-G47/G48 | Typed empty set. |
| `NSR-DOM-036` | `·` | dot/inner scalar product | vector/matrix profile; infix | `P140_MULTIPLICATIVE` / left | compatible vectors or algebraic structures with DotProduct → scalar or declared result | left then right once; short-circuit=NO; shape/type mismatch explicit | NATIVE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Dot product or type-declared inner scalar product. |
| `NSR-DOM-037` | `×` | vector cross product | Vector3/geometry profile; infix | `P140_MULTIPLICATIVE` / left | compatible three-dimensional vectors → Vector3 | left then right once; short-circuit=NO; dimension mismatch rejected | NATIVE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Cross product selected by the vector domain, not scalar multiplication. |
| `NSR-DOM-038` | `⊙` | Hadamard product | matrix/tensor profile; infix | `P140_MULTIPLICATIVE` / left | equal-shape matrices/tensors → same-shape value | left then right once; short-circuit=NO; shape mismatch explicit | NATIVE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Elementwise product. |
| `NSR-DOM-039` | `⊗` | tensor/Kronecker product | matrix/tensor profile; infix | `P140_MULTIPLICATIVE` / left | compatible vectors/matrices/tensors → higher-rank or Kronecker result | left then right once; short-circuit=NO; shape/size budget explicit | NATIVE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Tensor or Kronecker product according to operand types. |
| `NSR-DOM-040` | `⊕` | direct sum | algebra/matrix profile; infix | `P130_ADDITIVE` / left | compatible algebraic structures → direct-sum structure | left then right once; short-circuit=NO; shape/budget explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Direct sum. |
| `NSR-DOM-041` | `ᵀ` | transpose | matrix/tensor profile; postfix | `P170_POSTFIX` / left | matrix or transpose-capable tensor/view → transposed view/value | operand once; short-circuit=NO; view ownership and shape explicit | NATIVE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED_POSTFIX | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Postfix transpose. |
| `NSR-DOM-042` | `†` | adjoint | complex linear-algebra profile; postfix | `P170_POSTFIX` / left | complex matrix/operator → adjoint value/view | operand once; short-circuit=NO; unsupported scalar domain rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_POSTFIX | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Conjugate transpose/adjoint. |
| `NSR-DOM-043` | `⁻¹` | inverse | algebra/matrix profile; postfix | `P170_POSTFIX` / left | invertible algebraic value → Result<T, SingularError> or exact inverse type | operand once; short-circuit=NO; singularity/conditioning explicit | NATIVE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED_POSTFIX | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Postfix inverse; never silently produces invalid numeric data. |
| `NSR-DOM-044` | `‖x‖` | norm delimiters | vector/matrix profile; delimited | `DELIMITER_OPERATOR` / N/A | norm-capable value → nonnegative scalar | operand once; short-circuit=NO; norm kind/default must be declared by type/profile | NATIVE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Mathematical norm delimiters. |
| `NSR-DOM-045` | `⟨u,v⟩` | inner product delimiters | inner-product-space profile; delimited | `DELIMITER_OPERATOR` / N/A | compatible values in a declared inner-product space → scalar | u then v once; short-circuit=NO; domain/shape mismatch explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Inner-product notation. |
| `NSR-DOM-046` | `∘` | function/operator composition | callable/algebra profile; infix | `P145_COMPOSITION` / right | output of right callable compatible with input of left callable → composed callable | construction operands once; invocation follows callable order; short-circuit=NO; signature/effect incompatibility rejected | CALLABLE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G03; RF52-G47/G48 | Creates `f ∘ g`, which invokes g before f. |
| `NSR-DOM-047` | `⟂` | orthogonality | linear/geometry profile; infix | `P120_RELATIONAL` / non-associative | vectors/subspaces with explicit tolerance or exact domain → Bool | left then right once; short-circuit=NO; hidden tolerance forbidden | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14/G15/G16/G17; RF46-G36; RF52-G47/G49 | Tests orthogonality. |
| `NSR-DOM-048` | `∥` | parallel relation | geometry profile; infix | `P120_RELATIONAL` / non-associative | vectors/lines with explicit tolerance or exact domain → Bool | left then right once; short-circuit=NO; hidden tolerance forbidden | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G42; RF52-G47/G48 | Tests geometric parallelism. |
| `NSR-DOM-049` | `∫` | integral binder | calculus profile; binder | `BINDER` / N/A | integrable callable/expression, explicit variable/domain, method and tolerance → IntegralResult<T> | domain and integrand follow the integration plan; short-circuit=NO; convergence/error/status explicit | NATIVE_INTEGRATION_SUBSTRATE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED_BINDER | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Single integral. A naked Float result without convergence/error metadata is not the canonical contract. |
| `NSR-DOM-050` | `∬` | double integral binder | multidimensional calculus profile; binder | `BINDER` / N/A | two-dimensional domain and integrand plan → IntegralResult<T> | explicit plan; short-circuit=NO; convergence/error explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Double integral. |
| `NSR-DOM-051` | `∭` | triple integral binder | multidimensional calculus profile; binder | `BINDER` / N/A | three-dimensional domain and integrand plan → IntegralResult<T> | explicit plan; short-circuit=NO; convergence/error explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Triple integral. |
| `NSR-DOM-052` | `∮` | contour integral binder | complex/vector calculus profile; binder | `BINDER` / N/A | oriented contour plus integrand → IntegralResult<T> | explicit contour order; short-circuit=NO; orientation/convergence explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Contour integral. |
| `NSR-DOM-053` | `∂` | partial derivative | calculus/autodiff/symbolic profile; prefix/binder | `BINDER` / N/A | differentiable expression/function and selected variable → derivative expression/value/report | arguments once; short-circuit=NO; unsupported differentiability explicit | AUTODIFF_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Partial derivative. |
| `NSR-DOM-054` | `∇` | gradient | vector calculus/autodiff profile; prefix | `P150_PREFIX` / right | scalar field over a declared coordinate space → vector field | operand once; short-circuit=NO; dimension/domain explicit | AUTODIFF_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Gradient. |
| `NSR-DOM-055` | `∇·` | divergence | vector calculus profile; prefix compound | `P150_PREFIX` / right | vector field → scalar field | operand once; short-circuit=NO; dimension/domain explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Divergence; maximal-munch compound token in calculus context. |
| `NSR-DOM-056` | `∇×` | curl | vector calculus profile; prefix compound | `P150_PREFIX` / right | three-dimensional vector field or declared curl domain → vector/scalar domain result | operand once; short-circuit=NO; dimension/domain explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Curl/rotational. |
| `NSR-DOM-057` | `Δ` | Laplacian | calculus/PDE profile; prefix | `P150_PREFIX` / right | twice-differentiable scalar/vector field → field result | operand once; short-circuit=NO; boundary/discretization or symbolic policy explicit | PDE_SUBSTRATE_PARTIAL_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14/G16/G21; RF46-G35/G36; RF52-G47/G49 | Laplacian. |
| `NSR-DOM-058` | `∼` | distributed as | probability model profile; infix declaration/relation | `SPECIAL_PROBABILITY` / non-associative | random variable/model symbol and Distribution → typed probabilistic relation/binding | left then distribution once; short-circuit=NO; shape/support mismatch explicit | DISTRIBUTION_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G14; RF46-G37; RF52-G47/G48/G49 | Declares or states a distributional relation. |
| `NSR-DOM-059` | `⫫` | probabilistic independence | probability model profile; infix | `P120_RELATIONAL` / non-associative | random variables or variable sets → Bool, constraint or model relation | left then right once; short-circuit=NO; model context required | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G14; RF46-G37; RF52-G47/G48/G49 | Independence relation. |
| `NSR-DOM-060` | `\|` | conditional probability separator | inside `P(...)` probability grammar only; contextual separator | `PROBABILITY_GRAMMAR` / N/A | event/expression pair inside a probability construct → conditional event/probability expression | context-defined; short-circuit=NO; outside the probability grammar it is not activated | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_CONTEXTUAL | RF27-G14; RF46-G37; RF52-G47/G48/G49 | Separates event and condition only inside a dedicated probability grammar. |
| `NSR-DOM-061` | `∀` | universal quantifier | contract/solver/formal profile; binder | `BINDER` / N/A | finite or proof-bounded domain plus predicate → Bool, Constraint or ProofObligation | domain once; predicate under solver rules; short-circuit=NO; budgets and undecided status explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF46-G29/G30; RF52-G47/G48 | Universal quantification. |
| `NSR-DOM-062` | `∃` | existential quantifier | contract/solver/formal profile; binder | `BINDER` / N/A | finite or proof-bounded domain plus predicate → Bool, Constraint or ProofResult | domain once; search bounded; short-circuit=NO; SAT/UNSAT/UNKNOWN/TIMEOUT explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF46-G29/G30; RF52-G47/G48 | Existential quantification. |
| `NSR-DOM-063` | `∄` | non-existence quantifier | contract/solver/formal profile; binder | `BINDER` / N/A | finite or proof-bounded domain plus predicate → Bool, Constraint or ProofResult | domain once; search bounded; short-circuit=NO; UNKNOWN/TIMEOUT distinct from proof | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_BINDER | RF46-G29/G30; RF52-G47/G48 | States that no witness exists. |
| `NSR-DOM-064` | `⇒` | logical implication | formal logic/contract profile; infix | `P070_IMPLICATION` / right | Bool/Constraint operands → Bool or Constraint | left once; right may be solver-lazy, never ordinary hidden effects; short-circuit=CONTEXTUAL; solver status explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | Implication, separate from graph arrows and match arrows. |
| `NSR-DOM-065` | `⇔` | logical equivalence | formal logic/contract profile; infix | `P060_EQUIVALENCE` / non-associative | Bool/Constraint operands → Bool or Constraint | operands once; short-circuit=NO; solver status explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | If-and-only-if relation. |
| `NSR-DOM-066` | `⊢` | provability relation | proof profile; infix/sequent | `PROOF_GRAMMAR` / N/A | proof context and proposition → ProofResult | proof engine rules; short-circuit=NO; UNKNOWN is not PASS | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | Syntactic derivability/provability. |
| `NSR-DOM-067` | `⊨` | semantic satisfaction | model-checking profile; infix | `PROOF_GRAMMAR` / N/A | model and property → ModelCheckResult | bounded model evaluation; short-circuit=NO; counterexample/unknown/timeout explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | Semantic satisfaction. |
| `NSR-DOM-068` | `⊼` | NAND | formal Boolean profile; infix | `P090_AND` / left | Bool operands → Bool | both operands exactly once; short-circuit=NO; non-Bool rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | Boolean NAND; unlike `&&`, it does not short-circuit. |
| `NSR-DOM-069` | `⊽` | NOR | formal Boolean profile; infix | `P080_OR` / left | Bool operands → Bool | both operands exactly once; short-circuit=NO; non-Bool rejected | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF46-G29/G30; RF52-G47/G48 | Boolean NOR; unlike `\|\|`, it does not short-circuit. |
| `NSR-DOM-070` | `→` | directed relation/edge | graph profile only; infix declaration | `GRAPH_GRAMMAR` / non-associative | compatible nodes/states → Edge/Transition | left then right once; short-circuit=NO; duplicate/cycle policy graph-specific | GRAPH_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → APPROVED_DOMAIN_GATED | RF27-G09; RF46-G34/G45; RF52-G47/G48 | Directed graph edge. It is not the ASCII `->` match/signature separator. |
| `NSR-DOM-071` | `↔` | bidirectional relation/edge | graph profile only; infix declaration | `GRAPH_GRAMMAR` / non-associative | compatible nodes → edge pair or bidirectional edge | left then right once; short-circuit=NO; graph policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G09; RF46-G34/G45; RF52-G47/G48 | Bidirectional graph relation. |
| `NSR-DOM-072` | `⇢` | asynchronous/dataflow edge | workflow/dataflow profile; infix declaration | `GRAPH_GRAMMAR` / non-associative | compatible stages/endpoints → typed asynchronous edge | construction only; runtime effects declared separately; short-circuit=NO; backpressure/capability policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G09; RF46-G34/G45; RF52-G47/G48 | Asynchronous or dataflow connection. |
| `NSR-DOM-073` | `⟶` | state transition | statechart/workflow profile; infix declaration | `GRAPH_GRAMMAR` / non-associative | states and optional transition metadata → Transition | construction once; short-circuit=NO; guards/effects explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF27-G09; RF46-G34/G45; RF52-G47/G48 | State transition notation. |
| `NSR-DOM-074` | `⧺` | Text concatenation | Text profile; infix | `P130_ADDITIVE` / left | Text and Text → Text | left then right once; short-circuit=NO; allocation/length/Unicode metadata policy explicit | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Unambiguous Text concatenation without numeric coercion. |
| `NSR-DOM-075` | `=~` | pattern/regex match | bounded regex profile; infix | `P110_EQUALITY` / non-associative | Text and compiled/bounded Pattern → Bool or MatchResult depending on explicit form | text then pattern once; short-circuit=NO; step/depth/memory budgets; catastrophic pattern fails closed | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Bounded pattern match. |
| `NSR-DOM-076` | `!~` | pattern/regex non-match | bounded regex profile; infix | `P110_EQUALITY` / non-associative | Text and Pattern → Bool | text then pattern once; short-circuit=NO; same budgets as `=~` | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Negated bounded pattern match. |
| `NSR-DOM-077` | `${...}` | Text interpolation | inside interpolated Text literals only; embedded expression | `TEXT_TEMPLATE_GRAMMAR` / N/A | pure expression accepted by the interpolation profile → Text segment/FormatPlan value | left-to-right exactly once; short-circuit=NO; compile-time type/format diagnostics | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED_AFTER_FORMATPLAN | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Syntax B from RF84; lowers to the same FormatPlan as `.format(...)`. |
| `NSR-DOM-078` | `%s/%d/%f/%b/%%` | typed format placeholders | inside validated format Text only; template token | `TEXT_TEMPLATE_GRAMMAR` / N/A | placeholder/argument types and counts must match → FormatPlan/Text | arguments left-to-right exactly once; short-circuit=NO; compile-time for literal templates; Result for dynamic templates | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Percent tokens inside a format template are not arithmetic `%` operators. |
| `NSR-DOM-079` | `/name{...}` | Slash render directive | inside Slash-enabled Text/RenderPlan templates only; template directive | `TEXT_TEMPLATE_GRAMMAR` / N/A | registered bounded directive and validated body/options → RenderPlan node with plain fallback | template order; short-circuit=NO; unknown directive policy explicit; anti-Turing limits | INACTIVE_CURRENT → APPROVED_DOMAIN_GATED | RF84-G53/G59/G60/G61/G64/G65/G83; RF52-G47/G48 | Semantic rendering directive; outside a Slash template `/` remains division. |
| `NSR-DOM-080` | `@` | annotation/metadata introducer | declaration/metadata profile; prefix annotation | `DECLARATION_GRAMMAR` / N/A | registered annotation and typed arguments → metadata attached to a declaration/node | compile-time only unless the annotation explicitly declares generated runtime metadata; short-circuit=NO; unknown/invalid annotation diagnostic | INACTIVE_CURRENT_OR_RESERVED → APPROVED_DOMAIN_GATED | RF46-G28; RF52-G47/G48 | Introduces typed metadata; it is never a free arithmetic operator. |

## 10.1. Ativação de domínio

Uma forma domain-gated exige pelo menos uma destas provas:

```text
explicit module/import;
receiver type whose operator protocol owns the symbol;
dedicated grammar context such as P(...), Text interpolation or Slash DSL;
capability/target declared by the enclosing program;
edition/profile that includes the domain.
```

Uma forma não é ativada apenas porque:

```text
o lexer reconhece o code point;
existe uma função interna;
há ABI/runtime nativa;
aparece num Markdown;
um renderer aceita uma string semelhante.
```

## 10.2. Domínios não podem sobrepor-se silenciosamente

Exemplo `×`:

```text
Set × Set       => Cartesian product
Vector3 × Vector3 => cross product
Number × Number => not selected; scalar multiplication remains *
```

Exemplo `|`:

```text
inside P(A | B) => conditional probability separator
general expression => RESERVED
pattern context => not active unless a future registry version says so
```

---

# 11. `RESERVED`

Contagem: **23**

| ID | Símbolo/forma | Nome | Contexto/fixity | Precedência | Regra de tipos e resultado | Avaliação/falha | Estado atual → alvo | Dependências | Descrição |
|---|---|---|---|---|---|---|---|---|---|
| `NSR-RES-001` | `<.` | reverse flow | future flow expression; infix | `UNASSIGNED` / non-associative | unfrozen → unfrozen | unfrozen; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED_SEMANTICS_NOT_FROZEN | RF27-G03/G04; future decision | Historical parse-only idea; no executable semantics are frozen in this registry. |
| `NSR-RES-002` | `<.>` | bidirectional flow/binding | future endpoint relation; infix | `UNASSIGNED` / non-associative | unfrozen → unfrozen | unfrozen; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED_SEMANTICS_NOT_FROZEN | RF27-G13; RF46-G31/G33/G45 | Reserved until synchronization, ownership, causality and failure semantics are separately frozen. |
| `NSR-RES-003` | `...` | ellipsis/spread/rest/varargs | general source; contextual | `UNASSIGNED` / N/A | unfrozen → unfrozen | N/A; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF52-G47/G48 | Does not activate spread, rest, varargs or a range. |
| `NSR-RES-004` | `::` | qualified path separator | module/namespace path; infix path separator | `TYPE_OR_PATH_GRAMMAR` / left | unfrozen path/name rules → qualified symbol | compile-time; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF27-G03; RF52-G47/G48 | Reserved because current modules do not require a second public path syntax. |
| `NSR-RES-005` | `#` | hash-prefixed syntax | outside Text/comments; prefix/contextual | `UNASSIGNED` / N/A | unfrozen → unfrozen | N/A; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF84/RF116; future lexer decision | Held for one future purpose only; no implicit debug, comment, color or template semantics. |
| `NSR-RES-006` | `#RRGGBB` | hash Color literal | future Color literal; literal | `LITERAL` / N/A | Color context → Color | compile-time; short-circuit=NO; stable reserved diagnostic and quick fix | INACTIVE_CURRENT → RESERVED | RF116-G87/G88; RF52-G47/G48 | Reserved until a dedicated lexer contract exists; explicit `Color.hex()` remains the safe form. |
| `NSR-RES-007` | `$` | dollar syntax outside interpolation | general source; prefix/contextual | `UNASSIGNED` / N/A | unfrozen → unfrozen | N/A; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED_OUTSIDE_TEXT_INTERPOLATION | RF84-G61; RF52-G47 | Only `${...}` inside an interpolation-enabled Text literal may eventually use dollar. |
| `NSR-RES-008` | ``...`` | backtick literal/template | future raw/tagged template; delimited | `TEXT_GRAMMAR` / N/A | unfrozen → Text/template | source order; short-circuit=NO; stable reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF84-G63; RF52-G47/G48 | Reserved until raw, multiline and tagged literal grammar is frozen. |
| `NSR-RES-009` | `/*...*/` | block comment | lexer outside literals; lexical | `LEXICAL` / N/A | comment bytes → no tokens | lexical; short-circuit=NO; current explicit unsupported diagnostic | UNSUPPORTED_CURRENT → RESERVED_FOR_FUTURE | RF52-G47/G48 | Line comments are canonical; block comments remain reserved, not silently ignored. |
| `NSR-RES-010` | `&` | infix bitwise AND | general expression; infix | `UNASSIGNED` / left | Int/Bytes candidate → candidate | left then right once; short-circuit=NO; reserved diagnostic | METHOD_ACTIVE_SYMBOL_INACTIVE → RESERVED_TO_AVOID_CONTEXT_COLLISION | RF27-G01; RF52-G47/G48 | Existing method-based bitwise API is preserved while `&` also remains available for a future unsafe/reference decision. |
| `NSR-RES-011` | `\|` | infix bitwise OR/or-pattern | general expression or pattern; infix/contextual | `UNASSIGNED` / left | unfrozen → unfrozen | left then right once; short-circuit=NO; reserved diagnostic outside approved domain grammar | METHOD_ACTIVE_SYMBOL_INACTIVE → RESERVED_TO_AVOID_CONTEXT_COLLISION | RF27-G01/G05; RF52-G47/G48 | Reserved because bitwise OR, or-patterns and conditional probability compete for the same code point. |
| `NSR-RES-012` | `~` | prefix bitwise NOT | general expression; prefix | `UNASSIGNED` / right | Int candidate → Int candidate | operand once; short-circuit=NO; reserved diagnostic | METHOD_ACTIVE_SYMBOL_INACTIVE → RESERVED | RF27-G01; RF52-G47/G48 | Method form remains canonical until infix/prefix bitwise syntax is intentionally activated. |
| `NSR-RES-013` | `<<` | shift left symbol | general expression; infix | `UNASSIGNED` / left | Int and bounded shift count candidate → Int | left then count once; short-circuit=NO; reserved diagnostic | METHOD_ACTIVE_SYMBOL_INACTIVE → RESERVED | RF27-G01; RF52-G47/G48 | Existing bounded method semantics are not automatically exposed as an infix operator. |
| `NSR-RES-014` | `>>` | shift right symbol | general expression; infix | `UNASSIGNED` / left | Int and bounded shift count candidate → Int | left then count once; short-circuit=NO; reserved diagnostic | METHOD_ACTIVE_SYMBOL_INACTIVE → RESERVED | RF27-G01; RF52-G47/G48 | Reserved until signed/logical right-shift profiles are unified beyond the current method contract. |
| `NSR-RES-015` | `expr[index]` | general bracket indexing | expression suffix; postfix | `P180_SUFFIX` / left | indexable receiver and typed index → element or Option<Element> | receiver then index once; short-circuit=NO; bounds policy must be explicit | INACTIVE_CURRENT_USE_AT → RESERVED | RF27-G06/G07/G10; RF52-G47/G48 | General indexing remains RESERVED. NSR-RES-015-COMPAT-1.0.1 separately preserves bound immutable Array<Int,4> with a constant Int index; `.at()` is canonical. See NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json. |
| `NSR-RES-016` | `a:b` | slice colon inside brackets | future slice grammar; contextual | `UNASSIGNED` / N/A | sliceable receiver and bounded indices → Slice | indices once; short-circuit=NO; bounds/step policy required | INACTIVE_CURRENT → RESERVED | RF27-G01/G06/G07; RF52-G47/G48 | Reserved to avoid colliding with type and named-argument colon until a slice grammar is frozen. |
| `NSR-RES-017` | `&expr` | address/reference prefix | unsafe/FFI future profile; prefix | `UNASSIGNED` / right | lvalue with capability and lifetime proof → typed reference/address | operand place once; short-circuit=NO; unsafe capability required | INACTIVE_CURRENT → RESERVED_UNSAFE | RF27-G04; RF46-G44/G46; RF52-G51 | Never active in the safe core without an explicit unsafe/FFI contract. |
| `NSR-RES-018` | `*expr` | dereference prefix | unsafe/FFI future profile; prefix | `UNASSIGNED` / right | typed reference/pointer with capability → referent/place | pointer once; short-circuit=NO; null/alignment/lifetime checked | INACTIVE_CURRENT → RESERVED_UNSAFE | RF27-G04; RF46-G44/G46; RF52-G51 | Binary `*` remains core multiplication; prefix dereference is reserved. |
| `NSR-RES-019` | `λ` | lambda introducer | future callable syntax; prefix/binder | `CALLABLE_GRAMMAR` / N/A | parameter list and body → callable | compile-time construction; captures once; short-circuit=NO; capture/effect policy required | CALLABLE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE → RESERVED | RF27-G03; RF52-G47/G48 | Reserved because the existing callable syntax should not be duplicated without a migration decision. |
| `NSR-RES-020` | `↦` | mapping arrow | future binder/comprehension syntax; infix/binder | `UNASSIGNED` / right | unfrozen → unfrozen | unfrozen; short-circuit=NO; reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF27-G03/G07; RF52-G47/G48 | Reserved for a possible mathematically styled mapping syntax. |
| `NSR-RES-021` | `\|x\|` | absolute-value delimiters | future numeric grammar; delimited | `UNASSIGNED` / N/A | numeric value → nonnegative numeric value | operand once; short-circuit=NO; reserved diagnostic | INACTIVE_CURRENT → RESERVED_DUE_BAR_AMBIGUITY | RF27-G14; RF52-G47/G48 | Reserved because `\|` already competes with patterns, probability and potential bitwise syntax. |
| `NSR-RES-022` | `≔` | definition symbol | future specification/proof grammar; infix | `UNASSIGNED` / right | unfrozen → unfrozen | compile-time; short-circuit=NO; reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF46-G29; RF52-G47/G48 | Reserved for formal definitions; not assignment or binding. |
| `NSR-RES-023` | `∴ / ∵` | therefore/because proof symbols | future proof prose/grammar; contextual | `UNASSIGNED` / N/A | unfrozen → proof narrative | compile-time; short-circuit=NO; reserved diagnostic | INACTIVE_CURRENT → RESERVED | RF46-G29; RF52-G47 | Reserved for proof-report notation, not executable core expressions. |

Reservado significa:

```text
TOKEN_MAY_BE_RECOGNIZED=YES
EXECUTABLE_SEMANTICS=NO
FALLBACK_TO_OTHER_MEANING=NO
DIAGNOSTIC_REQUIRED=YES
```

Nenhum grupo pode “experimentar” um reservado em produto público sem atualizar este Registry.

---

# 12. `REJECTED`

Contagem: **26**

| ID | Símbolo/forma | Nome | Contexto/fixity | Precedência | Regra de tipos e resultado | Avaliação/falha | Estado atual → alvo | Dependências | Descrição |
|---|---|---|---|---|---|---|---|---|---|
| `NSR-REJ-001` | `\|>` | alternative pipeline | general expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic with quick fix to receiver-first dot flow | INACTIVE_CURRENT → REJECTED_PERMANENT | RF52-G47/G48 | Rejected because `.` is the canonical Nebo pipeline. |
| `NSR-REJ-002` | `<->` | alternative bidirectional arrow | general expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic | INACTIVE_CURRENT → REJECTED_ALTERNATIVE | RF52-G47/G48 | Rejected spelling; the historical candidate is `<.>`, itself still RESERVED. |
| `NSR-REJ-003` | `**` | alternative power | numeric expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix to `^` | INACTIVE_CURRENT → REJECTED_ALTERNATIVE | RF52-G47/G48 | Rejected because `^` is the canonical power operator. |
| `NSR-REJ-004` | `^ as XOR` | XOR interpretation of caret | logic/bit expression; semantic reinterpretation | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; typed diagnostic explaining power versus XOR | INACTIVE_CURRENT_INFIX → REJECTED_SEMANTIC_INTERPRETATION | RF27-G01; RF52-G47/G48 | Caret is power only; XOR uses `xor`, `⊻` or the existing method. |
| `NSR-REJ-005` | `++` | increment | prefix/postfix mutation; prefix/postfix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix where semantics are safe | INACTIVE_CURRENT → REJECTED | RF27-G02; RF52-G47/G48 | Rejected to keep mutation explicit and exactly-once. |
| `NSR-REJ-006` | `--` | decrement | prefix/postfix mutation; prefix/postfix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix where semantics are safe | INACTIVE_CURRENT → REJECTED | RF27-G02; RF52-G47/G48 | Rejected to avoid C-style value-before/value-after ambiguity. |
| `NSR-REJ-007` | `cond ? a : b` | C-style ternary | general expression; ternary | `N/A` / right | N/A → N/A | N/A; short-circuit=CONDITIONAL; dedicated unsupported-ternary diagnostic | INACTIVE_CURRENT_REJECTED_WITH_IMPRECISE_SNAPSHOT_DIAGNOSTIC → REJECTED | RF27-G02; RF52-G47/G48 | Rejected in favor of explicit flow-first conditional constructs. |
| `NSR-REJ-008` | `a ?: b` | Elvis operator | general expression; binary/ternary shorthand | `N/A` / right | N/A → N/A | N/A; short-circuit=CONDITIONAL; diagnostic | INACTIVE_CURRENT → REJECTED | RF27-G05; RF52-G47/G48 | Rejected because `??` has a precise Option meaning. |
| `NSR-REJ-009` | `:=` | definition/assignment operator | binding or assignment; infix | `N/A` / right | N/A → N/A | N/A; short-circuit=NO; quick fix based on context | INACTIVE_CURRENT → REJECTED | RF27-G02; RF52-G47/G48 | Rejected because Nebo already separates value-first binding from assignment. |
| `NSR-REJ-010` | `(a, b, c) as comma operator` | free comma sequencing | general expression; infix | `N/A` / left | N/A → N/A | N/A; short-circuit=NO; diagnostic | INACTIVE_CURRENT → REJECTED | RF27-G02/G03; RF52-G47/G48 | Comma remains a separator and never discards intermediate expression results as an operator. |
| `NSR-REJ-011` | `= as equality` | single-equals comparison | comparison expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix to `==` when no assignment is intended | INACTIVE_AS_EQUALITY → REJECTED | RF27-G02; RF52-G47/G48 | Single equals is assignment only. |
| `NSR-REJ-012` | `<>` | legacy inequality | comparison expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix to `!=` | INACTIVE_CURRENT → REJECTED | RF52-G47/G48 | Rejected legacy spelling. |
| `NSR-REJ-013` | `and / or / not` | textual logical operators | Boolean expression; keyword operators | `N/A` / N/A | N/A → N/A | N/A; short-circuit=N/A; quick fix to canonical symbols | HISTORICAL_ONLY → REJECTED_PUBLIC_ALIAS | RF52-G47/G48 | Rejected to keep one ASCII core spelling plus optional mathematical Unicode aliases. |
| `NSR-REJ-014` | `!!` | force unwrap or double factorial | general expression; postfix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic requiring explicit intent | INACTIVE_CURRENT → REJECTED_AMBIGUOUS | RF27-G05; RF46-G35; RF52-G47/G48 | Rejected because force unwrap and double factorial are incompatible meanings. |
| `NSR-REJ-015` | `// as integer division` | integer-division operator | numeric expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; lexer treats it as a comment | IMPOSSIBLE_BY_CURRENT_LEXER → REJECTED | RF52-G47 | Line comments permanently own `//`; integer division uses `/` with typed operands. |
| `NSR-REJ-016` | `=>` | alternative match/lambda arrow | match or callable syntax; separator | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix where unambiguous | INACTIVE_CURRENT → REJECTED_PUBLIC_MATCH_SEPARATOR | RF27-G03/G05; RF52-G47/G48 | The Assembly language uses `->` for bounded match arms; `=>` is not a second public spelling. |
| `NSR-REJ-017` | `1..10` | ASCII dot-dot range | range expression; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; quick fix to U+2026 or Range API | INACTIVE_CURRENT → REJECTED_AS_RANGE | RF27-G06; RF52-G47/G48 | ASCII `..` is reserved for lateral flow and cannot also mean range. |
| `NSR-REJ-018` | `ptr->field` | pointer member arrow | member access; infix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic | INACTIVE_CURRENT → REJECTED_SAFE_CORE | RF27-G04; RF52-G47/G48 | Rejected from safe Nebo; `->` retains signature/match meaning. |
| `NSR-REJ-019` | `100 + 10%` | implicit relative percentage addition | numeric/quantity expression; type combination | `N/A` / N/A | Number plus Percent → N/A | N/A; short-circuit=NO; type diagnostic with explicit alternatives | INACTIVE_CURRENT → REJECTED_IMPLICIT_SEMANTICS | RF46-G35; RF52-G47/G48 | The language never guesses that adding a Percent means increasing the left value. |
| `NSR-REJ-020` | `a ≈ b without tolerance` | approximation with hidden epsilon | numeric expression; infix usage | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic requiring tolerance or Uncertain type | INACTIVE_CURRENT → REJECTED_USAGE | RF46-G35/G36; RF52-G47/G48 | A global or target-dependent hidden epsilon is forbidden. |
| `NSR-REJ-021` | `∫ returning bare Float` | integral without report | calculus expression; usage | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic requiring method/tolerance/status | INACTIVE_CURRENT → REJECTED_USAGE | RF46-G36; RF52-G47 | Numerical integration must expose convergence and estimated error. |
| `NSR-REJ-022` | `a ± b as implicit Tuple` | plus/minus tuple expansion | measurement expression; usage | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; type diagnostic | INACTIVE_CURRENT → REJECTED_SEMANTIC_INTERPRETATION | RF46-G35; RF52-G47 | `±` constructs an uncertainty-bearing value, never an implicit pair. |
| `NSR-REJ-023` | `Text + Number` | implicit Text coercion | Text expression; type combination | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; typed diagnostic | REJECTED_BY_CURRENT_TYPECHECKER_IN_TYPED_CONTEXTS → REJECTED_IMPLICIT_COERCION | RF84-G53/G59/G61; RF52-G47 | Text formatting must be explicit; arithmetic addition does not stringify values. |
| `NSR-REJ-024` | `user-defined new operator lexeme` | arbitrary custom operator | language extension; any | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic | INACTIVE_CURRENT → REJECTED_PERMANENT | RF46-G28; RF52-G47/G48 | User types may implement known protocols but may not invent symbols or precedence. |
| `NSR-REJ-025` | `fullwidth/confusable operator forms` | Unicode confusables | general source; lexical | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; diagnostic prints code point and canonical replacement | INACTIVE_CURRENT → REJECTED_SECURITY | RF52-G47/G48/G51 | Only explicitly registered Unicode aliases are accepted; NFKC/fullwidth lookalikes are rejected. |
| `NSR-REJ-026` | `%% in expression` | double-percent arithmetic | general expression; infix/postfix | `N/A` / N/A | N/A → N/A | N/A; short-circuit=NO; contextual diagnostic | INACTIVE_CURRENT → REJECTED_OUTSIDE_TEMPLATE | RF84-G60; RF52-G47 | `%%` is only a literal-percent escape inside a validated format template. |

Rejeitado significa:

```text
PUBLIC_ACCEPTANCE=NO
SILENT_COMPATIBILITY_MODE=NO
AUTO_ENABLE_BY_EDITION=NO
DIAGNOSTIC_OR_QUICK_FIX=YES
```

---

# 13. Protocolos de operadores conhecidos

Os utilizadores não podem inventar novos símbolos. Tipos podem implementar protocolos registados.

## 13.1. Core

```text
Add
Subtract
Multiply
Divide
Remainder
Power
UnaryPlus
Negate
Eq
Comparable
ThreeWayCompare
LogicalXor
Assign
AddAssign
SubtractAssign
MultiplyAssign
DivideAssign
RemainderAssign
PowerAssign
Coalesce
OptionalChain
```

## 13.2. Domain-gated

```text
Sqrt
CubeRoot
FourthRoot
Factorial
Summable
ProductReducible
ApproxEq
Divisibility
Membership
Union
Intersection
SetDifference
SymmetricDifference
SubsetRelation
CartesianProduct
DotProduct
CrossProduct
HadamardProduct
TensorProduct
DirectSum
Transpose
Adjoint
Inverse
Norm
InnerProduct
Compose
Integrable
Differentiable
Gradient
Divergence
Curl
Laplacian
DistributionRelation
IndependenceRelation
SymbolicEquivalence
TextConcat
PatternMatch
```

## 13.3. Restrições

```text
operator implementation must declare effects;
core scalar operators are pure;
implicit allocation must be reflected in the type/effect/budget contract;
implicit network/filesystem/process access is forbidden;
candidate selection is deterministic;
no implicit cross-type conversion is used to resolve ambiguity;
one source operation lowers through one semantic operator kind.
```

---

# 14. Precedência versus tipos

A precedência decide a árvore; o typechecker decide a operação.

```nebo
a + b * c
```

é sempre:

```nebo
a + (b * c)
```

Mesmo quando `+` e `*` são implementados por protocolos de tipos personalizados.

```nebo
-2 ^ 2
```

é:

```nebo
-(2 ^ 2)
```

```nebo
2 ^ 3 ^ 2
```

é:

```nebo
2 ^ (3 ^ 2)
```

Comparações são não associativas:

```nebo
0 < x < 10
```

é rejeitada. Forma correta:

```nebo
(0 < x) && (x < 10)
```

---

# 15. Isolamento das mini-linguagens de Text

## 15.1. `%`

```text
17 % 5                 remainder operator
15%                    Percent postfix constructor
"%d".format(value)     typed format placeholder
"%%"                    literal percent inside format template
```

## 15.2. `/`

```text
a / b                  division operator
// comment             line comment
"/ok{...}"            Slash DSL only in an enabled Text/RenderPlan template
```

## 15.3. `$`

```text
${expr}               interpolation only inside an enabled Text literal
$ outside Text          RESERVED
```

## 15.4. `#`

```text
# outside an approved future grammar        RESERVED
Color.hex("#FF0000")                        explicit API
Color(#FF0000)                              not accepted
```

---

# 16. Unicode security and source normalization

```text
SOURCE_ENCODING=UTF_8
OPERATOR_MATCHING=EXACT_CODE_POINT_SEQUENCE
NFC_FOR_REGISTERED_OPERATOR_LEXEMES=IDENTITY_ONLY
NFKC_AUTOMATIC_REWRITE=FORBIDDEN
BIDI_CONTROL_OUTSIDE_TEXT_COMMENT=FORBIDDEN
ZERO_WIDTH_OPERATOR_SEPARATION=FORBIDDEN
FULLWIDTH_OPERATORS=REJECTED
UNREGISTERED_MATH_CONFUSABLES=REJECTED
DIAGNOSTIC_PRINTS_CODE_POINTS=YES
```

Accepted aliases are exactly those in `UNICODE_ALIAS`.

Examples rejected:

```text
fullwidth ＋ instead of +
fullwidth ％ instead of %
division slash ∕ instead of / or ÷
asterisk operator ∗ instead of *
lookalike arrows not registered by context
```

---

# 17. Formatter, LSP and diagnostics

## 17.1. Formatter

The formatter must know:

```text
fixity;
required spaces;
delimiter pairing;
domain activation;
whether an alias is exact;
whether capitalization or code-point conversion changes semantics;
```

Default:

```text
preserve source operator spelling;
normalize spaces;
never convert reserved/rejected syntax into accepted syntax silently;
never change ASCII to Unicode without explicit mode;
never change a domain-gated symbol into a core symbol.
```

## 17.2. LSP

Required capabilities:

```text
hover with Registry ID and class;
go-to-registry/specification;
signature/type rules;
precedence explanation;
quick fix for rejected alternatives;
code-point display for confusables;
semantic token per operator family;
rename safety for operator-bearing templates;
formatting parity;
source-map parity for Unicode aliases.
```

## 17.3. Diagnostic namespaces

Proposed, not activated by this document:

```text
NEBO-SYM-LEX-*       lexical/confusable/maximal-munch
NEBO-SYM-CTX-*       wrong context or missing domain
NEBO-SYM-TYPE-*      operand/result mismatch
NEBO-SYM-PREC-*      chaining/precedence ambiguity
NEBO-SYM-EVAL-*      effect/exactly-once/short-circuit violation
NEBO-SYM-OVERFLOW-*  checked arithmetic/domain failure
NEBO-SYM-RES-*       reserved lexeme
NEBO-SYM-REJ-*       rejected form with canonical alternative
NEBO-SYM-UNICODE-*   alias and code-point diagnostics
```

Activation requires a collision audit in the live Diagnostic Registry.

---

# 18. Mandatory current-HEAD gate before implementation

The 2026-08-09 audit reproduced a candidate typechecker bypass for discarded expression statements and candidate routing issues for `?` and Char equality. Therefore no operator expansion may begin before this gate passes on the live HEAD:

```text
TYPE_MATRIX=
Int,Float,Bool,Text,Char,Bytes,Option,Result,user_struct

CONTEXT_MATRIX=
bare_expression_statement
binding_initializer
return_expression
console_argument
function_argument
branch_guard

MODE_MATRIX=
check
emit-asm
build
native_run_when_valid

REQUIRED:
same typechecking in every context;
zero codegen after a type error;
dedicated diagnostics for ternary, ?? and ?.;
Char equality decision uniform in all contexts;
double-clean determinism;
RF27 regressions;
no fixture/source-fingerprint dispatch.
```

This Registry does not claim those candidates are still open on the current HEAD; it requires replay before expanding the operator surface.

---

# 19. Roadmap dependency matrix

| Registry area | Required substrata |
|---|---|
| Existing core and assignment | RF27-G02–G06 |
| Bitwise method bridge and `xor` | RF27-G01, RF27-G08 |
| Numeric power, roots, constants, sums | RF27-G14, RF46-G35/G36 |
| Matrix/tensor symbols | RF27-G15/G16/G17, RF46-G36 |
| Sets/membership | RF27-G07/G08/G09 |
| Probability symbols | RF27-G14, RF46-G37 |
| Formal logic and proof symbols | RF46-G29/G30 |
| Graph/workflow arrows | RF27-G09, RF46-G34/G45 |
| Text concat, formatting, interpolation, Slash DSL | RF84-G53–G65 |
| Regex and source tooling | RF84-G83, RF52-G47/G48 |
| Operator diagnostics, formatter, linter, LSP | RF52-G47/G48 |
| Compiler performance and operator-query cache | RF52-G49 |
| Unicode/target/source portability | RF52-G51/G52 |
| Console/Color symbols and presentation options | RF116-G85–G116 where applicable |

A native runtime substrate does not by itself activate source syntax.

---

# 20. Migration and change decisions

| Previous/current form | Registry decision |
|---|---|
| Current `Int / Int` signed integer division | Preserved; truncates toward zero |
| Current `bitAnd/bitOr/bitXor/bitNot/shiftLeft/shiftRight` | Preserved |
| Infix `^` as XOR from C-like traditions | Rejected; `^` means power |
| XOR | `xor` canonical ASCII, `⊻` exact Unicode alias, `bitXor()` method preserved |
| `Text + value` coercion | Rejected |
| Text concatenation | Domain-gated `⧺` or `.concat()` |
| `1..10` range | Rejected |
| Range | `…` family or existing `Range.*` APIs |
| `..` | Canonical bounded lateral flow/tap |
| `<.` / `<.>` | Reserved until semantics are fully frozen |
| `?` | Preserved as Result propagation |
| C ternary `? :` | Rejected |
| `??` / `?.` / `??=` | Approved core Option operators, not yet implemented |
| `=>` match arm | Rejected; current `->` preserved |
| `++` / `--` | Rejected |
| `%` | Infix remainder, postfix Percent, template token only in Text |
| Unicode math | Exact aliases or domain-gated forms only |
| User-created arbitrary operators | Rejected |

---

# 21. Recommended implementation waves

This is not a roadmap authorization. A future roadmap should split at least:

```text
W1 — live-HEAD operator matrix and typechecker uniformity;
W2 — registry infrastructure, TokenKind and diagnostics;
W3 — power, xor, three-way comparison and checked assignments;
W4 — Option operators and ellipsis ranges;
W5 — exact Unicode aliases and formatter/LSP;
W6 — typed ratios, roots, constants and uncertainty;
W7 — sets and linear-algebra operators;
W8 — calculus and probability binders;
W9 — formal logic, proof and graph grammars;
W10 — Text/template/regex integration;
W11 — cross-domain conformance and independent audit.
```

Each symbol needs its own positive, negative, precedence, type, exactly-once, failure, formatter, LSP and determinism evidence.

---

# 22. Machine-readable schema

The companion TSV contains one row per registry entry:

```text
id
cls
lexeme
name
context
fixity
arity
precedence
associativity
canonical_ascii
domain
operand_rule
result_rule
evaluation
short_circuit
failure_policy
current_state
target_state
dependencies
description
```

Required uniqueness key:

```text
lexeme + context + fixity + class
```

---

# 23. Registry counts

```text
CORE_ALWAYS_ON=47
UNICODE_ALIAS=9
DOMAIN_GATED=80
RESERVED=23
REJECTED=26
TOTAL_ENTRIES=185
```

---

# 24. Terminal normative block

```text
FINAL_DECISION=
NEBO_SYMBOL_AND_OPERATOR_REGISTRY_V1_FROZEN

REGISTRY_CLASSES=
CORE_ALWAYS_ON,UNICODE_ALIAS,DOMAIN_GATED,RESERVED,REJECTED

POWER_OPERATOR=^
POWER_ASSOCIATIVITY=RIGHT
CARET_XOR=REJECTED

XOR_ASCII=xor
XOR_UNICODE=⊻
XOR_METHOD=bitXor

REMAINDER=INFIX_%
PERCENT=POSTFIX_%
PERCENT_RESULT=Percent

INT_DIVISION=
SIGNED_INTEGER_TRUNCATE_TOWARD_ZERO

RANGE_CANONICAL=
…, …<, <…, <…<

ASCII_DOT_DOT_RANGE=
REJECTED

LATERAL_FLOW=
..

REVERSE_FLOW_SYMBOL=<.
REVERSE_FLOW_STATUS=RESERVED

BIDIRECTIONAL_FLOW_SYMBOL=<.>
BIDIRECTIONAL_FLOW_STATUS=RESERVED

RESULT_PROPAGATION=?
OPTION_COALESCE=??
OPTION_CHAIN=?.
OPTION_COALESCE_ASSIGN=??=

MATCH_ARM_SEPARATOR=->
FAT_ARROW_MATCH=REJECTED

UNICODE_ALIAS_ENGINE=
SAME_SEMANTIC_OPERATOR_KIND

DOMAIN_GATED_REQUIRES=
TYPE_OR_MODULE_OR_DEDICATED_GRAMMAR_PROOF

USER_DEFINED_NEW_OPERATOR_LEXEMES=
FORBIDDEN

USER_TYPES_IMPLEMENT_KNOWN_PROTOCOLS=
ALLOWED

HIDDEN_COERCION=
FORBIDDEN

HIDDEN_TOLERANCE=
FORBIDDEN

HIDDEN_PARALLELISM=
FORBIDDEN

EVALUATION_DEFAULT=
LEFT_TO_RIGHT_EXACTLY_ONCE

OVERFLOW_DEFAULT=
CHECKED

CURRENT_PRODUCT_MUTATION=
NONE

PRODUCT_IMPLEMENTATION_AUTHORIZED=
NO

ROADMAP_AUTO_CREATED=
NO

NEXT_ACTION=
REGISTER_DOCUMENT_THEN_WAIT_FOR_EXPLICIT_BOUNDED_ROADMAP_AUTHORIZATION
```

---

# 25. Validation requirements for this document

```text
UTF8=REQUIRED
LF_ONLY=REQUIRED
FINAL_NEWLINE=REQUIRED
MARKDOWN_CODE_FENCES=BALANCED
REGISTRY_IDS=UNIQUE
TSV_ROWS_MATCH_MARKDOWN_COUNTS=REQUIRED
CLASS_VALUES=EXACTLY_FIVE
SOURCE_HASHES=PRESERVED
```
