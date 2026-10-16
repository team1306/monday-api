# monday-api

Monday API scripts

## Getting started

```bash
git clone https://github.com/team1306/monday-api.git
cd monday-api
```

## Line endings (Windows and macOS)

This repo is edited on both Windows and macOS. The [`.gitattributes`](.gitattributes)
file sets line endings per file type, whatever each machine's `core.autocrlf`
setting is. PowerShell files (`.ps1`, `.psm1`, `.psd1`, `.ps1xml`, `.pssc`, `.psrc`)
and `.bat`/`.cmd` are always checked out with CRLF; other text files use LF.

- If a file shows as changed even though you didn't edit it, run:

  ```bash
  git add --renormalize .
  ```
