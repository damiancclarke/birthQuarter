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
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/spainRegs.txt", text replace
cap mkdir "$OUT"

local qual birthweight gestation lbw premature vlbw cesarean
local data births2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local FE    i.birthProvince
local se    robust
local cnd   if twin==0

********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`data'"
keep if parity == 1 & motherSpanish == 1 & ageMother>=25 & ageMother<= 45

********************************************************************************
*** (2b) Generate variables
********************************************************************************
gen ageGroup = 1 if ageMother<40
replace ageGroup = 2 if ageMother>=40

gen highEd              = yrsEducMother > 12 & yrsEducMother != .
gen young               = ageGroup  == 1
gen youngXhighEd        = young*highEd
gen youngXbadQ          = young*(1-goodQuarter)
gen highEdXbadQ         = highEd*(1-goodQuarter)
gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
gen vhighEd             = yrsEducMother >= 15 & yrsEducMother != .
gen youngXvhighEd       = young*vhighEd

lab var goodQuarter        "Good Season"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Aged 25-39"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var ageGroup           "Categorical age group"
lab var youngXbadQ         "Young$\times$ Bad S"
lab var highEdXbadQ        "College$\times$ Bad S"
lab var youngXhighEdXbadQ  "Young$\times$ College$\times$ Bad S"
lab var vhighEd            "Complete Degree"
lab var youngXvhighEd      "Degree$\times$ Aged 25-39"


********************************************************************************
*** (3a) Regressions (goodQuarter on Age)
********************************************************************************
eststo: reg goodQuarter young                     `cnd', `se'
eststo: reg goodQuarter young                `FE' `cnd', `se'
eststo: reg goodQuarter young highEd         `FE' `cnd', `se'
eststo: reg goodQuarter young highEd married `FE' `cnd', `se'


#delimit ;
esttab est1 est2 est3 est4 using "$OUT/spainBinary.tex",
replace `estopt' title("Birth Season and Age (Spain 2013)") booktabs
keep(_cons young highEd married) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
                  "\multicolumn{5}{p{13cm}}{\begin{footnotesize}Sample consists"
                  "of all singleton first born children of Spanish mothers"
                  "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: reg goodQuarter young                      `cnd', `se'
eststo: reg goodQuarter young                 `FE' `cnd', `se'
eststo: reg goodQuarter young vhighEd         `FE' `cnd', `se'
eststo: reg goodQuarter young vhighEd married `FE' `cnd', `se'


#delimit ;
esttab est1 est2 est3 est4 using "$OUT/spainBinaryHigh.tex",
replace `estopt' title("Birth Season and Age (Spain 2013)") booktabs
keep(_cons young highEd married) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
                  "\multicolumn{5}{p{13cm}}{\begin{footnotesize}Sample consists"
                  "of all singleton first born children of Spanish mothers"
                  "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if twin==1
eststo: reg goodQuarter young                     `cond', `se'
eststo: reg goodQuarter young                `FE' `cond', `se'
eststo: reg goodQuarter young highEd         `FE' `cond', `se'
eststo: reg goodQuarter young highEd married `FE' `cond', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/spainBinaryTwin.tex",
replace `estopt' title("Birth Season and Age (Spain, Twins Only)") booktabs
keep(_cons young highEd married smoker `pre') style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{13cm}}{\begin{footnotesize}Sample consists"
         "of all first born children of Spanish mothers (twins only)"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local cond `cnd' & single==1
eststo: reg goodQuarter young             `cond', `se'
eststo: reg goodQuarter young        `FE' `cond', `se'
eststo: reg goodQuarter young highEd `FE' `cond', `se'


#delimit ;
esttab est1 est2 est3 using "$OUT/spainBinarySingle.tex",
replace `estopt' title("Birth Season and Age: Single Women (Spain 2013)")
keep(_cons young highEd `pre') style(tex) booktabs mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{3}{p{10cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (3b) Regressions (Quality on Age, season)
********************************************************************************
foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter `FE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQuality.tex",
replace `estopt' title("Birth Quality by Age and Season (Spain 2013)")
keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers. Gestation weeks and premature"
         "are recorded separately in birth records: premature (binary) for all,"
         "and gestation (continuous) only for some."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter highEd married `FE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQualityEduc.tex",
replace `estopt' title("Birth Quality by Age and Season (Spain 2013)")
keep(_cons young badQuarter high* marr*) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers. Gestation weeks and premature"
         "are recorded separately in birth records: premature (binary) for all,"
         "and gestation (continuous) only for some."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (X) Close
********************************************************************************
log close

