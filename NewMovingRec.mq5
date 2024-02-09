//+------------------------------------------------------------------+
//|                                                 NewMovingRec.mq5 |
//|      Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg. |
//|                                     https://linktr.ee/thebottmon |
//+------------------------------------------------------------------+
#property copyright "Bottoman, N (2023). ALL4REX Pty (Ltd) Gauteng Johannesburg."
#property link      "https://linktr.ee/thebottmon"
#property version   "1.00"
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
    int HCandle, LCandle;
    
    double high[], low[];
    
    ArraySetAsSeries(high,true);
    
    ArraySetAsSeries(low,true);
    
    CopyHigh(_Symbol,_Period, 0, 30, high);
    
    CopyLow(_Symbol, _Period, 0, 30, low);
    
    HCandle = ArrayMaximum(high, 0, 30);
    
    LCandle = ArrayMinimum(low, 0, 30);
    
    MqlRates PriceInformaion[];
    
    ArraySetAsSeries(PriceInformaion, true);
    
    int Data = CopyRates(Symbol(), Period(), 0, Bars(Symbol(), Period()), PriceInformaion);
    
    ObjectDelete(NULL, "Rectangle");
    
    ObjectCreate
    (
      _Symbol,
      "Rectangle",
      0,
      PriceInformaion[30].time,
      PriceInformaion[HCandle].high,
      PriceInformaion[0].time,
      PriceInformaion[LCandle].low
    );    
    
    ObjectSetInteger(0, "Rectangle", OBJPROP_COLOR, clrGray);
    
    ObjectSetInteger(0, "Rectangle", OBJPROP_FILL, clrGray);

   
  }
//+------------------------------------------------------------------+
