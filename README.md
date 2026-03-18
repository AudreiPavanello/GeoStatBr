# GeoStatBR

**Point-and-click geospatial analysis for jamovi — no coding required**

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/AudreiPavanello/geostatbr/releases)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![jamovi](https://img.shields.io/badge/jamovi-%E2%89%A5%202.3-orange.svg)](https://www.jamovi.org)

---

## Overview

**GeoStatBR** is a [jamovi](https://www.jamovi.org) module that brings spatial data visualization and spatial autocorrelation analysis to students and researchers — entirely through jamovi's point-and-click interface. No R, no Python, no command line. The module focuses on Brazilian geography, providing built-in shapefiles for all 27 states and all 399 municipalities of Paraná, making it ideal for public health, social science, and environmental coursework in Brazil.

---

## Features

- **Choropleth Map** — visualize any numeric variable as a color-shaded map of Brazilian states or Paraná municipalities
- **Global Moran's I** — test for global spatial autocorrelation with a Moran scatter plot and permutation-based significance test
- **Local Moran's I (LISA)** — identify spatial clusters (High-High, Low-Low) and outliers (High-Low, Low-High) with cluster and significance maps

---

## Installation

1. Go to the [**Releases**](https://github.com/AudreiPavanello/geostatbr/releases) page and download the latest `.jmo` file.
2. Open **jamovi**.
3. Click the **Modules** button (⊞) in the top-right corner.
4. Select **Install from file…** and choose the downloaded `.jmo` file.
5. The **GeoStatBR** menu will appear in the analysis ribbon.

---

## Analyses

### Choropleth Map

Produces a thematic map that color-shades geographic regions according to a numeric variable, making spatial patterns immediately visible.

**Key options:**
- Geographic level: Brazilian states or Paraná municipalities
- Join column: the column in your dataset that matches region names/codes
- Variable to map
- Color palette and number of classes

**Output:**
- Full-color choropleth map

<!-- screenshot placeholder -->

---

### Global Moran's I

Tests whether values that are geographically close to each other tend to be more similar (positive autocorrelation) or more different (negative autocorrelation) than expected by chance.

**Key options:**
- Geographic level and join column
- Variable to test
- Number of permutations for the pseudo-p-value

**Output:**
- Moran's I statistic, expected value, variance, and p-value (table)
- Moran scatter plot

<!-- screenshot placeholder -->

---

### Local Moran's I (LISA)

Decomposes the global index to identify specific locations that drive spatial autocorrelation — high-value clusters, low-value clusters, and spatial outliers.

**Key options:**
- Geographic level and join column
- Variable to test
- Significance threshold for cluster classification

**Output:**
- LISA cluster map (HH/LL/HL/LH/Not Significant)
- LISA significance map
- Summary table of cluster counts

<!-- screenshot placeholder -->

---

## Quick Start

1. Open **jamovi** and load your dataset (CSV or spreadsheet).
2. Click the **GeoStatBR** menu in the analysis ribbon.
3. Choose an analysis: **Choropleth Map**, **Global Moran's I**, or **Local Moran's I (LISA)**.
4. Select the **geographic level** (Brazilian states or Paraná municipalities).
5. Select the **join column** — the variable in your data that identifies each region (e.g., state name, IBGE municipality code).
6. Select the **variable** you want to map or test.
7. The map or results appear instantly in the output panel.

---

## How to Cite

**APA:**

> Pavanello, A. (2026). *GeoStatBR: Geospatial Analysis for jamovi* (Version 0.1.0) [Computer software]. GitHub. https://github.com/AudreiPavanello/geostatbr

**BibTeX:**

```bibtex
@software{pavanello2026geostatbr,
  author    = {Pavanello, Audrei},
  title     = {{GeoStatBR}: Geospatial Analysis for jamovi},
  year      = {2026},
  version   = {0.1.0},
  note      = {Computer software},
  url       = {https://github.com/AudreiPavanello/geostatbr}
}
```

---

## License

GeoStatBR is free software distributed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).

---

---

## Português

# GeoStatBR

**Análise geoespacial com cliques para o jamovi — sem necessidade de programação**

[![Versão](https://img.shields.io/badge/versão-0.1.0-blue.svg)](https://github.com/AudreiPavanello/geostatbr/releases)
[![Licença: GPL-3](https://img.shields.io/badge/licença-GPL--3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![jamovi](https://img.shields.io/badge/jamovi-%E2%89%A5%202.3-orange.svg)](https://www.jamovi.org)

---

## Visão Geral

**GeoStatBR** é um módulo para o [jamovi](https://www.jamovi.org) que disponibiliza visualização de dados espaciais e testes de autocorrelação espacial para estudantes e pesquisadores — inteiramente por meio da interface de apontar e clicar do jamovi. Sem R, sem Python, sem linha de comando. O módulo foca na geografia brasileira, fornecendo shapefiles embutidos para todos os 27 estados e todos os 399 municípios do Paraná, sendo ideal para disciplinas de saúde pública, ciências sociais e meio ambiente no Brasil.

---

## Funcionalidades

- **Mapa Coroplético** — visualize qualquer variável numérica como um mapa sombreado por cores dos estados brasileiros ou municípios do Paraná
- **I de Moran Global** — teste de autocorrelação espacial global com diagrama de dispersão de Moran e teste de significância por permutação
- **I de Moran Local (LISA)** — identifique clusters espaciais (Alto-Alto, Baixo-Baixo) e outliers (Alto-Baixo, Baixo-Alto) com mapas de clusters e significância

---

## Instalação

1. Acesse a página de [**Releases**](https://github.com/AudreiPavanello/geostatbr/releases) e baixe o arquivo `.jmo` mais recente.
2. Abra o **jamovi**.
3. Clique no botão **Módulos** (⊞) no canto superior direito.
4. Selecione **Instalar a partir de arquivo…** e escolha o arquivo `.jmo` baixado.
5. O menu **GeoStatBR** aparecerá na faixa de análises.

---

## Análises

### Mapa Coroplético

Produz um mapa temático que sombreia regiões geográficas com cores de acordo com uma variável numérica, tornando os padrões espaciais imediatamente visíveis.

**Principais opções:**
- Nível geográfico: estados brasileiros ou municípios do Paraná
- Coluna de junção: a coluna no seu conjunto de dados que corresponde aos nomes/códigos das regiões
- Variável a mapear
- Paleta de cores e número de classes

**Saída:**
- Mapa coroplético colorido

<!-- screenshot placeholder -->

---

### I de Moran Global

Testa se valores geograficamente próximos tendem a ser mais semelhantes (autocorrelação positiva) ou mais diferentes (autocorrelação negativa) do que o esperado pelo acaso.

**Principais opções:**
- Nível geográfico e coluna de junção
- Variável a testar
- Número de permutações para o pseudo-valor-p

**Saída:**
- Estatística I de Moran, valor esperado, variância e valor-p (tabela)
- Diagrama de dispersão de Moran

<!-- screenshot placeholder -->

---

### I de Moran Local (LISA)

Decompõe o índice global para identificar locais específicos que impulsionam a autocorrelação espacial — clusters de valores altos, clusters de valores baixos e outliers espaciais.

**Principais opções:**
- Nível geográfico e coluna de junção
- Variável a testar
- Limiar de significância para classificação dos clusters

**Saída:**
- Mapa de clusters LISA (AA/BB/AB/BA/Não Significativo)
- Mapa de significância LISA
- Tabela resumo com contagem de clusters

<!-- screenshot placeholder -->

---

## Início Rápido

1. Abra o **jamovi** e carregue seu conjunto de dados (CSV ou planilha).
2. Clique no menu **GeoStatBR** na faixa de análises.
3. Escolha uma análise: **Mapa Coroplético**, **I de Moran Global** ou **I de Moran Local (LISA)**.
4. Selecione o **nível geográfico** (estados brasileiros ou municípios do Paraná).
5. Selecione a **coluna de junção** — a variável nos seus dados que identifica cada região (ex.: nome do estado, código IBGE do município).
6. Selecione a **variável** que deseja mapear ou testar.
7. O mapa ou os resultados aparecem instantaneamente no painel de saída.

---

## Como Citar

**ABNT:**

> PAVANELLO, A. *GeoStatBR: Análise Geoespacial para o jamovi* (Versão 0.1.0) [Software]. GitHub, 2026. Disponível em: https://github.com/AudreiPavanello/geostatbr

**BibTeX:**

```bibtex
@software{pavanello2026geostatbr,
  author    = {Pavanello, Audrei},
  title     = {{GeoStatBR}: Análise Geoespacial para o jamovi},
  year      = {2026},
  version   = {0.1.0},
  note      = {Software},
  url       = {https://github.com/AudreiPavanello/geostatbr}
}
```

---

## Licença

GeoStatBR é software livre distribuído sob a [Licença Pública Geral GNU v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
