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

local JulNov 0

********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`data'"
keep if survived1day == 1
keep if parity == 1 & motherSpanish == 1 & ageMother>=25 & ageMother<= 45
destring birthProvince, replace

replace gestation = . if gestation == 0

********************************************************************************
*** (2b) Generate variables
********************************************************************************
gen ageGroup = 1 if ageMother<40
replace ageGroup = 2 if ageMother>=40

gen professional        = professionM>=2&professionM<=5 if professionM!=. 
gen highEd              = yrsEducMother > 12 & yrsEducMother != .
gen young               = ageGroup  == 1
gen youngXhighEd        = young*highEd
gen youngXbadQ          = young*(1-goodQuarter)
gen highEdXbadQ         = highEd*(1-goodQuarter)
gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
gen vhighEd             = yrsEducMother >= 15 & yrsEducMother != .
gen youngXvhighEd       = young*vhighEd
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
gen     college         = highEd
gen     expectedMonth   = monthBirth + monthsPrem
replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
gen     expectQuarter   = ceil(expectedMonth/3)
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.
gen     labourForce     = professionM >0 & professionM <11 if professionM!=.

gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.


if `JulNov'==1 {
    drop goodQuarter badQuarter expectG* expectB* Qgood* Qbad* *XbadQ

    gen goodQuarter         = monthBirth>=7 & monthBirth<=11
    gen badQuarter          = monthBirth< 7 | monthBirth> 11
    gen expectGoodQ         = expectedMonth >= 7 & expectedMonth<=11 if gest!=.
    gen expectBadQ          = expectedMonth <  7 | expectedMonth> 11 if gest!=.
    gen Qgoodgood           = expectGoodQ==1 & goodQuarter==1 if gest!=.
    gen Qgoodbad            = expectGoodQ==1 & badQuarter ==1 if gest!=.
    gen Qbadgood            = expectBadQ==1  & goodQuarter==1 if gest!=.
    gen Qbadbad             = expectBadQ==1  & badQuarter ==1 if gest!=.

    gen youngXbadQ          = young*(1-goodQuarter)
    gen highEdXbadQ         = highEd*(1-goodQuarter)
    gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
}

sum expectGoodQ expectBadQ if young==0
sum Qgoodgood Qgoodbad Qbadgood Qbadbad if young==0


lab var goodQuarter        "Good Season"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Young (aged 25-39)"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var ageGroup           "Categorical age group"
lab var youngXbadQ         "Young$\times$ Bad S"
lab var highEdXbadQ        "College$\times$ Bad S"
lab var youngXhighEdXbadQ  "Young$\times$ College$\times$ Bad S"
lab var vhighEd            "Complete Degree"
lab var youngXvhighEd      "Degree$\times$ Aged 25-39"
lab var professional       "White Collar Job"
lab var labourForce        "In Labour Market"
lab var married            "Married"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var cesarean           "Cesarean"
lab var lbw                "LBW"
lab var premature          "Premature"
lab var vlbw               "VLBW"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var Qgoodbad           "Bad Season (due in good)"
lab var Qbadbad            "Bad Season (due in bad)"
lab var Qbadgood           "Good Season (due in bad)"
lab var college            "Some College +"
lab var ageMother          "Mother's Age"
lab var yrsEducMother      "Years of education"
lab var female             "Female"

    
********************************************************************************
*** (4a) Regressions (goodQuarter on Age)
********************************************************************************
eststo: reg goodQuarter young                                  `cnd', `se'
eststo: reg goodQuarter young                             `FE' `cnd', `se'
eststo: reg goodQuarter young highEd                      `FE' `cnd', `se'
eststo: reg goodQuarter young highEd professional         `FE' `cnd', `se'
eststo: reg goodQuarter young highEd professional married `FE' `cnd', `se'


#delimit ;
esttab est1 est2 est3 est4 est5 using "$OUT/spainBinary.tex",
replace `estopt' title("Birth Season and Age (Spain 2007-2013)") booktabs
keep(_cons young highEd professional married) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
                  "\multicolumn{6}{p{15cm}}{\begin{footnotesize}Sample consists"
                  "of all singleton first born children of Spanish mothers"
                  "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: reg goodQuarter young                                  `cnd', `se'
eststo: reg goodQuarter young                             `FE' `cnd', `se'
eststo: reg goodQuarter young highEd                      `FE' `cnd', `se'
eststo: reg goodQuarter young highEd labourForce          `FE' `cnd', `se'
eststo: reg goodQuarter young highEd labourForce  married `FE' `cnd', `se'
#delimit ;
esttab est1 est2 est3 est4 est5 using "$OUT/spainBinaryLForce.tex",
replace `estopt' title("Birth Season and Age (Spain 2007-2013)") booktabs
keep(_cons young highEd labourForce  married) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
                  "\multicolumn{6}{p{15cm}}{\begin{footnotesize}Sample consists"
                  "of all singleton first born children of Spanish mothers"
                  "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


eststo: reg goodQuarter young                                   `cnd', `se'
eststo: reg goodQuarter young                              `FE' `cnd', `se'
eststo: reg goodQuarter young vhighEd                      `FE' `cnd', `se'
eststo: reg goodQuarter young vhighEd professional         `FE' `cnd', `se'
eststo: reg goodQuarter young vhighEd professional married `FE' `cnd', `se'


