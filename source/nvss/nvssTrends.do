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

local stateFE 0
local twins   0
if `twins' == 1 local app twins


********************************************************************************
*** (2a) Use, subset
********************************************************************************
use $DAT/nvss2005_2013

if `twins'==1 keep if twin == 2
if `twins'==0 keep if twin == 1

gen birth = 1
gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen period = .
replace period = 1 if year >=2005 & year<=2007
replace period = 2 if year >=2008 & year<=2009
replace period = 3 if year >=2010 & year<=2013

replace educLevel = educLevel + 1
replace educLevel = 2 if educLevel == 3
replace ageGroup  = 1 if ageGroup  == 2
replace ageGroup  = 2 if ageGroup  == 3

********************************************************************************
*** (2b) Label for clarity
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def pr  1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years"

lab val period      pr
lab val ageGroup    aG
lab val goodQuarter gQ
lab val educLevel   eL

lab var goodQuarter  "Binary variable for born Q 2/3 (=1) or Q4/1 (=0)"
lab var ageGroup     "Categorical age group"
lab var period       "Period of time considered (pre/crisis/post)"
lab var educLevel    "Level of education obtained by mother"


********************************************************************************
*** (3) Collapse to bins counting births to make sumstats over time
********************************************************************************
count
preserve
drop if educLevel==.
collapse (sum) birth, by(goodQuarter educLevel period ageGroup)

reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

sort educLevel ageGroup
#delimit ;
listtex using "$SUM/Count.tex", rstyle(tabular) replace
head("\begin{table}[htpb!]\centering"
     "\caption{Number of Births per Cell}"
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
     "to quarters 4 and 1. All numbers are calculated based on all recorded"
     "births in the national vital statistics system (birth certificate) data"
     "from 2005-2013.\end{footnotesize}}\\"
     "\bottomrule\end{tabular}\end{table}");
#delimit cr
restore

preserve
drop if educLevel==.
collapse (sum) birth, by(goodQuarter educLevel period ageGroup)
reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(1000*birth0/totalbirths)/10
replace birth1=round(1000*birth1/totalbirths)/10
drop totalbirths
reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

#delimit ;
listtex using "$SUM/Proportion.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
        "\centering\caption{Percent of Births per Cell}"
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
drop if educLevel==.
collapse (sum) birth, by(goodQuarter educLevel ageGroup)
reshape wide birth, i(educLevel ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
drop totalbirths

#delimit ;
listtex using "$SUM/PropNoTime.tex", rstyle(tabular) replace
 head("\vspace{8mm}\begin{table}[htpb!]"
        "\centering\caption{Percent of Births per Cell (All Years)}"
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
restore

********************************************************************************
*** (3b) Histogram by education level
********************************************************************************
preserve
collapse (sum) birth, by(goodQuarter ageGroup educLevel)
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
collapse (sum) birth, by(goodQuarter ageGroup period)
reshape wide birth, i(ageGroup period) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50

#delimit ;
graph bar birth*, over(period, label(angle(45))) over(ageGroup)
scheme(s1mono) legend(label(1 "Bad Quarter") label(2 "Good Quarter"))
bar(2, bcolor(gs0)) bar(1, bcolor(white) lcolor(gs0)) ylabel(, nogrid) yline(0);
graph export "$OUT/totalPeriod`app'.eps", as(eps) replace;
#delimit cr
restore


exit
********************************************************************************
*** (4) Concentrate state FE
********************************************************************************
preserve
collapse (sum) birth [pw=perwt], by(goodQuarter ageGroup year statefip)
gen birthHat = .
foreach num of numlist 1(1)3 {
        qui reg birth i.statefip
            predict bh if e(sample), residual
            replace birthHat = bh if e(sample)
            drop bh
    }
collapse birthHat, by(goodQuarter ageGroup)
reshape wide birthHat, i(ageGroup) j(goodQuarter)
gen totalbirths = birthHat0 + birthHat1
replace birthHat0=(round(10000*birthHat0/totalbirths)/100)
replace birthHat1=(round(10000*birthHat1/totalbirths)/100)


restore




************************************************************************************
*** (X) Close
************************************************************************************
log close
