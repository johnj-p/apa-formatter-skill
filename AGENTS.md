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

## Feedback / Improvements
- [ ] Add automatic DOI resolution via crossref API
- [ ] Full figure APA caption support
- [ ] Add word count validation (abstract 150-250)
- [ ] Direct Zotero Better BibTeX export integration
- [ ] Support for footnotes (APA allows content footnotes)
- [ ] Add appendix support in LaTeX template
