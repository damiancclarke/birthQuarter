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

local qual apgar birthweight gestation lbw premature vlbw
local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats      /*
*/           (N, fmt(%9.0g) label(Observations))                       /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local yFE    i.year
local se     robust
local cnd    if twin==1
local keepif birthOrder==1 & motherAge>24

********************************************************************************
*** (1b) Define run type
********************************************************************************
local orign  0
local a2024  0
local y1213  0
local bord2  0
local over30 0
local fterm  0
local pre4w  0
local frace  1

if `a2024'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/2024/regressions"
    local keepif birthOrder==1
}
if `over30'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/over30/regressions"
    local keepif birthOrder==1 & motherAge>24
}
if `y1213'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/2012/regressions"
    local keepif birthOrder==1 & motherAge>24 & year==2012|year==2013
}
if `bord2'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/bord2/regressions"
    local keepif birthOrder==2 & motherAge>24
}
if `fterm'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/fullT/regressions"
    local keepif birthOrder==1 & motherAge>24 & gestation>=39&gestation<46
}
if `frace'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/frace/regressions"
    local keepif birthOrder==1 & motherAge>24 & fatherWhiteNonHisp == 1
}
if `pre4w'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/pre4w/regressions"
    local keepif birthOrder==1 & motherAge>24 & gestation<=35
}

********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"
keep if `keepif'
if `a2024'==1 replace ageGroup = 1 if ageGroup == 0
if `over30'==1 drop if motherAge<30&education==6

gen birth = 1
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen badQuarter  = birthQuarter == 4  | birthQuarter == 1
replace ageGroup  = ageGroup-1 if ageGroup>1

gen highEd              = (educLevel == 1 | educLevel == 2) if educLevel!=.
gen young               = ageGroup  == 1
gen youngXhighEd        = young*highEd
gen youngXbadQ          = young*(1-goodQuarter)
gen highEdXbadQ         = highEd*(1-goodQuarter)
gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
gen youngMan            = ageGroupMan == 1
gen youngManXbadQ       = youngMan*(1-goodQuarter)
gen vhighEd             = educLevel == 2 if educLevel!=.
gen youngXvhighEd       = young*vhighEd
gen noPreVisit          = numPrenatal == 0 if numPrenatal<99
gen prenate3months      = monthPrenat>0 & monthPrenat <= 3 if monthPrenat<99
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
gen     expectedMonth   = birthMonth + monthsPrem
replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
gene    expectQuarter   = ceil(expectedMonth/3) 
gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
*replace prePregBMI      = . if prePregBMI == 99

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years" 
if `a2024'==1 {
    lab drop aG
    lab def  aG  1 "20-39" 2 "40-45"
}
lab val ageGroup    aG
lab val goodQuarter gQ

lab var goodQuarter        "Good Season"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Aged 25-39"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var ageGroup           "Categorical age group"
lab var youngXbadQ         "Young$\times$ Bad S"
lab var highEdXbadQ        "College$\times$ Bad S"
lab var youngXhighEdXbadQ  "Young$\times$ College$\times$ Bad S"
lab var youngManXbadQ      "Young Man$\times$ Bad S"
lab var vhighEd            "Complete Degree"
lab var youngXvhighEd      "Degree$\times$ Aged 25-39"
lab var married            "Married"
lab var smoker             "Smoker"
lab var noPreVisit         "No Prenatal Visits"
lab var prenate3months     "Prenatal 1\textsuperscript{st} Trimester"
lab var apgar              "APGAR"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var lbw                "LBW"
lab var premature          "Premature"
lab var vlbw               "VLBW"
*lab var prePregBMI         "Pre-pregnancy BMI"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var badExpectGood      "Bad Season (due in good)"
lab var badExpectBad       "Bad Season (due in bad)"


********************************************************************************
*** (3a) Examine missing covariates
********************************************************************************
if `orign'==1 {
    gen smokeMissing = smoker    == .
    gen educMissing  = educLevel == .
    gen fatherAgeMis = fatherAge == 11
    foreach year of numlist 2005(1)2013 {
        foreach var in smoke educ {
            gen `var'Missing`year' = 1 if `var'Missing & year==`year'
            replace `var'Missing`year' = 0 if `var'Missing`year'==.
        }
        lab var educMissing`year' "Missing Education$\times$ `year'"
        lab var smokeMissing`year' "Missing Smoking$\times$ `year'"
    }
    lab var smokeMissing "Missing Smoking"
    lab var educMissing  "Missing Education"
    lab var fatherAgeMis "Father's Age Not Known"

    local base young married
    local yv goodQuarter
    eststo: reg `yv' `base' educMissing   smokeMissing              `yFE', `se'
    eststo: reg `yv' `base' educMissing   smokeMissing   fatherAgeM `yFE', `se'
    eststo: reg `yv' `base' educMissing2* smokeMissing   fatherAgeM `yFE', `se'
    eststo: reg `yv' `base' educMissing2* smokeMissing2* fatherAgeM `yFE', `se'
    #delimit ;
    esttab est1 est2 est3 est4 using "$OUT/NVSSMissing.tex",
    replace `estopt' title("Missing Records (NVSS 2005-2013)") booktabs 
    keep(_cons `base' educM* smokeM* fatherA*) style(tex) mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{5}{p{15cm}}{\begin{footnotesize}All regressions "
             "include year fixed effects.  Missing values for smoking and "
             "education are for those states who have not yet adopted the 2003 "
             "updated birth certificates.  Father's age is missing where it "
             "is not reported by the mother."
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
}

