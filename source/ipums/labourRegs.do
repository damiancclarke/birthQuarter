/* labourRegs.do                 damiancclarke             yyyy-mm-dd:2016-02-22
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Use all IPUMS mothers aged 25-45 to examine the differential pay for flexibility
in timing births.

The IPUMS file is named in exactly the same as the full mother file, as it was g
enerated using the same generation script.  
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"


log using "$LOG/labourRegs.txt", text replace

#delimit ;
local data   ACS_20052014_All.dta; 
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
             (N, fmt(%9.0g) label(Observations))
             starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label;
local wt     [pw=perwt]; 
local enote  "Heteroscedasticity robust standard errors are reported in
           parentheses. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.";
#delimit cr


********************************************************************************
*** (2) Open data subset to sample of interest (from Sonia's import file)
********************************************************************************
use "$DAT/`data'"
keep if motherAge>=25 & motherAge <=45
drop if occ2010 == 9920
keep if race==1 & hispan==0

gen educYrs = 0 if educd==2|educd==11|educd==12
replace educYrs = 3 if educd==10
replace educYrs = 1 if educd==14
replace educYrs = 2 if educd==15
replace educYrs = 3 if educd==16
replace educYrs = 4 if educd==17
replace educYrs = 5 if educd==21|educd==22
replace educYrs = 6 if educd==23
replace educYrs = 7 if educd==24
replace educYrs = 7 if educd==25
replace educYrs = 8 if educd==26
replace educYrs = 9 if educd==30
replace educYrs = 10 if educd==40
replace educYrs = 11 if educd==50
replace educYrs = 12 if educd>=61&educd<=64
replace educYrs = 13 if educd==65
replace educYrs = 14 if educd==71|educd==81
replace educYrs = 16 if educd==101
replace educYrs = 17 if educd==114
replace educYrs = 20 if educd==115|educd==116
gen educYrsSq=educYrs*educYrs
lab var educYrs "Years of Education"
lab var educYrsSq "Education Squared"

#delimit ;
gen maternalPolicy = state=="NewJersey"|state=="California";
gen ParentalPolicy = "AB" if state=="California"|state=="Connecticut"|
    state=="DC"|state=="NewJersey"|state=="Hawaii"|state=="Washington"|
    state=="Oregon"|state=="Maine"|state=="NewYork"|state=="Illnois";
replace ParentalPolicy = "F" if state=="Alabama"|state=="Delaware"|
    state=="Georgia"|state=="Idaho"|state=="Kansas"|state=="Michigan"|
    state=="Mississippi"|state=="Missouri"|state=="Nebraska"|
    state=="Nevada"|state=="NorthCarolina"|state=="NorthDakota"|
    state=="Oklahoma"|state=="SouthCarolina"|state=="SouthDakota"|
    state=="Utah"|state=="WestVirginia"|state=="Wyoming";
replace ParentalPolicy = "CDE" if ParentalPolicy == "";
#delimit cr



********************************************************************************
*** (3) Generate
********************************************************************************
gen teacher = twoLevelOcc != "Education, Training, and Library Occupations"
gen mother                = nchild! = 0
gen teacherXmother        = teacher*mother
gen income                = incearn if incearn>0
gen wages                 = incwage if incwage>0
gen logIncome             = log(income)
gen logWage               = log(wages)
gen motherAge2            = motherAge*motherAge/100

lab var teacher        "Non-Teacher"
lab var mother         "Mother"
lab var teacherXmother "Non-Teacher $\times$ Mother"
lab var income         "Earnings"
lab var wages          "Wage Income"
lab var logIncome      "log(Earnings)"
lab var logWage        "log(Wage Inc)"
lab var motherAge      "Age"
lab var motherAge2     "Age$^2$ / 100"
lab var highEduc       "Some College +"

********************************************************************************
*** (4) Regressions
********************************************************************************
local ctl motherAge motherAge2 highEduc uhrswork i.year
local cnd if motherAge>34
local abs absorb(state)
local se  robust
/*
eststo: areg logWage mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logWage mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeason_all.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth (Wage Income)"\label{tab:IPUMSWagesAll}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                              "
         "\bottomrule\multicolumn{5}{p{15.6cm}}{\begin{footnotesize}  Main  "
         "ACS estimation sample is used, augmenting to include un-married   "
         "women.  Teacher refers to occupational codes 2250-2500 (teachers, "
         "librarians and educational occupations).  Wages refer to wage and "
         "salary income, and are measured in dollars per year. A control for"
         "regular hours worked is included. `enote'                         "
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc_all.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth"\label{tab:IPUMSIncAll}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                    "
         "\bottomrule\multicolumn{5}{p{15.6cm}}{\begin{footnotesize}  Main   "
         "ACS estimation sample used, augmenting to include un-married women."
         "Teacher refers to occupational codes 2250-2500 (teachers,          "
         "librarians and educational occupations).  Earnings refers to total "
         "personal earned income, and is measured in dollars per year.  A    "
         "control for regular hours worked is included. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


keep if marst==1

eststo: areg logWage mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logWage mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeason.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth (Wage Income)"\label{tab:IPUMSWages}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                              "
         "\bottomrule\multicolumn{5}{p{15.8cm}}{\begin{footnotesize}  Main  "
         "ACS estimation sample used.  Teacher refers to occupational codes "
         "2250-2500 (teachers, librarians and educational occupations).     "
         "Wages refer to wage and salary income, and are measured in dollars"
         " per year. A control for regular hours worked is included. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth"\label{tab:IPUMSInc}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                   "
         "\bottomrule\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Main "
         "ACS estimation sample is used augmented with non-mothers and    "
         "with mothers of more than one child (or older children). Teacher"
         "refers to occupational codes 2250-2500 (teachers, librarians and"
         "educational occupations). Earnings refer to earned income in the"
         "past 12 months, and are measured in dollars per year. Usual     "
         "weekly hours of work are included as a control variable. `enote'"
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


*/

