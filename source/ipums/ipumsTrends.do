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
local legd     legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
local note "Quarters represent the difference between percent of yearly births"
if c(os)=="Unix" local e eps
if c(os)!="Unix" local e pdf

********************************************************************************
*** (2a) open file, subset, gen variables
********************************************************************************
use "$DAT/`data'"
keep if firstborn_1 == 1
keep if race==1 & race1==1 & hispan==0 & hispan1==0
keep if bpl<150 & bpl1<150

*gen ageGroup = ceil((age-14)/5)
gen ageGroup = age>=25 & age<=34
replace ageGroup = 2 if age>=35 & age<=39
replace ageGroup = 3 if age>=40 & age<=45
drop if ageGroup == .

gen college    = educ>=10
gen highschool = educ>=6
gen alleduc    = educ>=0

lab var college    "Complete college or higher (4 years college)"
lab var highschool "Complete highschool or above"
lab var alleduc    "All education levels combined"

lab def AG 1 "25-34" 2 "35-39" 3 "40-45"
lab val ageGroup AG

gen birth = 1

********************************************************************************
*** (3) Total graphs for each age group
********************************************************************************
preserve
collapse (count) birth [pw=perwt], by(birthqtr1 ageGroup year)
drop if ageGroup==0
reshape wide birth, i(ageGroup year) j(birthqtr1)

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


********************************************************************************
*** (4) collapse to year*birth quarter.  Use three samples
********************************************************************************
foreach samp of varlist college highschool alleduc {
    cap mkdir "$OUT/`samp'"

    preserve
    collapse (count) birth [pw=perwt], by(birthqtr1 ageGroup year `samp')
    drop if ageGroup==0
    reshape wide birth, i(ageGroup year `samp') j(birthqtr1)

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
            twoway line pQuarter1 year `cond',
            ||   line pQuarter2 year `cond', lpattern(dash)
            ||   line pQuarter3 year `cond', lpattern(dot)
            ||   line pQuarter4 year `cond', lpattern(dash_dot)
            scheme(s1color) xtitle("Year") ytitle("Proportion of All Births")
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
            graph bar pQuarter* `cond', over(year) scheme(s1color) `legd'
            graph export "$OUT/`samp'/Qtr`a1'_`a2'_`samp'_`n'.`e'", as(`e') replace
            
            foreach num of numlist 1(1)4 {
                replace pQuarter`num'=pQuarter`num'-0.25
            }
            
            graph bar pQuarter* `cond', over(year) scheme(s1color) `legd' /*
            */ note("`note', and 0.25")
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
        graph bar pQuarter* `cond', scheme(s1color) over(`samp') `legd' /*
        */ note("`note', and 0.25")
        graph export "$OUT/`samp'/aveDifQtr`a1'_`a2'_`samp'.`e'", as(`e') replace
        foreach num of numlist 1(1)4 {
            replace pQuarter`num'=pQuarter`num'+0.25
        }
    }
    restore
}

************************************************************************************
*** (X) Convert to pdf if Unix, close 
************************************************************************************
if c(os)=="Unix" {
    cd "$OUT"
    !for i in *.eps; do epstopdf $i; rm $i; done
    foreach samp of varlist college highschool alleduc {    
        cd "`samp'"
        !for i in *.eps; do epstopdf $i; rm $i; done
        cd ".."
    }       
}

log close
