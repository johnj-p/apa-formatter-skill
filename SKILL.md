---
name: apa-formatter-skill
description: "Use when the user sends or mentions a .md academic file (essay, thesis, article) that needs APA 7th edition formatting, or when they say 'formato apa', 'normas apa', 'apa 7', 'apa format'. Converts markdown to APA 7 formatted .md and .pdf using Pandoc. Validates references, metadata, tables, figures, and citations in 4 stages: Stage A (pre-structure), Stage B (inline during restructuring), Stage C (pre-PDF), Stage D (post-PDF)."
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
  - **Translated works**: si una cita corresponde a una obra traducida, verificar que el año usado sea el de la **versión consultada** (traducción), no el año de la obra original. La referencia debe incluir "(Obra original publicada en AAAA)" al final.
- **References section**: present? formatted correctly?
  - **Uncited references**: detectar referencias en la lista que **no tienen ninguna cita** en el cuerpo del documento. Reportar como warning: "La referencia 'X' aparece en la lista pero no está citada en el texto. Debe eliminarse o agregarse una cita."
  - **Author list**: detectar `et al.` o `y otros` dentro de la lista de referencias. APA 7 no permite estas abreviaciones en la lista de referencias — todos los autores (hasta 20) deben listarse explícitamente. Si no se conoce la lista completa, reportar: "La referencia 'X' usa 'et al.' en la lista de referencias. APA 7 exige listar todos los autores (hasta 20). Verificar la lista completa de autores."
  - **Missing DOIs/URLs**: detectar referencias sin DOI/URL cuando el documento citado es accesible en línea. Sugerir agregarlos.
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
  7. **Repeated title**: agregar siempre `# Título` centrado y bold después del abstract (APA 7 obligatorio). No preguntar al usuario.
 8. **Running head (encabezado superior)**: "APA 7 para documentos profesionales usa un encabezado en la parte superior de cada página con el título abreviado en mayúscula (máx. 50 caracteres). ¿Desea incluir un running head?" Si el usuario acepta, preguntar: "¿Cuál es la versión abreviada del título?" y agregar `runninghead: "VERSIÓN ABREVIADA"` al YAML. Si rechaza, omitir.

### Step 4: Validate references

1. **Zotero SQLite**: try to read `$env:USERPROFILE\Zotero\zotero.sqlite` in read-only mode using SQLite query to extract items. Generate a temporary `.bib` file with Better BibTeX keys.
2. **Fallback**: if SQLite fails or is unavailable, ask user for path to a `.bib` file.
3. **Cross-check**: verify every in-text citation has a matching entry in the references list **and vice versa** (every reference must be cited in text).
   - Si hay referencias sin cita correspondiente, reportar y preguntar si eliminarlas o agregar citas.
   - Si hay citas sin referencia, agregar la entrada faltante si es posible o reportar.
4. **Author list completeness**: detectar `et al.` o `y otros` dentro de la lista de referencias. APA 7 exige listar todos los autores (hasta 20) en la lista de referencias. Si no se dispone de la lista completa, reportar como issue y preguntar al usuario.
5. **URLs/DOIs**: flag references missing DOIs or with broken URLs. Sugerir agregar URLs para obras disponibles en línea (especialmente documentos gubernamentales, pautas y artículos).

If no `.bib` is available, the skill will work with inline references and format them in APA 7 style (hanging indent, italics for titles, etc.).

### Step 5: Report issues

Report problems clearly:
- "La tabla en línea 25 no tiene un título en cursiva APA."
- "La figura en línea 40 no tiene descripción alternativa."
- "La cita '(García, 2018)' no tiene entrada en referencias."
- "El encabezado 'Metodología' debería ser Nivel 2, no Nivel 1."
- "La línea X usa **negrita** como título en vez de heading markdown. Esto impide que aparezca en el TOC."
- "La referencia 'Piaget (1991) aparece en la lista pero no está citada en el texto. Debe eliminarse o agregarse una cita."
- "La referencia 'Moreno Angarita et al. (2014)' usa 'et al.' en la lista. APA 7 exige listar todos los autores (hasta 20). Verificar la lista completa."
- "La cita '(CAST, 2011)' corresponde a una traducción de 2013. El año debe ser el de la versión consultada: (CAST, 2013). La referencia debe incluir '(Obra original publicada en 2011)'."
- "La referencia 'Ministerio de Educación Nacional (2022)' no tiene URL. Los documentos gubernamentales disponibles en línea deben incluir el enlace."
- "La referencia 'CAST (2011)' no tiene URL. Las pautas DUA están disponibles gratuitamente en https://www.cast.org."

