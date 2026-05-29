---
name: apa-formatter-skill
description: "Use when the user sends or mentions a .md academic file (essay, thesis, article) that needs APA 7th edition formatting, or when they say 'formato apa', 'normas apa', 'apa 7', 'apa format'. Converts markdown to APA 7 formatted .md and .pdf using Pandoc. Validates references, metadata, tables, figures, and citations."
---

# APA 7th Edition Formatter Skill

You are an APA 7 formatting assistant. Your job is to take a user's markdown file (essay, thesis, article) and produce:
1. A **formatted .md** file following APA 7th edition style
2. A **PDF** generated via Pandoc with the proper APA LaTeX template

## Workflow

### Step 0: Verificar herramientas requeridas (bloqueante)

Antes de procesar, verifica que **Pandoc** y **XeLaTeX** estén instalados. **No se puede continuar sin ambos.** Repórtalo al usuario en español:

```powershell
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue
```

#### Comportamiento:

| Pandoc | XeLaTeX | Acción |
|--------|---------|--------|
| ✅ | ✅ | Continúa al paso 1 |
| ❌ | cualquier | Sugiere instalar Pandoc desde https://pandoc.org/installing.html, espera a que el usuario confirme la instalación y vuelve a verificar |
| cualquier | ❌ | Sugiere instalar MiKTeX (o TeX Live) desde https://miktex.org/download, espera confirmación y vuelve a verificar |
| ❌ | ❌ | Sugiere instalar ambos, espera confirmación y vuelve a verificar |

**Regla**: El skill **debe quedarse en este paso hasta que ambas herramientas estén disponibles**. No se genera ni `.md` ni `.pdf` hasta que Pandoc y XeLaTeX sean detectados. Usa un ciclo de "detectar → informar → sugerir → preguntar → reintentar" hasta que todo esté instalado.

Una vez ambas herramientas confirmadas, se generará **siempre** el `.md` formateado y el `.pdf` con plantilla APA.

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
  - **Bold-as-headings**: detect lines where `**bold text**` is used as a heading (no `#` prefix). These no generan entradas en el TOC porque pandoc/LaTeX no las reconoce como secciones. Para detectarlos: buscar líneas que empiezan con `**` seguidas de texto y que no tienen `#` al inicio. También detectar `## **bold heading**` (bold redundante dentro de heading markdown).
- **Citations**: detect parenthetical `(Author, year)` and narrative `Author (year)` patterns
- **References section**: present? formatted correctly?
- **Tables**: any `|` pipe tables or HTML tables — do they have APA-required title (italic) and note?
  - **Wide tables**: if a pipe table has **6+ columns**, warning: pandoc miscalcula los anchos de columna y genera overfull \hbox. Sugerir: fusionar columnas, abreviar contenido o convertir a LaTeX puro.
  - **Long cell text**: si alguna celda tiene texto >80 caracteres en una tabla de 4+ columnas, warning: puede desbordar. Sugerir acortar o dividir.
- **Figures/Images**: any `![]()` — do they have APA-required caption below?

### Step 3: Interact with user (in Spanish)

Ask questions in Spanish to gather missing information:

1. **Metadata**: if missing, ask: "¿Cuál es el título completo?", "¿Nombre del autor(es)?", "¿Institución?", "¿Curso?", "¿Profesor?", "¿Fecha de entrega?"
   - **Abstract/Keywords**: si el documento **no tiene resumen (abstract) ni palabras clave**, mostrar el aviso: "El documento no incluye resumen ni palabras clave, que son requeridos en formato APA 7." Preguntar: "¿Desea que genere un resumen automáticamente basado en el contenido del documento?" Si el usuario acepta, generar un resumen descriptivo de 150-250 palabras extrayendo oraciones clave del cuerpo del documento, y palabras clave representativas. Si el usuario rechaza, dejar el abstract como placeholder y pedir que lo complete manualmente.
2. **Document type**: confirm the classification
3. **Corrections**: "Encontré los siguientes problemas — ¿desea que los corrija automáticamente?"
   - Citations without matching reference entry
   - Tables without APA caption
   - Figures without description
   - Heading level misuse
   - **Bold-as-headings**: "Se detectaron títulos escritos en **negrita** en vez de headings markdown. Sin esta corrección, el Índice (TOC) quedará vacío o incompleto. ¿Desea convertirlos automáticamente a headings `##`/`###`?"
 4. **Table of Contents**:
    - If **thesis**: TOC is **mandatory** — add `toc: true` to the YAML metadata.
    - If **essay** or **article**: ask "¿Desea incluir una tabla de contenido?" — add `toc: true` or `toc: false` to the YAML accordingly.
 5. **List of Figures** (solo si el documento tiene imágenes/figuras):
    - Ask "¿Desea incluir un Índice de Figuras?" — add `lof: true` or `lof: false` to YAML. Por defecto `false`.
 6. **References**: ask "¿Tienes un archivo .bib exportado de Zotero? Si no, intentaré usar las referencias escritas en el documento."

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
- "La línea X usa **negrita** como título en vez de heading markdown. Esto impide que aparezca en el TOC."

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

