# Archie — Preprocessor Mapping (engine template)

> Format → tool lookup table that `/archie-ingest` consults when a source needs extraction before synthesis. The skill orchestrates; this table is the one place to swap a pick. Picks are wagers, not verdicts: swap when real friction or a new benchmark justifies it, and write the why in `log.md`.

---

## Install plan

| Tier | Tools | Rationale |
|---|---|---|
| **Set up when first needed, near-zero cost** | Firecrawl MCP (`npx -y firecrawl-mcp`, needs `FIRECRAWL_API_KEY`), markdownify (`pip install markdownify`) | URLs and saved HTML are the most common non-text sources. |
| **Lazy install on first felt friction** | MinerU, WhisperX, yt-dlp | Real install cost (pip packages, model downloads). Wait until an ingest actually needs them. Surface the command, get a nod, install. |
| **Never auto-installed** | Everything in the alternatives list | Documented for awareness. Promote by editing this table. |

## Decision rule for `/archie-ingest`

**Step 1 of any non-text ingest.** The extraction layer runs first and returns cleaned markdown before any synthesis. The agent never reads raw HTML, audio, or binary directly.

1. Look up the format below.
2. Check whether the primary tool is installed (`which <tool>`, `npx --version`, or a test import).
3. Installed → run it.
4. Not installed → surface the install command and **wait for confirmation**. No auto-install.
5. Output lands at `raw/processed/<slug>.md`; images at `raw/assets/`; the original stays immutable in `raw/`.
6. Text-native sources (`.md`, `.txt`, pasted text, transcripts) skip extraction.

## The table

| Format / pattern | Primary tool | Install | Fallbacks | Why |
|---|---|---|---|---|
| `.pdf`, `.pptx`, `.docx`, `.xlsx`, `.png`, `.jpg`, `.heic` | **MinerU** | `pip install mineru` | Docling, Marker, PyMuPDF4LLM, MarkItDown | OmniDocBench (CVPR 2025) English winner; OCR for 109 languages; Markdown + JSON output. |
| Digital-born docs with a text layer (bulk) | **Local cascade: pdftotext → textutil → soffice** | brew / macOS-native | MinerU for scans | Cheapest sufficient surface; route scan-like PDFs (low words per KB) to MinerU. |
| `.pptx` text layer | **python-pptx** or a direct zip/XML parse | `pip install python-pptx` | MinerU | soffice text export is unreliable for pptx. |
| Image piles | **Vision-agent triage first**, then extract only the artifacts | none | MinerU OCR batch (blind; avoid) | Classify before extract. |
| `.mp3`, `.m4a`, `.wav` | **WhisperX** | `pip install whisperx` | faster-whisper, Pyannote standalone | Transcription + diarization + word timestamps. |
| `.mp4`, `.mov`, YouTube URLs | **yt-dlp + WhisperX** | `pip install yt-dlp whisperx` | ffmpeg + WhisperX | Reliable audio extraction across formats. |
| `https://*` generic web URL | **Firecrawl MCP** | `npx -y firecrawl-mcp` | WebFetch (built-in), Crawl4AI (self-hosted escape hatch) | MCP-native, high success rate; WebFetch is fine for simple public pages. |
| LinkedIn / X / Instagram posts | **Manual paste** | none | paid enrichment APIs | Platform terms prohibit automated access; paste is zero-risk. |
| `.html` local file (platform exports) | **markdownify** | `pip install markdownify` | pandoc, MinerU | Deterministic, local, zero-API. |
| `.md`, `.txt`, pasted text, email threads | none, read directly | | | |
| Employer wiki / docs tools (Confluence, Google Docs, Notion, SharePoint) | **Export or paste as text** | | the tool's MCP if your org provides one | Keep the extraction surface inside the employer's tooling; never route internal docs through a personal API key. |

## Documented alternatives

- **Docling** (IBM): strong RAG-ready output and semantic chunking; includes audio. Pick when MinerU disappoints on a content type.
- **Marker**: fast, good structure fidelity, `--use_llm` for accuracy-critical docs. Pick for batch speed.
- **MarkItDown** (Microsoft): very fast on simple docs, loses structure on complex ones.
- **Crawl4AI**: open-source Playwright wrapper, self-hosted, no API key. Pick when Firecrawl's tier or vendor lock-in becomes a constraint.
- **Stagehand** / **Browser Use** / **Playwright + agent**: for JS-rendered or interactive flows where a scraper falls short.
- **faster-whisper** / **Pyannote 3.1**: lighter or higher-quality components if WhisperX feels heavy.

## Validation discipline

Re-validate a pick when a new benchmark shifts the answer, a project goes inactive or changes license, or real friction shows up. When swapping, log the why.
