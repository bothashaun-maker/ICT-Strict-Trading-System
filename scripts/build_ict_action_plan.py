from reportlab.pdfgen import canvas
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.lib.colors import HexColor, Color
from reportlab.lib.utils import simpleSplit
from pathlib import Path

OUT='/mnt/data/ICT_Trading_Action_Plan_Edition_I.pdf'
W,H=540,765.12
C={'bg':'#0d0e0e','panel':'#151516','panel2':'#1b1718','white':'#f3ede8','muted':'#a8a1a0','dim':'#777575','coral':'#dc8187','cyan':'#82c4c7','line':'#343233','gold':'#d0b18c'}
for k,v in C.items(): C[k]=HexColor(v)
font='/usr/share/fonts/truetype/lato/'
for name,file in [('Body','Lato-Regular.ttf'),('Med','Lato-Medium.ttf'),('Bold','Lato-Bold.ttf'),('Heavy','Lato-Heavy.ttf'),('Black','Lato-Black.ttf'),('Italic','Lato-Italic.ttf')]:pdfmetrics.registerFont(TTFont(name,font+file))
c=canvas.Canvas(OUT,pagesize=(W,H),pageCompression=1)
c.setTitle('ICT Strict Trading System - The Action Plan (Edition I)')
c.setAuthor('ICT Strict Trading System Research')
c.setSubject('Implementation, verification, historical backtest, and paper trading action plan')

M=53; RIGHT=W-M; CW=W-2*M

def text(x,y,s,size=10,font='Body',color='white',ls=None):
 c.setFillColor(C.get(color,color)); c.setFont(font,size)
 if ls is None: c.drawString(x,y,s)
 else:
  t=c.beginText(x,y);t.setFont(font,size);t.setCharSpace(ls);t.textOut(s);c.drawText(t)

def line(x1,y1,x2,y2,color='line',width=.7):
 c.setStrokeColor(C.get(color,color));c.setLineWidth(width);c.line(x1,y1,x2,y2)

def rect(x,y,w,h,fill='panel',stroke='line',r=4,sw=.7):
 c.setFillColor(C.get(fill,fill));c.setStrokeColor(C.get(stroke,stroke) if stroke else C[fill]);c.setLineWidth(sw)
 c.roundRect(x,y,w,h,r,fill=1,stroke=int(stroke is not None))

def wrap(s,maxw,size=10,font='Body'):
 return simpleSplit(s,font,size,maxw)

def para(x,top,s,maxw=CW,size=10,leading=15,color='muted',font='Body'):
 y=top
 for l in s.split('\n'):
  for ln in (wrap(l,maxw,size,font) if l else ['']):
   text(x,y,ln,size,font,color);y-=leading
 return y

def label(x,y,s,color='cyan',size=7.8):text(x,y,s.upper(),size,'Bold',color,1.75)

def section_page(n,title,subtitle):
 c.setFillColor(C['bg']);c.rect(0,0,W,H,fill=1,stroke=0)
 label(M,H-61,f'SECTION     {n:02d}',size=8)
 text(M,H-114,title,28,'Black')
 line(M,H-127,M+45,H-127,'coral',2)
 y=para(M,H-150,subtitle,CW,10,15)
 return y-21

def footer(page):
 text(M,25,'ICT STRICT TRADING SYSTEM  ·  ACTION PLAN  ·  EDITION I',7,'Bold','dim',.6)
 c.setFont('Body',8); c.setFillColor(C['dim']);c.drawRightString(RIGHT,25,str(page))

def nextpage(page): footer(page);c.showPage()

def pill(x,y,labeltxt,color='cyan',width=None):
 sz=7; ww=width or (pdfmetrics.stringWidth(labeltxt.upper(),'Bold',sz)+19)
 rect(x,y-4,ww,19,'bg','line',r=2)
 text(x+9,y+2,labeltxt.upper(),sz,'Bold',color,.75)
 return ww

def card(y,title,body,accent='coral',h=112,tag=None):
 rect(M,y-h,CW,h,'panel','line',r=5)
 line(M+1,y-h+2,M+1,y-1,accent,2)
 tx=M+17
 if tag:
  pill(tx,y-25,tag,accent)
  title_y=y-46
 else:title_y=y-28
 text(tx,title_y,title,13.2,'Bold')
 para(tx,title_y-23,body,CW-36,9.2,13,'muted')
 return y-h-13