### Step 5.5: Pre-structure validation (Stage A)

Antes de reestructurar el documento, realizar una **validación final del diagnóstico** para asegurar que todos los problemas detectados en Step 2–5 tienen una resolución planificada:

1. **Lista de verificación**: recorrer cada issue reportado en Step 5 y confirmar que:
   - ✓ El usuario fue consultado y aceptó/rechazó la corrección
   - ✓ Se tiene la información necesaria para aplicar la corrección (metadata, tipo documento, preferencias TOC/LOF)
   - ✓ Las referencias están validadas (sin `et al.` en lista, sin refs no citadas, con DOIs/URLs cuando corresponda)
2. **Resumen de estado**: generar un breve resumen con:
   - "X correcciones automáticas listas para aplicar"
   - "Y advertencias que requieren acción manual del usuario"
   - "Z issues bloqueantes (si hay, no continuar hasta resolverlos)"
3. **Regla**: Si hay issues bloqueantes (metadata crítica faltante, referencias sin validar, herramientas no instaladas), **no continuar** a Step 6. Reportar al usuario qué falta resolver.

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
toc-label: "Índice"
abstract-label: "Resumen"
keywords-label: "Palabras clave:"
runninghead: "TÍTULO ABREVIADO (MÁX. 50 CARAC.)"
---
```

**Inline validation (Stage B)**: mientras se reestructura cada sección, verificar en el momento:

- ✓ **Título del paper**: si se repite tras el resumen, debe ser `#` (Level 1), centrado y bold. Validar que no falte.
- ✓ **Cada sección principal**: confirmar que usa `#` (Level 1). Si alguna sección principal quedó como `##`, corregirla inmediatamente.
- ✓ **Cada subsección**: verificar que el nivel (Level 2, 3, 4) coincida con la jerarquía del documento. Si un Level 2 está seguido de otro Level 2 sin contenido intermedio, revisar si debería ser Level 1.
- ✓ **Cada tabla**: después de agregar el caption APA, verificar que tenga: número en **bold** (línea propia), título en *cursiva* (línea propia), pipe table debajo, y *Nota.* al final si aplica.
- ✓ **Cada figura**: verificar que tenga caption APA en el alt text `![caption](ruta)`.
- ✓ **Cada cita**: al reestructurar, verificar que el autor y año coincidan con alguna entrada en la lista de referencias. Si no, agregar la referencia faltante o corregir la cita.

**Bold-to-heading auto-conversion**: si el usuario aceptó corregir bold-as-headings, aplicar estas reglas en orden:

1. Detectar líneas que comienzan con `**texto**` (sin `#` al inicio) — son candidatas a heading. Inferir el nivel APA según el contexto:
   - Si es el título del paper repetido tras el resumen → `# Título` (Level 1, centrado, bold)
   - Si es una sección principal (Tema, Problema, Justificación, Objetivos, Antecedentes, Desarrollo, Recursos, Evaluación) → `# Título` (Level 1, centrado, bold). **Importante**: en APA 7, las secciones principales comparten el mismo nivel jerárquico que el título repetido del paper. Usar `#` para todas.
   - Si es una subsección (Objetivo General, Específicos, Primera Parte, etc.) → `## Título` (Level 2, alineado izquierda, bold)
   - Si es una sub-subsección (Videos de referencia, Rúbrica) → `### Título` (Level 3, alineado izquierda, bold italic)
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

**YouTube / online video references**: si el documento incluye enlaces a videos, generar una entrada APA 7 en la lista de referencias:

Formato APA 7 para video de YouTube:
```
Autor, A. A. [NombreCanal]. (año, Mes Día). *Título del video* [Video]. YouTube. \url{https://youtu.be/xxx}
```
Formato APA 7 para video en sitio web:
```
Autor, A. A. (año, Mes Día). *Título del video* [Video]. Nombre del sitio. \url{URL}
```
Si no se conoce el autor o la fecha exacta, reportar al usuario: "No se pudo generar la referencia APA del video 'X' porque falta el autor o la fecha de publicación. Por favor, verifica los metadatos del video."

**Important**: Las referencias de videos deben incluirse dentro de `\begin{refsect}...\end{refsect}`, igual que las demás referencias.

### Step 6.5: Pre-PDF validation (Stage C)

