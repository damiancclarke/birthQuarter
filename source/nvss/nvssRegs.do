/* nvssRegs.do v0.00             damiancclarke             yyyy-mm-dd:2015-04-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses NVSS data on first births and runs regressions on births by quar-
ter, allowing for additional controls, fixed effects, and so forth.

Note: I still need to add state controls to the original data file.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global OUT "~/investigacion/2015/birthQuarter/results/nvss/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g)) starlevel ("*" 0.10 "**" 0.05 "***" 0.01)/*
*/           mlabels("20-34" "35-39" "40-45")

********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"

gen birth = 1
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-34" 2 "35-39" 3 "40-45"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "None" 2 "1-3 years" 3 "4-5 years"

lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Binary variable for born Q 2/3 (=1) or Q4/1 (=0)"
lab var ageGroup     "Categorical age group"
lab var educLevel    "Level of education obtained by mother"



********************************************************************************
*** (3a) Set for binary by birthquarter by woman by educLevel
********************************************************************************
preserve
collapse (sum) birth, by(year goodQuarter ageGroup statefip educLevel)
reshape wide birth, i(statefip year ageGroup educLevel) j(goodQuarter)
gen birthTotal = birth0 + birth1
replace birth0 = birth0/birthTotal-0.5
replace birth1 = birth1/birthTotal-0.5
drop birthTotal
reshape long birth, i(statefip year ageGroup educLevel) j(goodQuarter)

********************************************************************************
*** (3b) regressions
********************************************************************************
local opt abs(statefip) cluster(statefip)

eststo: areg birth i.educLevel#c.goodQuarter i.year if ageGroup==1, `opt'
eststo: areg birth i.educLevel#c.goodQuarter i.year if ageGroup==2, `opt'
eststo: areg birth i.educLevel#c.goodQuarter i.year if ageGroup==3, `opt'

#delimit ;
estout est1 est2 est3 using "$OUT/IPUMSeducation.txt", replace `estopt'
title("Proportion of births by Quarter (IPUMS 2005-2013)") drop(20* _cons)
note("All regressions absorb state and year fixed effects.  Coefficients are"
     "expressed as the difference between the proportion of births in a given"
     "quarter and the theoretical proportion if births were spaced evenly by"
     "quarter.");
#delimit cr
estimates clear
restore



********************************************************************************
*** (3c) Set for binary by birthquarter by woman
********************************************************************************
collapse (sum) birth, by(year goodQuarter ageGroup statefip)
reshape wide birth, i(statefip year ageGroup) j(goodQuarter)
gen birthTotal = birth0 + birth1
replace birth0 = birth0/birthTotal-0.5
replace birth1 = birth1/birthTotal-0.5
drop birthTotal
reshape long birth, i(statefip year ageGroup) j(goodQuarter)

********************************************************************************
*** (3d) regressions
********************************************************************************
eststo: areg birth goodQuarter i.year if ageGroup==1, `opt'
eststo: areg birth goodQuarter i.year if ageGroup==2, `opt'
eststo: areg birth goodQuarter i.year if ageGroup==3, `opt'
#delimit ;
estout est1 est2 est3 using "$OUT/IPUMSAll.txt", replace `estopt'
title("Proportion of births by Quarter (IPUMS 2005-2013)") drop(20* _cons)
note("All regressions absorb state and year fixed effects.  Coefficients are"
     "expressed as the difference between the proportion of births in a given"
     "quarter and the theoretical proportion if births were spaced evenly by"
     "quarter.");
#delimit cr
estimates clear

eststo: areg birth i.year#c.goodQuarter if ageGroup==1, `opt'
eststo: areg birth i.year#c.goodQuarter if ageGroup==2, `opt'
eststo: areg birth i.year#c.goodQuarter if ageGroup==3, `opt'
#delimit ;
estout est1 est2 est3 using "$OUT/IPUMSTime.txt", replace `estopt'
title("Proportion of births by Quarter (IPUMS 2005-2013)") drop(_cons)
note("All regressions absorb state and year fixed effects.  Coefficients are"
     "expressed as the difference between the proportion of births in a given"
     "quarter and the theoretical proportion if births were spaced evenly by"
     "quarter.");
#delimit cr

    
