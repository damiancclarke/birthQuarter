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
local data births2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(R-squared Observations))              /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local FE    i.birthProvince
local se    robust
local cnd   if twin==0

********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`data'"
keep if parity == 1 & motherSpanish == 1 & ageMother>=25 & ageMother<= 45
destring birthProvince, replace

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
gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.

gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.

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
lab var married            "Married"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var cesarean           "Cesarean"
lab var lbw                "Low Birth Weight ($<$2500 g)"
lab var premature          "Premature ($<$37 weeks)"
lab var vlbw               "VLBW"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var badExpectGood      "Bad Season (due in good)"
lab var badExpectBad       "Bad Season (due in bad)"
lab var Qgoodbad           "Bad Season (due in good)"
lab var Qbadbad            "Bad Season (due in bad)"
lab var Qbadgood           "Good Season (due in bad)"
lab var college            "Some College +"
lab var ageMother          "Mother's Age"
lab var yrsEducMother      "Years of education"
lab var female             "Female"

********************************************************************************
*** (3) Summary stats
********************************************************************************
local sumM ageMother young married college yrsEducMother professional 
local sumK goodQuarter birthweight lbw gestat premature female cesarean

foreach sumS in sumM sumK {
    sum ``sumS''
    estpost tabstat ``sumS'', statistics(count mean sd min max) columns(statistics)
    esttab using "$SUM/Spain`sumS'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs
}
lab var lbw       "LBW"
lab var premature "Premature" 
lab var young     "Aged 25-39"

gen birth         = 1
gen educLevel     = 1 if highEd==0
replace educLevel = 2 if highEd==1

lab def aG  1 "Young " 2  "Old "
lab def eL  1 "No College" 2 "Some College +"
lab val ageGroup    aG
lab val educLevel   eL


preserve
collapse (sum) birth, by(goodQuarter educLevel ageGroup)
reshape wide birth, i(educLevel ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100

gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str5 b0         = string(birth0, "%05.2f")
gen str5 b1         = string(birth1, "%05.2f")
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")

drop totalbirths diff rati birth*

#delimit ;
listtex using "$SUM/PropNoTime.tex", rstyle(tabular) replace
head("\vspace{8mm}\begin{table}[htpb!]"
     "\centering\caption{Percent of Births per Cell (All Years)}"
     "\begin{tabular}{llcccc}\toprule"
     "Age Group &College&Bad Quarters&Good Quarters&Difference&Ratio \\ \midrule")
foot("\midrule\multicolumn{6}{p{9cm}}{\begin{footnotesize}\textsc{Notes:}"
     "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
     "to quarters 4 and 1. All values reflect the percent of births for this"
     "age group and education level."
     "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
decode ageGroup, gen(ag)
decode educLevel, gen(el)
egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample.txt", delimiter("&") replace noquote
restore

preserve
collapse (sum) birth, by(goodQuarter educLevel)
reshape wide birth, i(educLevel) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100

gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str5 b0         = string(birth0, "%05.2f")
gen str5 b1         = string(birth1, "%05.2f")
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")

drop totalbirths diff rati birth*

#delimit ;
listtex using "$SUM/PropNoTimeEduc`app'.tex", rstyle(tabular) replace
head("\vspace{8mm}\begin{table}[htpb!]"
     "\centering\caption{Percent of Births per Cell (All Years)}"
     "\begin{tabular}{lcccc}\toprule"
     "College&Bad Quarters&Good Quarters&Difference&Ratio \\ \midrule")
foot("\midrule\multicolumn{5}{p{9cm}}{\begin{footnotesize}\textsc{Notes:}"
     "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
     "to quarters 4 and 1. All values reflect the percent of births for this"
     "age group and education level."
     "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
decode educLevel, gen(el)
order el
drop educLevel
outsheet using "$SUM/JustEduc`app'.txt", delimiter("&") replace noquote
restore


preserve
drop if educLevel==.
collapse (sum) birth, by(goodQuarter ageGroup)
reshape wide birth, i( ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati

#delimit ;
listtex using "$SUM/PropNoTime2`app'.tex", rstyle(tabular) replace
head("\vspace{8mm}\begin{table}[htpb!]"
     "\centering\caption{Percent of Births per Cell (All Years)}"
     "\begin{tabular}{lcccc}\toprule"
     "Age Group &Bad Season&Good Season&Difference&Ratio \\ \midrule")
foot("\midrule\multicolumn{5}{p{9.5cm}}{\begin{footnotesize}\textsc{Notes:}"
     "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
     "to quarters 4 and 1. All values reflect the percent of births for this"
     "age group and education level."
     "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
outsheet using "$SUM/FullSample`app'.txt", delimiter("&") replace noquote
restore

foreach var of varlist premature {
    gen _`var'young = `var'       if ageGroup  == 1
    gen _`var'old = `var'         if ageGroup  == 2
    gen _`var'lowEd = `var'       if educLevel == 1
    gen _`var'highEd = `var'      if educLevel == 2
    gen _`var'younglowEd = `var'  if educLevel == 1 & ageGroup == 1
    gen _`var'younghighEd = `var' if educLevel == 2 & ageGroup == 1
    gen _`var'oldlowEd = `var'    if educLevel == 1 & ageGroup == 2
    gen _`var'oldhighEd = `var'   if educLevel == 2 & ageGroup == 2
}
sum _p*
estpost tabstat _p*, statistics(mean sd) columns(statistics)
esttab using "$SUM/spainPrem.tex", title("Premature")/*
*/ cells("mean(fmt(2)) sd(fmt(2))") replace label noobs
drop _p*
    

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
replace `estopt' title("Birth Season and Age (Spain 2013)") booktabs
keep(_cons young highEd professional married) style(tex) mlabels(, depvar)
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
replace `estopt' title("Birth Season and Age (Spain 2013)") booktabs
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
    eststo: reg `y' young badQua highEd professional married `FE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/spainQualityEduc.tex",
replace `estopt' title("Birth Quality by Age and Season (Spain 2013)")
keep(_cons young badQ* high* marr* pro*) style(tex) booktabs mlabels(, depvar)
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
         "\multicolumn{7}{p{20cm}}{\begin{footnotesize}Sample consists of all  "
         "first born children of Spanish mothers. Bad Season (due in bad) is a "
         "dummy for children expected and born in quarters 1 or 4, while Bad   "
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

