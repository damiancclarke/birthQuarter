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
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/graphs"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsSum.txt", text replace
cap mkdir "$OUT"

local data noallocatedagesexrelate_women1549_children_01_bio_reshaped_2005_2013


********************************************************************************
*** (2) open file, subset, gen variables
********************************************************************************
use "$DAT/`data'"
keep if firstborn_1 == 1
keep if race==1 & race1==1 & hispan==0 and hispan1==0
keep if bpl<150 & bpl1<150

*gen ageGroup = ceil((age-14)/5)
gen ageGroup = age>=25 & age<=34
replace ageGroup = 2 if age>=35 & age<=39
replace ageGroup = 3 if age>=40 & age<=45
drop if ageGroup == .

lab def AG 1 "25-34" 2 "35-39" 3 "40-45"
lab val ageGroup AG

gen birth = 1
collapse (count) birth, by(birthqtr1 ageGroup year)
reshape wide birth, i(ageGroup year) j(birthqtr1)

foreach num of numlist 1(1)4 {
    rename birth`num' nQuarter`num'
}

egen Total = rowtotal(nQuarter*)
foreach num of numlist 1(1)4 {
    gen pQuarter`num' = nQuarter`num'/Total
}

********************************************************************************
*** (3) label
********************************************************************************
lab var ageGroup  "Mother's age group (5 year bins), labelled"
lab var pQuarter1 "Proportion of births in first quarter"
lab var pQuarter2 "Proportion of births in second quarter"
lab var pQuarter3 "Proportion of births in third quarter"
lab var pQuarter4 "Proportion of births in fourth"
lab var nQuarter1 "Number of births in first quarter"
lab var nQuarter2 "Number of births in second quarter"
lab var nQuarter3 "Number of births in third quarter"
lab var nQuarter4 "Number of births in fourth quarter"

********************************************************************************
*** (4) Summary graphs
********************************************************************************
foreach group of numlist 1(1)7 {
    local a1 = 15+5*(`group'-1)
    local a2 = 15+5*(`group')-1
    dis "`a1', `a2'"
    #delimit ;
    twoway line pQuarter1 year if ageGroup==`group',
      ||   line pQuarter2 year if ageGroup==`group', lpattern(dash)
      ||   line pQuarter3 year if ageGroup==`group', lpattern(longdash)
      ||   line pQuarter4 year if ageGroup==`group', lpattern(dash_dot)
    scheme(s1color) xtitle("Year") ytitle("Proportion of All Births")
    legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
    note("Includes all first births (only) for women aged `a1' to `a2'");
    #delimit cr
    graph export "$OUT/ipumsTrends`a1'_`a2'.eps", as(eps) replace
}


collapse pQuarter*, by(ageGroup)
#delimit ;
graph bar pQuarter*, over(ageGroup) stack scheme(s1color) ylabel(0.25(0.25)1) 
   legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
   note("All first births from ACS IPUMS data: 2005-2013.");
graph export "$OUT/ipumsAverage.eps", as(eps) replace;
#delimit cr
