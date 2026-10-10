#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom SymbolのDigitsだけを変更する実験用スクリプト（tick・その他の仕様は変更しない）。
// Digits変更がTesterのtick取得に与える影響を、未使用のSymbolで切り分けるために使う（DECISIONS.md DEC-033）。
// Digits変更はバー履歴（.hcc）を消去するため、事前にバックアップすること。InpApply=falseは現状値の出力のみ。

input string InpSymbol = "US500_HIST";
input int    InpDigits = 1;
input bool   InpApply  = false;

void OnStart()
  {
   bool is_custom=false;
   if(!SymbolExist(InpSymbol,is_custom) || !is_custom)
     {
      PrintFormat("DIGITS_ABORTED reason=NOT_A_CUSTOM_SYMBOL symbol=%s",InpSymbol);
      return;
     }
   const int before=(int)SymbolInfoInteger(InpSymbol,SYMBOL_DIGITS);
   PrintFormat("DIGITS_BEFORE symbol=%s digits=%d point=%.8f",InpSymbol,before,SymbolInfoDouble(InpSymbol,SYMBOL_POINT));
   if(!InpApply)
     {
      Print("DIGITS_SKIPPED reason=DRY_RUN");
      return;
     }
   ResetLastError();
   const bool ok=CustomSymbolSetInteger(InpSymbol,SYMBOL_DIGITS,InpDigits);
   PrintFormat("DIGITS_%s symbol=%s digits=%d point=%.8f error=%d",ok ? "SET" : "FAILED",InpSymbol,
               (int)SymbolInfoInteger(InpSymbol,SYMBOL_DIGITS),SymbolInfoDouble(InpSymbol,SYMBOL_POINT),GetLastError());
  }
