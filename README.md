# ICT Strict Trading System — MT5 Research

> **STATUS: UNCOMPILED RESEARCH BUILD / NO VALIDATED ENTRY STRATEGY**
>
> Do not trade live or claim a win rate. No five-year ICT strategy backtest has been performed.

This project preserves the earlier MQL5 ICT research indicator and develops source-audited, repeatable intraday study tools for Nasdaq, gold, forex and crypto. It is for educational/research use before any demo trading.

## Current build

- `src/indicators/ICT_Strict_Framework_v12_London.mq5`: latest source snapshot, **not verified to compile** in MetaEditor.
- `archive/ICT_Strict_Framework_v11.mq5` and `archive/ICT_Strict_Framework_v02.mq5`: recoverable earlier versions.
- `docs/ICT_v12_London_Study_Notes_and_Test_Plan.md`: existing build notes and session table.
- `docs/Research_Log_2026-11-05.md`: further official ICT lesson cross-checks, open issues, independent testing caveats.
- `docs/Model_Specification_TODO.md`: unanswered conditions to convert into a measurable signal.
- `tests/validate_ict_time_windows.py`: Python preflight script for time mapping (**not** MT5 compilation or a backtest).
- `AGENTS.md`: Codex engineering guardrails.

## Required workflow

1. **Build and compile indicator:** configure real MT5/MetaEditor installation; fix source errors without silently changing rules; verify London, NY and broker-time conversions on M1/M5; remove historical lookahead.
2. **Quantify strategy:** separately design an MQL5 Expert Advisor for mechanical simulation; obtain five years of appropriately granular broker data per instrument; include spread, slippage and commissions, realistic fills and chronological out-of-sample tests.
3. **Demo:** after testing, at least three months of documented paper execution. Extend if the trade count is insufficient or results are unstable.

This source does **not** implement a verified 75%-winning strategy. Simulated wins, especially from small samples or cherry-picked periods, are not evidence of a dependable edge.

## Repository status

This repository is the source of record for the uncompiled MT5 research build. Codex and MT5 setup are pending. Do not trade live.
