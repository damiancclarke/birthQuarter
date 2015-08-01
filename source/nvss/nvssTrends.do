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
local keepif  birthOrder == 1 & motherAge > 24
local stateFE 0
local twins   0
local lyear   25
if `twins' == 1 local app twins

********************************************************************************
*** (1b) Define run type
********************************************************************************
local a2024  0
local y1213  0
local bord2  0
local over30 0
local fterm  0
local pre4w  0

if `a2024'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/2024/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/2024/sumStats"
    local keepif  birthOrder == 1
    local lyear   20
}
if `y1213'==1 {
    dis "Running only for 2012-2013 (see line 71)" 
    global OUT "~/investigacion/2015/birthQuarter/results/2012/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/2012/sumStats"
    local keepif birthOrder == 1 & year==2012|year==2013
}    
if `bord2'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/bord2/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/bord2/sumStats"
    local keepif  birthOrder == 2 & motherAge > 24
}    
if `over30'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/over30/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/over30/sumStats"
    local keepif  birthOrder == 1 & motherAge > 24 & (education!=6|motherAge>30)
}    
if `fterm'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/fullT/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/fullT/sumStats"
    local keepif  birthOrder == 1 & gestation >=39
}    
if `pre4w'==1 {
    global OUT "~/investigacion/2015/birthQuarter/results/pre4w/graphs" 
    global SUM "~/investigacion/2015/birthQuarter/results/pre4w/sumStats"
    local keepif  birthOrder == 1 & gestation <=35
}    
/*
********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if `keepif'

histogram motherAge, frac scheme(s1mono) xtitle("Mother's Age")
graph export "$OUT/ageDescriptive.eps", as(eps) replace

keep if twin<3

#delimit ;
lab def e 0 "N/A" 1 "Grades 1-8" 2 "Incomplete Highschool" 3 "Complete Highschool"
4 "Incomplete College" 5 "Bachelor's Degree" 6 "Higher Degree";
lab val education e;
#delimit cr
lab var education "Completed Education"
foreach g in all young old {
    if `"`g'"'=="young" local cond if motherAge>=`lyear' & motherAge<=39
    if `"`g'"'=="old"   local cond if motherAge>=40      & motherAge<=45

    catplot education `cond', frac scheme(s1mono)
    graph export "$OUT/educDescriptive`g'.eps", as(eps) replace 
}

preserve
gen birth=1
collapse (sum) birth, by(motherAge twin)
bys twin: egen total=sum(birth)
replace birth=birth/total
sort twin motherAge 
twoway line birth motherAge if twin==1, || line birth motherAge if twin==2,/*
*/ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion (first birth)")/*
*/ legend(label(1 "Single Births") label(2 "Twin Births")) lpattern(dash)  /*
*/ lcolor(gs0)
graph export "$OUT/ageDescriptiveParity.eps", as(eps) replace
restore

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
if `a2024'==1 replace ageGroup = 1 if ageGroup == 0
replace ageGroup  = 1 if ageGroup  == 2
replace ageGroup  = 2 if ageGroup  == 3

foreach edu of numlist 1 2 {
    if `edu'==1 local title "NoCollege"
    if `edu'==2 local title "SomeCollege"
    local cond if educLevel==`edu'
    
    histogram motherAge `cond', frac scheme(s1mono) xtitle("Mother's Age")
    graph export "$OUT/ageDescriptive`title'.eps", as(eps) replace

    preserve
    keep `cond'
    gen birth=1
    collapse (sum) birth, by(motherAge twin)
    bys twin: egen total=sum(birth)
    replace birth=birth/total
    sort twin motherAge
    twoway line birth motherAge if twin==1, || line birth motherAge if twin==2,/*
    */ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion (first birth)")/*
    */ legend(label(1 "Single Births") label(2 "Twin Births")) lpattern(dash)  /*
    */ lcolor(gs0)
    graph export "$OUT/ageDescriptiveParity`title'.eps", as(eps) replace
    restore
}

