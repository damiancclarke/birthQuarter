/* nvssTrends.do v0.00           damiancclarke             yyyy-mm-dd:2015-03-10 
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes formatted NVSS (birth certificate) data, and plots trends of fi-
rst births by age groups and quarters.  One group of graphs plots trends by age
groups over time (1 per age group), while the other plots averages for each age
group over the entire time period (1975-2002).

The file can be controlled in section 1, where globals and locals are set based
on the location of files on each machine.

contact: damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close

local allobs 0

********************************************************************************
*** (1) Globals and locals
********************************************************************************
if `allobs'==0 local f nvss
if `allobs'==1 local f nvssall
local mc
if `allobs'==1 local mc married

global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global OUT "~/investigacion/2015/birthQuarter/results/`f'/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/`f'/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global RAW "~/database/NVSS/Births/dta"

log using "$LOG/nvssTrends.txt", text replace
cap mkdir "$SUM"
cap mkdir "$OUT"

local data    nvss2005_2013
local keepif  birthOrder == 1 & motherAge > 24 & motherAge<=45
local twins   0
if `twins' == 1 local app twins


********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if birthOrder==1
/*
preserve
if `allobs'==0 keep if married==1
#delimit ;
if `allobs'==0 local nlab 0 "0" 100000 "100,000" 200000 "200,000"
                                300000 "300,000" 400000 "400,000";
if `allobs'==1 local nlab 0 "0" 100000 "100,000" 200000 "200,000" 300000
                               "300,000" 400000 "400,000" 500000 "500,000";
twoway hist motherAge if motherAge>24&motherAge<=45, freq color(gs0) width(1) ||
       hist motherAge if motherAge<=24|motherAge>45, freq color(gs12) width(1)
    ylabel(`nlab', angle(0)) xtitle("Mother's Age") 
    legend(label(1 "Estimation Sample") label(2 "<25 or >45")) scheme(s1mono);
                                        #delimit cr
graph export "$OUT/ageDescriptive.eps", as(eps) replace
restore
*/
keep if twin<3
/*
preserve
keep if `keepif'
if `allobs'==0 keep if married==1
collapse ART, by(motherAge)
#delimit ;
twoway line ART motherAge, xtitle("Mother's Age") scheme(s1mono)
ytitle("Assisted Reproductive Technology");
#delimit cr
graph export "$OUT/ART.eps", as(eps) replace
restore

preserve
if `allobs'==0 keep if married==1
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46
keep if motherAge>=20&motherAge<=45
collapse ART, by(ageG2)
lab def       aG2 1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45"
lab val ageG2 aG2
#delimit ;
graph bar ART, over(ageG2)  ylabel(, nogrid) exclude0
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("Proportion ART");
graph export "$OUT/ARTageGroup.eps", as(eps) replace;
#delimit cr
restore
*/
********************************************************************************
*** (2aii) Summary stats table
********************************************************************************
replace twin       = twin - 1
generat age3       = .
replace age3       = 1 if motherAge>=25 & motherAge<35
replace age3       = 2 if motherAge>=35 & motherAge<40
replace age3       = 3 if motherAge>=40 & motherAge<46
replace educLevel  = educLevel + 1
replace educLevel  = 2 if educLevel == 3
generat goodBirthQ = birthQuarter == 2 | birthQuarter == 3 

lab var educCat     "Years of education"
lab var motherAge   "Mother's Age"
lab var married     "Married"
lab var college     "At least some college"
lab var goodQuarter "Good Quarter"
lab var birthweight "Birthweight (grams)"
lab var lbw         "Low Birth Weight ($<$2500 g)"
lab var gestation   "Weeks of Gestation"
lab var premature   "Premature ($<$ 37 weeks)"
lab var apgar       "APGAR (1-10)"
lab var twin        "Twin"
lab var female      "Female"
lab var smoker      "Smoked during Pregnancy"
lab var ART         "Used ART (2009-2013 only)"
lab var young       "Young (aged 25-39)"
lab var expectGoodQ "Good season of birth (due date)"
lab var goodBirthQ  "Good season of birth (birth date)"


local Mum     motherAge `mc' young age2024 age2527 age2831 age3239 age4045
local MumPart college educCat smoker ART

gen tvar = abs(goodQuarter-1)
foreach st in Mum Kid MumPart {
    local Kid goodBirthQ expectGoodQ twin fem birthweight lbw gest premature apg

    sum ``st''
    #delimit ;
    estpost tabstat ``st'', statistics(count mean sd min max) columns(statistics);
    esttab using "$SUM/nvss`st'.tex", title("Descriptive Statistics (NVSS)")
     cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")
     replace label noobs;

    estpost ttest ``st'', by(tvar);
    esttab using "$SUM/ttest`st'.tex", nomtitles nonumber noobs label
      cells("mu_1(fmt(3)) mu_2(fmt(3)) se(fmt(4)) p(fmt(4))") replace;
    #delimit cr
    
    local Kid goodBirthQ expectGoodQ fem birthweight lbw gestat premature apgar
    preserve
    keep if `keepif' &married!=.&smoker!=.&college!=.&young!=.&twin==0
    if `allobs'==0 keep if married==1
    sum ``st''

    #delimit ;
    estpost tabstat ``st'', statistics(count mean sd min max)       
     columns(statistics);
    esttab using "$SUM/samp`st'.tex", title("Descriptive Statistics (NVSS)")
      cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  
    replace label noobs;

    estpost ttest ``st'', by(tvar);
    esttab using "$SUM/Sttest`st'.tex", nomtitles nonumber noobs label 
      cells("mu_1(fmt(3)) mu_2(fmt(3)) se(fmt(4)) p(fmt(4))") replace;
  
    #delimit cr
    restore
}
replace young     = . if motherAge<25|motherAge>45

preserve
keep if `keepif' &married!=.&smoker!=.&college!=.&young!=.&twin==0
if `allobs'==0 keep if married==1

#delimit ;
local listM motherAge young age2527 age2831 age3239 age4045 college
            educCat smoker ART;
