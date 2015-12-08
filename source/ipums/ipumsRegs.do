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
global SUM "~/investigacion/2015/birthQuarter/results/ipums/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace
cap mkdir "$OUT"

local data   ACS_20052014_cleaned.dta
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label

/*
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
        "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all "
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
        "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all "
         "first born children of US-born, white, non-hispanic mothers aged 25- "
         "45 included in ACS data. Standard errors are clustered by state.     "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3c) regressions: age quadratic
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
        "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all "
         "first born children of US-born, white, non-hispanic mothers aged 25- "
         "45 included in ACS data. Standard errors are clustered by state.     "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
*/


********************************************************************************
*** (4) Sumstats of good season by various levels
********************************************************************************
use "$DAT/`data'"
generat ageGroup = 1 if motherAge>=25&motherAge<40
replace ageGroup = 2 if motherAge>=40&motherAge<45
gen educLevel = highEduc

lab def ag 1 "Young (25-39) " 2 "Old (40-45) "
lab def ed 0 "No College" 1 "Some College +"
lab val ageGroup ag
lab val educLevel ed

preserve
drop if ageGroup==.

collapse (sum) birth, by(goodQuarter educLevel ageGroup)
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
collapse (sum) birth, by(goodQuarter educLevel)
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

collapse (sum) birth, by(goodQuarter ageG2)
lab def ag_2 1 "20-24 Years Old" 2 "25-37 Years Old" 3 "28-31 Years Old" /*
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