local nam MLeave NoMLeave PLeaveAB PLeaveCE PLeaveF
tokenize `nam'

foreach num of numlist 1(1)5 {
    if `"`1'"' == "MLeave" local group   maternalPolicy==1
    if `"`1'"' == "NoMLeave" local group maternalPolicy==0
    if `"`1'"' == "PLeaveAB" local group ParentalPolicy=="AB"
    if `"`1'"' == "PLeaveCE" local group ParentalPolicy=="CDE"
    if `"`1'"' == "PLeaveF"  local group ParentalPolicy=="F"
    preserve
    keep if `group'

eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc_`1'.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth"\label{tab:IPUMSInc}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                   "
         "\bottomrule\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Main "
         "ACS estimation sample is used augmented with non-mothers and    "
         "with mothers of more than one child (or older children). Teacher"
         "refers to occupational codes 2250-2500 (teachers, librarians and"
         "educational occupations). Earnings refer to earned income in the"
         "past 12 months, and are measured in dollars per year. Usual     "
         "weekly hours of work are included as a control variable. `enote'"
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
restore
macro shift

}
exit
local ctl motherAge motherAge2 educYrs educYrsSq uhrswork i.year
local cnd if motherAge>34
local abs absorb(state)
local se  robust

eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/EducSq_ValueGoodSeasonInc.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 educYrs educYrsSq) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth"\label{tab:IPUMSInc}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                   "
         "\bottomrule\multicolumn{5}{p{15.8cm}}{\begin{footnotesize} Main "
         "ACS estimation sample is used augmented with non-mothers and    "
         "with mothers of more than one child (or older children). Teacher"
         "refers to occupational codes 2250-2500 (teachers, librarians and"
         "educational occupations). Earnings refer to earned income in the"
         "past 12 months, and are measured in dollars per year. Usual     "
         "weekly hours of work are included as a control variable. `enote'"
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear



exit

local ctl motherAge motherAge2 highEduc i.year
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc_nohours.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth (No Hours Control)"\label{tab:IPUMSIncNoH}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                   "
         "\bottomrule\multicolumn{5}{p{15.6cm}}{\begin{footnotesize}  Main  "
         "ACS estimation sample used.  Teacher refers to occupational codes "
         "2250-2500 (teachers, librarians and educational occupations).     "
         "Earnings refers to total personal earned income, and is measured  "
         "in dollars per year. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


local ctl motherAge motherAge2 highEduc uhrswork i.year i.wkswork2
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc_weeks.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(mother teacher teacherXmother motherAge motherAge2 highEduc) 
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Value of Season of Birth (Weeks Control)"\label{tab:IPUMSIncWeek}) 
postfoot("State and Year FE & Y & Y & Y & Y \\                   "
         "\bottomrule\multicolumn{5}{p{15.6cm}}{\begin{footnotesize}  Main  "
         "ACS estimation sample used.  Teacher refers to occupational codes "
         "2250-2500 (teachers, librarians and educational occupations).     "
         "Earnings refers to total personal earned income, and is measured  "
         "in dollars per year. Controls for regular hours worked and number "
         "of weeks worked in the year are included. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
