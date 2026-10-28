*** |  (C) 2006-2024 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/30_biomass/magpie/sets.gms

sets
all_charScen                 "coefficients of the emulator formulas"   
/ a,b,c /

peren2rlf30(all_enty,rlf)    "map biomass energy to grades"
/
        pebios.(5)            
        pebioil.(5)
        pebiolc.2            "residues from agriculture and forestry"
/

peren2cont30(all_enty,rlf)   "map biomass energy to grades with continous supplycurve"
/
        pebiolc.1         "purpose grown"
/

bioMIPtype30                 "BioMIP biomass feedstock types for DEU sensitivities (cm_bioMIP_bio)"
/
        res               "woody and digestible residues (pebiolc.2)"
        src               "short rotation coppice (pebiolc.1)"
        fstgen            "1st generation crops for biodiesel and bioethanol, oily residues (pebios + pebioil)"
/

;

*** EOF ./modules/30_biomass/magpie/sets.gms
