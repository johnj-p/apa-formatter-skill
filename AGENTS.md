# AGENTS.md — apa-formatter Skill

> **Setup en máquina nueva:** después de clonar el repo, ejecuta `.\setup.ps1` para registrar el skill en opencode.

## [2026-05-25] Initial implementation
- Created: SKILL.md, LaTeX template, CSS, CSL, doc-type helpers
- Generic apa-template.latex with conditional variables
- Zotero SQLite + .bib fallback for references
- APA 7 formatting rules: citations, references, tables, figures, headings
- CSL file: apa-7th.csl from official CSL repository

## [2026-05-25] — Processed: mi-ensayo.md
- Type: article
- Issues found: missing metadata, Johnson (2020) orphan citation, table without APA caption, figure without caption, DOI missing for Lopez (2024)
- Corrections applied: YAML frontmatter added, APA captions for table/figure, Johnson entry added, DOIs added
- LaTeX template fixed: added `authblk`, `longtable`, `\xmpquote`, `\newcounter{none}`, conditional biblatex
- PDF generated: yes (24 KB, via xelatex)
- PDF via simple pandoc (no template) works with `--pdf-engine=xelatex`

## [2026-05-25] Testing session — fixes applied
- `apa-template.latex`: `\providecommand{\xmpquote}` (UTF-8 metadata), `authblk` (affil), `longtable` + `\newcounter{none}`, conditional `biblatex`, `newtxtext` font (en-dash fix), `xurl` + `\urlstyle{same}` + `breaklinks=true` (URL breaking), `\setcounter{secnumdepth}{0}` (no numbered headings), `\hypersetup{urlcolor=black}`, keywords `$for$` loop with commas, `refsect` environment (hanging indent via `\hangindent`), abstract flush left / keywords indented
- `SKILL.md`: Updated pandoc commands, DOI format instructions (angle brackets in markdown, `\url{}` inside refsect), heading levels table (no numbering), language-specific Table/Figura, `\textit{}` usage in raw LaTeX blocks
- Test file `mi-ensayo-apa.md`: accents restored, `Tabla 1` (Spanish), DOIs as `\url{}` in refsect, `Conclusiones`/`Referencias` as Level 1 headings
- TOC support: conditional `\tableofcontents` via `toc: true/false` YAML flag; thesis forces `true`, essay/article asks user

## [2026-05-25] Language labels
- Added `abstract-label`, `keywords-label`, `toc-label` YAML variables for i18n
- Added Step 0: tool detection (pandoc, xelatex, zotero) with detailed behavior table (PDF solo si Pandoc presente, template solo si LaTeX presente)
- Template defaults to English if variables are omitted
- Test file updated with Spanish labels ("Resumen", "Palabras clave:", "Índice")

## [2026-05-29] — Demo test: test-demo-apa.md
- Type: article (exploratory study on AI in education)
- Issues found: missing placeholder image (rendimiento-comparativo.png) — created dummy
- Corrections applied: placeholder image added, LaTeX template updated (`\tightlist`, `\pandocbounded`)
- PDF generated: yes (42 KB, via xelatex + APA template)
- Notes: All invented references comply with APA 7 format (hanging indent, DOIs as `\url{}`, `\textit{}` for titles)

## Dev notes
- Commits en español, descriptivos, con bullets de cambios
- Preferir squash a un solo commit por feature antes de push

## [2026-05-29] — Processed: test-investigacion-ia.md
- Type: article
- Issues found: none (document was pre-formatted correctly)
- Corrections applied: N/A (no issues detected)
- PDF generated: yes (46 KB, via xelatex + APA template)
- Notes: Test document with invented references and figure. All citations match reference entries. Table and figure have proper APA 7 captions. Spanish labels (Resumen, Palabras clave, Índice) working correctly.

## [2026-05-29] — Processed: test-apa-completo.md
- Type: article (mixed-methods study on AI in higher education)
- Issues found: abstract ~263 words (>250); typo "introductory"; decimal subcategory numbering (1.1, 1.2); `&` instead of `y` in Spanish citations
- Corrections applied: abstract trimmed to 153 words; typo fixed; subcategories renamed to descriptive headings; `&` → `y` in all Spanish in-text citations
- PDF generated: yes (98 KB, 36 pages, via pandoc → xelatex ×2 with APA template)
- Template fixes applied:
  - Page numbering: `\setcounter{page}{2}` after title page (abstract = p.2)
  - Figures: APA 7 caption via `\caption` (bold label, italic text, period separator, position=bottom); `\listoffigures` populated correctly
  - Block quotes: APA 7 style (left indent 0.5in only, via redefined `quote` environment)
  - `\tabcolsep` reduced to 3pt + `\small` font inside longtables for tighter table fit
