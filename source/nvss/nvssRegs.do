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

local qual apgar birthweight gestation lbw premature twin vlbw  
local data nvss2005_2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local yFE   i.year
local se    robust

********************************************************************************
*** (2a) Open data, setup for regressions
********************************************************************************
use "$DAT/`data'"

gen birth = 1
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen badQuarter = birthQuarter == 4  | birthQuarter == 1
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


********************************************************************************
*** (2b) Label for clarity
********************************************************************************
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
lab var smoker             "Smoker"


********************************************************************************
*** (3a) Examine missing covariates
********************************************************************************
gen smokeMissing = smoker    == .
gen educMissing  = educLevel == .

reg goodQuarter young married educMissing smokeMissing `yFE', `se'

gen propMissing = .
gen yearMissing = .
foreach y of numlist 2005(1)2013 {
    tab educLevel, m if year==`y'

    replace propMissing = r()
    replace yearMissing = `y'
}
#delimit;
twoway bar propMissing yearMissing in 1/9, scheme(s1mono) xtitle("Data Year")
ytitle("Proportion Missing Education") 
note("Missing education measures occurr in states which use pre-2003 format.")
graph export "$OUT/missingEduc.eps", as(eps) replace
#delimit cr
exit
********************************************************************************
*** (4a) Regressions (goodQuarter on Age)
********************************************************************************
eststo: reg goodQuarter young                            , `se'
eststo: reg goodQuarter young                       `yFE', `se'
eststo: reg goodQuarter young highEd                `yFE', `se'
eststo: reg goodQuarter young highEd married smoker `yFE', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinary.tex",
replace `estopt' title("Birth Season and Age (NVSS 2005-2013)")
keep(_cons young highEd married smoker) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{14cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: reg goodQuarter young                            , `se'
eststo: reg goodQuarter young                       `yFE', `se'
eststo: reg goodQuarter young vhighEd               `yFE', `se'
eststo: reg goodQuarter young vhighEd married smoker `yFE', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryHigh.tex",
replace `estopt' title("Birth Season and Age (NVSS 2005-2013)")
keep(_cons young vhighEd married smoker) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{14cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if twin==2
eststo: reg goodQuarter young                             `cond', `se'
eststo: reg goodQuarter young                       `yFE' `cond', `se'
eststo: reg goodQuarter young highEd                `yFE' `cond', `se'
eststo: reg goodQuarter young highEd married smoker `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSBinaryTwin.tex",
replace `estopt' title("Birth Season and Age (Twins Only)")
keep(_cons young highEd married smoker) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{5}{p{14cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


foreach m of numlist 0 1 {
    foreach g in smk mar {
        if `"`g'"'=="smk" {
            local cond if smoker==`m'
            if `m'==1 local Title "smoking"
            if `m'==0 local Title "non-smoking"
        }
        if `"`g'"'=="mar" {
            local cond if married==`m'
            if `m'==0 local Title "unmarried"
            if `m'==1 local Title "married"
        }
        eststo: reg goodQuarter young              `cond', `se'
        eststo: reg goodQuarter young        `yFE' `cond', `se'
        eststo: reg goodQuarter young highEd `yFE' `cond', `se'
    
        #delimit ;
        esttab est1 est2 est3 using "$OUT/NVSSBinary`Title'.tex",
        replace `estopt' title("Birth Season and Age (NVSS: `Title' women)")
        keep(_cons young highEd) style(tex) booktabs mlabels(, depvar)
        postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{12.5cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic, `Title' mothers."
         "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }
}

local cond if single==1
eststo: reg goodQuarter young              `cond', `se'
eststo: reg goodQuarter young        `yFE' `cond', `se'
eststo: reg goodQuarter young highEd `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 using "$OUT/NVSSBinarySingle.tex",
replace `estopt' title("Birth Season and Age: Single Women (NVSS 2005-2013)")
keep(_cons young highEd) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{12.5cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic single mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if fatherAge!=11
eststo: reg goodQuarter young youngMan                           `cond', `se'
eststo: reg goodQuarter young youngMan                     `yFE' `cond', `se'
eststo: reg goodQuarter young youngMan highEd              `yFE' `cond', `se'

#delimit ;
esttab est1 est2 est3 using "$OUT/NVSSBinaryM.tex",
replace `estopt' title("Birth Season and Age M/F (NVSS 2005-2013)")
keep(_cons young* highEd) style(tex) booktabs mlabels(, depvar)
postfoot("Year FE&&Y&Y&Y\\ \bottomrule"
         "\multicolumn{4}{p{12.5cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers with male"
         "partners. \end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (4b) Regressions (Quality on Age, season)
********************************************************************************
foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter `yFE', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQuality.tex",
replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

local cond if fatherAge!=11
foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter youngMan `yFE' `cond', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQualityM.tex",
replace `estopt' title("Birth Quality by Age and Season M/F (NVSS 2005-2013)")
keep(_cons young* badQuarter) style(tex) booktabs mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers with male"
         "partners. \end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


foreach e in 0 1 {
    if `e'==0 local educN "with no college education"
    if `e'==1 local educN "with college education"
    
    foreach y of varlist `qual' {
        eststo: reg `y' young badQuarter `yFE' if highEd==`e', `se'
    }
    #delimit ;
    esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQuality`e'.tex",
    replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
    keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
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
        eststo: reg `y' young badQuarter `yFE' if smoker==`s', `se'
    }
    #delimit ;
    esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQualitySmoke`s'.tex",
    replace `estopt' title("Birth Quality by Age and Season (Mothers `smokeN')")
    keep(_cons young badQuarter) style(tex) booktabs mlabels(, depvar)
    postfoot("\bottomrule"
             "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
             "first born children of US-born, white, non-hispanic mothers `smokeN'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
}
estimates clear


foreach y of varlist `qual' {
    eststo: reg `y' young badQuarter highEd married smoker `yFE', `se'
}
#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 using "$OUT/NVSSQualityEduc.tex",
replace `estopt' title("Birth Quality by Age and Season (NVSS 2005-2013)")
keep(_cons young badQuarter highEd married smoker) style(tex) mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{8}{p{15cm}}{\begin{footnotesize}Sample consists of all"
         "first born children of US-born, white, non-hispanic mothers"
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
#delimit cr
estimates clear

********************************************************************************
*** (X) Clear
********************************************************************************
log close
