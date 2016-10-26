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
local Fnote  "F-test of age variables refers to the F-statistic on the test that
              the coefficients on mother's age and age squared or all occupation
              dummies are jointly equal to zero. ";
local Xnote  "$ \chi^2 $ test statistics refer to the test that the coefficients
              on mother's age and age squared or all occupation dummies are
              jointly equal to zero. ";
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
local lv2 _2occ1 _2occ3 _2occ4 _2occ5 _2occ6 _2occ7 _2occ8 _2occ9 _2occ10 /*
*/ _2occ11 _2occ12 _2occ13 _2occ14 _2occ15 _2occ16 _2occ17 _2occ18 _2occ19 _2occ20      
cap drop _2occ2
gen nowork = workedyr==2
lab var nowork "Did Not Work Last Year"

#delimit ;
local add `" "(20-45 All Observations)" " "
             "(20-45 Black Unmarried Mothers)"  "(20-45 White Unmarried Mothers)" "';
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
    if `k'==3 local edu highEduc hispanic
    if `k'==4 local edu highEduc hispanic

    preserve
    keep if `gg'
 

    eststo: areg quarter2 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F1 = string(r(F),"%5.3f")
    test `age'
    local F1a = string(r(F),"%5.3f")
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    local pvL = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))

    eststo: areg quarter3 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F2 = string(r(F),"%5.3f")
    test `age'
    local F2a = string(r(F),"%5.3f")
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
    #delimit ;
    esttab est1 est2 using "$OUT/IPUMSIndustry_``k''.tex", replace `estopt' 
    title("Season of Birth Correlates in ACS `type'" \label{ACS``k''})
    keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
    starlevel ("$ ^\ddagger $ " `pvL') 
    postfoot("State and Year Fixed Effects&Y&Y\\                               "
             "F-test of Occupation Dummies&`F1'&`F2'\\                         "
             "F-test of Age Variables&`F1a'&`F2a'\\ \bottomrule                "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize}Sample consists   "
             "all singleton first-born children in the US to mothers aged of   "
             "20-45 included in 2005-2014 ACS data where the mother is in the  "
             "respective race/marital sample and either the head of the        "
             "household or the partner of the head of the household and work   "
             "in an occupation with at least 500 workers in the full sample.   "
             "Occupation classification is provided by the 2 digit occupatio   "
             "codes from the census. The omitted occupational category in      "
             "column 2 is Arts, Design, Entertainment, Sports, and Media, as   "
             "this occupation has Q2+Q3=0.500(0.500).  F-tests for occupation  "
             "report p-values of joint significance of the dummies, and `Fnote'"
             " The Leamer critical value for the t-statistic is `tL1'. `lnote' "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear


    logit quarter2 `age' `edu' `une' _year* `lv2' i.statefip `wt', `se'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F1 = string(r(chi2),"%5.3f")
    test `age'
    local F1a = string(r(chi2),"%5.3f")
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local dfr = e(N)-e(rank)
    local tL1  = string(sqrt((`dfr'/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    local pvL = ttail(e(N),sqrt((`dfr'/1)*(e(N)^(1/e(N))-1)))
    margins, dydx(`age' `edu' `une' `lv2') post
    estimates store m1

    logit quarter3 `age' `edu' `une' _year* `lv2' i.statefip `wt', `se'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F2 = string(r(chi2),"%5.3f")
    test `age'
    local F2a = string(r(chi2),"%5.3f")
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    margins, dydx(`age' `edu' `une' `lv2') post
    estimates store m2
    
    #delimit ;
    esttab m1 m2 using "$OUT/IPUMSIndustryLogit_``k''.tex", replace `estopt' 
    title("Logit Estimates of Season of Birth Correlates in ACS `type'")
    keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels("Quarter 2" "Quarter 3")
    starlevel ("$ ^\ddagger $ " `pvL') 
    postfoot("State and Year Fixed Effects&Y&Y\\                               "
             "$ \chi^2 $ test of Occupation Dummies&`F1'&`F2'\\                "
             "$\chi^2 $ test of Age Variables&`F1a'&`F2a'\\ \bottomrule        "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize}  Refer to notes  "
             "in table \ref{ACS``k''}.  Results are replicated here using a    "
             "Logit regression and reporting average marginal effects. F-tests "
             "for occupation report p-values of joint significance of the      "
             "dummies, and `Xnote' The Leamer critical value for the           "
             "t-statistic is `tL1'. `lnote' "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear



    if `k'==1 local edu highEduc hispanic black white married nowork
    if `k'==2 local edu highEduc hispanic nowork
    if `k'==3 local edu highEduc hispanic nowork
    if `k'==4 local edu highEduc hispanic nowork

    eststo: areg quarter2 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F1 = string(r(F),"%5.3f")
    test `age'
    local F1a = string(r(F),"%5.3f")
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    local pvL = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))

    eststo: areg quarter3 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F2 = string(r(F),"%5.3f")
    test `age'
    local F2a = string(r(F),"%5.3f")
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
    #delimit ;
    esttab est1 est2 using "$OUT/IPUMSIndustryNoWork_``k''.tex", replace `estopt' 
    title("Season of Birth Correlates in ACS with No Work Control `type'")
    keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
    starlevel ("$ ^\ddagger $ " `pvL') 
    postfoot("State and Year Fixed Effects&Y&Y\\                               "
             "F-test of Occupation Dummies&`F1'&`F2'\\                         "
             "F-test of Age Variables&`F1a'&`F2a'\\ \bottomrule                "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize} Refer to notes  "
             "in table \ref{ACS``k''}."
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear


    logit quarter2 `age' `edu' `une' _year* `lv2' i.statefip `wt', `se'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F1 = string(r(chi2),"%5.3f")
    test `age'
    local F1a = string(r(chi2),"%5.3f")
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local dfr = e(N)-e(rank)
    local tL1  = string(sqrt((`dfr'/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    local pvL = ttail(e(N),sqrt((`dfr'/1)*(e(N)^(1/e(N))-1)))
    margins, dydx(`age' `edu' `une' `lv2') post
    estimates store m1

    logit quarter3 `age' `edu' `une' _year* `lv2' i.statefip `wt', `se'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F2 = string(r(chi2),"%5.3f")
    test `age'
    local F2a = string(r(chi2),"%5.3f")
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    margins, dydx(`age' `edu' `une' `lv2') post
    estimates store m2
    
    #delimit ;
    esttab m1 m2 using "$OUT/IPUMSIndustryLogitNoWork_``k''.tex", replace `estopt' 
    title("Logit Estimates of Season of Birth Correlates in ACS with No Work Control `type'")
    keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels("Quarter 2" "Quarter 3")
    starlevel ("$ ^\ddagger $ " `pvL') 
    postfoot("State and Year Fixed Effects&Y&Y\\                               "
             "$ \chi^2 $ test of Occupation Dummies&`F1'&`F2'\\                "
             "$\chi^2 $ test of Age Variables&`F1a'&`F2a'\\ \bottomrule        "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize} Refer to notes  "
             "in table \ref{ACS``k''}."
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    if `k'==1 local edu highEduc logInc hispanic black white married
    if `k'==2 local edu highEduc logInc hispanic
    if `k'==3 local edu highEduc logInc hispanic
    if `k'==4 local edu highEduc logInc hispanic

    eststo:  areg quarter2 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F1 = string(r(F),"%5.3f")
    test `age'
    local F1a = string(r(F),"%5.3f")
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
    local pvL = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))
        
    eststo:  areg quarter3 `age' `edu' `une' _year* `lv2' `wt', `se' `abs'
    ds _2occ*
    local tvar `r(varlist)'
    test `tvar'
    local F2 = string(r(F),"%5.3f")
    test `age'
    local F2a = string(r(F),"%5.3f")
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
    #delimit ;
    esttab est1 est2 using "$OUT/IPUMSIndustryInc_``k''.tex", replace 
    title("Season of Birth Correlates in ACS with Income Controls `type'")
    keep(`age' `edu' `une' `lv2') style(tex) booktabs mlabels(, depvar)
    starlevel ("$ ^\ddagger $ " `pvL') `estopt' 
    postfoot("State and Year Fixed Effects&Y&Y\\                                "
             "F-test of Occupation Dummies&`F1'&`F2'\\                          "
             "F-test of Age Variables&`F1a'&`F2a'\\ \bottomrule                 "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize}Sample consists of "
             "all singleton first-born children in the US to mothers aged 20-45 "
             "included in 2005-2014 ACS data where the mother is in the         "
             "respective race/marital sample and either the head of the         "
             "household or the partner of the head of the household and works   "
             "in an occupation with at least 500 workers in the full sample.    "
             "Occupation classification is provided by the 2 digit occupation   "
             "codes from the census. The omitted occupational category is Arts, "
             "Design, Entertainment, Sports, and Media, as this occupation has  "
             "Q2+Q3=0.500(0.500). F-tests for occupation report p-values of     "
             "joint significance of the dummies, and `Fnote' The Leamer critical"
             " value for the t-statistic is `tL1'. `lnote'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
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
    if `k'==1 local edu black white hispanic married
    if `k'==2 local edu hispanic
    if `k'==3 local edu hispanic
    if `k'==4 local edu hispanic

    preserve
    keep if `gg'
    #delimit ;
    estpost tabstat motherAge `edu' young age2024 age2527 age2831 age3239 
                    age4045 highEduc educYrs goodQuarter teacher,
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