- Notes: Full APA 7 test document with all 5 heading levels, 6 tables, 2 figures, 27 references, 4 appendices, block quotes, statistical notation, Spanish i18n labels, TOC. Pandoc's `--pdf-engine` mode still fails with longtable + nested minipage — workaround: pandoc → .tex → xelatex ×2. Table column width warnings persist (pandoc miscalculates for 7-column tables). Tables use manual captions so `\listoftables` is empty — pending improvement.

## Reglas APA 7 — referencias a tablas/figuras
- En el texto: **sin negrita** ("en la Tabla 1", "la Figura 2 muestra")
- En el caption: número en **negrita** (`**Tabla 1**`), título en *cursiva*, nota sin formato especial

## [2026-05-29] — Auto-corrección de tablas (minipage en longtable)
- Problema: Pandoc anida `\begin{minipage}[b]{\linewidth}` dentro de columnas `p{}` en `\longtable`, causando 24+ errores "Missing number" y 199+ overfull \hbox.
- Solución: Script PowerShell en Step 7b de SKILL.md que elimina los wrappers `minipage` del `.tex` intermedio antes de xelatex.
- Resultado: 0 Missing number, 1 overfull (2.5pt, insignificante), 30 páginas.
- Template: `\footnotesize` → `\small` en `\renewenvironment{longtable}` para mejor legibilidad.
- Se agregó `\usepackage{calc}` al template (necesario para que `\real{}` en columnas `p{}` funcione correctamente en xelatex).
- Tabla B1 convertida de pipe table a LaTeX puro (`p{}` columnas fijas, sin minipage) en `test-apa-completo.md`.
- SKILL.md Step 2: advertencia para tablas con 6+ columnas o celdas >80 caracteres.
- SKILL.md Step 7: flujo recomendado ahora es pandoc → .tex → corrección → xelatex ×2.
- SKILL.md Step 7b: script de corrección automática de minipage anidado (post-pandoc, pre-xelatex).

## [2026-05-29] — Procesado: Proyecto Pensamiento computacional.md
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: bold headings instead of markdown headings, missing YAML metadata (abstract, keywords, toc), no APA captions in tables, dangling quote, citation "Alba Pastor (2013)" without reference, "Referencias" at wrong heading level
- Corrections applied: bold → ## headings, YAML frontmatter added (abstract placeholder, keywords, toc), APA captions added to 7 tables, citation adjusted to CAST (2011), dangling quote fixed, "Referencias" changed to # (Level 1), added `\usepackage{calc}` to template
- PDF generated: yes (50 KB, 13 pages, 0 overfull, 0 errors)
- Notes: The `\real{}` command used by pandoc in pipe table column widths requires the `calc` LaTeX package. Added to template.
- Template: `\listoffigures` ahora es condicional con `$if(lof)$` (controlable desde YAML).
- SKILL.md Step 3: agregada pregunta sobre Índice de Figuras (solo si hay imágenes).

## [2026-05-29] — Processed: Proyecto Pensamiento computacional.md (v2)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: bold headings instead of markdown headings (TOC vacío), missing abstract/keywords, dangling quote, missing space after quote, `^^K` chars in YouTube URL table cells
- Corrections applied: bold → proper markdown headings, abstract ~248 palabras, keywords en español, dangling quote removed, space added after quote, YouTube URLs wrapped in `<>` angle brackets, references in `\begin{refsect}` with `\textit{}`
- PDF generated: yes (50.5 KB, 0 errors, via pandoc → xelatex ×2 con APA template)
- Notes: TOC now shows all sections correctly. 0 overfull/underfull boxes. YouTube link table no longer produces ^^K errors.

## [2026-05-29] — Abstract/keywords auto-generation
- SKILL.md Step 3: added sub-item to detect missing abstract/keywords, warn the user, and offer to generate them automatically from document content
- If user accepts: generates 150-250 word descriptive abstract and representative keywords
- If user declines: leaves placeholder and requests manual completion

## [2026-05-29] — Processed: Proyecto Pensamiento computacional.md (v3)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: missing YAML metadata (abstract, keywords, toc), bold headings instead of markdown headings, empty headings (`### `, `#### `), missing APA captions in 7 tables, "Alba Pastor (2013)" should be CAST (2011), dangling quote, missing space after quote, "Referencias" at wrong heading level
- Corrections applied: YAML frontmatter added with auto-generated abstract (~190 words) and keywords, bold headings converted to proper heading levels (2-4), empty headings removed, APA captions added to all 7 tables, citation corrected to CAST (2011), dangling quote fixed, space added after quote, "Referencias" changed to `# Referencias` (Level 1) with `\newpage` before it, references wrapped in `\begin{refsect}` with `\textit{}` for titles, YouTube URLs wrapped in `<>`, refsect environment fixed (`\end{refsect}` was misspelled as `\end{refsect}`)
- PDF generated: yes (53 KB, 13 pages, 0 errors, via pandoc → xelatex ×2 con APA template)
- Notes: TOC shows all sections. 0 overfull/underfull boxes. Minipage bug detected and auto-fixed.

