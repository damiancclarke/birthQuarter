/* conjointAnalysis.do v0.00     damiancclarke             yyyy-mm-dd:2016-09-06
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/conjoint"

log using "$LOG/conjointAnalysis.txt", text replace

*-------------------------------------------------------------------------------
*--- (2) Generate
*-------------------------------------------------------------------------------
use "$DAT/conjointBase"
keep if _mergeR1R2==3
gen yrDif = abs(birthyr-respYOB)
gen inconsistent     = sex==1&respGender=="Male"|sex==0&respGender=="Female"
replace inconsistent = 1 if yrDif>1
drop if inconsistent==1

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)
tab dob        , gen(_dob)

drop _gend1 _cost5 _bwt2 _sob5 _dob1
rename _cost1 _costx
rename _cost4 _cost1
rename _cost3 _cost4
rename _costx _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _bwt1 _bwt2
rename _bwt4 _bwtx
rename _bwt6 _bwt4
rename _bwtx _bwt6
rename _bwt5 _bwtx
rename _bwt7 _bwt5
rename _bwtx _bwt7
rename _sob9 _sob5
rename _sob12 _sob9
rename _sob3 _sob12
rename _sob8 _sob3
rename _sob2 _sob8
rename _sob4 _sob2
rename _sob1 _sob4
rename _sob6 _sobx
rename _sob7 _sob6
rename _sobx _sob7
rename _sob10 _sobx
rename _sob11 _sob10
rename _sobx _sob11

gen Q2 = sob=="April"  |sob=="May"     |sob=="June"
gen Q3 = sob=="July"   |sob=="August"  |sob=="September"
gen Q4 = sob=="October"|sob=="November"|sob=="December"
gen goodSeason=Q2==1|Q3==1
*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p i.dob_p
local eFEs i.n1 i.n2 i.n3 i.n4 i.n5
order _sob2 _sob3 _sob4 _sob5 _sob6 _sob7 _sob8 _sob9 _sob10 _sob11 _sob12

gen All        = 1
gen parent     = childFlag==1
gen parentWant = parent==1|plankids==1
gen teacher    = occ==6
    
local conds All==1 parent==1 parentWant==1 All==1&WTPcheck==2               /*
*/ parent==1&WTPcheck==2 parentWant==1&WTPcheck==2 teacher==1               /*
*/ teacher==1&parent==1 teacher==1&parentWant==1 teacher==1&WTPcheck==2     /*
*/ teacher==1&parent==1&WTPcheck==2 teacher==1&parentWant==1&WTPcheck==2    /*
*/ minTemp<15 minTemp>=15 minTemp<32 minTemp>=32 minTemp<23 minTemp>=23


local jj = 1
foreach cond of local conds {
    preserve
    keep if `cond'
    reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* _sob* _dob*, cluster(ID)

    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local names GENDER Male Female COST 250 750 1000 2000 3000 4000 5000 6000 7500 /*
    */ 10000 BIRTH-WEIGHT 6lbs-9oz 6lbs-13oz 7lbs-0oz 7lbs-4oz 7lbs-7oz 7lbs-11oz   /*
    */ 7lbs-15oz 8lbs-2oz 8lbs-6oz 8lbs-9oz SEASON-OF-BIRTH Jan Feb Mar Apr May June/*
    */ July Aug Sep Oct Nov Dec DAY-OF-BIRTH Weekday Weekend
    tokenize `names'
    local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5       /*
    */ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4   /*
    */ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 s SEASON-OF_BIRTH _sob1 _sob2 _sob3     /*
    */ _sob4 _sob5 _sob6 _sob7 _sob8 _sob9 _sob10 _sob11 _sob12 s DAY-OF-BIRTH      /*
    */  _dob1 _dob2 s

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==5|`i'==17|`i'==29|`i'==43 {
            dis "``i''"
            dis "`var'"
        }
        else if `i'==4|`i'==16|`i'==28|`i'==42|`i'==46 {
        }
        else if `i'==2|`i'==10|`i'==18|`i'==30|`i'==44 {
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
    lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250" -7 "750"  /*
    */ -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" -14 "7500"       /*
    */ -15 "10000" -16 " " -17 "Birth Weight" -18 "6lbs, 9oz" -19 "6lbs, 13oz"          /*
    */ -20 "7lbs, 0oz" -21 "7lbs, 4oz" -22 "7lbs, 7oz" -23 "7lbs, 11oz" -24 "7lbs, 15oz"/*
    */ -25 "8lbs, 2oz" -26 "8lbs, 6oz" -27 "8lbs, 9oz" -28 " " -29 "Month of Birth"     /*
    */ -30 "Jan" -31 "Feb" -32 "Mar" -33 "Apr" -34 "May" -35 "June" -36 "Jul" -37 "Aug" /*
    */ -38 "Sep" -39 "Oct" -40 "Nov" -41 "Dec" -42 " " -43 "Day of Birth" -44 "Weekday" /*
    */ -45 "Weekend" -46 " "
    lab val Y names

    *-------------------------------------------------------------------------------
    *--- (4) Graph
    *-------------------------------------------------------------------------------
    #delimit ;
    twoway rcap  LB UB Y in 1/46, horizontal scheme(s1mono) lcolor(black) ||
           scatter Y Est in 1/46, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -29 -43, valuelabel angle(0))
    ymlabel(-2 -3 -4 -6(-1)-16 -18(-1)-28 -30(-1)-42 -44 -45, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/conjoint_c`jj'.eps", replace
    local ++jj
    restore
}

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


