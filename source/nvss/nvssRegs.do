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
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/nvss/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

local qual birthweight lbw vlbw gestation premature apgar 
local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats      /*
*/           (N, fmt(%9.0g) label(Observations))                             /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local yFE    i.year
local se     robust
local cnd    if twin==1 & motherAge>24 & motherAge <= 45
local keepif birthOrder==1 


********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"
keep if `keepif'

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
gen age2534             = motherAge>=25 & motherAge <35
gen age3539             = motherAge>=35 & motherAge <40
gen noPreVisit          = numPrenatal == 0 if numPrenatal<99
gen prenate3months      = monthPrenat>0 & monthPrenat <= 3 if monthPrenat<99
gen motherAge2          = motherAge^2
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
gen     expectedMonth   = birthMonth + monthsPrem
replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
gene    expectQuarter   = ceil(expectedMonth/3) 
gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.

gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.
gen     noART           = (ART-1)*-1
gen     noARTyoung      = noART*young
sum expectGoodQ expectBadQ
sum Qgoodgood Qgoodbad Qbadgood Qbadbad



********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years" 
lab val ageGroup    aG
lab val goodQuarter gQ

lab var goodQuarter        "Good Season"
lab var expectGoodQ        "Good Expect"
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
lab var age2534            "Aged 25-34"
lab var age3539            "Aged 35-39"
lab var married            "Married"
lab var smoker             "Smoked in Preg"
lab var noPreVisit         "No Prenatal Visits"
lab var prenate3months     "Prenatal 1\textsuperscript{st} Trimester"
lab var apgar              "APGAR"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var lbw                "LBW"
lab var premature          "Premature"
lab var vlbw               "VLBW"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var badExpectGood      "Bad Season (due in good)"
lab var badExpectBad       "Bad Season (due in bad)"
lab var Qgoodbad           "Bad Season (due in good)"
lab var Qbadbad            "Bad Season (due in bad)"
lab var Qbadgood           "Good Season (due in bad)"
lab var motherAge          "Mother's Age (years)"
lab var motherAge2         "Mother's Age$^2$"
lab var noART              "Did not undertake ART"
lab var noARTyoung         "No ART$\times$ Young"

/*
********************************************************************************
*** (3a) Examine missing covariates
********************************************************************************
preserve
keep `cnd'
gen smokeMissing = smoker    == .
gen educMissing  = educLevel == .
gen fatherAgeMis = fatherAge == 11
foreach year of numlist 2005(1)2013 {
    foreach var in smoke educ {
        gen `var'Missing`year' = 1 if `var'Missing & year==`year'
        replace `var'Missing`year' = 0 if `var'Missing`year'==.
    }
    lab var educMissing`year'  "Missing Education$\times$ `year'"
    lab var smokeMissing`year' "Missing Smoking$\times$ `year'"
}
lab var smokeMissing "Missing Smoking"
lab var educMissing  "Missing Education"
lab var fatherAgeMis "Father's Age Not Known"

local base young married
local y goodQuarter
eststo: reg `y' `base' educMissing   smokeMissing              `yFE', `se'
eststo: reg `y' `base' educMissing   smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing2* fatherAgeM `yFE', `se'
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

restore
*/

********************************************************************************
*** (4) Good Quarter Regressions
********************************************************************************

********************************************************************************
*** (4a) Different sets of explanatory variables
********************************************************************************
preserve
keep `cnd'

local add `" "" "(Young=25-34)" "(Education Interaction)" "(Complete College)" "'
local nam Main Young34 EdInteract High
local add `" ""  "(Seperated by Age)" "'
local nam Main Deseg
tokenize `nam'

