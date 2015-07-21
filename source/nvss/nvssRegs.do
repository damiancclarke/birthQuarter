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

log using "$LOG/nvssRegs2.txt", text replace
cap mkdir "$OUT"

local qual birthweight lbw vlbw gestation premature apgar 
local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats      /*
*/           (N, fmt(%9.0g) label(Observations))                             /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local yFE    i.year
local se     robust
local cnd    if twin==1
local keepif birthOrder==1 & motherAge>24
/*
********************************************************************************
*** (1b) Define run type
********************************************************************************
local orign  1
local a2024  0
local y1213  0
local bord2  0
local over30 0
local fterm  0
local pre4w  0
local frace  0

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
    local keepif birthOrder==1 & motherAge>24 & (year==2012|year==2013)
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
if `a2024' ==1 replace ageGroup = 1 if ageGroup == 0
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

sum expectGoodQ expectBadQ
sum Qgoodgood Qgoodbad Qbadgood Qbadbad



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
*** (4) Good Quarter Regressions
********************************************************************************
gen young2 = motherAge<35
lab var young2 "Aged 25-34"

********************************************************************************
*** (4a) Different sets of explanatory variables
********************************************************************************
local add `" "" "(Young=25-34)" "(Education Interaction)" "(Complete College)" "'
local nam Main Young34 EdInteract High
tokenize `nam'

foreach type of local add {

    local age young
    local edu highEd
    local con married smoker
    if `"`1'"' == "Young34"    local age young2
    if `"`1'"' == "EdInteract" local edu highEd youngXhighEd
    if `"`1'"' == "High"       local edu vhighEd 

    eststo: reg goodQuarter `age'                   `cnd', `se'
    eststo: reg goodQuarter `age'             `yFE' `cnd', `se'
    eststo: reg goodQuarter `age' `edu'       `yFE' `cnd', `se'
    eststo: reg goodQuarter `age' `edu' `con' `yFE' `cnd', `se'

    #delimit ;
    esttab est1 est2 est3 est4 using "$OUT/NVSSBinary`1'.tex",
    replace `estopt' title("Birth Season and Age `type'") booktabs 
    keep(_cons `age' `edu' `con') style(tex) mlabels(, depvar)
    postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
             "\multicolumn{5}{p{12cm}}{\begin{footnotesize}Sample consists "
             "of all first born children of US-born, white, non-hispanic   "
             "mothers. \end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
    macro shift
}


********************************************************************************
*** (4b) Conditions
********************************************************************************
local c1 twin==2 smoker==0&twin==1 smoker==1&twin==1 year>=2012&twin==1  /*
      */ infertTreat==0&twin==1 infertTreat==1&twin==1 twin==1 married==0&twin==1
local names Twin non-smoking smoking 2012-2013 non-ART ART Main unmarried
tokenize `names'

foreach cond of local c1 {
    dis "`1'"
    local cn 5
    local sp "&&Y&Y&Y"
    
    eststo: reg goodQuarter young                              if `cond', `se'
    eststo: reg goodQuarter young                        `yFE' if `cond', `se'
    eststo: reg goodQuarter young highEd                 `yFE' if `cond', `se'
    eststo: reg goodQuarter young highEd married smoker  `yFE' if `cond', `se'
    
    local ests est1 est2 est3 est4 
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"

    local vars _cons young highEd married smoker
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local ests est1 est2 est3 
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local vars _cons young highEd    
    if `"`1'"'=="unmarried"                      local vars _cons young highEd
    
    #delimit ;
    esttab `ests' using "$OUT/NVSSBinary`1'.tex", replace `estopt' booktabs 
    title("Birth Season and Age (`1' sample)") keep(`vars') mlabels(, depvar)
    postfoot("Year FE`sp'\\ \bottomrule"
             "\multicolumn{`cn'}{p{12cm}}{\begin{footnotesize}Sample consists "
             " of all first births to US-born, white, non-hispanic mothers.   "
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
}

********************************************************************************
*** (4b-i) Conditions (age continuous)
********************************************************************************
tokenize `names'
foreach cond of local c1 {
    dis "`1'"
    local cn 5
    local sp "&&Y&Y&Y"
    
    eststo: reg goodQuarter motherAge                             if `cond', `se'
    eststo: reg goodQuarter motherAge                       `yFE' if `cond', `se'
    eststo: reg goodQuarter motherAge highEd                `yFE' if `cond', `se'
    eststo: reg goodQuarter motherAge highEd married smoker `yFE' if `cond', `se'

    local ests est1 est2 est3 est4 
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"
    local vars _cons motherAge highEd married smoker
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
}

