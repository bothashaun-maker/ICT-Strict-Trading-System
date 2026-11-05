# Research checkpoint — 5 November 2026

**Important:** Research-only results. No indicator is independently established here as a dependable >75% winner. Do not trade borrowed funds, medical-bill money, or household necessities.

## Previous project recovered
- `ICT_Strict_Framework_v11.mq5` and `ICT_Strict_Framework_v02.mq5` (original Library files copied intact).
- Both are **MT5 indicators** from September 2026, not completed EAs/automatic trading systems.
- Strict ICT primary sources required; 2023 Silver Bullet model windows New York-local 03–04, 10–11, 14–15, fair value gaps and subsequent retracements.
- Still requires final ICT definitions (draw on liquidity, bias, sweep/market-structure shift, displacement, invalidation, stops, targets, separately-sourced Silver Arrow), compile check in MetaEditor, non-repainting historical replay, and broker tick-testing.
- **Code audit concern:** v1.1's `ServerTimeToNewYork()` derives server/GMT difference *from current time* and applies it to historical bars. Broker historical server offsets can change; historical New York sessions require broker-offset history and DST-aware conversion. Also inspect price-series indexing (`ArraySetAsSeries()` not explicitly used in shown `OnCalculate` block) before trusting signals. No MetaEditor compile test performed.

## One five-year independent calculation — RSI(2) on Bitcoin (NOT ICT)

**Source:** https://github.com/daniegitx1/btc-price-history — daily Bitstamp BTC/USD candles. Pinned source commit `0ce1b37a1a113e9e73c7181cbb5a954eccd333a3`, latest completed day 2026-11-04.

**Period:** 2021-11-05 to 2026-11-04 inclusive (1,826 daily candles). RSI(2) uses Wilder smoothing; long-only when daily close > prior 200-bar SMA (including today's close in MA) and RSI(2) < 5 or < 10. Enter *next day's open*. Exit if daily close > 5-day SMA, executed *next day's open*. An alternate exit is after at least 5 full observed candles of holding, again executed next open. One position at a time; 100% of available simulated cash; no leverage or borrowing. Modelled total friction = 0.15% each entry and each exit (0.30% approx round-trip). Any open trade closed on final available completed bar at close minus cost. Intratrade daily mark-to-market used for drawdown. This is a deliberately simple test, not broker-executable fills or live validation.

| Variant | 5-yr wins/trades | Win rate | Net return | Max drawdown | Later period (2024–Nov 2026) |
|---|---:|---:|---:|---:|---|
| RSI(2) <5, 5-day-MA exit | 18/23 | 78.3% | +51.7% | -9.8% | 11/16 = 68.8%; +25.5% |
| RSI(2) <10, 5-day-MA exit | 33/47 | 70.2% | +55.8% | -23.4% | 21/29 = 72.4%; +31.4% |
| RSI(2) <5, 5-day holding exit | 10/21 | 47.6% | +48.5% | -14.3% | 5/15 = 33.3%; +18.9% |
| RSI(2) <10, 5-day holding exit | 18/42 | 42.9% | +8.4% | -27.9% | 10/25 = 40.0%; +25.0% |

Unleveraged BTC buy/hold in the same full period (before transaction fees) = +30.9%.

**Interpretation:** One published-type oversold setting clears 75% in the full *historical* sample. On the later slice, the very same setting falls to 68.8%, and that slice includes only 16 trades. A Wilson 95% interval for 18/23 is approximately **58–90%**, not evidence the true win probability exceeds 75%. Multiple variants were examined, adding selection bias. No real-money claim is justified.

## Other externally published claims for investigation

1. `LucasXCoder/ict-silver-bullet-study`: their claimed NQ win rate is 72.1%, but returns weak, and cold ES validation loses money. Self-reported backtest, not independently audited.
2. `Steinwealth/EasyTrendline`: gold/XAUUSD 30-minute claims 86.27% (44/51), but only January–October 2025 and no external five-year validation; zero slippage reported.
3. `agrimtdk/STOCKsig`: self-reports 80.36% over ~5 years on ten Indian equities (56 trades); not independently re-run here, needs source-data and split verification.
4. `harshatangirala/smc-ict-research`: reproducible-looking public daily equity study of 44 formalized concepts; reports none significantly beats a matched random-entry benchmark. It expressly does not cover intraday Silver Bullet.
5. `Rucs0/ict-strategy-backtester`: 10-year SPY intraday proof-of-concept with negative costs-adjusted outcome. Separate formalization; not a verdict on all discretionary ICT setups.

## Critical next validation requirements
- Define a precise MT5 symbol and timeframe for the *actual* ICT indicator. For original ICT teaching, NY session time conversion is essential, including historical broker DST schedule.
- Run real 5-minute/1-minute data with tick-level spread/commission/slippage and stop-limit execution, one trade at a time and no forward-looking pivots.
- Pre-register unmodified rules, test across five full years, separate later chronological validation and different assets/brokers, report trade log, profit factor, drawdown, losing streak, exposure and confidence intervals. Check whether estimates remain positive after costs and multiple testing.
- Use **demo/paper only** while results are unverified. A 75% win rate can coexist with negative expectancy.

## Sources
- ICT original Silver Bullet video: https://www.youtube.com/watch?v=tRq1hyGGtl4
- Independent-search GitHub repositories: https://github.com/LucasXCoder/ict-silver-bullet-study ; https://github.com/Rucs0/ict-strategy-backtester ; https://github.com/harshatangirala/smc-ict-research
- >75% publisher claims: https://github.com/Steinwealth/EasyTrendline ; https://github.com/agrimtdk/STOCKsig
- Published RSI comparison: https://getalphacharts.com/backtest/rsi-strategy
- BTC source: https://github.com/daniegitx1/btc-price-history
- CFTC warning: https://www.cftc.gov/LearnAndProtect/AdvisoriesAndArticles/AITradingBots.html

The accompanying `backtest_rsi2_btc.py` uses only the Python standard library and downloads the **pinned** public CSV snapshot when run on a Windows PC with internet. It also supports `--csv path-to-file.csv` for offline replication. Its calculations were performed in an independent Javascript engine using the same documented rules during this chat; local Python file is syntax-checked, but cannot perform the live CSV download in the analysis container.