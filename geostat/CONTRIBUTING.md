# Contributing to GeoStatBr

---

## Reporting Bugs

1. Search [existing issues](https://github.com/AudreiPavanello/GeoStatBR_Module_jamovi/issues).
2. Open a new issue and include:
3. - Your jamovi version (Help > About jamovi)
   - Your operating system (Windows / macOS / Linux) and version
   - The exact steps to reproduce the problem
   - What you expected to happen vs. what actually happened
   - A screenshot or copy of any error message

---

## Requesting Features

Open an issue with the label **enhancement** and describe:

- What analysis or capability you need
- The scientific/educational use case
- Any R package or method you have in mind

Feature requests focused on Brazilian public health are especially welcome.

---

## Contributing Code

### Prerequisites

- R ≥ 4.5
- jamovi ≥ 2.7 (desktop installation)
- R packages: `jmvtools`, `devtools`, `testthat`

```r
install.packages(c("devtools", "testthat"))
remotes::install_github("jamovi/jmvtools")
```

## License

By contributing you agree that your contributions will be licensed under the
same [GPL-3 license](../LICENSE.txt) that covers GeoStatBR.
