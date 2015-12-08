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

local data    nvss2005_2013
local keepif  birthOrder == 1 & motherAge > 24 & motherAge<=45
local stateFE 0
local twins   0
if `twins' == 1 local app twins


********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if birthOrder==1

/*
#delimit ;
twoway hist motherAge if motherAge>24&motherAge<=45, freq color(gs0) width(1) ||
       hist motherAge if motherAge<=24|motherAge>45, freq color(gs12) width(1)
    ylabel( 0 "0" 100000 "100,000" 200000 "200,000" 300000 "300,000" 400000
           "400,000" 500000 "500,000", angle(0)) xtitle("Mother's Age") 
    legend(label(1 "Estimation Sample") label(2 "<25 or >45")) scheme(s1mono);
                                        #delimit cr
graph export "$OUT/ageDescriptive.eps", as(eps) replace
*/
keep if twin<3
/*
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
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46
keep if motherAge>=20&motherAge<=45
collapse ART, by(ageG2)
lab def       aG2 1 "20-24" 2 "25-37" 3 "28-31" 4 "32-39" 5 "40-45"
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
gen college        = educLevel==2 if educLevel!=.
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

/*
local Mum     motherAge married young age2024 age2527 age2831 age3239 age4045
local MumPart college educCat smoker ART

foreach st in Mum Kid MumPart {
    local Kid goodBirthQ expectGoodQ twin fem birthweight lbw gest premature apg

    sum ``st''
    estpost tabstat ``st'', statistics(count mean sd min max) columns(statistics)
    esttab using "$SUM/nvss`st'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs

    local Kid goodBirthQ expectGoodQ fem birthweight lbw gestat premature apgar
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

replace young     = . if motherAge<25|motherAge>45
*/
********************************************************************************
*** (2b) Subset
********************************************************************************
if `twins'==1 keep if twin == 1
if `twins'==0 keep if twin == 0
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

lab val ageGroup    aG0
lab val educLevel   eL

/*
********************************************************************************
*** (3) Descriptives by month
*******************************************************************************
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
keep if motherAge>=25&motherAge<=39
drop if education==. | conceptionMonth==.
gen dropout = education<=2
collapse (sum) birth, by(conceptionMonth dropout)
lab val conceptionMon mon
bys dropout: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort conceptionMonth

#delimit ;
twoway line birthProp conceptionM if dropout==1, lcolor(black) lpattern(dash)
    || line birthProp conceptionM if dropout==0, lcolor(black) lwidth(thick)
xaxis(1 2) scheme(s1mono) xtitle("Expected Month", axis(2))
xlabel(1(1)12, valuelabels axis(1)) xtitle("Month of Conception")
xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May"
       9 "Jun" 10 "Jul" 11 "Aug" 12 "Sep", axis(2)) 
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool or Above"))
ytitle("Proportion of All Births");
#delimit cr
graph export "$OUT/conceptionMonthDropout.eps", as(eps) replace
restore

*/
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

exit

tab young
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
graph bar premature, ylabel(0.07(0.01)0.14, nogrid) exclude0
over(ageG2, relabel(1 "20-24" 2 "25-27" 3 "28-31" 4 "32-39" 5 "40-45"))
bar(1, bcolor(gs0)) bar(2, bcolor(gs0)) bar(3, bcolor(gs0))
scheme(s1mono) ytitle("% Premature");
graph export "$OUT/prematureAges.eps", as(eps) replace;
#delimit cr
restore
*/
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
legend(order(1 "Young-Old" 2 "95% CI")) xlabel(1(1)12, valuelabels)
xtitle("Month");
graph export "$OUT/youngMonths.eps", as(eps) replace;
#delimit cr

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
    legend(order(1 "Young-Old" 2 "95% CI")) xlabel(1(1)12, valuelabels)
    xtitle("Month");
    graph export "$OUT/youngMonthsART`A'.eps", as(eps) replace;
    #delimit cr
}
exit
********************************************************************************
*** (4) Graph of good season by age
********************************************************************************
tab motherAge, gen(_age)
reg goodQuarter _age1-_age15 if motherAge>=25&motherAge<=45

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

*/
preserve
drop if educLevel==.|goodQuarter==.|motherAge<20|motherAge>45
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