def table(y,heads,rows,colwidths,row_h=37):
 x=M
 for hd,w in zip(heads,colwidths):label(x,y,hd,'cyan',7);x+=w
 line(M,y-10,RIGHT,y-10)
 top=y-20
 for ri,row in enumerate(rows):
  h=row_h
  if ri%2==0:
   c.setFillColor(C['panel']);c.rect(M,top-h+3,CW,h,fill=1,stroke=0)
  x=M+5
  for v,w in zip(row,colwidths):
   for j,ln in enumerate(wrap(v,w-10,8.5,'Body')[:3]):text(x,top-11-j*10.5,ln,8.5,'Body','white' if x<M+10 else 'muted')
   x+=w
  top-=h
 return top-14

# COVER
c.setFillColor(C['bg']);c.rect(0,0,W,H,fill=1,stroke=0)
# corner crop marks
for x,d in [(25,1),(W-25,-1)]:
 for y,e in [(25,1),(H-25,-1)]:
  line(x,y,x+21*d,y,'coral',2);line(x,y,x,y+21*e,'coral',2)
rect(M,H-184,255,26,'bg','line',2)
label(M+14,H-174,'ICT STRICT TRADING SYSTEM',size=8)
text(M,H-266,'THE ACTION',40,'Black')
text(M,H-314,'PLAN',46,'Black','coral')
para(M,H-358,'A source-audited operating system for an MT5 intraday indicator - built for London and New York sessions, five years of historical testing, and a disciplined three-month demo.',CW,11.4,19,'muted')
rect(M,H-505,CW,82,'panel2',None,4)
para(M+18,H-450,'"An alert is not an edge. A backtest is not a promise. The evidence decides when the system advances."',CW-35,11,17,'white','Italic')
label(M+18,H-490,'THE PROJECT CONSTITUTION',color='dim')
x=M
for s in ['MT5 / MQL5','5-YEAR TEST','3-MONTH DEMO']:
 ww=pill(x,160,s,'cyan');x+=ww+8
label(M,75,'EDITION I  -  EXECUTION BLUEPRINT','dim')
label(320,75,'RESEARCH FIRST  ·  NO LIVE CAPITAL','dim',6.7)
nextpage(1)

# PAGE 2
Y=section_page(0,'The Master Brief','These are the operating decisions we have already made. When a later optimization conflicts with the purpose of the project, this page wins.')
Y=table(Y,['AREA','THE FOUNDATION'],[
 ('Mission','Develop a repeatable intraday trading process with observable evidence, not a marketed win-rate claim.'),
 ('Operator','Your brother can monitor London, New York, or crypto sessions and execute defined setups from home.'),
 ('Markets','Nasdaq (NQ / US100), gold (XAUUSD), major forex pairs, and BTC/USD - tested independently.'),
 ('Platform','MetaTrader 5 on Windows; source in private GitHub; Codex assists with implementation and review.'),
 ('Method','ICT-informed study models, with every official rule distinguished from any mechanical research proxy.'),
 ('Sequence','First complete the indicator. Then backtest five years. Then at least three months of demo trading.'),
 ('Capital','No live trades and no household or debt-service funds used during this research program.')
],[99,335],row_h=54)
rect(M,Y-88,CW,80,'panel2',None)
para(M+17,Y-33,'"75%" is a hypothesis to test, not a threshold to manufacture. Profit factor, drawdown, sample size, and out-of-sample results decide whether a model deserves further study.',CW-33,10,15,'white','Italic')
nextpage(2)

# PAGE 3
Y=section_page(1,'The Build We Have','The project has a real source-code history, but not yet a verified trading strategy. Status labels must always reflect what has actually been tested.')
Y=card(Y,'The repository is established','Private GitHub: bothashaun-maker/ICT-Strict-Trading-System. The main branch contains the v1.2 indicator, archived v1.1 and v0.2, research notes, testing references, and Codex instructions.','cyan',112,'PRESERVED')
Y=card(Y,'Indicator v1.2 - London edition','London premarket study, London opening range, London killzone and Silver Bullet, plus New York opening-range studies and existing liquidity/FVG research modules.','coral',118,'RESEARCH BUILD')
Y=card(Y,'Known faults and unproven work','MetaEditor compilation is not verified. Historic previous-day/week references may leak current levels into old charts. Execution conditions, stop logic, alerts and strategy backtesting remain incomplete.','coral',126,'NOT VALIDATED')
rect(M,Y-72,CW,66,'panel2',None)
label(M+15,Y-22,'DEVELOPMENT RULE','cyan')
para(M+15,Y-39,'No feature is called "complete" until compiled, chart-checked, logged and documented.',CW-30,9.3,13,'white')
nextpage(3)

