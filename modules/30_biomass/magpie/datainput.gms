*** |  (C) 2006-2024 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/30_biomass/magpie/datainput.gms

*** read in regional maxprod of pebioil and pebios (1st generation) biomass.
table p30_bio1stgen(tall,all_regi,all_enty)     "regional maximal production potential for 1st generation crops only (pebioil, pebios)"
$ondelim
$include "./modules/30_biomass/magpie/input/p30_bio1stgen.cs3r"
$offdelim
;

*** read in regional maxprod of pebiolc residues
table p30_biolcResidues(tall,all_regi,all_LU_emi_scen)  "regional potential for pebiolc residues"
$ondelim
$include "./modules/30_biomass/magpie/input/p30_biolcResidues.cs3r"
$offdelim
;

*** costs: use global costs for all regions ($/GJ -> T$/TWa)
*** define costs for pebiolc residues (2nd grade) 
*** and for pebios, pebioil (defined only for 5th grade)
p30_datapebio(regi,"pebios","5","cost",ttot)$(ttot.val ge 2005)  = 12.4 * s30_D2TD / sm_GJ_2_TWa;
p30_datapebio(regi,"pebioil","5","cost",ttot)$(ttot.val ge 2005) = 15.8 * s30_D2TD / sm_GJ_2_TWa;
p30_datapebio(regi,"pebiolc","2","cost",ttot)$(ttot.val ge 2005) =    1 * s30_D2TD / sm_GJ_2_TWa;

*** maxprod pebiolc: choose SSP and convert from PJ/yr to TWa/yr
p30_datapebio(regi,"pebiolc","2","maxprod",ttot)$(ttot.val ge 2005) = p30_biolcResidues(ttot,regi,"%cm_LU_emi_scen%") * sm_EJ_2_TWa / 1000;

*** maxprod 1st gen: use regional maxprod data from MAgPIE for 1st generation energy carriers (pebios, pebioil)
p30_datapebio(regi,"pebios","5","maxprod",ttot)$(ttot.val ge 2005) = p30_bio1stgen(ttot,regi,"pebios") * sm_EJ_2_TWa / 1000;
p30_datapebio(regi,"pebioil","5","maxprod",ttot)$(ttot.val ge 2005) = p30_bio1stgen(ttot,regi,"pebioil") * sm_EJ_2_TWa / 1000;
display p30_datapebio;

p30_pebiolc_pricemag(ttot,regi) = 0;
*** In coupled runs p30_pebiolc_pricemag gets updated in presolve since it changes between Nash iterations

*** Read production of ligno-cellulosic purpose grown bioenergy from look-up table (used to calculate bioenergy costs in standalone runs and substract them from budget equation)
parameter p30_biolcProductionLookup(tall,all_regi,all_LU_emi_scen,all_rcp_scen)  "regional production of pebiolc purpose grown"
/
$ondelim
$include "./modules/30_biomass/magpie/input/p30_biolcProductionLookup.cs4r"
$offdelim
/
;

*** select pebiolc productoion from look-up table according to SSP and RCP
pm_pebiolc_demandmag(ttot,regi) = p30_biolcProductionLookup(ttot,regi,"%cm_LU_emi_scen%","%cm_rcp_scen%");
*** In coupled runs pm_pebiolc_demandmag gets updated in presolve since it changes between Nash iterations

*** Read parameters for bioenergy supply curve
parameter f30_bioen_price(tall,all_regi,all_LU_emi_scen,all_rcp_scen,all_charScen)  "time dependent fit coefficients for bioenergy price formula"
/
$ondelim
$include "./modules/30_biomass/magpie/input/f30_bioen_price.cs4r"
$offdelim
/
;

*** Why is this necessary? Isn't pm_pebiolc_costs_emu_preloop ALWAYS calculated in preloop, overwriting what has been loaded here?
if (cm_startyear gt 2005,
Execute_Loadpoint "input_ref.gdx", pm_pebiolc_costs_emu_preloop;
);

*** Select bioenergy bioenergy supply curve according to SSP scenario
i30_bioen_price_a(ttot,regi) = f30_bioen_price(ttot,regi,"%cm_LU_emi_scen%","%cm_rcp_scen%","a");
i30_bioen_price_b(ttot,regi) = f30_bioen_price(ttot,regi,"%cm_LU_emi_scen%","%cm_rcp_scen%","b");

*** FS: scale bioenergy supply curves of EU regions such that it matches with EUR bioenergy potential of H12/MagPIE runs
i30_bioen_price_b(ttot,regi)$(regi_group("EUR_regi",regi)) = cm_BioSupply_Adjust_EU * i30_bioen_price_b(ttot,regi)$(regi_group("EUR_regi",regi));

*RP* in 2005 and 2010, we always want to use bau values
loop(ttot$( (ttot.val = 2005) OR (ttot.val = 2010) ),
    i30_bioen_price_a(ttot,regi)  =  f30_bioen_price(ttot,regi,"%cm_LU_emi_scen%","rcp45","a");
    i30_bioen_price_b(ttot,regi)  =  f30_bioen_price(ttot,regi,"%cm_LU_emi_scen%","rcp45","b");
);
display i30_bioen_price_a, i30_bioen_price_b;

