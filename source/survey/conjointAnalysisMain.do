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
*--- (0) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint-main"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/conjoint-main"
global NVS "~/investigacion/2015/birthQuarter/data/nvss"
global ACS "~/investigacion/2015/birthQuarter/data/raw"
global GEO "~/investigacion/2015/birthQuarter/data/maps/states_simplified"


log using "$LOG/conjointAnalysisMain.txt", text replace

*-------------------------------------------------------------------------------
*--- (1) Summary Statistics
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup"
append using "$DAT/conjointDOBgroup"
bys ID: gen N=_n
keep if N==1
drop N

keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2
gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"

/*
save "$DAT/combined", replace

gen statename=RespState
count
bys statename: gen stateProportion = _N/r(N)

preserve
collapse stateProportion, by(statename)
rename statename NAME

merge 1:1 NAME using "$GEO/US_db"
format stateProportion %5.2f
#delimit ;
spmap stateProportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord_mercator",
point(data($DAT/combined) xcoord(long3) ycoord(lat3)
      select(drop if (latitude<24.39|latitude>49.38)|(longitude<-124.84|longitude>-66.9))
      size(*0.5) fcolor(red))
id(_ID) osize(thin) legtitle("Proportion of Respondents") legstyle(2) fcolor(Greens)
legend(symy(*1.2) symx(*1.2) size(*1.4) rowgap(1));
graph export "$OUT/surveyCoverage.eps", as(eps) replace;
#delimit cr
restore

preserve
encode RespNumKids, gen(nchild)
replace nchild=nchild-1
keep if nchild > 0
gen N = 1
collapse (sum) N, by(nchild)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthProp
tempfile nchild
save `nchild'

use "$NVS/natl2013", clear

gen N = 1
replace lbo_rec=6 if lbo_rec>=6
collapse (sum) N, by(lbo_rec)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthPropNVS
rename lbo_rec nchild
merge 1:1 nchild using `nchild'

graph bar birthPropNVS birthProp, over(nchild)                          /*
*/ legend(lab(1 "NVSS") lab(2 "MTurk Sample")) scheme(s1mono)           /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4)) ytitle("Proportion")
graph export "$OUT/nchild.eps", as(eps) replace
restore

preserve
gen N = 1
gen cbirthmonth = 1 if RespKidBMonth=="January"
replace cbirthmonth = 2 if RespKidBMonth=="February"
replace cbirthmonth = 3 if RespKidBMonth=="March"
replace cbirthmonth = 4 if RespKidBMonth=="April"
replace cbirthmonth = 5 if RespKidBMonth=="May"
replace cbirthmonth = 6 if RespKidBMonth=="June"
replace cbirthmonth = 7 if RespKidBMonth=="July"
replace cbirthmonth = 8 if RespKidBMonth=="August"
replace cbirthmonth = 9 if RespKidBMonth=="September"
replace cbirthmonth = 10 if RespKidBMonth=="October"
replace cbirthmonth = 11 if RespKidBMonth=="November"
replace cbirthmonth = 12 if RespKidBMonth=="December"
tab cbirthmonth, gen(_month)

gen birthProp = .
gen birthSE   = .
gen Month     = _n
foreach num of numlist 1(1)12 {
    sum _month`num'
    replace birthProp = r(mean) in `num'
    local se = r(sd)/sqrt(r(N))
    replace birthSE = `se'      in `num'
}
keep in 1/12
keep birthProp birthSE Month
gen lower = birthProp-1.96*birthSE
gen upper = birthProp+1.96*birthSE


tempfile bmonth
save `bmonth'


use "$NVS/birthCond", clear

tab birthMonth, gen(_month)

gen birthPropNVSS = .
gen birthSENVSS   = .
gen Month         = _n
foreach num of numlist 1(1)12 {
    sum _month`num'
    replace birthPropNVSS = r(mean) in `num'
    local se = r(sd)/sqrt(r(N))
    replace birthSENVSS = `se'      in `num'
}
keep in 1/12
keep birthPropNVSS birthSENVSS Month
gen lowerN = birthPropNVSS-1.96*birthSENVSS
gen upperN = birthPropNVSS+1.96*birthSENVSS


merge 1:1 Month using `bmonth'
local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProp     Month, `line1'       ||
       rcap lower upper   Month,  lcolor(gs10) ||
       rcap lowerN upperN Month, lcolor(gs10)  ||
       line birthPropNVSS Month, `line2' scheme(s1mono)
xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
       9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec", axis(1)) xtitle("Birth Month")
legend(order(1 "MTurk Survey Sample" 2 "95% CI" 4 "NVSS Birth Data"))
ytitle("Proportion of Births");
graph export "$OUT/birthsMonth.eps", as(eps) replace;
#delimit cr
restore
*/

*-------------------------------------------------------------------------------
*--- (A2) Generate [For Full Group]
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup", clear
append using "$DAT/conjointDOBgroup"
keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2
gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen someCollege = RespEduc!="Eighth Grade or Less"&/*
*/ RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen hispanic = RespHisp=="Yes"

*DOB and BWT replace missings as separate indicator

replace dob        ="missing" if dob        ==""
replace birthweight="missing" if birthweight==""
replace birthweight_p=5 if birthweight_p==.
replace dob_position =5 if dob_position ==.

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)
tab dob        , gen(_dob)

drop _gend1 _cost5 _bwt2 _sob4 _dob1
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



local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1


reg chosen `oFEs' _gend* _cost* _bwt* _sob* _dob* if `base', cluster(ID)


