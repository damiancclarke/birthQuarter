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
global UNE "~/investigacion/2015/birthQuarter/data/employ"
global OUT "~/investigacion/2015/birthQuarter/results/ipums/regressions"
global GRA "~/investigacion/2015/birthQuarter/results/ipums/graphs"
global SUM "~/investigacion/2015/birthQuarter/results/ipums/sumStats"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsRegs.txt", text replace
cap mkdir "$OUT"
cap mkdir "$GRA"
cap mkdir "$SUM"

#delimit ;
local data   ACS_20052014_cleaned.dta;
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
keep if motherAge>=25&motherAge<=45&twins==0
keep if marst==1
drop if occ2010 == 9920
tab year    , gen(_year)
tab statefip, gen(_state)

lab var unemployment "Unemployment Rate"
bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter

gen young = motherAge>=25&motherAge<=39
lab var young "Aged 25-39"

********************************************************************************
*** (3a) regressions: binary age groups
********************************************************************************
local se  robust
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc

local v1 `age' `edu'  _year* _state*
local v2 `age' `edu'  _year*
local v3 `age'        _year*
local v4 `age'                   

eststo: areg goodQuarter `v1'      `wt', abs(occ) `se'
test `age'
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000

foreach num of numlist 2 3 {
    eststo: areg goodQuarter `v`num'' if e(sample) `wt', `abs' `se'
    test `age'
    local F`num' = round(r(p)*1000)/1000
    if   `F`num'' == 0 local F`num' 0.000    
}
eststo: reg goodQuarter `v4' if e(sample) `wt', `se'
test `age'
local F4 = round(r(p)*1000)/1000

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/IPUMSBinary.tex", replace `estopt'
title("Season of Birth Correlates (IPUMS 2005-2014)"\label{tab:IPUMSBinary})
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Dummies&0`F4'&0`F3'&0`F2'&0`F1' \\                     "
         "State and Year FE&&Y&Y&Y\\ Occupation FE&&&&Y\\ \bottomrule          "
         "\multicolumn{5}{p{15.2cm}}{\begin{footnotesize}Sample consists of all"
         "first born children in the USA to white, non-hispanic, married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         "the head of the household or the partner of the head of the          "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Age 40-45 is the omitted base category. F-test of age dummies"
         "refers to the p-value on the joint significance of the three age     "
         "dummies. `enote'  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3b) regressions: boys and girls
********************************************************************************
local add `" "(Girls Only)" "(Boys Only)" "'
local nam girls boys
tokenize `nam'

foreach type of local add {
    preserve
    if `"`1'"'=="girls" keep if female==1
    if `"`1'"'=="boys"  keep if female==0
    if `"`1'"' == "girls" local samp1 "female, singleton"
    if `"`1'"' == "boys"  local samp1 "male, singleton"

    eststo: areg goodQuarter `v1'      `wt', abs(occ) `se'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000

    foreach num of numlist 2 3 {
        eststo: areg goodQuarter `v`num'' if e(sample) `wt', `abs' `se'
        test `age'
        local F`num' = round(r(p)*1000)/1000
        if   `F`num'' == 0 local F`num' 0.000    
    }
    eststo: reg goodQuarter `v4' if e(sample) `wt', `se'
    test `age'
    local F4 = round(r(p)*1000)/1000

    #delimit ;
    esttab est4 est3 est2 est1 using "$OUT/IPUMSBinary`1'.tex", replace 
    `estopt' title("Season of Birth Correlates `type'"\label{tab:IPUMS`type'})
    keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
    postfoot("F-test of Age Dummies&0`F4'&0`F3'&0`F2'&0`F1' \\                 "
             "State and Year FE&&Y&Y&Y\\ Occupation FE&&&&Y\\ \bottomrule      "
             "\multicolumn{5}{p{15.2cm}}{\begin{footnotesize}Sample consists of"
             "all `samp1' first born children with white, non-hispanic, married"
             "mothers aged 25-45 included in ACS data where the mother is      "
             "either the head of the household or the partner of the head of   "
             "the household and works in an occupation with at least 500       "
             "workers in the sample. Age 40-45 is the omitted base category.   "
             "F-test of age dummies refers to the p-value for the joint        "
             "significance of the three age dummies. `enote'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
    macro shift
    restore
}

********************************************************************************
*** (3c) regressions: binary age groups (robustness)
********************************************************************************
local se  robust
local abs abs(statefip)
local age age2527 age2831 age3239
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

