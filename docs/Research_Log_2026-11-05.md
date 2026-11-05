# Research log — 5 November 2026

## Scope and evidence standard

Official original lessons are primary sources. Transcript summaries are used as finding aids, with potential recognition errors and no chart verification. X access was blocked for direct reading; **no exhaustive X audit** is claimed.

## Finding A — 2025 opening-range and first-presented FVG distinction

Primary recording (ICT): https://www.youtube.com/watch?v=Zm9Q0NDRxoY
Timestamped transcript-based secondary reconstruction: https://bestprops.com/ict/2025-lecture-series/ict-opening-range-theory-first-presented-fvg/

The reconstruction describes 30-minute opening ranges: London 01:30–02:00, NY premarket 07:00–07:30, equity index 09:30–10:00 (all New York local). It emphasizes a selected FVG associated with (a) taking nearby liquidity, (b) displacement, and (c) an actual market-structure break. **Not simply the earliest geometric FVG in the window.** '90% inversion' appears as an attributed claim without published sample or tested method; it must not be encoded as an assumed probability.

**Needed:** inspect actual charts/audio at 10:12, 11:19–13:40, 16:48, 19:03, 20:56 and 22:18 before calling this a fully source-verified mechanical rule.

## Finding B — ICT Part 5 (9 September 2026): study range mismatch

Primary recording: https://www.youtube.com/watch?v=xnbtp_j81lI
Original caption mirror: https://prepublish.ai/youtube-transcript/xnbtp_j81lI
Summary: https://ictarchivist.com/2026/09/10/how-new-students-should-start-part-5-back-testing-properly/

The caption text refers to the **07:00–09:00 ET premarket high/low** and **09:30–10:00 ET opening range**, and emphasizes logging hypothetical entries, stops and outcomes. The pre-existing v1.2 NY premarket study currently uses **07:00–09:30**. Keep this as a separately named extended research window and add the 07:00–09:00 version for source-faithful testing. Don't retroactively relabel the longer version official.

ICT discussed studying a minimum six weeks backward and six weeks forward. This is an educational exercise, not proof that the model has positive expectancy. Our planned independent five-year test remains appropriate.

## Finding C — documented independent test vs performance claims

Independent methods and findings (not official ICT source):
https://doesitrepeat.com/blog/ict-new-students-backtest

The authors report a 57.7% hit rate for a claim sometimes described as a ~70% opening-gap midpoint occurrence. Their test also reports a negative/neutral expectancy in certain mechanical Silver Bullet proxy definitions once costs are imposed. **These are tests of explicit proxies, not the full discretionary ICT model**; don't mistake them as proof that all ICT setups fail. They show why we should test defined rules and costs, rather than trust probability marketing.

## Finding D — additional first-party video audit backlog

- ICT 2026 Opening Range Tape Reading (7 Apr): https://www.youtube.com/watch?v=gLt8kAG7noQ
- Teaching Calub Complex Opening Range Delivery (22 Jun): https://www.youtube.com/watch?v=k2QLuxMIZio
- ICT 2026 How New Students Should Start Part 5 (9 Sep): https://www.youtube.com/watch?v=xnbtp_j81lI

Presence of these original videos is verifiable. **Full frame-by-frame rule and chart audit remains incomplete**.

## Current code audit risk

`src/indicators/ICT_Strict_Framework_v12_London.mq5` lines near `DrawReferenceLiquidity` call `iHigh/iLow(_Symbol,PERIOD_D1,1)` and W1 shift 1 for the whole chart. That references the latest previous day/week when depicting earlier history, not historical previous levels per study event. This can pollute visual interpretation and any backtest built around it. There is also a user-defined, non-ICT London premarket 00:00–01:30 window. Not yet compiler-verified.

## Research sequence (no performance inference yet)

1. Validate London and NY opening range definitions and map source timestamps. 2. Define a clearly specified *research model* with disqualifiers and end-of-window expiry. 3. Compile indicator and verify deterministic, no-lookahead signal logging. 4. Develop EA and test separated in-sample/out-of-sample by instrument and session. 5. Minimum 3-month demo only after historical validation.
