/* ipumsTrends.do v0.00          damiancclarke             yyyy-mm-dd:2015-03-10
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes the IPUMS data shared by Climent and Sonia, and calculates summ-
ary figures based on first births by age groups.

The file can be controlled entirely in section one, where globals and locals po-
int to locations on the machine where data files are stored and to where results
should be exported.

The file used here is called:
noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013_nohomo_with_men.dta

contact: damian.clarke@economics.ox.ac.uk


*/

vers 11
clear all    
set more off
cap log close

********************************************************************************
*** (1a) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/ipums/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsSum.txt", text replace
cap mkdir "$OUT"

local data noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013_nohomo_with_men
local legd     legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
local note "Quarters represent the difference between percent of yearly births"

if c(os)=="Unix" local e eps
if c(os)!="Unix" local e pdf

local stateFE 1
local twins   0

if `twins' == 1 local app twins

********************************************************************************
*** (1b) Install additional ado files
********************************************************************************
cap which listtex
if _rc!=0 ssc install listtex

 

********************************************************************************
*** (2a) open file, descriptive graphs
********************************************************************************
use "$DAT/`data'"

keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150
keep if age>=25 & age<=45


histogram age, frac scheme(s1mono) xtitle("Mother's Age")
graph export "$OUT/ageDescriptive.eps", as(eps) replace

lab var educ "Educational Attainment"
foreach g in all young old {
    if `"`g'"'=="young" local cond if age>=25 & age<=39
    if `"`g'"'=="old"   local cond if age>=40 & age<=45

    catplot educ `cond', frac scheme(s1mono)
    graph export "$OUT/educDescriptive`g'.eps", as(eps) replace
}


preserve
gen birth=1
collapse (sum) birth, by(age firstborn_twins)
rename firstborn_twin twin
replace twin=twin+1
bys twin: egen total=sum(birth)
replace birth=birth/total
sort twin age
twoway line birth age if twin==1, || line birth age if twin==2,/*
*/ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion (first birth)")/*
*/ legend(label(1 "Single Births") label(2 "Twin Births")) lpattern(dash)
graph export "$OUT/ageDescriptiveParity.eps", as(eps) replace
restore

gen educLevel = .
replace educLevel = 1 if educ<=6
replace educLevel = 2 if educ>6 & educ<=11

foreach edu of numlist 1 2 {
    if `edu'==1 local title "NoCollege"
    if `edu'==2 local title "SomeCollege"
    local cond if educLevel==`edu'
    
    histogram age `cond', frac scheme(s1mono) xtitle("Mother's Age")
    graph export "$OUT/ageDescriptive`title'.eps", as(eps) replace

    preserve
    keep `cond'
    gen birth=1
    collapse (sum) birth, by(age firstborn_twins)
    rename firstborn_twin twin
    replace twin=twin+1
    bys twin: egen total=sum(birth)
    replace birth=birth/total
    sort twin age
    twoway line birth age if twin==1, || line birth age if twin==2,/*
    */ scheme(s1mono) xtitle("Mother's Age") ytitle("Proportion (first birth)")/*
    */ legend(label(1 "Single Births") label(2 "Twin Births")) lpattern(dash)
    graph export "$OUT/ageDescriptiveParity`title'.eps", as(eps) replace
    restore
}

drop educLevel


********************************************************************************
*** (2b) subset
********************************************************************************
if `twins' == 1 keep if firstborn_twins == 1
if `twins' == 0 keep if firstborn_1 == 1

********************************************************************************
*** (2c) Generate necessary variables
********************************************************************************
gen ageGroup = age>=25 & age<=39
replace ageGroup = 2 if age>=40 & age<=45
drop if ageGroup == 0

gen educLevel = .
replace educLevel = 1 if educ<=6
replace educLevel = 2 if educ>6 & educ<=11

gen birth  = 1
gen period = .
replace period = 1 if year>=2005&year<=2007
replace period = 2 if year>=2008&year<=2009
replace period = 3 if year>=2010&year<=2013