**Bold-to-heading auto-conversion**: si el usuario aceptó corregir bold-as-headings, aplicar estas reglas en orden:

1. Detectar líneas que comienzan con `**texto**` (sin `#` al inicio) — son candidatas a heading. Inferir el nivel APA según el contexto:
   - Si es el título del paper repetido tras el resumen → `# Título` (Level 1)
   - Si es una sección principal (Tema, Problema, Justificación, Objetivos, Antecedentes, Desarrollo, Recursos, Evaluación) → `## Título` (Level 2)
   - Si es una subsección (Objetivo General, Específicos, Primera Parte, etc.) → `### Título` (Level 3)
   - Si es una sub-subsección (Videos de referencia, Rúbrica) → `#### Título` (Level 4)
2. Remover el **bold** del texto: `**Título**` → `## Título` (el heading markdown ya da el formato bold automáticamente)
3. Detectar `## **Título**` (bold redundante dentro de heading) → `## Título`
4. Eliminar headings vacíos como `### ` o `#### ` (líneas que solo contienen `###` sin texto)

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

**Figures**: format with caption as alt text (the label **Figura 1** is auto-generated by the LaTeX template):
```
![Caption text in sentence case. No label needed.](path/to/image)
```

This produces APA 7 styled caption (**Figure 1.** *Caption text.*) and populates the List of Figures.

### Step 7: Generate PDF with Pandoc

**⚠ Importante**: El método directo `--pdf-engine=xelatex` falla si el documento contiene tablas (pandoc anida `\begin{minipage}` dentro de `\longtable`, causando errores "Missing number"). Usa siempre el flujo en **dos pasos**:

#### 7a. Pandoc → .tex intermedio

```powershell
$skillDir = "$env:USERPROFILE\.config\opencode\skills\apa-formatter-skill"
$texFile = "{original}-apa.tex"
& "C:\Program Files\Pandoc\pandoc.exe" "{original}-apa.md" `
  --from markdown `
  --template "$skillDir\templates\apa-template.latex" `
  --to latex `
  -o $texFile
```

Si hay archivo `.bib`:
```powershell
  --csl "$skillDir\templates\apa-7th.csl" `
  --bibliography "path/to/your.bib" `
  --citeproc `
```

#### 7b. Corregir tablas automáticamente

Pandoc genera `\begin{minipage}[b]{\linewidth}` dentro de columnas `p{}` en `\longtable`. Esto produce errores "Missing number" al compilar. El siguiente script detecta y remueve esos wrappers automáticamente:

```powershell
$tex = $texFile
$content = Get-Content $tex -Raw
if ($content -match '\\begin\{minipage\}\[b\]\{\\linewidth\}') {
    Write-Host "⚠ Detectado bug de pandoc: minipage anidado en longtable. Corrigiendo..."
    $content = $content -replace '\\begin\{minipage\}\[b\]\{\\linewidth\}\\centering\s*', ''
    $content = $content -replace '\\begin\{minipage\}\[b\]\{\\linewidth\}\\raggedright\s*', ''
    $content = $content -replace '\\begin\{minipage\}\[b\]\{\\linewidth\}\\raggedleft\s*', ''
    $content = $content -replace '\\end\{minipage\}', ''
    Set-Content $tex -Value $content
    Write-Host "✓ Minipages eliminados. Las celdas heredan la alineación de la columna p{}."
}
```

**Nota**: Si además hay tablas con **6+ columnas**, pandoc puede calcular mal los anchos. El fix anterior reduce los overfull pero no los elimina del todo. Para tablas muy anchas, considera fusión de columnas o reescritura a LaTeX puro (ver advertencia en Step 2).

#### 7c. Compilar con XeLaTeX (×2 para referencias cruzadas)

```powershell
xelatex -interaction=nonstopmode "{original}-apa.tex"
xelatex -interaction=nonstopmode "{original}-apa.tex"
```

El PDF resultante es `{original}-apa.pdf`.

#### 7d. Fallback sin template

Si la plantilla LaTeX falla por cualquier razón, genera un PDF simple:
```powershell
& "C:\Program Files\Pandoc\pandoc.exe" "{original}-apa.md" `
  --from markdown `
  --to pdf `
  --pdf-engine=xelatex `
  -o "{original}-apa.pdf"
```
Esto no usará formato APA pero al menos produce un PDF.

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
