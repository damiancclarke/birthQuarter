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
/*
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

save "$DAT/combined", replace

preserve
gen ageBirth=age
gen race=11 if white==1
gen marst=married
gen sex=RespSex=="Female"
gen hispanic=RespHisp=="Yes"
encode RespNumKids, gen(nchild)
replace nchild=nchild-1
gen cbirthmonth     = 1  if RespKidBMonth=="January"
replace cbirthmonth = 2  if RespKidBMonth=="February"
replace cbirthmonth = 3  if RespKidBMonth=="March"
replace cbirthmonth = 4  if RespKidBMonth=="April"
replace cbirthmonth = 5  if RespKidBMonth=="May"
replace cbirthmonth = 6  if RespKidBMonth=="June"
replace cbirthmonth = 7  if RespKidBMonth=="July"
replace cbirthmonth = 8  if RespKidBMonth=="August"
replace cbirthmonth = 9  if RespKidBMonth=="September"
replace cbirthmonth = 10 if RespKidBMonth=="October"
replace cbirthmonth = 11 if RespKidBMonth=="November"
replace cbirthmonth = 12 if RespKidBMonth=="December"

keep  if ageBirth>=25&ageBirth<=45&race==11&marst==1&sex==1
keep if nchild!=0
gen N = 1
gen Q1 = cbirthmonth >= 1 & cbirthmonth <=3
gen Q2 = cbirthmonth >= 4 & cbirthmonth <=6
gen Q3 = cbirthmonth >= 7 & cbirthmonth <=9
gen Q4 = cbirthmonth >=10 & cbirthmonth <=12
gen highEduc  = RespEduc!="Eighth Grade or Less"/*
*/ &RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen     sexchild = 1 if RespKidGender=="Girl"
replace sexchild = 0 if RespKidGender=="Boy"


collapse (sum) N (mean) nchild sexchild Q1 Q2 Q3 Q4 ageBirth    /*
*/ hispanic highEduc (sd) sd_nchild=nchild sd_sexchild=sexchild /*
*/ sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4                          /*
*/ sd_ageBirth=ageBirth sd_hispanic=hispanic sd_highEduc=highEduc
expand 9
gen mean  = .
gen stdev = .
gen var   = ""

local i = 1
foreach var of varlist nchild sexchild Q1 Q2 Q3 Q4 ageBirth /*
*/ hispanic highEduc {
    replace mean  = `var' in `i'
    replace stdev = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
gen data = "MTurk"
keep mean stdev var data N
tempfile MTurkSum
save `MTurkSum'
restore



preserve
use "$NVS/natl2013", clear
keep if mbrace==1&mar==1
gen N_NV = 1
gen nchild = lbo_rec
replace nchild = 6 if nchild>6&nchild<20
replace nchild = . if nchild>=20
gen sexchild = sex=="F"

gen Q1 = dob_mm >= 1 & dob_mm <=3
gen Q2 = dob_mm >= 4 & dob_mm <=6
gen Q3 = dob_mm >= 7 & dob_mm <=9
gen Q4 = dob_mm >=10 & dob_mm <=12
gen ageBirth = mager
gen highEduc = meduc>=4 if meduc!=9&meduc!=.
gen hispanic = umhisp!=0

collapse (sum) N (mean) nchild sexchild Q1 Q2 Q3 Q4 ageBirth      /*
*/ highEduc hispanic (sd) sd_nchild=nchild sd_sexchild=sexchild   /*
*/ sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4                            /*
*/ sd_ageBirth=ageBirth sd_hispanic=hispanic sd_highEduc=highEduc
expand 9
gen meanNV  = .
gen stdevNV = .
gen var   = ""

local i = 1
foreach var of varlist nchild sexchild Q1 Q2 Q3 Q4 ageBirth /*
*/ hispanic highEduc {
    replace meanNV  = `var' in `i'
    replace stdevNV = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
keep meanNV stdevNV var N_NV
tempfile NVSSSum
save `NVSSSum'

merge 1:1 var using `MTurkSum'
local i = 1
#delimit ;
local vnames `""Number of Children" "Age at First Birth" "Female Child"
               "Hispanic"
               "Some College +" "Born January-March" "Born April-June"
               "Born July-September" "Born October-December" "';
#delimit cr
local variables nchild ageBirth sexchild hispanic highEduc /*
*/ Q1 Q2 Q3 Q4
tokenize `variables'
file open bstats using "$OUT/NVSScomp.txt", write replace
foreach var of local vnames {
    foreach stat in N mean stdev N_NV meanNV stdevNV {
        qui sum `stat' if var=="`1'"
        local val`stat'=r(mean)
    }
    qui ttesti `valN' `valmean' `valstdev' `valN_NV' `valmeanNV' `valstdevNV'
    foreach val in mu_1 sd_1 mu_2 sd_2 t {
        local `val'=string(r(`val'), "%5.3f")
        *local `val'=round(r(`val')*1000)/1000
        *if ``val''<1&``val''>0 local `val' = "0``val''"
    }
    local dif = string((`mu_1'-`mu_2'),"%5.3f")
    *if `dif'<1&`dif'>0 local dif = "0`dif'"
    file write bstats "`var'&`mu_1'&(`sd_1')&`mu_2'&(`sd_2')&`dif'&`t'\\ " _n
    macro shift
}
file close bstats
restore


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
lab var _bwt2  "5lbs, 13oz"
lab var _bwt3  "6lbs, 3oz"
lab var _bwt4  "6lbs, 8oz"
lab var _bwt5  "6lbs, 13oz"
lab var _bwt6  "7lbs, 3oz"
lab var _bwt7  "7lbs, 8oz"
lab var _bwt8  "7lbs, 13oz"
lab var _bwt9  "8lbs, 3oz"
lab var _bwt10 "8lbs, 8oz"
lab var _bwt11 "8lbs, 13oz"
lab var _dob2  "Weekend Day"
lab var _gend2 "Female"

