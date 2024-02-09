//+------------------------------------------------------------------+
//|                                               RecExperiment1.mq5 |
//|      Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg. |
//|                                     https://linktr.ee/thebottmon |
//+------------------------------------------------------------------+
#property copyright "Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg."
#property link      "https://linktr.ee/thebottmon"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input uint                 InpRangeStart           = 0;
input uint                 InpRangeDuration        = 480;
input uint                 InpRangeClose           = 1200;
input ulong                InpDeviation            = 10;             
input ulong                InpMagic                = 200;   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool                 InpMonday               = false;
input bool                 InpTuesday              = true;
input bool                 InpWednesday            = true;
input bool                 InpThursday             = true;
input bool                 InpFriday               = false;
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
        
        bool f_entry;
        bool f_high_breakout;
        bool f_low_breakout;
        
    RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(99999), 
                     f_entry(false), f_high_breakout(false), f_low_breakout(false) {};
  };
RANGE_STRUCT range;
MqlTick prevTick, lastTick;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(InpDeviation);
   
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
    prevTick = lastTick;
    SymbolInfoTick(_Symbol,lastTick);
//+------------------------------------------------------------------+
//|This is the range calculation, calculating the high and low of the range                                    
//+------------------------------------------------------------------+
    if(lastTick.time>=range.start_time && lastTick.time < range.end_time)
      {
        range.f_entry = true;
          if(lastTick.ask > range.high)
            {
              range.high = lastTick.ask;
              DrawObjects();
            }
              if(lastTick.bid > range.low)
                {
                  range.low = lastTick.bid;
                  DrawObjects();
                }
      }
//+------------------------------------------------------------------+
//|Tests the conditions to calculate a new range                     |                                             
//+------------------------------------------------------------------+
    if( (InpRangeClose>=0 && lastTick.time>=range.close_time)
      ||(range.f_high_breakout && range.f_low_breakout)
      ||(range.end_time==0) 
      ||(range.end_time!=0 && lastTick.time>range.end_time && !range.f_entry)  )
        { 
          CalculateRange();
        }      
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
    DrawObjects(); 
  }
//+------------------------------------------------------------------+
//|End of OnTick                                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Calculate new Range Fuction                                       |
//+------------------------------------------------------------------+
void CalculateRange()
  {
    range.start_time = 0;
    range.end_time = 0;
    range.close_time = 0;
    range.high = 0.0;
    range.low = 99999;
    range.f_entry = false;
    range.f_high_breakout = false;
    range.f_low_breakout = false;
//+------------------------------------------------------------------+
//| calculate range start time                                       |
//+------------------------------------------------------------------+
    int time_cycle = 86400;
    range.start_time = (lastTick.time - (lastTick.time % time_cycle)) + InpRangeStart*60;
      for(int i=0; i<8; i++)
        {
          MqlDateTime tmp;
          TimeToStruct(range.start_time, tmp);
          int dow = tmp.day_of_week;
            if(lastTick.time>=range.start_time || dow==6 || dow==0 || (dow==1 && !InpMonday) || (dow==2 && !InpTuesday)
            || (dow==3 && !InpWednesday) || (dow==4 && !InpThursday) || (dow==5 && !InpFriday))
              {
                range.start_time += time_cycle;
              }
        }
//+------------------------------------------------------------------+
//| calculate range end time                                         |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//| calculate range close time                                       |
//+------------------------------------------------------------------+
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
void DrawObjects()
  {
    ObjectCreate
      (
        _Symbol, 
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+