foreach num of numlist 2(1)4 {
    eststo: reg goodQuarter `v`num'' if e(sample) `wt', `se'
    test `age'
    local F`num' = round(r(p)*1000)/1000
    if   `F`num'' == 0 local F`num' 0.000    
}

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/IPUMSBinary_Robust.tex", replace
`estopt' title("Season of Birth Correlates (Robustness)"\label{tab:IPUMSRobust})
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Dummies&0`F4'&0`F3'&0`F2'&0`F1' \\                     "
         "State and Year FE&Y&Y&Y&Y\\ State Linear Trends&Y& &Y&Y\\            "
         "Occupation FE&&&&Y\\                          \bottomrule            "
         "\multicolumn{5}{p{15.4cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Age 40-45 is the omitted base category. F-test of age dummies"
         "refers to the p-value for the joint significance of the three age    "
         "dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3d) regressions: good season and education interaction
********************************************************************************
local se  robust
local abs abs(statefip)

gen age2527XhighEd=age2527*highEduc
gen age2831XhighEd=age2831*highEduc
gen age3239XhighEd=age3239*highEduc

lab var age2527XhighEd "Aged 25-27 $\times$ Some College +"
lab var age2831XhighEd "Aged 28-31 $\times$ Some College +"
lab var age3239XhighEd "Aged 32-39 $\times$ Some College +"
    
local age1  age2527 age2831 age3239
local age1X age2527XhighEd age2831XhighEd age3239XhighEd
eststo: areg goodQua `age1' highEduc `age1X' _year*              `wt', `abs' `se'
test `age1'
local F1 = round(r(p)*1000)/1000

eststo: areg goodQua `age1' highEduc         _year* if e(sample) `wt', `abs' `se'
test `age1'
local F2 = round(r(p)*1000)/1000

eststo: areg goodQua `age1'                  _year* if e(sample) `wt', `abs' `se'
test `age3'
local F3 = round(r(p)*1000)/1000

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)

gen motherAge2      = motherAge*motherAge
gen motherAgeXeduc  = motherAge*highEd
gen motherAge2Xeduc = motherAge2*highEd

lab var educYrs         "Years of education"
lab var motherAge       "Mother's Age"
lab var motherAge2      "Mother's Age$^2$"
lab var motherAgeXeduc  "Mother's Age $\times$ Some College"
lab var motherAge2Xeduc "Mother's Age$^2$ $\times$ Some College"

local age2  motherAge motherAge2
eststo: areg goodQua `age2' educYrs          _year* `wt', `abs' `se'
test `age2'
local F4 = round(r(p)*1000)/1000

eststo: areg goodQua `age2'                  _year* `wt', `abs' `se'
test `age2'
local F5 = round(r(p)*1000)/1000

local kvar `age1' highEduc `age1X' `age2' educYrs
#delimit ;
esttab est3 est2 est1 est5 est4 using "$OUT/IPUMSBinaryEducAge.tex",
replace `estopt' booktabs keep(`kvar') mlabels(, depvar)
title("Season of Birth, Age and Education"\label{tab:IPUMSEducAge})
postfoot("F-test of Age Variables&0`F3'&0`F2'&0`F1'&0`F5'&0`F4' \\             "
         "\bottomrule\multicolumn{6}{p{18.6cm}}{\begin{footnotesize}           "
         "Sample consists of all first born children in the USA to white,      "
         "non-hispanic married mothers aged 25-45 included in ACS data where   "
         "the mother is either the head of the household or the partner        "
         "           of the head of the household and works in an occupation   "
         " with at least 500 workers in the sample. F-test of age dummies      "
         "refers to the p-value for the joint significance of the three age    "
         "dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

********************************************************************************
*** (3e) regressions: industry
********************************************************************************
tab oneLevelOcc, gen(_1occ)
tab twoLevelOcc, gen(_2occ)
tab occ        , gen(_occ)

gen significantOccs =_2occ6==1|_2occ8==1|_2occ9==1|_2occ13==1|_2occ14==1|_2occ15==1
gen insignificantOccs = _2occ7!=1&_2occ15!=1
replace insignificantOccs = 0 if _2occ2==1    
lab var   significantOccs "Significant 2 level occupations"
lab var insignificantOccs "Insignificant 2 level occupations"


local se  robust
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment
local une 
local lv1 _1occ*
local lv2 _2occ*
local lv3 _occ*
local sig significantOccs insignificantOccs


eststo: areg goodQuarter `age' `edu' `une' _year* `lv3' `wt', `se' `abs'
ds _occ*
local tvar `r(varlist)'
test `tvar'
local F1 = round(r(p)*1000)/1000
if `F1' == 0 local F1 0.000
test `age'
local F1a = round(r(p)*1000)/1000


drop _2occ2
eststo:  areg goodQuarter `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `edu' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000

#delimit ;
esttab est3 est2 est1 using "$OUT/IPUMSIndustry.tex",
replace `estopt' title("Season of Birth and Occupation"\label{tab:Occupation})
keep(_cons `age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2&3\\                                    "
         "F-test of Occupation Dummies&-&`F2'&`F1'\\                           "
         "F-test of Age Dummies&0`F3a'&0`F2a'&0`F1a'\\          \bottomrule    "
         "\multicolumn{4}{p{16.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Occupation codes refer to the level of occupation codes (2   "
         "digit, or 3 digit). The omitted occupational category in column 2 and"
         "column 4 is Arts, Design, Entertainment, Sports, and Media, as this  "
         "occupation has good quarter=0.500(0.500).  All occupation codes refer"
         "to IPUMS occ2010 codes, available at:                                "
         "https://usa.ipums.org/usa/volii/acs_occtooccsoc.shtml All F-tests    "
         "report p-values of joint significance of the dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

eststo: areg goodQuarter `age' `une' _year* `lv3' `wt', `se' `abs'
ds _occ*
local tvar `r(varlist)'
test `tvar'
local F1 = round(r(p)*1000)/1000
if `F1' == 0 local F1 0.000
test `age'
local F1a = round(r(p)*1000)/1000


eststo:  areg goodQuarter `age' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000

#delimit ;
esttab est3 est2 est1 using "$OUT/IPUMSIndustry_NoEduc.tex",
replace `estopt' title("Season of Birth and Occupation (No Education Control)")
keep(_cons `age' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2&3\\                                    "
         "F-test of Occupation Dummies&-&`F2'&`F1'\\                           "
         "F-test of Age Dummies&0`F3a'&0`F2a'&0`F1a'\\          \bottomrule    "
         "\multicolumn{4}{p{16.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Occupation codes refer to the level of occupation codes (2   "
         "digit, or 3 digit). The omitted occupational category in column 2 and"
         "column 4 is Arts, Design, Entertainment, Sports, and Media, as this  "
         "occupation has good quarter=0.500(0.500).  All occupation codes refer"
         "to IPUMS occ2010 codes, available at:                                "
         "https://usa.ipums.org/usa/volii/acs_occtooccsoc.shtml All F-tests    "
         "report p-values of joint significance of the dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

gen logInc = log(hhincome)
lab var logInc "log(household income)"
local inc logInc

eststo: areg goodQuarter `age' `inc' `une' _year* `lv3' `wt', `se' `abs'
ds _occ*
local tvar `r(varlist)'
test `tvar'
local F1 = round(r(p)*1000)/1000
if `F1' == 0 local F1 0.000
test `age'
local F1a = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `inc' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `inc' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000

#delimit ;
esttab est3 est2 est1 using "$OUT/IPUMSIndustry_Income.tex",
replace `estopt' title("Season of Birth and Occupation (Income Control)")
keep(_cons `age' `inc' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2&3\\                                    "
         "F-test of Occupation Dummies&-&`F2'&`F1'\\                           "
         "F-test of Age Dummies&0`F3a'&0`F2a'&0`F1a'\\          \bottomrule    "
         "\multicolumn{4}{p{16.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Occupation codes refer to the level of occupation codes (2   "
         "digit, or 3 digit). The omitted occupational category in column 2 and"
         "column 4 is Arts, Design, Entertainment, Sports, and Media, as this  "
         "occupation has good quarter=0.500(0.500).  All occupation codes refer"
         "to IPUMS occ2010 codes, available at:                                "
         "https://usa.ipums.org/usa/volii/acs_occtooccsoc.shtml All F-tests    "
         "report p-values of joint significance of the dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local inc logInc highEduc

eststo: areg goodQuarter `age' `inc' `une' _year* `lv3' `wt', `se' `abs'
ds _occ*
local tvar `r(varlist)'
test `tvar'
local F1 = round(r(p)*1000)/1000
if `F1' == 0 local F1 0.000
test `age'
local F1a = round(r(p)*1000)/1000


eststo:  areg goodQuarter `age' `inc' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000
test `age'
local F2a = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `inc' `une' _year*       `wt', `se' `abs'
test `age'
local F3a = round(r(p)*1000)/1000

#delimit ;
esttab est3 est2 est1 using "$OUT/IPUMSIndustry_IncEduc.tex",
replace `estopt' title("Season of Birth and Occupation (Income/Education Controls)")
keep(_cons `age' `inc' `une' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &-&2&3\\                                    "
         "F-test of Occupation Dummies&-&`F2'&`F1'\\                           "
         "F-test of Age Dummies&0`F3a'&0`F2a'&0`F1a'\\          \bottomrule    "
         "\multicolumn{4}{p{16.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Occupation codes refer to the level of occupation codes (2   "
         "digit, or 3 digit). The omitted occupational category in column 2 and"
         "column 4 is Arts, Design, Entertainment, Sports, and Media, as this  "
         "occupation has good quarter=0.500(0.500).  All occupation codes refer"
         "to IPUMS occ2010 codes, available at:                                "
         "https://usa.ipums.org/usa/volii/acs_occtooccsoc.shtml All F-tests    "
         "report p-values of joint significance of the dummies. `enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


********************************************************************************
*** (3f) regressions: Using Goldin's occupation classes
********************************************************************************
replace GoldinClass = . if GoldinClass==5

gen _gc1 = GoldinClass==1|GoldinClass==2 if GoldinClass!=.
gen _gc2 = GoldinClass==3 if GoldinClass!=.
gen _gc3 = GoldinClass==4 if GoldinClass!=.

lab var _gc1 "Technology and Business"
lab var _gc2 "Health Occupations"

local se  robust
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment
local une 
local ind _gc1

drop _gc*
tab GoldinClass, gen(_gc)
gen _gc5 = twoLevelOcc=="Education, Training, and Library Occupations"
lab var _gc5 "Education, Training, and Library"
replace _gc1=0 if _gc5==1
replace _gc3=0 if _gc5==1
replace _gc4=0 if _gc5==1


local ind _gc1 _gc3 _gc4 _gc5

eststo: areg goodQuarter `ind' `age' `edu' `une' _year*  `wt', `abs' `se'
test `age'
local F1 = round(r(p)*1000)/1000
eststo: areg goodQuarter `ind' `age' `edu' `une' _year*  `wt', `abs' `se'
test `age'
local F2 = round(r(p)*1000)/1000
eststo: areg goodQuarter `ind' `age' `edu'       _year*  `wt', `abs' `se'
test `age'
local F3 = round(r(p)*1000)/1000
eststo: areg goodQuarter `ind' `age'             _year*  `wt', `abs' `se'
test `age'
local F4 = round(r(p)*1000)/1000
eststo:  reg goodQuarter `ind' `age'                     `wt',       `se'
test `age'
local F5 = round(r(p)*1000)/1000

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSIndustryGoldinTeachers.tex",
replace `estopt'
title("Season of Birth and Occupation (\citeauthor{Goldin2014}'s Classification)")
keep(_cons `ind' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Dummies&0`F5'&0`F4'&0`F3'&0`F2'&0`F1'\\                "
         "State and Year FE&&Y&Y&Y&Y\\                     \bottomrule         "
         "\multicolumn{6}{p{18.8cm}}{\begin{footnotesize}Sample consists of all"
         "first born children in the USA to white, non-hispanic married mothers"
         "aged 25-45 included in ACS data where the mother is either the head  "
         "of the household or the partner of the head of the household and     "
         "works in an occupation with at least 500 workers in the sample.      "
         "Occupations are categorised as in \citet{Goldin2014} table A1.  The  "
         "omitted category is Business Occupations, and Other Occupations      "
         "(heterogeneous) are excluded.  The category Education, Training and  "
         "Library Occupations has been added. F-test of age dummies refers to  "
         "the p-value for the joint significance of the three age dummies.     "
         "`enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3g) regressions: Teachers
********************************************************************************
local se  robust
local abs abs(statefip)
local ag2 age2527 age2831 age3239
local agI age2527 age2831 age3239 age2527XTeach age2831XTeach age3239XTeach
local edu highEduc
local une unemployment
local une 

*gen teachers = occ2010>=2300&occ2010<=2330
*lab var teachers "School Teachers"
gen teachers = twoLevelOcc=="Education, Training, and Library Occupations"
lab var teachers "Education, Library, Training"
foreach age in 2527 2831 3239 {
    gen age`age'XTeach = age`age'*teachers
    lab var age`age'XTeach "Aged `age' $\times$ Education Occup"
}
gen quarter2 = birthQuarter == 2
lab var quarter "Quarter II"

eststo: areg goodQuarter teachers `agI' `edu' `une' _year*  `wt', `abs' `se'
test `agI'
local F1 = round(r(p)*1000)/1000
eststo: areg goodQuarter teachers `ag2' `edu' `une' _year*  `wt', `abs' `se'
test `ag2'
local F2 = round(r(p)*1000)/1000
eststo: areg goodQuarter teachers       `edu' `une' _year*  `wt', `abs' `se'
eststo: areg goodQuarter teachers       `edu'       _year*  `wt', `abs' `se'
eststo: areg goodQuarter teachers                   _year*  `wt', `abs' `se'
eststo:  reg goodQuarter teachers                           `wt',       `se'



#delimit ;
esttab est6 est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers.tex",
replace `estopt' title("Season of Birth and Occupation (Teachers)")
keep(_cons teachers `agI' `ag2' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("F-test of Age Dummies&    &    &     &     &0`F2'&0`F1'\\            "
         "State and Year FE&&Y&Y&Y&Y&Y\\                        \bottomrule    "
         "\multicolumn{7}{p{21.8cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic married       "
         "mothers aged 25-45 included in ACS data where the mother is either   "
         " the head of the household or the partner of the head of the         "
         "household and works in an occupation with at least 500 workers in the"
         "sample. Education, Library, Training refers to individuals employed  "
         "in this occupation (occ codes 2200-2550).  The omitted occupational  "
         "category is all non-educational occupations, and the omitted age     "
         "category is 40-45 year old women. F-test of age dummies refers to    "
         "the p-value for the joint significance of the three age dummies.     "
         "`enote'"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear



********************************************************************************
*** (3h) Twin regression
********************************************************************************
use "$DAT/`data'", clear
keep if marst==1
keep if motherAge>=25&motherAge<=45&twins==1
tab year    , gen(_year)
tab statefip, gen(_state)
gen young = motherAge>=25&motherAge<=39
lab var young "Aged 25-39"

lab var unemployment "Unemployment Rate"

local se  robust 
local abs abs(statefip)
local age age2527 age2831 age3239
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
keep if marst==1

generat ageGroup        = 1 if motherAge>=25&motherAge<40
replace ageGroup        = 2 if motherAge>=40&motherAge<=45
generat educLevel       = highEduc
replace educLevel       = 2 if educd>=101
gen teachers = occ2010>=2300&occ2010<=2330
lab var teachers "School Teachers"
bys twoLevelOcc: gen counter = _N
keep if counter>500
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
keep if motherAge>=25&motherAge<=45&twins==0
generat young     =   motherAge <=39

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)
 
lab var educYrs   "Years of education"
lab var married   "Married"
lab var young     "Young (aged 25-39)"
lab var highEduc  "Some College +"
lab var goodQuart "Good Season of Birth"
lab var motherAge "Mother's Age"


#delimit ;
estpost tabstat motherAge married young age2527 age2831 age3239 age4045
                highEduc educYrs goodQuarter,
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


********************************************************************************
*** (6e) Figure 6-8
********************************************************************************
preserve
cap drop teachers
generat teachers = 1 if twoLev == "Education, Training, and Library Occupations"
replace teachers = 2 if teachers==.
bys state: gen statecount = _N

collapse goodQuarter (min) cold, by(teachers statefip state fips state*)

lab var goodQuarter "Proportion good season"
lab var cold        "Coldest monthly average (degree F)"
local cc statecount>500

format goodQuarter %5.2f
foreach num of numlist 1 2 {
    local age teachers
    if `num'==2 local age nonteachers
    drop if state=="Alaska"
    
    corr goodQuarter cold if teachers==`num' & `cc'
    local ccoef = string(r(rho),"%5.3f")
    #delimit ;
    twoway scatter goodQuarter cold if teachers==`num'& `cc', mlabel(state) ||      
        lfit goodQuarter cold if teachers==`num'& `cc', scheme(s1mono)
        lcolor(gs0) legend(off) lpattern(dash)
    note("Correlation coefficient=`ccoef'");
    graph export "$GRA/`age'TempCold.eps", as(eps) replace;
    #delimit cr
}
restore
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

********************************************************************************
*** (7) Occupations
********************************************************************************
use "$DAT/`data'", clear
keep if marst==1

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
replace occAlt2 = 3 if twoL=="Architecture and Engineering Occupations"


preserve
collapse (sum) birth, by(birthQuarter occAlt2)
drop if occAlt == .
bys occAlt: egen totalbirth = sum(birth)
gen birthProportion = birth/totalbirth


#delimit ;
graph bar birthProportion, over(birthQuar, relabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4"))
over(occAlt, relabel(1 "Education" 2 "Significant" 3 "Architecture/Engineering"))
scheme(s1mono) exclude0 ytitle("Proportion of Births in Quarter"); 
graph export "$GRA/birthsOccupation2.eps", as(eps) replace;
#delimit cr
restore



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

keep if motherAge>=25&motherAge<=45&twins==0
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