#delimit ;
esttab est1 est2 est3 est4 est5 using "$OUT/spainBinaryHigh.tex",
replace `estopt' title("Birth Season and Age (Spain 2007-2013)") booktabs
keep(_cons young vhighEd married professional) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
                  "\multicolumn{6}{p{15cm}}{\begin{footnotesize}Sample consists"
                  "of all singleton first born children of Spanish mothers"
                  "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if twin==1
eststo: reg goodQuarter young                                  `cond', `se'
eststo: reg goodQuarter young                             `FE' `cond', `se'
eststo: reg goodQuarter young highEd                      `FE' `cond', `se'
eststo: reg goodQuarter young highEd professional         `FE' `cond', `se'
eststo: reg goodQuarter young highEd professional married `FE' `cond', `se'

#delimit ;
esttab est1 est2 est3 est4 est5 using "$OUT/spainBinaryTwin.tex",
replace `estopt' title("Birth Season and Age (Spain, Twins Only)") booktabs
keep(_cons young highEd married professional) style(tex) mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y&Y\\ \bottomrule"
         "\multicolumn{6}{p{15cm}}{\begin{footnotesize}Sample consists"
         "of all first born children of Spanish mothers (twins only)"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local cond `cnd' & single==1
eststo: reg goodQuarter young                          `cond', `se'
eststo: reg goodQuarter young                     `FE' `cond', `se'
eststo: reg goodQuarter young highEd              `FE' `cond', `se'
eststo: reg goodQuarter young highEd professional `FE' `cond', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/spainBinarySingle.tex",
replace `estopt' title("Birth Season and Age: Single Women (Spain 2013)")
keep(_cons young highEd professional) style(tex) booktabs mlabels(, depvar)
postfoot("Province FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{11cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (4b) Regressions (Quality on Age, season)
********************************************************************************
foreach y of varlist `qual' {
    eststo: reg `y' young goodQuarter `FE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQuality.tex",
replace `estopt' title("Birth Quality by Age and Season (Spain 2013)")
keep(_cons young goodQuarter) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15.8cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers. Gestation weeks and premature"
         "are recorded separately in birth records: premature (binary) for all,"
         "and gestation (continuous) only for some."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

foreach y of varlist `qual' {
    eststo: reg `y' young goodQua highEd professional married `FE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQualityEduc.tex",
replace `estopt' title("Birth Quality by Age and Season (Spain 2013)")
keep(_cons young goodQ* high* marr* pro*) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of Spanish mothers. Gestation weeks and premature"
         "are recorded separately in birth records: premature (binary) for all,"
         "and gestation (continuous) only for some."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (5) Redefine bad season as bad season due to short gestation, and bad season
********************************************************************************
local cont     highEd professional married
local cont     
local seasons  Qgoodbad Qbadgood Qbadbad
local aa       abs(gestation)

eststo: reg  birthweight young `seasons' `cont' `cnd', `se'
eststo: areg birthweight young `seasons' `cont' `cnd', `se' `aa'
eststo: reg  birthweight `seasons' `cont' `cnd'&young==1, `se'
eststo: areg birthweight `seasons' `cont' `cnd'&young==1, `se' `aa'
eststo: reg  birthweight `seasons' `cont' `cnd'&young==0, `se'
eststo: areg birthweight `seasons' `cont' `cnd'&young==0, `se' `aa'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQualityGestFix.tex",
replace  title("Birth Quality by Age and Season") collabels(none) label
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) style(tex)
stats (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations))
mtitles("No Gest" "Gestation" "No Gest" "Gestation" "No Gest" "Gestation")
keep(_cons young `seasons' `cont') starlevel ("*" 0.10 "**" 0.05 "***" 0.01)
mgroups("All" "Young" "Old", pattern(1 0 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(r){@span}))
postfoot("\bottomrule"
         "\multicolumn{7}{p{18.6cm}}{\begin{footnotesize}Sample consists of all"
         " first born children of Spanish mothers. Bad Season (due in bad) is a"
         " dummy for children expected and born in quarters 1 or 4, while Bad  "
         "Season (due in good) is a dummy for children expected in quarters 2  "
         "or 3, but were born prematurely in quarters 1 or 4. Fixed effects for"
         "weeks of gestation are included."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
#delimit cr
estimates clear
            

********************************************************************************
*** (X) Close
********************************************************************************
log close

