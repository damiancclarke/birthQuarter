/* ipumsRegs.do v0.00            damiancclarke             yyyy-mm-dd:2015-04-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses cleaned IPUMS data and runs regression of birth quarter on matern
al characteristics (including labour market) to examine season of birth choices.
The cleaning file is located in ../dataPrep/ipumsPrep.do.
*/

vers 11
clear all
set more off
cap log close
set matsize 2000

local allobs  1
local hisp    1
local allrace 1
if `allobs' == 0&`allrace'==0         local mnote " married "
if `allobs' == 0&`allrace'==0         local f "ipums/"
if `allobs' == 1&`allrace'==0         local f "ipums/both/"
if `hisp'==1   &`allrace'==0          local f "hisp/ipums/"
if `hisp'==1&`allobs'==1&`allrace'==0 local f "hispall/ipums/" 
if `allrace'==1&`allobs'==1           local f "raceall/ipums/"
if `allrace'==1&`allobs'==0           local f "race/ipums/"
cap mkdir "~/investigacion/2015/birthQuarter/results/`f'"

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/`f'regressions"
global GRA "~/investigacion/2015/birthQuarter/results/`f'graphs"
global SUM "~/investigacion/2015/birthQuarter/results/`f'sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace
cap mkdir "$OUT"
cap mkdir "$GRA"
cap mkdir "$SUM"

#delimit ;
local data   ACS_20052014_cleaned.dta;
if `hisp'==1    local data   ACS_20052014_cleaned_hisp.dta;
if `allrace'==1 local data   ACS_20052014_cleaned_all.dta;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats 
             (N, fmt(%9.0g) label(Observations))     
             starlevel ("*" 0.1 "**" 0.05 "***" 0.01) collabels(none) label;
local wt     [pw=perwt];
local enote  "Heteroscedasticity robust standard errors are reported in 
            parentheses. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.";
local Fnote  "F-test of age variables refers to the p-value on the test that
              the coefficients on mother's age and age squared are jointly equal
              to zero. ";
local onote  "Optimal age calculates the turning point of the mother's age
              quadratic. ";
#delimit cr

local agecond motherAge>=25&motherAge<=45
if `allrace'==1 local agecond motherAge>=20&motherAge<=45

********************************************************************************
*** (2) Open data subset to sample of interest (from Sonia's import file)
********************************************************************************
use "$DAT/`data'"
keep if `agecond'&twins==0
if `allobs' == 0 keep if marst==1
drop if occ2010 == 9920
tab year    , gen(_year)
tab statefip, gen(_state)

lab var unemployment "Unemployment Rate"
bys twoLevelOcc: gen counter = _N
keep if counter>499
drop counter

gen young = motherAge>=25&motherAge<=39
lab var young "Aged 25-39"

gen motherAge2      = motherAge*motherAge/100
lab var motherAge       "Mother's Age"
lab var motherAge2      "Mother's Age$^2$ / 100"

levelsof twoLevelOcc, local(occupations)
gen tstat = .
foreach occ of local occupations {
    reg goodQuarter if twoLevelOcc==`"`occ'"'
local val = string(_b[_cons]/_se[_cons], "%5.3f")
    replace tstat = `val' if twoLevelOcc==`"`occ'"'
}

preserve
gen observations = 1
collapse tstat (sum) observations, by(goodQuarter twoLevelOcc)
drop tstat

reshape wide observations, i(twoLevelOcc) j(goodQuarter)
levelsof twoLevelOcc, local(occupations)
replace twoLevelOcc = subinstr(twoLevelOcc, "Occupations", "", 1)
rename twoLevelOcc Occupations
rename observations0 Bad_Season
rename observations1 Good_Season

list, noobs separator(30) table

restore


********************************************************************************
*** (3a) regressions: Birth Quarter
********************************************************************************
local se  robust
local abs abs(statefip)
local age motherAge motherAge2 
local edu highEduc

local v1 `age' `edu'  _year* _state*
local v2 `age' `edu'  _year*
local v3 `age'        _year*
local v4 `age'                   

eststo: areg goodQuarter `v1'      `wt', abs(occ) `se'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

foreach num of numlist 2 3 {
    eststo: areg goodQuarter `v`num'' if e(sample) `wt', `abs' `se'
    test  `age'
    local F`num' = round(r(p)*1000)/1000
    if   `F`num'' == 0 local F`num' 0.000
    local opt`num' = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
}
eststo: reg goodQuarter `v4' if e(sample) `wt', `se'
test `age'
local F4 = round(r(p)*1000)/1000

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/IPUMSBinary.tex", replace `estopt'
title("Season of Birth Correlates (IPUMS 2005-2014)"\label{tab:IPUMSBinary})
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Variables&0`F4'&0`F3'&0`F2'&0`F1' \\                   "
         "Optimal Age &`opt4'&`opt3'&`opt2'&`opt1' \\                          "
         "State and Year FE&&Y&Y&Y\\ Occupation FE&&&&Y\\ \bottomrule          "
         "\multicolumn{5}{p{15.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children in the US to white, non-hispanic, married        "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         "the head of the household or the partner of the head of the          "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Age 40-45 is the omitted base category. `Fnote'`onote'`enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (3b) regressions: Birth Quarter (robustness)
********************************************************************************
local se  robust
local abs abs(statefip)
local age motherAge motherAge2
local edu highEduc
local une unemployment

local v1 `age' `edu' `une' _year* _state* i.statefip#c.year
local v2 `age' `edu' `une' _year* _state* i.statefip#c.year
local v3 `age' `edu' `une' _year* _state* 
local v4 `age' `edu'       _year* _state* i.statefip#c.year

eststo: areg goodQuarter `v1'      `wt', abs(occ) `se'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

foreach num of numlist 2(1)4 {
    eststo: reg goodQuarter `v`num'' if e(sample) `wt', `se'
   test `age'
    local F`num' = round(r(p)*1000)/1000
    if   `F`num'' == 0 local F`num' 0.000    
    local opt`num' = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

}

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/IPUMSBinary_Robust.tex", replace
`estopt' title("Season of Birth Correlates (Robustness)"\label{tab:IPUMSRobust})
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Variables&0`F4'&0`F3'&0`F2'&0`F1' \\                   "
         "Optimal Age &`opt4'&`opt3'&`opt2'&`opt1' \\                          "
         "State and Year FE&Y&Y&Y&Y\\ State Linear Trends&Y& &Y&Y\\            "
         "Occupation FE&&&&Y\\                          \bottomrule            "
         "\multicolumn{5}{p{15.4cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the US to white, non-hispanic married        "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Age 40-45 is the omitted base category. `Fnote'`onote'`enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (4a) regressions: industry
********************************************************************************
tab twoLevelOcc, gen(_2occ)
tab occ        , gen(_occ)

