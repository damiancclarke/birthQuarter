/* spainTrends.do v0.00          damiancclarke             yyyy-mm-dd:2015-06-19
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses Spanish administrative data (2013), subsets, and generates trends
and summary stats.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/spain"
global OUT "~/investigacion/2015/birthQuarter/results/spain/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/spain/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/spainRegs.txt", text replace
cap mkdir "$OUT"

local qual birthweight lbw vlbw gestation premature cesarean
local data births2007-2013
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (r2 N, fmt(%9.2f %9.0g) label(R-squared Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local FE    i.birthProvince
local se    robust
local cnd   if twin==0

local JulNov 1

********************************************************************************
*** (2a) Open and subset
********************************************************************************
use "$DAT/`data'"
keep if survived1day == 1
keep if parity == 1 & motherSpanish == 1 & ageMother>=25 & ageMother<= 45
destring birthProvince, replace

gen id = birthProvince
merge m:1 id using "$DAT/temperature2012"
drop _merge

********************************************************************************
*** (2b) Generate variables
********************************************************************************
gen ageGroup = 1 if ageMother<40
replace ageGroup = 2 if ageMother>=40


gen professional        = professionM>=2&professionM<=5 if professionM!=. 
gen highEd              = yrsEducMother > 12 & yrsEducMother != .
gen young               = ageGroup  == 1
gen youngXhighEd        = young*highEd
gen youngXbadQ          = young*(1-goodQuarter)
gen highEdXbadQ         = highEd*(1-goodQuarter)
gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
gen vhighEd             = yrsEducMother >= 15 & yrsEducMother != .
gen youngXvhighEd       = young*vhighEd
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
gen     college         = highEd
gen     expectedMonth   = monthBirth + monthsPrem
replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
gen     expectQuarter   = ceil(expectedMonth/3)
gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.

gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.
egen    cold            = rowmin(enero-diciembre)
egen    hot             = rowmax(enero-diciembre)
egen    meanTemp        = rowmean(enero-diciembre)


if `JulNov'==1 {
    drop goodQuarter badQuarter expectG* expectB* Qgood* Qbad* *XbadQ
    
    gen goodQuarter         = monthBirth>=7 & monthBirth<=11
    gen badQuarter          = monthBirth< 7 | monthBirth> 11
    gen expectGoodQ         = expectedMonth >= 7 & expectedMonth<=11 if gest!=.
    gen expectBadQ          = expectedMonth <  7 | expectedMonth> 11 if gest!=.
    gen Qgoodgood           = expectGoodQ==1 & goodQuarter==1 if gest!=.
    gen Qgoodbad            = expectGoodQ==1 & badQuarter ==1 if gest!=.
    gen Qbadgood            = expectBadQ==1  & goodQuarter==1 if gest!=.
    gen Qbadbad             = expectBadQ==1  & badQuarter ==1 if gest!=.
    
    gen youngXbadQ          = young*(1-goodQuarter)
    gen highEdXbadQ         = highEd*(1-goodQuarter)
    gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
}


sum expectGoodQ expectBadQ if young==0
sum Qgoodgood Qgoodbad Qbadgood Qbadbad if young==0


lab var goodQuarter        "Good Season"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Young (aged 25-39)"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var ageGroup           "Categorical age group"
lab var youngXbadQ         "Young$\times$ Bad S"
lab var highEdXbadQ        "College$\times$ Bad S"
lab var youngXhighEdXbadQ  "Young$\times$ College$\times$ Bad S"
lab var vhighEd            "Complete Degree"
lab var youngXvhighEd      "Degree$\times$ Aged 25-39"
lab var professional       "White Collar Job"
lab var married            "Married"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var cesarean           "Cesarean"
lab var lbw                "Low Birth Weight ($<$2500 g)"
lab var premature          "Premature ($<$37 weeks)"
lab var vlbw               "VLBW"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var badExpectGood      "Bad Season (due in good)"
lab var badExpectBad       "Bad Season (due in bad)"
lab var Qgoodbad           "Bad Season (due in good)"
lab var Qbadbad            "Bad Season (due in bad)"
lab var Qbadgood           "Good Season (due in bad)"
lab var college            "Some College +"
lab var ageMother          "Mother's Age"
lab var yrsEducMother      "Years of education"
lab var female             "Female"

********************************************************************************
*** (3) Summary stats
********************************************************************************
preserve
collapse goodQuarter cold hot meanTemp,  by(id name young)
lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average"
lab var hot         "Warmest monthly average"
lab var meanT       "Mean monthly temperature"

foreach num of numlist 0 1 {
    local age young
    if `num'==0 local age old

    twoway scatter goodQuarter cold if young==`num', mlabel(name)  ||      ///
        lfit goodQuarter cold if young==`num', scheme(s1mono) lcolor(gs0)  ///
        legend(off) lpattern(dash)
    graph export "$OUT/`age'TempCold.eps", as(eps) replace
    twoway scatter goodQuarter hot if young==`num', mlabel(name)   ||      ///
        lfit goodQuarter hot if young==`num', scheme(s1mono) lcolor(gs0)   ///
        legend(off) lpattern(dash)
    graph export "$OUT/`age'TempWarm.eps", as(eps) replace
    twoway scatter goodQuarter meanT if young==`num', mlabel(name) ||      ///
        lfit goodQuarter meanT if young==`num', scheme(s1mono) lcolor(gs0) ///
        legend(off) lpattern(dash)
    graph export "$OUT/`age'TempMean.eps", as(eps) replace
}
restore
    

local sumM ageMother young married college yrsEducMother professional 
local sumK goodQuarter birthweight lbw gestat premature female cesarean

foreach sumS in sumM sumK {
    sum ``sumS''
    estpost tabstat ``sumS'', statistics(count mean sd min max) columns(statistics)
    esttab using "$SUM/Spain`sumS'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs
}
lab var lbw       "LBW"
lab var premature "Premature" 
lab var young     "Aged 25-39"

gen birth         = 1
gen educLevel     = 1 if highEd==0
replace educLevel = 2 if highEd==1

lab def aG  1 "Young " 2  "Old "
lab def eL  1 "No College" 2 "Some College +"
lab val ageGroup    aG
lab val educLevel   eL


preserve
collapse premature (sum) birth, by(goodQuarter educLevel ageGroup)
bys educLevel ageGroup: egen avePrem = mean(premature)
drop premature
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
gen str4 prem       = string(aveP, "%04.2f")

drop totalbirths diff rati birth* avePrem

decode ageGroup, gen(ag)
decode educLevel, gen(el)
egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample.txt", delimiter("&") replace noquote
restore

preserve
collapse premature (sum) birth, by(goodQuarter educLevel)
bys educLevel: egen avePrem = mean(premature)
drop premature
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
gen str4 prem       = string(aveP, "%04.2f")

drop totalbirths diff rati birth* avePrem

decode educLevel, gen(el)
order el
drop educLevel
outsheet using "$SUM/JustEduc`app'.txt", delimiter("&") replace noquote
restore


preserve
drop if educLevel==.
collapse premature (sum) birth, by(goodQuarter ageGroup)
bys ageGroup: egen avePrem = mean(premature)
drop premature

reshape wide birth, i( ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
gen str4 prem       = string(aveP, "%04.2f")
drop totalbirths diff rati avePrem

outsheet using "$SUM/FullSample`app'.txt", delimiter("&") replace noquote
restore

foreach var of varlist premature {
    gen _`var'young = `var'       if ageGroup  == 1
    gen _`var'old = `var'         if ageGroup  == 2
    gen _`var'lowEd = `var'       if educLevel == 1
    gen _`var'highEd = `var'      if educLevel == 2
    gen _`var'younglowEd = `var'  if educLevel == 1 & ageGroup == 1
    gen _`var'younghighEd = `var' if educLevel == 2 & ageGroup == 1
    gen _`var'oldlowEd = `var'    if educLevel == 1 & ageGroup == 2
    gen _`var'oldhighEd = `var'   if educLevel == 2 & ageGroup == 2
}
sum _p*
estpost tabstat _p*, statistics(mean sd) columns(statistics)
esttab using "$SUM/spainPrem.tex", title("Premature")/*
*/ cells("mean(fmt(2)) sd(fmt(2))") replace label noobs
drop _p*
    
********************************************************************************
*** (4) Good Season by month
********************************************************************************
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngMont = .
foreach num of numlist 1(1)12 {
    gen month`num' = monthBirth == `num'
    qui reg month`num' young
    replace youngBeta = _b[young] in `num'
    replace youngHigh = _b[young] + 1.96*_se[young] in `num'
    replace youngLoww = _b[young] - 1.96*_se[young] in `num'
    replace youngMont = `num' in `num'
}
lab def Month   1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun"  /*
             */ 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
lab val youngMont Month

#delimit ;
twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
scheme(s1mono) yline(0, lpattern(dot)) legend(order(1 "Young-Old" 2 "95% CI"))
xlabel(1(1)12, valuelabels) xtitle("Month") ytitle("Young-Old");
graph export "$OUT/youngMonths.eps", as(eps) replace;
#delimit cr
    

********************************************************************************
*** (X) Close
********************************************************************************
log close