local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n
tab RespTargetMonth if `base'&(parent==1|planning==1)&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&N==1

tab RespTargetMonth if `base'&(parent==1|planning==1)&teacher==1&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&teacher==1&N==1

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
            `base'&parent==1&teacher==1&RespSex=="Female"
            `base'&parent==0
            `base'&parent==0&teacher==1
            `base'&parent==0&RespSex=="Female"
            `base'&parent==0&teacher==1&RespSex=="Female"
            `base'&planning==1
            `base'&planning==1&teacher==1
            `base'&planning==1&RespSex=="Female"
            `base'&planning==1&teacher==1&RespSex=="Female"
            all==1&teacher==1&RespSex=="Female";
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All
        MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent
MainNoParent MainTeacherNoParent MainFemaleNoParent MainTeacherFemaleNoParent
MainPlanning MainTeacherPlanning MainFemalePlanning MainTeacherFemalePlanning
AllTeacherFemale;
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

gen ratio = 1000*goodSeason/costNumerical
local nvar1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
local nvar2 _dob2

local ll=1
foreach c of local conds {
    count if `c'
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
    scatter Y Est in 1/39, mcolor(black) msymbol(oh) mlwidth(thin)
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
    margins, dydx(goodSeason costNumerical _gend2 `nvar1' `nvar2') post
    est store m`ll'
    estadd scalar wtp = 1000*_b[goodSeason]/_b[costNumerical]
    nlcom ratio:_b[goodSeason]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95 "[`lb';`ub']": m`ll'
    
    eststo: logit chosen `ctrl' spring summer _sob4 costNumerical if `c', cluster(ID)
    margins, dydx(spring summer costNumerical  _gend2 `nvar1' `nvar2' _sob4) post
    est store n`ll'
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`lb';`ub']": n`ll'
    est restore n`ll'
    nlcom ratio:_b[summer]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95su "[`lb';`ub']": n`ll'
    local ++ll
}

lab var costNumerical "Medical Costs (1000s)"
lab var goodSeason    "Good Season"
#delimit ;
esttab m1 m2 m3 m4 using "$OUT/conjointWTP-all.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth, and   "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent.  Willingness to pay and its 95\%          "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
lab var spring "Spring";
lab var summer "Summer";

esttab n1 n2 n3 n4 using "$OUT/conjointWTP-all_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m8 m9 m10 m11 using "$OUT/conjointWTP-all-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n8 n9 n10 n11 using "$OUT/conjointWTP-all_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m12 m13 m14 m15 using "$OUT/conjointWTP-all-nonparents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(goodSeason costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n12 n13 n14 n15 using "$OUT/conjointWTP-all_springsummer-nonparents.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(spring summer costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");

