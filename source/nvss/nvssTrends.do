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

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global OUT "~/investigacion/2015/birthQuarter/results/nvss/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/nvss/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"
global USW "~/investigacion/2015/birthQuarter/data/weather"

log using "$LOG/nvssTrends.txt", text replace
cap mkdir "$SUM"


local legd     legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
local note "Quarters represent the difference between percent of yearly births"
if c(os)=="Unix" local e eps
if c(os)!="Unix" local e pdf

local data nvss2005_2013
local keepif  birthOrder == 1 & motherAge > 24 & motherAge<=45
local stateFE 0
local twins   0
local lyear   25
if `twins' == 1 local app twins
/*
********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if married==1
keep if birthOrder==1

#delimit ;
twoway histogram motherAge if motherA>24&motherA<=45, freq color(gs0) width(1) ||
histogram motherAge if motherAge<=24|motherAge>45, freq color(gs12) width(1)
    ylabel( 0 "0" 100000 "100,000" 200000 "200,000" 300000 "300,000" 400000
           "400,000" 500000 "500,000", angle(0)) xtitle("Mother's Age") 
    legend(label(1 "Estimation Sample") label(2 "<25 or >45")) scheme(s1mono);
                                        #delimit cr
graph export "$OUT/ageDescriptive.eps", as(eps) replace
keep if twin<3

preserve
keep if `keepif'
collapse ART, by(motherAge)
#delimit ;
twoway line ART motherAge, xtitle("Mother's Age") scheme(s1mono)
ytitle("Assisted Reproductive Technology");
#delimit cr
graph export "$OUT/ART.eps", as(eps) replace
restore

preserve
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<35
replace ageG2 = 3 if motherAge>=35 & motherAge<40
replace ageG2 = 4 if motherAge>=40 & motherAge<46
keep if motherAge>=20&motherAge<=45
collapse ART, by(ageG2)
lab def       aG2 1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45"
lab val ageG2 aG2
#delimit ;
graph bar ART, over(ageG2)  ylabel(, nogrid) exclude0
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("Proportion ART");
graph export "$OUT/ARTageGroup.eps", as(eps) replace;
#delimit cr
restore



********************************************************************************
*** (2aii) Summary stats table
********************************************************************************
gen young   = motherAge>=25&motherAge<40
replace young = . if motherAge<25|motherAge>45
gen college = educLevel==2 if educLevel!=.
gen educCat = 4 if education==1
replace educCat = 10 if education == 2
replace educCat = 12 if education == 3
replace educCat = 14 if education == 4
replace educCat = 16 if education == 5
replace educCat = 17 if education == 6
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
replace twin    = twin - 1
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
*gen     expectedMonth   = birthMonth + monthsPrem
*replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
*replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
*gene    expectQuarter   = ceil(expectedMonth/3)
*gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     conceptionMonth = birthMonth - round(gestation*7/30.5)
replace conceptionMonth = conceptionMonth + 12 if conceptionMonth<1
gen     expectedMonth   = conceptionMonth + 9
replace expectedMonth   = expectedMonth-12 if expectedMonth>12
gen     expectQuarter   = ceil(expectedMonth/3)
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.

generat age3            = .
replace age3            = 1 if motherAge>=25 & motherAge<35
replace age3            = 2 if motherAge>=35 & motherAge<40
replace age3            = 3 if motherAge>=40 & motherAge<46

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
lab var ART         "Used ART (2012-2013 only)"
lab var young       "Young (aged 25-39)"
lab var expectGoodQ "Intended good season of birth"


local Mum     motherAge married young 
local MumPart college educCat smoker ART

foreach st in Mum Kid MumPart {
    local Kid goodQ expectGoodQ birthweight lbw gestat premature apgar twin fem

    sum ``st''
    estpost tabstat ``st'', statistics(count mean sd min max) columns(statistics)
    esttab using "$SUM/nvss`st'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs

    local Kid goodQ expectGoodQ birthweight lbw gestat premature apgar fem
    preserve
    keep if `keepif' &married!=.&smoker!=.&college!=.&young!=.&twin==0
    sum ``st''
    estpost tabstat ``st'', statistics(count mean sd min max)               /*
    */ columns(statistics)
    esttab using "$SUM/samp`st'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs
    restore
}

