//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
#property copyright "Tupa Trading"
#property link "http://www.paulista.tk/tupatrading/"
#property version "0.0.1"
//---

enum STRATEGY_IN
{
   ONLY_MA,   // Only moving averages
   ONLY_RSI,  // Only RSI
   MA_AND_RSI // moving averages plus RSI
};

//---
// Variables Input
sinput string s0;                     //-----------Strategy-------------
input STRATEGY_IN strategy = ONLY_MA; // Trader Entry Strategy

sinput string s1;                                       //-----------Moving Averages-------------
input int ma_fast_period = 12;                          // Fast Moving Average Period
input int ma_slow_period = 32;                          // Slow Moving Average Period
input ENUM_TIMEFRAMES ma_time_graphic = PERIOD_CURRENT; // Graphic Time
input ENUM_MA_METHOD ma_method = MODE_EMA;              // Method
input ENUM_APPLIED_PRICE ma_price = PRICE_CLOSE;        // Price Applied

sinput string s2;                                        //-----------RSI-------------
input int rsi_period = 5;                                // RSI Period
input ENUM_TIMEFRAMES rsi_time_graphic = PERIOD_CURRENT; // Graphic Time
input ENUM_APPLIED_PRICE rsi_price = PRICE_CLOSE;        // Price Applied

input int rsi_overbought = 70; // Level Overbought
input int rsi_oversold = 30;   // Level Oversold

sinput string s3;         //---------------------------
input int num_lots = 100; // Number of lots
input double TK = 60;     // Take Profit
input double SL = 30;     // Stop Loss

sinput string s4;                      //---------------------------
input string limit_close_op = "17:40"; // Time Limit Close Position

//+------------------------------------------------------------------+
//| Variables for functions                                          |
//+------------------------------------------------------------------+

int magic_number = 123456; // Magic Number
int IndicadorHandle1;
double IndicadorHandle1Buffer[];
double IndicadorHandle1Buffer1[];
double IndicadorHandle1Buffer2[];

//big player candles
int inpLookbackPeriod = 20;
int inpVolumeType = 1;
int inpColorUHUp = 16776960;
int inpColorVHUp = 16776960;
int inpColorHUp = 6579200;
int inpColorMUp = 3289632;
int inpColorLUp = -1;
int inpColorUHDown = 255;
int inpColorVHDown = 255;
int inpColorHDown = 120;
int inpColorMDown = 3289667;
int inpColorLDown = -1;

MqlRates candle[]; // Variable for storing candles
MqlTick tick;      // Variable for storing ticks

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicadorHandle1 = iCustom(_Symbol, _Period, "Big Player Candles");

   if (IndicadorHandle1 < 0)
   {
      Alert("Error trying to create Handles for indicator - error: ", GetLastError(), "!");
      return (-1);
   }

   ChartIndicatorAdd(0, 0, IndicadorHandle1);

   CopyRates(_Symbol, _Period, 0, 4, candle);
   ArraySetAsSeries(candle, true);
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

datetime volumeTime;
int realVolumeAcc;
int tickVolumeAcc;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Feed candle buffers with data:
   CopyRates(_Symbol, _Period, 0, 10, candle);
   ArraySetAsSeries(candle, true);

   // Feed with tick variable data
   SymbolInfoTick(_Symbol, tick);

   CopyBuffer(IndicadorHandle1, 0, 0, 10, IndicadorHandle1Buffer);
   CopyBuffer(IndicadorHandle1, 1, 0, 10, IndicadorHandle1Buffer1);
   CopyBuffer(IndicadorHandle1, 2, 0, 10, IndicadorHandle1Buffer2);

   ArraySetAsSeries(IndicadorHandle1Buffer, true);

   ArraySetAsSeries(IndicadorHandle1Buffer1, true);

   ArraySetAsSeries(IndicadorHandle1Buffer2, true);

   // Print("Candle");
   // ArrayPrint(candle);
   Print("Big Player Candles:");
   ArrayPrint(IndicadorHandle1Buffer);
   ArrayPrint(IndicadorHandle1Buffer1);
   ArrayPrint(IndicadorHandle1Buffer2);
}
//+------------------------------------------------------------------+
//| FUNCTIONS TO ASSIST IN THE VISUALIZATION OF THE STRATEGY         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawVerticalLine(string name, datetime dt, color cor = clrAliceBlue)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_VLINE, 0, dt, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, cor);
}

//+------------------------------------------------------------------+
//| FUNCTIONS FOR SENDING ORDERS                                     |
//+------------------------------------------------------------------+