gen goodQuarter = birthqtr1==2|birthqtr1==3 
gen married    = marst==1|marst==2
gen hhincomeSq = hhincome^2
gen female     = sex1==2
count
********************************************************************************
*** (2d) Label for clarity
********************************************************************************
lab def aG  1 "Young" 2  "Old"
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
*** (2e) Collapse to bins counting births to make sumstats over time
********************************************************************************
foreach iter in W Unw {
    if `"`iter'"'=="W"   local ctype sum
    if `"`iter'"'=="Unw" local ctype rawsum
    count
    preserve
    collapse (`ctype') birth [pw=perwt], by(goodQuarter educLevel period ageGroup)

    reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
    reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

    sort educLevel ageGroup 
    #delimit ;
    listtex using "$SUM/Count`iter'eighted`app'.tex", rstyle(tabular) replace
    head("\begin{table}[htpb!]\centering"
         "\caption{`iter'eighted Number of Births per Cell}"
         "\begin{tabular}{llcccccc}\toprule" 
         "&&\multicolumn{2}{c}{\textbf{Pre-Crisis}}&"
         "\multicolumn{2}{c}{\textbf{Crisis}}&"
         "\multicolumn{2}{c}{\textbf{Post-Crisis}}\\"
         "\cmidrule(r){3-4}\cmidrule(r){5-6}"
         "\cmidrule(r){7-8}" "&College& Bad Q&Good Q&Bad Q&Good Q&Bad Q&Good Q\\"
         "\midrule")
    foot("\midrule\multicolumn{8}{p{13cm}}{\begin{footnotesize}\textsc{Notes:}"
         "Pre-Crisis is 2005-2007, crisis is 2008-2009, and post-crisis is "
         "2010-2013. Good Q refers to birth quarters 2 and 3, while Bad Q refers"
         "to quarters 4 and 1.  All numbers reflect `iter'eighted values using the"
         "IPUMS ACS 2005-2013 sample.\end{footnotesize}}\\"
         "\bottomrule\end{tabular}\end{table}");
    #delimit cr
    restore
}

preserve
collapse (sum) birth [pw=perwt], by(goodQuarter educLevel period ageGroup)
reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(1000*birth0/totalbirths)/10
replace birth1=round(1000*birth1/totalbirths)/10
drop totalbirths
reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

#delimit ;
listtex using "$SUM/PropWeighted`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
  "\centering\caption{Percent of Births per Cell (Weighted)}"
  "\begin{tabular}{llcccccc}\toprule" 
  "&&\multicolumn{2}{c}{\textbf{Pre-Crisis}}&"
  "\multicolumn{2}{c}{\textbf{Crisis}}&"
  "\multicolumn{2}{c}{\textbf{Post-Crisis}}\\ \cmidrule(r){3-4}\cmidrule(r){5-6}"
  "\cmidrule(r){7-8}" "&College&Bad Q&Good Q&Bad Q&Good Q&Bad Q& Good Q\\ \midrule")
 foot("\midrule\multicolumn{8}{p{13cm}}{\begin{footnotesize}\textsc{Notes:}"
  "Pre-Crisis is 2005-2007,"
  "crisis is 2008-2009, and post-crisis is 2010-2013.  Good Q refers to birth "
  "quarters 2 and 3, while Bad Q refers to quarters 4 and 1.  All values reflect"
  "the percent of births for this time period, age group and education level."
  "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
restore

********************************************************************************
*** (2f) Sumstats all periods together
********************************************************************************
preserve
collapse (sum) birth [pw=perwt], by(goodQuarter educLevel ageGroup)
reshape wide birth, i(educLevel ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati

#delimit ;
listtex using "$SUM/PropWeightedNoTime`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
  "\centering\caption{Percent of Births per Cell (Weighted, All Years)}"
  "\begin{tabular}{llcccc}\toprule" 
  "Age Group &College&Bad Season&Good Season&Difference&Ratio \\ \midrule")
 foot("\midrule\multicolumn{6}{p{9.5cm}}{\begin{footnotesize}\textsc{Notes:}"
      "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
      "to quarters 4 and 1. All values reflect the percent of births for this"
      "age group and education level."
      "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
drop ageGroup educLevel
outsheet using "$SUM/EducSample`app'.txt", delimiter("&") replace noquote
restore

preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup)
reshape wide birth, i(ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati
#delimit ;
listtex using "$SUM/PropWeightedNoTime2`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
  "\centering\caption{Percent of Births per Cell (Weighted, All Years)}"
  "\begin{tabular}{lcccc}\toprule" 
  "Age Group &Bad Season&Good Season&Difference&Ratio \\ \midrule")
 foot("\midrule\multicolumn{5}{p{9.5cm}}{\begin{footnotesize}\textsc{Notes:}"
      "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
      "to quarters 4 and 1. All values reflect the percent of births for this"
      "age group and education level."
      "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
drop ageGroup
outsheet using "$SUM/FullSample`app'.txt", delimiter("&") replace noquote
restore


********************************************************************************
*** (3a) Global histogram
********************************************************************************
tempfile all educ

preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup)
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
*** (3b) Histogram by education level
********************************************************************************
preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup educLevel)
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
save `educ'
restore

********************************************************************************
*** (3c) Histogram by time period
********************************************************************************
preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup period)
reshape wide birth, i(ageGroup period) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50

#delimit ;
graph bar birth*, over(period,
                       label(angle(45))) over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Quarter") label(2 "Good Quarter"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid) yline(0);
graph export "$OUT/totalPeriod`app'.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (3d) Histogram: All, educ
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
list

#delimit ;
graph bar birth*, over(educLevel, relabel(1 "All" 2 "No College" 3 "1-5 yrs")
                       label(angle(45))) yline(0)
legend(label(1 "Young") label(2 "Old")) ylabel(, nogrid) 
scheme(s1mono) bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0));
graph export "$OUT/birthQdiff`app'.eps", as(eps) replace;
#delimit cr
restore


********************************************************************************
*** (4) Summary stats table
********************************************************************************
replace educLevel = educLevel - 1
    
local vr age educLevel goodQuarter female married hhincome
estpost tabstat `vr', by(ageGro) statistics(mean sd) listwise columns(statistics)
esttab using "$SUM/ipumsSum`app'.txt", replace main(mean) aux(sd) /*
  */ nostar unstack nonote nomtitle nonumber




************************************************************************************
*** (X) Close 
************************************************************************************
log close
