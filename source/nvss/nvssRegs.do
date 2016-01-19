/* nvssRegs.do v0.00             damiancclarke             yyyy-mm-dd:2015-04-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses NVSS data on first births and runs regressions on births by quar-
ter, allowing for additional controls, fixed effects, and so forth.

The main set of tables are made for married women only.  In the online appendix,
the results are replicated for married and unmarried women.  Running this file m
akes the main tables, however, if the full sample results are desired, the local
on line 19 should be set equal to 1.

*/

vers 11
clear all
set more off
cap log close

local allobs 1

********************************************************************************
*** (1) globals and locals
********************************************************************************
if `allobs'==0 local f nvss
if `allobs'==1 local f nvssall

global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/`f'/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

#delimit ;
local qual   birthweight lbw vlbw gestation premature apgar;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats        
             (N, fmt(%9.0g) label(Observations))                               
             starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label;
local yFE    i.year;
local se     robust;
local cnd    if twin==1 & motherAge>24 & motherAge <= 45 & liveBirth==1;
local keepif birthOrder==1;
#delimit cr

********************************************************************************
*** (2a) Open data for births and deaths
********************************************************************************
use          "$DAT/nvss2005_2013"
append using "$DAT/nvssFD2005_2013"
if `allobs'==0 keep if married==1

********************************************************************************
*** (3a) Good Quarter Regressions
********************************************************************************
#delimit ;
local add `" ""  "(No September)" "(Birth Order = 2)" "(Twin sample)" "';
local nam Main NoSep Bord2 Twin;
#delimit cr
tokenize `nam'