********************************************************************************
*** (2b) Subset
********************************************************************************
keep if `keepif'
if `twins'==1 keep if twin == 1
if `twins'==0 keep if twin == 0

***drop goodQuarter
***generate goodQuarter = expectGoodQ
***lab var goodQuarter "Good Quarter"

gen birth = 1

gen period = .
replace period = 1 if year >=2005 & year<=2007
replace period = 2 if year >=2008 & year<=2009
replace period = 3 if year >=2010 & year<=2013


********************************************************************************
*** (2c) Label for clarity
********************************************************************************
lab def aG  1 "Young (25-39) " 2  "Old (40-45) "
lab def aGa 1 "Young " 2  "Old "
lab def aG3 1 "25-34 Years " 2  "35-39 Years" 3 "40-45 Years"
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "Some College +"
lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" /*
*/ 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"

lab val period      pr
lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Binary variable for born Q 2/3 (=1) or Q4/1 (=0)"
lab var ageGroup     "Categorical age group"
lab var period       "Period of time considered (pre/crisis/post)"
lab var educLevel    "Level of education obtained by mother"


********************************************************************************
*** (3) Descriptives by month
*******************************************************************************
preserve
drop if age3==.|conceptionMonth==.
collapse (sum) birth, by(conceptionMonth age3)
lab val conceptionMon mon
lab val age3          ag3
bys age3: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth age3

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)
local line3 lpattern(longdash) lcolor(black) lwidth(thin)

#delimit ;
twoway line birthProportion conceptionMonth if age3==1, `line1' ||
       line birthProportion conceptionMonth if age3==2, `line2' ||
       line birthProportion conceptionMonth if age3==3, `line3'
scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
legend(label(1 "25-34 Year-olds") label(2 "35-39 Year-olds")
       label(3 "40-45 Year-olds")) ytitle("Proportion of All Births") ;
graph export "$OUT/conceptionMonth.eps", as(eps) replace;
#delimit cr
restore

preserve
drop if age3==.|conceptionMonth==.
collapse (sum) birth, by(conceptionMonth age3)
lab val conceptionMon mon
lab val age3          ag3
bys age3: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth age3
gen expected = .
local days 31 28.25 31 30 31 30 31 31 30 31 30 31
local i = 1
foreach d of local days {
    replace expected = `d' if conceptionMonth == `i'
    local ++i
}
replace expected = expected/365.25
replace birthProportion = birthProportion - expected

#delimit ;
twoway line birthProportion conceptionMonth if age3==1, `line1' ||
       line birthProportion conceptionMonth if age3==2, `line2' ||
       line birthProportion conceptionMonth if age3==3, `line3'
scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
legend(label(1 "25-34 Year-olds") label(2 "35-39 Year-olds")
       label(3 "40-45 Year-olds")) ytitle("Excess Births");
graph export "$OUT/conceptionMonthWeighted.eps", as(eps) replace;
#delimit cr
restore

preserve
drop if age3==.|conceptionMonth==.
keep if ART==1
collapse (sum) birth, by(conceptionMonth age3)
lab val conceptionMon mon
lab val age3          ag3
bys age3: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth age3

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)
local line3 lpattern(longdash) lcolor(black) lwidth(thin)

#delimit ;
twoway line birthProportion conceptionMonth if age3==1, `line1' ||
       line birthProportion conceptionMonth if age3==2, `line2' ||
       line birthProportion conceptionMonth if age3==3, `line3'
scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
legend(label(1 "25-34 Year-olds") label(2 "35-39 Year-olds")
       label(3 "40-45 Year-olds")) ytitle("Proportion of All Births") ;
graph export "$OUT/conceptionMonthART.eps", as(eps) replace;
#delimit cr
restore

preserve
drop if age3==.|conceptionMonth==.
keep if ART==1
collapse (sum) birth, by(conceptionMonth age3)
lab val conceptionMon mon
lab val age3          ag3
bys age3: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth age3
gen expected = .
local days 31 28.25 31 30 31 30 31 31 30 31 30 31
local i = 1
foreach d of local days {
    replace expected = `d' if conceptionMonth == `i'
    local ++i
}
replace expected = expected/365.25
replace birthProportion = birthProportion - expected

