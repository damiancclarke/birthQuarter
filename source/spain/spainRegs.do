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
local data births2007-2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(Observations))                        /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local FE    i.birthProvince
local se    robust
local cnd   if twin==0


********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`data'"
keep if survived1day == 1
keep if birthOrder == 1 & motherSpanish == 1 & motherAge>=25 & motherAge<= 45
keep if twin == 0 & married == 1
destring birthProvince, replace
/*    
********************************************************************************
*** (3a) Regressions (goodQuarter on Age)
********************************************************************************
local age age2527 age2831 age3239
local edu highEd
local yab abs(birthProvince)
local tr  i.birthProvince#c.year

eststo: areg goodQuarter `age' `edu' _year* i.gestation `tr', `se' `yab'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000

eststo: areg goodQuarter `age' `edu' _year* i.gestation    , `se' `yab'
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
esttab est5 est4 est3 est2 est1 using "$OUT/spainBinary.tex",
replace `estopt' title("Season of Birth Correlates") booktabs
keep(_cons `age' `edu') style(tex) mlabels(, depvar)
postfoot("F-test of Age Dummies&`F5'&`F4'&`F3'&`F2'&`F1'          \\       "
         "Province and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&&Y&Y    \\       "
         "Province Specific Trends&&&&&Y\\ \bottomrule                     "
         "\multicolumn{6}{p{17.8cm}}{\begin{footnotesize}Sample consists "
         "of all singleton first-born  children to married Spanish         "
         "women aged 25-45. Independent variables are all binary           "
         "measures. Heteroscedasticity robust standard errors are          "
         "reported. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3b) Regressions (Education interactions)
********************************************************************************    
local age1  age2527 age2831 age3239
local age1X age2527XhighEd age2831XhighEd age3239XhighEd
local age2  motherAge motherAge2

local v1 `age1' highEd `age1X' _year*
local v2 `age1' highEd         _year*
local v3 `age1'                _year*
local v4 `age2' educCat        _year*
local v5 `age2'                _year*

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

local kvar `age1' highEd `age1X' `age2' educCat
#delimit ;
esttab est3 est2 est1 est5 est4 using "$OUT/SpainBinaryEducAge.tex",
replace `estopt' booktabs keep(`kvar') mlabels(, depvar)
title("Season of Birth, Age and Education")
postfoot("F-test of Age Dummies&`F3'&`F2'&`F1'&`F5'&`F4' \\ \bottomrule      "
         "\multicolumn{6}{p{18cm}}{\begin{footnotesize}Sample consists       "
         " of singleton first-born children to married Spanish women         "
         "women aged 25-45. Heteroscedasticity robust standard errors are    "
         "reported. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.    "
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
    eststo: areg `y' `age' goodQuarter highEd _year*, `yab' `se'
    test `age'
    local F`jj' = round(r(p)*1000)/1000
    if   `F`jj'' == 0 local F`jj' 0.000
    local ++jj
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQuality.tex",
replace `estopt' title("Birth Quality by Age and Season")
keep(_cons `age' goodQuarter highEd) style(tex) booktabs mlabels(, depvar)
postfoot("F-test of Age Variables&`F1'&`F2'&`F3'&`F4'&`F5'&`F6' \\  \bottomrule"
         "\multicolumn{7}{p{17.4cm}}{\begin{footnotesize}Sample consists of all"
         " first born children of Spanish mothers. Gestation weeks and         "
         "premature are recorded separately in birth records: premature        "
         "(binary) for all, and gestation (continuous) only for some.          "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.                "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
*/
*******************************************************************************
*** (4) Labour Market regressions
********************************************************************************
replace professionMother = 0 if professionMother==.
tab professionMother, gen(_mprof)
drop if _mprof1==1
drop _mprof1

local age age2527 age2831 age3239
local edu highEd
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
replace `estopt' title("Season of Birth and Occupation")
keep(_cons `age' `edu' _mprof*) style(tex) booktabs mlabels(, depvar)
postfoot("F-test of Occupation Dummies&-&`F2t'\\                               "
         "F-test of Age Dummies&`F1'&`F2'     \\          \bottomrule          " 
         "\multicolumn{3}{p{12.2cm}}{\begin{footnotesize}Sample consists of all"
         "firstborn children with Spanish mothers who are married, and who     "
         "report an occupation on the birth certificate.  The omitted          "
         "occupational variable is Home Workers which has good season mean (sd)"
         "of 0.497(0.500).  Heteroscedasticity robust standard errors are      "
         "reported in parentheses, and year and province of birth fixed effects"
         "are included."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
         

********************************************************************************
*** (X) Close
********************************************************************************
log close