preserve
gen birth=1
keep if education==5|education==6
collapse (sum) birth, by(motherAge twin)
bys twin: egen total=sum(birth)
replace birth=birth/total
sort twin motherAge 
twoway line birth motherAge if twin==1, || line birth motherAge if twin==2,/*
*/ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion (first birth)")/*
*/ legend(label(1 "Single Births") label(2 "Twin Births")) lpattern(dash)  /*
*/ lcolor(gs0)
graph export "$OUT/ageDescriptiveParityDegree.eps", as(eps) replace
restore

preserve
collapse infertTreat, by(motherAge)
#delimit ;
twoway line infertTreat motherAge, xtitle("Mother's Age") scheme(s1mono)
ytitle("Assisted Reproductive Technology");
#delimit cr
graph export "$OUT/ART.eps", as(eps) replace
restore

preserve
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<35
replace ageG2 = 3 if motherAge>=35 & motherAge<40
replace ageG2 = 4 if motherAge>=40 & motherAge<46
collapse infertTreat, by(ageG2)
lab def       aG2 1 "20-24" 2 "25-34" 3 "35-39" 4 "40-45"
lab val ageG2 aG2
#delimit ;
graph bar infertTreat, over(ageG2)  ylabel(, nogrid) exclude0
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("Proportion ART");
graph export "$OUT/ARTageGroup.eps", as(eps) replace;
#delimit cr
restore


preserve
replace twin = twin - 1
keep twin motherAge educLevel
drop if educLevel==.
collapse twin, by(motherAge educLevel) 
reshape wide twin, i(motherAge) j(educLevel)
twoway line twin1 motherAge, || line twin2 motherAge, lpattern(dash) lcolor(gs0)/*
*/ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion Twins")             /*
*/ legend(label(1 "No College") label(2 "Some College +")) 
graph export "$OUT/twinPrevalence.eps", as(eps) replace
restore


********************************************************************************
*** (2aii) Summary stats table
********************************************************************************
gen young   = ageGroup==1 
gen college = educLevel==2 if educLevel!=.
gen educCat = 4 if education==1
replace educCat = 10 if education == 2
replace educCat = 12 if education == 3
replace educCat = 14 if education == 4
replace educCat = 16 if education == 5
replace educCat = 17 if education == 6
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
replace twin    = twin - 1

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
lab var infertTreat "Used ART (2012-2013 only)"
lab var young       "Young (aged 25-39)"

local Mum     motherAge married young 
local MumPart college educCat smoker infertTreat
local Kid     goodQuarter birthweight lbw gestat premature apgar twin female

foreach stype in Mum Kid MumPart {
    sum ``stype''
    estpost tabstat ``stype'', statistics(count mean sd min max)               /*
    */ columns(statistics)
    esttab using "$SUM/nvss`stype'.tex", title("Descriptive Statistics (NVSS)")/*
    */ cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")  /*
    */ replace label noobs
}

********************************************************************************
*** (2b) Subset
********************************************************************************
if `twins'==1 keep if twin == 1
if `twins'==0 keep if twin == 0

gen birth = 1

gen period = .
replace period = 1 if year >=2005 & year<=2007
replace period = 2 if year >=2008 & year<=2009
replace period = 3 if year >=2010 & year<=2013

********************************************************************************
*** (2c) Label for clarity
********************************************************************************
lab def aG  1 "Young " 2  "Old "
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "Some College +"

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
********************************************************************************
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
lab def months 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" /*
*/ 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
lab val birthMonth months

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

********************************************************************************
*** (5) Prematurity
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
twoway bar premature goodQuarter, bcolor(black) scheme(s1mono)
xtitle("Season of Birth") xlabel(1 2, valuelabels)
ytitle("Proportion of Premature Births") ylabel(0.08(0.005)0.095);
graph export "$OUT/prematureSeason.eps", as(eps) replace;
restore;

