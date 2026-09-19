#property copyright "EA-Trading-System"
#property strict
#property script_show_inputs

// 複製元を持たずに作成されたCFD系Custom Symbol（JP225_HIST/US30_HIST/XAUUSD_HIST）の仕様を、
// OANDA証券の公開仕様（原ページで照合済み、DECISIONS.md DEC-033参照）へ設定する。
// tick履歴には触れず、Symbolの削除・再作成も行わない。ただしDigitsの変更はMT5がバー履歴（.hcc）を
// 消去するため、全仕様の適用後はRebuildBarsFromTicksでバーを再生成すること（2026-09-19確認）。
// InpApply=false（既定）は現状値の出力のみで、何も変更しない。

input string InpTargetSymbol = "JP225_HIST"; // JP225_HIST / US30_HIST / XAUUSD_HIST のいずれか
input bool   InpApply        = false;        // true = 仕様を書き換える
input bool   InpMarginRateOnly = false;      // true = 計算モードと証拠金率のみ設定する（Digits等は触らない。Digits変更はバー履歴を消去するため）
input string InpOutputPrefix = "cfd-spec";   // MQL5\Files\EaTradingSystem\Diagnostics\<prefix>-<symbol>-before|after.tsv
input string InpRebuildFromMonth = "";       // 空以外なら、適用後に指定月範囲のバーをtickから再生成する（yyyy.mm）
input string InpRebuildToMonth   = "";       // 再生成の終了月（この月を含む）

#include <EaTradingSystem\Diagnostics\SymbolSpecDump.mqh>
#include <EaTradingSystem\Diagnostics\SymbolBarRebuild.mqh>

struct SCfdSpec
  {
   int    digits;
   double tick_size;
   double contract_size;
   double volume_min;
   double volume_step;
   double volume_max;
   string currency_base;
   string currency_profit;
   string currency_margin;
   ENUM_SYMBOL_CALC_MODE calc_mode;
   double margin_rate;
  };

bool LoadSpec(const string symbol,SCfdSpec &spec)
  {
   ZeroMemory(spec);
   if(symbol=="JP225_HIST")
     {
      spec.digits=1; spec.tick_size=0.1; spec.contract_size=1.0;
      spec.volume_min=1.0; spec.volume_step=1.0; spec.volume_max=10000.0;
      spec.currency_base="JPY"; spec.currency_profit="JPY"; spec.currency_margin="JPY";
      spec.calc_mode=SYMBOL_CALC_MODE_CFD;
      spec.margin_rate=0.10;
      return true;
     }
   if(symbol=="US30_HIST")
     {
      spec.digits=1; spec.tick_size=0.1; spec.contract_size=1.0;
      spec.volume_min=0.1; spec.volume_step=0.1; spec.volume_max=100.0; // 最大取引数量100（最大建玉数量は250）
      spec.currency_base="USD"; spec.currency_profit="USD"; spec.currency_margin="USD";
      spec.calc_mode=SYMBOL_CALC_MODE_CFD;
      spec.margin_rate=0.10;
      return true;
     }
   if(symbol=="XAUUSD_HIST")
     {
      spec.digits=3; spec.tick_size=0.001; spec.contract_size=100.0;
      spec.volume_min=0.01; spec.volume_step=0.01; spec.volume_max=20.0;
      spec.currency_base="XAU"; spec.currency_profit="USD"; spec.currency_margin="USD";
      spec.calc_mode=SYMBOL_CALC_MODE_CFD;
      spec.margin_rate=0.05;
      return true;
     }
   return false;
  }

bool Check(const bool ok,const string what)
  {
   if(!ok)
      PrintFormat("APPLY_STEP_FAILED step=%s error=%d",what,GetLastError());
   return ok;
  }

bool ApplyMarginRate(const string symbol,const SCfdSpec &spec)
  {
   ResetLastError();
   bool ok=true;
   // CFDINDEX/FUTURESはSYMBOL_MARGIN_INITIAL（固定額）基準で証拠金が計算され、0のままだと証拠金が0になる
   // （2026-09-19実測）。価格連動で証拠金率が効くCFDモードを使う。
   ok=Check(CustomSymbolSetInteger(symbol,SYMBOL_TRADE_CALC_MODE,spec.calc_mode),"CALC_MODE") && ok;
   ok=Check(CustomSymbolSetMarginRate(symbol,ORDER_TYPE_BUY,spec.margin_rate,spec.margin_rate),"MARGIN_RATE_BUY") && ok;
   ok=Check(CustomSymbolSetMarginRate(symbol,ORDER_TYPE_SELL,spec.margin_rate,spec.margin_rate),"MARGIN_RATE_SELL") && ok;
   return ok;
  }

