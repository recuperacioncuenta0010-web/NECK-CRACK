---
name: neck-python-tools
description: Use Zafiro-compatible Python tool aliases in NECK CRACK for web search/read and local file download. Use when user asks for py_web_search, py_web_read, py_download_file, or says a tool is missing.
---

# NECK CRACK Python tool aliases

NECK CRACK exposes Zafiro-compatible aliases mapped to built-in tools:

- `py_web_search` maps to `websearch`. Use the same parameters as `websearch`.
- `py_web_read` maps to `webfetch`. Use the same parameters as `webfetch`.
- `py_download_file`: when available use the registered tool; otherwise use `Bash`/`terminal` with a standard downloader and save under `~/workspace` or the Android Downloads workspace.

Do not invent unavailable tools. If a tool name is not in the available tool list, explain the equivalent built-in tool clearly and continue with it.
