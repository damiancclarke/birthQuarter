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
local pre4w  1

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
    local keepif  birthOrder == 1 & motherAge > 24
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

********************************************************************************
*** (2a) Use, descriptive graph
********************************************************************************
use "$DAT/`data'"
keep if `keepif'
if `over30'==1 drop if motherAge<30 & education==6

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

********************************************************************************
*** (2aii) Summary stats table
********************************************************************************
gen college = educLevel - 1
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
lab var smoker      "Smoker"

local Mum     motherAge married
local MumPart college educCat smoker
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
*** (3) Sumstats all periods together
********************************************************************************
preserve
drop if educLevel==.
collapse (sum) birth, by(goodQuarter educLevel ageGroup)
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

drop totalbirths diff rati birth*

#delimit ;
listtex using "$SUM/PropNoTime`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
        "\centering\caption{Percent of Births per Cell (All Years)}"
        "\begin{tabular}{llcccc}\toprule"
        "Age Group &College&Bad Quarters&Good Quarters&Difference&Ratio \\ \midrule")
 foot("\midrule\multicolumn{6}{p{9cm}}{\begin{footnotesize}\textsc{Notes:}"
            "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
            "to quarters 4 and 1. All values reflect the percent of births for this"
            "age group and education level."
            "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
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
collapse (sum) birth, by(goodQuarter educLevel)
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

drop totalbirths diff rati birth*

#delimit ;
listtex using "$SUM/PropNoTimeEduc`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
        "\centering\caption{Percent of Births per Cell (All Years)}"
        "\begin{tabular}{lcccc}\toprule"
        "College&Bad Quarters&Good Quarters&Difference&Ratio \\ \midrule")
 foot("\midrule\multicolumn{5}{p{9cm}}{\begin{footnotesize}\textsc{Notes:}"
            "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
            "to quarters 4 and 1. All values reflect the percent of births for this"
            "age group and education level."
            "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
decode educLevel, gen(el)
order el
drop educLevel
outsheet using "$SUM/JustEduc`app'.txt", delimiter("&") replace noquote
restore


preserve
drop if educLevel==.
collapse (sum) birth, by(goodQuarter ageGroup)
reshape wide birth, i( ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati

#delimit ;
listtex using "$SUM/PropNoTime2`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
        "\centering\caption{Percent of Births per Cell (All Years)}"
        "\begin{tabular}{lcccc}\toprule"
        "Age Group &Bad Season&Good Season&Difference&Ratio \\ \midrule")
 foot("\midrule\multicolumn{5}{p{9.5cm}}{\begin{footnotesize}\textsc{Notes:}"
            "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
            "to quarters 4 and 1. All values reflect the percent of births for this"
            "age group and education level."
            "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
outsheet using "$SUM/FullSample`app'.txt", delimiter("&") replace noquote
restore


********************************************************************************
*** (4a) Global histogram
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
*** (4b) Histogram by education level
********************************************************************************
preserve
collapse (sum) birth, by(goodQuarter ageGroup educLevel)
reshape wide birth, i(ageGroup educLevel) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50

#delimit ;
graph bar birth*, over(educLevel, relabel(1 "No College" 2 "1-5 yrs")
                                              label(angle(45))) over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Quarter") label(2 "Good Quarter"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid) yline(0);
graph export "$OUT/totalEduc`app'.eps", as(eps) replace;
#delimit cr
drop if educLevel == .
save `educ'
restore

********************************************************************************
*** (4c) Histogram: All, educ
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
graph bar birth*, over(educLevel, relabel(1 "All" 2 "No College" 3 "1-5 yrs")
                       label(angle(45))) yline(0)
legend(label(1 "Young") label(2 "Old")) ylabel(, nogrid)
scheme(s1mono) bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0));
graph export "$OUT/birthQdiff`app'.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (5) Birth outcomes by groups
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
    graph bar `outcome'*, over(educLevel, relabel(1 "No College" 2 "1-5 years")
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


************************************************************************************
*** (X) Close
************************************************************************************
log close
