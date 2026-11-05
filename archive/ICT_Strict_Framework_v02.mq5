//+------------------------------------------------------------------+
//| ICT_Strict_Framework_v02.mq5                                     |
//| ICT Silver Bullet research build                                |
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
input bool DrawEntries         = true;
input bool EnableAlerts        = false;

input int LookbackBars = 3000;

// Optional minimum price-framework filter.
// Set to the appropriate value for the instrument being studied.
// 0 = display candidates without applying the framework-size filter.
input double MinimumFrameworkPriceMove = 0.0;

// Reference levels used as documented draw-on-liquidity candidates.
input bool UsePreviousDayHighLow  = true;
input bool UsePreviousWeekHighLow = true;

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

//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME,"ICT Strict Framework v0.2");
   ArrayResize(g_fvgs,0);
   return(INIT_SUCCEEDED);
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

   ArrayResize(g_fvgs,0);

   int first = rates_total-3;
   if(LookbackBars > 0)
      first=MathMin(first,LookbackBars);

   if(DrawDrawOnLiquidity)
      DrawReferenceLiquidity(time,rates_total);

   for(int i=first;i>=2;i--)
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
//| Convert broker server time to New York time.                    |
//|                                                                  |
//| Uses current terminal server/GMT relationship plus a calculated  |
//| US DST rule. This avoids a fixed South-Africa/broker offset.      |
//+------------------------------------------------------------------+
datetime ServerTimeToNewYork(datetime server_time)
  {
   datetime now_server=TimeTradeServer();
   datetime now_gmt=TimeGMT();

   int server_minus_gmt=(int)(now_server-now_gmt);

   datetime gmt_time=server_time-server_minus_gmt;

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
   for(int j=creation_index-1;j>=0;j--)
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

      if(EnableAlerts)
         Alert("ICT Silver Bullet FVG retracement: ",
               z.window_name," ",
               (z.direction>0 ? "BULLISH" : "BEARISH"),
               " ",_Symbol,
               " ",TimeToString(time[j]));

      return;
     }
  }
//+------------------------------------------------------------------+