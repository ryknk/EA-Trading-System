#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// Custom Symbolのバー履歴が失われたとき（Digits変更等）に、保持されているtickを同じ内容で書き戻し、
// バー履歴を再生成する。tickの値は変更しない。月単位で処理し、InpApply=falseは件数確認のみ。

input string InpSymbol    = "JP225_HIST";
input string InpFromMonth = "2024.03"; // 処理開始月（yyyy.mm）
input string InpToMonth   = "2024.03"; // 処理終了月（yyyy.mm、この月を含む）
input bool   InpApply     = false;     // true = CustomTicksReplaceで書き戻す

#include <EaTradingSystem\Diagnostics\SymbolBarRebuild.mqh>

void OnStart()
  {
   bool is_custom=false;
   if(!SymbolExist(InpSymbol,is_custom) || !is_custom)
     {
      PrintFormat("REBUILD_ABORTED reason=NOT_A_CUSTOM_SYMBOL symbol=%s",InpSymbol);
      return;
     }
   long total_ticks=0;
   const int failed_months=RebuildBarsFromTicksRange(InpSymbol,InpFromMonth,InpToMonth,InpApply,total_ticks);
   if(failed_months<0)
      return;
   PrintFormat("REBUILD_%s symbol=%s ticks=%I64d failed_months=%d",
               failed_months==0 ? "COMPLETED" : "PARTIAL_FAILURE",InpSymbol,total_ticks,failed_months);
  }