#delimit ;
twoway line birthProportion conceptionMonth if age3==1, `line1' ||
       line birthProportion conceptionMonth if age3==2, `line2' ||
       line birthProportion conceptionMonth if age3==3, `line3'
scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
legend(label(1 "25-34 Year-olds") label(2 "35-39 Year-olds")
       label(3 "40-45 Year-olds")) ytitle("Excess Births");
graph export "$OUT/conceptionMonthWeightedART.eps", as(eps) replace;
#delimit cr
restore

tab young
preserve
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
drop if age3==.
collapse premature, by(age3)
#delimit ;
graph bar premature, ylabel(0.07(0.01)0.14, nogrid) exclude0
over(age3, relabel(1 "25-34 Year-olds" 2 "35-39 Year-olds" 3 "40-45 Year-olds"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))
scheme(s1mono) ytitle("% Premature");
graph export "$OUT/prematureAges.eps", as(eps) replace;
#delimit cr
restore

gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngMont = .
foreach num of numlist 1(1)12 {
    gen month`num' = birthMonth == `num'
    qui reg month`num' young
    replace youngBeta = _b[young] in `num'
    replace youngHigh = _b[young] + 1.96*_se[young] in `num'
    replace youngLoww = _b[young] - 1.96*_se[young] in `num'
    replace youngMont = `num' in `num'
}
lab def Month   1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun"  /*
             */ 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
lab val youngMont Month
lab val birthMont Month

#delimit ;
twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
legend(order(1 "Young-Old" 2 "95% CI")) xlabel(1(1)12, valuelabels)
xtitle("Month");
graph export "$OUT/youngMonths.eps", as(eps) replace;
#delimit cr

foreach A of numlist 0 1 {
    foreach num of numlist 1(1)12 {
        qui reg month`num' young if ART==`A'
        replace youngBeta = _b[young] in `num'
        replace youngHigh = _b[young] + 1.96*_se[young] in `num'
        replace youngLoww = _b[young] - 1.96*_se[young] in `num'
        replace youngMont = `num' in `num'
    }
    lab val youngMont Month
    lab val birthMont Month

    #delimit ;
    twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
    scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
    legend(order(1 "Young-Old" 2 "95% CI")) xlabel(1(1)12, valuelabels)
    xtitle("Month");
    graph export "$OUT/youngMonthsART`A'.eps", as(eps) replace;
    #delimit cr
}

********************************************************************************
*** (3) Prematurity
********************************************************************************
#delimit ;
hist gestat if gestat>24, frac scheme(s1mono) xtitle("Weeks of Gestation")
width(1) start(25);
graph export "$OUT/gestWeeks.eps", as(eps) replace;

preserve;
collapse premature, by(birthMonth);
twoway bar premature birthMonth, bcolor(black) scheme(s1mono)
xtitle("Month of Birth") xlabel(1(1)12, valuelabels)
ytitle("Proportion of Premature Births") ylabel(0.08(0.005)0.095);
graph export "$OUT/prematureMonth.eps", as(eps) replace;
restore;

preserve;
collapse premature, by(goodQuarter);
drop if goodQuarter==.;
twoway bar premature goodQuarter, bcolor(black) scheme(s1mono)
xtitle("Season of Birth") xlabel(1 2, valuelabels)
ytitle("Proportion of Premature Births") ylabel(0.08(0.005)0.095);
graph export "$OUT/prematureSeason.eps", as(eps) replace;
restore;

preserve;
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
*** (4) Sumstats all periods together
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
drop if educLevel==.|goodQuarter==.
collapse premature ART (sum) birth, by(goodQuarter ageGroup)
bys ageGroup: egen aveprem = mean(premature)
bys ageGroup: egen aveART = mean(ART)
drop premature ART
reshape wide birth, i(ageGroup) j(goodQuarter)
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
exit
********************************************************************************
*** (5a) Global histogram
********************************************************************************
tempfile all educ

preserve
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
*** (5b) Histogram by education level
********************************************************************************
preserve
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
*** (5c) Histogram: All, educ
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

list
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
*** (5d) Histogram for more age groups
********************************************************************************
preserve
use "$DAT/`data'", clear
keep if birthOrder==1&educLevel!=.&motherAge>=20&motherAge<=45

gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<35
replace ageG2 = 3 if motherAge>=35 & motherAge<40
replace ageG2 = 4 if motherAge>=40 & motherAge<46

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen birth = 1

collapse (sum) birth, by(goodQuarter ageG2)
reshape wide birth, i(ageG2) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
keep birth1 ageG2 
replace birth1=birth1*2
list
lab def       aG2 1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45"
lab val ageG2 aG2


#delimit ;
graph bar birth1, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'.eps", as(eps) replace;
#delimit cr
restore

