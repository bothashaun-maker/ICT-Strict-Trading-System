//+------------------------------------------------------------------+
//| ICT_Strict_Framework_v12.mq5                                     |
//| ICT Silver Bullet + London premarket / opening-range chart study                                |
//|                                                                  |
//| SOURCE-AUDITED SCOPE OF THIS BUILD:                             |
//| - ICT 2023 Silver Bullet Time Based Trading Model               |
//| - Draw on Liquidity is treated as primary context               |
//| - Three New York-local SB windows                                |
//| - FVG formed during the window                                   |
//| - Retracement into the FVG is the execution event               |
//|                                                                  |
//| This build deliberately does NOT invent an ATR displacement      |
//| threshold, arbitrary swing length, or automatic daily bias.      |
//| Those require separate source-audited modules.                   |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0

enum ICT_BIAS
  {
   BIAS_NONE    = 0,
   BIAS_BULLISH = 1,
   BIAS_BEARISH = -1
  };

input ICT_BIAS ManualBias = BIAS_NONE;

input bool DrawSBWindows       = true;
input bool DrawDrawOnLiquidity = true;
input bool DrawFVGs            = true;
input bool DrawEntries         = false; // mechanical touch markers, not trade entries
input bool EnableAlerts        = false; // default OFF; not an automated trading system

input int LookbackBars = 3000;

// Optional minimum price-framework filter.
// Set to the appropriate value for the instrument being studied.
// 0 = display candidates without applying the framework-size filter.
input double MinimumFrameworkPriceMove = 0.0;

// Reference levels used as documented draw-on-liquidity candidates.
input bool UsePreviousDayHighLow  = true;
input bool UsePreviousWeekHighLow = true;

// Liquidity engine: display/audit mode. These are reference candidates,
// not an automatic trade-direction verdict.
input bool UseEqualHighLowLiquidity = true;
input bool UseAsianSessionLiquidity = true;
input bool UseLondonSessionLiquidity = true;
input int  EqualLevelLookbackBars = 250;
input int  EqualLevelMaxSeparationBars = 20;
input double EqualLevelTolerancePoints = 20.0;
input bool MarkLiquiditySweeps = false; // legacy sweep audit requires historic-level review
input bool MarkLiquidityLabels = true;

// v1.2 session research settings (New York clock, with DST respected).
// IMPORTANT: broker-server UTC rules MUST be checked against the broker.
// A fixed UTC+2 server, for example, uses FIXED, winter offset 2.
// A broker that moves UTC+2 winter -> UTC+3 summer at EU DST uses EU_DST.
// There is no reliable historical offset supplied by TimeGMT() in MT5 tests.
enum ICT_BROKER_CLOCK { BROKER_FIXED_UTC=0, BROKER_EU_DST=1, BROKER_US_DST=2 };
input ICT_BROKER_CLOCK BrokerClockMode = BROKER_FIXED_UTC;
input int BrokerWinterUTCOffsetHours = 2;
input int BrokerSummerUTCOffsetHours = 3;

// These are reference studies ONLY, never buy/sell signals.
// London 'premarket' 00:00-01:30 is an adjustable RESEARCH WINDOW,
// not a claim that ICT universally defines this as an official window.
input bool StudyLondonPremarket = true;
input int LondonPremarketStartNY = 0;   // minutes after NY midnight (00:00)
input int LondonPremarketEndNY = 90;    // 01:30
input bool StudyLondonOpeningRange = true;
input int LondonOpeningRangeStartNY = 90; // 01:30
input int LondonOpeningRangeEndNY = 120;  // 02:00
input bool StudyLondonKillzone = true;  // 02:00-05:00
input bool StudyNYPremarket = true;     // 07:00-09:30
input bool StudyNYEarlyOpeningRange = true; // 07:00-07:30
input bool StudyNYOpeningRangeAM = true; // 09:30-10:00
input bool StudyNYOpeningRangePM = true; // 13:30-14:00
input int StudyLookbackCalendarDays = 10;
input int StudyProjectLevelsMinutes = 180;
input bool StudyDrawRangeLabels = true;


struct SB_FVG
  {
   datetime created;
   double upper;
   double lower;
   double ce;
   int direction;
   bool entry_found;
   string window_name;
  };

SB_FVG g_fvgs[];
bool g_alert_ready=false;
datetime g_last_closed_bar=0;

