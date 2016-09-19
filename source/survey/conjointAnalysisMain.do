/* conjointAnalysisMain.do v0.00 damiancclarke             yyyy-mm-dd:2016-09-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint-main"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/conjoint-main"

log using "$LOG/conjointAnalysisMain.txt", text replace

*-------------------------------------------------------------------------------
*--- (2) Generate
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup"
keep if _mergeMTQT==3

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)


drop _gend1 _cost5 _bwt2 _sob4
rename _cost1 _costx
rename _cost4 _cost1
rename _cost3 _cost4
rename _costx _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _bwt1 _bwt2
rename _bwt4 _bwtx
rename _bwt5 _bwt4
rename _bwt3 _bwt5
rename _bwtx _bwt3
rename _bwt6 _bwtx
rename _bwt7 _bwt6
rename _bwt8 _bwt7
rename _bwtx _bwt8
rename _bwt9 _bwtx
rename _bwt10 _bwt9
rename _bwt11 _bwt10
rename _bwtx _bwt11
rename _sob1 _sob4
gen goodSeason=_sob2==1|_sob3==1
gen     costNumerical = subinstr(cost,"$","",1)
replace costNumerical = subinstr(costNumerical,",","",1)
destring costNumerical, replace
*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4

reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* _sob*, cluster(ID)
reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* goodSeason, cluster(ID)
reg chosen `oFEs' `qFEs' _gend* _bwt* goodSeason costNumerical, cluster(ID)
dis _b[goodSeason]/_b[costNumerical]
reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* _sob*, cluster(ID)



local Nobs = e(N)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local names GENDER Male Female COST 250 750 1000 2000 3000 4000 5000 6000  /*
*/ 7500 10000 BIRTH-WEIGHT 5lbs-8oz 5lbs-13oz 6lbs-3oz 6lbs-8oz 6lbs-13oz  /*
*/ 7lbs-3oz 7lbs-8oz 7lbs-13oz 8lbs-3oz 8lbs-8oz 8lbs-13oz SEASON-OF-BIRTH /*
*/ Winter Spring Summer Fall
tokenize `names'
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 /*
*/ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1 _sob2  /*
*/ _sob3 _sob4 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==17|`i'==30 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==16|`i'==29|`i'==35 {
    }
    else if `i'==2|`i'==10|`i'==18|`i'==31 {
        qui replace Est = 0 in `i'
        qui replace UB  = 0 in `i'
        qui replace LB  = 0 in `i'
    }
    else {
        qui replace Est = _b[`var'] in `i'
        qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
        qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
    }
    local ++i
}
    

replace Y = -Y
lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Birth Weight" -18 "5lbs, 8oz"        /*
*/ -19 "5lbs, 13oz" -20 "6lbs, 3oz" -21 "6lbs, 8oz" -22 "6lbs, 13oz"        /*
*/ -23 "7lbs, 3oz" -24 "7lbs, 8oz" -25 "7lbs, 13oz" -26 "8lbs, 3oz"         /*
*/ -27 "8lbs, 8oz" -28 "8lbs, 13oz"  -29 " " -30 "Season of Birth"          /*
*/ -31 "Winter" -32 "Spring" -33 "Summer" -34 "Fall" -35 " "
lab val Y names

*-------------------------------------------------------------------------------
*--- (4) Graph
*-------------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/35, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/35, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -30, valuelabel angle(0))
ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-28 -31(-1)-34, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-BwtGroup.eps", replace


*-------------------------------------------------------------------------------
*--- (5) good season
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4

reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* goodSeason, cluster(ID)

drop Est UB LB Y
gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 /*
*/ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1        /*
*/ goodSeason s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==17|`i'==30 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==16|`i'==29|`i'==33 {
    }
    else if `i'==2|`i'==10|`i'==18|`i'==31 {
        qui replace Est = 0 in `i'
        qui replace UB  = 0 in `i'
        qui replace LB  = 0 in `i'
    }
    else {
        qui replace Est = _b[`var'] in `i'
        qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
        qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
    }
    local ++i
}
    

