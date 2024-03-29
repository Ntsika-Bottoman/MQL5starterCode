//+------------------------------------------------------------------+
//|                                        Stop Loss Take Profit.mq5 |
//|                         Copyright © 2016-2022, Vladimir Karputov |
//|                      https://www.mql5.com/en/users/barabashkakvn |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2016-2022, Vladimir Karputov"
#property link      "https://www.mql5.com/en/users/barabashkakvn"
#property version   "1.007"
//+------------------------------------------------------------------+
//|Includes by linking causing interfacing                           |
//+------------------------------------------------------------------+
//#include <..\Experts\Scripts\Experimentwithpython1.py>
//#include <..\Experts\Stop_Loss_Take_Profit.mq5>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property description "Take Profit and Stop Loss - in Points (1.00055-1.00045=10 points)"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
//---
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CSymbolInfo    m_symbol;                     // object of CSymbolInfo class
//--- input parameters
input group             "Trading settings"
input uint                 InpStopLoss             = 150;            // Stop Loss 150
input uint                 InpTakeProfit           = 460;            // Take Profit 460
input group             "Position size management (lot calculation)"
input double               InpLots                 = 0.01;           // Lots
input group             "Additional features"
input ulong                InpDeviation            = 10;             // Deviation, in Points (1.00045-1.00055=10 points) 10
input ulong                InpMagic                = 200;            // Magic number 200
//---
double   m_stop_loss                = 0.0;      // Stop Loss                   -> double
double   m_take_profit              = 0.0;      // Take Profit                -> double
//- - - MA - - -
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
//- - - forced initialization of the MA's - - -
    MAValue5High = iMA(_Symbol,PERIOD_M30,5,0,MODE_SMMA,PRICE_HIGH);
    MAValue5Low = iMA(_Symbol,PERIOD_M30,5,0,MODE_SMMA,PRICE_LOW);
    MAValue5Expo = iMA(_Symbol,PERIOD_M30,1,0,MODE_EMA,PRICE_CLOSE);
//--- forced initialization of variables
   m_stop_loss                = 0.0;      // Stop Loss                  -> double
   m_take_profit              = 0.0;      // Take Profit                -> double
//---
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
//---
   m_stop_loss                = InpStopLoss                 * m_symbol.Point();
   m_take_profit              = InpTakeProfit               * m_symbol.Point();
//--- Initialize the generator of random numbers
   MathSrand(GetTickCount());
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
//- - - 
    ArraySetAsSeries(MA_value,true);
    CopyBuffer(MAValue5High,0,0,3,MA_value);
    ArraySetAsSeries(MA_value2,true);
    CopyBuffer(MAValue5Low,0,0,3,MA_value2);
    ArraySetAsSeries(MA_value3,true);
    CopyBuffer(MAValue5Expo,0,0,3,MA_value3);
//- - -
     MqlRates PriceInfo[];
     ArraySetAsSeries(PriceInfo,true);
     CopyRates(_Symbol,PERIOD_CURRENT,0,4,PriceInfo); 
//- - -
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
            if(MA_value3[1] > MA_value[1] && MA_value3[1] > MA_value2[1] && PriceInfo[1].close > PriceInfo[2].close)
              {
                double sl=(m_stop_loss==0.0)?0.0:m_symbol.Ask()-m_stop_loss;
                double tp=(m_take_profit==0.0)?0.0:m_symbol.Ask()+m_take_profit;
                m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp));
              }
        
            else if(MA_value3[0] < MA_value[0] && MA_value3[0] < MA_value2[0] && PriceInfo[0].close < PriceInfo[1].close)
              {
                double sl=(m_stop_loss==0.0)?0.0:m_symbol.Bid()+m_stop_loss;
                double tp=(m_take_profit==0.0)?0.0:m_symbol.Bid()-m_take_profit;
                m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp));;
              }
           }
        }
     }
//---
  }
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
     
//---
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
//---
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