preserve
use "$DAT/`data'", clear
keep if birthOrder==1&educLevel!=.&motherAge>=20&motherAge<=45

gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<35
replace ageG2 = 3 if motherAge>=35 & motherAge<40
replace ageG2 = 4 if motherAge>=40 & motherAge<46

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen birth = 1

keep if ART!=.
gen age2024 = ageG2==1
gen age2534 = ageG2==2
gen age3539 = ageG2==3
replace goodQuarter = goodQuarter*100
foreach Anum of numlist 0 1 {
    reg goodQuarter age2024 age2534 age3539 if ART==`Anum'
    local se2024`Anum' = _se[age2024]
    local se2534`Anum' = _se[age2534]
    local se3539`Anum' = _se[age3539]
    local se4045`Anum' = _se[_cons]
}
replace goodQuarter = goodQuarter/100



collapse (sum) birth, by(goodQuarter ageG2 ART)
reshape wide birth, i(ageG2 ART) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
keep birth1 ageG2 ART
replace birth1=birth1*2
list
lab def       aG2 1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45"
lab val ageG2 aG2

gen seUp   = .
gen seDown = .
foreach Anum of numlist 0 1 {
    replace seUp= birth1+1.96*`se2024`Anum'' if ageG2==1&ART==`Anum'
    replace seUp= birth1+1.96*`se2534`Anum'' if ageG2==2&ART==`Anum'
    replace seUp= birth1+1.96*`se3539`Anum'' if ageG2==3&ART==`Anum'
    replace seUp= birth1+1.96*`se4045`Anum'' if ageG2==4&ART==`Anum'

    replace seDo= birth1-1.96*`se2024`Anum'' if ageG2==1&ART==`Anum'
    replace seDo= birth1-1.96*`se2534`Anum'' if ageG2==2&ART==`Anum'
    replace seDo= birth1-1.96*`se3539`Anum'' if ageG2==3&ART==`Anum'
    replace seDo= birth1-1.96*`se4045`Anum'' if ageG2==4&ART==`Anum'
}

#delimit ;
graph bar birth1 if ART==1, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'ART.eps", as(eps) replace;

twoway bar birth1 ageG2 if ART==1, barw(0.5) ylabel(, nogrid) color(ltblue)
  || rcap seUp seDo ageG2 if ART==1, lcolor(black) yline(0, lpattern("_"))
xlabel(1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45") xtitle(" ") legend(off)
scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'ART.eps", as(eps) replace;


graph bar birth1 if ART==0, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_")) 
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'NoART.eps", as(eps) replace;

twoway bar birth1 ageG2 if ART==0, barw(0.5) color(ltblue) ylabel(, nogrid)
 || rcap seUp seDo ageG2 if ART==0, yline(0, lpattern("_")) lcolor(black) 
xlabel(1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45") xtitle(" ") legend(off)
scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$OUT/birthQdiff_4Ages`app'NoART.eps", as(eps) replace;

#delimit cr

********************************************************************************
*** (6) Birth outcomes by groups
********************************************************************************
local hkbirth birthweight lbw gestation premature vlbw apgar  
local axesN   3100[50]3350 0.04[0.02]0.14 38[0.2]39 0.06[0.02]0.18
if `twins'==1 {
    local axesN 2150[50]2450 0.4[0.05]0.7 34[0.5]36 0.5[0.05]0.8 0.06[0.02]0.14
}

tokenize `axesN'
preserve
collapse `hkbirth', by(goodQuarter ageGroup educLevel)
reshape wide `hkbirth', i(ageGroup educLevel) j(goodQuarter)
drop if educLevel == .

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
*/
********************************************************************************
*** (7) Examine by geographic variation (hot/cold)
********************************************************************************
use "$DAT/nvss1990s", clear
keep if `keepif' & twin==1
gen birth = 1
gen young = motherAge>=25&motherAge<40


***NOTE: 12 is Florida (759,551 births). 31 is Nebraska (125,628 births).
***27 is Minnesota (350,968 births).
keep if stoccfip=="12"|stoccfip=="27"
gen     conceptionMonth = birthMonth - round(gestation*7/30.5)
replace conceptionMonth = conceptionMonth + 12 if conceptionMonth<1
gen     state = ""
replace state = "Florida"    if stoccfip=="12"
replace state = "Minnesota"  if stoccfip=="27"

cap lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" /*
*/ 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"


drop if conceptionMonth==.
collapse (sum) birth, by(conceptionMonth state young)
lab val conceptionMon mon
bys state young: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth state

local line1 lpattern(solid)    lcolor(black)
local line2 lpattern(dash)     lcolor(black) 
local cond1 state=="Florida"  
local cond2 state=="Minnesota"

#delimit ;
twoway line birthProportion conceptionMonth if `cond1'& young==1, `line1' ||
       line birthProportion conceptionMonth if `cond2'& young==1, `line2' 
scheme(s1mono) xtitle("Month of Conception") ytitle("Proportion of All Births") 
legend(label(1 "Florida") label(2 "Minnesota")) xlabel(1(1)12, valuelabels);
graph export "$OUT/conceptionMonthFloridaMinnesota_young.eps", as(eps) replace;

twoway line birthProportion conceptionMonth if `cond1'& young==0, `line1' ||
       line birthProportion conceptionMonth if `cond2'& young==0, `line2' 
scheme(s1mono) xtitle("Month of Conception") ytitle("Proportion of All Births") 
legend(label(1 "Florida") label(2 "Minnesota")) xlabel(1(1)12, valuelabels);
graph export "$OUT/conceptionMonthFloridaMinnesota_old.eps", as(eps) replace;
#delimit cr
exit

insheet using "$USW/usaWeather.txt", delim(";") names clear
rename fips FIPS
destring temp, replace

reshape wide temp, i(state FIPS year month) j(type) string
keep if year>1997&year<=1999

collapse temptmpcst (min) temptminst (max) temptmaxst, by(state FIPS)
tostring FIPS, replace
foreach num in 1 2 4 5 6 8 9 {
    replace FIPS = "0`num'" if FIPS=="`num'"
}
expand 2 if FIPS == "24", gen(expanded)
replace FIPS = "11" if expanded==1
drop expanded
rename temptmpcst meanT
rename temptminst cold
rename temptmaxst hot

tempfile weather
save `weather'


use "$DAT/nvss1998_1999"
keep if birthOrder == 1 & motherAge > 24
gen goodSeason = birthQuarter == 2 | birthQuarter == 3
gen young = motherAge < 40    
collapse goodSeason, by(young stoccfip)

rename stoccfip FIPS
tostring FIPS, replace
foreach num in 1 2 4 5 6 8 9 {
    replace FIPS = "0`num'" if FIPS=="`num'"
}
merge m:1 FIPS using `weather'
drop _merge

lab var goodSeason  "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
lab var hot         "Warmest monthly average (degree F)"
lab var meanT       "Mean monthly temperature (degree F)"

foreach num of numlist 0 1 {
    local age young
    if `num'==0 local age old
    drop if FIPS=="02"

    corr goodSeason cold if young==`num'
    local ccoef = string(r(rho),"%5.3f")
    twoway scatter goodSeason cold if young==`num', mlabel(state) ||      ///
        lfit goodSeason cold if young==`num', scheme(s1mono) lcolor(gs0)  ///
            legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'")
    graph export "$OUT/`age'TempCold.eps", as(eps) replace
    twoway scatter goodSeason hot if young==`num', mlabel(state)  ||      ///
        lfit goodSeason hot if young==`num', scheme(s1mono) lcolor(gs0)   ///
            legend(off) lpattern(dash)
    graph export "$OUT/`age'TempWarm.eps", as(eps) replace
    twoway scatter goodSeason meanT if young==`num', mlabel(state)||      ///
        lfit goodSeason meanT if young==`num', scheme(s1mono) lcolor(gs0) ///
            legend(off) lpattern(dash)
    graph export "$OUT/`age'TempMean.eps", as(eps) replace
}
exit


merge m:1 FIPS using "$DAT/../maps/USdata"
drop if _merge==2
drop _merge

spmap goodSeason if young==1&(FIPS!="02"&FIPS!="15") using "$DAT/../maps/UScoords",/*
*/ id(_ID) fcolor(YlOrRd) legend(symy(*2) symx(*2) size(*2.1))
graph export "$OUT/maps/youngGoodSeason.eps", replace as(eps)

spmap goodSeason if young==0&(FIPS!="02"&FIPS!="15") using "$DAT/../maps/UScoords", /*
*/ id(_ID) fcolor(YlOrRd) legend(symy(*2) symx(*2) size(*2.1))
graph export "$OUT/maps/oldGoodSeason.eps", replace as(eps)



************************************************************************************
*** (X) Close
************************************************************************************
log close
