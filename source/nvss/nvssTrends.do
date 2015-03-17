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

local legd     legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))
local note "Quarters represent the difference between percent of yearly births"
if c(os)=="Unix" local e eps
if c(os)!="Unix" local e pdf


********************************************************************************
*** (2) Open file, plot by age group
********************************************************************************
foreach samp in all college highschool {
    cap mkdir "$OUT/`samp'"
    use "$DAT/nvssAgeQuarter_`samp'", clear
    foreach var of varlist pQuarter* {
        replace `var'=`var'-0.25
    }

    foreach n of numlist 0 1 {
        if `"`samp'"'=="all"&`n'==0 exit

        foreach group of numlist 1(1)3 {
            local a1 = 40
            local a2 = 45
            if `group'==1 local a1 = 25
            if `group'==1 local a2 = 34
            if `group'==2 local a1 = 35
            if `group'==2 local a2 = 39
    
            dis "`a1', `a2'"
            local cond if ageGroup==`group' & `samp'==`n'
            #delimit ;
            twoway line pQuarter1 year `cond',
            ||   line pQuarter2 year `cond', lpattern(dash)
            ||   line pQuarter3 year `cond', lpattern(dot)
            ||   line pQuarter4 year `cond', lpattern(dash_dot)
            scheme(s1color) xtitle("Year") ytitle("Proportion of All Births")
            `legd'
            note("Includes all first births (only) for women aged `a1' to `a2'");
            #delimit cr
            graph export "$OUT/`samp'/Trend`a1'_`a2'_`samp'_`n'.eps", as(eps) replace
        }
    }

    ****************************************************************************
    *** (3) plots by year*quarter
    ****************************************************************************
    foreach n of numlist 0 1 {
        if `"`samp'"'=="all"&`n'==0 exit
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
                
            graph bar pQuarter* `cond', scheme(s1color) `legd' note("`note', and 0.25") /*
            */ over(year, relabel(1 "1975" 2 " " 3 " " 4 " " 5 " " 6 "1980" 7 " " 8 " " /*
            */ 9 " " 10 " " 11 "1985" 12 " " 13 " " 14 " " 15 " " 16 "1990" 17  " " 18  /*
            */ " " 19 " " 20  " " 21 "1995" 22 " " 23 " " 24 " " 25 " " 26 "2000" 27 " "/*
            */ 28 " " 29 " " 30 " " 31 "2005" 32 " " 33 " " 34 " ")) 
            graph export "$OUT/`samp'/difQtr`a1'_`a2'_`samp'_`n'.`e'", as(`e') replace                
        }
    }


    ********************************************************************************
    *** (4) Summary plots
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
        
        local cond if ageGroup==`group'
        graph bar pQuarter* `cond', scheme(s1color)  `legd' /*
        */ note("`note', and 0.25") over(`samp', relabel(1 "`samp'" 2 "No `samp'"))
        graph export "$OUT/`samp'/aveDifQtr`a1'_`a2'_`samp'.`e'", as(`e') replace
    }
}

********************************************************************************
*** (X) Close
********************************************************************************
log close
