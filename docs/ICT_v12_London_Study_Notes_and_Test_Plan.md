# ICT Strict Framework v1.2 — London study integration

**Dated:** 5 November 2026  
**Platform:** MetaTrader 5 / MQL5  
**Status:** Source file written and statically inspected. **NOT compiled in MetaEditor, not proven on an MT5 chart, and NOT independently backtested as a trading model.** It should not be traded live.

## What changed from the retrieved v1.1 source

1. Added a configurable **London premarket research range** (default 00:00–01:30 New York time). This is a **custom study definition**, not asserted to be a universal ICT rule.
2. Added the **London 30-minute opening range** (01:30–02:00 New York time), its observed opening price, high, and low. It is treated separately from the **London killzone** (02:00–05:00).
3. Added **New York early opening range** (07:00–07:30), **New York premarket reference range** (07:00–09:30), **equities opening range** (09:30–10:00), and **PM opening range** (13:30–14:00). These can be toggled individually.
4. Each selected study draws a price rectangle (range high/low), its opening-price line, and projected high/low levels. Data are drawn from fully closed candles only, on M1 or M5 charts. The current incomplete study window may expand as new candles close.
5. Replaced use of *today's* broker-to-UTC offset on historic timestamps with manually configured fixed, European DST, or US DST broker server modes. **Broker configuration still needs to be verified for the particular MT5 broker.** The fall-back repeated clock-hour may remain ambiguous without a UTC timestamp.
6. Explicitly set timeseries indexing, run whole-chart calculations once per newly closed candle, admit a freshly completed FVG at index 1, and prevent live retracement detection using the still-forming candle at index 0.
7. Disabled default historical sweep/sequence auditing and entry-marker arrows: the older v1.1 implementation still has unvalidated historical liquidity-reference logic, including using current previous-day/week levels when scanning historic bars. Those legacy modules have **not been made backtest-safe**.
8. Corrected a previously misplaced legacy audit classification (`delivery_reversal_aligned` was set before `delivery` was determined).

**Important:** This is an evolving *study indicator*, not an Expert Advisor, not a validated ICT model, and not a 75%-accurate signal system. No automated orders are placed.

## Exact time reference — South Africa

All strategy-time labels use **America/New_York local clock time**, including the annual US daylight-saving change. South Africa is UTC+2 all year.

| Study window | New York local time | South Africa when NY is on standard time (EST) | South Africa when NY is on daylight time (EDT) |
|---|---|---|---|
| London premarket **research** | 00:00–01:30 | 07:00–08:30 | 06:00–07:30 |
| London opening range | 01:30–02:00 | **08:30–09:00** | **07:30–08:00** |
| London killzone | 02:00–05:00 | 09:00–12:00 | 08:00–11:00 |
| London Silver Bullet | 03:00–04:00 | 10:00–11:00 | 09:00–10:00 |
| New York early opening range | 07:00–07:30 | 14:00–14:30 | 13:00–13:30 |
| NY premarket **research** | 07:00–09:30 | 14:00–16:30 | 13:00–15:30 |
| US equities opening range | 09:30–10:00 | 16:30–17:00 | 15:30–16:00 |
| New York PM opening range | 13:30–14:00 | 20:30–21:00 | 19:30–20:00 |

## Source investigation: what can and cannot be called an ICT rule