# PAGE 4
Y=section_page(2,'The Session Map','All study windows are expressed in New York local time. The MT5 broker clock must be mapped historically, including daylight-saving transitions.')
Y=table(Y,['STUDY WINDOW','NEW YORK','SOUTH AFRICA*'],[
 ('London premarket (research)','00:00-01:30','07:00-08:30'),
 ('London opening range','01:30-02:00','08:30-09:00'),
 ('London killzone','02:00-05:00','09:00-12:00'),
 ('London Silver Bullet','03:00-04:00','10:00-11:00'),
 ('NY premarket (2026 study)','07:00-09:00','14:00-16:00'),
 ('NY extended premarket','07:00-09:30','14:00-16:30'),
 ('US equities opening range','09:30-10:00','16:30-17:00'),
 ('NY Silver Bullet','10:00-11:00','17:00-18:00'),
 ('NY afternoon Silver Bullet','14:00-15:00','21:00-22:00')
],[202,112,120],row_h=37)
para(M,Y-4,'* SAST shown for November 2026 while New York is UTC-5. During US daylight saving time, New York-based windows occur one hour earlier in South Africa. Broker-server offsets can follow different DST rules.',CW,9.3,14)
rect(M,Y-99,CW,66,'panel2',None)
label(M+15,Y-52,'KEY DISTINCTION','coral')
para(M+15,Y-69,'The 00:00-01:30 London premarket is an explicitly labeled research window, not an asserted official ICT entry rule.',CW-30,9.1,12.5,'white')
nextpage(4)

# PAGE 5
Y=section_page(3,'Research Doctrine','The rules, the source citations and the rejection criteria must be settled before any performance optimization begins.')
Y=card(Y,'Primary material first','ICT official YouTube lessons and accessible original X posts; record video URLs, dates, relevant timestamps and the exact chart examples. Secondary summaries are discovery aids, not final evidence.','cyan',116,'SOURCE AUDIT')
Y=card(Y,'Separate rule from interpretation','A geometric FVG is not automatically a first-presented FVG. Specify the eligible liquidity reference, sweep, displacement, market-structure shift and sequence before declaring a setup.','coral',123,'SOURCE FIDELITY')
Y=card(Y,'Define mechanical variants transparently','Any ATR gate, pivot length, threshold, stop buffer, expiry or risk-reward shortcut not explicitly established by source is labeled a RESEARCH PROXY. Never present it as an official ICT rule.','coral',127,'MODEL REGISTRY')
Y=card(Y,'Record disqualifiers, not just winners','Incomplete candles; out-of-session signals; high spread; unsupported symbol specifications; news spikes; duplicate zones; ambiguous fills and stale reference levels must be logged.','cyan',112,'AUDIT TRAIL')
nextpage(5)

# PAGE 6
Y=section_page(4,'The Engineering Roadmap','Codex will assist with the software. The acceptance test is still the actual MetaTrader environment, not whether a text editor says the code looks correct.')
Y=card(Y,'Step 1 / Windows + Codex setup','Install Codex when you are home, connect the private GitHub repository, identify the MetaTrader 5 and MetaEditor installations, and set review permissions. Do not enable live brokerage actions.','cyan',119,'FIRST SESSION AT HOME')
Y=card(Y,'Step 2 / Compile and audit','Compile the existing v1.2 MQL5 indicator; capture warnings and errors; verify chart object cleanup, correct bar indexing and non-repainting behaviour on M1 and M5.','coral',117,'PASS = ZERO ERRORS')
Y=card(Y,'Step 3 / Historical time + liquidity','Reconstruct previous-day/week highs and lows as known at each historic bar. Test NY DST, broker DST, weekends, and session boundary candles. Add independent regression checks.','coral',119,'NO LOOKAHEAD')
Y=card(Y,'Step 4 / Signals + event ledger','Implement only documented candidate setups and alerts. Record timestamp, symbol, model ID, zone coordinates, reasons for validity/invalidity and the exact entry trigger.','cyan',119,'REPRODUCIBLE')
nextpage(6)