local listK fem birthweight lbw gestat premature apgar;
#delimit cr


gen gQ = goodQuarter
local i = 1
foreach var of varlist `listM' {
    reg `var' gQ
    estimates store n`i'
    local ++i
}
suest n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
test [n1_mean]gQ [n2_mean]gQ [n3_mean]gQ [n4_mean]gQ [n5_mean]gQ  /*
*/   [n6_mean]gQ [n7_mean]gQ [n8_mean]gQ [n9_mean]gQ [n10_mean]gQ


local i = 1
foreach var of varlist `listK' {
    quietly reg `var' gQ
    estimates store n`i'
    local ++i
}
suest n1 n2 n3 n4 n5 n6 n7 n8
test [n1_mean]gQ [n2_mean]gQ [n3_mean]gQ [n4_mean]gQ [n5_mean]gQ [n6_mean]gQ /*
*/   [n7_mean]gQ [n8_mean]gQ
restore

exit
********************************************************************************
*** (2b) Subset
********************************************************************************
if `twins'==1 keep if twin == 1
if `twins'==0 keep if twin == 0
if `allobs'==0 keep if married==1
gen birth = 1

********************************************************************************
*** (2c) Label for clarity
********************************************************************************
lab def aG0 1 "Young (25-39) " 2  "Old (40-45) "
lab def aGa 1 "Young " 2  "Old "
lab def aG3 1 "25-34 Years " 2  "35-39 Years" 3 "40-45 Years"
lab def eL  1 "No College" 2 "Some College +"
lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" /*
*/ 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
lab def Qua 1 "Q1 (Jan-Mar)" 2 "Q2 (Apr-Jun)" 3 "Q3 (Jul-Sep)" 4 "Q4 (Oct-Dec)"

lab val ageGroup    aG0
lab val educLevel   eL

********************************************************************************
*** (3) Descriptives by month
*******************************************************************************
preserve
keep if `keepif'
drop if female == . | conceptionMonth == .
collapse female, by(conceptionMonth)
lab val conceptionMon mon

#delimit ;
twoway line female conceptionMonth, xlabel(1(1)12, valuelabels) 
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) lcolor(black) lwidth(thick)
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
ytitle("Proportion Female Conceptions");
#delimit cr
graph export "$OUT/proportionMonthFemale.eps", as(eps) replace
restore

preserve
keep if `keepif'
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.|conceptionMonth==.|female==.

collapse female, by(conceptionMonth youngOld)
lab val conceptionMon mon
sort conceptionMonth youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line female conceptionMonth if youngOld==1, `line1' ||
       line female conceptionMonth if youngOld==2, `line2'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) 
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion Female Conceptions");
graph export "$OUT/conceptionMonthFemaleAge.eps", as(eps) replace;
#delimit cr
restore



preserve
keep if `keepif'
drop if ART==.|conceptionMonth==.
collapse (sum) birth, by(conceptionMonth ART)
reshape wide birth, i(conceptionMonth) j(ART)
lab def m2 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" /*
*/ 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"

lab val conceptionMon m2
gen proportionART = birth1/(birth0+birth1)
sort conceptionMonth
twoway line proportionART conceptionMonth, xlabel(1(1)12, valuelabels) /*
*/ scheme(s1mono) ytitle("Proportion of Conceptions Using ART")        /*
*/ xtitle("Month of Conception")
graph export "$OUT/proportionMonthART.eps", as(eps) replace
restore

preserve
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
keep if youngOld != .
drop if education==. | conceptionMonth==.

generat educlevels = 1 if education<=2
replace educlevels = 2 if education>2&education<5
replace educlevels = 3 if education>=5

collapse (sum) birth, by(conceptionMonth youngOld educlevels)
lab val conceptionMon mon
bys educlevels youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth

local line1 lcolor(black) lpattern(dash) lwidth(thin)
local line2 lcolor(black) lwidth(medium) lpattern(longdash)
local line3 lcolor(black) lwidth(thick)

#delimit ;
twoway line birthProp conceptionM if educlevels==1&youngOld==1, `line1' 
    || line birthProp conceptionM if educlevels==2&youngOld==1, `line2' 
    || line birthProp conceptionM if educlevels==3&youngOld==1, `line3'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthEducYoung.eps", as(eps) replace;

twoway line birthProp conceptionM if educlevels==1&youngOld==2, `line1' 
    || line birthProp conceptionM if educlevels==2&youngOld==2, `line2' 
    || line birthProp conceptionM if educlevels==3&youngOld==2, `line3'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthEducOld.eps", as(eps) replace;
#delimit cr
restore

preserve
cap drop youngOld
generat youngOld = 1 if motherAge>=28&motherAge<=31  
replace youngOld = 2 if motherAge>=40&motherAge<=45
keep if youngOld != .
generat educlevels = 1 if education<=2
replace educlevels = 2 if education>2&education<5
replace educlevels = 3 if education>=5

collapse (sum) birth, by(birthQuarter youngOld educlevels)
lab val birthQuarter Qua
bys educlevels youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter

local line1 lcolor(black) lpattern(dash) lwidth(thin)
local line2 lcolor(black) lwidth(medium) lpattern(longdash)
local line3 lcolor(black) lwidth(thick)

#delimit ;
twoway line birthProp birthQuarter if educlevels==1&youngOld==1, `line1'
    || line birthProp birthQuarter if educlevels==2&youngOld==1, `line2'
    || line birthProp birthQuarter if educlevels==3&youngOld==1, `line3'
scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
       lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/birthQuarterEducYoungComparison.eps", as(eps) replace;

twoway line birthProp birthQuarter if educlevels==1&youngOld==2, `line1'
    || line birthProp birthQuarter if educlevels==2&youngOld==2, `line2'
    || line birthProp birthQuarter if educlevels==3&youngOld==2, `line3'
scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
ylabel(0.23 0.24 0.25 0.26 0.27)
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
       lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/birthQuarterEducOldComparison.eps", as(eps) replace;
