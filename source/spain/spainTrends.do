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

local data births2007-2013
local FE   i.birthProvince
local se   robust
local cnd  if twin==0

********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if survived1day == 1 & birthOrder == 1 & motherSpanish==1 & twin==0

preserve
keep if married == 1
#delimit ;
twoway hist motherAge if motherAge>24 &motherAge<=45, freq color(gs0)  width(1)  
   ||  hist motherAge if motherAge<=24|motherAge>=45, freq color(gs12) width(1)
xtitle("Mother's Age") legend(label(1 "Estimation Sample") label(2 "<25 or >45"))
ylabel(0 "0" 20000 "20,000" 40000 "40,000" 60000 "60,000" 80000 "80,000",
       angle(0)) scheme(s1mono);
#delimit cr
graph export "$OUT/ageDescriptive.eps", as(eps) replace 
restore


********************************************************************************
*** (2b) Summary Stats Table
********************************************************************************
gen goodBirthQ = birthQuarter == 2 | birthQuarter == 3
lab var motherAge   "Mother's Age"
lab var college     "At least some college"
lab var expectGoodQ "Good season of birth (due date)"
lab var goodBirthQ  "Good season of birth (birth date)"
lab var female      "Female"
lab var birthweight "Birthweight (grams)"
lab var lbw         "Low Birth Weight ($<$2500 g)"
lab var gestation   "Weeks of Gestation"
lab var premature   "Premature ($<$ 37 weeks)" 
lab var young       "Young (aged 25-39)"
lab var educCat     "Years of education"

local Mum     motherAge married young age2024 age2527 age2831 age3239 age4045
local MumPart college educCat
local Kid     goodBirthQ expectGoodQ fem birthweight lbw gestation premature