********************************************************************************
*** (4b-ii) Conditions (age and age sq)
********************************************************************************
tokenize `names'
foreach cond of local c1 {
    dis "`1'"
    local cn 5
    local sp "&&Y&Y&Y"
    
    eststo: reg goodQuarter motherAge*                             if `cond', `se'
    eststo: reg goodQuarter motherAge*                       `yFE' if `cond', `se'
    eststo: reg goodQuarter motherAge* highEd                `yFE' if `cond', `se'
    eststo: reg goodQuarter motherAge* highEd married smoker `yFE' if `cond', `se'

    local ests est1 est2 est3 est4 
    if `"`1'"' == "unmarried"     local ests est1 est2 est3
    if `"`1'"' == "unmarried"     local cn 4
    if `"`1'"' == "unmarried"     local sp "&&Y&Y"
    local vars _cons motherAge motherAge2 highEd married smoker
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking" local ests est1 est2 est3 
    if `"`1'"'=="non-smoking"|`"`1'"'=="smoking"|`"`1'"'=="unmarried" /*
    */ local vars _cons motherAge motherAge2 highEd    
    
    #delimit ;
    esttab `ests' using "$OUT/NVSSBinary`1'_A2.tex", replace `estopt' booktabs 
    title("Birth Season and Age (`1' sample)") keep(`vars') mlabels(, depvar)
    postfoot("Year FE`sp'\\ \bottomrule"
             "\multicolumn{`cn'}{p{12.8cm}}{\begin{footnotesize}Sample consists"
             " of all first births to US-born, white, non-hispanic mothers.    "
             "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
    #delimit cr
    estimates clear
    macro shift
}

/*
********************************************************************************
*** (4c) Multinomial logit for expected/realised
********************************************************************************
gen     seasonType = 1 if Qgoodgood  == 1
replace seasonType = 2 if Qgoodbad   == 1
replace seasonType = 3 if Qbadgood   == 1
replace seasonType = 4 if Qbadbad    == 1
replace seasonType = . if seasonType == 0
local cnew `cnd'&seasonType>1
lab var smoker "Smoked during pregnancy"

mlogit seasonType young highEd married smoker `yFE' `cnd', vce(robust)
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
*/

********************************************************************************
*** (5) Regressions (Quality on Age, season)
********************************************************************************
local c1    twin==1 smoker==0&twin==1 smoker==1&twin==1 year>=2012&twin==1    /*
*/ infertTreat==0&twin==1 infertTreat==1&twin==1 twin==2 married==0&twin==1
local varsY   young badQuarter highEd married smoker
local varsA   motherAge badQuarter highEd married smoker
local varsA2  motherAge motherAge2 badQuarter highEd married smoker
local names   Main non-smoking smoking 2012-2013 non-ART ART Twin unmarried
tokenize `names'


foreach cond of local c1 {
    dis "`1'"

    foreach ageType in Y A A2 {
        local nT "_`ageType'"
        if `"`ageType'"'=="Y" local nT

        
        foreach y of varlist `qual' {
            eststo: reg `y' `vars`ageType'' `yFE' if `cond', `se'
        }

        local Ovars _cons `vars`ageType''
        if `"`1'"'=="non-smoking"|`"`1'"'=="smoking"|`"`1'"'=="unmarried" {
            if `"`ageType'"'=="Y"  local Ovars _cons young badQuarter highEd
            if `"`ageType'"'=="A"  local Ovars _cons motherAge badQuarter highEd
            if `"`ageType'"'=="A2" local Ovars _cons motherAge motherAge2 /*
            */ badQuarter highEd
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
}
exit
********************************************************************************
*** (5a) Redefine bad season as bad season due to short gest, and bad season
********************************************************************************
local cont highEd married smoker
local seasons Qgoodbad Qbadgood Qbadbad
local aa abs(gestation)
    