*** default: no binding limit on 1st generation biomass for any region
p30_limit_1stgen_total(ttot,regi) = 1e10;

*** -------------------------------------------------------------
*** BioMIP biomass availability sensitivities for Germany (cm_bioMIP_bio)
*** Source: sensitivities/BioMIP_BiomassSenstivity.xlsx, values in PJ/yr
***   res:    woody + digestible residues                  -> pebiolc grade 2
***   src:    short rotation coppice (2nd gen energy crop) -> pebiolc grade 1
***   fstgen: 1st gen crops for biodiesel/bioethanol + oily residues -> pebios + pebioil
*** 1st gen digestibles (energy crops for biogas) are not included yet, as the
*** respective technology is not represented in REMIND.
*** 2035 and 2045 are interpolated linearly, values are kept constant after 2050.
*** -------------------------------------------------------------
$ifthen.bioMIP not "%cm_bioMIP_bio%" == "off"
p30_bioMIP_pot(ttot,bioMIPtype30) = 0;
$ifthen.bioMIPscen "%cm_bioMIP_bio%" == "trends"
*** Current Trends: phase down 1st gen, SRC expansion, residue mobilization 30/45/60%
p30_bioMIP_pot("2030","res")    = 608.7;
p30_bioMIP_pot("2040","res")    = 640.0;
p30_bioMIP_pot("2050","res")    = 649.3;
p30_bioMIP_pot("2030","src")    = 106.6;
p30_bioMIP_pot("2040","src")    = 255.8;
p30_bioMIP_pot("2050","src")    = 255.8;
p30_bioMIP_pot("2030","fstgen") = 214.0;
p30_bioMIP_pot("2040","fstgen") = 214.6;
p30_bioMIP_pot("2050","fstgen") = 215.1;
$elseif.bioMIPscen "%cm_bioMIP_bio%" == "frozen"
*** Frozen World: constant 1st gen, no SRC, residue mobilization 30/45/60%
p30_bioMIP_pot("2030","res")    = 608.7;
p30_bioMIP_pot("2040","res")    = 640.0;
p30_bioMIP_pot("2050","res")    = 649.3;
p30_bioMIP_pot("2030","fstgen") = 189.8;
p30_bioMIP_pot("2040","fstgen") = 190.4;
p30_bioMIP_pot("2050","fstgen") = 190.9;
$elseif.bioMIPscen "%cm_bioMIP_bio%" == "low"
*** Low Biomass: energy crop phase-out by 2040, residue mobilization 10/20/30%
p30_bioMIP_pot("2030","res")    = 600.4;
p30_bioMIP_pot("2040","res")    = 623.5;
p30_bioMIP_pot("2050","res")    = 630.1;
p30_bioMIP_pot("2030","fstgen") = 147.0;
p30_bioMIP_pot("2040","fstgen") =  19.3;
p30_bioMIP_pot("2050","fstgen") =  19.6;
$elseif.bioMIPscen "%cm_bioMIP_bio%" == "high"
*** High Biomass: SRC expansion, residue mobilization 60/80/100%
p30_bioMIP_pot("2030","res")    = 619.0;
p30_bioMIP_pot("2040","res")    = 660.6;
p30_bioMIP_pot("2050","res")    = 667.5;
p30_bioMIP_pot("2030","src")    = 226.0;
p30_bioMIP_pot("2040","src")    = 556.5;
p30_bioMIP_pot("2050","src")    = 556.5;
p30_bioMIP_pot("2030","fstgen") = 160.3;
p30_bioMIP_pot("2040","fstgen") = 132.3;
p30_bioMIP_pot("2050","fstgen") = 134.3;
$endif.bioMIPscen

*** interpolate 2035 and 2045, keep 2050 values constant afterwards
p30_bioMIP_pot("2035",bioMIPtype30) = 0.5 * (p30_bioMIP_pot("2030",bioMIPtype30) + p30_bioMIP_pot("2040",bioMIPtype30));
p30_bioMIP_pot("2045",bioMIPtype30) = 0.5 * (p30_bioMIP_pot("2040",bioMIPtype30) + p30_bioMIP_pot("2050",bioMIPtype30));
p30_bioMIP_pot(ttot,bioMIPtype30)$(ttot.val gt 2050) = p30_bioMIP_pot("2050",bioMIPtype30);

*** 1st generation limit for DEU, enforced by q30_limit_1stgen_total [PJ]
p30_limit_1stgen_total(ttot,regi)$(sameas(regi,"DEU") AND ttot.val ge 2030) = p30_bioMIP_pot(ttot,"fstgen");
display p30_bioMIP_pot, p30_limit_1stgen_total;
$endif.bioMIP

*** EOF ./modules/30_biomass/magpie/datainput.gms