replace Y = -Y
lab def names2 -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Birth Weight" -18 "5lbs, 8oz"        /*
*/ -19 "5lbs, 13oz" -20 "6lbs, 3oz" -21 "6lbs, 8oz" -22 "6lbs, 13oz"        /*
*/ -23 "7lbs, 3oz" -24 "7lbs, 8oz" -25 "7lbs, 13oz" -26 "8lbs, 3oz"         /*
*/ -27 "8lbs, 8oz" -28 "8lbs, 13oz"  -29 " " -30 "Season of Birth"          /*
*/ -31 "Bad Season" -32 "Good Season" -33 " "
lab val Y names2

*-------------------------------------------------------------------------------
*--- (4) Graph
*-------------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/33, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/33, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -30, valuelabel angle(0))
ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-28 -31(-1)-32, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-BwtGroup_binary.eps", replace



*-------------------------------------------------------------------------------
*--- (2) Generate
*-------------------------------------------------------------------------------
use "$DAT/conjointDOBgroup", clear
keep if _mergeMTQT==3

tab gender, gen(_gend)
tab cost  , gen(_cost)
tab dob   , gen(_dob)
tab sob   , gen(_sob)

drop _gend1 _cost5 _dob1 _sob4
rename _cost1 _costx
rename _cost4 _cost1
rename _cost3 _cost4
rename _costx _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _sob1 _sob4
gen goodSeason=_sob2==1|_sob3==1

*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.dob_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4

reg chosen `oFEs' `qFEs' _gend* _cost* _dob* _sob*, cluster(ID)

local Nobs = e(N)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local names GENDER Male Female COST 250 750 1000 2000 3000 4000 5000 6000     /*
*/ 7500 10000 SEASON-OF-BIRTH Winter Spring Summer Fall DAY-OF-BIRTH Weekday  /*
*/ Weekend 
tokenize `names'
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 s SEASON-OF-BIRTH _sob1 _sob2 _sob3    /*
*/ _sob4 s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==17|`i'==23 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==16|`i'==22|`i'==26 {
    }
    else if `i'==2|`i'==10|`i'==18|`i'==24 {
        qui replace Est = 0 in `i'
        qui replace UB  = 0 in `i'
        qui replace LB  = 0 in `i'
    }
    else {
        qui replace Est = _b[`var'] in `i'
        qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
        qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
    }
    local ++i
}
    

replace Y = -Y
lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Season of Birth" -18 "Winter"        /*
*/ -19 "Spring" -20 "Summer" -21 "Fall" -22 " " -23 "Day of Birth"          /*
*/ -24 "Weekday" -25 "Weekend" -26 ""
lab val Y names

*-------------------------------------------------------------------------------
*--- (4) Graph
*-------------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/26, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/26, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -23, valuelabel angle(0))
ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-21 -24 -25, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-DobGroup.eps", replace


reg chosen `oFEs' `qFEs' _gend* _cost* _dob* goodSeason, cluster(ID)

drop Est UB LB Y
gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 s SEASON-OF-BIRTH _sob1 goodSeason     /*
*/ s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==17|`i'==21 {
        dis "``i''"
    }
    else if `i'==4|`i'==16|`i'==20|`i'==24 {
    }
    else if `i'==2|`i'==10|`i'==18|`i'==22 {
        qui replace Est = 0 in `i'
        qui replace UB  = 0 in `i'
        qui replace LB  = 0 in `i'
    }
    else {
        qui replace Est = _b[`var'] in `i'
        qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
        qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
    }
    local ++i
}
    

replace Y = -Y
lab def names2 -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000"  /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Season of Birth" -18 "Bad Season"     /*
*/ -19 "Good Season" -20 " " -21 "Day of Birth" -22 "Weekday" -23 "Weekend" -24 ""
lab val Y names2