#delimit cr
restore


preserve
keep if `keepif'
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.|conceptionMonth==.

collapse (sum) birth, by(conceptionMonth youngOld)
lab val conceptionMon mon
bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
       line birthProportion conceptionMonth if youngOld==2, `line2'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) 
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonth.eps", as(eps) replace;
#delimit cr
restore


preserve
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.

collapse (sum) birth, by(birthQuarter youngOld)
lab val birthQuarter Qua
bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion birthQuarter if youngOld==1, `line1' ||
           line birthProportion birthQuarter if youngOld==2, `line2'
scheme(s1mono) xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$OUT/birthQuarterAgesComparison.eps", as(eps) replace;
#delimit cr
restore


preserve
keep if `keepif'
generat youngOld = 1 if motherAge>=28&motherAge<=39
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.|conceptionMonth==.
keep if ART==1
collapse (sum) birth, by(conceptionMonth youngOld)
lab val conceptionMon mon

bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
       line birthProportion conceptionMonth if youngOld==2, `line2' 
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) 
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(label(1 "28-39 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthART.eps", as(eps) replace;
#delimit cr
restore


preserve
keep if `keepif'
collapse (sum) birth, by(birthMonth young)

bys young: egen totalBirths = sum(birth)
replace birth = birth/totalBirths

gen days = 31 if birthMonth==1|birthMonth==3|birthMonth==5|birthMonth==7|/*
*/ birthMonth==8|birthMonth==10|birthMonth==12
replace days = 30 if birthMonth==4|birthMonth==6|birthMonth==9|birthMonth==11 
replace days = 28.25 if birthMonth==2
gen expectedProp = days / 365.25
gen excessBirths = birth - expectedProp

lab var birth        "Proportion of Births"
lab var expectedProp "Expected Births (days/365.25)"
lab var excessBirths "Proportion of Excess Births (Actual-Expected)"
lab val birthMonth    mon

sort young birthMonth
foreach num of numlist 0 1 {
    local name Old
    if `num'==1 local name Young
    #delimit ;
    twoway bar birth birthMonth if young==`num', bcolor(ltblue) ||
        line expectedProp birthM if young==`num', scheme(s1mono) lpattern(dash)
    lcolor(black) xlabel(1(1)12, valuelabels) ytitle("Proportion")
    xtitle("Month of Birth");
    graph export "$OUT/birthsPerMonth`name'.eps", as(eps) replace;

    twoway bar excessBirths birthMonth if young==`num', bcolor(ltblue)
    xlabel(1(1)12, valuelabels) ytitle("Proportion") xtitle("Month of Birth")
    ytitle("Proportion Excess Births (Actual-Expected)") scheme(s1mono)
    yline(0, lpattern(dash) lcolor(black)) ylabel(-0.01 -0.005 0 0.005);
    graph export "$OUT/excessBirths`name'.eps", as(eps) replace;
    #delimit cr
}
restore

preserve
keep if `keepif'
collapse premature, by(birthQuarter)
#delimit ;
graph bar premature, ylabel(0.09(0.01)0.11, nogrid) exclude0
over(birthQuar, relabel(1 "Jan-Mar" 2 "Apr-Jun" 3 "Jul-Sep" 4 "Oct-Dec"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))bar(4, bcolor(gs0))
scheme(s1mono) ytitle("% Premature");
graph export "$OUT/prematureQOB.eps", as(eps) replace;
#delimit cr
restore

preserve
gen ageG2 = motherAge>=20 & motherAge<46
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46
keep if motherAge>=20&motherAge<=45
collapse premature, by(ageG2)
#delimit ;
graph bar premature, ylabel(0.05(0.01)0.14, nogrid) exclude0
over(ageG2, relabel(1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))
scheme(s1mono) ytitle("% Premature"); 
graph export "$OUT/prematureAges.eps", as(eps) replace;
#delimit cr
restore

preserve
keep if `keepif'
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngMont = .

generat Xvar = 1 if motherAge>=28&motherAge<=31
replace Xvar = 0 if motherAge>=40&motherAge<=45
foreach num of numlist 1(1)12 {
    gen month`num' = conceptionMonth == `num'
    qui reg month`num' Xvar
    replace youngBeta = _b[Xvar] in `num'
    replace youngHigh = _b[Xvar] + 1.96*_se[Xvar] in `num'
    replace youngLoww = _b[Xvar] - 1.96*_se[Xvar] in `num'
    replace youngMont = `num' in `num'
}
lab def Month   1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun"  /*
             */ 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
lab val youngMont       Month
lab val conceptionMonth Month

#delimit ;
twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
xaxis(1 2) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) legend(order(1 "Young-Old" 2 "95% CI"))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month");
graph export "$OUT/youngMonths.eps", as(eps) replace;
#delimit cr

drop Xvar
generat Xvar = 1 if motherAge>=28&motherAge<=39
replace Xvar = 0 if motherAge>=40&motherAge<=45

foreach A of numlist 0 1 {
    foreach num of numlist 1(1)12 {
        qui reg month`num' Xvar if ART==`A'
        replace youngBeta = _b[Xvar] in `num'
        replace youngHigh = _b[Xvar] + 1.96*_se[Xvar] in `num'
        replace youngLoww = _b[Xvar] - 1.96*_se[Xvar] in `num'
        replace youngMont = `num' in `num'
    }
    lab val youngMont Month
    lab val birthMont Month

    #delimit ;
    twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
    scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
    xaxis(1 2) xtitle("Month of Conception", axis(2))
    xlabel(1(1)12, valuelabels axis(2))
    xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
           9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1))
    xtitle("Expected Month") legend(order(1 "Young-Old" 2 "95% CI"));
    graph export "$OUT/youngMonthsART`A'.eps", as(eps) replace;
    #delimit cr
}
restore