#delimit ;
local conds `base'&(parent==1|planning==1)
            `base'&(parent==1|planning==1)&teacher==1
            `base'&(parent==1|planning==1)&RespSex=="Female"
            `base'&(parent==1|planning==1)&teacher==1&RespSex=="Female"
            all==1
            `base'&parent==1
            `base'&parent==1&teacher==1
            `base'&parent==1&RespSex=="Female"
            `base'&parent==1&teacher==1&RespSex=="Female";
local names Main MainTeacher MainFemale MainTeacherFemale All
       MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent;
#delimit cr
tokenize `names'
lab def names -1 "Gender" -2 "Male" -3 "Female" -4 " " -5 "Cost" -6 "250"   /*
*/ -7 "750" -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" /*
*/ -14 "7500" -15 "10000" -16 " " -17 "Birth Weight" -18 "5lbs, 8oz"        /*
*/ -19 "5lbs, 13oz" -20 "6lbs, 3oz" -21 "6lbs, 8oz" -22 "6lbs, 13oz"        /*
*/ -23 "7lbs, 3oz" -24 "7lbs, 8oz" -25 "7lbs, 13oz" -26 "8lbs, 3oz"         /*
*/ -27 "8lbs, 8oz" -28 "8lbs, 13oz"  -29 " " -30 "Season of Birth"          /*
*/ -31 "Winter" -32 "Spring" -33 "Summer" -34 "Fall" -35 " "                /*
*/ -36 "Day of Birth" -37 "Weekday" -38 "Weekend" -39 ""

local ll=1
foreach c of local conds {
    reg chosen `oFEs' _gend* _cost* _bwt* _sob* _dob* if `c', cluster(ID)
    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5     /*
    */ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 /*
    */ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1 _sob2  /*
    */ _sob3 _sob4 s DAY-OF-BIRTH _dob1 _dob2 s

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==5|`i'==17|`i'==30|`i'==36 {
            dis "`var'"
        }
        else if `i'==4|`i'==16|`i'==29|`i'==35|`i'==39 {
        }
        else if `i'==2|`i'==10|`i'==18|`i'==31|`i'==37 {
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
    twoway rcap  LB UB Y in 1/39, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/35, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7))
    ylabel(-1 -5 -17 -30 -36, valuelabel angle(0))
    ymlabel(-2 -3 -4 -6(-1)-15 -18(-1)-28 -31(-1)-34 -37 -38, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Conjoint-FullGroup_`1'.eps", replace
    macro shift
    drop Est UB LB Y
    
    local ctrl `oFEs' _gend* _bwt* _dob*
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
esttab m1 m2 m3 m4 using "$OUT/conjointWTP-all.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth, and   "
         "gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

lab var spring "Spring";
lab var summer "Summer";

esttab n1 n2 n3 n4 using "$OUT/conjointWTP-all_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m6 m7 m8 m9 using "$OUT/conjointWTP-all-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n6 n7 n8 n9 using "$OUT/conjointWTP-all_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr


estimates clear


local ctrl1 `oFEs' _gend* _bwt* _dob*
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
esttab m1 m2 m3 using "$OUT/conjointWTP-allMain.tex", replace
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
*--- (B2) Generate [For Birth weight Group]
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup", clear
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
            all==1
            `base'&parent==1
            `base'&parent==1&teacher==1
            `base'&parent==1&RespSex=="Female"
            `base'&parent==1&teacher==1&RespSex=="Female";
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All
      MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent;
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
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
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
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m8 m9 m10 m11 using "$OUT/conjointWTP-bwt-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n8 n9 n10 n11 using "$OUT/conjointWTP-bwt_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
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
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear



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
            all==1
            `base'&parent==1
            `base'&parent==1&teacher==1
            `base'&parent==1&RespSex=="Female"
            `base'&parent==1&teacher==1&RespSex=="Female";
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All
      MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent;
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
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
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
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m8 m9 m10 m11 using "$OUT/conjointWTP-dob-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp N, fmt(%5.1f %9.0g) label("Willingness to Pay" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) label collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n8 n9 n10 n11 using "$OUT/conjointWTP-dob_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp wtpSu N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "WTP (summer)" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical) style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent."
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
