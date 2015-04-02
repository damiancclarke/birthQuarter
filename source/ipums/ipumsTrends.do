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

local stateFE 0

if `stateFE'==1 global OUT "$OUT/FE"


********************************************************************************
*** (1b) Install additional ado files
********************************************************************************
cap which listtex
if _rc!=0 ssc install listtex



********************************************************************************
*** (2a) open file, subset
********************************************************************************
use "$DAT/`data'"
keep if firstborn_1 == 1
keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150

********************************************************************************
*** (2b) Generate necessary variables
********************************************************************************
gen ageGroup = age>=25 & age<=34
replace ageGroup = 2 if age>=35 & age<=39
replace ageGroup = 3 if age>=40 & age<=45
drop if ageGroup == 0

*gen college    = educ>=10
*gen highschool = educ>=6
*gen alleduc    = educ>=0

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
*** (2d) Collapse to bins counting births
********************************************************************************
collapse (sum) birth [pw=perwt], by(goodQuarter educLevel period ageGroup)

preserve
reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

sort ageGroup educLevel
#delimit ;
listtex using "$SUM/CountWeighted.tex", rstyle(tabular) replace
 head("\begin{table}[htpb!]\centering\caption{Weighted Number of Births per Cell}"
  "\begin{tabular}{llcccccc}\toprule" 
  "&&\multicolumn{2}{c}{\textbf{Pre-Crisis}}&"
  "\multicolumn{2}{c}{\textbf{Crisis}}&"
  "\multicolumn{2}{c}{\textbf{Post-Crisis}}\\ \cmidrule(r){3-4}\cmidrule(r){5-6}"
  "\cmidrule(r){7-8}" "&College& Bad Q&Good Q&Badd Q&Good Q&Bad Q&Good Q\\ \midrule")
 foot("\midrule\multicolumn{8}{p{13cm}}{\begin{footnotesize}\textsc{Notes:}"
  "Pre-Crisis is 2005-2007,"
  "crisis is 2008-2009, and post-crisis is 2010-2013.  Good Q refers to birth "
  "quarters 2 and 3, while Bad Q refers to quarters 4 and 1.  All numbers reflect"
  "weighted values using the IPUMS variable perwt.\end{footnotesize}}\\"
  "\bottomrule\end{tabular}\end{table}");
#delimit cr

restore

preserve
reshape wide birth, i(educLevel period ageGroup) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(1000*birth0/totalbirths)/10
replace birth1=round(1000*birth1/totalbirths)/10
drop totalbirths
reshape wide birth0 birth1, i(educLevel ageGroup) j(period)

#delimit ;
listtex using "$SUM/PropWeighted.tex", rstyle(tabular) replace
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


exit

********************************************************************************
*** (3) Total graphs for each age group
********************************************************************************
preserve
collapse (count) birth [pw=perwt], by(birthqtr1 ageGroup period statefip)
drop if ageGroup==0
if `stateFE'==1 {
    qui reg birth i.statefip
    drop birth
    predict birth, residuals 
}
collapse (count) birth, by(birthqtr1 ageGroup period)
reshape wide birth, i(ageGroup period) j(birthqtr1)


foreach num of numlist 1(1)4 {
    rename birth`num' nQuarter`num'
}

egen Total = rowtotal(nQuarter*)
foreach num of numlist 1(1)4 {
    gen pQuarter`num' = nQuarter`num'/Total - 0.25
}