foreach type of local add {
    preserve

    local age age2527 age2831 age3239
    local edu highEd
    local con married smoker value i.gestation
    local con smoker value i.gestation
    local yab abs(fips)
    local spcnd
    local group `cnd'&`keepif'
    local samp1 "singleton"
    local samp2 "first born"
    
    if `"`1'"' == "NoSep" local spcnd if birthMonth!=9
    if `"`1'"' == "Bord2" local group `cnd'&birthOrder==2&liveBirth==1
    if `"`1'"' == "Twin"  local group /*
           */ if twin==2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "Bord2" local samp2 "second born"
    if `"`1'"' == "Twin"  local samp1 "twin" 

    keep `group'

    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000

    eststo: areg goodQuarter `age' `edu' _year* if e(sample) , `se' `yab'
    test `age'
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000

    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000

    keep if year>=2009&ART!=.
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000

    eststo: areg goodQuarter `age' `edu' `con' _year* noART `spcnd', `se' `yab'
    test `age'
    local F6 = round(r(p)*1000)/1000
    if   `F6' == 0 local F6 0.000

    #delimit ;
    esttab est4 est3 est2 est1 est5 est6 using "$OUT/NVSSBinary`1'.tex",
    replace `estopt' title("Season of Birth Correlates `type'") booktabs 
    keep(_cons `age' `edu' noART smoker value) style(tex) mlabels(, depvar)
    postfoot("F-test of Age Dummies&`F4'&`F3'&`F2'&`F1'&`F5'&`F6' \\        "
             "State and Year FE&&Y&Y&Y&Y&Y\\ Gestation FE &&&&Y&Y&Y\\       "
             "2009-2013 Only&&&&&Y&Y\\ \bottomrule                          "
             "\multicolumn{7}{p{20cm}}{\begin{footnotesize}Sample consists  "
             "of `samp1'   `samp2'    children to non-Hispanic white women  "
             "aged 25-45. Independent variables are binary, except for      "
             "unemployment, which is measured as the unemployment rate in   "
             "the mother's state in the month of conception. Standard errors"
             "are clustered by state.                                       "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.         "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    macro shift
    restore
}

********************************************************************************
*** (3b) Age continuous, or quadratic
********************************************************************************
local names `" "(age as a continuous variable)" "(age and age squared)" "'
local edu highEd
local con married smoker value 
local con smoker value 
local yab abs(fips)
local age motherAge
local app A

foreach AA of local names {
    preserve
    keep `cnd'&`keepif'
    
    if `"`AA'"'=="(age and age squared)" local age motherAge motherAge2
    if `"`AA'"'=="(age and age squared)" local app A2


    eststo: areg goodQuarter `age' `edu' `con' _year*             , `se' `yab'
    eststo: areg goodQuarter `age' `edu'       _year* if e(sample), `se' `yab'
    eststo: areg goodQuarter `age'             _year* if e(sample), `se' `yab'
    eststo:  reg goodQuarter `age'                    if e(sample), `se'
    keep if year>=2009&ART!=.
    eststo: areg goodQuarter `age' `edu' `con' _year*             , `se' `yab'
    eststo: areg goodQuarter `age' `edu' `con' _year* noART       , `se' `yab'


    local vars _cons `age' `edu' `con' noART

    #delimit ;
    esttab est4 est3 est2 est1 est5 est6 using "$OUT/NVSSBinaryMain_`app'.tex",
    replace `estopt' booktabs keep(`vars') mlabels(, depvar)
    title("Season of Birth Correlates `AA'")
    postfoot("State and Year FE&&Y&Y&Y&Y&Y\\ Gestation FE&&&&Y&Y&Y \\        "
             "2009-2013 Only &&&&&Y&Y\\ \bottomrule                            "
             "\multicolumn{7}{p{20cm}}{\begin{footnotesize}Sample consists     "
             " of singleton first-born children to non-Hispanic white women    "
             "aged 25-45. Independent variables are binary, except for age,    "
             "which is in years, and unemployment, which is measured as the    "
             "unemployment rate in the mother's state in the month of          "
             "conception. Standard errors are clustered by state.              "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            " 
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
    restore
}

********************************************************************************
*** (3c) Good Season, Age and education interactions
********************************************************************************
preserve
keep `cnd'&`keepif'
gen motherAge2Xeduc = motherAge2*educCat
lab var motherAge2Xeduc "Mother's Age$^2$ $\times$ Education"

local age1  age2527 age2831 age3239
local age1X age2527XhighEd age2831XhighEd age3239XhighEd
local age2  motherAge motherAge2

local v1 `age1' smoker highEd `age1X' _year* 
local v2 `age1' smoker highEd         _year*
local v3 `age1' smoker                _year*
local v4 `age2' smoker educCat        _year*
local v5 `age2' smoker                _year*

eststo: areg goodQua `v1', abs(fips)
test `age1'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000

foreach num of numlist 2(1)5 {
    eststo: areg goodQua `v`num'' if e(sample), abs(fips)
    if `num'< 4 test `age1'
    if `num'> 3 test `age2'
    
    local F`num' = round(r(p)*1000)/1000
    if  `F`num'' == 0 local F`num' 0.000
}

local kvar `age1' highEd `age1X' `age2' educCat
#delimit ;
esttab est3 est2 est1 est5 est4 using "$OUT/NVSSBinaryEducAge.tex",
replace `estopt' booktabs keep(`kvar') mlabels(, depvar)
title("Season of Birth, Age and Education")
postfoot("F-test of Age Dummies&`F3'&`F2'&`F1'&`F5'&`F4' \\ \bottomrule    "
         "\multicolumn{6}{p{18cm}}{\begin{footnotesize}Sample consists     "
         " of singleton first-born children to non-Hispanic white women    "
         "aged 25-45. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01." 
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
restore

********************************************************************************
*** (4) ART and Teens
********************************************************************************
preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `keepif'
local con highEd married smoker value _year*
local con highEd smoker value _year*

eststo: areg goodQuarter age2024 ART            `con'              , abs(fips)
eststo: areg goodQuarter age2024 ART            _year* if e(sample), abs(fips)
eststo:  reg goodQuarter age2024 ART                   if e(sample)
eststo: areg goodQuarter age2024 ART ARTage2024 `con'              , abs(fips)
eststo: areg goodQuarter age2024 ART ARTage2024 _year* if e(sample), abs(fips)
eststo:  reg goodQuarter age2024 ART ARTage2024        if e(sample)

#delimit ;
esttab est3 est2 est1 est6 est5 est4 using "$OUT/ART2024.tex",
replace `estopt' keep(_cons age2024 ART ARTage2024) style(tex) 
title("Season of Birth Correlates: Very Young (20-24) and ART users") booktabs
postfoot("State and Year FE&&Y&Y&&Y&Y\\ Controls&&&Y&&&Y\\  \bottomrule "
         "\multicolumn{7}{p{19cm}}{\begin{footnotesize}Sample consists  "
         "of singleton first-born children to non-Hispanic white women  "
         "aged 20-45 in the years 2009-2013.                            "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.         "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore

********************************************************************************
*** (5) Regressions (Quality on Age, season)
********************************************************************************
local c1      twin==1&birthOrd==1&liveBir==1 twin==2&birthOrder==1&liveBir==1 /*
           */ twin==1&birthOrd==2&liveBir==1 twin==1&birthOrd==1
local varsY   age2527 age2831 age3239 
local varsA   motherAge 
local varsA2  motherAge motherAge2 
local control goodQuarter highEd smoker value
local names   Main Twin Bord2 FDeaths
tokenize `names'


foreach cond of local c1 {
    if `"`1'"'=="Main"    local title "Main Sample"
    if `"`1'"'=="Twin"    local title "Twin Sample"
    if `"`1'"'=="Bord2"   local title "Birth Order 2"
    if `"`1'"'=="FDeaths" local title "Including Fetal Deaths"

    dis "`1', `title'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    foreach ageType in Y A A2 {
        local nT "_`ageType'"
        if `"`ageType'"'=="Y" local nT

        local jj=1
        foreach y of varlist `qual' {
            eststo: areg `y' `vars`ageType'' `control' `yFE', `se' abs(fips)
            test `vars`ageType''
            local F`jj' = round(r(p)*1000)/1000
            if   `F`jj'' == 0 local F`jj' 0.000
            local ++jj
        }
    
        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality`1'`nT'.tex",
        replace `estopt' title("Birth Quality by Age and Season (`title')")
        keep(_cons `vars`ageType'' `control') style(tex) mlabels(, depvar) 
        postfoot("F-test of Age Variables&`F1'&`F2'&`F3'&`F4'&`F5'&`F6' \\     "
                 "\bottomrule"
                 "\multicolumn{7}{p{17cm}}{\begin{footnotesize}Sample consists "
                 "of singleton first-born children to non-Hispanic white women "
                 "aged 25-45. State and year fixed effects are included, and   "
                 "standard errors are clustered by state.                      "
                 "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.        "
                 "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
        #delimit cr
        estimates clear
    }
    
    macro shift
    restore
}

keep if `keepif'

********************************************************************************
*** (6) Appendix including fetal deaths
********************************************************************************
keep if twin==1 & motherAge>24 & motherAge <= 45

local age age2527 age2831 age3239
local edu highEd
local con smoker value
local yab abs(fips)
local ges i.gestation
local spcnd

eststo: areg goodQuarter `age' `con' _year* i.gestation , `se' `yab'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000
eststo: areg goodQuarter `age' `con' _year*             , `se' `yab'
    test `age'
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000
eststo: areg goodQuarter `age'       _year* if e(sample), `se' `yab'
    test `age'
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000
eststo:  reg goodQuarter `age'              if e(sample), `se'
    test `age'
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000
    
#delimit ;
esttab est4 est3 est2 est1 using "$OUT/NVSSBinaryFDeaths.tex",
replace `estopt' title("Birth Season and Age (Including Fetal Deaths)") 
keep(_cons `age' `con') style(tex) mlabels(, depvar)
postfoot("F-test of Age Dummies&`F4'&`F3'&`F2'&`F1' \\                       "
         "State and Year FE&&Y&Y&Y\\  Gestation FE &&&&Y \\ \bottomrule      "
         "\multicolumn{5}{p{14cm}}{\begin{footnotesize}Sample consists of all"
         "first live births and fetal deaths of US-born, white, non-hispanic "
         "mothers aged between 25 and 45.  Fetal deaths are included if      "
         "occurring between 25 and 44 weeks of gestation.                    "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs ;
#delimit cr
estimates clear

********************************************************************************
*** (7) Appendix examining missing covariates
********************************************************************************
preserve
keep `cnd'&`keepif'
gen smokeMissing = smoker    == .
gen educMissing  = educLevel == .
gen fatherAgeMis = fatherAge == 11
foreach year of numlist 2005(1)2013 {
    foreach var in smoke educ {
        gen `var'Missing`year' = 1 if `var'Missing & year==`year'
        replace `var'Missing`year' = 0 if `var'Missing`year'==.
    }
    lab var educMissing`year'  "Missing Education$\times$ `year'"
    lab var smokeMissing`year' "Missing Smoking$\times$ `year'"
}
lab var smokeMissing "Missing Smoking"
lab var educMissing  "Missing Education"
lab var fatherAgeMis "Father's Age Not Known"

local base young
local y goodQuarter
eststo: reg `y' `base' educMissing   smokeMissing              `yFE', `se'
eststo: reg `y' `base' educMissing   smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing2* fatherAgeM `yFE', `se'
#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSMissing.tex",
replace `estopt' title("Missing Records (NVSS 2005-2013)") booktabs 
keep(_cons `base' educM* smokeM* fatherA*) style(tex) mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{5}{p{15cm}}{\begin{footnotesize}All regressions "
         "include year fixed effects.  Missing values for smoking and "
         "education are for those states who have not yet adopted the 2003 "
         "updated birth certificates.  Father's age is missing where it "
         "is not reported by the mother. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

gen propMissing = .
gen propOldEduc = .
gen yearMissing = .

local ii = 1
foreach y of numlist 2005(1)2013 {
    qui count if educLevel == . & year==`y'
    local mis = `=r(N)'
    qui count if year==`y'
    local all = `=r(N)'
    local prop = `mis'/`all'

    replace propMissing = `prop' in `ii'
    replace yearMissing = `y'    in `ii'

    sum oldEduc if year==`y'
    if `y'<2009  replace propOldEduc = r(mean) in `ii'
    if `y'>=2009 replace propOldEduc = 0       in `ii'
    local ++ii
}

#delimit;
twoway bar propMissing yearMissing in 1/9, color(white) lcolor(gs0)
|| connect propOldEduc yearMissing in 1/9,
scheme(s1mono) xtitle("Data Year") ytitle("Proportion Missing Education") 
note("Missing education measures occurr in states which use pre-2003 format.")
legend(label(1 "Missing (2003 coding)") label(2 "Old Variable Available"));
graph export "$OUT/../graphs/missingEduc.eps", as(eps) replace;
#delimit cr

restore


********************************************************************************
*** (X) Clear
********************************************************************************
log close
