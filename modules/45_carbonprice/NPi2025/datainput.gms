*** |  (C) 2006-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/45_carbonprice/NPi2025/datainput.gms

***----------------------------
*** CO2 Tax level growing exponentially from 2025 value taken from input data
***----------------------------

*** for years up to 2025 take CO2 price defined by fm_taxCO2eqHist 
*** fm_taxCO2eqHist reflects historical carbon prices and
*** assumptions on current aggregate effect of other policies
pm_taxCO2eq(ttot,regi)$(ttot.val le 2025) = fm_taxCO2eqHist(ttot,regi) * sm_DptCO2_2_TDpGtC;

*** for years after 2025, assume modest linear increase of CO2 price by 20 USD/tCO2 over 75 years (2025-2100)
pm_taxCO2eq(t,regi)$(t.val gt 2025) = pm_taxCO2eq("2025",regi)
                                      + (t.val - 2025) * (20/75) * sm_DptCO2_2_TDpGtC;


*** for EU, take carbon price from fm_taxCO2eqHist up to 2030,
*** then increase linearly by 20 USD/tCO2 over 75 years (2030-2100)
loop(ext_regi$sameas(ext_regi, "EUR_regi"),
  pm_taxCO2eq(t,regi)$(     t.val ge 2030
                        AND regi_group(ext_regi,regi)) = ( fm_taxCO2eqHist("2030",regi)
                                                           + (t.val - 2030) * (20/75) ) * sm_DptCO2_2_TDpGtC;
 );


*** after 2100, keep CO2 price constant at 2100 level
pm_taxCO2eq(t,regi)$(t.val gt 2100) = pm_taxCO2eq("2100",regi);

*** switch off MAC abatement of land emissions, scenario should only have Magpie baseline emissions
pm_macSwitch(ttot,regi,emiMacMagpie) = 0;

*** EOF ./modules/45_carbonprice/NPi2025/datainput.gms
