# Proposed model specification — UNRESOLVED until primary-source and chart audit

**State:** No model below is ready for automated trading or a win-rate claim.

| Field | Required definition | Current status |
|---|---|---|
| Market and chart | US100/NQ, XAUUSD, EURUSD, BTCUSD; M1/M5; actual symbol specs | NEED BROKER DATA |
| Session window | Exact NY local time, per setup, broker DST mapping | PARTLY SPECIFIED |
| Liquidity reference | Which highs/lows existed *before* event; exact tolerance | UNRESOLVED |
| Liquidity sweep | Intrabar touch vs bar close; buffer; time sequencing | UNRESOLVED |
| Displacement | Price action criteria or consistent *explicitly labeled proxy* | UNRESOLVED |
| Structure shift | Swing detection, bar-close rule, no future pivot info | UNRESOLVED |
| FVG | Three-candle geometry and which 'first-presented' candidate qualifies | PARTLY SPECIFIED |
| Entry | Price/limit/market timing after confirmation; expiry | UNRESOLVED |
| Stop | Structural level plus tick buffer, broker constraints | UNRESOLVED |
| Targets | Prior resting liquidity or fixed RR proxy, exit time | UNRESOLVED |
| Exclusions | Economic calendar, spread, holidays, rollover, news spikes | UNRESOLVED |
| Sizing | Defined R per trade, daily max loss, no live execution | UNRESOLVED |
| Evaluation | 5 years with strict out-of-sample, costs and CIs | NOT STARTED |

**Engineering caution:** multiple alternative definitions can be tested as different model IDs, but cannot later be conflated with official ICT rules or selected solely because one wins in-sample. Logs must retain all candidates, exclusions and ordering.