foreach st in Mum Kid MumPart {
    sum ``st''
    estpost tabstat ``st'', statistics(count mean sd min max) columns(statistics)
    esttab using "$SUM/Spain`st'.tex", title("Descriptive Statistics (Spain)") /*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs

    preserve
    keep if married==1&motherAge>=25&motherAge<=45&college!=.
    sum ``st''
    #delimit ;
    estpost tabstat ``st'', statistics(count mean sd min max) columns(statistics);
    esttab using "$SUM/SpainSmp`st'.tex", title("Descriptive Statistics (Spain)")
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") 
    replace label noobs;
    #delimit cr
    restore
}

keep if married == 1
********************************************************************************
*** (2c) Good season table
********************************************************************************
lab var premature "Premature" 
lab var young     "Aged 25-39"

gen birth         = 1
gen educLevel     = 1 if highEd==0
replace educLevel = 2 if highEd==1
gen ageGroup      = 1 if motherAge>=25&motherAge<40
replace ageGroup  = 2 if motherAge>=40&motherAge<46

lab def aG  1 "Young (25-39) " 2  "Old (40-45) "
lab def eL  1 "No College" 2 "Some College +"
lab val ageGroup    aG
lab val educLevel   eL

preserve
drop if educLevel==.|goodQuarter==.|ageGroup==.
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
replace ag="Young " if ag=="Young (25-39) "
replace ag="Old "   if ag=="Old (40-45) "

egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample.txt", delimiter("&") replace noquote
restore

preserve
drop if goodQuarter==.|ageGroup==.
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

drop if educLevel==.|goodQuarter==.|motherAge<20|motherAge>45
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

collapse premature (sum) birth, by(goodQuarter ageG2)
lab def ag_2 1 "20-24 Years Old" 2 "25-27 Years Old" 3 "28-31 Years Old" /*
*/ 4 "32-39 Years Old" 5 "40-45 Years Old"
lab val ageG2 ag_2

bys ageG2: egen avePrem = mean(premature)
drop premature

reshape wide birth, i(ageG2) j(goodQuarter)
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
*** (3) Good Season Figure by month
********************************************************************************
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
lab def seasn   0 "Q2 or Q3 (Good)" 1 "Q1 or Q4 (Bad)"
lab val youngMont Month
lab val conceptionMonth Month
lab val goodQuarter seasn

#delimit ;
twoway line youngBeta youngMont || rcap youngLoww youngHigh youngMont,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
xaxis(1 2) xtitle("Month of Conception", axis(2))
xlabel(1(1)12, valuelabels axis(2)) legend(order(1 "Young-Old" 2 "95% CI"))
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
        9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month");
graph export "$OUT/youngMonths.eps", as(eps) replace;
#delimit cr

********************************************************************************
*** (4) Graph of good season by age
********************************************************************************
keep if motherAge>=25&motherAge<=45

tab motherAge, gen(_age)
reg goodQuarter _age1-_age15
reg expectGoodQ _age1-_age15

gen ageES = .
gen ageLB = .
gen ageUB = .
gen ageNM = .
foreach num of numlist 1(1)15 {
    replace ageES = _b[_age`num']                     in `num'
    replace ageLB = _b[_age`num']-1.96*_se[_age`num'] in `num'
    replace ageUB = _b[_age`num']+1.96*_se[_age`num'] in `num'
    replace ageNM = `num'+24                          in `num'
}

#delimit ;
twoway line ageES ageNM in 1/15, lpattern(solid) lcolor(black) lwidth(medthick)
|| line ageLB ageNM in 1/15, lpattern(dash)  lcolor(black) lwidth(medium)
|| line ageUB ageNM in 1/15, lpattern(dash)  lcolor(black) lwidth(medium) ||
    scatter ageES ageNM in 1/15, mcolor(black) m(S)
scheme(s1mono) legend(order(1 "Point Estimate" 2 "95 % CI"))
xlabel(25(1)39) xtitle("Mother's Age") ytitle("Proportion Good Season" " ");
graph export "$OUT/goodSeasonAge.eps", as(eps) replace;
#delimit cr


********************************************************************************
*** (5) Proportion of conceptions
********************************************************************************
preserve
generat youngOld = 1 if motherAge>=25&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.|conceptionMonth==.

collapse (sum) birth, by(conceptionMonth youngOld)
lab val conceptionMonth Month
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



********************************************************************************
*** (6) Proportion of conceptions by education
********************************************************************************
preserve
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
keep if youngOld != .
drop if educationM==0 | educationM==. | conceptionMonth==.

generat educlevels = 1 if educationM<=4
replace educlevels = 2 if educationM>4&educationM<7
replace educlevels = 3 if educationM>=7

collapse (sum) birth, by(conceptionMonth youngOld educlevels)
lab val conceptionMonth Month
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

********************************************************************************
*** (7) Weather plots
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

    corr goodQuarter cold if young==`num'
    local ccoef = string(r(rho),"%5.3f")
    twoway scatter goodQuarter cold if young==`num', mlabel(name)  ||      ///
        lfit goodQuarter cold if young==`num', scheme(s1mono) lcolor(gs0)  ///
        legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'")
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
    

********************************************************************************
*** (8) Age Histogram
********************************************************************************
preserve
cap drop ageG2
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
cap drop birth
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

********************************************************************************
*** (9) Prematurity histogram
********************************************************************************
preserve
cap drop ageG2
gen ageG2 = motherAge>=20 & motherAge<46
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46
keep if motherAge>=20&motherAge<=45
collapse premature, by(ageG2)
#delimit ;
graph bar premature, ylabel(0.03(0.01)0.09, nogrid) exclude0
over(ageG2, relabel(1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))
scheme(s1mono) ytitle("% Premature");
graph export "$OUT/prematureAges.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (10) Other Prematurity
********************************************************************************
#delimit ;
hist gestat if gestat>24, frac scheme(s1mono) xtitle("Weeks of Gestation")
width(1) start(25);
graph export "$OUT/gestWeeks.eps", as(eps) replace;

preserve;
collapse premature, by(monthBirth);
twoway bar premature monthBirth, bcolor(black) scheme(s1mono)                
xtitle("Month of Birth") xlabel(1(1)12, valuelabels)                         
ytitle("Proportion of Premature Births") ylabel(0.055(0.0025)0.0625);
graph export "$OUT/prematureMonth.eps", as(eps) replace;
restore;

preserve;
collapse premature, by(goodQuarter);
twoway bar premature goodQuarter, bcolor(black) scheme(s1mono)                
xtitle("Season of Birth") xlabel(1 2, valuelabels)                         
ytitle("Proportion of Premature Births") ylabel(0.055(0.0025)0.065);
graph export "$OUT/prematureSeason.eps", as(eps) replace;
restore;

preserve;
collapse premature, by(goodQuarter ageGroup);
reshape wide premature, i(ageGroup) j(goodQuarter);

graph bar premature*, over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Season") label(2 "Good Season"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid)
exclude0 ylab(0.05(0.01)0.09);
graph export "$OUT/prematureSeasonAge.eps", as(eps) replace;
restore;
#delimit cr


********************************************************************************
*** (X) Close
********************************************************************************
log close

