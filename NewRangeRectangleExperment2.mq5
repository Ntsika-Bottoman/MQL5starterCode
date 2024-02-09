//+------------------------------------------------------------------+
//|                                  NewRangeRectangleExperment2.mq5 |
//|      Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg. |
//|                                     https://linktr.ee/thebottmon |
//+------------------------------------------------------------------+
#property copyright "Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg."
#property link      "https://linktr.ee/thebottmon"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool                 InpMonday               = false;
input bool                 InpTuesday              = true;
input bool                 InpWednesday            = true;
input bool                 InpThursday             = true;
input bool                 InpFriday               = false;
input uint                 InpRangeStart           = 0;
input uint                 InpRangeDuration        = 480;
input uint                 InpRangeClose           = 1200;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct RANGE_STRUCT
  {
    datetime start_time;
    datetime end_time;
    datetime close_time;
    
      double high;
      double low;
      
      RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(99999) {};
  };
  
RANGE_STRUCT range;
MqlTick currentTick;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    SymbolInfoTick(_Symbol,currentTick);
//+------------------------------------------------------------------+
//|We're in the range now, get high and low                          |
//+------------------------------------------------------------------+
  if(IsNewCandle()==true)
    {
      if(currentTick.time>=range.start_time && currentTick.time < range.end_time)
         {
           if(currentTick.ask > range.high)
             {
               range.high = currentTick.ask;
                 {
                   if(currentTick.bid > range.low)
                     {
                       range.low = currentTick.bid;
                     }
                 }
             }      
         }
    }
//+------------------------------------------------------------------+
//|Tests the conditions to calculate a new range                     |                                             
//+------------------------------------------------------------------+
    if( (InpRangeClose>=0 && currentTick.time>=range.close_time)
      ||(range.end_time==0) 
      ||(range.end_time!=0 && currentTick.time>range.end_time)  )
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
      {
        CalculateRectangleTime();
        DrawRectangle();
      }
  }
//+------------------------------------------------------------------+
//|Calculate new Rectangle object                                    |
//+------------------------------------------------------------------+
void CalculateRectangleTime()
  {
    int time_cycle = 86400;
    range.start_time = (currentTick.time - (currentTick.time % time_cycle)) + InpRangeStart*60;
      for(int i=0; i<8; i++)
      {
          MqlDateTime tmp;
          TimeToStruct(range.start_time, tmp);
          int dow = tmp.day_of_week;
            if(currentTick.time>=range.start_time || dow==6 || dow==0 || (dow==1 && !InpMonday) || (dow==2 && !InpTuesday)
            || (dow==3 && !InpWednesday) || (dow==4 && !InpThursday) || (dow==5 && !InpFriday))
              {
                range.start_time += time_cycle;
              }
        }
        range.end_time = range.start_time + InpRangeDuration*60;
          for(int i=0; i<2; i++)
          {
            MqlDateTime tmp;
            TimeToStruct(range.start_time, tmp);
            int dow = tmp.day_of_week;
              if(dow==6 || dow==0)
                {
                  range.end_time += time_cycle;
                }
          }
          range.close_time = (range.end_time - (range.end_time % time_cycle)) + InpRangeClose*60;
            for(int i=0; i<3; i++)
            {
              MqlDateTime tmp;
              TimeToStruct(range.close_time, tmp);
              int dow = tmp.day_of_week;
              if(range.close_time<=range.end_time || dow==6 || dow==0)
                {
                  range.close_time += time_cycle;
                }
            }  
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawRectangle()
  {
    ObjectCreate
      (
        0, 
        "Asian Session", 
        OBJ_RECTANGLE, 
        0, 
        range.start_time, 
        range.low, 
        range.end_time, 
        range.high
      );
        ObjectSetInteger(0, "Asian Session", OBJPROP_FILL, false);
        ObjectSetInteger(0, "Asian Session", OBJPROP_WIDTH,2);
        ObjectSetInteger(0, "Asian Session", OBJPROP_BACK,true);
        ObjectSetInteger(0, "Asian Session", OBJPROP_COLOR,clrGray);
        ObjectSetInteger(0, "Asian Session", OBJPROP_BACK,true);   
        ObjectSetInteger(0, "Asian Session", OBJPROP_STYLE,STYLE_DOT);
  }   
//-------------------------------------------------------------------+
//insuring its a new candle function                                 |
//+------------------------------------------------------------------+    
bool IsNewCandle()
  {
    static int BarsOnChart=0;
	   if (Bars(_Symbol,PERIOD_CURRENT) == BarsOnChart)
	 return (false);
	   BarsOnChart = Bars(_Symbol,PERIOD_CURRENT);
	 return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