preserve
keep if `keepif'
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngQuar = .

generat Xvar = 1 if motherAge>=28&motherAge<=31
replace Xvar = 0 if motherAge>=40&motherAge<=45
foreach num of numlist 1(1)4 {
    gen quarter`num' = birthQuarter == `num'
    qui reg quarter`num' Xvar
    replace youngBeta = _b[Xvar] in `num'
    replace youngHigh = _b[Xvar] + 1.96*_se[Xvar] in `num'
    replace youngLoww = _b[Xvar] - 1.96*_se[Xvar] in `num'
    replace youngQuar = `num' in `num'
}
lab val youngQuar       Qua 

#delimit ;
twoway line youngBeta youngQuar || rcap youngLoww youngHigh youngQuar,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(order(1 "Young-Old" 2 "95% CI"));
graph export "$OUT/youngQuarterComparison.eps", as(eps) replace;  
#delimit cr
restore

********************************************************************************
*** (4) Graph of good season by age
********************************************************************************
preserve
keep if motherAge>=20&motherAge<=45

tab motherAge, gen(_age)
reg goodQuarter _age1-_age20 if motherAge>=20&motherAge<=45
reg expectGoodQ _age1-_age20 if motherAge>=20&motherAge<=45

gen ageES = .
gen ageLB = .
gen ageUB = .
gen ageNM = .
foreach num of numlist 1(1)20 {
    replace ageES = _b[_age`num']                     in `num'
    replace ageLB = _b[_age`num']-1.96*_se[_age`num'] in `num'
    replace ageUB = _b[_age`num']+1.96*_se[_age`num'] in `num'
    replace ageNM = `num'+19                          in `num'
}
#delimit ;
twoway line ageES ageNM in 1/20, lpattern(solid) lcolor(black) lwidth(medthick)
    || line ageLB ageNM in 1/20, lpattern(dash)  lcolor(black) lwidth(medium)
    || line ageUB ageNM in 1/20, lpattern(dash)  lcolor(black) lwidth(medium) ||
    scatter ageES ageNM in 1/20, mcolor(black) m(S) 
    scheme(s1mono) legend(order(1 "Point Estimate" 2 "95 % CI"))
    xlabel(20(1)39) xtitle("Mother's Age") ytitle("Proportion Good Season" " ");
graph export "$OUT/goodSeasonAge.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (5) Prematurity
********************************************************************************
#delimit ;
hist gestat if gestat>24, frac scheme(s1mono) xtitle("Weeks of Gestation")
width(1) start(25);
graph export "$OUT/gestWeeks.eps", as(eps) replace;

preserve;
keep if `keepif';
collapse premature, by(birthMonth);
twoway bar premature birthMonth, bcolor(black) scheme(s1mono)
xtitle("Month of Birth") xlabel(1(1)12, valuelabels)
ytitle("Proportion of Premature Births") ylabel(0.08(0.005)0.095);
graph export "$OUT/prematureMonth.eps", as(eps) replace;
restore;

preserve;
keep if `keepif';
collapse premature, by(goodQuarter);
drop if goodQuarter==.;
twoway bar premature goodQuarter, bcolor(black) scheme(s1mono)
xtitle("Season of Birth") xlabel(1 2, valuelabels)
ytitle("Proportion of Premature Births") ylabel(0.08(0.005)0.095);
graph export "$OUT/prematureSeason.eps", as(eps) replace;
restore;

preserve;
keep if `keepif';
collapse premature, by(goodQuarter ageGroup);
drop if goodQuarter==.;
reshape wide premature, i(ageGroup) j(goodQuarter);

graph bar premature*, over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Season") label(2 "Good Season"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid)
exclude0 ylab(0.08(0.01)0.14);
graph export "$OUT/prematureSeasonAge.eps", as(eps) replace;
restore;
#delimit cr

********************************************************************************
*** (6) Sumstats all periods together
********************************************************************************
preserve
drop if educLevel==.
drop if goodQuarter==.
collapse premature ART (sum) birth, by(goodQuarter educLevel ageGroup)
bys ageGroup educLevel: egen aveprem = mean(premature)
bys ageGroup educLevel: egen aveART = mean(ART)
drop premature ART
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
gen str4 prem       = string(aveprem, "%04.2f")
gen str4 ART        = string(aveART, "%04.2f")
drop totalbirths diff rati birth* ave*
    
decode ageGroup, gen(ag)
replace ag = "Young " if ag == "Young (25-39) "
replace ag = "Old "   if ag == "Old (40-45) "
keep if ag =="Young "| ag == "Old " 
decode educLevel, gen(el)
egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample`app'.txt", delimiter("&") replace noquote
restore

preserve
drop if educLevel==.|goodQuarter==.
collapse premature ART (sum) birth, by(goodQuarter educLevel)
bys educLevel: egen aveprem = mean(premature)
bys educLevel: egen aveART = mean(ART)
drop premature ART
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
gen str4 prem       = string(aveprem, "%04.2f")
gen str4 ART        = string(aveART, "%04.2f")
drop totalbirths diff rati birth* ave*
    
decode educLevel, gen(el)
order el
drop educLevel
outsheet using "$SUM/JustEduc`app'.txt", delimiter("&") replace noquote
restore

preserve
drop if educLevel==.|goodQuarter==.|motherAge<20|motherAge>45
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

collapse premature ART (sum) birth, by(goodQuarter ageG2)
lab def ag_2 1 "20-24 Years Old" 2 "25-27 Years Old" 3 "28-31 Years Old" /*
*/ 4 "32-39 Years Old" 5 "40-45 Years Old"
lab val ageG2 ag_2

bys ageG2: egen aveprem = mean(premature)
bys ageG2: egen aveART = mean(ART)
drop premature ART
reshape wide birth, i(ageG2) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
gen str4 prem       = string(aveprem, "%04.2f")
gen str4 ART        = string(aveART, "%04.2f")
drop totalbirths diff rati ave*

outsheet using "$SUM/FullSample`app'.txt", delimiter("&") replace noquote
restore

foreach var of varlist premature ART {
    gen _`var'young = `var'       if ageGroup  == 1
    gen _`var'old = `var'         if ageGroup  == 2
    gen _`var'lowEd = `var'       if educLevel == 1
    gen _`var'highEd = `var'      if educLevel == 2
    gen _`var'younglowEd = `var'  if educLevel == 1 & ageGroup == 1
    gen _`var'younghighEd = `var' if educLevel == 2 & ageGroup == 1
    gen _`var'oldlowEd = `var'    if educLevel == 1 & ageGroup == 2
    gen _`var'oldhighEd = `var'   if educLevel == 2 & ageGroup == 2
}
sum _p* _A*
estpost tabstat _p* _A*, statistics(mean sd) columns(statistics)
esttab using "$SUM/nvssARTPrem.tex", title("ART and Premature")/*
    */ cells("mean(fmt(2)) sd(fmt(2))") replace label noobs
drop _p* _A*

********************************************************************************
*** (6a) Global histogram
********************************************************************************
tempfile all educ

preserve
drop if goodQuarter==.
collapse (sum) birth, by(goodQuarter ageGroup)
reshape wide birth, i(ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
#delimit ;
graph bar birth*, over(ageGroup) scheme(s1mono) legend(label(1 "Bad Quarter")
  label(2 "Good Quarter")) bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0))
  ylabel(, nogrid) yline(0);
graph export "$OUT/total`app'.eps", as(eps) replace;
#delimit cr
save `all'
restore

********************************************************************************
*** (6b) Histogram by education level
********************************************************************************
preserve
drop if goodQuarter==.
drop if educLevel  ==.

collapse (sum) birth, by(goodQuarter ageGroup educLevel)
reshape wide birth, i(ageGroup educLevel) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50

#delimit ;
graph bar birth*, over(educLevel, relabel(1 "No College" 2 "Some College +")
                                              label(angle(45))) over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Quarter") label(2 "Good Quarter"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid) yline(0);
graph export "$OUT/totalEduc`app'.eps", as(eps) replace;
#delimit cr
drop if educLevel == .
save `educ'
restore

********************************************************************************
*** (6c) Histogram: All, educ
********************************************************************************
preserve
use `all', replace
append using `educ'
keep birth1 ageGroup educLevel
replace birth1 = birth1*2
replace educLevel = 0 if educLevel == .
replace educLevel = educLevel + 1
lab def eL2  1 "All" 2 "No College" 3 "Some College +"
lab val educLevel   eL2

reshape wide birth1, i(educLevel) j(ageGroup)

#delimit ;
graph bar birth*, over(educLevel, relabel(1 "All" 2 "No College" 3
                                          "Some College +")
                       label(angle(45))) yline(0)
legend(label(1 "20-25") label(2 "25-39") label(3 "40-45")) ylabel(, nogrid)
scheme(s1mono) bar(1, bcolor(gs0)) bar(2, bcolor(white) lcolor(gs0));
graph export "$OUT/birthQdiff`app'.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (6d) Histogram for more age groups
********************************************************************************
preserve
use "$DAT/`data'", clear
if `allobs'==0 keep if married==1
keep if birthOrder==1&educLevel!=.&motherAge>=20&motherAge<=45

gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
gen birth = 1

collapse (sum) birth, by(goodQuarter ageG2)
drop if goodQuarter == .
reshape wide birth, i(ageG2) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
keep birth1 ageG2
replace birth1=birth1*2
list
lab def       aG4 1 "20-24" 2 "25-27" 3 "28-31" 4 "35-39" 5 "40-45"
lab val ageG2 aG4


#delimit ;
graph bar birth1, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'.eps", as(eps) replace;
#delimit cr
restore

preserve
use "$DAT/`data'", clear
if `allobs'==0 keep if married==1
keep if birthOrder==1&educLevel!=.&motherAge>=20&motherAge<=45

gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
gen birth = 1

keep if ART!=.
replace goodQuarter = goodQuarter*100
foreach Anum of numlist 0 1 {
    reg goodQuarter age2024 age2527 age2831 age3239 if ART==`Anum'
    local se2024`Anum' = _se[age2024]
    local se2527`Anum' = _se[age2527]
    local se2831`Anum' = _se[age2831]
    local se3239`Anum' = _se[age3239]
    local se4045`Anum' = _se[_cons]
}
replace goodQuarter = goodQuarter/100

collapse (sum) birth, by(goodQuarter ageG2 ART)
drop if goodQuarter==.|ageG2==.
reshape wide birth, i(ageG2 ART) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
keep birth1 ageG2 ART
replace birth1=birth1*2
list
lab def       aG5 1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45"
lab val ageG2 aG5

gen seUp   = .
gen seDown = .
foreach Anum of numlist 0 1 {
    replace seUp= birth1+1.96*`se2024`Anum'' if ageG2==1&ART==`Anum'
    replace seUp= birth1+1.96*`se2527`Anum'' if ageG2==2&ART==`Anum'
    replace seUp= birth1+1.96*`se2831`Anum'' if ageG2==3&ART==`Anum'
    replace seUp= birth1+1.96*`se3239`Anum'' if ageG2==4&ART==`Anum'
    replace seUp= birth1+1.96*`se4045`Anum'' if ageG2==5&ART==`Anum'

    replace seDo= birth1-1.96*`se2024`Anum'' if ageG2==1&ART==`Anum'
    replace seDo= birth1-1.96*`se2527`Anum'' if ageG2==2&ART==`Anum'
    replace seDo= birth1-1.96*`se2831`Anum'' if ageG2==3&ART==`Anum'
    replace seDo= birth1-1.96*`se3239`Anum'' if ageG2==4&ART==`Anum'
    replace seDo= birth1-1.96*`se4045`Anum'' if ageG2==5&ART==`Anum'
}

#delimit ;
graph bar birth1 if ART==1, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'ART.eps", as(eps) replace;

twoway bar birth1 ageG2 if ART==1, barw(0.5) ylabel(, nogrid) color(ltblue)
  || rcap seUp seDo ageG2 if ART==1, lcolor(black) yline(0, lpattern("_"))
xlabel(1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45") xtitle(" ")
legend(off) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'ART.eps", as(eps) replace;


graph bar birth1 if ART==0, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'NoART.eps", as(eps) replace;

twoway bar birth1 ageG2 if ART==0, barw(0.5) color(ltblue) ylabel(, nogrid)
 || rcap seUp seDo ageG2 if ART==0, yline(0, lpattern("_")) lcolor(black) 
xlabel(1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45") xtitle(" ")
legend(off) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'NoART.eps", as(eps) replace;

#delimit cr
restore

********************************************************************************
*** (7) Birth outcomes by groups
********************************************************************************
local hkbirth birthweight lbw gestation premature vlbw apgar  
local axesN   3100[50]3350 0.04[0.02]0.14 38[0.2]39 0.06[0.02]0.18
if `twins'==1 {
    local axesN 2150[50]2450 0.4[0.05]0.7 34[0.5]36 0.5[0.05]0.8 0.06[0.02]0.14
}

tokenize `axesN'
preserve
collapse `hkbirth', by(goodQuarter ageGroup educLevel)
drop if educLevel == .|goodQuarter == .
reshape wide `hkbirth', i(ageGroup educLevel) j(goodQuarter)


foreach outcome in `hkbirth' {
    #delimit ;
    graph bar `outcome'*, over(educLevel, relabel(1 "No College" 2 "Some College +")
                                              label(angle(45))) over(ageGroup)
      scheme(s1mono) legend(label(1 "Bad Season") label(2 "Good Season"))
      bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid)
      exclude0 ylab(`1');
    graph export "$OUT/Quality_`outcome'_`app'.eps", as(eps) replace;
    #delimit cr
    macro shift
}
restore