//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME,"ICT Strict Framework v1.2 | London OR");
   ArrayResize(g_fvgs,0);
   if(BrokerWinterUTCOffsetHours<-12 || BrokerWinterUTCOffsetHours>14 ||
      BrokerSummerUTCOffsetHours<-12 || BrokerSummerUTCOffsetHours>14)
     { Print("ICT v1.2: invalid broker UTC offset input"); return(INIT_PARAMETERS_INCORRECT); }
   if(LondonPremarketStartNY<0 || LondonPremarketEndNY>1440 ||
      LondonPremarketStartNY>=LondonPremarketEndNY ||
      LondonOpeningRangeStartNY<0 || LondonOpeningRangeEndNY>1440 ||
      LondonOpeningRangeStartNY>=LondonOpeningRangeEndNY ||
      StudyLookbackCalendarDays<1 || StudyLookbackCalendarDays>90 ||
      StudyProjectLevelsMinutes<0 || StudyProjectLevelsMinutes>1440)
     { Print("ICT v1.2: invalid London study window/project settings"); return(INIT_PARAMETERS_INCORRECT); }
   if(PeriodSeconds(_Period)>300)
      Print("ICT v1.2: choose M1 or M5 for precise London opening-range study.");
   Print("ICT v1.2: verify broker's historical UTC offset / DST rules before using London studies.");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // Only erase our new London/NY study objects. Existing v1.1 chart
   // objects have their own names and are deliberately not touched.
   for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
     {
      string obj=ObjectName(0,i,0,-1);
      if(StringFind(obj,"ICT12_")==0) ObjectDelete(0,obj);
     }
   Comment("");
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < 10)
      return(rates_total);

   // Explicit timeseries direction; index 0 must mean current forming bar.
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

   // Recompute once per closed M1/M5 candle (not every tick).
   if(prev_calculated>0 && g_last_closed_bar==time[1]) return(rates_total);

   // Alert only when the most recent fully closed bar changes; never on attach.
   g_alert_ready=(prev_calculated>0 && g_last_closed_bar>0 && g_last_closed_bar!=time[1]);
   g_last_closed_bar=time[1];

   // New windows only inspect completed bars (index >= 1).
   // Use M1 or M5 charts; larger candle periods straddle session boundaries.
   if(PeriodSeconds(_Period)<=300)
      BuildLondonAndNYStudies(time,open,high,low,rates_total);

   ArrayResize(g_fvgs,0);

   int first = rates_total-3;
   if(LookbackBars > 0)
      first=MathMin(first,LookbackBars);

   if(DrawDrawOnLiquidity)
     {
      DrawReferenceLiquidity(time,rates_total);
      if(UseEqualHighLowLiquidity)
         DrawEqualHighLowLiquidity(time,high,low,rates_total);
      if(UseAsianSessionLiquidity)
         DrawSessionLiquidity(time,high,low,rates_total,"ASIA",0,0);
      if(UseLondonSessionLiquidity)
         DrawSessionLiquidity(time,high,low,rates_total,"LONDON",1,0);
     }

   if(MarkLiquiditySweeps)
      DetectReferenceLiquiditySweeps(time,high,low,close,rates_total);

   DrawDOLAuditPanel(high,low,rates_total);
   if(ShowLiquidityRunAudit)
      BuildExpandedLiquidityRunAudit(time,high,low,close,rates_total);

   if(ShowLiquidityRunAudit)
      BuildLiquidityRunSequence(time,high,low,close,rates_total);

   for(int i=first;i>=1;i--)
     {
      string window="";
      if(!GetSBWindow(time[i],window))
         continue;

      int direction=0;
      double upper=0,lower=0;

      // ICT FVG geometry: three-candle imbalance.
      if(low[i] > high[i+2])
        {
         direction=1;
         lower=high[i+2];
         upper=low[i];
        }
      else
      if(high[i] < low[i+2])
        {
         direction=-1;
         lower=high[i];
         upper=low[i+2];
        }

      if(direction==0)
         continue;

      // Do not claim a direction when no bias has been supplied.
      if(ManualBias!=BIAS_NONE && (int)ManualBias!=direction)
         continue;

      // Optional framework-size filter. It is OFF by default because
      // the exact instrument conversion must be explicitly configured.
      if(MinimumFrameworkPriceMove>0.0)
        {
         double projectedMove = MathAbs(upper-lower);
         if(projectedMove < MinimumFrameworkPriceMove)
            continue;
        }

      SB_FVG z;
      z.created=time[i];
      z.upper=upper;
      z.lower=lower;
      z.ce=(upper+lower)/2.0;
      z.direction=direction;
      z.entry_found=false;
      z.window_name=window;

      int n=ArraySize(g_fvgs);
      ArrayResize(g_fvgs,n+1);
      g_fvgs[n]=z;

      if(DrawFVGs)
         DrawFVG(z,n);

      // Execution is a later retracement into the FVG.
      FindFirstRetracement(i,z,time,high,low,close);
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Identify the three ICT Silver Bullet windows in NY local time.   |
//+------------------------------------------------------------------+
bool GetSBWindow(datetime server_time,string &name)
  {
   datetime ny=ServerTimeToNewYork(server_time);

   MqlDateTime dt;
   TimeToStruct(ny,dt);
   int m=dt.hour*60+dt.min;

   if(m>=180 && m<240)
     {
      name="LONDON_SB_03_04";
      return(true);
     }

   if(m>=600 && m<660)
     {
      name="NY_AM_SB_10_11";
      return(true);
     }

   if(m>=840 && m<900)
     {
      name="NY_PM_SB_14_15";
      return(true);
     }

   return(false);
  }


//+------------------------------------------------------------------+
//| Broker DST helpers. In broker wall-clock seconds, DST transition |
//| start uses the offset before the jump; end uses offset before   |
//| the fall-back. The duplicated fall-back hour is inherently      |
//| ambiguous without a broker-provided UTC timestamp; manually     |
//| inspect those dates. Most sessions studied are unaffected.      |
//+------------------------------------------------------------------+
datetime LastSundayUTC(int year,int month,int hour_utc)
  {
   MqlDateTime d; ZeroMemory(d);
   d.year=year; d.mon=month; d.day=1; d.hour=hour_utc;
   datetime first=StructToTime(d);
   TimeToStruct(first,d);
   int delta=(7-d.day_of_week)%7;
   int day=1+delta;
   while(day+7<=((month==3 || month==10) ? 31 : 30)) day+=7;
   d.day=day;
   return(StructToTime(d));
  }

int BrokerUTCOffsetAtServerTime(datetime server_time)
  {
   if(BrokerClockMode==BROKER_FIXED_UTC) return BrokerWinterUTCOffsetHours;
   MqlDateTime sd; TimeToStruct(server_time,sd);
   datetime transition_start=0,transition_end=0;
   if(BrokerClockMode==BROKER_EU_DST)
     {
      // EU transitions are at 01:00 UTC on last Sunday in March/October.
      transition_start=LastSundayUTC(sd.year,3,1)+BrokerWinterUTCOffsetHours*3600;
      transition_end=LastSundayUTC(sd.year,10,1)+BrokerSummerUTCOffsetHours*3600;
     }
   else if(BrokerClockMode==BROKER_US_DST)
     {
      transition_start=US_DST_Start(sd.year)+BrokerWinterUTCOffsetHours*3600;
      transition_end=US_DST_End(sd.year)+BrokerSummerUTCOffsetHours*3600;
     }
   if(server_time>=transition_start && server_time<transition_end)
      return BrokerSummerUTCOffsetHours;
   return BrokerWinterUTCOffsetHours;
  }

//+------------------------------------------------------------------+
//| Render completed-bar session ranges and projected high/low.      |
//| Prices can change only while the actual study window is still   |
//| forming. Historical windows are locked at their observed highs  |
//| and lows. No trading entries or probability claims are made.     |
//+------------------------------------------------------------------+
string NYDateKey(datetime ny)
  {
   MqlDateTime d; TimeToStruct(ny,d);
   return StringFormat("%04d%02d%02d",d.year,d.mon,d.day);
  }

void PutStudyTrend(string name,datetime left,double price,datetime right,color ink)
  {
   if(ObjectFind(0,name)<0)
     ObjectCreate(0,name,OBJ_TREND,0,left,price,right,price);
   else
     {
      ObjectMove(0,name,0,left,price);
      ObjectMove(0,name,1,right,price);
     }
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
  }

void RenderStudyRange(string name,string title,datetime first_bar,datetime last_bar,
                      double top,double bottom,double opening,color ink)
  {
   if(first_bar<=0 || last_bar<=0 || top<bottom || bottom<=0.0) return;
   int seconds=PeriodSeconds(_Period);
   datetime window_end=last_bar+seconds;
   if(window_end<=first_bar) window_end=first_bar+seconds;
   string rect=name+"_BOX";
   if(ObjectFind(0,rect)<0)
      ObjectCreate(0,rect,OBJ_RECTANGLE,0,first_bar,top,window_end,bottom);
   else
     {
      ObjectMove(0,rect,0,first_bar,top);
      ObjectMove(0,rect,1,window_end,bottom);
     }
   ObjectSetInteger(0,rect,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,rect,OBJPROP_BACK,true);
   ObjectSetInteger(0,rect,OBJPROP_FILL,false);
   ObjectSetInteger(0,rect,OBJPROP_WIDTH,1);
   datetime projected=window_end+StudyProjectLevelsMinutes*60;
   if(projected<=window_end) projected=window_end+60;
   PutStudyTrend(name+"_H",window_end,top,projected,ink);
   PutStudyTrend(name+"_L",window_end,bottom,projected,ink);
   PutStudyTrend(name+"_OPEN",first_bar,opening,window_end,ink);
   if(StudyDrawRangeLabels)
     {
      string tname=name+"_TEXT";
      if(ObjectFind(0,tname)<0)
         ObjectCreate(0,tname,OBJ_TEXT,0,first_bar,top);
      else ObjectMove(0,tname,0,first_bar,top);
      ObjectSetString(0,tname,OBJPROP_TEXT,title+" (study only)");
      ObjectSetInteger(0,tname,OBJPROP_COLOR,ink);
      ObjectSetInteger(0,tname,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,tname,OBJPROP_BACK,true);
     }
  }

void DrawStudyWindow(const datetime &time[],const double &open[],
                     const double &high[],const double &low[],int rates_total,
                     string tag,string title,int start_minute,int end_minute,color ink)
  {
   if(start_minute<0 || end_minute>1440 || start_minute>=end_minute) return;
   int sec=PeriodSeconds(_Period);
   int window_count=MathMin(rates_total-1,
                            (StudyLookbackCalendarDays+3)*86400/sec);
   datetime cutoff=time[1]-StudyLookbackCalendarDays*86400;
   string active_day="";
   datetime first_bar=0,last_bar=0;
   double top=-DBL_MAX,bottom=DBL_MAX,opening=0.0;
   bool active=false;
   for(int i=window_count;i>=1;i--)
     {
      if(time[i]<cutoff) continue;
      datetime ny=ServerTimeToNewYork(time[i]);
      MqlDateTime d; TimeToStruct(ny,d);
      int m=d.hour*60+d.min;
      if(m<start_minute || m>=end_minute) continue;
      string day=NYDateKey(ny);
      if(active && active_day!=day)
        {
         RenderStudyRange("ICT12_"+tag+"_"+active_day,title,
                          first_bar,last_bar,top,bottom,opening,ink);
         active=false;
        }
      if(!active)
        {
         active_day=day; first_bar=time[i]; last_bar=time[i];
         top=high[i];bottom=low[i];opening=open[i];active=true;
        }
      else
        {
         top=MathMax(top,high[i]);bottom=MathMin(bottom,low[i]);
         last_bar=time[i];
        }
     }
   if(active)
      RenderStudyRange("ICT12_"+tag+"_"+active_day,title,
                       first_bar,last_bar,top,bottom,opening,ink);
  }

void BuildLondonAndNYStudies(const datetime &time[],const double &open[],
                             const double &high[],const double &low[],int rates_total)
  {
   if(StudyLondonPremarket)
      DrawStudyWindow(time,open,high,low,rates_total,"LDN_PRE","London premarket",
                      LondonPremarketStartNY,LondonPremarketEndNY,clrSteelBlue);
   if(StudyLondonOpeningRange)
      DrawStudyWindow(time,open,high,low,rates_total,"LDN_OR","London opening range",
                      LondonOpeningRangeStartNY,LondonOpeningRangeEndNY,clrOrange);
   if(StudyLondonKillzone)
      DrawStudyWindow(time,open,high,low,rates_total,"LDN_KZ","London killzone",
                      120,300,clrMediumPurple);
   if(StudyNYPremarket)
      DrawStudyWindow(time,open,high,low,rates_total,"NY_PRE","NY premarket",
                      420,570,clrTeal);
   if(StudyNYEarlyOpeningRange)
      DrawStudyWindow(time,open,high,low,rates_total,"NY_OR_EARLY","NY early opening range",
                      420,450,clrLightSteelBlue);
   if(StudyNYOpeningRangeAM)
      DrawStudyWindow(time,open,high,low,rates_total,"NY_OR_AM","NY equity opening range",
                      570,600,clrGold);
   if(StudyNYOpeningRangePM)
      DrawStudyWindow(time,open,high,low,rates_total,"NY_OR_PM","NY PM opening range",
                      810,840,clrCrimson);
  }

//+------------------------------------------------------------------+
//| Convert broker server time to New York time.                    |
//|                                                                  |
//| Uses current terminal server/GMT relationship plus a calculated  |
//| US DST rule. This avoids a fixed South-Africa/broker offset.      |
//+------------------------------------------------------------------+
datetime ServerTimeToNewYork(datetime server_time)
  {
   // v1.2 FIX: historical broker offset by date, NEVER by today's offset.
   // MT5's TimeGMT==TimeTradeServer in its Strategy Tester, which makes
   // the old current-offset calculation invalid for historical sessions.
   int broker_hours=BrokerUTCOffsetAtServerTime(server_time);
   datetime gmt_time=server_time-broker_hours*3600;

   MqlDateTime g;
   TimeToStruct(gmt_time,g);

   int year=g.year;

   datetime dst_start=US_DST_Start(year);
   datetime dst_end=US_DST_End(year);

   // US DST is 02:00 local standard time = 07:00 UTC in March,
   // and 02:00 local daylight time = 06:00 UTC in November.
   int ny_offset_hours=-5;

   if(gmt_time>=dst_start && gmt_time<dst_end)
      ny_offset_hours=-4;

   return(gmt_time + ny_offset_hours*3600);
  }

//+------------------------------------------------------------------+
//| Second Sunday in March, 07:00 UTC                               |
//+------------------------------------------------------------------+
datetime US_DST_Start(int year)
  {
   MqlDateTime d;
   ZeroMemory(d);
   d.year=year;
   d.mon=3;
   d.day=1;
   d.hour=7;

   datetime t=StructToTime(d);
   TimeToStruct(t,d);

   // Sunday = 0
   int days_to_sunday=(7-d.day_of_week)%7;
   d.day=1+days_to_sunday+7;

   return(StructToTime(d));
  }

//+------------------------------------------------------------------+
//| First Sunday in November, 06:00 UTC                              |
//+------------------------------------------------------------------+
datetime US_DST_End(int year)
  {
   MqlDateTime d;
   ZeroMemory(d);
   d.year=year;
   d.mon=11;
   d.day=1;
   d.hour=6;

   datetime t=StructToTime(d);
   TimeToStruct(t,d);

   int days_to_sunday=(7-d.day_of_week)%7;
   d.day=1+days_to_sunday;

   return(StructToTime(d));
  }

//+------------------------------------------------------------------+
//| Draw previous-day / previous-week liquidity references.          |
//+------------------------------------------------------------------+
void DrawReferenceLiquidity(const datetime &time[],int rates_total)
  {
   datetime now=time[0];

   if(UsePreviousDayHighLow)
     {
      double pdh=iHigh(_Symbol,PERIOD_D1,1);
      double pdl=iLow(_Symbol,PERIOD_D1,1);

      DrawHLine("ICT_PDH",pdh);
      DrawHLine("ICT_PDL",pdl);
     }

   if(UsePreviousWeekHighLow)
     {
      double pwh=iHigh(_Symbol,PERIOD_W1,1);
      double pwl=iLow(_Symbol,PERIOD_W1,1);

      DrawHLine("ICT_PWH",pwh);
      DrawHLine("ICT_PWL",pwl);
     }
  }

void DrawHLine(string name,double price)
  {
   if(price<=0)
      return;

   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_HLINE,0,0,price);

   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
  }