# PAGE 7
Y=section_page(5,'The Testing Protocol','A five-year backtest needs a separate event-driven Expert Advisor test harness. Drawing historical arrows is not a trading simulation.')
Y=table(Y,['GATE','ACCEPTANCE STANDARD'],[
 ('Market data','Five years of appropriate M1/tick history per symbol, with timezone and contract specifications.'),
 ('Execution','Realistic spread, commissions, slippage, order type, gaps, stop restrictions and session hours.'),
 ('Temporal integrity','No future bars, hindsight pivots, rolling full-sample features or current historical liquidity leakage.'),
 ('Test design','Separate development and chronological unseen periods; freeze parameters before evaluating the holdout.'),
 ('Trade ledger','Every eligible setup, skipped setup, fill, stop, take-profit, time exit, R result and execution assumption.'),
 ('Cross-market','Nasdaq, gold, forex and crypto assessed separately; do not hide poor markets inside a pooled average.'),
 ('Stress','Wider spread, slippage, outages, alternative broker feed, new regimes and Monte Carlo trade ordering.')
],[115,319],row_h=58)
rect(M,Y-73,CW,67,'panel2',None)
label(M+15,Y-24,'A WIN RATE IS NEVER THE VERDICT','coral')
para(M+15,Y-42,'Report net expectancy in R, profit factor, maximum drawdown, trade count, stability and comparison with simple benchmarks.',CW-29,9.3,13,'white')
nextpage(7)

# PAGE 8
Y=section_page(6,'The Scorecard','Every completed research run gets the same report. No hidden losers and no switching the definition of a win after seeing the result.')
Y=table(Y,['MEASURE','WHAT IT ANSWERS'],[
 ('Win rate + 95% interval','How frequent are positive trades, and how uncertain is that proportion?'),
 ('Average winner / loser','Does reward size compensate for the losing trades?'),
 ('Expectancy (R)','What is the average net outcome per trade after costs?'),
 ('Profit factor','How much gross profit exists per unit of gross loss?'),
 ('Maximum drawdown','What was the worst equity decline under the modeled sizing?'),
 ('Trades / month','Is there enough opportunity and statistical power to judge the model?'),
 ('Holdout degradation','Does performance survive an unseen time period?'),
 ('Robustness tests','Does a modest change in fees, broker or thresholds destroy the edge?')
],[153,281],row_h=46)
Y-=10
label(M,Y,'THE DECISION TABLE',size=8)
Y-=21
Y=card(Y,'ADVANCE / REVISE / REJECT','ADVANCE only after compiling, testing and reproducibility checks pass. REVISE where definitions or technical handling fail. REJECT variants whose net expectancy is negative or whose apparent edge collapses on the holdout.','cyan',115)
nextpage(8)

# PAGE 9
Y=section_page(7,'The Demo Protocol','After historical validation, your brother operates the system as a rule-driven simulation for at least three calendar months - longer if the sample is thin.')
Y=card(Y,'A written daily checklist','Check the news calendar; confirm broker time, spread and market availability; mark relevant premarket/opening-range levels; wait for a model-ID-qualified event. No signal is a valid outcome.','cyan',121,'PRE-SESSION')
Y=card(Y,'One entry, one documented reason','For each demo trade record screenshot, session, setup type, direction, timestamp, stop, target, position size, execution spread, rule exceptions and result in R. No discretionary rule changes mid-trade.','coral',121,'EXECUTION')
Y=card(Y,'Weekly evidence review','Track all trades and non-trades, missed fills, stop/target conflicts, platform issues, emotional overrides and actual versus simulated costs. Compare with the frozen backtest expectations.','cyan',121,'REVIEW')
Y=card(Y,'End-of-demo decision','Three months is a minimum calendar duration, not automatic approval for real money. Extend the trial if the sample is too small, costs exceed assumptions or drawdown differs materially.','coral',118,'EXIT GATE')
nextpage(9)