dis "PLANNERS";
esttab m16 m17 m18 m19 using "$OUT/conjointWTP-all-planners.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Planning to be Parents Only)")
keep(goodSeason costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n16 n17 n18 n19 using "$OUT/conjointWTP-all_springsummer-planners.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Planning to be Parents Only)")
keep(spring summer costNumerical  _gend2 `nvar1' `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight, day of birth and    "
         "gender). Each respondent sees 14 profiles (7 rounds of 2) and must "
         "choose their preferred option in each round.  Standard errors are  "
         "clustered by respondent. Willingness to pay and its 95\%           "
         "confidence interval is estimated based on the ratio of costs to the"
         "probability of choosing good season.  The 95\% confidence interval "
         "is calculated using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr


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
lab var _bwt2  "5lbs, 13oz"
lab var _bwt3  "6lbs, 3oz"
lab var _bwt4  "6lbs, 8oz"
lab var _bwt5  "6lbs, 13oz"
lab var _bwt6  "7lbs, 3oz"
lab var _bwt7  "7lbs, 8oz"
lab var _bwt8  "7lbs, 13oz"
lab var _bwt9  "8lbs, 3oz"
lab var _bwt10 "8lbs, 8oz"
lab var _bwt11 "8lbs, 13oz"
lab var _gend2 "Female"


*-------------------------------------------------------------------------------
*--- (B3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n
tab RespTargetMonth if `base'&(parent==1|planning==1)&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&N==1

tab RespTargetMonth if `base'&(parent==1|planning==1)&teacher==1&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&teacher==1&N==1

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
            `base'&parent==1&teacher==1&RespSex=="Female"
            `base'&parent==0
            `base'&parent==0&teacher==1
            `base'&parent==0&RespSex=="Female"
            `base'&parent==0&teacher==1&RespSex=="Female"
            `base'&planning==1
            `base'&planning==1&teacher==1
            `base'&planning==1&RespSex=="Female"
            `base'&planning==1&teacher==1&RespSex=="Female"
            all==1;
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All
        MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent
MainNoParent MainTeacherNoParent MainFemaleNoParent MainTeacherFemaleNoParent
MainPlanning MainTeacherPlanning MainFemalePlanning MainTeacherFemalePlanning
AllTeacherFemale;
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
    margins, dydx(goodSeason costNumerical  _gend2 `nvar1') post
    est store o`ll'
    estadd scalar wtp = 1000*_b[goodSeason]/_b[costNumerical]
    nlcom ratio:_b[goodSeason]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95 "[`lb';`ub']": o`ll'

    cap {
        eststo: logit chosen `ctrl' spring summer _sob4 costNumerical if `c', cluster(ID)
        margins, dydx(spring summer costNumerical  _gend2 `nvar1') post
        est store p`ll'
        estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
        estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
        nlcom ratio:_b[spring]/_b[costNumerical], post
        local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
        local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
        estadd local conf95sp "[`lb';`ub']": p`ll'
        est restore p`ll'
        nlcom ratio:_b[summer]/_b[costNumerical], post
        local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
        local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
        estadd local conf95su "[`lb';`ub']": p`ll'
    }
    local ++ll
}

lab var costNumerical "Medical Costs (1000s)"
lab var goodSeason    "Good Season"
#delimit ;
esttab o1 o2 o3 o4 using "$OUT/conjointWTP-bwt.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical  _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio.  "
         "\end{footnotesize}}\end{tabular}\end{table}");

lab var spring "Spring";
lab var summer "Summer";

esttab p1 p2 p3 p4 using "$OUT/conjointWTP-bwt_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical  _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab o8 o9 o10 o11 using "$OUT/conjointWTP-bwt-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab p8 p9 p10 p11 using "$OUT/conjointWTP-bwt_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab o12 o13 o14 o15 using "$OUT/conjointWTP-bwt-nonparents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(goodSeason costNumerical _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab p12 p13 p14 p15 using "$OUT/conjointWTP-bwt_springsummer-nonparents.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(spring summer costNumerical _gend2 `nvar1') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (birth weight and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr


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
lab var _dob2  "Weekend Day"
lab var _gend2 "Female"


*-------------------------------------------------------------------------------
*--- (D3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.dob_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n
tab RespTargetMonth if `base'&(parent==1|planning==1)&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&N==1

tab RespTargetMonth if `base'&(parent==1|planning==1)&teacher==1&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&teacher==1&N==1

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
            `base'&parent==1&teacher==1&RespSex=="Female"
            `base'&parent==0
            `base'&parent==0&teacher==1
            `base'&parent==0&RespSex=="Female"
            `base'&parent==0&teacher==1&RespSex=="Female"
            `base'&planning==1
            `base'&planning==1&teacher==1
            `base'&planning==1&RespSex=="Female"
            `base'&planning==1&teacher==1&RespSex=="Female"
            all==1&teacher==1&RespSex=="Female";
local names Main MainTeacher MainFemale MainTeacherFemale cold warm All
        MainParent MainTeacherParent MainFemaleParent MainTeacherFemaleParent
MainNoParent MainTeacherNoParent MainFemaleNoParent MainTeacherFemaleNoParent
MainPlanning MainTeacherPlanning MainFemalePlanning MainTeacherFemalePlanning
AllTeacherFemale;
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
    margins, dydx(goodSeason costNumerical _gend2 `nvar2') post
    est store q`ll'
    estadd scalar wtp = 1000*_b[goodSeason]/_b[costNumerical]
    nlcom ratio:_b[goodSeason]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95 "[`lb';`ub']": q`ll'

    eststo: logit chosen `ctrl' spring summer _sob4 costNumerical if `c', cluster(ID)
    margins, dydx(spring summer costNumerical _gend2 `nvar2') post
    est store r`ll'
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`lb';`ub']": r`ll'
    est restore r`ll'
    nlcom ratio:_b[summer]/_b[costNumerical], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95su "[`lb';`ub']": r`ll'
    local ++ll
}

lab var costNumerical "Medical Costs (1000s)"
lab var goodSeason    "Good Season"
#delimit ;
esttab q1 q2 q3 q4 using "$OUT/conjointWTP-dob.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) label collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
title("Conjoint Analysis Regressions")
keep(goodSeason costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr

lab var summer "Summer"
lab var spring "Spring"

#delimit ;
esttab r1 r2 r3 r4 using "$OUT/conjointWTP-dob_springsummer.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions")
keep(spring summer costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab q8 q9 q10 q11 using "$OUT/conjointWTP-dob-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) label collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
title("Conjoint Analysis Regressions (Parents Only)")
keep(goodSeason costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab r8 r9 r10 r11 using "$OUT/conjointWTP-dob_springsummer-parents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Parents Only)")
keep(spring summer costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab q12 q13 q14 q15 using "$OUT/conjointWTP-dob-nonparents.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) label collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(goodSeason costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab r12 r13 r14 r15 using "$OUT/conjointWTP-dob_springsummer-nonparents.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Main Sample" "Teachers Only" "Women Only" "Women Teachers")
label title("Conjoint Analysis Regressions (Non-Parents Only)")
keep(spring summer costNumerical _gend2 `nvar2') style(tex) booktabs
postfoot("\bottomrule           "
         "\multicolumn{5}{p{16.2cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

#delimit cr


*-------------------------------------------------------------------------------
*--- (5) Export tables
*-------------------------------------------------------------------------------
lab var _sob4 "Fall"

#delimit ;
esttab n7 p7 r7 using "$OUT/conjointWTP-seasons.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Full Sample" "Birth Weight Sample" "Day of Birth Sample")
label title("Birth Characteristics and Willingness to Pay") booktabs
keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex) 
postfoot("\bottomrule           "
         "\multicolumn{4}{p{13.6cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab n20 p20 r20 using "$OUT/conjointWTP-teachers-seasons.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp wtpSu conf95su N, fmt(%5.1f %5.1f %9.0g)
 label("WTP (spring)" "95\% CI" "WTP (summer)" "95\% CI" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Full Sample" "Birth Weight Sample" "Day of Birth Sample")
label title("Birth Characteristics and Willingness to Pay
(Women in Education, Library and Training Occupations)") booktabs
keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex) 
postfoot("\bottomrule           "
         "\multicolumn{4}{p{13.6cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m7 o7 q7 using "$OUT/conjointWTP.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Full Sample" "Birth Weight Sample" "Day of Birth Sample")
label title("Birth Characteristics and Willingness to Pay") booktabs
keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex) 
postfoot("\bottomrule           "
         "\multicolumn{4}{p{13.6cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");

esttab m20 o20 q20 using "$OUT/conjointWTP-teachers.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %9.0g)
 label("Willingness to Pay" "95\% CI WTP" Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(,none)
mlabels("Full Sample" "Birth Weight Sample" "Day of Birth Sample")
label title("Birth Characteristics and Willingness to Pay
(Women in Education, Library and Training Occupations)") booktabs
keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex) 
postfoot("\bottomrule           "
         "\multicolumn{4}{p{13.6cm}}{\begin{footnotesize} Average marginal   "
         "from a logit regression are displayed. All columns include         "
         "option order fixed effects, round fixed effects and controls for   "
         "all alternative characteristics (day of birth and gender). Each    "
         "respondent sees 14 profiles (7 rounds of 2) and must choose their  "
         "preferred option in each round.  Standard errors are clustered by  "
         "respondent. Willingness to pay and its 95\% confidence interval is "
         "estimated based on the ratio of costs to the probability of        "
         "choosing good season.  The 95\% confidence interval is calculated  "
         "using thet delta method for the (non-linear) ratio."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr




