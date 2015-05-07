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
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label

********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"

keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150

gen ageGroup = age>=25 & age<=39
replace ageGroup = 2 if age>=40 & age<=45
drop if ageGroup == 0

gen educLevel = .
replace educLevel = 1 if educ<=6
replace educLevel = 2 if educ>6 & educ<=11

gen birth  = 1
gen period = .
replace period = 1 if year>=2005&year<=2007
replace period = 2 if year>=2008&year<=2009
replace period = 3 if year>=2010&year<=2013

gen goodQuarter = birthqtr1==2|birthqtr1==3

gen married    = marst==1|marst==2
gen hhincomeSq = hhincome^2
gen female     = sex1==2

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years"

lab val period      pr
lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Good Quarter"
lab var ageGroup     "Categorical age group"
lab var period       "Period of time considered (pre/crisis/post)"
lab var educLevel    "Level of education obtained by mother"

********************************************************************************
*** (2c) Generate a set of empty cells for quarter*state*educ
********************************************************************************
preserve
gen zero = 0
collapse zero, by(statefip)
expand 9
bys statefip: gen year=2004+_n
expand 2
bys statefip year: gen goodQuarter=_n-1
expand 2
bys statefip year goodQuarter: gen ageGroup=_n
expand 2
bys statefip year goodQuarter ageGroup: gen educLevel=_n
count

lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL
tempfile zeros znoeduc
save `zeros'
keep if educLevel==1
drop educLevel
save `znoeduc'
restore

********************************************************************************
*** (3a) Set for binary by birthquarter by woman by educLevel
********************************************************************************
preserve
collapse (sum) birth, by(year goodQuarter ageGroup statefip educLevel)
merge 1:1 year goodQuarter ageGroup statefip educLevel using `zeros'
replace birth = zero if _merge==2
drop zero _merge

reshape wide birth, i(statefip year ageGroup educLevel) j(goodQuarter)
gen birthTotal = birth0 + birth1
replace birth0 = birth0/birthTotal-0.5
replace birth1 = birth1/birthTotal-0.5
drop birthTotal
reshape long birth, i(statefip year ageGroup educLevel) j(goodQuarter)
replace birth=0 if birth==.

********************************************************************************
*** (3b) regressions
********************************************************************************
local se cluster(statefip)
local abs abs(statefip)

eststo: areg birth i.educLevel#c.goodQuarter i.year if ageGroup==1, `se' `abs'
eststo: areg birth i.educLevel#c.goodQuarter i.year if ageGroup==2, `se' `abs'

#delimit ;
esttab est1 est2 using "$OUT/IPUMSeducation.tex", replace `estopt' style(tex)
title("Proportion of births by Quarter (IPUMS 2005-2013)") drop(20*)
postfoot("\bottomrule\multicolumn{3}{p{9cm}}{\begin{footnotesize}All regressions"
         "absorb state and year fixed effects. Coefficients are expressed as the "
         "difference between the proportion of births in a given quarter and "
         "the theoretical proportion if births were spaced evenly by quarter."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs
mlabels("Age 20-39" "Age 40-45") width(0.8\hsize);
#delimit cr
estimates clear
restore

********************************************************************************
*** (3c) Set for binary by birthquarter by woman
********************************************************************************
preserve
collapse (sum) birth, by(year goodQuarter ageGroup statefip)
merge 1:1 year goodQuarter ageGroup statefip using `znoeduc'
replace birth = zero if _merge==2
drop zero _merge

reshape wide birth, i(statefip year ageGroup) j(goodQuarter)
gen birthTotal = birth0 + birth1
replace birth0 = birth0/birthTotal-0.5
replace birth1 = birth1/birthTotal-0.5
drop birthTotal
reshape long birth, i(statefip year ageGroup) j(goodQuarter)
replace birth=0 if birth==.

********************************************************************************
*** (3d) regressions
********************************************************************************
foreach group of numlist 1 2 {
    eststo: areg birth goodQuarter i.year if ageGroup==`group', `se' `abs'
}

#delimit ;
esttab est1 est2 using "$OUT/IPUMSAll.tex", replace `estopt' style(tex)
title("Proportion of births by Quarter (IPUMS 2005-2013)") drop(20*)
postfoot("\bottomrule\multicolumn{3}{p{9cm}}{\begin{footnotesize}"
         "All regressions absorb state and year fixed effects. Coefficients are"
         "expressed as the difference between the proportion of births in a"
         "given quarter and the theoretical proportion if births were spaced"
         "evenly by quarter.\end{footnotesize}}\end{tabular}\end{table}")
booktabs mlabels("Age 20-39" " Age 40-45") width(0.8\hsize);
#delimit cr
estimates clear

foreach group of numlist 1 2 {
    eststo: areg birth i.year#c.goodQuarter if ageGroup==`group', `se' `abs'
}

#delimit ;
esttab est1 est2 using "$OUT/IPUMSTime.tex", replace `estopt' style(tex)
title("Proportion of births by Quarter (IPUMS 2005-2013)") 
postfoot("\bottomrule\multicolumn{3}{p{9cm}}{\begin{footnotesize}"
         "All regressions absorb state and year fixed effects. Coefficients are"
         "expressed as the difference between the proportion of births in a given"
         "quarter and the theoretical proportion if births were spaced evenly by"
         "quarter. \end{footnotesize}}\end{tabular}\end{table}")
mlabels("Age 20-39" "Age 40-45") booktabs width(0.8\hsize);
#delimit cr
restore
estimates clear

********************************************************************************
*** (4) regressions of good season of birth
********************************************************************************
set matsize 3000
local ctrls hhincome hhincomeSq married female
local yFE   i.year
local sFE   i.statefip
local sxyFE i.year##i.statefip
local wt    [pw=perwt]

gen highEd = educLevel == 2
gen young  = ageGroup  == 1
gen youngXhighEd = young*highEd

lab var goodQuarter "Good S"
lab var highEd      "College Educ"
lab var young       "Aged 25-39"
lab var youngXhigh  "College$\times$ Aged 25-39"
lab var female      "Female child"
lab var hhincomeSq  "household income squared"  
lab var married     "Married"

eststo: reg goodQuarter young                                   `wt', `se'
eststo: reg goodQuarter young               `yFE'               `wt', `se' 
eststo: reg goodQuarter young               `yFE' `sFE'         `wt', `se'
eststo: reg goodQuarter young                 `sxyFE'           `wt', `se'
eststo: reg goodQuarter young highEd          `sxyFE'           `wt', `se'
eststo: reg goodQuarter young highEd          `sxyFE'   `ctrls' `wt', `se'
eststo: reg goodQuarter young highEd youngX   `sxyFE'   `ctrls' `wt', `se'
eststo: reg goodQuarter young highEd youngX   `sxyFE'           `wt', `se'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 est8 using "$OUT/IPUMSBinary.tex",
replace `estopt' title("Proportion of births by Season (IPUMS 2005-2013)")
keep(_cons young highEd youngX* `ctrls') style(tex) booktabs mlabels(, depvar) 
postfoot("\midrule Year FE&&Y&Y&Y&Y&Y&Y&Y\\ State FE&&&Y&Y&Y&Y&Y&Y\\"
        "State$\times$ Year FE&&&&Y&Y&Y&Y&Y\\ \bottomrule"
        "\multicolumn{8}{p{21cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers."
         "Standard errors are clustered by state, and inverse probability"
         "weights are used.  The outcome variable is a binary variable"
         "equal to 1 for individuals born in birth quarters 2 or 3 ('good"
         "season'). Linear probability models are estimated by OLS."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