// BUY TO MARKET
void BuyAtMarket()
{
   MqlTradeRequest request; // request
   MqlTradeResult response; // response

   ZeroMemory(request);
   ZeroMemory(response);

   //--- For Buy Order
   request.action = TRADE_ACTION_DEAL;                   // Trade operation type
   request.magic = magic_number;                         // Magic number
   request.symbol = _Symbol;                             // Trade symbol
   request.volume = num_lots;                            // Lots number
   request.price = NormalizeDouble(tick.ask, _Digits);   // Price to buy
   request.sl = NormalizeDouble(tick.ask - SL, _Digits); // Stop Loss Price
   request.tp = NormalizeDouble(tick.ask + TK, _Digits); // Take Profit
   request.deviation = 0;                                // Maximal possible deviation from the requested price
   request.type = ORDER_TYPE_BUY;                        // Order type
   request.type_filling = ORDER_FILLING_FOK;             // Order execution type

   //---
   OrderSend(request, response);
   //---
   if (response.retcode == 10008 || response.retcode == 10009)
   {
      Print("Order Buy executed successfully!!");
   }
   else
   {
      Print("Error sending Order to Buy. Error = ", GetLastError());
      ResetLastError();
   }
}

// SELL TO MARKET
void SellAtMarket()
{
   MqlTradeRequest request; // request
   MqlTradeResult response; // response

   ZeroMemory(request);
   ZeroMemory(response);

   //--- For Sell Order
   request.action = TRADE_ACTION_DEAL;                   // Trade operation type
   request.magic = magic_number;                         // Magic number
   request.symbol = _Symbol;                             // Trade symbol
   request.volume = num_lots;                            // Lots number
   request.price = NormalizeDouble(tick.bid, _Digits);   // Price to sell
   request.sl = NormalizeDouble(tick.bid + SL, _Digits); // Stop Loss Price
   request.tp = NormalizeDouble(tick.bid - TK, _Digits); // Take Profit
   request.deviation = 0;                                // Maximal possible deviation from the requested price
   request.type = ORDER_TYPE_SELL;                       // Order type
   request.type_filling = ORDER_FILLING_FOK;             // Order execution type
                                                         //---
   OrderSend(request, response);
   //---
   if (response.retcode == 10008 || response.retcode == 10009)
   {
      Print("Order to Sell executed successfully!");
   }
   else
   {
      Print("Error sending Order to Sell. Error =", GetLastError());
      ResetLastError();
   }
}

//---
void CloseBuy()
{
   MqlTradeRequest request; // request
   MqlTradeResult response; // response

   ZeroMemory(request);
   ZeroMemory(response);

   //--- For Sell Order
   request.action = TRADE_ACTION_DEAL;
   request.magic = magic_number;
   request.symbol = _Symbol;
   request.volume = num_lots;
   request.price = 0;
   request.type = ORDER_TYPE_SELL;
   request.type_filling = ORDER_FILLING_RETURN;

   //---
   OrderSend(request, response);
   //---
   if (response.retcode == 10008 || response.retcode == 10009)
   {
      Print("Order to Sell executed successfully!");
   }
   else
   {
      Print("Error sending Order to Sell. Error =", GetLastError());
      ResetLastError();
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseSell()
{
   MqlTradeRequest request; // request
   MqlTradeResult response; // response

   ZeroMemory(request);
   ZeroMemory(response);

   //--- For Buy Order
   request.action = TRADE_ACTION_DEAL;
   request.magic = magic_number;
   request.symbol = _Symbol;
   request.volume = num_lots;
   request.price = 0;
   request.type = ORDER_TYPE_BUY;
   request.type_filling = ORDER_FILLING_RETURN;

   //---
   OrderSend(request, response);

   //---
   if (response.retcode == 10008 || response.retcode == 10009)
   {
      Print("Order Buy executed successfully!!");
   }
   else
   {
      Print("Error sending Order to Buy. Error = ", GetLastError());
      ResetLastError();
   }
}
//+------------------------------------------------------------------+
//| USEFUL FUNCTIONS                                                 |
//+------------------------------------------------------------------+
//--- for bar change
bool isNewBar()
{
   //--- memorize the time of opening of the last bar in the static variable
   static datetime last_time = 0;
   //--- current time
   datetime lastbar_time = (datetime)SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);

   //--- if it is the first call of the function
   if (last_time == 0)
   {
      //--- set the time and exit
      last_time = lastbar_time;
      return (false);
   }

   //--- if the time differs
   if (last_time != lastbar_time)
   {
      //--- memorize the time and return true
      last_time = lastbar_time;
      return (true);
   }
   //--- if we passed to this line, then the bar is not new; return false
   return (false);
}
//+------------------------------------------------------------------+