local hkbirth birthweight lbw gestation
local axesN   3225[25]3350 0.05[0.01]0.1 38.4[0.2]39.2
if `twins'==1 local axesN 2300[25]2400 0.5[0.025]0.6 35[0.1]35.5 

tokenize `axesN'
preserve
drop if goodQuarter == .
collapse `hkbirth', by(goodQuarter ageGroup)
reshape wide `hkbirth', i(ageGroup) j(goodQuarter)

foreach outcome in `hkbirth' {
    #delimit ;
    graph bar `outcome'*, over(ageGroup)
      scheme(s1mono) legend(label(1 "Bad Season") label(2 "Good Season"))
      bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid)
      exclude0 ylab(`1');
    graph export "$OUT/AllQuality_`outcome'_`app'.eps", as(eps) replace;
    #delimit cr
    macro shift
}
restore

********************************************************************************
*** (8) Examine by geographic variation (hot/cold)
********************************************************************************
***NOTE: 12 is Florida (759,551 births). 31 is Nebraska (125,628 births).
***27 is Minnesota (350,968 births).
cap lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" /*
*/ 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
#delimit ;
local stat AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME 
           MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX 
           UT VA VT WA WI WV WY;
local snam " `"Alaska"' `"Alabama"' `"Arkansas"' `"Arizona"' `"California"'
             `"Colorado"' `"Connecticut"' `"Washington DC"' `"Delaware"'
             `"Florida"' `"Georgia"' `"Hawaii"' `"Iowa"' `"Idaho"' `"Illinois"'
             `"Indiana"' `"Kansas"' `"Kentucky"' `"Louisiana"' `"Massachusetts"'
             `"Maryland"' `"Maine"' `"Michigan"' `"Minnesota"' `"Missouri"'
             `"Mississippi"' `"Montana"' `"North Carolina"' `"North Dakota"'
             `"Nebraska"' `"New Hampshire"' `"New Jersey"' `"New Mexico"'
             `"Nevada"' `"New York"' `"Ohio"' `"Oklahoma"' `"Oregon"'
             `"Pennsylvania"' `"Rhode Island"' `"South Carolina"'
             `"South Dakota"' `"Tennessee"' `"Texas"' `"Utah"' `"Virginia"'
             `"Vermont"' `"Washington"' `"Wisconsin"' `"West Virginia"'
             `"Wyoming"'";
