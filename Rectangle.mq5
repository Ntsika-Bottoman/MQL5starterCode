//+------------------------------------------------------------------+
//|                                           RangeBreakoutA4PEA.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|Includes by linking the graphical panel causing interfacing       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Includes the automated trading library                            |
//+------------------------------------------------------------------+
#property description "Take Profit and Stop Loss - in Points (1.00055-1.00045=10 points)"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
//+------------------------------------------------------------------+
//|Input Global variables                                            |
//+------------------------------------------------------------------+
input group             "Trading Range"
input uint                 InpRangeStart           = 15;
input uint                 InpRangeDuration        = 480;
input uint                 InpRangeClose           = 1200;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group             "Trading settings"
input uint                 InpStopLoss             = 150;            // Stop Loss 150
input uint                 InpTakeProfit           = 460;            // Take Profit 460
input group             "Position size management (lot calculation)"
input double               InpLots                 = 0.01;           // Lots
input group             "Additional features"
input ulong                InpDeviation            = 10;             // Deviation, in Points (1.00045-1.00055=10 points) 10
input ulong                InpMagic                = 200;            // Magic number 200
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input bool                 InpMonday               = false;
input bool                 InpTuesday              = true;
input bool                 InpWednesday            = true;
input bool                 InpThursday             = true;
input bool                 InpFriday               = false;
//- - -
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
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
double   m_stop_loss                = 0.0;      // Stop Loss                   -> double
double   m_take_profit              = 0.0;      // Take Profit                -> double
int MAValue5High;
double MA_value[];
int MAValue5Low;
double MA_value2[];
int MAValue5Expo;
double MA_value3[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//+------------------------------------------------------------------+
//|Forced initialization of MA variables                             |
//+------------------------------------------------------------------+
    MAValue5High = iMA(_Symbol,PERIOD_M30,5,0,MODE_SMMA,PRICE_HIGH);
    MAValue5Low = iMA(_Symbol,PERIOD_M30,5,0,MODE_SMMA,PRICE_LOW);
    MAValue5Expo = iMA(_Symbol,PERIOD_M30,1,0,MODE_EMA,PRICE_CLOSE);
//+------------------------------------------------------------------+
//|Initialize range functions and error detection                    |
//+------------------------------------------------------------------+
   m_stop_loss                = 0.0;      
   m_take_profit              = 0.0;      

   ResetLastError();
   if(!m_symbol.Name(Symbol())) // sets symbol name
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: CSymbolInfo.Name");
      return(INIT_FAILED);
     }
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(InpDeviation);
   m_stop_loss                = InpStopLoss                 * m_symbol.Point();
   m_take_profit              = InpTakeProfit               * m_symbol.Point();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- Initialize the generator of random numbers
   MathSrand(GetTickCount());
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
    if(InpRangeStart < 0 || InpRangeStart >= 1440)
      {
        Alert("Range Start < 0 or >= 1440");
        return INIT_PARAMETERS_INCORRECT;
      }
        if(InpRangeClose < 0 || InpRangeClose >= 1440 || (InpRangeStart+InpRangeDuration)%1440 == InpRangeClose)
        {
          Alert("Range Close < 0 or >= 1440 or endtime == closetime");
          return INIT_PARAMETERS_INCORRECT;
        }
          if(InpRangeDuration < 0 || InpRangeDuration >= 1440)
            {
              Alert("Range Duration < 0 or >= 1440");
              return INIT_PARAMETERS_INCORRECT;
            }
              if(_UninitReason==REASON_PARAMETERS)
                {
                  CalculateRange();
                }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//+------------------------------------------------------------------+
//|Delete objects when you remove the EA                             |
//+------------------------------------------------------------------+
    ObjectsDeleteAll(NULL,"Range");
//+------------------------------------------------------------------+
//|Destroy Panel                                                     |
//+------------------------------------------------------------------+

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//+------------------------------------------------------------------+
//|House Keeping                                                     |
//+------------------------------------------------------------------+
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
//|Check if the breakout condition is met                            |
//+------------------------------------------------------------------+
    CheckBreakOuts();
//+------------------------------------------------------------------+
//|Checks if the setup is coherent with YBR                          |
//+------------------------------------------------------------------+
  
//+------------------------------------------------------------------+
//|Calling the candle stick formations                               |
//+------------------------------------------------------------------+
//You can mess with the weights to get the precise Hammer Candle formation you want
     getHummerSignal(0.5,0.7);
     getEngulfingSignal();
     getStarSignal(0.3);