**2025 original ICT lesson:** [ICT Opening Range Theory / 1st Presented FVG Logic](https://www.youtube.com/watch?v=Zm9Q0NDRxoY). A study of the published transcript documents London 01:30–02:00, New York early 07:00–07:30, US equities 09:30–10:00, and **30-minute** opening ranges. It emphasizes that the first *qualified* presented FVG is connected to a liquidity event, displacement, and a market-structure shift — rather than simply the earliest 3-candle gap on screen. [Transcript research with time references](https://bestprops.com/ict/2025-lecture-series/ict-opening-range-theory-first-presented-fvg/). This source is a transcript-based interpretation. Verify it against ICT's actual charts before encoding exact execution rules.

**2026 primary videos to audit against historical charts:** [April 7, 2026 opening-range tape reading](https://www.youtube.com/watch?v=gLt8kAG7noQ) and [April 10, 2026 opening-range tape reading](https://www.youtube.com/watch?v=Hiq47zliJ_Y). Their official existence and titles were verified. **A comprehensive transcription/chart audit was not completed in this session**.

**Session timing context:** [ICT killzone timing reference](https://www.ictkillzone.com/ict-kill-zones). Third-party time references vary at the edges of some sessions, so the model's exact rules must be traced to the specific original lesson before making automated trading assertions.

**MT5 historical timezone limitation:** [MetaQuotes, Testing Trading Strategies](https://www.mql5.com/en/docs/runtime/testing) explains that `TimeGMT()` equals simulated `TimeTradeServer()` inside the Strategy Tester. The earlier v1.1 conversion used the *current* terminal offset when interpreting old candles, which is not safe for five-year research.

## Installation and first on-chart check (Windows, MT5)

1. Open **MetaTrader 5** → **File → Open Data Folder** → `MQL5\Indicators`.
2. Copy `ICT_Strict_Framework_v12_London.mq5` into that folder. Keep the older v1.1 file separately for comparison.
3. Open **MetaEditor** with **F4**, then open the `.mq5` file and press **F7** to compile.
4. Inspect the **Errors** tab. **Compilation has not been verified here.** If errors appear, retain the complete line/error messages. Correct them before running the indicator.
5. Back in MT5, refresh **Navigator → Indicators**, attach the indicator to an **M1 or M5** chart, and confirm the rectangles/levels against known historical NY timestamps.
6. **Calibrate broker time:** if your broker keeps UTC+2 year-round, leave `BrokerClockMode=BROKER_FIXED_UTC`, winter offset `2`. If your broker moves UTC+2 in winter / UTC+3 in summer following European DST, select `BROKER_EU_DST` and set offsets to `2` and `3`. **Do not assume these example settings fit your broker.** Some brokers use UTC+0, UTC+3, New York close, or other rules. Adjust to the actual broker and verify months in different seasons.
7. With charts on 5 November 2026, confirm a London opening range from **08:30 to 09:00 SAST** if the broker-to-UTC settings are correct. With July 2026 history, confirm **07:30 to 08:00 SAST**. The labels use New York time. Plotted chart bars remain on the broker's server clock.
8. The v1.1 legacy liquidity overlays are still present. For first visual verification, disable the legacy `DrawDrawOnLiquidity` and `DrawFVGs` options if they obscure the new studies.

## Code validation that was actually performed here

- Source built from the retrieved original `.mq5`, preserving earlier framework modules.
- Static brace/parenthesis/bracket balance checked.
- Key functions and toggle names checked for presence.
- A separate Python implementation of the clock mapping was checked against IANA `America/New_York` and `Europe/Helsinki` timezones on **14 historical spot dates**, testing fixed UTC+2 and a European-DST +2/+3 broker clock. 24 session-window conversion rows for January, July and November 2026 were generated.
- **No MetaEditor/MQL5 compiler is installed in this execution environment.** These checks do not establish compilation success or correct on-chart behavior. They do not test order placement, latency, slippage, or trading profitability.

## Investigating the first-presented FVG: next strict-model audit

For each **M1 or M5** opening-range example, the research record must capture the following before any entry alert can be described as an ICT setup:

- Which *pre-existing* highs or lows were liquidity targets? Was one actually swept?
- Which opening-range candle printed displacement? What is the *source-supported* threshold or qualitative test, if any?
- What swing structure was broken, and on what timeframe? Do not invent a pivot length or ATR requirement and call it official ICT.
- Which three-candle FVG is *associated with that break*, rather than merely appearing first?
- Is it mitigated or inverted, and what price interaction with consequent encroachment was observed?
- Does the model provide a mechanical stop, invalidation, draw on liquidity, exit and expiry? If not, no independent win-rate claim can be produced from it.

## Agreed project order

**Phase A — Indicator first:** compile v1.2 in MT5. Validate time/date mapping on M1/M5 for at least two New York seasons. Audit 2025 opening-range and 2026 examples. Finish fully explicit candidate model and event logging. No live trade signals until this is done.

**Phase B — Five-year backtest second:** 5 November 2021 through 4 November 2026, on the broker's market symbols. Obtain appropriate tick/M1 data for EURUSD, XAUUSD, US100/NQ, BTCUSD with actual instrument trade hours, daylight changes, spread, commissions, stop/limit fills, and slippage. Use an MT5 **Expert Advisor test harness** (the indicator's drawn rectangles are **not** a backtest of a trade strategy). Reserve a chronological out-of-sample segment. Reject lookahead, repeated optimization, and fragile best-case assumptions. Report sample size, win rate with uncertainty, expectancy in R, profit factor, worst drawdown, costs and per-session performance.

**Phase C — Demo third:** a minimum of **three calendar months** of logged forward trading by your brother, using the same version and rules that passed Phase B. Record missed trades and all trades, including losses. Also record execution differences. Three months alone cannot statistically verify a 75% win rate if the sample is small; extend the study when needed. Never fund live trading with household essentials, debt repayments, or medical-bill money.

**Status at end of this session:** Phase A source update and initial source audit completed. **MT5 compilation and verification outstanding. Phase B and Phase C not started.**