#delimit cr
tokenize `stat'
rename state stateNoSpace
gen state = ""
foreach sname of local snam {
    dis "`1' <--> `sname'"
    tab stateNoSpace if bstate=="`1'"
    replace state="`sname'" if bstate=="`1'"
    macro shift
}



drop if conceptionMonth==.
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
collapse (sum) birth, by(conceptionMonth bstate youngOld state)
lab val conceptionMon mon
bys bstate youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth bstate

local line1 lpattern(solid)    lcolor(black)
local line2 lpattern(dash)     lcolor(black) 
local MN    Minnesota
local WI    Wisconsin

foreach hS in Alabama Arkansas Arizona {
    local cond1 state=="`hS'"
    local cond2 state=="Minnesota"
    #delimit ;
    twoway line birthProportion conceptionMonth if `cond1'& youngO==1, `line1' ||
           line birthProportion conceptionMonth if `cond2'& youngO==1, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$OUT/conceptionMonth`hS'Minnesota_young.eps", as(eps) replace;

    twoway line birthProportion conceptionMonth if `cond1'& youngO==2, `line1' ||
           line birthProportion conceptionMonth if `cond2'& youngO==2, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$OUT/conceptionMonth`hS'Minnesota_old.eps", as(eps) replace;
    #delimit cr

    local cond2 state=="Wisconsin"
    #delimit ;
    twoway line birthProportion conceptionMonth if `cond1'& youngO==1, `line1' ||
           line birthProportion conceptionMonth if `cond2'& youngO==1, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$OUT/conceptionMonth`hS'Wisconsin_young.eps", as(eps) replace;

    twoway line birthProportion conceptionMonth if `cond1'& youngO==2, `line1' ||
           line birthProportion conceptionMonth if `cond2'& youngO==2, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$OUT/conceptionMonth`hS'Wisconsin_old.eps", as(eps) replace;
    #delimit cr
}