*-------------------------------------------------------------------------------
*--- (4) Graph
*-------------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/24, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/24, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -21, valuelabel angle(0))
ymlabel(-2 -3 -4 -6(-1)-15 -18 -19 -22 -23, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-DobGroup_binary.eps", replace



exit
*-------------------------------------------------------------------------------
*--- (5) Regressions
*-------------------------------------------------------------------------------
gen bwtValues = 3000 if birthweight=="6 pounds 9 ounces"
replace bwtValues = 3100 if birthweight=="6 pounds 13 ounces"
replace bwtValues = 3200 if birthweight=="7 pounds 0 ounces"
replace bwtValues = 3300 if birthweight=="7 pounds 4 ounces"
replace bwtValues = 3400 if birthweight=="7 pounds 7 ounces"
replace bwtValues = 3500 if birthweight=="7 pounds 11 ounces"
replace bwtValues = 3600 if birthweight=="7 pounds 15 ounces"
replace bwtValues = 3700 if birthweight=="8 pounds 2 ounces"
replace bwtValues = 3800 if birthweight=="8 pounds 6 ounces"
replace bwtValues = 3900 if birthweight=="8 pounds 9 ounces"
gen costValues = subinstr(cost, "$", "", 1)
replace costValues = subinstr(costValues, ",", "", 1)
destring costValues, replace
gen someCollegePlus = educ>3
gen teachXParentGoodSeason = teacher*parent*goodSeason
gen teachXGoodSeason       = teacher*goodSeason
gen parentXGoodSeaon       = parent*goodSeason
gen teachXParent           = teacher*parent
gen ageBirth2              = ageBirth^2
lab var bwtValues  "Birth Weight (grams)"
lab var costValues "Out of Pocket Expenses (USD)"
lab var goodSeason "Good Season"
lab var ageBirth   "Age"
lab var ageBirth2  "Age Squared"
lab var someColl   "Some College +"
lab var hispanic   "Hispanic"
lab var teacher    "Teacher"
lab var parent     "Parent"
lab var teachXParentGoodSeason "Teacher $\times$ Parent $\times$ Good Season"
lab var teachXGoodSeason "Teacher $\times$ Good Season"
lab var parentXGoodSeaon "Parent $\times$ Good Season"
lab var teachXParent "Teacher $\times$ Parent"
lab var chosen       "Chosen $\times 100$"

#delimit ;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) labels(Observations))
             starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label;
#delimit cr
local conts _dob* _gend* i.round

replace chosen=chosen*100
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID) 

local conts `conts' ageBirth ageBirth2 someCollegePlus hispanic teacher parent sex
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID) 

local conts `conts' teachX* parentX
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID)


#delimit ;
esttab est1 est2 est3 using "$OUT/ChoiceRegression.tex",
keep(bwtValues costValues goodSeason ageBirth ageBirth2 someCollegePlus hispanic
     teacher parent sex teachXParentGoodSeason teachXGoodSeason parentXGoodSeaon
     teachXParent) replace `estopt'
title("Conjoint Choice and Chooser Characteristics") booktabs
style(tex) mlabels(, depvar)
postfoot("\bottomrule                            "
         "\multicolumn{4}{p{14cm}}{\begin{footnotesize} Marginal effects are      "
         "reported from a linear regression of chosen multiplied by 100 (so margins are interpreted as percentage point changes in likelihood of selection, with standard errors are clustered   "
         "at the level of the respondent.  All         "
         "columns include round fixed effects, as well as controls for the choice "
         "of gender and day of birth."
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

keep if WTPcheck==2
local conts _dob* _gend* i.round
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID) 

local conts `conts' ageBirth ageBirth2 someCollegePlus hispanic teacher parent sex
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID) 

local conts `conts' teachX* parentX
eststo: reg chosen bwtValues costValues goodSeason `conts', cluster(ID)


#delimit ;
esttab est1 est2 est3 using "$OUT/ChoiceRegressionWTPsure.tex",
keep(bwtValues costValues goodSeason ageBirth ageBirth2 someCollegePlus hispanic
     teacher parent sex teachXParentGoodSeason teachXGoodSeason parentXGoodSeaon
     teachXParent) replace `estopt'
title("Conjoint Choice and Chooser Characteristics (Sure about WTP Only)") booktabs
style(tex) mlabels(, depvar)
postfoot("\bottomrule                            "
         "\multicolumn{4}{p{14cm}}{\begin{footnotesize} Marginal effects are      "
         "reported from a linear regression of chosen multiplied by 100 (so margins are interpreted as percentage point changes in likelihood of selection, with standard errors are clustered   "
         "at the level of the respondent.  All         "
         "columns include round fixed effects, as well as controls for the choice "
         "of gender and day of birth."
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