//+------------------------------------------------------------------+
//|Buy & Sell Condition                                              |
//+------------------------------------------------------------------+
    if(range.f_high_breakout == true)
      {
        if(CalculateAllPositions()==0)
          {
            if(!RefreshRates())
          return;
//--- odd (1) - "BUY", even (2) - "SELL"
          int math_rand=MathRand();
            if(math_rand%2==0)
              {
                if(IsNewCandle()==true)
                  {
                    double sl=(m_stop_loss==0.0)?0.0:m_symbol.Ask()-m_stop_loss;
                    double tp=(m_take_profit==0.0)?0.0:m_symbol.Ask()+m_take_profit;
                    m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp));
                  }
                    else
                      {
                        double sl=(m_stop_loss==0.0)?0.0:m_symbol.Bid()+m_stop_loss;
                        double tp=(m_take_profit==0.0)?0.0:m_symbol.Bid()-m_take_profit;
                        m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp));;
                      }
              }
           }
        }
//- - - 
    }
//+------------------------------------------------------------------+
//|End of OnTick Function                                            |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|ChartEvent handler                                                |
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
    range.low = 9999999999999;
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
//+------------------------------------------------------------------+
//| calling the Draw Range Lines function                            |
//+------------------------------------------------------------------+
    DrawObjects();      
//+------------------------------------------------------------------+
//| Update panel                                                     |
//+------------------------------------------------------------------+
          
  }
//+------------------------------------------------------------------+
//|Breakout Function Signal One                                      |
//+------------------------------------------------------------------+
void CheckBreakOuts()
  {
   if(lastTick.time >= range.end_time && range.end_time>0 && range.f_entry)
      {
        if(!range.f_high_breakout && lastTick.ask >= range.high)
          {
            range.f_high_breakout = true;
            //buy position
          }
      } 
  }
//+------------------------------------------------------------------+
//|Draw Range Lines Function                                         |
//+------------------------------------------------------------------+
void DrawObjects()
  {
//+------------------------------------------------------------------+
//|Draw start time                                                   |
//+------------------------------------------------------------------+
    ObjectDelete(NULL,"Range Start");
      if(range.start_time>0)
        {
          ObjectCreate(NULL,"Range Start",OBJ_VLINE,0,range.start_time,0);
          ObjectSetString(NULL,"Range Start",OBJPROP_TOOLTIP,"Start of the Range\n"+TimeToString(range.start_time,TIME_DATE|TIME_MINUTES));
          ObjectSetInteger(NULL,"Range Start",OBJPROP_COLOR,clrGreenYellow);
          ObjectSetInteger(NULL,"Range Start",OBJPROP_WIDTH,2);
          ObjectSetInteger(NULL,"Range Start",OBJPROP_BACK,true); 
        } 
//+------------------------------------------------------------------+
//|Draw end time                                                     |
//+------------------------------------------------------------------+ 
    ObjectDelete(NULL,"Range End");
      if(range.end_time>0)
        {
          ObjectCreate(NULL,"Range End",OBJ_VLINE,0,range.end_time,0);
          ObjectSetString(NULL,"Range End",OBJPROP_TOOLTIP,"End of the Range\n"+TimeToString(range.end_time,TIME_DATE|TIME_MINUTES));
          ObjectSetInteger(NULL,"Range End",OBJPROP_COLOR,clrGray);
          ObjectSetInteger(NULL,"Range End",OBJPROP_WIDTH,2);
          ObjectSetInteger(NULL,"Range End",OBJPROP_BACK,true); 
        } 
//+------------------------------------------------------------------+
//|Draw close time                                                   |
//+------------------------------------------------------------------+  
    ObjectDelete(NULL,"Range Close");
      if(range.close_time>0)
        {
          ObjectCreate(NULL,"Range End",OBJ_VLINE,0,range.close_time,0);
          ObjectSetString(NULL,"Range End",OBJPROP_TOOLTIP,"Close of the Range\n"+TimeToString(range.close_time,TIME_DATE|TIME_MINUTES));
          ObjectSetInteger(NULL,"Range End",OBJPROP_COLOR,clrRed);
          ObjectSetInteger(NULL,"Range End",OBJPROP_WIDTH,2);
          ObjectSetInteger(NULL,"Range End",OBJPROP_BACK,true); 
        }        
//+------------------------------------------------------------------+
//|Draws the high of the range                                       |
//+------------------------------------------------------------------+
    ObjectsDeleteAll(NULL,"Range High");
      if(range.high>0)
        {
          ObjectCreate(NULL,"Range High",OBJ_TREND,0,range.start_time,range.high,range.end_time,range.high);
          ObjectSetString(NULL,"Range High",OBJPROP_TOOLTIP,"High of the Range\n"+DoubleToString(range.high,_Digits));
          ObjectSetInteger(NULL,"Range High",OBJPROP_COLOR,clrBlue);
          ObjectSetInteger(NULL,"Range High",OBJPROP_WIDTH,2);
          ObjectSetInteger(NULL,"Range High",OBJPROP_BACK,true); 
//+------------------------------------------------------------------+
//|Draws the breakout thresholdline high                             |
//+------------------------------------------------------------------+
          ObjectCreate(NULL,"Range High ",OBJ_TREND,0,range.end_time,range.high,range.close_time,range.high);
          ObjectSetString(NULL,"Range High ",OBJPROP_TOOLTIP,"High of the Range \n"+DoubleToString(range.high,_Digits));
          ObjectSetInteger(NULL,"Range High ",OBJPROP_COLOR,clrBlue);
          ObjectSetInteger(NULL,"Range High ",OBJPROP_BACK,true);   
          ObjectSetInteger(NULL,"Range High ",OBJPROP_STYLE,STYLE_DOT);
        }
//+------------------------------------------------------------------+
//|Draws the low of the range                                        |                           
//+------------------------------------------------------------------+  
    ObjectsDeleteAll(NULL,"Range Low");
      if(range.low>9999999)
        {
          ObjectCreate(NULL,"Range Low",OBJ_TREND,0,range.start_time,range.low,range.end_time,range.low);
          ObjectSetString(NULL,"Range Low",OBJPROP_TOOLTIP,"Close of the Range\n"+DoubleToString(range.low,_Digits));
          ObjectSetInteger(NULL,"Range Low",OBJPROP_COLOR,clrGreen);
          ObjectSetInteger(NULL,"Range Low",OBJPROP_WIDTH,2);
          ObjectSetInteger(NULL,"Range Low",OBJPROP_BACK,true); 
//+------------------------------------------------------------------+
//|Draws the breakout thresholdline low                              |
//+------------------------------------------------------------------+
          ObjectCreate(NULL,"Range Low ",OBJ_TREND,0,range.end_time,range.low,range.close_time,range.low);
          ObjectSetString(NULL,"Range Low ",OBJPROP_TOOLTIP,"Low of the Range \n"+DoubleToString(range.low,_Digits));
          ObjectSetInteger(NULL,"Range Low ",OBJPROP_COLOR,clrBlue);
          ObjectSetInteger(NULL,"Range Low ",OBJPROP_BACK,true);   
          ObjectSetInteger(NULL,"Range Low ",OBJPROP_STYLE,STYLE_DOT);
        }   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
     {
      Print(__FILE__," ",__FUNCTION__,", ERROR: ","Ask == 0.0 OR Bid == 0.0");
      return(false);
     } 
   return(true);
  }
