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

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/raw"
global UNE "~/investigacion/2015/birthQuarter/data/employ"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace
cap mkdir "$OUT"

local data   ACS_20052014_cleaned.dta
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label

********************************************************************************
*** (2) Open data subset to sample of interest (from Sonia's import file)
********************************************************************************
use "$DAT/`data'"
keep if motherAge>=25&motherAge<=45
tab year    , gen(_year)
tab statefip, gen(_state)

lab var unemployment "Unemployment Rate"

********************************************************************************
*** (3a) regressions: binary age groups
********************************************************************************
local se  cluster(statefip)
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment

eststo: areg goodQuarter `age' `edu' `une' _year* _state*     , abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample), `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample),          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSBinary.tex",
replace `estopt' title("Season of Birth Correlates (IPUMS 2005-2014)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
        "\multicolumn{5}{p{16.8cm}}{\begin{footnotesize}Sample consists of all "
         "first born children of US-born, white, non-hispanic mothers aged 25- "
         "45 included in ACS data. Standard errors are clustered by state.     "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3b) regressions: age continuous
********************************************************************************
gen motherAge2 = motherAge*motherAge
lab var motherAge  "Mother's Age (years)"
lab var motherAge2 "Mother's Age\textsuperscript{2}"

local age motherAge

eststo: areg goodQuarter `age' `edu' `une' _year* _state*     , abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample), `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample),          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/goodQuarter_Years.tex",
replace `estopt' title("Season of Birth Correlates (Continuous Age)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
        "\multicolumn{5}{p{16.8cm}}{\begin{footnotesize}Sample consists of all "
         "first born children of US-born, white, non-hispanic mothers aged 25- "
         "45 included in ACS data. Standard errors are clustered by state.     "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3b) regressions: age quadratic
********************************************************************************
local age motherAge motherAge2

eststo: areg goodQuarter `age' `edu' `une' _year* _state*     , abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample), `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample), `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample),          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/goodQuarter_YearsSquared.tex",
replace `estopt' title("Season of Birth Correlates (Age and Age Squared)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
        "\multicolumn{5}{p{16.8cm}}{\begin{footnotesize}Sample consists of all "
         "first born children of US-born, white, non-hispanic mothers aged 25- "
         "45 included in ACS data. Standard errors are clustered by state.     "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