//+------------------------------------------------------------------+
//| Draw FVG and CE.                                                 |
//+------------------------------------------------------------------+
void DrawFVG(const SB_FVG &z,int id)
  {
   string base="ICT_SB_"+IntegerToString(id)+"_"+IntegerToString((long)z.created);
   string box=base+"_FVG";
   string ce =base+"_CE";

   datetime end_time=z.created+3600;

   if(ObjectFind(0,box)<0)
      ObjectCreate(0,box,OBJ_RECTANGLE,0,z.created,z.upper,end_time,z.lower);

   ObjectSetInteger(0,box,OBJPROP_BACK,true);
   ObjectSetInteger(0,box,OBJPROP_FILL,true);

   if(ObjectFind(0,ce)<0)
      ObjectCreate(0,ce,OBJ_TREND,0,z.created,z.ce,end_time,z.ce);

   ObjectSetInteger(0,ce,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,ce,OBJPROP_WIDTH,1);
  }

//+------------------------------------------------------------------+
//| First later retracement into the FVG.                            |
//| The marker is NOT a claim that every retracement is tradable.    |
//+------------------------------------------------------------------+
void FindFirstRetracement(const int creation_index,
                          const SB_FVG &z,
                          const datetime &time[],
                          const double &high[],
                          const double &low[],
                          const double &close[])
  {
   for(int j=creation_index-1;j>=1;j--)
     {
      bool touched=(low[j]<=z.upper && high[j]>=z.lower);

      if(!touched)
         continue;

      string name="ICT_SB_ENTRY_"+IntegerToString((long)z.created);

      if(ObjectFind(0,name)>=0)
         return;

      if(DrawEntries)
        {
         ObjectCreate(0,name,OBJ_ARROW,0,time[j],close[j]);
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,
                         (z.direction>0 ? 233 : 234));
         ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
        }

      // Restrict alert to the most recent *closed* candle only.
      // No historical replay alerts when indicator first loads.
      if(EnableAlerts && j==1 && g_alert_ready)
         Alert("ICT Silver Bullet FVG retracement: ",
               z.window_name," ",
               (z.direction>0 ? "BULLISH" : "BEARISH"),
               " ",_Symbol,
               " ",TimeToString(time[j]));

      return;
     }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| v0.4 DOL audit layer                                             |
