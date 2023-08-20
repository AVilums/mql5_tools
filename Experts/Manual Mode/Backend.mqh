#include <Math\Stat\Stat.mqh>
#include <EasyAndFastGUI\WndCreate.mqh>
#include <EasyAndFastGUI\TimeCounter.mqh>

class CBackend : public CWndCreate {
   protected:
      CWindow m_window;

      CStatusBar m_status_bar;

      CTextEdit base;
      CTextEdit extreme;
      CTextEdit target;
      CTextEdit volume;
      
      CTextLabel rr;
      CTextLabel percentage;  
      CTextLabel cash;
      CTextLabel pip_value;

      CComboBox zone_type;
      CComboBox range_type;
      CComboBox entry_method;

      CButton add;
      CButton refresh;

   protected:

      void Calculate_RR();
      void Calculate_Pip_Value();
      void Calculate_Risk();

      double pipValue;

   public:
      CBackend(void);
      ~CBackend(void);

      void OnInitEvent(void);
      void OnDeinitEvent(const int reason);
      void OnTimerEvent(void);
      
      double GetBase() { return StringToDouble(base.GetValue());}
      double GetExtreme() { return StringToDouble(extreme.GetValue());}
      double GetTarget() { return StringToDouble(target.GetValue());}
      double GetVolume() { return StringToDouble(volume.GetValue());}

      virtual void OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

      bool CreateGUI(void);
};

#include "EntryMethods.mqh"
#include "MainWindow.mqh"
// #include <Trade/Trade.mqh>
// CTrade *trade = new CTrade;

CBackend::CBackend(void) {}
CBackend::~CBackend(void) {}

void CBackend::OnInitEvent(void) { }

void CBackend::OnDeinitEvent(const int reason) { 
   CWndEvents::Destroy();
   delete trade;
}

void CBackend::OnTimerEvent(void) { }

void CBackend::Calculate_RR() {
   double cBase = GetBase();
   double cExtreme = GetExtreme();
   double cTarget = GetTarget();

   double entry = get_half_zone(cBase, cExtreme);
   double r1 = MathAbs(entry - cExtreme);
   double r2 = MathAbs((entry - cTarget)/r1);

   if (entry_method.GetValue() == "EM1 (50%)") {

      r2 = MathRound(r2, 2);
      rr.LabelText("Risk-to-reward: " + DoubleToString(r2, 2));
      rr.Update(true);
   
   } else if (entry_method.GetValue() == "EM2 (base & 50%)") {

      double base = MathAbs(cBase - cExtreme);
      double r3 = MathAbs((cBase-cTarget)/base);

      r3 = MathRound((r2+r3)/2, 2);
      
      rr.LabelText("Risk-to-reward: " + DoubleToString(r3, 2));
      rr.Update(true); 
   }
}

void CBackend::Calculate_Risk() {
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);  

   if (entry_method.GetValue() == "EM1 (50%)") {
  
      double stop_range = MathAbs((GetBase() - GetExtreme())) / 2 * 100;
      double risk_cash = pipValue * stop_range;
      cash.LabelText("Risk €: " + DoubleToString(risk_cash, 2));
      cash.Update(true);

      double risk_percentage = MathAbs((risk_cash / account_balance)) * 100;
      percentage.LabelText("Risk %: " + DoubleToString(risk_percentage, 2));
      percentage.Update(true);
  
   } else if (entry_method.GetValue() == "EM2 (base & 50%)") {
      double stop_range = MathAbs((GetBase() - GetExtreme())) / 2 * 100;
      double risk_cash = (pipValue/2) * stop_range;
      
      stop_range = MathAbs((GetBase() - GetExtreme())) * 100;
      risk_cash = risk_cash + ((pipValue/2) * stop_range);
      
      cash.LabelText("Risk €: " + DoubleToString(risk_cash, 2));
      cash.Update(true);

   }
}

void CBackend::Calculate_Pip_Value() {
   double cVolume = GetVolume();
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double eur_ask = SymbolInfoDouble("EURGBP", SYMBOL_ASK);

   pipValue = ((cVolume/ask)*1000)*(2-eur_ask);
   pip_value.LabelText("Pip Value: " + DoubleToString(pipValue, 4));
   pip_value.Update(true); 
}

void CBackend::OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam) {   

   if (id == CHARTEVENT_CUSTOM + ON_CLICK_BUTTON) {

      Calculate_RR(); 
      Calculate_Pip_Value();
      Calculate_Risk();

      if (lparam == add.Id()) {
         double cbase = StringToDouble(base.GetValue());
         double cextreme = StringToDouble(extreme.GetValue());
         double ctarget = StringToDouble(target.GetValue());
         double cvolume = StringToDouble(volume.GetValue());

         string czone_type = zone_type.GetValue();
         string crange_type = range_type.GetValue();

         if (entry_method.GetValue() == "EM1 (50%)") {
            entry_method1(cbase, cextreme, ctarget, cvolume, czone_type);
         } else if (entry_method.GetValue() == "EM2 (base & 50%)") {
            entry_method2(cbase, cextreme, ctarget, cvolume, czone_type, crange_type);
         }
      }
      return;
   }
}