********************************************************************************
*** (8b) All states
********************************************************************************
tokenize `stat'
cap mkdir "$OUT/states"
foreach s of local snam {
    local cond if state=="`s'"
    sum totalBirths `cond'&young==1
    local Ny = r(mean)
    sum totalBirths `cond'&young==0
    local No = r(mean)
    local Nt = `No'+`Ny'

    #delimit ;
    twoway line birthProportion conceptionMonth `cond'&young==1, `line1' ||
    line birthProportion conceptionMonth `cond'&young==0, `line2' 
    scheme(s1mono) xtitle("Month of Conception") ytitle("Proportion of All Births") 
    legend(label(1 "Young") label(2 "Old")) xlabel(1(1)12, valuelabels) title(`s')
    note("Total number of births is `Nt', young are `Ny' and old are `No'.");
    graph export "$OUT/states/months`1'.eps", as(eps) replace;
    #delimit cr
    macro shift
}

insheet using "$USW/usaWeather.txt", delim(";") names clear
destring temp, replace

reshape wide temp, i(state fips year month) j(type) string
keep if year>1997&year<=1999

collapse temptmpcst (min) temptminst (max) temptmaxst, by(state fips)
expand 2 if fips == 24, gen(expanded)
replace fips = 11 if expanded==1
replace state= "Washington DC" if expanded==1
drop expanded
rename temptmpcst meanT
rename temptminst cold
rename temptmaxst hot

tempfile weather
save `weather'


use "$DAT/`data'"
if `allobs'==0 keep if married==1
replace twin=twin-1
keep if birthOrder==1&motherAge>19&motherAge<=45
gen birth = 1
drop ageGroup young
gen     ageGroup = 1 if motherAge>=20&motherAge<=24
replace ageGroup = 2 if motherAge>=25&motherAge<=27
replace ageGroup = 3 if motherAge>=28&motherAge<=31
replace ageGroup = 4 if motherAge>=32&motherAge<=39
replace ageGroup = 5 if motherAge>=40&motherAge<=45

keep if goodQuarter != .
gen     young = 1 if ageGroup == 2|ageGroup==3|ageGroup==4
replace young = 0 if ageGroup == 5

preserve
collapse goodQuarter expectGoodQ, by(ageGroup fips state bstate)

merge m:1 state using `weather'
drop _merge

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
lab var hot         "Warmest monthly average (degree F)"
lab var meanT       "Mean monthly temperature (degree F)"
format goodQuarter %5.2f
foreach num of numlist 3 5 {
    local age young
    if `num'==5 local age old
    drop if state=="Alaska"

    corr goodQuarter cold if ageGroup==`num'
    local ccoef = string(r(rho),"%5.3f")
    twoway scatter goodQuarter cold if ageGroup==`num', mlabel(state) ||      ///
        lfit goodQuarter cold if ageGroup==`num', scheme(s1mono) lcolor(gs0)  ///
            legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'")
    graph export "$OUT/`age'TempCold.eps", as(eps) replace

    corr goodQuarter hot if ageGroup==`num'
    local ccoef = string(r(rho),"%5.3f")
    twoway scatter goodQuarter hot if ageGroup==`num', mlabel(state)  ||      ///
        lfit goodQuarter hot if ageGroup==`num', scheme(s1mono) lcolor(gs0)   ///
            legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'")
    graph export "$OUT/`age'TempWarm.eps", as(eps) replace
    twoway scatter goodQuarter meanT if ageGroup==`num', mlabel(state)||      ///
        lfit goodQuarter meanT if ageGroup==`num', scheme(s1mono) lcolor(gs0) ///
            legend(off) lpattern(dash)
    graph export "$OUT/`age'TempMean.eps", as(eps) replace
}
restore

collapse goodQuarter expectGoodQ, by(ageGroup fips state bstate female)

merge m:1 state using `weather'
drop _merge

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
lab var hot         "Warmest monthly average (degree F)"
lab var meanT       "Mean monthly temperature (degree F)"
format goodQuarter %5.2f
foreach gend of numlist 0 1 {
    if `gend'==0 local gname male
    if `gend'==1 local gname female
    foreach num of numlist 3 5 {
        local age young
        if `num'==5 local age old
        drop if state=="Alaska"

        corr goodQuarter cold if ageGroup==`num'&female==`gend'
        local ccoef = string(r(rho),"%5.3f")
        #delimit ;
        twoway scatter goodQuarter cold if ageGroup==`num'&female==`gend', mlabel(state)
             ||   lfit goodQuarter cold if ageGroup==`num'&female==`gend', scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'");
        #delimit cr
        graph export "$OUT/`age'TempCold_`gname'.eps", as(eps) replace
    }
}


drop state
rename bstate state
merge m:1 state using "$DAT/../maps/state_database_clean"
drop _merge
format expectGoodQ %5.3f

cap mkdir "$OUT/maps"
#delimit ;
spmap expectGoodQ if ageGroup==3&(fips!=2&fips!=18) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$OUT/maps/youngGoodSeason.eps", replace as(eps);

spmap expectGoodQ if ageGroup==5&(fips!=2&fips!=18) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$OUT/maps/oldGoodSeason.eps", replace as(eps);
#delimit cr



