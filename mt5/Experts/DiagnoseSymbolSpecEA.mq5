#property copyright "EA-Trading-System"
#property strict

// Strategy Tester内でのSymbol仕様を出力する診断用Expert（発注・Symbol変更は行わない）。
// Tester Agentは端末と別のMQL5\Filesを持つため、結果はFILE_COMMON（Terminal\Common\Files）へ書き出す。

input string InpSymbols    = "USDJPY_HIST";
input string InpOutputFile = "symbol-spec-diagnostics-tester.tsv";
input double InpProbePrice = 0.0;
input double InpProbeStop  = 0.0;

#include <EaTradingSystem\Diagnostics\SymbolSpecDump.mqh>

bool g_dumped=false;

int OnInit()
  {
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   if(g_dumped)
      return;
   g_dumped=true;
   FolderCreate("EaTradingSystem\\Diagnostics",FILE_COMMON);
   const int handle=FileOpen("EaTradingSystem\\Diagnostics\\"+InpOutputFile,FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON,'\t');
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("DIAG_FILE_OPEN_FAILED error=%d",GetLastError());
      return;
     }
   Emit(handle,"ACCOUNT","CURRENCY",AccountInfoString(ACCOUNT_CURRENCY));
   Emit(handle,"ACCOUNT","LEVERAGE",IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)));
   Emit(handle,"ACCOUNT","EQUITY",DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   Emit(handle,"ACCOUNT","TESTER",MQLInfoInteger(MQL_TESTER) ? "true" : "false");
   Emit(handle,"ACCOUNT","CHART_SYMBOL",_Symbol);
   string symbols[];
   const int count=StringSplit(InpSymbols,',',symbols);
   for(int i=0;i<count;i++)
     {
      string symbol=symbols[i];
      StringTrimLeft(symbol);
      StringTrimRight(symbol);
      if(StringLen(symbol)>0)
         DumpSymbol(handle,symbol,InpProbePrice,InpProbeStop);
     }
   FileClose(handle);
   Print("DIAG_COMPLETED");
  }
