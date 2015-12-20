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

local data   ACS_20052014_cleaned.dta
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats /*
*/           (N, fmt(%9.0g) label(Observations))     /*
*/           starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
local wt     [pw=perwt]

********************************************************************************
*** (2) Open data subset to sample of interest (from Sonia's import file)
********************************************************************************
use "$DAT/`data'"
keep if motherAge>=25&motherAge<=45&twins==0
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

eststo: areg goodQuarter `age' `edu' `une' _year* _state*      `wt', abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample) `wt', `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample) `wt',          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSBinary.tex",
replace `estopt' title("Season of Birth Correlates (IPUMS 2005-2014)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Standard errors are clustered by state.  "
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

eststo: areg goodQuarter `age' `edu' `une' _year* _state*      `wt', abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample) `wt', `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample) `wt',          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/goodQuarter_Years.tex",
replace `estopt' title("Season of Birth Correlates (Continuous Age)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Standard errors are clustered by state.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3c) regressions: age quadratic
********************************************************************************
local age motherAge motherAge2

eststo: areg goodQuarter `age' `edu' `une' _year* _state*      `wt', abs(occ) `se'
eststo: areg goodQuarter `age' `edu' `une' _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age' `edu'       _year* if e(sample) `wt', `abs'    `se'
eststo: areg goodQuarter `age'             _year* if e(sample) `wt', `abs'    `se'
eststo:  reg goodQuarter `age'                    if e(sample) `wt',          `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/goodQuarter_YearsSquared.tex",
replace `estopt' title("Season of Birth Correlates (Age and Age Squared)")
keep(_cons `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\ Occupation FE&&&&&Y\\ \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Standard errors are clustered by state.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3d) regressions: good season and education interaction
********************************************************************************
local se  cluster(statefip)
local abs abs(statefip)

gen age2527XhighEd=age2527*highEduc
gen age2831XhighEd=age2831*highEduc
gen age3239XhighEd=age3239*highEduc

lab var age2527XhighEd "Aged 25-27 $\times$ Some College"
lab var age2831XhighEd "Aged 28-31 $\times$ Some College"
lab var age3239XhighEd "Aged 32-39 $\times$ Some College"
    
local age1  age2527 age2831 age3239
local age1X age2527XhighEd age2831XhighEd age3239XhighEd
eststo: areg goodQua `age1' highEduc `age1X' _year*              `wt', `abs' `se'
eststo: areg goodQua `age1' highEduc         _year* if e(sample) `wt', `abs' `se'
eststo: areg goodQua `age1'                  _year* if e(sample) `wt', `abs' `se'

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)
 
gen motherAgeXeduc  = motherAge*educYrs
gen motherAge2Xeduc = motherAge2*educYrs

lab var educYrs         "Years of education"
lab var motherAge2Xeduc "Mother's Age$2$ $\times$ Education"

local age2  motherAge motherAge2
local age2X motherAgeXeduc motherAge2Xeduc
eststo: areg goodQua `age2' educYrs `age2X' _year*             `wt', `abs' `se'
eststo: areg goodQua `age2' educYrs        _year* if e(sample) `wt', `abs' `se'
eststo: areg goodQua `age2'                _year* if e(sample) `wt', `abs' `se'

local kvar `age1' highEduc `age1X' `age2' educYrs `age2X'
#delimit ;
esttab est3 est2 est1 est6 est5 est4 using "$OUT/IPUMSBinaryEducAge.tex",
replace `estopt' booktabs keep(`kvar') mlabels(, depvar)
title("Season of Birth, Age and Education")
postfoot("\bottomrule                                                      "
         "\multicolumn{7}{p{20cm}}{\begin{footnotesize}Sample consists     "
         " of singleton first-born children to non-Hispanic white women    "
         "aged 25-45. ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

********************************************************************************
*** (3e) regressions: industry
********************************************************************************
tab oneLevelOcc, gen(_1occ)
tab twoLevelOcc, gen(_2occ)
tab occ        , gen(_occ)

local se  cluster(statefip)
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment
local lv1 _1occ*
local lv2 _2occ*
local lv3 _occ*

eststo: areg goodQuarter `age' `edu' `une' _year* `lv3' `wt', `se' `abs'
ds _occ*
local tvar `r(varlist)'
test `tvar'
local F3 = round(r(p)*1000)/1000
if `F3' == 0 local F3 0.000

eststo:  areg goodQuarter `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
ds _2occ*
local tvar `r(varlist)'
test `tvar'
local F2 = round(r(p)*1000)/1000
if `F2' == 0 local F2 0.000

eststo:  areg goodQuarter `age' `edu' `une' _year* `lv1' `wt', `se' `abs'
ds _1occ*
local tvar `r(varlist)'
test `tvar'
local F1 = round(r(p)*1000)/1000

eststo:  areg goodQuarter `age' `edu' `une' _year*       `wt', `se' `abs'

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/IPUMSIndustry.tex",
replace `estopt' title("Season of Birth and Industry")
keep(_cons `age' `edu' `une' `lv1' `lv2') style(tex) booktabs mlabels(, depvar) 
postfoot("Occupation Codes (level) &&1&2&3\\                                   "
         "p-value on F-test of Occupation Dummies&&`F1'&`F2'&`F3'\\ \bottomrule"
         "\multicolumn{5}{p{20.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Industry codes refer to the level of occupation codes (1  "
         "digit, 2 digit, or 3 digit)"
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3f) regressions: Using Goldin's occupation classes
********************************************************************************
tab GoldinClass, gen(_gc)
local se  cluster(statefip)
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment
local ind _gc1 _gc2 _gc3 _gc4

eststo: areg goodQuarter `ind' `age' `edu' `une' _year*  `wt', `abs' `se'
eststo: areg goodQuarter `ind' `age' `edu' `une' _year*  `wt', `abs' `se'
eststo: areg goodQuarter `ind' `age' `edu'       _year*  `wt', `abs' `se'
eststo: areg goodQuarter `ind' `age'             _year*  `wt', `abs' `se'
eststo:  reg goodQuarter `ind' `age'                     `wt',       `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSIndustryGoldin.tex",
replace `estopt' title("Season of Birth and Occupation (Goldin's Classification)")
keep(_cons `ind' `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\                       \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Standard errors are clustered by state. Occupations are   "
         "categorised as in Goldin (2014) table A1.  The omitted category is   "
         "Other Occupations."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3g) regressions: Teachers
********************************************************************************
local se  cluster(statefip)
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment

gen teachers = occ2010>=2300&occ2010<=2330
lab var teachers "School Teachers"

eststo: areg goodQuarter teachers `age' `edu' `une' _year*  `wt', `abs' `se'
eststo: areg goodQuarter teachers `age' `edu' `une' _year*  `wt', `abs' `se'
eststo: areg goodQuarter teachers `age' `edu'       _year*  `wt', `abs' `se'
eststo: areg goodQuarter teachers `age'             _year*  `wt', `abs' `se'
eststo:  reg goodQuarter teachers `age'                     `wt',       `se'

#delimit ;
esttab est5 est4 est3 est2 est1 using "$OUT/IPUMSTeachers.tex",
replace `estopt' title("Season of Birth and Occupation (Teachers)")
keep(_cons teachers `age' `edu' `une') style(tex) booktabs mlabels(, depvar) 
postfoot("State and Year FE&&Y&Y&Y&Y\\                       \bottomrule       "
         "\multicolumn{6}{p{17.2cm}}{\begin{footnotesize}Sample consists of all"
         " first born children in the USA to white, non-hispanic mothers aged  "
         "25-45 included in ACS data where the mother is either the head of the"
         " household or the partner (married or unmarried) of the head of the  "
         "household. Standard errors are clustered by state. School teachers   "
         "include Pre-school, Elementary, Middle, Secondary and Special        "
         "Education levels (occ codes 2300-2330)."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

********************************************************************************
*** (3h) Twin regression
********************************************************************************
use "$DAT/`data'", clear
keep if motherAge>=25&motherAge<=45&twins==1
tab year    , gen(_year)
tab statefip, gen(_state)

lab var unemployment "Unemployment Rate"

local se  cluster(statefip)
local abs abs(statefip)
local age age2527 age2831 age3239
local edu highEduc
local une unemployment

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
         "of the household. Standard errors are clustered by state.  "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

exit
********************************************************************************
*** (4) Sumstats of good season by various levels
********************************************************************************
use "$DAT/`data'", clear
generat ageGroup        = 1 if motherAge>=25&motherAge<40
replace ageGroup        = 2 if motherAge>=40&motherAge<=45
generat educLevel       = highEduc
replace educLevel       = 2 if educd>=101

lab def ag 1 "Young (25-39) " 2 "Old (40-45) "
lab def ed 0 "No College" 1 "Some College" 2 "Complete College"
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
gen youngBeta = .
gen youngHigh = .
gen youngLoww = .
gen youngQuar = .

generat Xvar = 1 if motherAge>=28&motherAge<=31
replace Xvar = 0 if motherAge>=40&motherAge<=45
foreach num of numlist 1(1)4 {
    gen quarter`num' = birthQuarter == `num'
    qui reg quarter`num' Xvar
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


********************************************************************************
*** (6b) Figure 3 (NVSS)
********************************************************************************
preserve
keep if motherAge>=25
tab motherAge, gen(_age)
reg goodQuarter _age1-_age15 if motherAge>=25&motherAge<=45

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

collapse (sum) birth, by(birthQuarter youngOld)
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

collapse (sum) birth, by(birthQuarter youngOld educlevels)
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

collapse (sum) birth, by(goodQuarter ageG2)
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
*** (X) Close
********************************************************************************
log close
dis _newline(5) " Terminated without Error" _newline(5)