foreach type of local add {

    local age young
    local edu highEd
    local con married smoker
    local yab abs(year)
    local ges i.gestation
    if `"`1'"' == "Young34"    local age age2534
    if `"`1'"' == "EdInteract" local edu highEd youngXhighEd
    if `"`1'"' == "High"       local edu vhighEd 
    if `"`1'"' == "Deseg"      local age age2534 age3539

    eststo: areg goodQuarter `age' `edu' `con'                   , `se' `yab'
    eststo: areg goodQuarter `age' `edu'             if e(sample), `se' `yab'
    eststo: areg goodQuarter `age'                   if e(sample), `se' `yab'
    eststo:  reg goodQuarter `age'                   if e(sample), `se'
    eststo: areg goodQuarter `age' `edu' `con'                   , `se' `yab'
    eststo: areg goodQuarter `age' `edu' `con' noART             , `se' `yab'
    eststo: areg goodQuarter `age' `edu' `con' noART `ges'       , `se' `yab'

    #delimit ;
    esttab est4 est3 est2 est1 est5 est6 est7 using "$OUT/NVSSBinary`1'.tex",
    replace `estopt' title("Birth Season and Age `type'") booktabs 
    keep(_cons `age' `edu' noART `con') style(tex) mlabels(, depvar)
    postfoot("Year FE&&Y&Y&Y&Y&Y&Y\\ 2012-2013 Only&&&&&Y&Y&Y\\            "
             "Gestation FE &&&&&&&Y\\ \bottomrule                          "
             "\multicolumn{8}{p{18cm}}{\begin{footnotesize}Sample consists "
             "of all first born children of US-born, white, non-hispanic   "
             "mothers. \end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    eststo: areg expectGoodQ `age' `edu' `con'                   , `se' `yab'
    eststo: areg expectGoodQ `age' `edu'             if e(sample), `se' `yab'
    eststo: areg expectGoodQ `age'                   if e(sample), `se' `yab'
    eststo:  reg expectGoodQ `age'                   if e(sample), `se'
    eststo: areg expectGoodQ `age' `edu' `con'                   , `se' `yab'
    eststo: areg expectGoodQ `age' `edu' `con' noART             , `se' `yab'
    eststo: areg expectGoodQ `age' `edu' `con' noART `ges'       , `se' `yab'

    #delimit ;
    esttab est4 est3 est2 est1 est5 est6 est7 using "$OUT/NVSSExpect`1'.tex",
    replace `estopt' title("Birth Season and Age `type'") booktabs 
    keep(_cons `age' `edu' noART `con') style(tex) mlabels(, depvar)
    postfoot("Year FE&&Y&Y&Y&Y&Y&Y\\ 2012-2013 Only&&&&&Y&Y&Y\\            "
             "Gestation FE &&&&&&&Y\\ \bottomrule                          "
             "\multicolumn{8}{p{18cm}}{\begin{footnotesize}Sample consists "
             "of all first born children of US-born, white, non-hispanic   "
             "mothers for whom gestation is recorded."
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    macro shift
}

*ART TABLE
eststo: areg goodQuarter noART young highEd                 , `se' abs(year)
eststo: areg goodQuarter noART young noARTyoung if e(sample), `se' abs(year)
eststo: areg goodQuarter noART young            if e(sample), `se' abs(year)
eststo: areg goodQuarter noART                  if e(sample), `se' abs(year)
eststo:  reg goodQuarter noART                  if e(sample), `se' 
    
#delimit ;
esttab est5 est4 est3 est1 est2 using "$OUT/NVSSBinaryART.tex",
replace `estopt' title("Birth Season and ART Usage") booktabs 
keep(_cons noART young noARTyoung highEd) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y&Y\\  \bottomrule                              "
         "\multicolumn{6}{p{13cm}}{\begin{footnotesize}Sample consists "
         "of all first born children of US-born, white, non-hispanic   "
         "mothers from 2012-2013.                                      "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore

********************************************************************************
*** (4b) Conditions
********************************************************************************
/*
local c1 twin==2 smoker==0&twin==1 smoker==1&twin==1 year>=2012&twin==1  /*
      */ infertTreat==0&twin==1 infertTreat==1&twin==1 twin==1 married==0&twin==1
local names Twin non-smoking smoking 2012-2013 non-ART ART Main unmarried
tokenize `names'

foreach cond of local c1 {
    dis "`1'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    local cn 5
    local cm 12
    local sp "&&Y&Y&Y"
    
    eststo: reg goodQuarter young                             , `se'
    eststo: reg goodQuarter young                        `yFE', `se'
    eststo: reg goodQuarter young highEd                 `yFE', `se'
    eststo: reg goodQuarter young highEd married smoker  `yFE', `se'
    
    local ests est1 est2 est3 est4 
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"
    if `"`1'"' == "unmarried"     local cm 10.4

    local vars _cons young highEd married smoker
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local ests est1 est2 est3 
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local vars _cons young highEd    
    if `"`1'"'=="unmarried"                      local vars _cons young highEd
    
    #delimit ;
    esttab `ests' using "$OUT/NVSSBinary`1'.tex", replace `estopt' booktabs 
    title("Birth Season and Age (`1' sample)") keep(`vars') mlabels(, depvar)
    postfoot("Year FE`sp'\\ \bottomrule"
             "\multicolumn{`cn'}{p{`cm'cm}}{\begin{footnotesize}Sample consists"
             " of all first births to US-born, white, non-hispanic mothers.    "
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
    restore
}

********************************************************************************
*** (4b-i) Conditions (age continuous)
********************************************************************************
local c1 twin==1&motherAge>24&motherAge<=45
local names Main
tokenize `names'

foreach cond of local c1 {
    dis "`1'"
    preserve
    keep `cond'
    local cn 7
    local sp "&&Y&Y&Y&Y&Y"
    local age motherAge
    local edu highEd
    local con married smoker
    local yab abs(year)
    
    eststo: areg goodQuarter `age' `edu' `con'                   , `se' `yab'
    eststo: areg goodQuarter `age' `edu'             if e(sample), `se' `yab'
    eststo: areg goodQuarter `age'                   if e(sample), `se' `yab'
    eststo:  reg goodQuarter `age'                   if e(sample), `se'
    eststo: areg goodQuarter `age' `edu' `con'       if ART!=.   , `se' `yab'
    eststo: areg goodQuarter `age' `edu' `con' noART if ART!=.   , `se' `yab'

    
    local ests est4 est3 est2 est1 est5 est6  
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"
    local vars _cons motherAge highEd married smoker noART
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local ests est1 est2 est3 
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local vars _cons motherAge highEd    
    if `"`1'"'=="unmarried"                      local vars _cons motherAge highEd    
    
    #delimit ;
    esttab `ests' using "$OUT/NVSSBinary`1'_A.tex", replace `estopt' booktabs 
    title("Birth Season and Age (`1' sample)") keep(`vars') mlabels(, depvar)
    postfoot("Year FE`sp'\\ \bottomrule"
             "\multicolumn{`cn'}{p{12cm}}{\begin{footnotesize}Sample consists "
             " of all first births to US-born, white, non-hispanic mothers.   "
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
    restore
}

********************************************************************************
*** (4b-ii) Conditions (age and age sq)
********************************************************************************
local c1 twin==1&motherAge>24&motherAge<=45
local names Main
tokenize `names'

foreach cond of local c1 {
    dis "`1'"
    preserve
    keep `cond'
    local cn 7
    local sp "&&Y&Y&Y&Y&Y"
    local age motherAge motherAge2
    local edu highEd
    local con married smoker
    local yab abs(year)
    
    eststo: areg goodQuarter `age' `edu' `con'                 , `se' `yab'
    eststo: areg goodQuarter `age' `edu'             if e(sample), `se' `yab'
    eststo: areg goodQuarter `age'                   if e(sample), `se' `yab'
    eststo:  reg goodQuarter `age'                   if e(sample), `se'
    eststo: areg goodQuarter `age' `edu' `con'       if ART!=.   , `se' `yab'
    eststo: areg goodQuarter `age' `edu' `con' noART if ART!=.   , `se' `yab'
    
    local ests est1 est2 est3 est4 est5 est6
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"
    local vars _cons motherAge motherAge2 highEd married smoker noART
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local ests est1 est2 est3 
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking"|`"`1'"'=="unmarried" /*
    */ local vars _cons motherAge motherAge2 highEd    
    
    #delimit ;
    esttab `ests' using "$OUT/NVSSBinary`1'_A2.tex", replace `estopt' booktabs 
    title("Birth Season and Age (`1' sample)") keep(`vars') mlabels(, depvar)
    postfoot("Year FE`sp'\\ \bottomrule"
             "\multicolumn{`cn'}{p{14.8cm}}{\begin{footnotesize}Sample consists"
             " of all first births to US-born, white, non-hispanic mothers.    "
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
    restore
}

********************************************************************************
*** (4c) Multinomial logit for expected/realised
********************************************************************************
preserve
keep `cnd'

gen     seasonType = 1 if Qgoodgood  == 1
replace seasonType = 2 if Qgoodbad   == 1
replace seasonType = 3 if Qbadgood   == 1
replace seasonType = 4 if Qbadbad    == 1
replace seasonType = . if seasonType == 0
lab var smoker "Smoked during pregnancy"

mlogit seasonType young highEd married smoker `yFE', vce(robust)
eststo mlogit

foreach o in 2 3 4 {
    dis "MFX for `o'"
    estpost margins, dydx(young highEd married smoker) predict(outcome(`o'))
    estimates store sm`o'
    estimates restore mlogit
}
    
#delimit ;
esttab sm2 sm3 sm4 using "$OUT/NVSSseasonMLogit.tex",
replace `estopt' style(tex) keep(young highEd married smoker)
mtitles("Good,Bad" "Bad,Good" "Bad,Bad")
title("Birth Season Predictors (Multinomial Logit)") 
postfoot("\bottomrule"
         "\multicolumn{4}{p{11.2cm}}{\begin{footnotesize} Estimated average   "
         "marginal effects are reported. Standard errors for marginal effects "
         "are calculated using the delta method. Year fixed effects included  "
         "(not reported). `Good,Bad' refers to expected in good, born in bad, "
         "and similar for other columns. Expected in good and born in good is "
         "the omitted base outcome."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
#delimit cr
estimates clear
restore

********************************************************************************
*** (5) Regressions (Quality on Age, season)
********************************************************************************
local c1      twin==1 year>=2012&twin==1 infertTreat==0&twin==1 /*
              */ infertTreat==1&twin==1 twin==2 
local varsY   young goodQuarter highEd married smoker
local varsA   motherAge goodQuarter highEd married smoker
local varsA2  motherAge motherAge2 goodQuarter highEd married smoker
local names   Main 2012-2013 non-ART ART Twin
tokenize `names'


foreach cond of local c1 {
    dis "`1'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    foreach ageType in Y A A2 {
        local nT "_`ageType'"
        if `"`ageType'"'=="Y" local nT

        
        foreach y of varlist `qual' {
            eststo: reg `y' `vars`ageType'' `yFE', `se'
        }

        local Ovars _cons `vars`ageType''
        if `"`1'"'=="non-smoking"|`"`1'"'=="smoking"|`"`1'"'=="unmarried" {
            if `"`ageType'"'=="Y"  local Ovars _cons young goodQuarter highEd
            if `"`ageType'"'=="A"  local Ovars _cons motherAge goodQuarter highEd
            if `"`ageType'"'=="A2" local Ovars _cons motherAge motherAge2 /*
            */ goodQuarter highEd
        }
    
        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality`1'`nT'.tex",
        replace `estopt' title("Birth Quality by Age and Season (`1' sample)")
        keep(_cons `Ovars') style(tex) mlabels(, depvar) booktabs
        postfoot("\bottomrule"
                 "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists "
                 "of all first born children of US-born, white, non-hispanic   "
                 "mothers. \end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }
    
    macro shift
    restore
}
*/

preserve
keep `cnd'
*COMBINED AGE TABLES
local controls age2534 age3539 goodQuarter highEd married smoker
foreach y of varlist `qual' {
    eststo: reg `y' `controls' `yFE', `se'
}

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQualityDeseg.tex",
replace `estopt' title("Birth Quality by Age and Season (Seperated by Age)")
keep(_cons `controls') style(tex) mlabels(, depvar) booktabs
postfoot("\bottomrule"
         "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists "
         "of all first born children of US-born, white, non-hispanic   "
         "mothers. \end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore

exit
********************************************************************************
*** (5a) Redefine bad season as bad season due to short gest, and bad season
********************************************************************************
local cont highEd married smoker
local cont
local seasons Qgoodbad Qbadgood Qbadbad
local aa abs(gestation)

preserve
keep `cnd'

eststo: reg  birthweight young `seasons' `cont' `yFE'      , `se'
eststo: areg birthweight young `seasons' `cont' `yFE'      , `se' `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' if young==1, `se'
eststo: areg birthweight `seasons' `cont' `yFE' if young==1, `se' `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' if young==0, `se'
eststo: areg birthweight `seasons' `cont' `yFE' if young==0, `se' `aa'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/QualityAllComb.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) collabels(none) label
stats (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations)) booktabs            
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) style(tex)
title("Birth Quality by Age and Season") keep(_cons young `seasons')  
mtitles("No Gest" "Gestation" "No Gest" "Gestation" "No Gest" "Gestation")
mgroups("All" "Young" "Old", pattern(1 0 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(r){@span}))
postfoot("\bottomrule"
         "\multicolumn{7}{p{19.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers. Bad     "
         "Season (due in bad) is a dummy for children expected and born in     "
         "quarters 1 or 4, while Bad Season (due in good) is a dummy for       "
         "children expected in quarters 2 or 3, but were born prematurely in   "
         "quarters 1 or 4.  For each outcome, the first column is unconditional"
         "on gestation while the second column includes fixed effects for weeks"
         " of gestation. "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local seasons expectGoodQ
    
eststo: reg  birthweight young `seasons' `cont' `yFE'      , `se'
eststo: areg birthweight young `seasons' `cont' `yFE'      , `se' `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' if young==1, `se'
eststo: areg birthweight `seasons' `cont' `yFE' if young==1, `se' `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' if young==0, `se'
eststo: areg birthweight `seasons' `cont' `yFE' if young==0, `se' `aa'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/QualityAllCombExp.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) collabels(none) label
stats (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations)) booktabs            
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) style(tex)
title("Birth Quality by Age and Season") keep(_cons young `seasons')  
mtitles("No Gest" "Gestation" "No Gest" "Gestation" "No Gest" "Gestation")
mgroups("All" "Young" "Old", pattern(1 0 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(r){@span}))
postfoot("\bottomrule"
         "\multicolumn{7}{p{19.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers. For each"
         " outcome, the first column is unconditional on gestation while the   "
         "second column includes fixed effects for weeks"
         " of gestation. "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore

exit
********************************************************************************
*** (6) Appendix including fetal deaths
********************************************************************************
append using "$DAT/nvssFD2005_2013"
replace goodQuarter = 1 if liveBirth==0 & birthQuarter == 2 | birthQuarter == 3
replace goodQuarter = 0 if liveBirth==0 & birthQuarter == 1 | birthQuarter == 4
replace highEd      = 1 if liveBirth==0 & (educLevel == 1 | educLevel == 2)
replace highEd      = 0 if liveBirth==0 & educLevel == 0
replace young       = 1 if liveBirth==0 & motherAge>=24 & motherAge<=39
replace young       = 0 if liveBirth==0 & motherAge>=40


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

    
local cond `cnd'&liveBirth==0
eststo: reg goodQuarter young                                   `cond', `se'
eststo: reg goodQuarter young                             `yFE' `cond', `se'
eststo: reg goodQuarter young highEd                      `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 using "$OUT/NVSSBinaryFDeathsOnly.tex",
replace `estopt' title("Birth Season and Age (Fetal Deaths Only)") 
keep(_cons young highEd ) style(tex) mlabels(, depvar)
postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{9cm}}{\begin{footnotesize}Sample consists of all"
         "firsts (live births and fetal deaths) of US-born, white, non-hispanic"
         "mothers.  Fetal deaths are included if occurring between 25 and 44"
         "weeks of gestation.  Education is recorded for fetal deaths only "
         "prior to 2008."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs ;
#delimit cr
estimates clear

*/
********************************************************************************
*** (7) 1970, 1990 regs
********************************************************************************
insheet using "$USW/usaWeather.txt", delim(";") names
rename fips stoccfip
destring temp, replace

reshape wide temp, i(state stoccfip year month) j(type) string
keep if year>=1990&year<=1999
bys state year (temptmpcst): gen tempOrder = _n
foreach num of numlist 1 2 3 {
    gen min`num' = month if tempOrder == `num'
    by state year: egen minMonth`num' = mean(min`num')
    drop min`num'
}

gen minTemp = temptminst if tempOrder ==1
bys state: egen aveMinTemp=mean(minTemp)
drop tempOrder minTemp

reshape wide temp*, i(state stoccfip year minMonth* aveMinTemp) j(month)
gen coldState_20 = aveMinTemp<20

tostring stoccfip, replace
foreach num in 1 2 4 5 6 8 9 {
    replace stoccfip = "0`num'" if stoccfip=="`num'"
}
expand 2 if stoccfip == "24", gen(expanded)
replace stoccfip = "11" if expanded == 1
drop expanded

tempfile weather
save `weather'


foreach syear of numlist 1990 /*1970*/ {
    global OUT "~/investigacion/2015/birthQuarter/results/`syear's/regressions"

    use "$DAT/nvss`syear's", clear
    keep if birthOrder==1 & motherAge>24
    merge m:1 stoccfip year using `weather'
    gen badSeasonWeather = birthMonth == minMonth1 | birthMonth == minMonth2 /*
                      */ | birthMonth == minMonth3
    replace badSeasonWeather = 1 if statenat=="12"&/*
                      */       (birthMonth==12|birthMonth==1|birthMonth==2)
    gen goodSeasonWeather = badSeasonWeather == 0
    
    gen birth = 1
    gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
    gen badQuarter  = birthQuarter == 4 | birthQuarter == 1
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
    gen     prematurity     = gestation - 39
    gen     monthsPrem      = round(prematurity/4)*-1
    gen     expectedMonth   = birthMonth + monthsPrem
    replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
    replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
    gene    expectQuarter   = ceil(expectedMonth/3) 
    gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
    gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
    gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
    gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.

    gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
    gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
    gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
    gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.

    sum expectGoodQ expectBadQ
    sum Qgoodgood Qgoodbad Qbadgood Qbadbad

    lab def aG  1 "25-39" 2 "40-45"
    lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
    lab def eL  1 "No College" 2 "1-5 years" 
    lab val ageGroup    aG
    lab val goodQuarter gQ
    
    lab var goodSeasonWeather  "Good Season"
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
    lab var birthweight        "Birthweight"
    lab var gestation          "Gestation"
    lab var lbw                "LBW"
    lab var premature          "Premature"
    lab var vlbw               "VLBW"
    lab var prematurity        "Weeks premature"
    lab var monthsPrem         "Months Premature"
    lab var badExpectGood      "Bad Season (due in good)"
    lab var badExpectBad       "Bad Season (due in bad)"
    lab var Qgoodbad           "Bad Season (due in good)"
    lab var Qbadbad            "Bad Season (due in bad)"
    lab var Qbadgood           "Good Season (due in bad)"
    if `syear'==1990 lab var smoker             "Smoked in Preg"
    if `syear'==1990 lab var apgar              "APGAR"


    ****************************************************************************
    *** (7a) Good season predictors
    ****************************************************************************
    encode statenat, gen(statecode)
    local abs abs(statecode)
    /*
    local smoke
    if `syear'==1990 local smoke smoker

    eststo:  reg goodQuarter young                              `cnd', `se'
    eststo:  reg goodQuarter young                        `yFE' `cnd', `se'
    eststo:  reg goodQuarter young highEd                 `yFE' `cnd', `se'
    eststo:  reg goodQuarter young highEd married `smoke' `yFE' `cnd', `se' 
    eststo: areg goodQuarter young highEd married `smoke' `yFE' `cnd', `se' `abs'

    #delimit ;
    esttab est1 est2 est3 est4 est5 using "$OUT/NVSSBinary.tex",
    replace `estopt' title("Birth Season and Age: `syear'") booktabs 
    keep(_cons young highEd married) style(tex) mlabels(, depvar)
    postfoot("Year FE&&Y&Y&Y&Y\\ State FE&&&&&Y\\ \bottomrule"
         "\multicolumn{6}{p{15.6cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers in the   "
         "`syear'. \end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    
    eststo:  reg goodSeasonW young                              `cnd', `se'
    eststo:  reg goodSeasonW young                        `yFE' `cnd', `se'
    eststo:  reg goodSeasonW young highEd                 `yFE' `cnd', `se'
    eststo:  reg goodSeasonW young highEd married `smoke' `yFE' `cnd', `se' 
    eststo: areg goodSeasonW young highEd married `smoke' `yFE' `cnd', `se' `abs'

    #delimit ;
    esttab est1 est2 est3 est4 est5 using "$OUT/NVSSBinaryWeather.tex",
    replace `estopt' title("Birth Season and Age (Weather to define Good Season)") 
    keep(_cons young highEd married) style(tex) mlabels(, depvar) booktabs 
    postfoot("Year FE&&Y&Y&Y&Y\\ State FE&&&&&Y\\ \bottomrule"
         "\multicolumn{6}{p{15.6cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers in the   "
         "`syear'. Good season is defined as a birth occurring in one of the   "
         "nine warmest months of the year for each state.                      "
         "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
    
    ****************************************************************************
    *** (7b) Mlogit
    ****************************************************************************
    gen     seasonType = 1 if Qgoodgood  == 1
    replace seasonType = 2 if Qgoodbad   == 1
    replace seasonType = 3 if Qbadgood   == 1
    replace seasonType = 4 if Qbadbad    == 1
    replace seasonType = . if seasonType == 0
    local cnew `cnd'&seasonType>1
    local sFE  i.statecode

    mlogit seasonType young highEd married `yFE' `cnd', vce(robust)
    eststo mlogit

    foreach o in 2 3 4 {
        dis "MFX for `o'"
        estpost margins, dydx(young highEd married) predict(outcome(`o'))
        estimates store sm`o'
        estimates restore mlogit
    }
    
    mlogit seasonType young highEd married `yFE' `sFE' `cnd', vce(robust)
    eststo mlogit

    foreach o in 2 3 4 {
        dis "MFX for `o'"
        estpost margins, dydx(young highEd married) predict(outcome(`o'))
        estimates store smFE`o'
        estimates restore mlogit
    }

    #delimit ;
    esttab sm2 sm3 sm4 smFE2 smFE3 smFE4 using "$OUT/NVSSseasonMLogit.tex",
    replace `estopt' style(tex) keep(young highEd married)
    mtitles("Good,Bad" "Bad,Good" "Bad,Bad" "Good,Bad" "Bad,Good" "Bad,Bad")
    mgroups("No State FE" "State FE", pattern(1 0 0 1 0 0)
    prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
    title("Birth Season Predictors (Multinomial Logit): `syear'") 
    postfoot("\bottomrule"
         "\multicolumn{7}{p{16cm}}{\begin{footnotesize} Estimated average   "
         "marginal effects are reported. Standard errors for marginal effects "
         "are calculated using the delta method. Year fixed effects included  "
         "(not reported). `Good,Bad' refers to expected in good, born in bad, "
         "and similar for other columns. Expected in good and born in good is "
         "the omitted base outcome."
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear
    */
    ****************************************************************************
    *** (7c) Quality regs
    ****************************************************************************
*    gen badSeasonCold = badSeasonWeather*cold
    gen badSeasonCold = badQuarter*cold
    lab var badSeasonWeather "Bad Season (weather)"
    lab var coldState_20     "Cold State"               
    lab var badSeasonCold    "Bad Season$\times$ Cold"
    
    local wvar badSeasonWeather badSeasonCold
    local wvar badQuarter badSeasonCold
    local cvar highEd married smoker 
    local FE2  i.year i.statecode
    local sec  cluster(statecode)
    

    foreach y of varlist `qual' {
        eststo: reg `y' young badSeasonWeather `cvar' `FE2' `cnd', `sec'
        eststo: reg `y' young `wvar'           `cvar' `FE2' `cnd', `sec'
    }

    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/NVSSQualityWeather.tex",
    replace `estopt' keep(_cons young badSeasonWeather `cvar') style(tex)
    mlabels(, depvar) booktabs
    title("Birth Quality by Age and Season (Weather to define Good Season)")    
    postfoot("\bottomrule"
             "\multicolumn{7}{p{16.4cm}}{\begin{footnotesize}Sample consists"
             " of all first born children of US-born, white, non-hispanic   "
             "mothers. Warm or cold states are defined as a minimum yearly  "
             "temperature of above or below 20 degrees Fahrenheit.          "
             "\end{footnotesize}}\end{tabular}\end{table}");

    esttab est2 est4 est6 est8 est10 est12 using "$OUT/NVSSQualityWInterac.tex",
    replace `estopt' keep(_cons young `wvar' `cvar') style(tex)
    mlabels(, depvar) booktabs
    title("Birth Quality by Age and Season (Weather Interactions)")    
    postfoot("\bottomrule"
             "\multicolumn{7}{p{16.2cm}}{\begin{footnotesize}Sample consists"
             " of all first born children of US-born, white, non-hispanic   "
             "mothers. Warm or cold states are defined as a minimum yearly  "
             "temperature of above or below 20 degrees Fahrenheit.          "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    gen statetype = "Cold" if coldState_20==1
    replace statetype = "Warm" if coldState_20==0|statenat=="12"
    foreach ww in Warm Cold {
        local cond `cnd'&statetype=="`ww'"
        foreach y of varlist `qual' {
            eststo: reg `y' young badSeasonWeather `cvar' `FE2' `cond', `sec'
        }
        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality`ww'.tex",
        replace `estopt' keep(_cons badSeasonWeather `cvar') style(tex)
        mlabels(, depvar) booktabs
        title("Birth Quality by Age and Season (`ww' states only)")    
        postfoot("\bottomrule"
                 "\multicolumn{7}{p{16.2cm}}{\begin{footnotesize}Sample consist"
                 "s of all first born children of US-born, white, non-hispanic "
                 "mothers. Warm or cold states are defined as a minimum yearly "
                 " temperature of above or below 20 degrees Fahrenheit.        "
                 "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }

    ****************************************************************************
    *** (7d) Quality regs -- gestation interaction
    **************************************************************************** 
    foreach method in FE noFE {
        local cont highEd married
        local seasons Qgoodbad Qbadgood Qbadbad
        local aa abs(gestation)
        local FEs `yFE'

        if `"`method'"'=="FE" local FEs `yFE' i.statecode

        eststo: reg  birthweight young `seasons' `cont' `FEs' `cnd', `se'
        eststo: areg birthweight young `seasons' `cont' `FEs' `cnd', `se'    `aa'
        eststo: reg  birthweight `seasons' `cont' `FEs' `cnd'&young==1, `se'
        eststo: areg birthweight `seasons' `cont' `FEs' `cnd'&young==1, `se' `aa'
        eststo: reg  birthweight `seasons' `cont' `FEs' `cnd'&young==0, `se'
        eststo: areg birthweight `seasons' `cont' `FEs' `cnd'&young==0, `se' `aa'

        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using "$OUT/QualityAllComb`method'.tex",
        replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) collabels(none)
        label stats (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations)) booktabs            
        starlevel ("*" 0.10 "**" 0.05 "***" 0.01) style(tex)
        title("Birth Quality by Age and Season: `syear'")
        keep(_cons young `seasons' `cont')
        mtitles("No Gest" "Gestation" "No Gest" "Gestation" "No Gest" "Gestation")
        mgroups("All" "Young" "Old", pattern(1 0 1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(r){@span}))
        postfoot("\bottomrule"
         "\multicolumn{7}{p{18.8cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers. Bad     "
         "Season (due in bad) is a dummy for children expected and born in     "
         "quarters 1 or 4, while Bad Season (due in good) is a dummy for       "
         "children expected in quarters 2 or 3, but were born prematurely in   "
         "quarters 1 or 4.  For each outcome, the first column is unconditional"
         "on gestation while the second column includes fixed effects for weeks"
         " of gestation.\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }
}

********************************************************************************
*** (X) Clear
********************************************************************************
log close
