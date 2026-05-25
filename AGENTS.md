# AGENTS.md — apa-formatter Skill

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

## Feedback / Improvements
- [ ] Add automatic DOI resolution via crossref API
- [ ] Full figure APA caption support
- [ ] Add word count validation (abstract 150-250)
- [ ] Direct Zotero Better BibTeX export integration
- [ ] Support for footnotes (APA allows content footnotes)
- [ ] Add appendix support in LaTeX template