bool ApplySpec(const string symbol,const SCfdSpec &spec)
  {
   ResetLastError();
   bool ok=true;
   // Volume Min/Maxの前後関係が不整合になる瞬間を作らないよう、拡大側（Max）から先に設定する。
   ok=Check(CustomSymbolSetDouble(symbol,SYMBOL_VOLUME_MAX,spec.volume_max),"VOLUME_MAX") && ok;
   ok=Check(CustomSymbolSetDouble(symbol,SYMBOL_VOLUME_MIN,spec.volume_min),"VOLUME_MIN") && ok;
   ok=Check(CustomSymbolSetDouble(symbol,SYMBOL_VOLUME_STEP,spec.volume_step),"VOLUME_STEP") && ok;
   ok=Check(CustomSymbolSetInteger(symbol,SYMBOL_DIGITS,spec.digits),"DIGITS") && ok;
   ok=Check(CustomSymbolSetDouble(symbol,SYMBOL_TRADE_TICK_SIZE,spec.tick_size),"TICK_SIZE") && ok;
   ok=Check(CustomSymbolSetDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE,spec.contract_size),"CONTRACT_SIZE") && ok;
   ok=Check(CustomSymbolSetInteger(symbol,SYMBOL_TRADE_CALC_MODE,spec.calc_mode),"CALC_MODE") && ok;
   ok=Check(CustomSymbolSetString(symbol,SYMBOL_CURRENCY_BASE,spec.currency_base),"CURRENCY_BASE") && ok;
   ok=Check(CustomSymbolSetString(symbol,SYMBOL_CURRENCY_PROFIT,spec.currency_profit),"CURRENCY_PROFIT") && ok;
   ok=Check(CustomSymbolSetString(symbol,SYMBOL_CURRENCY_MARGIN,spec.currency_margin),"CURRENCY_MARGIN") && ok;
   ok=ApplyMarginRate(symbol,spec) && ok;
   return ok;
  }

void DumpToFile(const string symbol,const string suffix)
  {
   const string path="EaTradingSystem\\Diagnostics\\"+InpOutputPrefix+"-"+symbol+"-"+suffix+".tsv";
   const int handle=FileOpen(path,FILE_WRITE|FILE_CSV|FILE_ANSI,'\t');
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("DIAG_FILE_OPEN_FAILED path=%s error=%d",path,GetLastError());
      return;
     }
   DumpSymbol(handle,symbol,0.0,0.0);
   FileClose(handle);
  }

void OnStart()
  {
   SCfdSpec spec;
   if(!LoadSpec(InpTargetSymbol,spec))
     {
      PrintFormat("APPLY_ABORTED reason=UNSUPPORTED_SYMBOL symbol=%s",InpTargetSymbol);
      return;
     }
   bool is_custom=false;
   if(!SymbolExist(InpTargetSymbol,is_custom) || !is_custom)
     {
      PrintFormat("APPLY_ABORTED reason=NOT_A_CUSTOM_SYMBOL symbol=%s",InpTargetSymbol);
      return;
     }
   FolderCreate("EaTradingSystem\\Diagnostics");
   DumpToFile(InpTargetSymbol,"before");
   if(!InpApply)
     {
      PrintFormat("APPLY_SKIPPED reason=DRY_RUN symbol=%s",InpTargetSymbol);
      return;
     }
   const bool ok=(InpMarginRateOnly ? ApplyMarginRate(InpTargetSymbol,spec) : ApplySpec(InpTargetSymbol,spec));
   DumpToFile(InpTargetSymbol,"after");
   PrintFormat("APPLY_%s symbol=%s",ok ? "COMPLETED" : "PARTIAL_FAILURE",InpTargetSymbol);
   // 仕様適用に失敗した場合はバー再生成へ進まない（中途半端な状態でtickを書き戻さない）。
   if(ok && StringLen(InpRebuildFromMonth)>0 && StringLen(InpRebuildToMonth)>0)
     {
      long total_ticks=0;
      const int failed_months=RebuildBarsFromTicksRange(InpTargetSymbol,InpRebuildFromMonth,InpRebuildToMonth,true,total_ticks);
      PrintFormat("REBUILD_%s symbol=%s ticks=%I64d failed_months=%d",
                  failed_months==0 ? "COMPLETED" : "PARTIAL_FAILURE",InpTargetSymbol,total_ticks,failed_months);
     }
  }