preserve;
collapse premature, by(goodQuarter ageGroup);
reshape wide premature, i(ageGroup) j(goodQuarter);

graph bar premature*, over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Season") label(2 "Good Season"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid)
exclude0 ylab(0.08(0.01)0.14);
graph export "$OUT/prematureSeasonAge.eps", as(eps) replace;
restore;
#delimit cr

exit


********************************************************************************
*** (4) Sumstats all periods together
********************************************************************************
preserve
drop if educLevel==.
collapse premature infertTreat (sum) birth, by(goodQuarter educLevel ageGroup)
bys ageGroup educLevel: egen aveprem = mean(premature)
bys ageGroup educLevel: egen aveART = mean(infertTreat)
drop premature infertTreat
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
decode educLevel, gen(el)
egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample`app'.txt", delimiter("&") replace noquote
restore

preserve
drop if educLevel==.
collapse premature infertTreat (sum) birth, by(goodQuarter educLevel)
bys educLevel: egen aveprem = mean(premature)
bys educLevel: egen aveART = mean(infertTreat)
drop premature infertTreat
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
drop if educLevel==.
collapse premature infertTreat (sum) birth, by(goodQuarter ageGroup)
bys ageGroup: egen aveprem = mean(premature)
bys ageGroup: egen aveART = mean(infertTreat)
drop premature infertTreat
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

foreach var of varlist premature infertTreat {
    gen _`var'young = `var'       if ageGroup  == 1
    gen _`var'old = `var'         if ageGroup  == 2
    gen _`var'lowEd = `var'       if educLevel == 1
    gen _`var'highEd = `var'      if educLevel == 2
    gen _`var'younglowEd = `var'  if educLevel == 1 & ageGroup == 1
    gen _`var'younghighEd = `var' if educLevel == 2 & ageGroup == 1
    gen _`var'oldlowEd = `var'    if educLevel == 1 & ageGroup == 2
    gen _`var'oldhighEd = `var'   if educLevel == 2 & ageGroup == 2
}
sum _p* _i*
estpost tabstat _p* _i*, statistics(mean sd) columns(statistics)
esttab using "$SUM/nvssARTPrem.tex", title("ART and Premature")/*
    */ cells("mean(fmt(2)) sd(fmt(2))") replace label noobs
drop _p* _i*


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
legend(label(1 "Young") label(2 "Old")) ylabel(, nogrid)
scheme(s1mono) bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0));
graph export "$OUT/birthQdiff`app'.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (5d) Histogram for more age groups
********************************************************************************
preserve
use "$DAT/`data'", clear
keep if birthOrder==1&educLevel!=.

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

********************************************************************************
*** (7) Examine by geographic variation (hot/cold)
********************************************************************************
insheet using "$USW/usaWeather.txt", delim(";") names
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
    
    twoway scatter goodSeason cold if young==`num', mlabel(state) ||      ///
        lfit goodSeason cold if young==`num', scheme(s1mono) lcolor(gs0)  ///
            legend(off) lpattern(dash)
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
*/

********************************************************************************
*** (8) Time series plot of weather and good season
********************************************************************************
cap mkdir "$OUT/weather"

insheet using "$USW/usaWeather.txt", delim(";") names
rename fips FIPS
destring temp, replace

reshape wide temp, i(state FIPS year month) j(type) string
collapse temptmpcst (min) temptminst (max) temptmaxst, by(state FIPS year)
keep if year>=1971 & year<2000

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
bys state FIPS: egen aveTemp70_90 = mean(meanT)
bys state FIPS: egen aveMin70_90  = mean(cold)
bys state FIPS: egen aveMax70_90  = mean(hot)
bys state FIPS: egen aveMin90s    = mean(cold) if year>1987

