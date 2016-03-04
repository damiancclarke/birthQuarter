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

********************************************************************************
*** (3) Generate
********************************************************************************
gen teacher = twoLevelOcc == "Education, Training, and Library Occupations"
gen mother                = nchild! = 0
gen teacherXmother        = teacher*mother
gen income                = incearn if incearn>0
gen wages                 = incwage if incwage>0
gen logIncome             = log(income)
gen logWage               = log(wages)
gen motherAge2            = motherAge*motherAge

lab var teacher        "Teacher"
lab var mother         "Mother"
lab var teacherXmother "Teacher $\times$ Mother"
lab var income         "Income"
lab var wages          "Earnings"
lab var logIncome      "log(Income)"
lab var logWage        "log(Earnings)"


********************************************************************************
*** (4) Regressions
********************************************************************************
local ctl motherAge motherAge2 highEduc uhrswork i.year
local cnd if motherAge>34
local abs absorb(state)
local se  robust

eststo: areg logWage mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logWage mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg wages   mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeason_all.tex", replace
`estopt' booktabs keep(mother teacher teacherXmother) mlabels(, depvar)
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("Wages, Job Types, and Mothers"\label{tab:IPUMSWages}) 
postfoot("\bottomrule\multicolumn{5}{p{14.6cm}}{\begin{footnotesize}        "
"Sample consists of all white, non-hispanic, married women aged 25-45       "
"included in ACS data, where the woman works in an occupation with at least "
"500 workers in the sample.  Teacher refers to occupational codes 2250-2500 "
" (teachers, librarians and educational occupations).  Wages refer to wage  "
"and salary income, and are measured in dollars per year.  State and year   "
"fixed effects, and controls for mother's age (quadratic), education, and   "
"regular hours worked are included. `enote'                                 "
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc_all.tex", replace
`estopt' booktabs keep(mother teacher teacherXmother) mlabels(, depvar)
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("Wages, Job Types, and Mothers"\label{tab:IPUMSWages}) 
postfoot("\bottomrule\multicolumn{5}{p{14.6cm}}{\begin{footnotesize}        "
"Sample consists of all white, non-hispanic, married women aged 25-45       "
"included in ACS data, where the woman works in an occupation with at least "
"500 workers in the sample.  Teacher refers to occupational codes 2250-2500 "
" (teachers, librarians and educational occupations). Income refers to total"
"personal earned income, and is measured in dollars per year. State and year"
"fixed effects, and controls for mother's age (quadratic), education, and   "
"regular hours worked are included. `enote'                                 "
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
`estopt' booktabs keep(mother teacher teacherXmother) mlabels(, depvar)
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("Wages, Job Types, and Mothers"\label{tab:IPUMSWages}) 
postfoot("\bottomrule\multicolumn{5}{p{14.6cm}}{\begin{footnotesize}        "
"Sample consists of all white, non-hispanic, married women aged 25-45       "
"included in ACS data, where the woman works in an occupation with at least "
"500 workers in the sample.  Teacher refers to occupational codes 2250-2500 "
" (teachers, librarians and educational occupations).  Wages refer to wage  "
"and salary income, and are measured in dollars per year.  State and year   "
"fixed effects, and controls for mother's age (quadratic), education, and   "
"regular hours worked are included. `enote'                                 "
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


eststo: areg logIncome mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt'      , `abs' `se'
eststo: areg logIncome mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'
eststo: areg income    mother teacher teacherXmother `ctl' `wt' `cnd', `abs' `se'

#delimit ;
esttab est1 est2 est3 est4 using "$OUT/ValueGoodSeasonInc.tex", replace
`estopt' booktabs keep(mother teacher teacherXmother) mlabels(, depvar)
mgroups("All" "$\geq$ 35 Years", pattern(1 0 1 0)
prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("Wages, Job Types, and Mothers"\label{tab:IPUMSWages}) 
postfoot("\bottomrule\multicolumn{5}{p{14.6cm}}{\begin{footnotesize}        "
"Sample consists of all white, non-hispanic, married women aged 25-45       "
"included in ACS data, where the woman works in an occupation with at least "
"500 workers in the sample.  Teacher refers to occupational codes 2250-2500 "
" (teachers, librarians and educational occupations). Income refers to total"
"personal earned income, and is measured in dollars per year. State and year"
"fixed effects, and controls for mother's age (quadratic), education, and   "
"regular hours worked are included. `enote'                                 "
"\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
