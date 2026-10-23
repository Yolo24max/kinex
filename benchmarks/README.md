---
pretty_name: Kinex Benchmark Release
language:
- en
tags:
- robotics
- benchmark
- agents
- kinex
size_categories:
- n<1K
configs:
- config_name: results
  data_files:
  - split: test
    path: episodes.jsonl
---

# Kinex Benchmark Release

[Explore the benchmark](https://huggingface.co/spaces/stacx-lab/kinex-benchmark-release)

132 tasks across **LIBERO**, **RoboTwin** and **RoboDojo**. This release contains GPT-6 Astra / high results for Kinex and Codex.

| Model | Agent and interface | Successful episodes | Episodes |
| --- | --- | ---: | ---: |
| GPT-6 Astra / high | Kinex with device API | 103 | 132 |
| GPT-6 Astra / high | Codex with native device API | 96 | 132 |
| GPT-6 Astra / high | Codex with native control API | 96 | 132 |

This release contains 396 Astra episodes. Each episode remains independently accessible. Only the three environments above are included. Original native outcomes, seeds, budgets and usage are preserved.

Control budgets are 600 action steps for LIBERO, 400–1,700 task-specific steps for RoboTwin, and 1,875 control steps for RoboDojo. Costs are API-equivalent estimates, not verified account charges.

[Results CSV](results.csv) · [Evaluation protocol](https://stacx-lab-kinex-benchmark-release.static.hf.space/#protocol/details) · [Instruction audit](https://stacx-lab-kinex-benchmark-release.static.hf.space/#audit)

The release contains episode records, recordings, session transcripts, observation images and saved artifacts. `provenance.json` identifies the pinned source publications; `asset-manifest.json` records original locations and content identities. Source recordings and artifacts are copied without modification. Transcript image references are relocated to the release assets; message content is unchanged. Original records retain their immutable evidence links.