eststo: reg  birthweight young `seasons' `cont' `yFE' `cnd', `se'
eststo: areg birthweight young `seasons' `cont' `yFE' `cnd', `se'    `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' `cnd'&young==1, `se'
eststo: areg birthweight `seasons' `cont' `yFE' `cnd'&young==1, `se' `aa'
eststo: reg  birthweight `seasons' `cont' `yFE' `cnd'&young==0, `se'
eststo: areg birthweight `seasons' `cont' `yFE' `cnd'&young==0, `se' `aa'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/QualityAllComb.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) collabels(none) label
stats (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations)) booktabs            
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) style(tex)
title("Birth Quality by Age and Season") keep(_cons young `seasons' `cont')  
mtitles("No Gest" "Gestation" "No Gest" "Gestation" "No Gest" "Gestation")
mgroups("All" "Young" "Old", pattern(1 0 1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(r){@span}))
postfoot("\bottomrule"
         "\multicolumn{7}{p{20.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers. Bad     "
         "Season (due in bad) is a dummy for children expected and born in     "
         "quarters 1 or 4, while Bad Season (due in good) is a dummy for       "
         "children expected in quarters 2 or 3, but were born prematurely in   "
         "quarters 1 or 4.  For each outcome, the first column is unconditional"
         "on gestation while the second column includes fixed effects for weeks"
         " of gestation.\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


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
    replace `estopt' title("Birth Season and Age: `syear'") booktabs 
    keep(_cons young highEd married) style(tex) mlabels(, depvar)
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
    /*
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
    gen badQuarterCold = badQuarterWeather*cold
    lab var badQuarterWeather "Bad Season (weather)"
    lab var coldState_20      "Cold State"               
    lab var badQuarterCold    "Bad Season$\times$ Cold"
    
    local wvar badQuarterWeather coldState_20 badQuarterCold
    local cvar highEd married smoker 
    local FE2  i.year i.statecode


    foreach y of varlist `qual' {
        eststo: reg `y' young badQuarterWeather `cvar' `FE2' `cnd', `se'
        eststo: reg `y' young `wvar'            `cvar' `FE2' `cnd', `se'
    }

    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/NVSSQualityWeather.tex",
    replace `estopt' keep(_cons badQuarterWeather `cvar') style(tex)
    mlabels(, depvar) booktabs
    title("Birth Quality by Age and Season (Weather to define badQuarter)")    
    postfoot("\bottomrule"
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists "
             "of all first born children of US-born, white, non-hispanic   "
             "mothers. Warm or cold states are defined as a minimum yearly "
             "temperature of above or below 20 degrees Fahrenheit.         "
             "\end{footnotesize}}\end{tabular}\end{table}");

    esttab est2 est4 est6 est8 est10 est12 using "$OUT/NVSSQualityWInterac.tex",
    replace `estopt' keep(_cons `wvar' `cvar') style(tex)
    mlabels(, depvar) booktabs
    title("Birth Quality by Age and Season (Weather Interactions)")    
    postfoot("\bottomrule"
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists "
             "of all first born children of US-born, white, non-hispanic   "
             "mothers. Warm or cold states are defined as a minimum yearly "
             "temperature of above or below 20 degrees Fahrenheit.         "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    gen statetype = "Cold" if coldstate==1
    replace statetype = "Warm" if coldstate==0|statenat=="12"
    foreach ww in Warm Cold {
        local cond `cnd'&statetype=="`ww'"
        foreach y of varlist `qual' {
            eststo: reg `y' young badQuarterWeather `cvar' `FE2' if `cond', `se'
        }
        #delimit ;
        esttab est1 est2 est3 est4 est5 est6 using "$OUT/NVSSQuality`ww'.tex",
        replace `estopt' keep(_cons badQuarterWeather `cvar') style(tex)
        mlabels(, depvar) booktabs
        title("Birth Quality by Age and Season (`ww' states only)")    
        postfoot("\bottomrule"
                 "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Sample consists "
                 "of all first born children of US-born, white, non-hispanic   "
                 "mothers.  Warm or cold states are defined as a minimum yearly"
                 " temperature of above or below 20 degrees Fahrenheit.        "
                 "\end{footnotesize}}\end{tabular}\end{table}")
        #delimit cr
        estimates clear
    }

    exit
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
         "\multicolumn{7}{p{20.2cm}}{\begin{footnotesize}Sample consists of all"
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