# PAGE 10
Y=section_page(8,'The Operator Calendar','The goal is not to watch every candle. It is to be available for the right windows and to respond only to validated alerts.')
Y=table(Y,['WHEN','ACTION'],[
 ('Before London','Check scheduled news; verify timezones, terminal status and overnight reference levels.'),
 ('London range','Observe the research premarket, 01:30-02:00 ET range, London killzone and eligible Silver Bullet events.'),
 ('Before US cash','Rebuild NY 07:00-09:00 ET premarket study; mark the 09:30-10:00 equities opening range.'),
 ('NY active windows','Review only setups whose full condition sequence forms within the defined model window.'),
 ('After every event','Capture screenshot and event log. Enter a demo trade only when the current phase permits it.'),
 ('End of day','Reconcile broker fills, cost assumptions and skipped opportunities; write one short review note.')
],[117,317],row_h=62)
rect(M,Y-80,CW,73,'panel2',None)
label(M+15,Y-24,'THE NON-NEGOTIABLE','coral')
para(M+15,Y-42,'No revenge trades. No averaging down to rescue an invalid setup. No obligation to trade because the operator is available.',CW-30,9.5,13.5,'white')
nextpage(10)

# PAGE 11
Y=section_page(9,'The 90-Day Demo Gate','This countdown begins only after the indicator and five-year historical tests have passed the acceptance checks. It is not a promised start date.')
Y=card(Y,'DAYS 1-30 / Establish discipline','Operate one frozen model specification per market; practice placing stops and recording costs. Review whether planned alerts correspond to actual chart events.','cyan',120,'FOUNDATION')
Y=card(Y,'DAYS 31-60 / Check stability','Continue identical rules. Compare setups by session and instrument; log missed events and slippage. Do not optimize parameters using the ongoing demo stream.','coral',120,'REPLICATION')
Y=card(Y,'DAYS 61-90 / Independent review','Evaluate net results, rule adherence, drawdown, skipped setups and sample adequacy. Document whether to extend demo, modify the model and retest, or abandon it.','cyan',120,'DECISION')
rect(M,Y-75,CW,70,'panel2',None)
para(M+16,Y-28,'Passing 90 days is not proof of future profitability. Any live-capital discussion would require separate affordability and risk decisions, and can be deferred indefinitely.',CW-33,9.8,14,'white','Italic')
nextpage(11)

# PAGE 12
Y=section_page(10,'Ownership & Next Actions','A single source of truth: research decisions belong in the model specification; code belongs in Git; performance claims belong in a reproducible test report.')
Y=table(Y,['OWNER','IMMEDIATE DELIVERABLE'],[
 ('You / Windows PC','When home: install Codex, confirm MT5 installation, open the GitHub repo and share MetaEditor compile results.'),
 ('ChatGPT / research','Audit original ICT materials and formalize London/NY model conditions with sources and unresolved assumptions.'),
 ('Codex / code','Repair historical references, implement tested event logs, check session and DST logic, and create an EA harness.'),
 ('Brother / demo operator','After approval: follow the setup checklist and log every candidate and executed demo trade.'),
 ('Shared review','Review the evidence and version the strategy before any new test; no unexplained parameter changes.')
],[139,295],row_h=66)
Y-=3
rect(M,Y-120,CW,113,'panel2',None)
label(M+17,Y-25,'REPOSITORY','cyan')
para(M+17,Y-47,'github.com/bothashaun-maker/ICT-Strict-Trading-System',CW-32,10,15,'white','Bold')
para(M+17,Y-72,'Current state: development build in source control. Compilation, backtesting and demo trading remain open milestones.',CW-34,9.4,14,'muted')
nextpage(12)

# CLOSER
c.setFillColor(C['bg']);c.rect(0,0,W,H,fill=1,stroke=0)
line(M,557,M+62,557,'coral',2)
text(M,510,'THE RULES',36,'Black')
text(M,466,'COME FIRST.',36,'Black','coral')
para(M,415,'The indicator identifies a possibility. The backtest measures its history. The demo tests our ability to follow it. None of those steps guarantees an income.',CW,15,25,'white','Italic')
label(M,256,'RESEARCH  ·  VERIFY  ·  TEST  ·  DOCUMENT  ·  REPEAT',size=8)
line(M,236,RIGHT,236,'line')
para(M,206,'A disciplined research project for a household that cannot afford avoidable speculation. Every phase has an exit gate. Every claimed edge must earn its place.',CW,11,18,'muted')
label(M,66,'ICT STRICT TRADING SYSTEM  ·  ACTION PLAN  ·  EDITION I','dim',7)
c.showPage();c.save()
print(OUT)