local se  robust
local abs abs(statefip)
local age motherAge motherAge2
local edu highEduc 
if `hisp'==1             local edu highEduc hispanic
if `hisp'==1&`allobs'==1 local edu highEduc hispanic married
if `allrace'==1             local edu highEduc hispanic black white
if `allrace'==1&`allobs'==1 local edu highEduc hispanic black white married

local une unemployment
local une 
local lv2 _2occ*
drop _2occ2

eststo:  areg goodQuarter `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
local sval = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))
dis `sval'

eststo:  areg goodQuarter `age' `edu' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

#delimit ;
esttab est2 est1 using "$OUT/IPUMSIndustry.tex", replace `estopt' 
title("Season of Birth Correlates: Occupation"\label{tab:Occupation})
keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
postfoot("State and Year Fixed Effects&Y&Y\\                                   "
         "Occupation Codes (level) &-&2\\                                      "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize}Sample consists of all"
         " singleton first-born children in the US to white, non-hispanic      "
         "`mnote' mothers aged 25-45 included in 2005-2014 ACS data where the  "
         "mother is either the head of the household or the partner of the head"
         " of the household and works in an occupation with at least 500       "
         "workers in the sample. Occupation codes refer to the level of        "
         "occupation codes (2 digit, or 3 digit). The omitted occupational     "
         "category in column 2 and column 4 is Arts, Design, Entertainment,    "
         "Sports, and Media, as this occupation has good quarter=0.500(0.500). "
         "F-tests for occupation report p-values of joint significance of the  "
         "dummies, and `Fnote' The Leamer critical value for the t-statistic is"
         "`tL1'.`enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (4b) regressions: industry (by quarter)
********************************************************************************
gen quarter2 = birthQuarter==2
gen quarter3 = birthQuarter==3
gen all      = 1
lab var quarter2 "Quarter 2"
lab var quarter3 "Quarter 3"


local se  robust
local abs abs(statefip)
local age motherAge motherAge2
local edu highEduc
if `hisp'==1             local edu highEduc hispanic
if `hisp'==1&`allobs'==1 local edu highEduc hispanic married
local une unemployment
local une 
local lv2 _2occ*
cap drop _2occ2

foreach Q in 2 3 {
    local conds all==1 cold<23 cold>=23
    tokenize `conds'
    local cnames `" "" "-cold" "-warm" "'
    foreach cnd of local cnames {
        preserve
        keep if `1'
    
        eststo:  areg quarter`Q' `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
        ds _2occ*
        local tvar `r(varlist)'
        test `tvar'
        local F2 = round(r(p)*1000)/1000
        if `F2' == 0 local F2 0.000
        test `age'
        local F2a = round(r(p)*1000)/1000
        local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    
        eststo:  areg quarter`Q' `age' `edu' `une' _year*       `wt', `se' `abs'
        test `age'
        local F3a = round(r(p)*1000)/1000
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
        #delimit ;
        esttab est2 est1 using "$OUT/IPUMSIndustryQ`Q'`cnd'.tex", replace `estopt' 
        title("Season of Birth Correlates: Occupation (Quarter `Q')")
        keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
        postfoot("State and Year Fixed Effects&Y&Y\\                           "
         "Occupation Codes (level) &-&2\\                                      "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize}Sample consists of all"
         " singleton first-born children in the US to white, non-hispanic      "
         "`mnote' mothers aged 25-45 included in 2005-2014 ACS data where the  "
         "mother is either the head of the household or the partner of the head"
         " of the household and works in an occupation with at least 1000      "
         "workers in the sample. Occupation codes refer to the level of        "
         "occupation codes (2 digit, or 3 digit). The omitted occupational     "
         "category in column 2 and column 4 is Arts, Design, Entertainment,    "
         "Sports, and Media, as this occupation has good quarter=0.500(0.500). "
         "F-tests for occupation report p-values of joint significance of the  "
         "dummies, and `Fnote' The Leamer critical value for the t-statistic is"
         "`tL1'. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
        restore
        macro shift
    }
}



********************************************************************************
*** (4c) Industry regressions: add controls 
********************************************************************************
gen logInc = log(hhincome)
lab var logInc "log(household income)"
local inc logInc `edu'  

eststo:  areg goodQuarter `age' `inc' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo:  areg goodQuarter `age' `inc' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

#delimit ;
esttab est2 est1 using "$OUT/IPUMSIndustry_IncEduc.tex", replace `estopt' 
title("Season of Birth Correlates: Occupation (Income/Education Controls)")
keep(_cons `age' `inc' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2\\                                      "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize} Refer to notes in    "
         "table 6 of the main text. The Leamer critical value for the          "
         "t-statistic is `tL1'."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (4d) regressions: industry -- weeks worked
********************************************************************************
cap tab twoLevelOcc, gen(_2occ)
local se  robust
local abs abs(statefip)
local age motherAge motherAge2
local edu highEduc
local lv2 _2occ*

    
gen     weeksWork = 0    if wkswork2 == 0
replace weeksWork = 7    if wkswork2 == 1
replace weeksWork = 20   if wkswork2 == 2
replace weeksWork = 33   if wkswork2 == 3
replace weeksWork = 43.5 if wkswork2 == 4
replace weeksWork = 48.5 if wkswork2 == 5
replace weeksWork = 51   if wkswork2 == 6
lab var weeksWork "Weeks Worked"

gen wkworklow     = 0  if wkswork==0
replace wkworklow = 1  if wkswork==1
replace wkworklow = 14 if wkswork==2
replace wkworklow = 27 if wkswork==3
replace wkworklow = 40 if wkswork==4
replace wkworklow = 48 if wkswork==5
replace wkworklow = 50 if wkswork==6
gen wkworkhigh     = 0  if wkswork==0
replace wkworkhigh = 13 if wkswork==1
replace wkworkhigh = 26 if wkswork==2
replace wkworkhigh = 39 if wkswork==3
replace wkworkhigh = 47 if wkswork==4
replace wkworkhigh = 49 if wkswork==5
replace wkworkhigh = 52 if wkswork==6
lab var wkworklow "Weeks Worked"

cap drop _2occ2
eststo:  areg weeksWork `age' `edu' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000

eststo:  areg weeksWork `age' `edu' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000

#delimit ;
esttab est2 est1 using "$OUT/IPUMSIndustryWeeksWork.tex", replace `estopt' 
title("Weeks of Work Correlates: Occupation"\label{tab:Occupation})
keep(_cons `age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2\\                                      "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize}Sample consists of all"
         " singleton first-born children in the US  to white, non-hispanic     "
	 "married mothers aged 25-45 included in 2005-2014 ACS data where the  "
	 "mother is either the head of the household or the partner of the head"
	 " of the household and works in an occupation with at least 500       "
	 "workers in the sample. Occupation codes refer to the level of        "
	 "occupation codes (2 digit, or 3 digit). The omitted occupational     "
	 "category in column 2 and column 4 is Arts, Design, Entertainment,    "
         "Sports, and Media, as this occupation has good quarter=0.500(0.500). "
         "F-tests for   "
         "occupation report p-values of joint significance of the dummies, and "
         "`Fnote' `onote' `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (5a) regressions: Teachers
