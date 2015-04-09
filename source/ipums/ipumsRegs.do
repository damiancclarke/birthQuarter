/* ipumsRegs.do v0.00            damiancclarke             yyyy-mm-dd:2015-04-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses raw IPUMS data on first births and runs logit regressions on bir-
ths by quarter, allowing for additional controls, fixed effects, and so forth.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace
cap mkdir "$OUT"

local data noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013
local estopt  cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/            (r2 N, fmt(%9.2f %9.0g)) starlevel ("*" 0.10 "**" 0.05 "***" 0.01)

********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"

keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150

gen ageGroup = age>=25 & age<=34
replace ageGroup = 2 if age>=35 & age<=39
replace ageGroup = 3 if age>=40 & age<=45
drop if ageGroup == 0

gen educLevel = .
replace educLevel = 1 if educ<=6
replace educLevel = 2 if educ>6 & educ<=8
replace educLevel = 3 if educ>8 & educ<=11

gen birth  = 1
gen period = .
replace period = 1 if year>=2005&year<=2007
replace period = 2 if year>=2008&year<=2009
replace period = 3 if year>=2010&year<=2013

gen goodQuarter = birthqtr1==2|birthqtr1==3

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-34" 2 "35-39" 3 "40-45"
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "None" 2 "1-3 years" 3 "4-5 years"

lab val period      pr
lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Binary variable for born Q 2/3 (=1) or Q4/1 (=0)"
lab var ageGroup     "Categorical age group"
lab var period       "Period of time considered (pre/crisis/post)"
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

    