## [2026-05-29] — Processed: Proyecto Pensamiento computacional.md (v4 — revisión APA)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found in review: major section headings at Level 2 instead of Level 1; Piaget (1991) and Vygotsky (2009) in references but not cited in text; CAST year should be 2013 (translation consulted) not 2011; missing DOIs/URLs for CAST and MEN; "y otros" in reference list (not allowed in APA 7); ambiguous narrative citation "Alba Pastor (CAST, 2011)"; long cell text in tables; YouTube videos without formal APA references
- Corrections applied: sections changed from `##` to `#` (Level 1); Piaget and Vygotsky removed from references; CAST year changed to 2013 with original year note; URLs added for CAST and MEN; "y otros" replaced with explicit authors; narrative citation rephrased; table cell text shortened
- Skill improvements: added checks for uncited references, author list completeness (no "et al." in references), translated works citation year, missing DOIs/URLs; fixed bold-to-heading rule (sections principales → `#` Level 1); added YouTube video reference format
- Template improvements: fixed `\everypar` leak in `refsect` environment (now resets after `\end{refsect}`)
- PDF generated: yes (53 KB, 13 pages, 0 errors, via pandoc → xelatex ×2 con APA template)

## [2026-05-31] — Processed: Proyecto Pensamiento computacional.md (v5)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: missing YAML metadata, no abstract/keywords, bold-as-headings, empty headings, CAST year should be 2013 (not 2011), Piaget/Vygotsky/Moreno Angarita et al. uncited in text, "et al." in reference list, dangling quote, missing space after quote, tables without APA captions, YouTube URLs without angle brackets
- Corrections applied: YAML frontmatter with auto-generated abstract (~190 words) and keywords, bold → proper `#`/`##`/`###` headings, empty headings removed, APA captions on all 7 tables, CAST year corrected to 2013 with original work note, uncited references removed, dangling quote fixed, space added, YouTube URLs wrapped in `<>`, references in `\begin{refsect}` with `\textit{}`, headline included after abstract
- PDF generated: yes (49 KB, 13 pages, 0 errors, 0 overfull, 0 underfull, via pandoc → xelatex ×2 con APA template)
- Notes: TOC has 18 entries covering all sections. Minipage bug detected and auto-fixed. All citations match reference entries.

## [2026-05-31] — Processed: Proyecto Pensamiento computacional.md (v6)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: missing YAML metadata, no abstract/keywords, bold-as-headings, empty headings, CAST year should be 2013 (not 2011), Piaget/Vygotsky/Moreno Angarita et al. uncited in text, "et al." in reference list, dangling quote, missing space after quote, tables without APA captions, YouTube URLs without angle brackets, bookmark level mismatch (### under # without ##)
- Corrections applied: YAML frontmatter with auto-generated abstract (~195 words) and keywords, bold → proper `#`/`##`/`###` headings, empty headings removed, APA captions on all 7 tables, CAST year corrected to 2013 with original work note, uncited references removed, dangling quote fixed, space added, YouTube URLs wrapped in `<>`, references in `\begin{refsect}` with `\textit{}`, headline included after abstract, Rúbrica heading changed from `###` to `##` for consistent bookmark levels
- PDF generated: yes (49 KB, 13 pages, 0 errors, 0 overfull, 0 underfull, via pandoc → xelatex ×2 con APA template)
- Notes: TOC has 18 entries covering all sections. Minipage bug detected and auto-fixed. All citations match reference entries. No hyperref bookmark level warnings after fix.

## [2026-05-31] — Processed: Proyecto Pensamiento computacional.md (v7)
- Type: article (ATE sobre pensamiento algorítmico con cubo Rubik)
- Issues found: missing YAML metadata, no abstract/keywords, bold-as-headings, empty headings, CAST year should be 2013 (not 2011), Piaget/Vygotsky/Moreno Angarita et al. (2014) uncited in text, "et al." in reference list, dangling quote, missing space after quote, tables without APA captions, YouTube URLs without angle brackets
- Corrections applied: YAML frontmatter with auto-generated abstract (~183 words) and keywords, bold → proper `#`/`##`/`###` headings, empty headings removed, APA captions on all 7 tables, CAST year corrected to 2013 with original work note, uncited references removed, dangling quote fixed, space added, YouTube URLs wrapped in `<>`, references in `\begin{refsect}` with `\textit{}`, headline included after abstract
- PDF generated: yes (49.5 KB, 0 errors, 0 overfull, 0 underfull, via pandoc → xelatex ×2 con APA template)
- Notes: TOC has entries for all sections. Minipage bug detected and auto-fixed. All citations match reference entries.

## Feedback / Improvements
- [ ] Add automatic DOI resolution via crossref API
- [ ] Full figure APA caption support
- [ ] Add word count validation (abstract 150-250)
- [ ] Direct Zotero Better BibTeX export integration
- [ ] Support for footnotes (APA allows content footnotes)
- [ ] Add appendix support in LaTeX template