Antes de generar el PDF, realizar una **validación final del contenido del `.md` formateado**. Leer el archivo `{original}-apa.md` generado y verificar:

1. **YAML frontmatter**: ¿tiene todos los campos requeridos? (`title`, `author`, `institution`, `course`, `professor`, `date`, `abstract`, `keywords`, `toc`, `toc-label`, `abstract-label`, `keywords-label`). Si el usuario solicitó running head, verificar `runninghead` presente.
2. **Resumen**: ¿entre 150–250 palabras? ¿sin sangría? ¿en párrafo único?
3. **Keywords**: ¿3–5 palabras? ¿separadas por comas? ¿en minúscula?
4. **Headings**:
   - `#` solo para título repetido del paper y secciones principales (verificar que no haya `#` de más)
   - `##` para subsecciones
   - `###` para sub-subsecciones
   - No debe haber números en los headings (ej. "1. Introducción")
   - No debe haber headings vacíos
5. **Citas vs Referencias**: hacer un barrido final:
   - Extraer todos los patrones `(Autor, año)` y `Autor (año)` del texto
   - Extraer todas las entradas dentro de `\begin{refsect}...\end{refsect}`
   - Verificar correspondencia **biunívoca**: cada cita tiene su referencia y viceversa
   - Reportar discrepancias: "La cita X no tiene referencia" o "La referencia Y no se cita en el texto"
6. **Tablas**: cada tabla debe tener:
   - Número en **bold** (`**Tabla N**`)
   - Título en *cursiva* en la línea siguiente
   - Pipe table debajo
   - *Nota.* al final si aplica
   - Las celdas de la tabla no deben contener texto excesivamente largo (>80 caracteres en tablas de 3+ columnas)
7. **Figuras**: verificar que las rutas de imagen existan (si aplica)
8. **URLs**: dentro de la refsect, verificar que usen `\url{}`, no `<>`
9. **`\newpage`**: ¿hay un `\newpage` antes de `# Referencias`? Si no, agregarlo.

**Si hay errores**: corregirlos directamente en el archivo `.md` y volver a validar. No continuar a Step 7 hasta que Stage C pase sin errores.

**Si todo está correcto**: "✓ Validación pre-PDF superada. Generando PDF..."

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

### Step 7.5: Post-PDF validation (Stage D)

Después de generar el PDF, realizar una **validación de la salida** para detectar problemas que solo se manifiestan en la compilación:

1. **Revisar el log de LaTeX**: leer `{original}-apa.log` y buscar:
   - `"Error"` — si hay errores, el PDF puede estar incompleto o corrupto. Reportar y sugerir revisar el `.tex` intermedio.
   - `"Overfull \hbox"` — si hay muchos (>5) o muy severos (>50pt), revisar las tablas anchas o URLs largas. Sugerir ajustes.
   - `"Underfull \hbox"` — generalmente estético, reportar solo si hay muchos (>20).
   - `"Warning"` — revisar warnings de referencias cruzadas (`Rerun to get cross-references right`), citas no resueltas, o paquetes faltantes.
2. **Verificar páginas**: ¿el número de páginas es razonable para el tipo de documento?
   - Article típico: 5–20 páginas
   - Thesis: 30–100+ páginas
   - Essay: 3–10 páginas
   - Si el PDF tiene 0 páginas o >200 sin justificación, reportar anomalía.
3. **Verificar el PDF**: 
   - ¿El archivo existe y tiene tamaño > 0 KB?
   - ¿El nombre corresponde a `{original}-apa.pdf`?
4. **Verificar TOC**: si `toc: true`, abrir el PDF y confirmar que el TOC no está vacío (esto se puede verificar en el log: si el TOC tiene entradas, aparecerán en el `.toc` generado).
5. **Verificar minipage bug**: si en Stage 7b se detectó y corrigió minipage, confirmar en el log que ya no hay errores "Missing number" relacionados con `longtable`.
6. **Resumen de calidad**: generar un reporte breve:
   ```
   [PDF] {original}-apa.pdf
   ├─ Páginas: N
   ├─ Errores: 0
   ├─ Overfull: N (máx Xpt)
   ├─ Underfull: N
   └─ TOC: {OK|vacío}
   ```
   Si el reporte muestra problemas graves (errores, TOC vacío, 0 páginas), **no marcar como éxito** y sugerir correcciones. Si los problemas son leves (pocos overfull estéticos), reportar pero continuar.

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
