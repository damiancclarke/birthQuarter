/* conjointAnalysisMain.do v0.00 damiancclarke             yyyy-mm-dd:2016-09-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

The script below is split into two parts.  The first is for the birthweight grou
p and the second is for the day of birth group.  The two parts are denoted using
B (birthweight) and D (day of birth)
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
*--- (B2) Generate [For Birth weight Group]
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup"
keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2

gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen someCollege = RespEduc!="Eighth Grade or Less"&/*
*/ RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen hispanic = RespHisp=="Yes"

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
replace costNumerical = costNumerical/1000
gen spring = _sob2
gen summer = _sob3
gen all = 1
gen TPG = teacher*parent*goodSeason
gen TP = teacher*parent
gen TG = teacher*goodSeason
gen PG = parent*goodSeason
lab var age "Age"
lab var age2 "Age Squared"
lab var someCollege "Some College +"
lab var hispanic "Hispanic"
lab var teacher "Teacher"
lab var parent  "Parent"
lab var TPG "Teacher $\times$ Parent $\times$ Good Season"
lab var TP "Teacher $\times$ Parent"
lab var TG "Teacher $\times$ Good Season"
lab var PG "Parent $\times$ Good Season"

tab RespTargetMonth if age>=25&age<=45&married==1&(parent==1|planning==1)&white==1
tab RespTargetWhich if age>=25&age<=45&married==1&(parent==1|planning==1)&white==1

tab RespTargetMonth if age>=25&age<=45&married==1&(parent==1|planning==1)&teacher==1&white==1
tab RespTargetWhich if age>=25&age<=45&married==1&(parent==1|planning==1)&teacher==1&white==1

*-------------------------------------------------------------------------------
*--- (B3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

#delimit ;
local conds `base'&(parent==1|planning==1)
            `base'&(parent==1|planning==1)&teacher==1
            `base'&(parent==1|planning==1)&RespSex=="Female"
            `base'&(parent==1|planning==1)&teacher==1&RespSex=="Female"
            `base'&(parent==1|planning==1)&minTemp<=23
            `base'&(parent==1|planning==1)&minTemp>23
            all==1;
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All;
#delimit cr
tokenize `names'
lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Birth Weight" -18 "5lbs, 8oz"        /*
*/ -19 "5lbs, 13oz" -20 "6lbs, 3oz" -21 "6lbs, 8oz" -22 "6lbs, 13oz"        /*
*/ -23 "7lbs, 3oz" -24 "7lbs, 8oz" -25 "7lbs, 13oz" -26 "8lbs, 3oz"         /*
*/ -27 "8lbs, 8oz" -28 "8lbs, 13oz"  -29 " " -30 "Season of Birth"          /*
*/ -31 "Winter" -32 "Spring" -33 "Summer" -34 "Fall" -35 " "

local ll=1
foreach c of local conds {
    reg chosen `oFEs' _gend* _cost* _bwt* _sob* if `c', cluster(ID)
    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
    */ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 /*
    */ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1 _sob2  /*
    */ _sob3 _sob4 s

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==5|`i'==17|`i'==30 {
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
    lab val Y names

    *---------------------------------------------------------------------------
    *--- (B4) Graph
    *---------------------------------------------------------------------------
    #delimit ;
    twoway rcap  LB UB Y in 1/35, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/35, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -30, valuelabel angle(0))
    ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-28 -31(-1)-34, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Conjoint-BwtGroup_`1'.eps", replace
    macro shift
    drop Est UB LB Y
    
    local ctrl `oFEs' _gend* _bwt*
    eststo: logit chosen `ctrl' goodSeason costNumerical if `c', cluster(ID)
    margins, dydx(goodSeason costNumerical) post
    est store m`ll'
    estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

    eststo: logit chosen `ctrl' spring summer _sob4 costNumerical if `c', cluster(ID)
    margins, dydx(spring summer costNumerical) post
    est store n`ll'
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    local ++ll
}

lab var costNumerical "Medical Costs (1000s)"
lab var goodSeason    "Good Season"
#delimit ;
esttab m1 m2 m3 m4 using "$OUT/conjointWTP-bwt.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");

lab var spring "Spring";
lab var summer "Summer";

esttab n1 n2 n3 n4 using "$OUT/conjointWTP-bwt_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local ctrl1 `oFEs' _gend* _bwt*
local ctrl2 age age2 someCollege hispanic teacher parent
local ctrl3 PG TG TP TPG 
local cc if `base'&(parent==1|planning==1)

eststo: logit chosen `ctrl1' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical) post
est store m1
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

eststo: logit chosen `ctrl1' `ctrl2' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical `ctrl2') post
est store m2
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

eststo: logit chosen `ctrl1' `ctrl2' `ctrl3' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical `ctrl2' `ctrl3') post
est store m3
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]
lab var chosen "Preferred"

#delimit ;
esttab m1 m2 m3 using "$OUT/conjointWTP-bwtMain.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels(,depvar) label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical `ctrl2' `ctrl3') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{4}{p{11.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). The     "
         "estimation sample consist of all married 25-45 year-olds (at survey"
         " or time of birth) who are white or hispanic. Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


*-------------------------------------------------------------------------------
*--- (B5) Analysis by good/bad season
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4

