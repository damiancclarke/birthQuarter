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

local allobs 0
if `allobs'==0 local f nvss
if `allobs'==1 local f nvssall
if `allobs'==0 local mnote " married "

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/`f'/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

#delimit ;
local qual   birthweight lbw vlbw gestation premature apgar;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats        
             (N, fmt(%9.0g) labels(Observations))
             starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label;
*             (N r2, fmt(%9.0g %5.3f) labels(Observations R-Squared))
local yFE    i.year;
local se     robust;
local cnd    if twin==1 & motherAge>24 & motherAge <= 45 & liveBirth==1;
local keepif birthOrder==1;
local Fnote  "F-test of age variables refers to the test that
              the coefficients on mother's age and age squared are jointly
              equal to zero. Reported p-values are those corresponding to
              this classical F-test.";
local onote  "Optimal age calculates the turning point of the mother's age
              quadratic.";
local enote  "Heteroscedasticity robust standard errors are reported in
              parentheses.";
#delimit cr

********************************************************************************
*** (2a) Open data for births and deaths
********************************************************************************
use          "$DAT/nvss2005_2013"
append using "$DAT/nvssFD2005_2013"
if `allobs'==0 keep if married==1

local mc 
if `allobs'==1 local mc married

replace motherAge2 = motherAge2/100
lab var motherAge2 "Mother's Age$^2$ / 100"
replace PrePregWt = PrePregWt/10
lab var PrePregWt  "Pre-Pregnancy Weight / 10"
lab var height     "Height (Inches)"

gen educYrs   = educCat
gen educYrsSq = educYrs*educYrs
lab var educYrs   "Years of Education"
lab var educYrsSq "Education Squared"

********************************************************************************
*** (3a) Good Quarter Regressions
********************************************************************************
#delimit ;
local add `" ""  "(excluding babies conceived in September)"
             "(including second births)" "(only twins)" "(including twins)" "';
local nam Main NoSep Bord2 Twin TwinS;
#delimit cr
tokenize `nam'