//|                                                                  |
//| This layer deliberately does NOT rank a liquidity pool as the    |
//| automatic draw on liquidity. It classifies visible candidates,   |
//| records whether they have already been traded through, and shows  |
//| nearest candidates above/below current price for manual audit.    |
//|                                                                  |
//| This is an audit/visualisation layer, not a proprietary ICT rule. |
//+------------------------------------------------------------------+
input bool ShowDOLAuditPanel = true;
input bool ShowNearestLiquidityCandidates = true;
input bool ShowLiquidityRunAudit = false; // legacy sequence audit not suitable for backtest yet
input int  LiquidityRunLookbackBars = 500;
input int  PostRunDeliveryBars = 12;
input double LiquidityRunBreakBufferPoints = 0.0;
input int SequenceMaxBarsAfterRun = 24;
input int SequenceLookbackBars = 500;
input bool ShowSequencePanel = true;
input bool ShowOpposingLiquidityAudit = true;
input bool ShowSequenceMatrix = true;
input int SequenceMatrixLookbackBars = 500;

enum LIQ_RUN_STATE
  {
   RUN_NONE = 0,
   RUN_SWEEP_REJECTION,
   RUN_BREAK_AND_HOLD,
   RUN_UNRESOLVED
  };

struct LiquidityRunEvent
  {
   datetime event_time;
   string pool_name;
   string side;
   double level;
   double event_price;
   int state;
   int delivery;
   bool fvg_after;
  };

LiquidityRunEvent g_run_events[];

void DrawDOLAuditPanel(const double &high[],const double &low[],int rates_total)
  {
   if(!ShowDOLAuditPanel || rates_total<2) return;

   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pdh=UsePreviousDayHighLow?iHigh(_Symbol,PERIOD_D1,1):0.0;
   double pdl=UsePreviousDayHighLow?iLow(_Symbol,PERIOD_D1,1):0.0;
   double pwh=UsePreviousWeekHighLow?iHigh(_Symbol,PERIOD_W1,1):0.0;
   double pwl=UsePreviousWeekHighLow?iLow(_Symbol,PERIOD_W1,1):0.0;

   double above[2]={pdh,pwh};
   double below[2]={pdl,pwl};
   string an[2]={"PDH","PWH"};
   string bn[2]={"PDL","PWL"};

   string text="ICT v0.4 DOL AUDIT\n";
   text+="Price: "+DoubleToString(price,_Digits)+"\n";
   text+="Above: ";
   bool haveA=false;
   double nearestA=DBL_MAX; string nearestAN="";
   for(int i=0;i<2;i++) if(above[i]>price && above[i]>0)
     {
      if(haveA) text+=", ";
      text+=an[i]+" "+DoubleToString(above[i],_Digits);
      haveA=true;
      if(above[i]-price<nearestA-price){nearestA=above[i];nearestAN=an[i];}
     }
   if(!haveA) text+="none";
   text+="\nBelow: ";
   bool haveB=false;
   double nearestB=-DBL_MAX; string nearestBN="";
   for(int i=0;i<2;i++) if(below[i]<price && below[i]>0)
     {
      if(haveB) text+=", ";
      text+=bn[i]+" "+DoubleToString(below[i],_Digits);
      haveB=true;
      if(price-below[i]<price-nearestB){nearestB=below[i];nearestBN=bn[i];}
     }
   if(!haveB) text+="none";
   text+="\n\nNo automatic DOL selected.";
   text+="\nCandidate levels require contextual audit.";
   if(ShowNearestLiquidityCandidates)
     {
      text+="\nNearest above: "+(nearestAN==""?"none":nearestAN);
      text+="\nNearest below: "+(nearestBN==""?"none":nearestBN);
     }
   Comment(text);
  }