collapse premature ART (sum) birth, by(goodQuarter ageG2)
lab def ag_2 1 "20-24 Years Old" 2 "25-37 Years Old" 3 "28-31 Years Old" /*
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
*** (6d) Histogram for more age groups
********************************************************************************
preserve
use "$DAT/`data'", clear
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

*/
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
collapse (sum) birth, by(conceptionMonth bstate young state)
lab val conceptionMon mon
bys bstate young: egen totalBirths = sum(birth)
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
    twoway line birthProportion conceptionMonth if `cond1'& young==1, `line1' ||
           line birthProportion conceptionMonth if `cond2'& young==1, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$OUT/conceptionMonth`hS'Minnesota_young.eps", as(eps) replace;

    twoway line birthProportion conceptionMonth if `cond1'& young==0, `line1' ||
           line birthProportion conceptionMonth if `cond2'& young==0, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$OUT/conceptionMonth`hS'Minnesota_old.eps", as(eps) replace;
    #delimit cr

    local cond2 state=="Wisconsin"
    #delimit ;
    twoway line birthProportion conceptionMonth if `cond1'& young==1, `line1' ||
           line birthProportion conceptionMonth if `cond2'& young==1, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$OUT/conceptionMonth`hS'Wisconsin_young.eps", as(eps) replace;

    twoway line birthProportion conceptionMonth if `cond1'& young==0, `line1' ||
           line birthProportion conceptionMonth if `cond2'& young==0, `line2' 
    scheme(s1mono) xtitle("Month of Conception") xlabel(1(1)12, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$OUT/conceptionMonth`hS'Wisconsin_old.eps", as(eps) replace;
    #delimit cr
}

********************************************************************************
*** (8b) All states
********************************************************************************
tokenize `stat'
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
replace twin=twin-1
keep if birthOrder==1
gen birth = 1
drop ageGroup
gen     ageGroup = 1 if motherAge>=15&motherAge<=19
replace ageGroup = 2 if motherAge>=20&motherAge<=25
replace ageGroup = 3 if motherAge>=25&motherAge<=39
replace ageGroup = 4 if motherAge>=40&motherAge<=45

keep if goodQuarter != .
collapse goodQuarter, by(ageGroup fips state bstate)

gen     young = 1 if ageGroup == 3
replace young = 0 if ageGroup == 4

merge m:1 state using `weather'
drop _merge

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
lab var hot         "Warmest monthly average (degree F)"
lab var meanT       "Mean monthly temperature (degree F)"
format goodQuarter %5.2f
foreach num of numlist 0 1 {
    local age young
    if `num'==0 local age old
    drop if state=="Alaska"

    corr goodQuarter cold if young==`num'
    local ccoef = string(r(rho),"%5.3f")
    twoway scatter goodQuarter cold if young==`num', mlabel(state) ||      ///
        lfit goodQuarter cold if young==`num', scheme(s1mono) lcolor(gs0)  ///
            legend(off) lpattern(dash) note("Correlation coefficient=`ccoef'")
    graph export "$OUT/`age'TempCold.eps", as(eps) replace
    twoway scatter goodQuarter hot if young==`num', mlabel(state)  ||      ///
        lfit goodQuarter hot if young==`num', scheme(s1mono) lcolor(gs0)   ///
            legend(off) lpattern(dash)
    graph export "$OUT/`age'TempWarm.eps", as(eps) replace
    twoway scatter goodQuarter meanT if young==`num', mlabel(state)||      ///
        lfit goodQuarter meanT if young==`num', scheme(s1mono) lcolor(gs0) ///
            legend(off) lpattern(dash)
    graph export "$OUT/`age'TempMean.eps", as(eps) replace
}

drop state
rename bstate state
merge m:1 state using "$DAT/../maps/state_database_clean"
drop _merge
format goodQuarter %5.3f


#delimit ;
spmap goodQuarter if young==1&(fips!=2&fips!=18) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$OUT/maps/youngGoodSeason.eps", replace as(eps);

spmap goodQuarter if young==0&(fips!=2&fips!=18) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$OUT/maps/oldGoodSeason.eps", replace as(eps);

spmap goodQuarter if ageGr==1&(fips!=2&fips!=18) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$OUT/maps/teenGoodSeason.eps", replace as(eps);

#delimit cr



************************************************************************************
*** (X) Close
************************************************************************************
log close
