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


********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global OUT "~/investigacion/2015/birthQuarter/results/census/regressions"
global GRA "~/investigacion/2015/birthQuarter/results/census/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/census/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace

#delimit ;
local data   ACS_20052014_cleaned_all.dta;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats 
             (N, fmt(%9.0g) label(Observations))     
             collabels(none) label;
local wt     [pw=perwt];
local lnote  "Heteroscedasticity robust standard errors are reported in 
            parentheses. $ ^\ddagger $ Significant based on Leamer criterion.";
local Fnote  "F-test of age variables refers to the p-value on the test that
              the coefficients on mother's age and age squared are jointly equal
              to zero. ";
local onote  "Optimal age calculates the turning point of the mother's age
              quadratic. ";
#delimit cr

local agecond motherAge>=20&motherAge<=45

********************************************************************************
*** (2) Open data subset to sample of interest (from Sonia's import file)
********************************************************************************
use "$DAT/`data'"
keep if `agecond'&twins==0
drop if occ2010 == 9920
tab year       , gen(_year)
tab statefip   , gen(_state)

bys twoLevelOcc: gen counter = _N
keep if counter>499
drop counter
tab twoLevelOcc, gen(_2occ)
gen motherAge2  = motherAge*motherAge/100
gen quarter2 = birthQuarter==2
gen quarter3 = birthQuarter==3
gen all      = 1
gen logInc   = log(hhincome)

lab var quarter2     "Quarter 2"
lab var quarter3     "Quarter 3"
lab var motherAge    "Mother's Age"
lab var motherAge2   "Mother's Age$^2$ / 100"
lab var unemployment "Unemployment Rate"
lab var logInc       "log(household income)"


********************************************************************************
*** (3) regressions: industry (by quarter)
********************************************************************************
local se  robust
local abs abs(statefip)
local age motherAge motherAge2
local une 
local lv2 _2occ*
cap drop _2occ2

#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 Black unmarried"  "20-45 White unmarried" "';
local nam All whiteMarried blackUnmarried whiteUnmarried;
#delimit cr
tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg  motherAge>=20&motherAge<=45
    if `k'==2 local gg  motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg  motherAge>=20&motherAge<=45&black==1&married==0
    if `k'==4 local gg  motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==1 local edu highEduc hispanic black white married
    if `k'==2 local edu highEduc hispanic
    if `k'==3 local edu highEduc
    if `k'==4 local edu highEduc hispanic

    preserve
    keep if `gg'
 
    foreach Q in 2 3 {
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
        local pvL = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))
        
        eststo:  areg quarter`Q' `age' `edu' `une' _year*       `wt', `se' `abs'
        test `age'
        local F3a = round(r(p)*1000)/1000
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
        #delimit ;
        esttab est2 est1 using "$OUT/IPUMSIndustryQ`Q'_``k''.tex", replace `estopt' 
        title("Season of Birth Correlates: Occupation (Quarter `Q', `type')")
        keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
        starlevel ("$ ^\ddagger $ " `pvL') 
        postfoot("State and Year Fixed Effects&Y&Y\\                           "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize}Sample consists of all"
         " singleton first-born children in the US to mothers aged 25-45       "
         "included in 2005-2014 ACS data where the mother is in the respective "
         "race/marital sample and either the head of the household or the      "
         "partner of the head of"
         "the household and works in an occupation with at least 500 workers   "
         "in the full sample. Occupation classification is provided by the 2   "
         "digit occupation codes from the census. The omitted occupational     "
         "category in column 2 and column 4 is Arts, Design, Entertainment,    "
         "Sports, and Media, as this occupation has good quarter=0.500(0.500). "
         "F-tests for occupation report p-values of joint significance of the  "
         "dummies, and `Fnote' The Leamer critical value for the t-statistic is"
         "`tL1'. `lnote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }

    if `k'==1 local edu highEduc logInc hispanic black white married
    if `k'==2 local edu highEduc logInc hispanic
    if `k'==3 local edu highEduc logInc
    if `k'==4 local edu highEduc logInc hispanic

    foreach Q in 2 3 {
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
        local pvL = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))
        
        eststo:  areg quarter`Q' `age' `edu' `une' _year*       `wt', `se' `abs'
        test `age'
        local F3a = round(r(p)*1000)/1000
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
        #delimit ;
        esttab est2 est1 using "$OUT/IPUMSIndustryIncQ`Q'_``k''.tex", replace 
        title("Season of Birth Correlates: Occupation with Income Controls (Quarter `Q', `type')")
        keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
        starlevel ("$ ^\ddagger $ " `pvL') `estopt' 
        postfoot("State and Year Fixed Effects&Y&Y\\                           "
         "F-test of Occupation Dummies&-&`F2'\\                                "
         "F-test of Age Variables&0`F3a'&0`F2a'\\ \bottomrule                  "
         "\multicolumn{3}{p{14.6cm}}{\begin{footnotesize}Sample consists of all"
         " singleton first-born children in the US to mothers aged 25-45       "
         "included in 2005-2014 ACS data where the mother is in the respective "
         "race/marital sample and either the head of the household or the      "
         "partner of the head of"
         "the household and works in an occupation with at least 500 workers   "
         "in the full sample. Occupation classification is provided by the 2   "
         "digit occupation codes from the census. The omitted occupational     "
         "category in column 2 and column 4 is Arts, Design, Entertainment,    "
         "Sports, and Media, as this occupation has good quarter=0.500(0.500). "
         "F-tests for occupation report p-values of joint significance of the  "
         "dummies, and `Fnote' The Leamer critical value for the t-statistic is"
         "`tL1'. `lnote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
    }
    restore
    local ++k
}


********************************************************************************
*** (5) Sumstats (all)
********************************************************************************
generat young     =   motherAge <=39
gen teacher=twoLevelOcc =="Education, Training, and Library Occupations"

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)
 
lab var educYrs   "Years of education"
lab var married   "Married"
lab var young     "Young (aged 25-39)"
lab var highEduc  "Some College +"
lab var goodQuart "Good Season of Birth"
lab var motherAge "Mother's Age"
lab var teacher   "Works in Education, Training and Library"

tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg  motherAge>=20&motherAge<=45
    if `k'==2 local gg  motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg  motherAge>=20&motherAge<=45&black==1&married==0
    if `k'==4 local gg  motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==1 local edu hispanic black white married
    if `k'==2 local edu hispanic
    if `k'==3 local edu  
    if `k'==4 local edu hispanic

    preserve
    keep if `gg'
    #delimit ;
    estpost tabstat motherAge married young age2024 age2527 age2831 age3239 
                    age4045 highEduc educYrs goodQuarter `edu' teacher,
    statistics(count mean sd min max) columns(statistics);

    esttab using "$SUM/IPUMSstats_``k''.tex", replace label noobs
    title("Descriptive Statistics (NVSS, `type')")
    cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))");
    #delimit cr
    restore

    local ++k
}


********************************************************************************
*** (X) Close
********************************************************************************
log close
dis _newline(5) " Terminated without Error" _newline(5)
