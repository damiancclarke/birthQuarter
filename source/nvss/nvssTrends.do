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
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssTrends.txt", text replace
cap mkdir "$OUT"

********************************************************************************
*** (2) Open file, plot by age group
********************************************************************************
use "$DAT/nvssAgeQuarter"

foreach group of numlist 1(1)7 {
    local a1 = 15+5*(`group'-1)
    local a2 = 15+5*(`group')-1
    dis "`a1', `a2'"
    #delimit ;
    twoway line pQuarter1 year if ageGroup==`group',
      ||   line pQuarter2 year if ageGroup==`group', lpattern(dash)
      ||   line pQuarter3 year if ageGroup==`group', lpattern(longdash)
      ||   line pQuarter4 year if ageGroup==`group', lpattern(dash_dot)
    scheme(s1mono) xtitle("Year") ytitle("Proportion of All Births")
    legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
    note("Includes all first births (only) for women aged `a1' to `a2'");
    #delimit cr
    graph export "$OUT/nvssTrends`a1'_`a2'.eps", as(eps) replace
}

********************************************************************************
*** (3) Combine one plot for all periods
********************************************************************************
collapse pQuarter*, by(ageGroup)
graph bar pQuarter*, over(ageGroup) stack scheme(s1mono) ylabel(0.25(0.25)1) ///
    legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))          ///
    note("All first births from NVSS data: 1975-2002.")
graph export "$OUT/nvssAverage.eps", as(eps) replace
