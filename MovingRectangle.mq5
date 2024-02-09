//+------------------------------------------------------------------+
//|                                              MovingRectangle.mq5 |
//|      Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg. |
//|                                     https://linktr.ee/thebottmon |
//+------------------------------------------------------------------+
#property copyright "Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg."
#property link      "https://linktr.ee/thebottmon"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    int HighestCandle, LowestCandle;
    
    double High[], low[];
    
    ArraySetAsSeries(High,true);
    
    ArraySetAsSeries(low,true);
    
    CopyHigh(_Symbol, Period() ,0,30,High);
    
    CopyLow(_Symbol, Period() ,0,30,low);
    
    HighestCandle = ArrayMaximum(High,30);
    
    LowestCandle = ArrayMinimum(low,30);
    
    MqlRates PriceInfo[];
    
    ArraySetAsSeries(PriceInfo,true);
    
    int Data = CopyRates(Symbol(), PERIOD_CURRENT, 0, Bars(Symbol(), Period()), PriceInfo);
    
    ObjectDelete(_Symbol, "Rectangle");
    
    ObjectCreate
    (
      _Symbol,
      "Rectangle",
      OBJ_RECTANGLE,
      0, // On the main chart window
      PriceInfo[30].time, // left border, the start point of the triangle. 
      PriceInfo.[HighestCandle].high, // the starting candle
      PriceInfo[0].time, // the ending candle of the rectange, the one at 8 & 9:30
      PriceInfo[LowestCandle].low // the ending candle
    );
    
    ObjectSetInteger(0, "Rectangle", OBJPROP_COLOR, clrGray);
    
    ObjectSetInteger(0, "Rectangle", OBJPROP_FILL, clrGray);
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
