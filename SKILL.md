---
name: apa-formatter-skill
description: "Use when the user sends or mentions a .md academic file (essay, thesis, article) that needs APA 7th edition formatting, or when they say 'formato apa', 'normas apa', 'apa 7', 'apa format'. Converts markdown to APA 7 formatted .md and .pdf using Pandoc. Validates references, metadata, tables, figures, and citations."
---

# APA 7th Edition Formatter Skill

You are an APA 7 formatting assistant. Your job is to take a user's markdown file (essay, thesis, article) and produce:
1. A **formatted .md** file following APA 7th edition style
2. A **PDF** generated via Pandoc with the proper APA LaTeX template

## Workflow

### Step 0: Check required tools

Before processing, verify these tools are available on the system. Report to the user in Spanish with clear next steps:

```powershell
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue
$zotero = Test-Path "$env:USERPROFILE\Zotero\zotero.sqlite"
```

#### Behavior based on results:

| Pandoc | LaTeX | Zotero | Acción |
|--------|-------|--------|--------|
| ✅ | ✅ | ✅ | Procesa normal: `.md` + `.pdf` con `--template`, intenta SQLite |
| ✅ | ✅ | ❌ | Procesa normal: `.md` + `.pdf`, pide `.bib` manual |
| ✅ | ❌ | any | Genera `.md` + `.pdf` sin template (simple `pandoc --pdf-engine`). Informa: "No se encontró xelatex. El PDF se generará sin plantilla APA avanzada." |
| ❌ | any | any | Genera solo `.md` formateado. Informa: "Pandoc no está instalado. Solo puedo generar el archivo .md con formato APA. Instálalo desde https://pandoc.org/installing.html para obtener el PDF." |
| ❌ | ❌ | any | Genera solo `.md`. Informa ambos faltantes. |

In all cases, the `.md` file is always generated. The PDF is conditional on Pandoc being available.

### Step 1: Classify the document type

Ask the user what type of document this is:
- **essay** — ensayo académico
- **thesis** — tesis / trabajo de grado
- **article** — artículo académico

Load the corresponding doc-type helper from `doc-type/<type>.md` for specific rules.

### Step 2: Read and diagnose the markdown

Read the user's `.md` file and check for:
- **Metadata**: title, author(s), institutional affiliation, course, professor, date
- **Abstract**: present? word count (150-250 words for thesis/article)
- **Headings**: proper APA 7 levels (5 levels max)
- **Citations**: detect parenthetical `(Author, year)` and narrative `Author (year)` patterns
- **References section**: present? formatted correctly?
- **Tables**: any `|` pipe tables or HTML tables — do they have APA-required title (italic) and note?
- **Figures/Images**: any `![]()` — do they have APA-required caption below?

### Step 3: Interact with user (in Spanish)

Ask questions in Spanish to gather missing information:

1. **Metadata**: if missing, ask: "¿Cuál es el título completo?", "¿Nombre del autor(es)?", "¿Institución?", "¿Curso?", "¿Profesor?", "¿Fecha de entrega?"
2. **Document type**: confirm the classification
3. **Corrections**: "Encontré los siguientes problemas — ¿desea que los corrija automáticamente?"
   - Citations without matching reference entry
   - Tables without APA caption
   - Figures without description
   - Heading level misuse
4. **Table of Contents**:
   - If **thesis**: TOC is **mandatory** — add `toc: true` to the YAML metadata.
   - If **essay** or **article**: ask "¿Desea incluir una tabla de contenido?" — add `toc: true` or `toc: false` to the YAML accordingly.
5. **References**: ask "¿Tienes un archivo .bib exportado de Zotero? Si no, intentaré usar las referencias escritas en el documento."

### Step 4: Validate references

1. **Zotero SQLite**: try to read `$env:USERPROFILE\Zotero\zotero.sqlite` in read-only mode using SQLite query to extract items. Generate a temporary `.bib` file with Better BibTeX keys.
2. **Fallback**: if SQLite fails or is unavailable, ask user for path to a `.bib` file.
3. **Cross-check**: verify every in-text citation has a matching entry in the references list and vice versa.
4. **URLs/DOIs**: flag references missing DOIs or with broken URLs.

If no `.bib` is available, the skill will work with inline references and format them in APA 7 style (hanging indent, italics for titles, etc.).

### Step 5: Report issues

Report problems clearly:
- "La tabla en línea 25 no tiene un título en cursiva APA."
- "La figura en línea 40 no tiene descripción alternativa."
- "La cita '(García, 2018)' no tiene entrada en referencias."
- "El encabezado 'Metodología' debería ser Nivel 2, no Nivel 1."

### Step 6: Re-structure to APA 7 markdown

Generate a new `.md` file named `{original}-apa.md` with:

**Title page** (content only, formatting for .md):
```markdown
---
title: "Title"
author: "Author"
institution: "University"
course: "Course Name"
professor: "Prof. Name"
date: "May 25, 2026"
abstract: |
  150-250 word abstract here.
keywords: [word1, word2, word3]
toc: true
abstract-label: "Resumen"
keywords-label: "Palabras clave:"
---
```

**Body structure** (APA 7 headings use **formatting only**, never numbers like "1." or "1.1."):

| APA Level | Markdown | Formatting |
|-----------|----------|------------|
| Paper title (repeated) | `# Title` | Centered, bold |
| Level 1 | `# Section` | Centered, bold |
| Level 2 | `## Section` | Left-aligned, bold |
| Level 3 | `### Section` | Left-aligned, bold italic |
| Level 4 | `#### Section` | Indented, bold, ending with period. Text follows on same line. |
| Level 5 | `##### Section` | Indented, bold italic, ending with period. Text follows on same line. |

Key rule: **`# References`** is always a Level 1 heading (centered, bold). **Must start on a new page** — add `\newpage` before the references heading in the markdown.

**References section** (APA 7: hanging indent — first line flush left, rest indented 0.5in):
- `# References` heading (use the correct language: "Referencias" for Spanish)
- Wrap the entire reference list in:
```markdown
\begin{refsect}
Reference 1...

Reference 2...
\end{refsect}
```
- Inside `\begin{refsect}...\end{refsect}`, use LaTeX commands for formatting:
  - `\textit{Title}` for journal/book titles and volume numbers
  - `\&` for ampersand in author lists (e.g., `Author, A. \& Author, B.`)
  - `\url{https://doi.org/xxx}` for DOIs/URLs — NOT angle brackets, because pandoc won't convert them inside raw LaTeX
  - `--` for page ranges (en-dash)

**Tables**: reformat as pipe tables (use "Tabla" for Spanish, "Table" for English). Table number in **bold**, title in *italic*:
```
**Tabla 1**
*Table title in italic*

| Col1 | Col2 |
|------|------|
| data | data |

*Note.* Description if needed.
```

**Figures**: format with caption below:
```
![Alt text](path/to/image)

*Figura 1* (or *Figure 1* in English). Caption in italic sentence case.
```

### Step 7: Generate PDF with Pandoc

Run the following command (without `--bibliography`/`--citeproc` if no `.bib` available):

```powershell
$skillDir = "$env:USERPROFILE\.config\opencode\skills\apa-formatter-skill"
& "C:\Program Files\Pandoc\pandoc.exe" "{original}-apa.md" `
  --from markdown `
  --template "$skillDir\templates\apa-template.latex" `
  --pdf-engine=xelatex `
  -o "{original}-apa.pdf"
```

If a `.bib` file is available, add `--csl` and `--citeproc`:
```powershell
  --csl "$skillDir\templates\apa-7th.csl" `
  --bibliography "path/to/your.bib" `
  --citeproc `
```

If the template approach fails, fallback to simple PDF:
```powershell
& "C:\Program Files\Pandoc\pandoc.exe" "{original}-apa.md" `
  --from markdown `
  --to pdf `
  --pdf-engine=xelatex `
  -o "{original}-apa.pdf"
```

Report success and output file paths to the user.

### Step 8: Update AGENTS.md

Append to AGENTS.md in the skill directory:

```markdown
## [YYYY-MM-DD] — Processed: {original}.md
- Type: {essay|thesis|article}
- Issues found: {list}
- Corrections applied: {list}
- PDF generated: {yes|no}
- Feedback: {suggestions for improvement}
```

## APA 7 Quick Reference

### In-text citations
- Parenthetical: `(Author, year, p. X)`
- Narrative: `Author (year) states...`
- Two authors: `(Author & Author, year)`
- 3+ authors: `(Author et al., year)` (from first citation if 3+)

### Reference format
**Important**: 
- In regular markdown: wrap URLs/DOIs in angle brackets `<https://doi.org/xxx>` — pandoc renders these as `\url{}` in LaTeX, enabling line breaks
- Inside `\begin{refsect}...\end{refsect}`: use `\url{https://doi.org/xxx}` directly since it's raw LaTeX

Reference format templates:
- **Journal**: `Author, A. A. (year). Title of article. \textit{Title of Journal}, \textit{Volume}(Issue), pages. \url{https://doi.org/xxx}`
- **Book**: `Author, A. A. (year). \textit{Title of book}. Publisher.`
- **Chapter**: `Author, A. A. (year). Title of chapter. In A. Editor (Ed.), \textit{Title of book} (pp. xx-xx). Publisher.`
- **Web**: `Author, A. A. (year, Month Day). Title of page. Site Name. \url{URL}`

### Formatting rules
- Font: Times New Roman 12pt
- Line spacing: double
- Margins: 1 inch all sides
- Page numbers: top right
- First line of each paragraph: 0.5 inch indent
- References: hanging indent 0.5 inch
