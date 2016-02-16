/* spainRegs.do v0.00            damiancclarke             yyyy-mm-dd:2015-05-24
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses Spanish administrative data (2013), subsets, and runs regressions
on births by quarter, allowing for additional controls, fixed effects, and so
forth.  Raw data from INE is read in using the file spainPrep.do


*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/spain"
global OUT "~/investigacion/2015/birthQuarter/results/spain/regressions"
global SUM "~/investigacion/2015/birthQuarter/results/spain/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/spainRegs.txt", text replace
cap mkdir "$OUT"

local qual birthweight lbw vlbw gestation premature cesarean
local bdata births2007-2013
local fdata fetaldeaths2007-2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(Observations))                        /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local FE    i.birthProvince
local se    robust
local cnd   if twin==0


********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`bdata'"
append using "$DAT/`fdata'"
replace liveBirth = 1 if liveBirth == .

keep if motherSpanish == 1 & motherAge>=25 & motherAge<= 45
*keep if married == 1
drop if professionMother == 13
destring birthProvince, replace

********************************************************************************
*** (3a) Regressions (goodQuarter on Age)
********************************************************************************
#delimit ;
local add `" ""  "(Including Fetal Deaths)" "(Birth Order = 2)" "(Twin sample)"
                 "(Girls Only)" "(Boys Only)" "(No Armed Forces)" "';
local nam Main FDeaths Bord2 Twin girls boys noArmy;
#delimit cr
tokenize `nam'

foreach type of local add {
    preserve

    local age   age2527 age2831 age3239
    local edu   highEd married
    local con   i.gestation
    local yab   abs(birthProvince)
    local tr    i.birthProvince#c.year
    local sd1   survived1day == 1
    local group birthOrder == 1 & liveBirth == 1 & twin == 0 & `sd1'
    local fd
    local samp1 "singleton"
    local samp2 "first born"

    if `"`1'"' == "FDeaths" local group birthOrder==1&twin==0
    if `"`1'"' == "Bord2"   local group birthOrder==2&liveBirth==1&twin==0&`sd1'
    if `"`1'"' == "Twin"    local group birthOrder==1&liveBirth==1&twin==1&`sd1'
    if `"`1'"' == "girls"   local group `group' & female==1
    if `"`1'"' == "boys"    local group `group' & female==0
    if `"`1'"' == "Bord2"   local samp2 "second born"
    if `"`1'"' == "Twin"    local samp1 "twin"
    if `"`1'"' == "girls"   local samp1 "female, singleton"
    if `"`1'"' == "boys"    local samp1 "male, singleton"
    if `"`1'"' == "FDeaths" local fd "or first pregnancies leading to fetal deaths"
    if `"`1'"' == "noArmy"  local group `group' & professionMother!=1
    if `"`1'"' == "noArmy"  local nmil ", non-military"

    keep if `group'

    eststo: areg goodQuarter `age' `edu' _year* `con' `tr', `se' `yab'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000

    eststo: areg goodQuarter `age' `edu' _year* `con'    , `se' `yab'
    test `age'
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000

    eststo: areg goodQuarter `age' `edu' _year* if e(sample) , `se' `yab'
    test `age'
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000

    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000

    #delimit ;
    esttab est5 est4 est3 est2 est1 using "$OUT/spainBinary`1'.tex", replace
    `estopt' title("Season of Birth Correlates `type'"\label{tab:SpainBinary`1'})
    keep(_cons `age' `edu') style(tex) mlabels(, depvar) booktabs
    postfoot("F-test of Age Dummies&`F5'&`F4'&`F3'&`F2'&`F1'          \\       "
             "Province and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&&Y&Y    \\       "
             "Province Specific Linear Trends&&&&&Y\\ \bottomrule              "
             "\multicolumn{6}{p{18.8cm}}{\begin{footnotesize}Sample consists   "
             "of all `samp1' `samp2' children `fd' to married Spanish `nmil'   "
             "women aged 25-45. Independent variables are all binary           "
             "measures.  F-test for age dummies refers to the p-value on the   "
             "joint significance of the three age dummies. Heteroscedasticity  "
             "robust standard errors are reported.                             "
             "          ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.  "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
    
    macro shift
    restore
}

keep if birthOrder == 1 & liveBirth == 1 & twin == 0 & survived1day == 1
********************************************************************************
*** (3b) Regressions (Education interactions)
********************************************************************************    
local age1  age2527 age2831 age3239
local age1X age2527XhighEd age2831XhighEd age3239XhighEd
local age2  motherAge motherAge2

local v1 `age1' highEd `age1X' _year* married
local v2 `age1' highEd         _year* married
local v3 `age1'                _year* married
local v4 `age2' educCat        _year* married
local v5 `age2'                _year* married

eststo: areg goodQua `v1', abs(birthProvince)
test `age1'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000

foreach num of numlist 2(1)5 {
    eststo: areg goodQua `v`num'' if e(sample), abs(birthProvince)
    if `num'< 4 test `age1'
    if `num'> 3 test `age2'

    local F`num' = round(r(p)*1000)/1000
    if  `F`num'' == 0 local F`num' 0.000
}

local kvar `age1' highEd `age1X' `age2' educCat married
#delimit ;
esttab est3 est2 est1 est5 est4 using "$OUT/SpainBinaryEducAge.tex",
replace `estopt' booktabs keep(`kvar') mlabels(, depvar)
title("Season of Birth, Age and Education"\label{tab:SpainEducAge})
postfoot("F-test of Age Variables&`F3'&`F2'&`F1'&`F5'&`F4' \\ \bottomrule    "
         "\multicolumn{6}{p{18cm}}{\begin{footnotesize}Sample consists       "
         " of singleton first-born children to married Spanish women         "
         "women aged 25-45.  F-test for age variables refers to the p-value  "
         "on the joint significance of the age variables in each column.     "
         "Heteroscedasticity robust standard errors are reported.            "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


*******************************************************************************
*** (3c) Regressions (Quality on Age, season)
********************************************************************************
local yab abs(birthProvince)
local age age2527 age2831 age3239
local jj=1

foreach y of varlist `qual' {
    eststo: areg `y' `age' goodQuarter highEd married _year*, `yab' `se'
    test `age'
    local F`jj' = round(r(p)*1000)/1000
    if   `F`jj'' == 0 local F`jj' 0.000
    local ++jj
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQuality.tex", replace
`estopt' title("Birth Quality by Age and Season"\label{tab:SpainQuality}) 
keep(_cons `age' goodQuarter highEd married) style(tex)  mlabels(, depvar)
postfoot("F-test of Age Variables&`F1'&`F2'&`F3'&`F4'&`F5'&`F6' \\  \bottomrule"
         "\multicolumn{7}{p{17.4cm}}{\begin{footnotesize}Sample consists of all"
         " first born children of Spanish mothers. Gestation weeks and         "
         "premature are recorded separately in birth records: premature        "
         "(binary) for all, and gestation (continuous) only for some. F-test   "
         "for age variables refers to the p-value on the joint significance of "
         "the age variables in each column. Heteroscedasticity robust standard "
         "errors are reported.                                                 "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.                "
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
#delimit cr
estimates clear

*******************************************************************************
*** (4) Labour Market regressions
********************************************************************************
replace professionMother = 0 if professionMother==.
tab professionMother, gen(_mprof)
drop if _mprof1==1
drop _mprof1

local age age2527 age2831 age3239
local edu highEd married
local yab abs(birthProvince)

eststo: areg goodQuarter `age' `edu' _year*        , `se' `yab'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000

drop _mprof13
eststo: areg goodQuarter `age' `edu' _year* _mp*   , `se' `yab'
test `age'
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
ds _mprof*
local tvar `r(varlist)'
test `tvar'
local F2t = round(r(p)*1000)/1000

#delimit ;
esttab est1 est2 using "$OUT/SpainIndustry.tex",
replace `estopt' title("Season of Birth and Occupation"\label{tab:SpainOcc})
keep(_cons `age' `edu' _mprof*) style(tex) booktabs mlabels(, depvar)
postfoot("F-test of Occupation Dummies&-&`F2t'\\                               "
         "F-test of Age Dummies&`F1'&`F2'     \\          \bottomrule          " 
         "\multicolumn{3}{p{12.2cm}}{\begin{footnotesize}Sample consists of all"
         "firstborn children with Spanish mothers who are married, and who     "
         "report an occupation on the birth certificate.  The omitted          "
         "occupational variable is Home Workers which has good season mean (sd)"
         "of 0.497(0.500).  F-tests for age and occupation dummies report the  "
         "p-value for the joint significance of all dummies. Heteroscedasticity"
         "robust standard errors are reported in parentheses, and year and     "
         "province of birth fixed effects are included."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
         

********************************************************************************
*** (X) Close
********************************************************************************
log close

