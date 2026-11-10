# THE ACTION PLAN
**ICT STRICT TRADING SYSTEM — EDITION I**  
*Source-audited development · MT5 / MQL5 · Five-year backtesting · Minimum three-month demo*

> An alert is not an edge. A backtest is not a promise. The evidence decides whether the system advances.

This is the repository-readable companion to the designed 13-page PDF `ICT_Trading_Action_Plan_Edition_I.pdf` created on 10 November 2026. **The original designed PDF has not been uploaded to GitHub.** This text preserves the key plan and milestone definitions.

## SECTION 00 — The Master Brief

| Area | Foundation |
|---|---|
| Mission | Develop a repeatable intraday trading process supported by verifiable data, not a marketed 75% claim. |
| Operator | Brother trades from home, monitoring qualifying setups in London, New York or crypto sessions. |
| Markets | Nasdaq (NQ/US100), gold (XAUUSD), major forex, BTC/USD — separately tested. |
| Platform | Windows + MetaTrader 5, MQL5, Codex, private GitHub. |
| Method | ICT-informed setups, clearly separating sourced ICT rules from research hypotheses. |
| Sequence | Complete indicator → five-year backtest → **at least three months demo**. |
| Capital | No live trades, no household/debt repayment funds at risk in development. |

## SECTION 01 — The Build We Have

- Historical indicators: `archive/ICT_Strict_Framework_v02.mq5` and `archive/ICT_Strict_Framework_v11.mq5`.
- Development indicator: `src/indicators/ICT_Strict_Framework_v12_London.mq5`.
- London premarket, London opening range, London killzone, NY premarket and opening-range study features have been prepared.
- **Unverified:** MT5 compilation; entry model completeness; five-year ICT backtest; profitable edge.

## SECTION 02 — The Session Map

New York time is the primary source of truth; convert to broker server time carefully with historical daylight-saving transitions. South Africa time changes seasonally relative to New York. Monitor London premarket and opening range, London killzone and Silver Bullet; NY premarket, equities opening range and Silver Bullet; optional afternoon setups.

The London 00:00–01:30 ET premarket is a **research-defined** observation window, not an officially verified ICT entry rule. Likewise, the premarket 07:00–09:00 ET definition from a 2026 lesson must be recorded separately from earlier extended 07:00–09:30 research.

## SECTION 03 — Research Doctrine

Use original ICT YouTube lessons and accessible original X posts. Record video URL, publication date, timestamp, chart example, exact setup qualifier, invalidation and open questions. Do not treat secondary summaries as conclusive. Source-check liquidity sweeps, displacement, structure shifts, FVG, inversion FVG, first-presented FVG, opening gap and Silver Bullet logic.

Define every proposed mechanical proxy explicitly; never silently present it as an official ICT rule. Reject future-looking pivots, repainted signals and survivorship/cherry-picking.

## SECTION 04 — The Engineering Roadmap

1. At home: install Codex, connect the private GitHub project and locate MT5/MetaEditor (real accounts and live order permissions disabled).
2. Compile v1.2 in MetaEditor; preserve full compiler errors, warnings and build number. Verify chart display on M1/M5.
3. Repair historical liquidity highs/lows so each event only sees information known at that candle. Verify NY and broker DST across years.
4. Specify candidate signals and a deterministic event log: timestamp, symbol, model ID, qualified inputs, reasons for disqualification, entry/stop/target assumptions.
5. Add repeatable regression tests and separately build an Expert Advisor backtesting harness.

## SECTION 05 — The Testing Protocol

Obtain at least five years of appropriately granular market data, with true trading hours and contract specifications per instrument. Model bid/ask spreads, commissions, slippage, fill ambiguity, news volatility, rollover and execution constraints.

Separate development data from chronologically unseen test data. Do not repeatedly optimize on the holdout. Report each instrument, session and model independently; compare model variants without concealing failures.

## SECTION 06 — The Scorecard

Every backtest should document sample dates, symbol and broker, timeframe, settings/source version, number of trades, win/loss distribution, expectancy in R, profit factor, average win/loss, maximum drawdown, longest losing streak, exposure, fees, slippage sensitivity, out-of-sample results, and uncertainty due to sample size.

**75% winning trades is a hypothesis**, not the acceptance criterion by itself. Risk-adjusted return and robustness determine whether any model proceeds.

## SECTION 07 — The Demo Protocol

After passing the historical gate, the brother follows a rule-based checklist, records all observed qualifying setups (taken and skipped), and executes **demo only**. Track actual spread, entry timing, slips, stops, targets, emotions and mistakes. No discretion outside the documented plan without recording it as a separate test.

## SECTION 08 — The Operator Calendar

Pre-session: check economic events, instrument availability, relevant prior highs/lows, session model and invalidation criteria. During approved windows: wait for a fully qualified alert, confirm the checklist, log the action. Post-session: review candidate signals, execution and screenshots. Don't demand a trade from every session.

## SECTION 09 — The 90-Day Demo Gate

Start the three-month clock **only after** both indicator and five-year historical validation are completed. Review weeks 1–4 for rule compliance and data collection; weeks 5–8 for repeatability and spread sensitivity; weeks 9–13 for stability and independent review. Extend beyond 90 days if trade count or quality is inadequate.

## SECTION 10 — Ownership & Next Actions

- **User:** when home, install Codex with assistance, connect GitHub and provide MT5 compiler output.
- **ChatGPT/research:** audit primary lessons, define and cite exact mechanical conditions and exclusions.
- **Codex/code:** compile, fix historical reference leakage, implement deterministic event ledger and backtest EA.
- **Brother/operator:** after historical acceptance, run the demo and log all candidate and executed trades.
- **Shared review:** version rules and publish reproducible test reports before introducing variants.

**The rules come first.** Indicator → historical evidence → forward demo → independent decision on whether any further risk is justified.

---
**Version:** Edition I · 10 November 2026 · Research-only, uncompiled indicator; no independently verified 75% edge.