********************************************************************************
gen logIncEarn = log(incwage) if incwage>0

local se  robust
local abs abs(statefip)
local age motherAge motherAge2
if `hisp'==1             local age motherAge motherAge2 hispanic
if `hisp'==1&`allobs'==1 local age motherAge motherAge2 hispanic married
local edu highEduc
local une unemployment
local une
local mnv teachers 
local inc logIncEarn
lab var logIncEarn "log(Earnings)"


gen teachers = twoLevelOcc=="Education, Training, and Library Occupations"
lab var teachers "Teacher"
gen teacherXcold = teachers*cold
lab var teacherXcold "Teacher $\times$ Min State Temp"

foreach aa in 2527 2831 3239 {
    gen age`aa'XTeach = age`aa'*teachers
    lab var age`aa'XTeach "Aged `aa' $\times$ Education Occup"
}
cap gen quarter2 = birthQuarter==2
cap gen quarter3 = birthQuarter==3
lab var quarter2 "Quarter 2"
lab var quarter3 "Quarter 3"


eststo: areg goodQuarter `mnv' `age' `edu' _year* `wt', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg goodQuarter `mnv'       `edu'       _year*  `wt', `abs' `se'
eststo: areg goodQuarter             `edu'       _year*  `wt', `abs' `se'
eststo: areg goodQuarter `mnv'                   _year*  `wt', `abs' `se'
eststo:  reg goodQuarter `mnv'                           `wt',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers.tex", replace
title("Season of Birth Correlates: \`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter2 `mnv' `age' `edu' _year* `wt', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter2 `mnv'       `edu'       _year*  `wt', `abs' `se'
eststo: areg quarter2             `edu'       _year*  `wt', `abs' `se'
eststo: areg quarter2 `mnv'                   _year*  `wt', `abs' `se'
eststo:  reg quarter2 `mnv'                           `wt',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-Q2.tex", replace
title("Season of Birth Correlates Quarter 2: \`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter3 `mnv' `age' `edu' _year* `wt', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter3 `mnv'       `edu'       _year*  `wt', `abs' `se'
eststo: areg quarter3             `edu'       _year*  `wt', `abs' `se'
eststo: areg quarter3 `mnv'                   _year*  `wt', `abs' `se'
eststo:  reg quarter3 `mnv'                           `wt',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-Q3.tex", replace
title("Season of Birth Correlates Quarter 3: \`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear



local cnd if cold<23
eststo: areg goodQuarter `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg goodQuarter `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg goodQuarter             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg goodQuarter `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg goodQuarter `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-cold.tex", replace
title("Season of Birth Correlates ($<$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter2 `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter2 `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter2             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter2 `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg quarter2 `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-cold-Q2.tex", replace
title("Season of Birth Correlates Quarter 2 ($<$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter3 `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter3 `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter3             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter3 `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg quarter3 `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-cold-Q3.tex", replace
title("Season of Birth Correlates Quarter 3 ($<$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local cnd if cold>=23
eststo: areg goodQuarter `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg goodQuarter `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg goodQuarter             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg goodQuarter `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg goodQuarter `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-warm.tex", replace
title("Season of Birth Correlates ($\geq$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter2 `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter2 `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter2             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter2 `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg quarter2 `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-warm-Q2.tex", replace
title("Season of Birth Correlates Quarter 2 ($\geq$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg quarter3 `mnv' `age' `edu' _year* `wt' `cnd', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
eststo: areg quarter3 `mnv'       `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter3             `edu'       _year*  `wt' `cnd', `abs' `se'
eststo: areg quarter3 `mnv'                   _year*  `wt' `cnd', `abs' `se'
eststo:  reg quarter3 `mnv'                           `wt' `cnd',       `se'
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")


#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers-warm-Q3.tex", replace
title("Season of Birth Correlates Quarter 3 ($\geq$ -5 Celsius):
\`\`Teachers'' vs.\ \`\`Non-Teachers''")
keep(`mnv' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) `estopt' 
postfoot("F-test of Age Variables &  &    &     &     &0`F2'\\                  "
         "State and Year FE&&Y&Y&Y&Y\\                        \bottomrule       "
         "\multicolumn{6}{p{18.4cm}}{\begin{footnotesize}Main ACS estimation    "
         "sample is used. Teacher refers to individuals employed in ``Education,"
         "Training and Library'' occupations (occupation codes 2200-2550). The  "
         "omitted occupational category is all non-educational occupations.     "
         "`Fnote' The Leamer critical value for the t-statistic is `tL1'.       "
         "Heteroscedasticity robust standard errors are reported in parentheses."
         "clustered by state. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear



********************************************************************************
*** (3g) Twin regression
********************************************************************************
use "$DAT/`data'", clear
keep if marst==1
keep if `agecond'&twins==1
tab year    , gen(_year)
tab statefip, gen(_state)
gen young = motherAge>=25&motherAge<=39
lab var young "Aged 25-39"

lab var unemployment "Unemployment Rate"
gen motherAge2      = motherAge*motherAge
lab var motherAge       "Mother's Age"
lab var motherAge2      "Mother's Age$^2$"


local se  robust 
local abs abs(statefip)
local age motherAge motherAge2
local edu highEduc
local une unemployment
local une 

eststo: areg goodQuarter `age' `edu' `une' _year* _state*      `wt', abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample) `wt', `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample) `wt',          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSBinaryTwin.tex",
replace `estopt' title("Season of Birth Correlates (IPUMS Twins)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born twin children from ACS data who were born to white,      "
         "non-hispanic mothers aged 25-45, where the mother is either the head "
         "of the  household or the partner (married or unmarried) of the head  "
         "of the household.  The omitted age category is 40-45 year old women. "
         "`enote' "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (4) Sumstats of good season by various levels
********************************************************************************
use "$DAT/`data'", clear
if `allobs'==0 keep if marst==1

generat ageGroup        = 1 if motherAge>=25&motherAge<40
replace ageGroup        = 2 if motherAge>=40&motherAge<=45
generat educLevel       = highEduc
replace educLevel       = 2 if educd>=101
gen teachers = occ2010>=2300&occ2010<=2330
lab var teachers "School Teachers"
bys twoLevelOcc: gen counter = _N
keep if counter>499
drop counter


lab def ag 1 "Young (25-39) " 2 "Old (40-45) "
lab def ed 0 "No College" 1 "Some College" 2 "Complete College"
lab val ageGroup ag
lab val educLevel ed

preserve
drop if ageGroup==.

collapse (sum) birth `wt', by(goodQuarter educLevel ageGroup)
reshape wide birth, i(educLevel ageGroup) j(goodQuarter)

gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100

gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str5 b0         = string(birth0, "%05.2f")
gen str5 b1         = string(birth1, "%05.2f")
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")

drop totalbirths diff rati birth*

decode ageGroup, gen(ag)
replace ag = "Young " if ag == "Young (25-39) "
replace ag = "Old "   if ag == "Old (40-45) "
decode educLevel, gen(el)
egen group=concat(ag el)
order group
sort ageGroup educLevel
drop ageGroup educLevel ag el
outsheet using "$SUM/EducSample.txt", delimiter("&") replace noquote
restore


preserve
collapse (sum) birth `wt', by(goodQuarter educLevel)
reshape wide birth, i(educLevel) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100

gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str5 b0         = string(birth0, "%05.2f")
gen str5 b1         = string(birth1, "%05.2f")
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati birth*

decode educLevel, gen(el)
order el
drop educLevel
outsheet using "$SUM/JustEduc.txt", delimiter("&") replace noquote
restore

preserve
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

collapse (sum) birth `wt', by(goodQuarter ageG2)
lab def ag_2 1 "20-24 Years Old" 2 "25-27 Years Old" 3 "28-31 Years Old" /*
*/ 4 "32-39 Years Old" 5 "40-45 Years Old"
lab val ageG2 ag_2

reshape wide birth, i(ageG2) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=round(10000*birth0/totalbirths)/100
replace birth1=round(10000*birth1/totalbirths)/100
gen diff            = birth1 - birth0
gen rati            = birth1 / birth0
gen str4 difference = string(diff, "%04.2f")
gen str4 ratio      = string(rati, "%04.2f")
drop totalbirths diff rati

outsheet using "$SUM/FullSample.txt", delimiter("&") replace noquote
restore


********************************************************************************
*** (5) Sumstats (all)
********************************************************************************
preserve
keep if `agecond'&twins==0
generat young     =   motherAge <=39

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)
 
lab var educYrs   "Years of education"
lab var married   "Married"
lab var young     "Young (aged 25-39)"
lab var highEduc  "Some College +"
lab var goodQuart "Good Season of Birth"
lab var motherAge "Mother's Age"
local his hispanic
if `hisp'==0 local his

#delimit ;
estpost tabstat motherAge married young age2527 age2831 age3239 age4045
                highEduc educYrs goodQuarter `his',
statistics(count mean sd min max) columns(statistics);

esttab using "$SUM/IPUMSstats.tex", title("Descriptive Statistics (NVSS)")
  cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))")
  replace label noobs;
#delimit cr
restore

********************************************************************************
*** (6a) Figure 1
********************************************************************************
preserve
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngQuar = .

generat Xvar = 1 if motherAge>=28&motherAge<=31
replace Xvar = 0 if motherAge>=40&motherAge<=45
foreach num of numlist 1(1)4 {
    gen quarter`num' = birthQuarter == `num'
    qui reg quarter`num' Xvar `wt'
    replace youngBeta = _b[Xvar] in `num'
    replace youngHigh = _b[Xvar] + 1.96*_se[Xvar] in `num'
    replace youngLoww = _b[Xvar] - 1.96*_se[Xvar] in `num'
    replace youngQuar = `num' in `num'
}
lab def Qua 1 "Q1 (Jan-Mar)" 2 "Q2 (Apr-Jun)" 3 "Q3 (Jul-Sep)" 4 "Q4 (Oct-Dec)"
lab val youngQuar       Qua

#delimit ;
twoway line youngBeta youngQuar || rcap youngLoww youngHigh youngQuar,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(order(1 "Young-Old" 2 "95% CI"));
graph export "$GRA/youngQuarter.eps", as(eps) replace;
#delimit cr
restore

preserve
keep if teachers==1
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngQuar = .

generat Xvar = 1 if motherAge>=28&motherAge<=31
replace Xvar = 0 if motherAge>=40&motherAge<=45
foreach num of numlist 1(1)4 {
    gen quarter`num' = birthQuarter == `num'
    qui reg quarter`num' Xvar `wt'
    replace youngBeta = _b[Xvar] in `num'
    replace youngHigh = _b[Xvar] + 1.96*_se[Xvar] in `num'
    replace youngLoww = _b[Xvar] - 1.96*_se[Xvar] in `num'
    replace youngQuar = `num' in `num'
}
lab def Qua 1 "Q1 (Jan-Mar)" 2 "Q2 (Apr-Jun)" 3 "Q3 (Jul-Sep)" 4 "Q4 (Oct-Dec)"
lab val youngQuar       Qua

#delimit ;
twoway line youngBeta youngQuar || rcap youngLoww youngHigh youngQuar,
scheme(s1mono) yline(0, lpattern(dash) lcolor(red)) ytitle("Young-Old")
xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(order(1 "Young-Old" 2 "95% CI"));
graph export "$GRA/youngQuarterTeachers.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (6b) Figure 3 (NVSS)
********************************************************************************
preserve
keep if motherAge>=25
tab motherAge, gen(_age)
reg goodQuarter _age1-_age15 `wt' if motherAge>=25&motherAge<=45

gen ageES = .
gen ageLB = .
gen ageUB = .
gen ageNM = .
foreach num of numlist 1(1)15 {
    replace ageES = _b[_age`num']                     in `num'
    replace ageLB = _b[_age`num']-1.96*_se[_age`num'] in `num'
    replace ageUB = _b[_age`num']+1.96*_se[_age`num'] in `num'
    replace ageNM = `num'+24                          in `num'
}
#delimit ;
twoway line ageES ageNM in 1/15, lpattern(solid) lcolor(black) lwidth(medthick)
    || line ageLB ageNM in 1/15, lpattern(dash)  lcolor(black) lwidth(medium)
    || line ageUB ageNM in 1/15, lpattern(dash)  lcolor(black) lwidth(medium)
    || scatter ageES ageNM in 1/15, mcolor(black) m(S)
    scheme(s1mono) legend(order(1 "Point Estimate" 2 "95 % CI"))
    xlabel(25(1)39) xtitle("Mother's Age") ytitle("Proportion Good Season" " ");
graph export "$GRA/goodSeasonAge.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (6c) Figure 4a
********************************************************************************
preserve
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.

collapse (sum) birth `wt', by(birthQuarter youngOld)
lab val birthQuarter Qua
bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion birthQuarter if youngOld==1, `line1' ||
       line birthProportion birthQuarter if youngOld==2, `line2'
scheme(s1mono) xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$GRA/birthQuarterAges.eps", as(eps) replace;
#delimit cr
restore

preserve
keep if teachers==1
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45

drop if youngOld==.

collapse (sum) birth `wt', by(birthQuarter youngOld)
lab val birthQuarter Qua
bys youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter youngOld

local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProportion birthQuarter if youngOld==1, `line1' ||
       line birthProportion birthQuarter if youngOld==2, `line2'
scheme(s1mono) xtitle("Quarter of Birth") xlabel(1(1)4, valuelabels)
legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
ytitle("Proportion of All Births");
graph export "$GRA/birthQuarterAgesTeachers.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (6d) Figure 5a
********************************************************************************
preserve
cap drop youngOld
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
keep if youngOld != .
generat educlevels = 1 if highEduc==0
replace educlevels = 2 if highEduc==1
replace educlevels = 3 if educd>=101

collapse (sum) birth `wt', by(birthQuarter youngOld educlevels)
lab val birthQuarter Qua
bys educlevels youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter

local line1 lcolor(black) lpattern(dash) lwidth(thin)
local line2 lcolor(black) lwidth(medium) lpattern(longdash)
local line3 lcolor(black) lwidth(thick)

#delimit ;
twoway line birthProp birthQuarter if educlevels==1&youngOld==1, `line1'
    || line birthProp birthQuarter if educlevels==2&youngOld==1, `line2'
    || line birthProp birthQuarter if educlevels==3&youngOld==1, `line3'
scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool,Incomplete College")
       lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$GRA/birthQuarterEducYoung.eps", as(eps) replace;

twoway line birthProp birthQuarter if educlevels==1&youngOld==2, `line1'
    || line birthProp birthQuarter if educlevels==2&youngOld==2, `line2'
    || line birthProp birthQuarter if educlevels==3&youngOld==2, `line3'
scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
ylabel(0.23 0.24 0.25 0.26 0.27)
legend(lab(1 "Incomplete Highschool") lab(2 "Highschool or Incomplete College")
       lab(3 "Complete College")) ytitle("Proportion of All Births");
graph export "$GRA/birthQuarterEducOld.eps", as(eps) replace;
#delimit cr
restore


gen pop=1
********************************************************************************
*** (6e) Figure 6-8
********************************************************************************
#delimit ;
local c1 motherAge>=28&motherAge<=31
         motherAge>=28&motherAge<=31&teachers==1
         motherAge>=28&motherAge<=31&teachers==2
         motherAge>=25&motherAge<=39
         motherAge>=25&motherAge<=39&teachers==1
         motherAge>=25&motherAge<=39&teachers==2
         motherAge>=40&motherAge<=45
         motherAge>=40&motherAge<=45&teachers==1
         motherAge>=40&motherAge<=45&teachers==2;
local gname 2831 2831Teacher 2831NonTeacher 2539 2539Teacher 2539NonTeacher
            4045 4045Teacher 4045NonTeacher;            
#delimit cr

tokenize `gname'
foreach cond of local c1 {
    preserve
    cap drop teachers
    generat teachers = 1 if twoLev == "Education, Training, and Library Occupations"
    replace teachers = 2 if teachers==.
    bys state: gen statecount = _N

    keep if `cond'
    qui count if statecount>500
    local SN = r(N)

    collapse goodQuarter (min) cold (max) hot (sum) pop, /*
    */ by(statefip state fips state*)
    gen diff = hot-cold
    
    lab var goodQuarter "Proportion good season"
    lab var cold        "Coldest monthly average (degree F)"
    lab var diff        "Annual variation in Temperature (degree F)"
    local cc statecount>500

    format goodQuarter %5.2f
    drop if state=="Alaska"|state=="Nebraska"

    foreach tvar of varlist cold diff {
        corr goodQuarter `tvar' if `cc'
        local ccoef = string(r(rho),"%5.3f")
        reg goodQuarter `tvar' if `cc', nohead
        local pval   = (ttail(e(df_r),abs(_b[`tvar']/_se[`tvar'])))
        local pvalue = string(`pval',"%5.3f")
        if `pvalue' == 0 local pvalue 0.000
        
        #delimit ;
        twoway scatter goodQuarter `tvar' if `cc', mlabel(state) ||      
                  lfit goodQuarter `tvar' if `cc', scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
        note("Correlation coefficient=`ccoef', p-value=`pvalue', N=`SN'");
        graph export "$GRA/StateTemp_`1'_`tvar'.eps", as(eps) replace;
        #delimit cr

        corr goodQuarter `tvar' [aw=pop] if `cc'
        local ccoef = string(r(rho),"%5.3f")
        reg goodQuarter `tvar' [aw=pop]  if `cc', nohead
        local pval   = (ttail(e(df_r),abs(_b[`tvar']/_se[`tvar'])))
        local pvalue = string(`pval',"%5.3f")
        if `pvalue' == 0 local pvalue 0.000

        #delimit ;
        twoway scatter goodQuarter `tvar' if `cc', msymbol(i) mlabel(state) ||
               scatter goodQuarter `tvar' if `cc' [aw=pop], msymbol(Oh) ||      
                  lfit goodQuarter `tvar' if `cc' [aw=pop], scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
        note("Correlation coefficient=`ccoef', p-value=`pvalue', N=`SN'");
        graph export "$GRA/StateTemp_`1'_`tvar'_weight.eps", as(eps) replace;
        #delimit cr
    }
    macro shift
    restore
}

cap gen pop=1
gen quarter2 = birthQuarter==2
gen quarter3 = birthQuarter==3


#delimit ;
local c1 motherAge>=28&motherAge<=31&teachers==1
         motherAge>=28&motherAge<=31&teachers==2
         motherAge>=25&motherAge<=39&teachers==1
         motherAge>=25&motherAge<=39&teachers==2
         motherAge>=40&motherAge<=45&teachers==1
         motherAge>=40&motherAge<=45&teachers==2;
local gname 2831Teacher 2831NonTeacher 2539Teacher 2539NonTeacher 4045Teacher 4045NonTeacher;            
#delimit cr
tokenize `gname'
foreach cond of local c1 {
    preserve
    cap drop teachers
    generat teachers = 1 if twoLev == "Education, Training, and Library Occupations"
    replace teachers = 2 if teachers==.
    bys state: gen statecount = _N

    keep if `cond'
    qui count if statecount>500
    local SN = r(N)

    collapse quarter2 quarter3 (min) cold (max) hot (sum) pop, /*
    */ by(statefip state fips state*)
    gen diff = hot-cold
    
    lab var quarter2    "Proportion born in Quarter 2"
    lab var quarter3    "Proportion born in Quarter 3"
    lab var cold        "Coldest monthly average (degree F)"
    lab var diff        "Annual variation in Temperature (degree F)"
    local cc statecount>500

    format quarter2 %5.2f
    format quarter3 %5.2f
    drop if state=="Alaska"|state=="Nebraska"

    foreach tvar of varlist quarter2 quarter3 {
        corr `tvar' cold [aw=pop] if `cc'
        local ccoef = string(r(rho),"%5.3f")
        reg `tvar' cold [aw=pop]  if `cc', nohead
        local pval   = (ttail(e(df_r),abs(_b[cold]/_se[cold])))
        local pvalue = string(`pval',"%5.3f")
        if `pvalue' == 0 local pvalue 0.000

        #delimit ;
        twoway scatter `tvar' cold if `cc', msymbol(i) mlabel(state) ||
               scatter `tvar' cold if `cc' [aw=pop], msymbol(Oh) ||      
                  lfit `tvar' cold if `cc' [aw=pop], scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
        note("Correlation coefficient=`ccoef', p-value=`pvalue', N=`SN'");
        graph export "$GRA/StateTemp`tvar'_`1'.eps", as(eps) replace;
        #delimit cr
    }
    macro shift
    restore
}




preserve
bys state: gen statecount = _N
keep if age2831==1
cap drop teachers
generat teachers = 1 if twoLev == "Education, Training, and Library Occupations"
replace teachers = 2 if teachers==.

collapse goodQuarter (min) cold, by(teachers statefip state fips state*)

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
local cc statecount>500

format goodQuarter %5.2f

foreach num of numlist 1 2 {
    local age teachers
    if `num'==2 local age nonteachers
    drop if state=="Alaska"|state=="Nebraska"
    
    corr goodQuarter cold if teachers==`num' & `cc'
    local ccoef = string(r(rho),"%5.3f")
    #delimit ;
    twoway scatter goodQuarter cold if teachers==`num'& `cc', mlabel(state) ||      
        lfit goodQuarter cold if teachers==`num'& `cc', scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
    note("Correlation coefficient=`ccoef'");
    graph export "$GRA/`age'TempCold_2831.eps", as(eps) replace;
    #delimit cr
}

restore
cap drop teachers
generat teachers = 1 if twoLev == "Education, Training, and Library Occupations"
replace teachers = 2 if teachers==.
lab var teachers "Education, Library, Training"
lab var cold     "Minimum Temperature in State ($^{\circ}$ F)"

eststo: reg goodQuarter cold                                  i.year, r
eststo: reg goodQuarter cold age2527 age2831 age3239          i.year, r
eststo: reg goodQuarter cold age2527 age2831 age3239 teachers i.year, r
eststo: reg goodQuarter cold age2527 age2831 age3239 i.year if teachers==1, r
eststo: reg goodQuarter cold age2527 age2831 age3239 i.year if teachers==2, r

#delimit ;
esttab est1 est2 est3 est4 est5 using "$OUT/IPUMSTeachersCold.tex",
replace `estopt' title("Season of Birth, Occupation and Weather") mlabels(, depvar) 
keep(_cons cold age2527 age2831 age3239 teachers) style(tex) booktabs 
postfoot("Education Only & & & & Y & \\ Non-Education Only  & & & & & Y \\     "
         "\bottomrule \multicolumn{6}{p{19.8cm}}{\begin{footnotesize}          "
         "All regressions include year fixed effects, but not state effects,   "
         "as minimum monthly temperature is defined as the minimum in the state"
         "so is colinear with state fixed effects. Education, Library, Training"
         "refers to individuals employed in this occupation (occ codes         "
         "2200-2550). The omitted age category in each case is 40-45 year old  "
         "women."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


    
preserve
cap drop youngOld
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
bys state: gen statecount = _N
keep if youngOld != .

collapse goodQuarter (min) cold, by(youngOld statefip state fips state*)

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
local cc statecount>500

format goodQuarter %5.2f
foreach num of numlist 1 2 {
    local age young
    if `num'==2 local age old
    drop if state=="Alaska"
    
    corr goodQuarter cold if youngOld==`num' & `cc'
    local ccoef = string(r(rho),"%5.3f")
    #delimit ;
    twoway scatter goodQuarter cold if youngOld==`num'& `cc', mlabel(state) ||      
        lfit goodQuarter cold if youngOld==`num'& `cc', scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
    note("Correlation coefficient=`ccoef'");
    graph export "$GRA/`age'TempCold.eps", as(eps) replace;
    #delimit cr
}

drop state
rename stateabbrev state
merge m:1 state using "$DAT/../maps/state_database_clean"
drop _merge


#delimit ;
spmap goodQuarter if youngOld==1&(statefip!=2&statefip!=15) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$GRA/youngGoodSeason.eps", replace as(eps);

spmap goodQuarter if youngOld==2&(statefip!=2&statefip!=15) using
"$DAT/../maps/state_coords_clean", id(_polygonid) fcolor(YlOrRd)
legend(symy(*2) symx(*2) size(*2.1) position(4) rowgap(1)) legstyle(2);
graph export "$GRA/oldGoodSeason.eps", replace as(eps);
#delimit cr
restore


********************************************************************************
*** (6f) Figure 11
********************************************************************************
preserve
gen ageG2 = motherAge>=20 & motherAge<25
replace ageG2 = 2 if motherAge>=25 & motherAge<28
replace ageG2 = 3 if motherAge>=28 & motherAge<32
replace ageG2 = 4 if motherAge>=32 & motherAge<40
replace ageG2 = 5 if motherAge>=40 & motherAge<46

collapse (sum) birth `wt', by(goodQuarter ageG2)
drop if goodQuarter == .
reshape wide birth, i(ageG2) j(goodQuarter)
gen totalbirths = birth0 + birth1
replace birth0=(round(10000*birth0/totalbirths)/100)-50
replace birth1=(round(10000*birth1/totalbirths)/100)-50
keep birth1 ageG2
replace birth1=birth1*2
list
lab def       aG4 1 "20-24" 2 "25-27" 3 "28-31" 4 "35-39" 5 "40-45"
lab val ageG2 aG4

#delimit ;
graph bar birth1, over(ageG2)  ylabel(, nogrid) yline(0, lpattern("_"))
bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue)) bar(3, bcolor(ltblue))
bar(4, bcolor(ltblue)) scheme(s1mono) ytitle("% Good Season - % Bad Season");
graph export "$GRA/birthQdiff_4Ages.eps", as(eps) replace;
#delimit cr
restore

********************************************************************************
*** (6g) Figure 11
********************************************************************************
generat youngOld = 1 if motherAge>=28&motherAge<=31
replace youngOld = 2 if motherAge>=40&motherAge<=45
collapse (sum) birth, by(birthQuarter state youngOld)
lab val birthQuarter mon
bys state youngOld: egen totalBirths = sum(birth)
gen birthProportion = birth/totalBirths
sort birthQuarter state

local line1 lpattern(solid)    lcolor(black)
local line2 lpattern(dash)     lcolor(black)
local MN    Minnesota
local WI    Wisconsin

foreach hS in Alabama Arkansas Arizona {
    local cond1 state=="`hS'"
    local cond2 state=="Minnesota"
    #delimit ;
    twoway line birthProportion birthQuarter if `cond1'& youngO==1, `line1' ||
           line birthProportion birthQuarter if `cond2'& youngO==1, `line2'
    scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$GRA/birthQuarter`hS'Minnesota_young.eps", as(eps) replace;

    twoway line birthProportion birthQuarter if `cond1'& youngO==2, `line1' ||
           line birthProportion birthQuarter if `cond2'& youngO==2, `line2'
    scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`MN'"));
    graph export "$GRA/birthQuarter`hS'Minnesota_old.eps", as(eps) replace;
    #delimit cr

    local cond2 state=="Wisconsin"
    #delimit ;
    twoway line birthProportion birthQuarter if `cond1'& youngO==1, `line1' ||
           line birthProportion birthQuarter if `cond2'& youngO==1, `line2'
    scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$GRA/birthQuarter`hS'Wisconsin_young.eps", as(eps) replace;

    twoway line birthProportion birthQuarter if `cond1'& youngO==2, `line1' ||
           line birthProportion birthQuarter if `cond2'& youngO==2, `line2'
    scheme(s1mono) xtitle("Birth Quarter") xlabel(1(1)4, valuelabels)
    ytitle("Proportion of All Births") legend(label(1 "`hS'") label(2 "`WI'"));
    graph export "$GRA/birthQuarter`hS'Wisconsin_old.eps", as(eps) replace;
    #delimit cr
}
*/
********************************************************************************
*** (7) Occupations
********************************************************************************
use "$DAT/`data'", clear
if `allobs'== 0 keep if marst==1

bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter

generat ageGroup        = 1 if motherAge>=25&motherAge<40
replace ageGroup        = 2 if motherAge>=40&motherAge<=45
generat educLevel       = highEduc
replace educLevel       = 2 if educd>=101

lab def ag 1 "Young (25-39) " 2 "Old (40-45) "
lab def ed 0 "No College" 1 "Some College" 2 "Complete College"
lab val ageGroup ag
lab val educLevel ed

generat occAlt = 1 if twoL=="Personal Care and Service Occupations"
replace occAlt = 1 if twoL=="Sales Related"
replace occAlt = 1 if twoL=="Office and Administrative Support Occupations"
replace occAlt = 1 if twoL=="Food Preparation and Serving Occupations"
replace occAlt = 2 if twoL=="Healthcare Practitioners and Technical Occupations"
replace occAlt = 2 if twoL=="Legal Occupations"
replace occAlt = 2 if twoL=="Management Occupations"
replace occAlt = 2 if twoL=="Life, Physical, and Social Science Occupations"
replace occAlt = 2 if twoL=="Financial Specialists"
replace occAlt = 3 if twoL=="Education, Training, and Library Occupations"

preserve
collapse (sum) birth `wt', by(birthQuarter occAlt)
drop if occAlt == .
bys occAlt: egen totalbirth = sum(birth)
gen birthProportion = birth/totalbirth


#delimit ;
graph bar birthProportion, over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Group 1" 2 "Group 2" 3 "Group 3")) scheme(s1mono)
exclude0 ytitle("Proportion of Births in Quarter"); 
graph export "$GRA/birthsOccupation.eps", as(eps) replace;
#delimit cr
restore

tab twoLevelOcc, gen(_2occ)
gen sigOccs =_2occ6==1|_2occ8==1|_2occ9==1|_2occ13==1|_2occ14==1|_2occ15==1


generat occAlt2 = 1 if twoL=="Education, Training, and Library Occupations"
replace occAlt2 = 2 if sigOccs==1
replace occAlt2 = 3 if twoL=="Life, Physical, and Social Science Occupations"


preserve
count if occAlt!=.
local SN = r(N)
collapse (sum) birth, by(birthQuarter occAlt2)
drop if occAlt == .
bys occAlt: egen totalbirth = sum(birth)
gen birthProportion = birth/totalbirth


#delimit ;
graph bar birthProportion, over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Education" 2 "Significant" 3 "Life/Physical/Soc Science"))
scheme(s1mono) exclude0 ytitle("Proportion of Births in Quarter")
yline(0.25, lpattern(dash) lcolor(red))
note("Total Observations (All Occupations) = `SN'"); 
graph export "$GRA/birthsOccupation2.eps", as(eps) replace;
#delimit cr
restore

replace occAlt2 = 4 if twoL=="Unemployed"
preserve
count if occAlt!=.
local SN = r(N)
collapse (sum) birth, by(birthQuarter occAlt2)
drop if occAlt == .
bys occAlt: egen totalbirth = sum(birth)
gen birthProportion = birth/totalbirth


#delimit ;
graph bar birthProportion, over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Education" 2 "Significant" 3 "Sciences" 4 "No Work Experience"))
scheme(s1mono) exclude0 ytitle("Proportion of Births in Quarter")
yline(0.25, lpattern(dash) lcolor(red))
note("Total Observations (All Occupations) = `SN'"); 
graph export "$GRA/birthsOccupation_NoWork.eps", as(eps) replace;
#delimit cr
restore


preserve
cap gen tsplit = cold<23    
count if occAlt!=.&tsplit==1
local SN1 = r(N)
count if occAlt!=.&tsplit==0
local SN2 = r(N)
bys twoLevelOcc tsplit: gen counter2 = _N
keep if counter2>=500
collapse (sum) birth, by(birthQuarter occAlt2 tsplit)
drop if occAlt == .
bys occAlt tsplit: egen totalbirth = sum(birth)
gen birthProportion = birth/totalbirth


#delimit ;
graph bar birthProportion if tsplit==1, yline(0.25, lpattern(dash) lcolor(red))
over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Education" 2 "Significant" 3 "Life/Physical/Soc Science"))
scheme(s1mono) exclude0 ytitle("Proportion of Births in Quarter")
ylabel(0.22(0.02)0.3) note("Total Observations (All Occupations) = `SN1'"); ; 
graph export "$GRA/birthsOccupation_cold.eps", as(eps) replace;

graph bar birthProportion if tsplit==0, yline(0.25, lpattern(dash) lcolor(red))
over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Education" 2 "Significant" 3 "Life/Physical/Soc Science"))
scheme(s1mono) exclude0 ytitle("Proportion of Births in Quarter")
ylabel(0.22(0.02)0.3) note("Total Observations (All Occupations) = `SN2'"); 
graph export "$GRA/birthsOccupation_warm.eps", as(eps) replace;

#delimit cr
restore
dis "hello"


cap mkdir "$GRA/occ"

preserve
collapse (sum) birth, by(birthQuarter twoLevelOcc)
bys twoLevelOcc: egen totalbirth = sum(birth)
gen birthProp = birth/totalbirth

levelsof twoLevelOcc, local(occs)
local j=1
foreach occ of local occs {
    dis "`occ'"
    sum totalbirth if twoLevelOcc=="`occ'"
    local N = `r(mean)'
    #delimit ;
    graph bar birthProp if twoLevelOcc=="`occ'",
    over(birthQuarte, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")) scheme(s1mono)
    exclude0 ytitle("Proportion of Births in Quarter") ylabel(0.22 0.24 0.26 0.28)
    note("Occupation: `occ' has `N' mothers in the sample") title("`occ'");
    graph export "$GRA/occ/twolevelProportion`j'.eps", as(eps) replace;
    #delimit cr
    local ++j
}
restore

preserve
drop if GoldinClass == .
decode GoldinClass, gen(GClass)
collapse (sum) birth, by(birthQuarter GClass)
bys GClass: egen totalbirth = sum(birth)
gen birthProp = birth/totalbirth

levelsof GClass, local(occs)
local j=1
foreach occ of local occs {
    dis "`occ'"
    sum totalbirth if GClass=="`occ'"
    local N = `r(mean)'
    #delimit ;
    graph bar birthProp if GClass=="`occ'",
    over(birthQuarte, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")) scheme(s1mono)
    exclude0 ytitle("Proportion of Births in Quarter") ylabel(0.22 0.24 0.26 0.28)
    note("Occupation: `occ' has `N' mothers in the sample") title("`occ'");
    graph export "$GRA/occ/GoldinClassProportion`j'.eps", as(eps) replace;
    #delimit cr
    local ++j
}
restore

********************************************************************************
*** (8) Income
********************************************************************************
use "$DAT/`data'", clear
keep if marst==1
local incvar hhincome
local incvar inctot

keep if `agecond'&twins==0
drop if occ2010 == 9920
tab year    , gen(_year)
tab statefip, gen(_state)
bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter

sum `incvar',d
keep if `incvar' > `r(p5)' & `incvar' < `r(p95)'

xtile income5  = `incvar', nq(5)
xtile income10 = `incvar', nq(5)

tab income5, gen(_inc)
sum goodQuarter if _inc1==1

areg goodQ _inc2-_inc5 age2527 age2831 age3239 i.year `wt', robus abs(statefip)

gen IncomeQuantile  = .
gen percentGood     = .
gen lowpercentGood  = .
gen highpercentGood = .

foreach q of numlist 2 3 4 5 {
    replace percentGood     = _b[_inc`q'] in `q'
    replace lowpercentGood  = _b[_inc`q'] - 1.65*_se[_inc`q'] in `q'
    replace highpercentGood = _b[_inc`q'] + 1.65*_se[_inc`q'] in `q'
    replace IncomeQuantile  = `q' in `q'
}

#delimit ;
twoway scatter percentGood IncomeQuantile in 2/5, msymbol(D) mcolor(black)
    || rcap highpercentGood lowpercentGood IncomeQuantile in 2/5, lcolor(black)
ytitle("Proportion Good Season") xtitle("Income Quantile") scheme(s1mono)
yline(0, lwidth(thick) lcolor(red))
legend(lab(1 "Mean Good Season") lab(2 "95% CI"));
*note("All estimates are compared to quantile 1.  `n1'");
#delimit cr
graph export "$GRA/incomeGoodSeason.eps", as(eps) replace
drop IncomeQuantile percentGood lowpercentGood highpercentGood

gen age2539 = motherAge>=25&motherAge<=39
foreach group in 2539 4045 {
    sum goodQuarter if _inc1==1 & age`group'==1
    areg goodQ _inc2-_inc5 i.year if age`group'==1, robus abs(statefip)

    gen IncomeQuantile  = .
    gen percentGood     = .
    gen lowpercentGood  = .
    gen highpercentGood = .

    foreach q of numlist 2 3 4 5 {
        replace percentGood     = _b[_inc`q'] in `q'
        replace lowpercentGood  = _b[_inc`q'] - 1.65*_se[_inc`q'] in `q'
        replace highpercentGood = _b[_inc`q'] + 1.65*_se[_inc`q'] in `q'
        replace IncomeQuantile  = `q' in `q'
    }

    #delimit ;
    twoway scatter percentGood IncomeQuantile in 2/5, msymbol(D) mcolor(black)
    || rcap highpercentGood lowpercentGood IncomeQuantile in 2/5, lcolor(black)
    ytitle("Proportion Good Season") xtitle("Income Quantile") scheme(s1mono)
    yline(0, lwidth(thick) lcolor(red))
    legend(lab(1 "Mean Good Season") lab(2 "95% CI"));
    #delimit cr
    graph export "$GRA/incomeGoodSeason`group'.eps", as(eps) replace
    drop IncomeQuantile percentGood lowpercentGood highpercentGood
}

replace `incvar' = `incvar'/1000
#delimit ;
twoway lowess goodQuarter `incvar' if age2831 == 1, lwidth(thick) lcolor(black)
||     lowess goodQuarter `incvar' if age4045 == 1, lcolor(black) lpattern(dash)
scheme(s1mono) legend(lab(1 "Ages 28-31") lab(2 "Ages 40-45"))
ytitle("Proportion Good Season") xtitle("Total Household Income (1000s)");
#delimit cr
graph export "$GRA/incomeSeasonLowess.eps", as(eps) replace

tab birthQuarter, gen(_bq)
gen AG2 = 1 if age2831==1
replace AG2 = 2 if age4045==1
drop if AG2 == .
collapse goodQuarter _bq1 _bq2 _bq3 _bq4 (semean) segQ=goodQ sebQ1=_bq1 /*
*/ sebQ2=_bq2 sebQ3=_bq3 sebQ4=_bq4, by(income5 AG2)
reshape long _bq sebQ, i(income5 AG2) j(season)
gen highbq = _bq+1.65*sebQ
gen lowbq  = _bq-1.65*sebQ



gen seasonIncome     = income5    if season == 1
replace seasonIncome = income5+5  if season == 2
replace seasonIncome = income5+10 if season == 3
replace seasonIncome = income5+15 if season == 4

#delimit ;
twoway (bar _bq seasonIncome if season==1&AG2==1)
       (bar _bq seasonIncome if season==2&AG2==1)
       (bar _bq seasonIncome if season==3&AG2==1)
       (bar _bq seasonIncome if season==4&AG2==1)
       (rcap highbq lowbq seasonIncome),
legend(off) scheme(s1mono)
xlabel(3 "Birth Quarter 1" 8 "Birth Quarter 2" 13 "Birth Quarter 3" 18
       "Birth Quarter 4",  noticks);
graph export "$GRA/incomeSeasonsSEs_2831.eps", as(eps) replace;

graph bar _bq if AG2==1, over(income5)
over(season, relabel(1 "Birth Quarter 1" 2 "Birth Quarter 2"
                     3 "Birth Quarter 3" 4 "Birth Quarter 4")) exclude0
scheme(s1mono) bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue))
bar(3, bcolor(ltblue)) bar(4, bcolor(ltblue)) ytitle("Proportion of Births");
graph export "$GRA/incomeSeasons_2831.eps", as(eps) replace;

graph bar _bq if AG2==2, over(income5)
over(season, relabel(1 "Birth Quarter 1" 2 "Birth Quarter 2"
                     3 "Birth Quarter 3" 4 "Birth Quarter 4")) exclude0
scheme(s1mono) bar(1, bcolor(ltblue)) bar(2, bcolor(ltblue))
bar(3, bcolor(ltblue)) bar(4, bcolor(ltblue)) ytitle("Proportion of Births");
#delimit cr
graph export "$GRA/incomeSeasons_4045.eps", as(eps) replace


********************************************************************************
*** (X) Close
********************************************************************************
log close
dis _newline(5) " Terminated without Error" _newline(5)
