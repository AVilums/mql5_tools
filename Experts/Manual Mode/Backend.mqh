// Include necessary libraries
#include <Math\Stat\Stat.mqh>
#include <EasyAndFastGUI\WndCreate.mqh>
#include <EasyAndFastGUI\TimeCounter.mqh>

class CBackend : public CWndCreate {
  protected:
    CTimeCounter      m_counter1; // for updating execution process
    CTimeCounter      m_counter2; // for updating status bar items

    CWindow           m_window;

    CStatusBar        m_status_bar;

    CPicture          m_picture1;

    CTextEdit         base;
    CTextEdit         extreme;
    CTextEdit         target;
    CTextEdit         volume;
    
    CButton           add;
    
    CComboBox         zone_type;
    CComboBox         range_type;
    CComboBox         entry_method;

  public:
    CBackend(void);
    ~CBackend(void);

    void OnInitEvent(void);
    void OnDeinitEvent(const int reason);

    void OnTimerEvent(void);
    
    virtual void OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

    bool CreateGUI(void);
};

#include "MainWindow.mqh"
#include <Trade/Trade.mqh>

CTrade *trade = new CTrade;

CBackend::CBackend(void) {
   m_counter1.SetParameters(16,16);
   m_counter2.SetParameters(16,35);
}

CBackend::~CBackend(void) { }

void CBackend::OnInitEvent(void) { }

void CBackend::OnDeinitEvent(const int reason) { 
   CWndEvents::Destroy();
   delete trade;
}

void CBackend::OnTimerEvent(void) {
}

void CBackend::OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam) {   
   
   if (id == CHARTEVENT_CUSTOM + ON_CLICK_BUTTON) {
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

void entry_method1(double base, double extreme, double target, double volume, string zone_type) {
   double half_zone = MathAbs((base + extreme)/2);

   if (zone_type == "Buy Zone") { 
      trade.BuyLimit(volume, half_zone, NULL, extreme, target, ORDER_TIME_GTC, 0, "Here");
   } else if (zone_type == "Sell Zone") {
      trade.SellLimit(volume, half_zone, NULL, extreme, target, ORDER_TIME_GTC, 0, "Here");
   }
}

void entry_method2(double base, double extreme, double target, double volume, string zone_type, string range_type) {
   double half_zone = MathAbs((base + extreme)/2);
   double slippage = 0.015;

   if (range_type == "Wick") { return; }
   
   volume = MathRound(volume/2, 2); 
   // TODO calculate deviations 

   if (zone_type == "Buy Zone") {
      trade.BuyLimit(volume, base+slippage, NULL, extreme-slippage, target, ORDER_TIME_GTC, 0, "Here"); 
      trade.BuyLimit(volume, half_zone+slippage, NULL, extreme-slippage, target, ORDER_TIME_GTC, 0, "Here");
   } else if (zone_type == "Sell Zone") {
      trade.SellLimit(volume, base-slippage, NULL, extreme+slippage, target, ORDER_TIME_GTC, 0, "Here");
      trade.SellLimit(volume, half_zone-slippage, NULL, extreme+slippage, target, ORDER_TIME_GTC, 0, "Here");
   }
}