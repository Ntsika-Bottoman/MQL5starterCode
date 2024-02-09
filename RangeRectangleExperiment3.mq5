//+------------------------------------------------------------------+
//|                                    RangeRectangleExperiment3.mq5 |
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
MqlTick lastTick;
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
    CalculateRange();

    DrawObjects();
   
  }
//+------------------------------------------------------------------+
//|Calculate new Range Fuction                                       |
//+------------------------------------------------------------------+
void CalculateRange()
  {
   
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
          ObjectSetInteger(NULL,"Range Start",OBJPROP_BACK,false); 
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
          ObjectSetInteger(NULL,"Range End",OBJPROP_BACK,false); 
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
          ObjectSetInteger(NULL,"Range End",OBJPROP_BACK,false); 
        }  
  }      
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+      