//+------------------------------------------------------------------+
//| Calculate all positions Buy and Sell                             |
//+------------------------------------------------------------------+
int CalculateAllPositions()
  {
   int totlal=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
            totlal++;
            
   return(totlal);
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
int getStarSignal(double maxMiddleRatio)
  {
    datetime time = iTime(_Symbol,PERIOD_CURRENT,1);
    
    double high1 = iHigh(_Symbol,PERIOD_CURRENT,1);
    double low1 = iLow(_Symbol,PERIOD_CURRENT,1);
    double open1 = iOpen(_Symbol,PERIOD_CURRENT,1);
    double close1 = iClose(_Symbol,PERIOD_CURRENT,1);
      
      double high2 = iHigh(_Symbol,PERIOD_CURRENT,2);
      double low2 = iLow(_Symbol,PERIOD_CURRENT,2);
      double open2 = iOpen(_Symbol,PERIOD_CURRENT,2);
      double close2 = iClose(_Symbol,PERIOD_CURRENT,2);
    
        double high3 = iHigh(_Symbol,PERIOD_CURRENT,3);
        double low3 = iLow(_Symbol,PERIOD_CURRENT,3);
        double open3 = iOpen(_Symbol,PERIOD_CURRENT,3);
        double close3 = iClose(_Symbol,PERIOD_CURRENT,3);
      
        double size1 = high1 - low1;
        double size2 = high2 - low2;
        double size3 = high3 - low3;
      
        if(open1 < close1)
          {
            if(open3 > close3)
              {
                if(size2 < size1 * maxMiddleRatio && size2 < size3 * maxMiddleRatio)
                  {
                    createObject(time,low1,200,1,clrGreen,"Morning Star");
                    return 1;
                  }
              }
          }
          if(open1 > close1)
          {
            if(open3 < close3)
              {
                if(size2 < size1 * maxMiddleRatio && size2 < size3 * maxMiddleRatio)
                  {
                    createObject(time,high1,201,-1,clrRed,"Evening Star");
                    return -1;
                  }
              }
          }
    return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getEngulfingSignal()
  {
    datetime time = iTime(_Symbol,PERIOD_CURRENT,1);
    double high1 = iHigh(_Symbol,PERIOD_CURRENT,1);
    double low1 = iLow(_Symbol,PERIOD_CURRENT,1);
    double open1 = iOpen(_Symbol,PERIOD_CURRENT,1);
    double close1 = iClose(_Symbol,PERIOD_CURRENT,1);
      
      double high2 = iHigh(_Symbol,PERIOD_CURRENT,2);
      double low2 = iLow(_Symbol,PERIOD_CURRENT,2);
      double open2 = iOpen(_Symbol,PERIOD_CURRENT,2);
      double close2 = iClose(_Symbol,PERIOD_CURRENT,2);
    //bullish engulf formation  
    if(open1 < close1)
      {
        if(open2 > close2)
          {
            if(high1 > high2 && low1 < low2)
              { 
                if(close1 > open2 && open1 < close2)
                  {
                    createObject(time,low1,217,1,clrGreen,"Engulfing");
                    return 1;
                  }
              } 
          }
      }
//bearish engulf formation  
      if(open1 > close1)
        {
          if(open2 < close2)
            {
              if(high1 > high2 && low1 < low2)
                { 
                  if(close1 < open2 && open1 > close2)
                  {
                    createObject(time,high1,218,-1,clrRed,"Engulfing");
                    return -1;
                  } 
                }
            }
        }     
      return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This is where you will mix and match the timeframes, adjust the high return with period current
int getHummerSignal(double maxRatioShortShadow, double minRatioLongShadow)
  {
    datetime time = iTime(_Symbol,PERIOD_CURRENT,1);
    
    double high = iHigh(_Symbol,PERIOD_CURRENT,1);
    double low = iLow(_Symbol,PERIOD_CURRENT,1);
    double open = iOpen(_Symbol,PERIOD_CURRENT,1);
    double close = iClose(_Symbol,PERIOD_CURRENT,1);
    
    double candleSize = high - low;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+    
// green hummer buy formation    
    if(open < close)
      {
        if(high - close < candleSize * maxRatioShortShadow)
          {
            if(open - low > candleSize * minRatioLongShadow)
              {
                createObject(time,low,233,1,clrGreen,"Hammer");
                return 1;
              }
          }
      } 
// red hummer buy formation   
    if(open > close)
      {
        if(high - open < candleSize * maxRatioShortShadow)
          {
            if(close - low > candleSize * minRatioLongShadow)
              {
                createObject(time,low,233,1,clrGreen,"Hammer");
                return 1;
              }
          }
      } 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// green hummer sell formation    
    if(open < close)
      {
        if(open - low < candleSize * maxRatioShortShadow)
          {
            if(high - close > candleSize * minRatioLongShadow)
              {
                createObject(time,high,234,-1,clrRed,"Inverted Hammer");
                return -1;
              }
          }
      } 
// red hummer sell formation    
    if(open > close)
      {
        if(close - low < candleSize * maxRatioShortShadow)
          {
            if(high - open > candleSize * minRatioLongShadow)
              {
                createObject(time,high,234,-1,clrRed,"Inverted Hammer");
                return -1;
              }
          }
      }       
    return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createObject(datetime time, double price, int arrowCode, int direction, color clr, string txt)
  {
    string objectName = "";
    StringConcatenate(objectName,"Signal@",time,"at",DoubleToString(price,_Digits),"(",arrowCode,")");
      if(ObjectCreate(0,objectName,OBJ_ARROW,0,time,price))
        {
          ObjectSetInteger(0,objectName,OBJPROP_ARROWCODE,arrowCode);
          ObjectSetInteger(0,objectName,OBJPROP_COLOR,clr);
          if(direction > 0) ObjectSetInteger(0,objectName,OBJPROP_ANCHOR,ANCHOR_TOP);
          if(direction < 0) ObjectSetInteger(0,objectName,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
        }
        string objectNameDesc = objectName+txt;
          if(ObjectCreate(0,objectNameDesc,OBJ_TEXT,0,time,price))
            {
              ObjectSetString(0,objectNameDesc,OBJPROP_TEXT," "+txt);
              ObjectSetInteger(0,objectNameDesc,OBJPROP_COLOR,clr);
            }
  }
//+------------------------------------------------------------------+
//|End of the Program                                                |
//+------------------------------------------------------------------+