********************************************************************************
*** (4a) Regressions (goodQuarter on Age)
********************************************************************************
local pre noPreVisit prenate3months
local bmi prePregBMI

eststo: reg goodQuarter young                                   `cnd', `se'
eststo: reg goodQuarter young                             `yFE' `cnd', `se'
eststo: reg goodQuarter young highEd                      `yFE' `cnd', `se'
eststo: reg goodQuarter young highEd married smoker       `yFE' `cnd', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinary.tex",
replace `estopt' title("Birth Season and Age (NVSS 2005-2013)") booktabs 
keep(_cons young highEd married smoker) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{12cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: reg goodQuarter young                                    `cnd', `se'
eststo: reg goodQuarter young                              `yFE' `cnd', `se'
eststo: reg goodQuarter young vhighEd                      `yFE' `cnd', `se'
eststo: reg goodQuarter young vhighEd married smoker       `yFE' `cnd', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryHigh.tex",
replace `estopt' title("Birth Season and Age (NVSS 2005-2013)") booktabs
keep(_cons young vhighEd married smoker) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{12cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if twin==2
eststo: reg goodQuarter young                                   `cond', `se'
eststo: reg goodQuarter young                             `yFE' `cond', `se'
eststo: reg goodQuarter young highEd                      `yFE' `cond', `se'
eststo: reg goodQuarter young highEd married smoker       `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryTwin.tex",
replace `estopt' title("Birth Season and Age (Twins Only)") booktabs
keep(_cons young highEd married smoker) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{12cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


foreach m of numlist 0 1 {
    foreach g in smk mar {
        if `"`g'"'=="smk" {
            local cond `cnd' & smoker==`m'
            if `m'==1 local Title "smoking"
            if `m'==0 local Title "non-smoking"
        }
        if `"`g'"'=="mar" {
            local cond `cnd' & married==`m'
            if `m'==0 local Title "unmarried"
            if `m'==1 local Title "married"
        }
        eststo: reg goodQuarter young                    `cond', `se'
        eststo: reg goodQuarter young              `yFE' `cond', `se'
        eststo: reg goodQuarter young highEd       `yFE' `cond', `se'
    
        #delimit ;
        esttab est1 est2 est3  using "$OUT/NVSSBinary`Title'.tex",
        replace `estopt' title("Birth Season and Age (NVSS: `Title' women)")
        keep(_cons young highEd) style(tex) booktabs mlabels(, depvar)
        postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{10.5cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic, `Title' mothers."
         "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }
}

local cond `cnd' & single==1
eststo: reg goodQuarter young                    `cond', `se'
eststo: reg goodQuarter young              `yFE' `cond', `se'
eststo: reg goodQuarter young highEd       `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 using "$OUT/NVSSBinarySingle.tex",
replace `estopt' title("Birth Season and Age: Single Women (NVSS 2005-2013)")
keep(_cons young highEd) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{10.5cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic single mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

if `y1213'==1 {
    foreach m of numlist 0 1 {
        local cond `cnd'&infertTreat==`m'

        eststo: reg goodQuarter young                               `cond', `se'
        eststo: reg goodQuarter young                         `yFE' `cond', `se'
        eststo: reg goodQuarter young highEd                  `yFE' `cond', `se'
        eststo: reg goodQuarter young highEd married smoker   `yFE' `cond', `se'

        #delimit ;
        esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryInfert`m'.tex", replace
        `estopt' title("Birth Season and Age (Infertility Treatment=`m')")  
        keep(_cons young highEd married smoker) style(tex) mlabels(, depvar)
        postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{12cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
         #delimit cr
        estimates clear
    }
}
********************************************************************************
*** (4b) Regressions (Quality on Age, season)
********************************************************************************
foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter `yFE' `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality.tex",
replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

foreach e in 0 1 {
    if `e'==0 local educN "with no college education"
    if `e'==1 local educN "with college education"
    
    foreach y of varlist `qual' {
        eststo: reg `y' young badQuarter `yFE' `cnd' & highEd==`e', `se'
    }
    #delimit ;
    esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality`e'.tex",
    replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
    keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
             "first born children of US-born, white, non-hispanic mothers `educN'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
}
estimates clear

foreach s in 0 1 {
    if `s'==0 local smokeN "who do not smoke"
    if `s'==1 local smokeN "who smoke"
    
    foreach y of varlist `qual' {
        eststo: reg `y' young badQuarter `yFE' `cnd' & smoker==`s', `se'
    }
    #delimit ;
    esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQualitySmoke`s'.tex",
    replace `estopt' title("Birth Quality by Age and Season (Mothers `smokeN')")
    keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
             "first born children of US-born, white, non-hispanic mothers `smokeN'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
}
estimates clear


foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter highEd married smoker `yFE'  `cnd', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQualityEduc.tex",
replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
keep(_cons young badQuarter highEd married smoker) style(tex) mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
#delimit cr
estimates clear

if `y1213'==1 {
    foreach m of numlist 0 1 {
        local cond `cnd'&infertTreat==`m'
        foreach y of varlist `qual' {
            eststo: reg `y' young badQuarter highEd mar smo `yFE' `cond', `se'
        }
        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using
        "$OUT/NVSSQualityInfert`m'.tex", replace `estopt' mlabels(, depvar)
        title("Birth Quality by Age and Season (Infertility=`m')")
        keep(_cons young badQuarter highEd married smoker) style(tex) 
        postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
        #delimit cr
        estimates clear
    }
}
********************************************************************************
*** (5) Redefine bad season as bad season due to short gestation, and bad season
********************************************************************************
if `orign'==1 {
    local controls highEd married smoker
    foreach y of varlist apgar birthweight lbw vlbw {
        eststo: reg `y' young badExpect* `controls' i.gestation `yFE' `cnd', `se'
    }
    #delimit ;
    esttab est1 est2 est3 est4 using "$OUT/NVSSQualityGestFix.tex", replace 
    `estopt' title("Birth Quality by Age and Season (Accounting for Gestation)")
    keep(_cons young badExpect* `controls') style(tex) mlabels(, depvar)
    postfoot("\bottomrule"
         "\multicolumn{5}{p{13.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers."
         "Bad Season (due in bad) is a dummy for children expected and born in"
         "quarters 1 or 4, while Bad Season (due in good) is a dummy for children"
         "expected in quarters 2 or 3, but were born prematurely in quarters 1 or"
         "4.  Fixed effects for weeks of gestation are included."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear
}
exit
********************************************************************************
*** (6) Appendix including fetal deaths
********************************************************************************
append using "$DAT/nvssFD2005_2013"
replace goodQuarter = 1 if liveBirth==0 & birthQuarter == 2 | birthQuarter == 3
replace badQuarter  = 1 if liveBirth==0 & birthQuarter == 1 | birthQuarter == 4
replace highEd      = 1 if liveBirth==0 & (educLevel == 1 | educLevel == 2)
replace young       = 1 if liveBirth==0 & motherAge>=24 & motherAge<=39

eststo: reg goodQuarter young                                   `cnd', `se'
eststo: reg goodQuarter young                             `yFE' `cnd', `se'
eststo: reg goodQuarter young highEd                      `yFE' `cnd', `se'
eststo: reg goodQuarter young highEd married smoker       `yFE' `cnd', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryFDeaths.tex",
replace `estopt' title("Birth Season and Age (Including Fetal Deaths)") 
keep(_cons young highEd married smoker) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{13cm}}{\begin{footnotesize}Sample consists of all"
         "firsts (live births and fetal deaths) of US-born, white, non-hispanic"
         "mothers.  Fetal deaths are included if occurring between 25 and 44"
         "weeks of gestation.  Education is recorded for fetal deaths only "
         "prior to 2008."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs ;
#delimit cr
estimates clear


********************************************************************************
*** (X) Clear
********************************************************************************
log close