//+------------------------------------------------------------------+
//| Equal highs / equal lows: liquidity CANDIDATES.                 |
//|                                                                  |
//| This deliberately uses a configurable price tolerance rather     |
//| than pretending ICT specifies one universal number of points.    |
//+------------------------------------------------------------------+
void DrawEqualHighLowLiquidity(const datetime &time[],
                               const double &high[],
                               const double &low[],
                               int rates_total)
  {
   int max_i=MathMin(rates_total-2,EqualLevelLookbackBars);
   double tol=EqualLevelTolerancePoints*_Point;
   if(tol<=0.0) return;

   int foundH=0,foundL=0;
   for(int i=max_i;i>=2;i--)
     {
      // Local pivot candidates: one bar on either side. These are
      // deliberately modest structural candidates, not a claim that
      // every pivot is an ICT liquidity pool.
      bool ph=(high[i]>=high[i-1] && high[i]>=high[i+1]);
      bool pl=(low[i]<=low[i-1] && low[i]<=low[i+1]);

      if(ph)
        {
         for(int j=i-1;j>=MathMax(1,i-EqualLevelMaxSeparationBars);j--)
           {
            bool ph2=(high[j]>=high[j-1] && high[j]>=high[j+1]);
            if(ph2 && MathAbs(high[i]-high[j])<=tol)
              {
               string n="ICT_EQH_"+IntegerToString((long)time[i]);
               if(ObjectFind(0,n)<0)
                 {
                  double level=(high[i]+high[j])/2.0;
                  DrawHLine(n,level);
                  if(MarkLiquidityLabels)
                     DrawText(n+"_TXT","EQH / BSL candidate",time[i],level);
                 }
               foundH++;
               break;
              }
           }
        }

      if(pl)
        {
         for(int j=i-1;j>=MathMax(1,i-EqualLevelMaxSeparationBars);j--)
           {
            bool pl2=(low[j]<=low[j-1] && low[j]<=low[j+1]);
            if(pl2 && MathAbs(low[i]-low[j])<=tol)
              {
               string n="ICT_EQL_"+IntegerToString((long)time[i]);
               if(ObjectFind(0,n)<0)
                 {
                  double level=(low[i]+low[j])/2.0;
                  DrawHLine(n,level);
                  if(MarkLiquidityLabels)
                     DrawText(n+"_TXT","EQL / SSL candidate",time[i],level);
                 }
               foundL++;
               break;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Session high/low references.                                    |
//| 0=Asia, 1=London. New York local time is used.                  |
//| These are references for later liquidity-run research.           |
//+------------------------------------------------------------------+
void DrawSessionLiquidity(const datetime &time[],
                          const double &high[],
                          const double &low[],
                          int rates_total,
                          string label,
                          int session_type,
                          int unused)
  {
   datetime latest_day=0;
   double hi=-DBL_MAX,lo=DBL_MAX;
   bool have=false;

   for(int i=MathMin(rates_total-1,LookbackBars);i>=0;i--)
     {
      datetime ny=ServerTimeToNewYork(time[i]);
      MqlDateTime d; TimeToStruct(ny,d);
      int mins=d.hour*60+d.min;

      bool in=false;
      if(session_type==0) in=(mins>=0 && mins<120);       // 00:00-02:00 NY
      if(session_type==1) in=(mins>=120 && mins<300);     // 02:00-05:00 NY
      if(!in) continue;

      datetime day=StringToTime(StringFormat("%04d.%02d.%02d 00:00",d.year,d.mon,d.day));
      if(latest_day!=0 && day!=latest_day)
        {
         string key=label+"_"+IntegerToString((long)latest_day);
         DrawHLine(key+"_H",hi);
         DrawHLine(key+"_L",lo);
         if(MarkLiquidityLabels)
           {
            DrawText(key+"_HT",label+" H / BSL candidate",time[i+1<rates_total?i+1:i],hi);
            DrawText(key+"_LT",label+" L / SSL candidate",time[i+1<rates_total?i+1:i],lo);
           }
         hi=-DBL_MAX; lo=DBL_MAX; have=false;
        }

      latest_day=day;
      hi=MathMax(hi,high[i]);
      lo=MathMin(lo,low[i]);
      have=true;
     }

   if(have && latest_day!=0)
     {
      string key=label+"_"+IntegerToString((long)latest_day);
      DrawHLine(key+"_H",hi);
      DrawHLine(key+"_L",lo);
     }
  }

//+------------------------------------------------------------------+
//| Sweep detector for major reference levels.                      |
//| A sweep is marked only when price trades through a level and      |
//| closes back across it on the same bar. It is a mechanical event, |
//| not a trade signal.                                               |
//+------------------------------------------------------------------+
void DetectReferenceLiquiditySweeps(const datetime &time[],
                                    const double &high[],
                                    const double &low[],
                                    const double &close[],
                                    int rates_total)
  {
   if(rates_total<3) return;

   double levels[4];
   string names[4];
   int n=0;

   if(UsePreviousDayHighLow)
     {
      levels[n]=iHigh(_Symbol,PERIOD_D1,1); names[n]="PDH"; n++;
      levels[n]=iLow(_Symbol,PERIOD_D1,1);  names[n]="PDL"; n++;
     }
   if(UsePreviousWeekHighLow)
     {
      levels[n]=iHigh(_Symbol,PERIOD_W1,1); names[n]="PWH"; n++;
      levels[n]=iLow(_Symbol,PERIOD_W1,1);  names[n]="PWL"; n++;
     }

   int limit=MathMin(rates_total-2,LookbackBars);
   for(int i=limit;i>=1;i--)
     {
      for(int k=0;k<n;k++)
        {
         double level=levels[k];
         if(level<=0) continue;

         bool buySide=(names[k]=="PDH" || names[k]=="PWH");
         bool sellSide=!buySide;

         bool sweptHigh=(buySide && high[i]>level && close[i]<level);
         bool sweptLow =(sellSide && low[i]<level && close[i]>level);

         if(sweptHigh || sweptLow)
           {
            string obj="ICT_SWEEP_"+names[k]+"_"+IntegerToString((long)time[i]);
            if(ObjectFind(0,obj)<0)
              {
               ObjectCreate(0,obj,OBJ_ARROW,0,time[i],close[i]);
               ObjectSetInteger(0,obj,OBJPROP_ARROWCODE,(sweptHigh?234:233));
               ObjectSetInteger(0,obj,OBJPROP_WIDTH,2);
               if(MarkLiquidityLabels)
                  DrawText(obj+"_TXT",(sweptHigh?"BSL sweep":"SSL sweep"),time[i],close[i]);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| v0.9 Liquidity Run Delivery Audit                                         |
//|                                                                  |
//| The July/August 2026 ICT material explicitly discusses high-     |
//| resistance liquidity-run conditions. The exact discretionary     |
//| classification is NOT reduced here to a proprietary formula.     |
//| This module therefore reports observable event states only:       |
//|   1) liquidity was pierced and rejected, or                       |
//|   2) liquidity was pierced and price held beyond it.              |
//|                                                                  |
//| These are mechanical audit labels, NOT ICT trade signals.         |
//+------------------------------------------------------------------+\n
//+------------------------------------------------------------------+
//| v0.7 expanded liquidity-pool audit                               |
//| Adds EQH/EQL and completed Asia/London session references to the |
//| same liquidity-run engine. These remain candidates for audit.    |
//+------------------------------------------------------------------+
struct LiquidityPool
  {
   datetime created;
   string name;
   string side;
   double level;
  };

LiquidityPool g_pools[];

void AddLiquidityPool(datetime created,string name,string side,double level)
  {
   if(level<=0.0) return;
   for(int i=0;i<ArraySize(g_pools);i++)
     if(g_pools[i].name==name && g_pools[i].side==side && MathAbs(g_pools[i].level-level)<=_Point)
        return;
   LiquidityPool p;
   p.created=created; p.name=name; p.side=side; p.level=level;
   int n=ArraySize(g_pools); ArrayResize(g_pools,n+1); g_pools[n]=p;
  }

void BuildEqualPools(const datetime &time[],const double &high[],const double &low[],int rates_total)
  {
   if(!UseEqualHighLowLiquidity) return;
   int max_i=MathMin(rates_total-2,EqualLevelLookbackBars);
   double tol=EqualLevelTolerancePoints*_Point;
   if(tol<=0.0) return;
   for(int i=max_i;i>=2;i--)
     {
      bool ph=(high[i]>=high[i-1] && high[i]>=high[i+1]);
      bool pl=(low[i]<=low[i-1] && low[i]<=low[i+1]);
      if(ph)
        for(int j=i-1;j>=MathMax(1,i-EqualLevelMaxSeparationBars);j--)
          if(high[j]>=high[j-1] && high[j]>=high[j+1] && MathAbs(high[i]-high[j])<=tol)
            { AddLiquidityPool(time[i],"EQH","BSL",(high[i]+high[j])/2.0); break; }
      if(pl)
        for(int j=i-1;j>=MathMax(1,i-EqualLevelMaxSeparationBars);j--)
          if(low[j]<=low[j-1] && low[j]<=low[j+1] && MathAbs(low[i]-low[j])<=tol)
            { AddLiquidityPool(time[i],"EQL","SSL",(low[i]+low[j])/2.0); break; }
     }
  }

void BuildSessionPools(const datetime &time[],const double &high[],const double &low[],int rates_total)
  {
   if(!UseAsianSessionLiquidity && !UseLondonSessionLiquidity) return;
   int limit=MathMin(rates_total-2,LookbackBars>0?LookbackBars:rates_total-2);
   for(int i=limit;i>=1;i--)
     {
      datetime ny=ServerTimeToNewYork(time[i]); MqlDateTime dt; TimeToStruct(ny,dt);
      int mins=dt.hour*60+dt.min, start=0, finish=0; string name="";
      if(UseAsianSessionLiquidity && mins>=0 && mins<120) { start=0; finish=120; name="ASIA"; }
      else if(UseLondonSessionLiquidity && mins>=120 && mins<300) { start=120; finish=300; name="LONDON"; }
      else continue;

      double sh=-DBL_MAX, sl=DBL_MAX;
      for(int j=i;j>=1;j--)
        {
         datetime nyj=ServerTimeToNewYork(time[j]); MqlDateTime dj; TimeToStruct(nyj,dj);
         if(dj.year!=dt.year || dj.mon!=dt.mon || dj.day!=dt.day) break;
         int mj=dj.hour*60+dj.min;
         if(mj<start || mj>=finish) break;
         if(high[j]>sh) sh=high[j]; if(low[j]<sl) sl=low[j];
        }
      if(sh>-DBL_MAX/2.0)
        {
         string date_tag=IntegerToString(dt.year)+IntegerToString(dt.mon)+IntegerToString(dt.day);
         int duration=(name=="ASIA" ? 7200 : 10800);
         AddLiquidityPool(time[i]+duration,name+" HIGH "+date_tag,"BSL",sh);
         AddLiquidityPool(time[i]+duration,name+" LOW "+date_tag,"SSL",sl);
        }
     }
  }

void BuildExpandedLiquidityRunAudit(const datetime &time[],const double &high[],const double &low[],const double &close[],int rates_total)
  {
   ArrayResize(g_run_events,0); ArrayResize(g_pools,0);
   if(rates_total<5) return;

   if(UsePreviousDayHighLow)
     { AddLiquidityPool(time[MathMin(rates_total-1,1)],"PDH","BSL",iHigh(_Symbol,PERIOD_D1,1)); AddLiquidityPool(time[MathMin(rates_total-1,1)],"PDL","SSL",iLow(_Symbol,PERIOD_D1,1)); }
   if(UsePreviousWeekHighLow)
     { AddLiquidityPool(time[MathMin(rates_total-1,1)],"PWH","BSL",iHigh(_Symbol,PERIOD_W1,1)); AddLiquidityPool(time[MathMin(rates_total-1,1)],"PWL","SSL",iLow(_Symbol,PERIOD_W1,1)); }
   BuildEqualPools(time,high,low,rates_total); BuildSessionPools(time,high,low,rates_total);

   int limit=MathMin(rates_total-2,MathMax(10,LiquidityRunLookbackBars));
   double buffer=LiquidityRunBreakBufferPoints*_Point;
   for(int p=0;p<ArraySize(g_pools);p++)
     {
      LiquidityPool pool=g_pools[p];
      for(int i=limit;i>=1;i--)
        {
         if(time[i]<=pool.created) continue;
         bool bsl=(pool.side=="BSL");
         if(!(bsl ? high[i]>pool.level : low[i]<pool.level)) continue;
         bool rejection=(bsl ? close[i]<pool.level : close[i]>pool.level);
         int state=rejection?RUN_SWEEP_REJECTION:RUN_UNRESOLVED, delivery=0; bool fvg_after=false;
         int end=MathMax(1,i-PostRunDeliveryBars);
         for(int j=i-1;j>=end;j--)
           {
            if(state==RUN_UNRESOLVED && ((bsl && close[j]>pool.level+buffer) || (!bsl && close[j]<pool.level-buffer))) state=RUN_BREAK_AND_HOLD;
            if(delivery==0) { if(close[j]>close[i]) delivery=1; else if(close[j]<close[i]) delivery=-1; }
           }
         int fvgEnd=MathMax(2,i-PostRunDeliveryBars);
         for(int j=i-1;j>=fvgEnd;j--) if(low[j]>high[j+2] || high[j]<low[j+2]) { fvg_after=true; break; }

         LiquidityRunEvent e;
         e.event_time=time[i]; e.pool_name=pool.name; e.side=pool.side; e.level=pool.level; e.event_price=close[i];
         e.state=state; e.delivery=delivery; e.fvg_after=fvg_after;
         int n=ArraySize(g_run_events); ArrayResize(g_run_events,n+1); g_run_events[n]=e;
         if(MarkLiquiditySweeps) DrawLiquidityRunEvent(e);
         break;
        }
     }
   DrawLiquidityRunAuditPanel();
  }

void DrawLiquidityRunEvent(const LiquidityRunEvent &e)
  {
   string base="ICT_RUN_"+e.pool_name+"_"+IntegerToString((long)e.event_time);
   if(ObjectFind(0,base)<0)
     {
      ObjectCreate(0,base,OBJ_ARROW,0,e.event_time,e.event_price);
      ObjectSetInteger(0,base,OBJPROP_ARROWCODE,(e.side=="BSL" ? 234 : 233));
      ObjectSetInteger(0,base,OBJPROP_WIDTH,2);
     }
   if(MarkLiquidityLabels)
     {
      string state="unresolved";
      if(e.state==RUN_SWEEP_REJECTION) state="sweep/rejection";
      if(e.state==RUN_BREAK_AND_HOLD) state="break/hold";
      string txt=e.pool_name+" "+e.side+" "+state;
      if(e.fvg_after) txt+=" | FVG after";
      DrawText(base+"_TXT",txt,e.event_time,e.event_price);
     }
  }

void DrawLiquidityRunAuditPanel()
  {
   string text="ICT v0.7 LIQUIDITY RUN SEQUENCE\n";
   int total=ArraySize(g_run_events);
   text+="Observed liquidity-pool run events: "+IntegerToString(total)+"\n";
   int sweeps=0,breaks=0,unresolved=0,fvgs=0;
   LiquidityRunEvent latest; bool have=false;
   for(int i=0;i<total;i++)
     {
      if(g_run_events[i].state==RUN_SWEEP_REJECTION) sweeps++;
      else if(g_run_events[i].state==RUN_BREAK_AND_HOLD) breaks++;
      else unresolved++;
      if(g_run_events[i].fvg_after) fvgs++;
      if(!have || g_run_events[i].event_time>latest.event_time) { latest=g_run_events[i]; have=true; }
     }
   text+="Sweep/rejection: "+IntegerToString(sweeps)+"\n";
   text+="Break/hold: "+IntegerToString(breaks)+"\n";
   text+="Unresolved: "+IntegerToString(unresolved)+"\n";
   text+="Runs followed by FVG: "+IntegerToString(fvgs)+"\n";
   if(have)
     {
      string state="UNRESOLVED";
      if(latest.state==RUN_SWEEP_REJECTION) state="SWEEP / REJECTION";
      if(latest.state==RUN_BREAK_AND_HOLD) state="BREAK / HOLD";
      text+="\nLatest: "+latest.pool_name+" "+latest.side;
      text+="\nState: "+state;
      text+="\nTime: "+TimeToString(latest.event_time);
      text+="\nFVG after: "+(latest.fvg_after?"YES":"NO");
     }
   text+="\n\nAudit only — no automatic DOL or trade signal.";
   Comment(text);
  }

enum LIQ_RELATION
  {
   LIQ_REL_NONE = 0,
   LIQ_TOWARD_OPPOSING,
   LIQ_AWAY_FROM_OPPOSING
  };

struct LiquiditySequence
  {
   datetime run_time;
   string pool_name;
   string side;
   int run_state;
   double run_price;
   int delivery;
   string opposing_name;
   double opposing_level;
   int relation;
   double distance_to_opposing;
   double max_delivery_progress;
   bool opposing_reached;
   bool opposing_approached;
   datetime fvg_time;
   double fvg_upper;
   double fvg_lower;
   double fvg_ce;
   int fvg_direction;
   bool delivery_reversal_aligned;
   bool fvg_delivery_aligned;
   datetime retrace_time;
   bool complete;
  };

LiquiditySequence g_sequences[];

int FindNearestOpposingPool(const LiquidityRunEvent &e, int delivery, double &level, string &name)
  {
   level=0.0; name="";
   string wanted=(e.side=="BSL" ? "SSL" : "BSL");
   double best=DBL_MAX; int found=-1;
   for(int i=0;i<ArraySize(g_pools);i++)
     {
      LiquidityPool p=g_pools[i];
      if(p.side!=wanted || p.level<=0.0 || p.created>e.event_time) continue;
      if(delivery>0 && p.level<=e.event_price) continue;
      if(delivery<0 && p.level>=e.event_price) continue;
      double d=MathAbs(p.level-e.event_price);
      if(d<best) { best=d; level=p.level; name=p.name; found=i; }
     }
   return(found);
  }

void BuildLiquidityRunSequence(const datetime &time[],
                               const double &high[],
                               const double &low[],
                               const double &close[],
                               int rates_total)
  {
   ArrayResize(g_sequences,0);
   int total=ArraySize(g_run_events);
   if(total==0) return;

   for(int eidx=0;eidx<total;eidx++)
     {
      LiquidityRunEvent e=g_run_events[eidx];
      if(e.state==RUN_UNRESOLVED) continue;

      int event_index=-1;
      int limit=MathMin(rates_total-3,MathMax(10,SequenceLookbackBars));
      for(int i=limit;i>=1;i--)
        {
         if(time[i]==e.event_time)
           { event_index=i; break; }
        }
      if(event_index<1) continue;

      LiquiditySequence q;
      q.run_time=e.event_time;
      q.pool_name=e.pool_name;
      q.side=e.side;
      q.run_state=e.state;
      q.run_price=e.event_price;
      q.delivery=0;
      q.opposing_name="";
      q.opposing_level=0.0;
      q.relation=LIQ_REL_NONE;
      q.distance_to_opposing=0.0;
      q.max_delivery_progress=0.0;
      q.opposing_reached=false;
      q.opposing_approached=false;
      q.fvg_time=0;
      q.fvg_upper=0.0;
      q.fvg_lower=0.0;
      q.fvg_ce=0.0;
      q.fvg_direction=0;
      q.delivery_reversal_aligned=false;
      q.fvg_delivery_aligned=false;
      q.retrace_time=0;
      q.complete=false;

      int end=MathMax(2,event_index-SequenceMaxBarsAfterRun);
      int fvg_index=-1;

      // Observable post-run delivery: first directional close relative
      // to the event close. This is descriptive, not a bias decision.
      for(int j=event_index-1;j>=end;j--)
        {
         if(close[j]>close[event_index]) { q.delivery=1; break; }
         if(close[j]<close[event_index]) { q.delivery=-1; break; }
        }

      q.delivery_reversal_aligned=((e.side=="BSL" && q.delivery<0) ||
                                   (e.side=="SSL" && q.delivery>0));

      // Compare observed delivery with the nearest opposing liquidity
      // candidate that already existed at the time of the run. This is
      // descriptive only: it does not select a DOL or define resistance.
      if(ShowOpposingLiquidityAudit && q.delivery!=0)
        {
         double opp_level=0.0; string opp_name="";
         if(FindNearestOpposingPool(e,q.delivery,opp_level,opp_name)>=0)
           {
            q.opposing_level=opp_level; q.opposing_name=opp_name;
            q.distance_to_opposing=MathAbs(opp_level-q.run_price);
            bool toward=(q.delivery>0 && opp_level>q.run_price) ||
                        (q.delivery<0 && opp_level<q.run_price);
            q.relation=(toward?LIQ_TOWARD_OPPOSING:LIQ_AWAY_FROM_OPPOSING);

            // Measure only what price actually did after the run.
            // Progress is normalized to the run-to-opposing-pool distance.
            if(toward && q.distance_to_opposing>0.0)
              {
               int end_prog=MathMax(1,event_index-SequenceMaxBarsAfterRun);
               double max_progress=0.0;
               for(int j=event_index-1;j>=end_prog;j--)
                 {
                  double progress=(q.delivery>0 ?
                                   (high[j]-q.run_price)/q.distance_to_opposing :
                                   (q.run_price-low[j])/q.distance_to_opposing);
                  if(progress>max_progress) max_progress=progress;
                  if((q.delivery>0 && high[j]>=opp_level) ||
                     (q.delivery<0 && low[j]<=opp_level))
                     q.opposing_reached=true;
                 }
               q.max_delivery_progress=MathMax(0.0,max_progress);
               // 0 < progress < 1 means the pool was approached but not reached.
               q.opposing_approached=(q.max_delivery_progress>0.0 && !q.opposing_reached);
              }
           }
        }

      // First post-run FVG that forms inside a defined SB window.
      for(int j=event_index-1;j>=end;j--)
        {
         string sbwin="";
         if(!GetSBWindow(time[j],sbwin)) continue;

         int dir=0;
         double upper=0.0,lower=0.0;
         if(low[j]>high[j+2])
           {
            dir=1;
            lower=high[j+2];
            upper=low[j];
           }
         else if(high[j]<low[j+2])
           {
            dir=-1;
            lower=high[j];
            upper=low[j+2];
           }

         if(dir==0) continue;

         fvg_index=j;
         q.fvg_time=time[j];
         q.fvg_upper=upper;
         q.fvg_lower=lower;
         q.fvg_ce=(upper+lower)/2.0;
         q.fvg_direction=dir;
         q.fvg_delivery_aligned=(q.delivery!=0 && dir==q.delivery);
         break;
        }

      // First later touch of the sequence FVG.
      if(fvg_index>=1)
        {
         for(int k=fvg_index-1;k>=1;k--)
           {
            if(low[k]<=q.fvg_upper && high[k]>=q.fvg_lower)
              {
               q.retrace_time=time[k];
               q.complete=true;
               break;
              }
           }
        }

      int sz=ArraySize(g_sequences);
      ArrayResize(g_sequences,sz+1);
      g_sequences[sz]=q;
      DrawSequenceEvent(q);
     }

   if(ShowSequencePanel)
      DrawSequencePanel();
  }

void DrawSequenceEvent(const LiquiditySequence &q)
  {
   string base="ICT_SEQ_"+q.pool_name+"_"+IntegerToString((long)q.run_time);
   string txt=q.pool_name+" "+q.side+" -> ";
   if(q.delivery>0) txt+="UP delivery";
   else if(q.delivery<0) txt+="DOWN delivery";
   else txt+="no delivery";
   if(q.opposing_name!="")
     {
      if(q.relation==LIQ_TOWARD_OPPOSING) txt+=" -> toward "+q.opposing_name;
      else if(q.relation==LIQ_AWAY_FROM_OPPOSING) txt+=" -> away from "+q.opposing_name;
     }
   if(q.fvg_time>0) txt+=" -> SB FVG";
   else txt+=" -> no SB FVG";
   if(q.complete) txt+=" -> RETRACEMENT";

   if(MarkLiquidityLabels)
      DrawText(base+"_TXT",txt,q.run_time,q.fvg_time>0?q.fvg_ce:q.run_price);
  }

string SequenceStateName(int state)
  {
   if(state==RUN_SWEEP_REJECTION) return "SWEEP";
   if(state==RUN_BREAK_AND_HOLD) return "BREAK";
   return "UNRESOLVED";
  }

string SequenceDeliveryName(int delivery)
  {
   if(delivery>0) return "UP";
   if(delivery<0) return "DOWN";
   return "NONE";
  }

string SequenceOutcomeName(const LiquiditySequence &q)
  {
   if(q.opposing_reached) return "REACHED";
   if(q.opposing_approached) return "APPROACHED";
   if(q.opposing_name=="") return "NO TARGET";
   return "NOT REACHED";
  }

string BuildSequenceMatrixText()
  {
   if(!ShowSequenceMatrix) return "";

   // Exact observed sequence classes. This is a descriptive cross-tab,
   // not a ranking, probability model, or trading rule.
   string keys[96];
   int counts[96];
   ArrayInitialize(counts,0);
   int key_count=0;

   for(int i=0;i<ArraySize(g_sequences);i++)
     {
      LiquiditySequence q=g_sequences[i];
      int bars_from_now=iBarShift(_Symbol,_Period,q.run_time,false);
      if(SequenceMatrixLookbackBars>0 &&
         (bars_from_now<0 || bars_from_now>SequenceMatrixLookbackBars)) continue;

      string key=q.side+" "+SequenceStateName(q.run_state)+" -> "+SequenceDeliveryName(q.delivery);
      key+=" -> "+SequenceOutcomeName(q);
      key+=" -> "+(q.fvg_time>0?(q.fvg_delivery_aligned?"FVG-A":"FVG-N"):"NO-FVG");
      key+=" -> "+(q.complete?"RETRACE":"NO-RETRACE");

      int found=-1;
      for(int k=0;k<key_count;k++)
         if(keys[k]==key) { found=k; break; }

      if(found<0 && key_count<96)
        {
         keys[key_count]=key;
         counts[key_count]=1;
         key_count++;
        }
      else if(found>=0)
         counts[found]++;
     }

   string text="\nOBSERVED SEQUENCE MATRIX";
   text+="\nBSL/SSL × state × delivery × outcome × FVG × retrace";
   int shown=0;
   for(int k=0;k<key_count;k++)
     {
      if(counts[k]<=0) continue;
      text+="\n"+keys[k]+" : "+IntegerToString(counts[k]);
      shown++;
      // First-observed order only; no ranking or sorting by outcome.
      if(shown>=24)
        {
         if(key_count>shown) text+="\n... additional classes omitted.";
         break;
        }
     }
   if(shown==0) text+="\nNo matrix observations in lookback.";
   return text;
  }

void DrawSequencePanel()
  {
   int total=ArraySize(g_sequences);
   int fvg=0,retrace=0,toward=0,away=0;
   int reached=0,approached=0,no_target=0;
   int bsl=0,ssl=0,bsl_rev=0,ssl_rev=0,aligned_fvg=0;
   int bsl_sweep=0,bsl_break=0,ssl_sweep=0,ssl_break=0;
   LiquiditySequence latest;
   bool have=false;

   for(int i=0;i<total;i++)
     {
      LiquiditySequence q=g_sequences[i];
      if(q.fvg_time>0) fvg++;
      if(q.complete) retrace++;
      if(q.relation==LIQ_TOWARD_OPPOSING) toward++;
      else if(q.relation==LIQ_AWAY_FROM_OPPOSING) away++;
      if(q.opposing_reached) reached++;
      else if(q.opposing_approached) approached++;
      else if(q.opposing_name=="") no_target++;
      if(q.side=="BSL")
        {
         bsl++;
         if(q.delivery_reversal_aligned) bsl_rev++;
         if(q.run_state==RUN_SWEEP_REJECTION) bsl_sweep++;
         if(q.run_state==RUN_BREAK_AND_HOLD) bsl_break++;
        }
      else if(q.side=="SSL")
        {
         ssl++;
         if(q.delivery_reversal_aligned) ssl_rev++;
         if(q.run_state==RUN_SWEEP_REJECTION) ssl_sweep++;
         if(q.run_state==RUN_BREAK_AND_HOLD) ssl_break++;
        }
      if(q.fvg_delivery_aligned) aligned_fvg++;
      if(!have || q.run_time>latest.run_time)
        { latest=q; have=true; }
     }

   string text="ICT v1.2 DELIVERY MODEL AUDIT (LEGACY / DESCRIPTIVE)\n";
   text+="Liquidity-pool runs: "+IntegerToString(total)+"\n";
   text+="BSL runs: "+IntegerToString(bsl)+"  SSL runs: "+IntegerToString(ssl)+"\n";
   text+="BSL sweep/break: "+IntegerToString(bsl_sweep)+" / "+IntegerToString(bsl_break)+"\n";
   text+="SSL sweep/break: "+IntegerToString(ssl_sweep)+" / "+IntegerToString(ssl_break)+"\n";
   text+="BSL reversal-aligned delivery: "+IntegerToString(bsl_rev)+"\n";
   text+="SSL reversal-aligned delivery: "+IntegerToString(ssl_rev)+"\n";
   text+="Runs -> SB FVG: "+IntegerToString(fvg)+"\n";
   text+="Runs -> delivery-aligned FVG: "+IntegerToString(aligned_fvg)+"\n";
   text+="Runs -> SB FVG -> retracement: "+IntegerToString(retrace)+"\n";
   text+="Delivery toward opposing pool: "+IntegerToString(toward)+"\n";
   text+="Delivery away from opposing pool: "+IntegerToString(away)+"\n";
   text+="Opposing liquidity reached: "+IntegerToString(reached)+"\n";
   text+="Opposing liquidity approached: "+IntegerToString(approached)+"\n";
   text+="No opposing candidate in path: "+IntegerToString(no_target)+"\n";

   if(have)
     {
      text+="\nLatest: "+latest.pool_name+" "+latest.side;
      text+="\nState: "+SequenceStateName(latest.run_state);
      text+="\nDelivery: "+SequenceDeliveryName(latest.delivery);
      text+="\nReversal-aligned: "+(latest.delivery_reversal_aligned?"YES":"NO");
      if(latest.opposing_name!="")
        {
         text+="\nOpposing candidate: "+latest.opposing_name;
         text+="\nRelation: "+(latest.relation==LIQ_TOWARD_OPPOSING?"TOWARD":latest.relation==LIQ_AWAY_FROM_OPPOSING?"AWAY":"NONE");
         text+="\nDistance: "+DoubleToString(latest.distance_to_opposing,_Digits);
         text+="\nMax progress: "+DoubleToString(latest.max_delivery_progress*100.0,1)+"%";
         text+="\nOutcome: "+SequenceOutcomeName(latest);
        }
      text+="\nSB FVG: "+(latest.fvg_time>0?"YES":"NO");
      text+="\nFVG delivery-aligned: "+(latest.fvg_delivery_aligned?"YES":"NO");
      text+="\nRetracement: "+(latest.complete?"YES":"NO");
     }
   text+="\n\nMatrix is observational only — no automatic DOL / bias / trade signal.";
   text+=BuildSequenceMatrixText();
   Comment(text);
  }

//+------------------------------------------------------------------+
void DrawText(string name,string txt,datetime t,double price)
  {
   if(ObjectFind(0,name)>=0) return;
   ObjectCreate(0,name,OBJ_TEXT,0,t,price);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
  }

//+------------------------------------------------------------------+