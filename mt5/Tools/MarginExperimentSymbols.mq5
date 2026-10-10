#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// JP225_HISTのTester内証拠金が0になる原因を切り分けるための実験用Custom Symbolを作成・削除する。
// JP225_HISTを複製し、計算モード／証拠金設定だけを変えた4銘柄を作り、JP225_HISTの短期間tickをコピーする。
// JP225_HIST自体は変更しない。InpDelete=trueで、この4銘柄だけを削除する。

input string InpSourceSymbol = "JP225_HIST";
input string InpTickFrom     = "2024.02.26"; // コピーするtick期間（Testerの事前バッファ確保のため対象日の前週から）
input string InpTickTo       = "2024.03.09";
input bool   InpDelete       = false;        // true = 実験用4銘柄を削除する（作成はしない）

string g_names[4]={"JP225_XMCFD","JP225_XMLEV","JP225_XMFUT","JP225_XMIDX"};
string g_labels[4]={"CFD(2)+rate10%","CFDLEVERAGE(4)+rate10%","FUTURES(1)+margin_initial","CFDINDEX(3)+rate10%+margin_initial"};

bool DeleteExperiments()
  {
   bool ok=true;
   for(int i=0;i<4;i++)
     {
      bool is_custom=false;
      if(!SymbolExist(g_names[i],is_custom))
         continue;
      if(!is_custom)
        {
         PrintFormat("EXP_DELETE_SKIPPED symbol=%s reason=NOT_CUSTOM",g_names[i]);
         ok=false;
         continue;
        }
      SymbolSelect(g_names[i],false);
      if(!CustomSymbolDelete(g_names[i]))
        {
         PrintFormat("EXP_DELETE_FAILED symbol=%s error=%d",g_names[i],GetLastError());
         ok=false;
        }
      else
         PrintFormat("EXP_DELETED symbol=%s",g_names[i]);
     }
   return ok;
  }

bool CreateExperiment(const int index,MqlTick &ticks[],const int tick_count)
  {
   const string name=g_names[index];
   bool is_custom=false;
   if(SymbolExist(name,is_custom))
     {
      PrintFormat("EXP_CREATE_ABORTED symbol=%s reason=ALREADY_EXISTS",name);
      return false;
     }
   if(!CustomSymbolCreate(name,"Custom\\EaTradingSystem\\Experiment",InpSourceSymbol))
     {
      PrintFormat("EXP_CREATE_FAILED symbol=%s error=%d",name,GetLastError());
      return false;
     }
   bool ok=true;
   switch(index)
     {
      case 0: ok=CustomSymbolSetInteger(name,SYMBOL_TRADE_CALC_MODE,SYMBOL_CALC_MODE_CFD); break;
      case 1: ok=CustomSymbolSetInteger(name,SYMBOL_TRADE_CALC_MODE,SYMBOL_CALC_MODE_CFDLEVERAGE); break;
      case 2:
         ok=CustomSymbolSetInteger(name,SYMBOL_TRADE_CALC_MODE,SYMBOL_CALC_MODE_FUTURES) &&
            CustomSymbolSetDouble(name,SYMBOL_MARGIN_INITIAL,4000.0) &&
            CustomSymbolSetDouble(name,SYMBOL_MARGIN_MAINTENANCE,4000.0);
         break;
      case 3:
         ok=CustomSymbolSetInteger(name,SYMBOL_TRADE_CALC_MODE,SYMBOL_CALC_MODE_CFDINDEX) &&
            CustomSymbolSetDouble(name,SYMBOL_MARGIN_INITIAL,4000.0) &&
            CustomSymbolSetDouble(name,SYMBOL_MARGIN_MAINTENANCE,4000.0);
         break;
     }
   if(!ok)
     {
      PrintFormat("EXP_SET_MODE_FAILED symbol=%s error=%d",name,GetLastError());
      return false;
     }
   CustomSymbolSetMarginRate(name,ORDER_TYPE_BUY,0.10,0.10);
   CustomSymbolSetMarginRate(name,ORDER_TYPE_SELL,0.10,0.10);
   SymbolSelect(name,true);
   const int chunk=200000;
   long added=0;
   for(int offset=0;offset<tick_count;offset+=chunk)
     {
      const int count=MathMin(chunk,tick_count-offset);
      MqlTick part[];
      ArrayResize(part,count);
      ArrayCopy(part,ticks,0,offset,count);
      const int result=CustomTicksAdd(name,part);
      if(result<0)
        {
         PrintFormat("EXP_TICKS_FAILED symbol=%s offset=%d error=%d",name,offset,GetLastError());
         return false;
        }
      added+=result;
     }
   PrintFormat("EXP_CREATED symbol=%s mode=%s ticks=%I64d",name,g_labels[index],added);
   return true;
  }

void OnStart()
  {
   if(InpDelete)
     {
      PrintFormat("EXP_DELETE_%s",DeleteExperiments() ? "COMPLETED" : "PARTIAL_FAILURE");
      return;
     }
   const datetime from=StringToTime(InpTickFrom);
   const datetime to=StringToTime(InpTickTo);
   MqlTick ticks[];
   const int tick_count=CopyTicksRange(InpSourceSymbol,ticks,COPY_TICKS_ALL,(ulong)from*1000,(ulong)to*1000);
   if(tick_count<=0)
     {
      PrintFormat("EXP_ABORTED reason=NO_SOURCE_TICKS error=%d",GetLastError());
      return;
     }
   PrintFormat("EXP_SOURCE_TICKS count=%d",tick_count);
   int created=0;
   for(int i=0;i<4;i++)
      if(CreateExperiment(i,ticks,tick_count))
         created++;
   PrintFormat("EXP_CREATE_%s created=%d/4",created==4 ? "COMPLETED" : "PARTIAL_FAILURE",created);
  }
