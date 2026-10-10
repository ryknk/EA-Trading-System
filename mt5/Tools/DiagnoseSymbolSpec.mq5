#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolと複製元の実Symbolについて、リスク計算・スプレッド判定・証拠金計算に関わる
// 仕様を出力する診断用スクリプト（読み取り専用。Symbolの作成・変更・削除は行わない）。
// 出力は MQL5\Files\EaTradingSystem\Diagnostics\<InpOutputFile> にタブ区切りで書き出す。

input string InpSymbols    = "USDJPY_HIST,USDJPY,JP225_HIST,US30_HIST,XAUUSD_HIST"; // 診断対象（カンマ区切り）
input string InpListFilter = "";                                                     // 空以外なら、部分一致するBroker全Symbol名を列挙する（カンマ区切り、大文字小文字無視）
input string InpOutputFile = "symbol-spec-diagnostics.tsv";
input double InpProbePrice = 0.0;  // 0なら各Symbolの現在Bidを使用。OrderCalcProfit/Margin検証用の建値
input double InpProbeStop  = 0.0;  // 0なら建値の1%を損切り幅として使用

#include <EaTradingSystem\Diagnostics\SymbolSpecDump.mqh>

void OnStart()
  {
   FolderCreate("EaTradingSystem\\Diagnostics");
   const int handle=FileOpen("EaTradingSystem\\Diagnostics\\"+InpOutputFile,FILE_WRITE|FILE_CSV|FILE_ANSI,'\t');
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("DIAG_FILE_OPEN_FAILED error=%d",GetLastError());
      return;
     }
   PrintFormat("DIAG_ACCOUNT currency=%s server=%s leverage=%d company=%s",
               AccountInfoString(ACCOUNT_CURRENCY),AccountInfoString(ACCOUNT_SERVER),
               (int)AccountInfoInteger(ACCOUNT_LEVERAGE),AccountInfoString(ACCOUNT_COMPANY));
   Emit(handle,"ACCOUNT","CURRENCY",AccountInfoString(ACCOUNT_CURRENCY));
   Emit(handle,"ACCOUNT","SERVER",AccountInfoString(ACCOUNT_SERVER));
   Emit(handle,"ACCOUNT","LEVERAGE",IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)));
   Emit(handle,"ACCOUNT","MARGIN_MODE",IntegerToString((int)AccountInfoInteger(ACCOUNT_MARGIN_MODE)));
   Emit(handle,"ACCOUNT","TESTER",MQLInfoInteger(MQL_TESTER) ? "true" : "false");

   if(StringLen(InpListFilter)>0)
      ListBrokerSymbols(handle,InpListFilter);

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