foreach type of local add {
    preserve

    local age motherAge motherAge2
    local edu highEd
    local con smoker i.gestation `mc' 
    local c2  WIC underweight overweight obese noART
    local yab abs(fips)
    local spcnd
    local group `cnd'&`keepif'
    local samp1 "singleton"
    local samp2 "first born"
    
    if `"`1'"' == "NoSep" local spcnd if birthMonth!=9
    if `"`1'"' == "Bord2" local group `cnd'&birthOrder==2&liveBirth==1
    if `"`1'"' == "Twin"  local group /*
           */ if twin==2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "TwinS" local group /*
           */ if twin<=2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "Bord2" local samp2 "second born"
    if `"`1'"' == "Twin"  local samp1 "twin" 
    if `"`1'"' == "TwinS" local samp1 "twin and singleton" 

    keep `group'

    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F1a= round(r(F)*1000)/1000
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local L1   = (e(df_r)/2)*(e(N)^(2/e(N))-1)
    
    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'
    local F2a= round(r(F)*1000)/1000
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F3a= round(r(F)*1000)/1000
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000
    local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    keep if year>=2009&ART!=.&WIC!=.&underweight!=.
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F4a= round(r(F)*1000)/1000
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000
    local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local L4   =(e(df_r)/2)*(e(N)^(2/e(N))-1)

    eststo: areg goodQuarter `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
    test `age'
    local F5a= round(r(F)*1000)/1000
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000
    local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    #delimit ;
    esttab est3 est2 est1 est4 est5 using "$OUT/NVSSBinary`1'.tex",
    replace `estopt' keep(`age' `edu' smoker `c2' `mc') 
    title("Season of Birth Correlates `type'"\label{tab:bq`1'}) booktabs 
    style(tex) mlabels(, depvar)
    postfoot("F-test of Age Variables&`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\       "
             "p-value of F-test      &`F3'&`F2'&`F1'&`F4'&`F5' \\            "
             "Leamer Critical Value  &`L1'&`L1'&`L1'&`L4'&`L4' \\            "
             "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\             "
             "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\           "
             "2009-2013 Only&&&&Y&Y\\ \bottomrule                            "
             "\multicolumn{6}{p{19cm}}{\begin{footnotesize} All `samp1',     "
             "`samp2' children from the main sample are included. `Fnote'    "
             "Leamer critical values refer to Leamer/Schwartz/Deaton critical"
             "5% values adjusted for sample size.  `onote' `enote'           "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    macro shift
    restore
}


local age motherAge motherAge2
local edu highEd
local co1 smoker `mc' i.gestation
local con smoker `mc' value i.gestation
local c2  WIC underweight overweight obese noART
local yab abs(fips)

preserve
keep `cnd'&`keepif'

eststo: areg goodQuarter `age' `edu' `con' _year* i.fips#c.year, `se' `yab'
test `age'
local F1a= round(r(F)*1000)/1000
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L1   = (e(df_r)/2)*(e(N)^(2/e(N))-1)

eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F2a= round(r(F)*1000)/1000
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `co1' _year* i.fips#c.year, `se' `yab'
test `age'
local F3a= round(r(F)*1000)/1000
local F3 = round(r(p)*1000)/1000
if   `F3' == 0 local F3 0.000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

keep if year>=2009&ART!=.&WIC!=.&underweight!=.
eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F4a= round(r(F)*1000)/1000
local F4 = round(r(p)*1000)/1000
if   `F4' == 0 local F4 0.000
local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L4   = (e(df_r)/2)*(e(N)^(2/e(N))-1)

eststo: areg goodQuarter `age' `edu' `con' _year* `c2'        , `se' `yab'
test `age'
local F5a= round(r(F)*1000)/1000
local F5 = round(r(p)*1000)/1000
if   `F5' == 0 local F5 0.000
local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `con' `c2' i.fips#c.year  , `se' `yab'
test `age'
local F6a= round(r(F)*1000)/1000
local F6 = round(r(p)*1000)/1000
if   `F6' == 0 local F6 0.000
local opt6 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

local tnote "controlling for state-specific trends and unemployment rate"
#delimit ;
esttab est3 est2 est1 est4 est5 est6 using
"$OUT/NVSSBinaryMain_robust.tex", replace `estopt'
title("Season of Birth Correlates (`tnote')" \label{tab:robustness})
booktabs keep(`age' `edu' `c2' smoker value `mc')
style(tex) mlabels(, depvar)
postfoot("F-test of Age Variables&`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\      "
         "p-value of F-test      &`F3'&`F2'&`F1'&`F4'&`F5' \\           "
         "Leamer Critical Value  &`L1'&`L1'&`L1'&`L4'&`L4' \\           "
         "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5'&`opt6' \\     "
         "State and Year FE&Y&Y&Y&Y&Y&Y\\ Gestation FE &Y&Y&Y&Y&Y&Y\\   "
         "State Specific Linear Trends&Y& &Y& & & Y \\                  "
         "2009-2013 Only&&&&Y&Y&Y\\ \bottomrule                         "
         "\multicolumn{7}{p{20cm}}{\begin{footnotesize} Independent     "
	 "variables are binary, except for                              "
         "unemployment, which is measured as the unemployment rate in   "
         "the mother's state in the month of conception. `Fnote'        "
         "Leamer critical values refer to Leamer/Schwartz/Deaton critical"
         "5% values adjusted for sample size. `onote'"
         " `enote' ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore

/*
********************************************************************************
*** (4) ART and Teens
********************************************************************************
local lab "\label{tab:ART2024}"
local con smoker WIC underweight overweight obese `mc'

preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `keepif'
               
eststo: areg goodQuarter age2024 noART highEd `con'  _year*, abs(fips)
keep if e(sample) == 1                                     
eststo: areg goodQuarter age2024 noART highEd smoker _year*, abs(fips)
eststo: areg goodQuarter age2024 noART               _year*, abs(fips)
eststo:  reg goodQuarter age2024 noART                                

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/ART2024.tex", replace
`estopt' keep(age2024 noART highEd `con') style(tex) booktabs
title("Season of Birth Correlates: Very Young (20-24) and ART users`lab'")
postfoot("State and Year FE&&Y&Y&Y\\  \bottomrule                        "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Main estimation  "
         "sample is augmented to also include women aged 20-24.            "
         "Heteroscedasticity robust standard errors are reported.          "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore
*/
********************************************************************************
*** (5) Regressions (Quality on Age, season)
********************************************************************************
local c1      twin==1&birthOrd==1&liveBir==1
local varsY   motherAge motherAge2
local control highEd smoker WIC underweight overweight obese ART `mc'
local names   Main

tokenize `names'

foreach cond of local c1 {
    if `"`1'"'=="Main"    local title     
    dis "`1', `title'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    local jj=1
    foreach y of varlist `qual' {
        eststo: areg `y' goodQuarter `varsY' `control' `yFE', `se' abs(fips)
        test `varsY'
        local F`jj'a  = round(r(p)*1000)/1000
        if   `F`jj'a' == 0 local F`jj'a 0.000
        local F`jj'b  = round(r(p)*1000)/1000
        local L`jj'   =(e(df_r)/2)*(e(N)^(2/e(N))-1)

        local smp if e(sample)==1        
        eststo: areg `y' goodQuarter         `yFE' `smp', `se' abs(fips)

        local ++jj
    }

    local lab "with controls"
    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/NVSSQuality`1'.tex",
    title("Birth Quality and Season of Birth (`title'`lab')"\label{tab:quality`1'})
    keep(goodQuarter `varsY' `control') style(tex) mlabels(, depvar) `estopt'
    postfoot("F-test of Age Variables&`F1b'&`F2b'&`F3b'&`F4b'&`F5b'&`F6b' \\ "
             "p-value of F-test      &`F1a'&`F2a'&`F3a'&`F4a'&`F5a'&`F6a' \\ "
             "Leamer Critical Value  &`L1'&`L2'&`L3'&`L4'&`L5'&`L6'       \\ "
             "\bottomrule                                                    "
             "\multicolumn{7}{p{18.8cm}}{\begin{footnotesize}Main estimation "
	     "sample is used. State and year fixed effects are               "
             "included, and `Fnote' Leamer critical values refer to          "
             "Leamer/Schwartz/Deaton critical 5% values adjusted for sample  "
             "size. `enote'                                                  "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs replace;

    local lab "without controls";
    esttab est2 est4 est6 est8 est10 est12 using "$OUT/NVSSQuality`1'_NC.tex",
    replace `estopt' title("Birth Quality and Season of Birth (`title'`lab')")
    keep(_cons goodQuarter) style(tex) mlabels(, depvar) 
    postfoot("\bottomrule                                                    "
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Main estimation   "
	     "sample is used. State and year fixed effects are               "
             "included. `enote'                                              "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear
    
    macro shift
    restore
}
keep if `keepif'

********************************************************************************
*** (6) Regression including fetal deaths
********************************************************************************
keep if twin==1 & motherAge>24 & motherAge <= 45

local age motherAge motherAge2
local edu highEd
local con smoker `mc'
local yab abs(fips)
local ges i.gestation
local spcnd

eststo: areg goodQuarter `age' `con' _year* i.gestation , `se' `yab'
test `age'
local F1a= round(r(F)*1000)/1000
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L1   = (e(df_r)/2)*(e(N)^(2/e(N))-1)

eststo: areg goodQuarter `age' `con' _year*             , `se' `yab'
test `age'
local F2a= round(r(F)*1000)/1000
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age'       _year* if e(sample), `se' `yab'
test `age'
local F3a= round(r(F)*1000)/1000
local F3 = round(r(p)*1000)/1000
if   `F3' == 0 local F3 0.000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo:  reg goodQuarter `age'              if e(sample), `se'
test `age'
local F4a= round(r(F)*1000)/1000
local F4 = round(r(p)*1000)/1000
if   `F4' == 0 local F4 0.000
local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/NVSSBinaryFDeaths.tex", replace
title("Season of Birth Correlates (Including Fetal Deaths)"\label{tab:FDeaths}) 
`estopt' keep(`age' `con') style(tex) mlabels(, depvar)
postfoot("F-test of Age Variables&`F4a'&`F3a'&`F2a'&`F1a' \\                 "
         "p-value of F-test      &`F4' &`F3' &`F2' &`F1'  \\                 "
         "Leamer Critical Value  &`L1'&`L1'&`L1'&`L1'     \\                 "
         "Optimal Age &`opt4'&`opt3'&`opt2'&`opt1' \\                        "
         "State and Year FE&&Y&Y&Y\\  Gestation FE &&&&Y \\ \bottomrule      "
         "\multicolumn{5}{p{15.2cm}}{\begin{footnotesize}  Main sample is    "
	 "augmented to include fetal deaths occurring between 25 and 44      " 
	 "weeks of gestation. Fetal death files include only a subset of the "
         "full set of variables included in the birth files, so education and"
         " ART controls are not included. `Fnote' Leamer critical values     "
         "refer to Leamer/Schwartz/Deaton critical 5% values adjusted for    "
         "sample size.`onote' `enote'                                        "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs ;
#delimit cr
estimates clear
exit

********************************************************************************
*** (7) Appendix examining missing covariates
********************************************************************************
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


********************************************************************************
*** (X) Clear
********************************************************************************
log close



*/
********************************************************************************
*** (E3a) Good Quarter Regressions
********************************************************************************
#delimit ;
local add `" ""  "(excluding babies conceived in September)"
             "(including second births)" "(only twins)" "(including twins)" "';
local nam Main NoSep Bord2 Twin TwinS;
#delimit cr
tokenize `nam'

foreach type of local add {
    preserve

    local age motherAge motherAge2
    local edu educYrs educYrsSq
    local con smoker i.gestation `mc' 
    local c2  WIC underweight overweight obese noART
    local yab abs(fips)
    local spcnd
    local group `cnd'&`keepif'
    local samp1 "singleton"
    local samp2 "first born"
    
    if `"`1'"' == "NoSep" local spcnd if birthMonth!=9
    if `"`1'"' == "Bord2" local group `cnd'&birthOrder==2&liveBirth==1
    if `"`1'"' == "Twin"  local group /*
           */ if twin==2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "TwinS" local group /*
           */ if twin<=2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "Bord2" local samp2 "second born"
    if `"`1'"' == "Twin"  local samp1 "twin" 
    if `"`1'"' == "TwinS" local samp1 "twin and singleton" 

    keep `group'

    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'    
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000
    local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    keep if year>=2009&ART!=.&WIC!=.&underweight!=.
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000
    local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo: areg goodQuarter `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
    test `age'
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000
    local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    #delimit ;
    esttab est3 est2 est1 est4 est5 using "$OUT/EducSq_NVSSBinary`1'.tex",
    replace `estopt' keep(`age' `edu' smoker `c2' `mc') 
    title("Season of Birth Correlates `type'"\label{tab:bq`1'}) booktabs 
    style(tex) mlabels(, depvar)
    postfoot("F-test of Age Variables&`F3'&`F2'&`F1'&`F4'&`F5' \\            "
             "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\             "
             "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\           "
             "2009-2013 Only&&&&Y&Y\\ \bottomrule                            "
             "\multicolumn{6}{p{19cm}}{\begin{footnotesize} All `samp1',     "
             "`samp2' children from the main sample are included.  Years of  "
             "education are inferred from 6 categorical measures. `Fnote'    "
             "`onote' `enote'     "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    macro shift
    restore
}


local age motherAge motherAge2
local edu educYrs educYrsSq
local co1 smoker `mc' i.gestation
local con smoker `mc' value i.gestation
local c2  WIC underweight overweight obese noART
local yab abs(fips)

preserve
keep `cnd'&`keepif'

eststo: areg goodQuarter `age' `edu' `con' _year* i.fips#c.year, `se' `yab'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `co1' _year* i.fips#c.year, `se' `yab'
test `age'
local F3 = round(r(p)*1000)/1000
if   `F3' == 0 local F3 0.000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

keep if year>=2009&ART!=.&WIC!=.&underweight!=.
eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F4 = round(r(p)*1000)/1000
if   `F4' == 0 local F4 0.000
local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `con' _year* `c2'        , `se' `yab'
test `age'
local F5 = round(r(p)*1000)/1000
if   `F5' == 0 local F5 0.000
local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `con' `c2' i.fips#c.year  , `se' `yab'
test `age'
local F6 = round(r(p)*1000)/1000
if   `F6' == 0 local F6 0.000
local opt6 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

local tnote "controlling for state-specific trends and unemployment rate"
#delimit ;
esttab est3 est2 est1 est4 est5 est6 using
"$OUT/EducSq_NVSSBinaryMain_robust.tex", replace `estopt'
title("Season of Birth Correlates (`tnote')" \label{tab:robustness})
booktabs keep(`age' `edu' `c2' smoker value `mc')
style(tex) mlabels(, depvar)
postfoot("F-test of Age Variables&`F3'&`F2'&`F1'&`F4'&`F5'&`F6' \\      "
         "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5'&`opt6' \\     "
         "State and Year FE&Y&Y&Y&Y&Y&Y\\ Gestation FE &Y&Y&Y&Y&Y&Y\\   "
         "State Specific Linear Trends&Y& &Y& & & Y \\                  "
         "2009-2013 Only&&&&Y&Y&Y\\ \bottomrule                         "
         "\multicolumn{7}{p{20cm}}{\begin{footnotesize} Independent     "
	 "variables are binary, except for                              "
         "unemployment, which is measured as the unemployment rate in   "
         "the mother's state in the month of conception, and education  "
         "and its square which is measured as years, inferred from 6    "
         "categories. `Fnote' `onote'"
         " `enote' ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore


********************************************************************************
*** (E4) ART and Teens
********************************************************************************
local lab "\label{tab:ART2024}"
local con smoker WIC underweight overweight obese `mc'

preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `keepif'
               
eststo: areg goodQuarter age2024 noART educYrs* `con'  _year*, abs(fips)
keep if e(sample) == 1                                     
eststo: areg goodQuarter age2024 noART educYrs* smoker _year*, abs(fips)
eststo: areg goodQuarter age2024 noART                 _year*, abs(fips)
eststo:  reg goodQuarter age2024 noART                                

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/EducSq_ART2024.tex", replace
`estopt' keep(age2024 noART educYrs educYrsSq `con') style(tex) booktabs
title("Season of Birth Correlates: Very Young (20-24) and ART users`lab'")
postfoot("State and Year FE&&Y&Y&Y\\  \bottomrule                        "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Main estimation  "
         "sample is augmented to also include women aged 20-24.            "
         "Heteroscedasticity robust standard errors are reported.          "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore

********************************************************************************
*** (E5) Regressions (Quality on Age, season)
********************************************************************************
local c1      twin==1&birthOrd==1&liveBir==1
local varsY   motherAge motherAge2
local control educYrs educYrsSq smoker WIC underweight overweight obese ART `mc'
local names   Main

tokenize `names'

foreach cond of local c1 {
    if `"`1'"'=="Main"    local title     
    dis "`1', `title'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    local jj=1
    foreach y of varlist `qual' {
        eststo: areg `y' goodQuarter `varsY' `control' `yFE', `se' abs(fips)
        test `varsY'
        local F`jj'a = round(r(p)*1000)/1000
        if   `F`jj'a' == 0 local F`jj'a 0.000

        local smp if e(sample)==1        
        eststo: areg `y' goodQuarter         `yFE' `smp', `se' abs(fips)

        local ++jj
    }

    local lab "with controls"
    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/EducSq_NVSSQuality`1'.tex",
    title("Birth Quality and Season of Birth (`title'`lab')"\label{tab:quality`1'})
    keep(goodQuarter `varsY' `control') style(tex) mlabels(, depvar) `estopt'
    postfoot("F-test of Age Variables&`F1a'&`F2a'&`F3a'&`F4a'&`F5a'&`F6a' \\ "
             "\bottomrule                                                    "
             "\multicolumn{7}{p{18.8cm}}{\begin{footnotesize}Main estimation "
	     "sample is used. State and year fixed effects are               "
             "included, and `Fnote'         `enote'                          "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs replace;

    local lab "without controls";
    esttab est2 est4 est6 est8 est10 est12 using "$OUT/EducSq_NVSSQuality`1'_NC.tex",
    replace `estopt' title("Birth Quality and Season of Birth (`title'`lab')")
    keep(_cons goodQuarter) style(tex) mlabels(, depvar) 
    postfoot("\bottomrule                                                    "
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Main estimation   "
	     "sample is used. State and year fixed effects are               "
             "included. `enote'                                              "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear
    
    macro shift
    restore
}