graph bar pQuarter*, scheme(s1color) over(ageGro) `legd' note("`note', and 0.25")
graph export "$OUT/aveDifQtrAge.`e'", as(`e') replace
restore

exit
********************************************************************************
*** (4) collapse to year*birth quarter.  Use three samples
********************************************************************************
foreach samp of varlist college highschool alleduc {
    cap mkdir "$OUT/`samp'"

    preserve
    collapse (count) birth [pw=perwt], by(birthqtr1 ageGroup period `samp')
    drop if ageGroup==0
    reshape wide birth, i(ageGroup period `samp') j(birthqtr1)

    foreach num of numlist 1(1)4 {
        rename birth`num' nQuarter`num'
    }

    egen Total = rowtotal(nQuarter*)
    foreach num of numlist 1(1)4 {
        gen pQuarter`num' = nQuarter`num'/Total
    }

    ****************************************************************************
    *** (5) label
    ****************************************************************************
    lab var ageGroup  "Mother's age group (5 year bins), labelled"
    lab var pQuarter1 "Proportion of births in first quarter"
    lab var pQuarter2 "Proportion of births in second quarter"
    lab var pQuarter3 "Proportion of births in third quarter"
    lab var pQuarter4 "Proportion of births in fourth"
    lab var nQuarter1 "Number of births in first quarter"
    lab var nQuarter2 "Number of births in second quarter"
    lab var nQuarter3 "Number of births in third quarter"
    lab var nQuarter4 "Number of births in fourth quarter"
    
    ****************************************************************************
    *** (6) Summary graphs
    ****************************************************************************
    foreach n of numlist 0 1 {
        if `"`samp'"'=="alleduc"&`n'==0 exit
        foreach group of numlist 1(1)3 {
            local a1 = 40
            local a2 = 45
            if `group'==1 {
                local a1=25
                local a2=34        
            }
            if `group'==2 {
                local a1=35
                local a2=39        
            }
            
            dis "`a1', `a2'"
            local cond if ageGroup==`group'&`samp'==`n'
            #delimit ;
            twoway line pQuarter1 period `cond',
            ||   line pQuarter2 period `cond', lpattern(dash)
            ||   line pQuarter3 period `cond', lpattern(dot)
            ||   line pQuarter4 period `cond', lpattern(dash_dot)
            scheme(s1color) xtitle("Time Period") ytitle("Proportion of All Births")
            legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
            note("Includes all first births (only) for women aged `a1' to `a2'");
            #delimit cr
            graph export "$OUT/`samp'/Trend`a1'_`a2'_`samp'_`n'.`e'", as(`e') replace
        }
    }
    ****************************************************************************
    *** (7) plots by year*quarter
    ****************************************************************************
    foreach n of numlist 0 1 {
        if `"`samp'"'=="alleduc"&`n'==0 exit
        foreach group of numlist 1(1)3 {
            local a1 = 40
            local a2 = 45
            if `group'==1 {
                local a1=25
                local a2=34        
            }
            if `group'==2 {
                local a1=35
                local a2=39        
            }
            
            dis "`a1', `a2'"
            local cond if ageGroup==`group'&`samp'==`n'
            graph bar pQuarter* `cond', scheme(s1color) `legd' exclude0 /*
            */ over(period, relabel(1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis")) 
            graph export "$OUT/`samp'/Qtr`a1'_`a2'_`samp'_`n'.`e'", as(`e') replace
            
            foreach num of numlist 1(1)4 {
                replace pQuarter`num'=pQuarter`num'-0.25
            }
            
            graph bar pQuarter* `cond', scheme(s1color) `legd' /*
            */ note("`note', and 0.25") /*
            */ over(period, relabel(1 "Pre-crisis" 2 "Crisis" 3 "Post-crisis"))
            graph export "$OUT/`samp'/difQtr`a1'_`a2'_`samp'_`n'.`e'", as(`e') replace

            foreach num of numlist 1(1)4 {
                replace pQuarter`num'=pQuarter`num'+0.25
            }
            
        }
    }

    ********************************************************************************
    *** (8) Summary plots
    ********************************************************************************
    foreach group of numlist 1(1)3 {
        local a1 = 40
        local a2 = 45
        if `group'==1 {
            local a1=25
            local a2=34        
        }
        if `group'==2 {
            local a1=35
            local a2=39        
        }
        
        collapse pQuarter*, by(ageGroup `samp')
        foreach num of numlist 1(1)4 {
            replace pQuarter`num'=pQuarter`num'-0.25
        }
        
        local cond if ageGroup==`group'
        graph bar pQuarter* `cond', scheme(s1color)  `legd' /*
        */ note("`note', and 0.25") over(`samp', relabel(1 "No `samp'" 2 "`samp'"))
        graph export "$OUT/`samp'/aveDifQtr`a1'_`a2'_`samp'.`e'", as(`e') replace
        foreach num of numlist 1(1)4 {
            replace pQuarter`num'=pQuarter`num'+0.25
        }
    }
    restore
}

************************************************************************************
*** (X) Close 
************************************************************************************
log close