tempfile weatherYear
save `weatherYear'


foreach decade in 70s 80s 90s {
    use "$DAT/nvss19`decade'.dta"
    gen young = motherAge>=25&motherAge<40 if motherAge>24
    keep if young!=.
    gen goodSeason = birthQuarter == 2 | birthQuarter == 3
    collapse goodSeason, by(statenat young year)    
    tempfile birth`decade'
    save `birth`decade''
}
clear
append using `birth70s' `birth80s' `birth90s'
merge m:1 statenat using "$DAT/nvssStatesFIPS"
drop _merge

rename stoccfip FIPS
merge m:1 FIPS year using `weatherYear'
**NOTE: merges correctly except for Hawaii (_merge==1) and national (_merge==2)

gen coldState_20 = aveMin70_90<20
gen coldState_15 = aveMin70_90<15
gen coldState_10 = aveMin70_90<10
gen deviation    = cold-aveMin70_90
gen deviation90s = cold-aveMin90s

lab var cold       "Coldest Temperature (degree F)"
lab var goodSeason "Proportion Good Season"

local conds young==1&coldS==1 young==1&coldS==0 young==0&coldS==1 young==0&coldS==0
local names young_cold young_warm old_cold old_warm

drop if young==.
foreach lag of numlist 1 2 {
    bys statenat young (year): gen minLag_`lag'=cold[_n-`lag']
    bys statenat young (year): gen devLag_`lag'=deviation[_n-`lag']
    bys statenat young (year): gen devL90_`lag'=deviation90s[_n-`lag']
    gen deviationGroup_`lag' = .
    gen deviationG90s_`lag'  = .
    foreach num of numlist 1(1)6{
        local min = -20+(5*`num')
        local max = -15+(5*`num')
        dis "`min', `max'"
        replace deviationGroup_`lag' = `num' if devLag_`lag'>=`min'&devLag_`lag'<`max'
        replace deviationG90s_`lag' = `num' if devL90_`lag'>=`min'&devL90_`lag'<`max'
    }
}

lab def dev 1 "-15 to -10" 2 "-10 to -5" 3 "-5 to 0" 4 "0 to 5" 5 "5 to 10" 6 "10 to 15"
lab val deviationGroup_1 dev
lab val deviationGroup_2 dev
lab val deviationG90s_1 dev
lab val deviationG90s_2 dev

foreach lag of numlist 1 2 {
    foreach DG in deviationGroup deviationG90s {
        local opts over(`DG'_`lag') nooutsides box(1, fcolor(white) lcolor(black)) /*
        */ scheme(s1mono) ylabel(,nogrid) medline(lcolor(black) lwidth(thin))
        graph box goodSeason if coldState_20==1&young==1, `opts'
        graph export "$OUT/weather/`DG'ColdYoung_lag`lag'.eps", as(eps) replace
        graph box goodSeason if coldState_20==0&young==1, `opts'
        graph export "$OUT/weather/`DG'WarmYoung_lag`lag'.eps", as(eps) replace
        graph box goodSeason if coldState_20==1&young==0, `opts'
        graph export "$OUT/weather/`DG'ColdOld_lag`lag'.eps", as(eps) replace
        graph box goodSeason if coldState_20==0&young==0, `opts'
        graph export "$OUT/weather/`DG'WarmOld_lag`lag'.eps", as(eps) replace
    }
}
exit
    
foreach x of numlist 20 15 10 {
    preserve
    collapse goodSeason cold, by(coldState_`x' young year)
    keep if young!=.
    tokenize `names'
    foreach c of local conds {
        #delimit ;
        twoway line goodS year if `c', yaxis(1) lpattern(dash) lcolor(black)
        ||     line cold  year if `c', yaxis(2) lcolor(black) scheme(s1mono)
        ytitle("Proportion Good Season")
        ytitle("Coldest Temperature (degree F)", axis(2))
        legend(label(1 "Good Season") label(2 "Coldest Temperature"));
        graph export "$OUT/weather/weather`x'_`1'.eps", as(eps) replace;
        #delimit cr
        macro shift
    }
    restore
}


************************************************************************************
*** (X) Close
************************************************************************************
log close