************************************************************************************
*** (9) Evolution
************************************************************************************
local tfiles
foreach y of numlist 1968(1)2013 {
    use "$RAW/natl`y'", clear
    tempfile f`y'
    if `y'<2003 rename dlivord lbo
    if `y'==2003 {
        drop mrace
        rename mracerec mrace
        gen dmage = mager41 + 13
        rename dob_mm birmon
    }
    if `y'>2003 {
        drop mrace
        rename mracerec mrace
        rename mager dmage
        rename dob_mm birmon
    }
    tab birmon
    keep if lbo==1&mrace==1&dmage>=25&dmage<=45
    qui gen goodSeason = birmon>3 & birmon<=9
    collapse goodSeason (semean) se=goodSeason
    save `f`y''
        
    use "$RAW/natl`y'", clear
    if `y'<2003 rename dlivord lbo
    if `y'==2003 {
        drop mrace
        rename mracerec mrace
        gen dmage = mager41 + 13
        rename dob_mm birmon
    }
    if `y'>2003 {
        drop mrace
        rename mracerec mrace
        rename mager dmage
        rename dob_mm birmon
    }

    keep if lbo==1&mrace==1&dmage>=25&dmage<=45
    qui gen goodSeason = birmon>3 & birmon<=9
    qui gen     ageGroup = 1 if dmage>=25&dmage<28
    qui replace ageGroup = 2 if dmage>=28&dmage<32
    qui replace ageGroup = 3 if dmage>=32&dmage<40
    qui replace ageGroup = 4 if dmage>=40&dmage<46
    collapse goodSeason (semean) se=goodSeason, by(ageGroup)
    append using `f`y''
    qui gen year = `y'
    save `f`y'', replace

    list
    local tfiles `tfiles' `f`y''
}
clear
append using `tfiles'
gen lbound = goodSeason - 1.96*se
gen ubound = goodSeason + 1.96*se
save "$DAT/proportionTime", replace
use "$DAT/proportionTime", clear

local l1 lcolor(black) msymbol(o)  mcolor(black)
local l2 lcolor(black) msymbol(Dh) mcolor(black)
local l3 lcolor(black) msymbol(Th) mcolor(black)
local l4 lcolor(black) msymbol(s)  mcolor(black)

#delimit;
twoway line goodSeason year if ageGroup==., lcolor(black) ||
    rcap ubound lbound year if ageGroup==., lcolor(black)
   ytitle("Proportion Good Season of Birth") xtitle("Year") scheme(s1mono)
   yline(0.50, lpattern(dash)) legend(lab(1 "Good Season") lab(2 "95% CI"));
graph export "$OUT/longRun.eps", as(eps) replace;
#delimit cr

local ages 25-27 28-31 32-39 40-45
tokenize `ages'
foreach num of numlist 1 2 3 4 {
    #delimit;
    twoway line goodSeason year if ageGroup==`num', lcolor(black) ||
        rcap ubound lbound year if ageGroup==`num', lcolor(black)
        ytitle("Proportion Good Season of Birth") xtitle("Year") scheme(s1mono)
        yline(0.50, lpattern(dash)) legend(lab(1 "Good Season") lab(2 "95% CI"));
    graph export "$OUT/longRun_``num''.eps", as(eps) replace;
    #delimit cr
}

#delimit;
twoway connected goodSeason year if ageGroup==1, `l1'          ||
       connected goodSeason year if ageGroup==2, `l2'          ||
       connected goodSeason year if ageGroup==3, `l3'          ||
       connected goodSeason year if ageGroup==4, `l4'          ||
         rcap ubound lbound year if ageGroup==1, lcolor(black) ||
         rcap ubound lbound year if ageGroup==2, lcolor(black) ||
         rcap ubound lbound year if ageGroup==3, lcolor(black) ||
         rcap ubound lbound year if ageGroup==4, lcolor(black) 
   ytitle("Proportion Good Season of Birth") xtitle("Year") scheme(s1mono)
   legend(order(1 "25-27" 2 "28-31" 3 "32-39" 4 "40-45") title("Mother's Age"));
graph export "$OUT/longRunAges.eps", as(eps) replace;


#delimit cr


************************************************************************************
*** (10) Black mother descriptives
************************************************************************************
use "$DAT/nvss2005_2013_Black", clear
keep if twin==1 & motherAge>24 & motherAge <= 45
lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" /*
*/ 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"


preserve
gen birth = 1
collapse (sum) birth, by(birthQuarter)
egen total = total(birth)
gen birthProportion = birth/total
#delimit ;
graph bar birthProportion, ylabel(0.20(0.02)0.30, nogrid) exclude0
over(birthQuarter, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))
scheme(s1mono) ytitle("Proportion of Births") yline(0.25, lpattern(dash)); 
graph export "$OUT/blackQuarter.eps", as(eps) replace;
#delimit cr
restore

preserve
gen birth = 1
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
generat educlevels = 1 if education<=2
replace educlevels = 2 if education>2&education<5
replace educlevels = 3 if education>=5

keep if youngOld != .
drop if conceptionMonth==. | educlevels==.
collapse (sum) birth, by(conceptionMonth youngOld educlevels)
lab val conceptionMon mon
bys educlevels youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth

local line1 lcolor(black) lpattern(dash) lwidth(thin)
local line2 lcolor(black) lwidth(medium) lpattern(longdash)
local line3 lcolor(black) lwidth(thick)

#delimit ;
twoway line birthProp conceptionM if educlevels==1&youngOld==1, `line1' 
    || line birthProp conceptionM if educlevels==2&youngOld==1, `line2' 
    || line birthProp conceptionM if educlevels==3&youngOld==1, `line3'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthEducYoungBlack.eps", as(eps) replace;

twoway line birthProp conceptionM if educlevels==1&youngOld==2, `line1' 
    || line birthProp conceptionM if educlevels==2&youngOld==2, `line2' 
    || line birthProp conceptionM if educlevels==3&youngOld==2, `line3'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthEducOldBlack.eps", as(eps) replace;
#delimit cr
restore

preserve
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
gen birth = 1

drop if youngOld==.|conceptionMonth==.

collapse (sum) birth, by(conceptionMonth youngOld)
lab val conceptionMon mon
bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
       line birthProportion conceptionMonth if youngOld==2, `line2'
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) 
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthBlack.eps", as(eps) replace;
#delimit cr
restore

preserve
gen birth = 1
generat youngOld = 1 if motherAge>=28&motherAge<=39
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.|conceptionMonth==.
keep if ART==1
collapse (sum) birth, by(conceptionMonth youngOld)
lab val conceptionMon mon

bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
       line birthProportion conceptionMonth if youngOld==2, `line2' 
xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) 
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
legend(label(1 "28-39 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$OUT/conceptionMonthARTBlack.eps", as(eps) replace;
#delimit cr
restore


    
************************************************************************************
*** (X) Close
************************************************************************************
log close
