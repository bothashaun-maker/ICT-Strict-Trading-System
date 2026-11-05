# Codex Instructions — ICT Strict Trading System

## Hard requirements

- **No fabrication**: never claim a 75% success rate, profitable backtest, successful MT5 compilation or source-verified ICT rule without direct verification and reproducible evidence.
- **No live orders**: do not execute trades, move money, or connect real brokerage accounts. The project order is indicator, five-year tests, then >=3 calendar months demo.
- **Source fidelity**: differentiate a quoted/verified rule from a researcher-defined *mechanical proxy*. The term 'ICT' is not proof of an official endorsement or an objectively defined algorithm.
- **Lookahead prevention**: indicator must use completed candles and reconstruct historical liquidity levels as they were known at the time. Current `iHigh/iLow` of PERIOD_D1/ W1 shift 1 is not suitable for historical decision events.
- **Time correctness**: label every study session in America/New_York local time; broker clock offsets and DST must be configurable and historically correct; handle US vs EU transitions and broker fall-back ambiguous hour.
- **Evidence**: all nontrivial strategy rules need source URL, timestamp and clear formal condition, including disqualifiers. Do not invent arbitrary ATR thresholds, fixed pivot lengths or automatic directional bias and call them official.
- **Market realism**: add spread, commissions, slippage, contract specs, session trading hours, stop restrictions, fill ambiguities, gaps and high-impact news boundaries to EA tests.
- **Coding style**: use `.mq5` cleanly, MetaEditor compilation as mandatory pass/fail step; do not treat Python static checks as compiled MQL5 verification.

## First development task

1. Set up MT5 MetaEditor compile command or authorized GUI workflow; compile v1.2; record full errors/warnings and terminal build number.
2. Confirm study windows; note user wants London premarket and opening range, NY early/equities/PM opening ranges, Silver Bullet windows.
3. Audit `DrawReferenceLiquidity` and legacy sweeps for historical leakage; rebuild references for each historical bar using `iBarShift` or source-time-indexed rates.
4. Add *optional* NY premarket high/low study exactly **07:00–09:00 ET** per ICT Sept 9, 2026 lesson, keeping old 07:00–09:30 research range with a distinct name and labeling.
5. Produce deterministic alert event log, not just mutable chart annotations.
6. Do not label 'first FVG' as 'first presented FVG' without documented sweep/displacement/structure-break qualifiers.
7. Write regression test cases across multiple years and weekends/DST transitions.
8. Only then consider a separate backtest EA and independent walk-forward evaluation.

## Trade model boundaries

If exact displacement/structure/entry/stop/exit/expiry rules are not objectively definable from primary sources, mark them `UNRESOLVED` and require a clearly labeled research hypothesis. Don't optimize away losing examples; log all setups and skipped opportunities.