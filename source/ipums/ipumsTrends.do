/* ipumsTrends.do v0.00          damiancclarke             yyyy-mm-dd:2015-03-10
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes the IPUMS data shared by Climent and Sonia, and calculates summ-
ary figures based on first births by age groups.

The file can be controlled entirely in section one, where globals and locals po-
int to locations on the machine where data files are stored and to where results
should be exported.

The file used here is called:
noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013.dta

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

local data noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013
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
*** (2a) open file, subset
********************************************************************************
use "$DAT/`data'"

if `twins' == 1 keep if firstborn_twins == 1
if `twins' == 0 keep if firstborn_1 == 1
keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150

********************************************************************************
*** (2b) Generate necessary variables
********************************************************************************
gen ageGroup = age>=25 & age<=34
replace ageGroup = 2 if age>=35 & age<=39
replace ageGroup = 3 if age>=40 & age<=45
drop if ageGroup == 0

gen educLevel = .
replace educLevel = 1 if educ<=6
replace educLevel = 2 if educ>6 & educ<=8
replace educLevel = 3 if educ>8 & educ<=11

gen birth  = 1
gen period = .
replace period = 1 if year>=2005&year<=2007
replace period = 2 if year>=2008&year<=2009
replace period = 3 if year>=2010&year<=2013

gen goodQuarter = birthqtr1==2|birthqtr1==3 

********************************************************************************
*** (2c) Label for clarity
********************************************************************************
lab def aG  1 "25-34" 2 "35-39" 3 "40-45"
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "None" 2 "1-3 years" 3 "4-5 years" 

lab val period      pr
lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Binary variable for born Q 2/3 (=1) or Q4/1 (=0)"
lab var ageGroup     "Categorical age group"
lab var period       "Period of time considered (pre/crisis/post)"
lab var educLevel    "Level of education obtained by mother"

********************************************************************************
*** (2d) Collapse to bins counting births to make sumstats over time
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
         "\cmidrule(r){7-8}" "&College& Bad Q&Good Q&Badd Q&Good Q&Bad Q&Good Q\\"
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
*** (2e) Sumstats all periods together
********************************************************************************
preserve
collapse (sum) birth [pw=perwt], by(goodQuarter educLevel ageGroup)
reshape wide birth, i(educLevel ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
drop totalbirths

#delimit ;
listtex using "$SUM/PropWeightedNoTime`app'.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
  "\centering\caption{Percent of Births per Cell (Weighted, All Years)}"
  "\begin{tabular}{llcc}\toprule" 
  "Age Group &College&Bad Quarters&Good Quarters \\ \midrule")
 foot("\midrule\multicolumn{4}{p{9cm}}{\begin{footnotesize}\textsc{Notes:}"
      "Good Quarters refer to birth quarters 2 and 3, while Bad Quarters refer"
      "to quarters 4 and 1. All values reflect the percent of births for this"
      "age group and education level."
      "\end{footnotesize}}\\ \bottomrule\end{tabular}\end{table}");
#delimit cr
restore


********************************************************************************
*** (3a) Global histogram
********************************************************************************
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
graph bar birth*, over(educLevel, relabel(1 "None" 2 "1-3 yrs" 3 "4-5 yrs")
                       label(angle(45))) over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Quarter") label(2 "Good Quarter"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid) yline(0);
graph export "$OUT/totalEduc`app'.eps", as(eps) replace;
#delimit cr
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
*** (4) Concentrate state FE 
********************************************************************************
*preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup year statefip)
gen birthHat
foreach num of numlist 1(1)3 {
    qui reg birth i.statefip
    predict bh if e(sample), residual
    replace birthHat = bh if e(sample)
    drop bh
}


*restore




************************************************************************************
*** (X) Close 
************************************************************************************
log close