reg chosen `oFEs' _gend* _cost* _bwt* goodSeason, cluster(ID)

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
*--- (D2) Generate [Day of birth group]
*-------------------------------------------------------------------------------
use "$DAT/conjointDOBgroup", clear
keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2

gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen white      = RespRace=="White"
gen teacher    = RespOccupation=="Education, Training, Library"
gen childBYear = RespKidBYear if parent==1
gen married    = RespMarital=="Married"
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen someCollege = RespEduc!="Eighth Grade or Less"&/*
*/ RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen hispanic = RespHisp=="Yes"

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
gen     costNumerical = subinstr(cost,"$","",1)
replace costNumerical = subinstr(costNumerical,",","",1)
destring costNumerical, replace
replace costNumerical=costNumerical/1000
gen spring = _sob2
gen summer = _sob3
gen all=1
gen TPG = teacher*parent*goodSeason
gen TP = teacher*parent
gen TG = teacher*goodSeason
gen PG = parent*goodSeason
lab var age "Age"
lab var age2 "Age Squared"
lab var someCollege "Some College +"
lab var hispanic "Hispanic"
lab var teacher "Teacher"
lab var parent  "Parent"
lab var TPG "Teacher $\times$ Parent $\times$ Good Season"
lab var TP "Teacher $\times$ Parent"
lab var TG "Teacher $\times$ Good Season"
lab var PG "Parent $\times$ Good Season"

tab RespTargetMonth if age>=25&age<=45&married==1&(parent==1|planning==1)&white==1
tab RespTargetWhich if age>=25&age<=45&married==1&(parent==1|planning==1)&white==1

tab RespTargetMonth if age>=25&age<=45&married==1&(parent==1|planning==1)&teacher==1&white==1
tab RespTargetWhich if age>=25&age<=45&married==1&(parent==1|planning==1)&teacher==1&white==1
exit

*-------------------------------------------------------------------------------
*--- (D3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.dob_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

#delimit ;
local conds `base'&(parent==1|planning==1)
            `base'&(parent==1|planning==1)&teacher==1
            `base'&(parent==1|planning==1)&RespSex=="Female"
            `base'&(parent==1|planning==1)&teacher==1&RespSex=="Female"
            `base'&(parent==1|planning==1)&minTemp<=23
            `base'&(parent==1|planning==1)&minTemp>23
            all==1;
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All;
#delimit cr
tokenize `names'
lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Season of Birth" -18 "Winter"        /*
*/ -19 "Spring" -20 "Summer" -21 "Fall" -22 " " -23 "Day of Birth"          /*
*/ -24 "Weekday" -25 "Weekend" -26 ""

local ll=1
foreach c of local conds {
    reg chosen `oFEs'  _gend* _cost* _dob* _sob* if `c', cluster(ID)
    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
    */ _cost6 _cost7 _cost8 _cost9 _cost10 s SEASON-OF-BIRTH _sob1 _sob2 _sob3    /*
    */ _sob4 s DAY-OF-BIRTH _dob1 _dob2 s

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==5|`i'==17|`i'==23 {
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
    lab val Y names

    *---------------------------------------------------------------------------
    *--- (D4) Graph
    *---------------------------------------------------------------------------
    #delimit ;
    twoway rcap  LB UB Y in 1/26, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/26, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -5 -17 -23, valuelabel angle(0))
    ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-21 -24 -25, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Conjoint-DobGroup_`1'.eps", replace
    macro shift
    drop Est UB LB Y

    local ctrl `oFEs'  _gend* _dob*
    eststo: logit chosen `ctrl' goodSeason costNumerical if `c', cluster(ID)
    margins, dydx(goodSeason costNumerical) post
    est store m`ll'
    estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

    eststo: logit chosen `ctrl' spring summer _sob4 costNumerical if `c', cluster(ID)
    margins, dydx(spring summer costNumerical) post
    est store n`ll'
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    local ++ll
}

lab var costNumerical "Medical Costs (1000s)"
lab var goodSeason    "Good Season"
#delimit ;
esttab m1 m2 m3 m4 using "$OUT/conjointWTP-dob.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) label collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr

lab var summer "Summer"
lab var spring "Spring"

#delimit ;
esttab n1 n2 n3 n4 using "$OUT/conjointWTP-dob_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

*local c1 `oFEs' 
*local c2 `oFEs' age age2 someCollege hispanic 
*eststo: logit chosen _gend* _dob* goodSeason costNumerical, cluster(ID)

local ctrl1 `oFEs' _gend* _dob*
local ctrl2 age age2 someCollege hispanic teacher parent
local ctrl3 PG TG TP TPG 
local cc if `base'&(parent==1|planning==1)

eststo: logit chosen `ctrl1' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical) post
est store m1
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

eststo: logit chosen `ctrl1' `ctrl2' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical `ctrl2') post
est store m2
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]

eststo: logit chosen `ctrl1' `ctrl2' `ctrl3' goodSeason costNumerical `cc', cluster(ID)
margins, dydx(goodSeason costNumerical `ctrl2' `ctrl3') post
est store m3
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]
lab var chosen "Preferred"

#delimit ;
esttab m1 m2 m3 using "$OUT/conjointWTP-dobMain.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels(,depvar) label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical `ctrl2' `ctrl3') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{4}{p{11.4cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). The     "
         "estimation sample consist of all married 25-45 year-olds (at survey"
         " or time of birth) who are white or hispanic. Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

*-------------------------------------------------------------------------------
*--- (D5) Analysis by good/bad season
*-------------------------------------------------------------------------------
reg chosen `oFEs' `qFEs' _gend* _cost* _dob* goodSeason, cluster(ID)


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


reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* _sob*, cluster(ID)
reg chosen `oFEs' `qFEs' _gend* _cost* _bwt* goodSeason, cluster(ID)


*-------------------------------------------------------------------------------
*--- (6) Regressions [This comes from old script and needs to be updated]
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


