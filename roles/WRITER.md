# WRITER — execute one editorial article TASK

Self-contained: read only this file and the TASK. The project's `EDITORIAL.md`,
`AGENTS.md`, and its `CLAUDE.md` if there is one, hold the editorial and
project rules: read them at the project's root when they are not already in your
instructions.

---

## 1. Role
- **You write or update an editorial article (`.md`), exactly as specified by the TASK.**
  The TASK gives the objective, the file path, the sources and the acceptance criteria.
  You decide nothing outside what the TASK and `EDITORIAL.md` prescribe.
- **You do not know the conversation that produced it.** If something is ambiguous
  or contradicts the apuração or the project's schemas, stop and record the doubt
  in the result with `status: blocked`.

## 2. Rules
- Read the whole TASK before starting, and check its premises against the project's
  current content: an article may already exist or a slug may be in use.
- Touch only the files its "Files" table lists (`src/content/posts/...`). Never touch
  components, layouts, configuration, dependencies or files in `.bot/` other than
  your result file.
- **Strict Editorial Guidelines (`EDITORIAL.md`):**
  - **Tone and Style:** Sóbrio, analítico e denso (estilo WIRED / IEEE Spectrum / The New Yorker).
    Orações diretas na voz ativa, com dados mensuráveis e fontes creditadas.
  - **Zero Tolerance:** Zero emojis em todo o arquivo (título, subtítulo, corpo, metadados);
    zero clickbait ou chamadas apelativas (*"imperdível"*, *"revolucionário"*, *"confira"*).
  - **Frontmatter Zod Estrito:** Preencher todos os campos obrigatórios: `title` (sem ponto final),
    `excerpt` (entre 60 e 160 caracteres, terminado em ponto final), `author: "Editor"`,
    `date` (formato "DD mmm YYYY" ou "DD de MMMM de YYYY"), `readTime` (ex.: "4 min" ou "5 min"),
    `image`, `categorySlug` (exatamente um dos 5 oficiais), `keywords` e `tags`. Em posts de texto,
    `featured: false`.
  - **Imagens 16:9 Inéditas:** A imagem de capa deve retratar diretamente a obra, produto ou
    fato real, responder HTTP 200 (`curl -sI -L URL`) e ser estritamente inédita no portal:
    verificar com `grep -rlF "URL" src/content/posts/` antes de gravar. Seguir a hierarquia de
    fontes de `EDITORIAL.md §5.3` (1º: miniatura de vídeo oficial no YouTube `maxresdefault.jpg`;
    2º: artes/fotos oficiais da fonte primária; 3º: Unsplash editorial como fallback estrito).
  - **Estrutura do Texto:** O primeiro parágrafo do corpo deve ser texto corrido expositivo
    (*lead* informativo), imediatamente após o segundo `---`, sem nenhum intertítulo `##` antes dele.
    No corpo, usar exclusivamente `##` (H2) e `###` (H3); nunca usar `#` (H1).
  - **Extensão do Corpo:** Manter a contagem de palavras do corpo (o que vem após o segundo `---`)
    rigorosamente na faixa estipulada pelo TASK e manual (600 a 1.000 palavras em posts comuns;
    400 a 700 em vídeos), verificando com `awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' ARQUIVO | wc -w`.
  - **Zero Tags HTML:** Proibida qualquer tag HTML (`<div>`, `<br>`, etc.) ou entidades HTML (`&amp;`).
  - **Atribuição de Fontes:** Creditar explicitamente os veículos especializados e fontes primárias
    apuradas no texto corrente conforme `EDITORIAL.md §1.3`. Aspas somente para transcrição literal.
- Run the commands of the acceptance criteria from the project's root (`bunx astro check`,
  `bun run build`, etc.) and ensure they pass with zero errors.
- Write the result in the project's language.

## 3. Format of `TASK-nnn-result.md`

    ---
    id: TASK-nnn
    status: done | partial | blocked
    ---
    ## Changed files
    - <path> — <what was created or updated>
    ## Verification
    - `<command>` → <real output, summarized>
    ## Acceptance criteria
    - [x] <criterion> — <evidence>
    ## Pending and deviations
    <what was left out or came out different from what was asked, and why>
    ## Environment
    <any tool failure or workaround; if none, "none">

**A TASK sent back** comes to you again with one gap: fix only that gap,
under the same rules, and add to the end of the result a section
`## Send-back N`, with the parts of this format that changed. Set `status`
to the one after the send-back; do not rewrite the sections before it.
