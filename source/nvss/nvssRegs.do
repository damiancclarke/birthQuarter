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

local qual vlbw lbw apgar gestation premature birthweight twin
local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g)) starlevel ("*" 0.10 "**" 0.05 "***" 0.01)/*
*/           collabels(none) label


********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"

gen birth = 1
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen badQuarter = birthQuarter == 4 | birthQuarter == 1
replace ageGroup  = ageGroup-1 if ageGroup>1
replace educLevel = educLevel+1 if educLevel < 2

gen highEd = educLevel == 2
gen young  = ageGroup  == 1
gen youngXhighEd = young*highEd
gen youngXbadQ   = young*(1-goodQuarter)

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years" 

lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter "Good Q"
lab var highEd      "College Educ"
lab var young       "Aged 25-39"
lab var youngXhigh  "College$\times$ Aged 25-39"
lab var ageGroup     "Categorical age group"
lab var educLevel    "Level of education obtained by mother"
lab var youngXbadQ  "Young$\times$ Bad Q"


********************************************************************************
*** (3a) Regressions (goodQuarter on Age)
********************************************************************************
local yFE   i.year

eststo: reg goodQuarter young                    
eststo: reg goodQuarter young                   `yFE'
eststo: reg goodQuarter young highEd youngXhigh `yFE'

#delimit ;
esttab est1 est2 est3 using "$OUT/NVSSBinary.tex",
replace `estopt' title("Birth Quarter and Age (NVSS 2005-2013)")
keep(_cons young highEd youngX*) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{10cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3b) Regressions (Quality on Age, season)
********************************************************************************
foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter youngXbadQ i.year
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQuality.tex",
replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
keep(_cons young badQ* youngX*) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

foreach e in 0 1 {
    if `e'==0 local educN "with no college education"
    if `e'==1 local educN "with college education"
    
    foreach y of varlist `qual' {
        eststo: reg `y' young badQuarter youngXbadQ i.year if highEd==`e'
    }
    #delimit ;
    esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQuality`e'.tex",
    replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
    keep(_cons young badQ* youngX*) style(tex) booktabs mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
             "first born children of US-born, white, non-hispanic mothers `educN'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
}

********************************************************************************
*** (X) Clear
********************************************************************************
log close
