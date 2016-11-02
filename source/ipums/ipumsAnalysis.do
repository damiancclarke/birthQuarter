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
            parentheses. $ ^\ddagger $ Significant based on the Leamer criterion
            at 5\%.";
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

/*
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

/*
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
local add `" "(All Observations, 20--45)" "(White Married Mothers, 20--45) "
     "(Black Unmarried Mothers, 20--45)"  "(White Unmarried Mothers, 20--45)" "';
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
    local race white
    local mar  unmarried
    if `k'==3 local race black
    if `k'==2 local mar maried

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
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize}Sample consists of"
             " all singleton first-born children in the US born to `race' `mar'"
             " mothers aged 20-45 included in 2005-2014 ACS data where the     "
             "mother is either the head of the                                 "
             "household or the partner of the head of the household and works  "
             "in an occupation with at least 500 workers in the full sample.   "
             "Occupation classification is provided by the 2 digit occupation  "
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
    postfoot("State and Year Fixed Effects&Y&Y\\                                "
             "$ \chi^2 $ test of Occupation Dummies&`F1'&`F2'\\                 "
             "$\chi^2 $ test of Age Variables&`F1a'&`F2a'\\ \bottomrule         "
             "\multicolumn{3}{p{13.6cm}}{\begin{footnotesize}  Refer to notes   "
             "in table \ref{ACS``k''}.  Results are replicated here using a     "
             "Logit regression and reporting average marginal effects. $\chi^2$ "
             "tests for occupation report p-values of joint significance of the "
             "dummies, and `Xnote' The Leamer critical value for the            "
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
             "all singleton first-born children born in the US to `race' `mar'  "
             "mothers aged 20-45 included in 2005-2014 ACS data where the mother"
             " is either the head of the                                        "
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

*/
********************************************************************************
*** (5) Sumstats (all)
********************************************************************************
generat young     =   motherAge <=39
gen teacher=twoLevelOcc =="Education, Training, and Library Occupations"
gen quarter1 = birthQuarter==1
gen quarter4 = birthQuarter==4

local rd (1=2) (2=6) (3=9) (4=10) (5=11) (6=12) (7=13) (8=14) (10=15) (11=16)
recode educ `rd', gen(educYrs)
 
lab var educYrs   "Years of education"
lab var married   "Married"
lab var young     "Young (aged 25-39)"
lab var highEduc  "Some College +"
lab var goodQuart "Good Season of Birth"
lab var motherAge "Mother's Age"
lab var teacher   "Works in Education, Training and Library"
lab var quarter1  "Quarter 1 Birth"
lab var quarter2  "Quarter 2 Birth"
lab var quarter3  "Quarter 3 Birth"
lab var quarter4  "Quarter 4 Birth"

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
    if `k'==1 local edu black white hispanic married
    if `k'==2 local edu hispanic
    if `k'==3 local edu hispanic
    if `k'==4 local edu hispanic

    preserve
    keep if `gg'
    #delimit ;
    estpost tabstat motherAge `edu' young age2024 age2527 age2831 age3239 
    age4045 highEduc educYrs teacher quarter1 quarter2 quarter3 quarter4,
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
*/

use $DAT/ipums_00071, clear
drop if qsex==4
drop if qrelate==4
drop if qage==4
keep if age>=20&age<=45

#delimit ;
local l2 " `"Management Occupations"' `"Business Operations Specialists"'
           `"Financial Specialists"' `"Computer and Mathematical Occupations"'
           `"Architecture and Engineering Occupations"'
           `"Life, Physical, and Social Science Occupations"'
           `"Community and Social Services Occupations"'
           `"Legal Occupations"'
           `"Education, Training, and Library Occupations"'
           `"Arts, Design, Entertainment, Sports, and Media Occupations"'
           `"Healthcare Practitioners and Technical Occupations"'
           `"Healthcare Support Occupations"' `"Protective Service Occupations"'
           `"Food Preparation and Serving Occupations"'
           `"Building and Grounds Cleaning and Maintenance Occupations"'
           `"Personal Care and Service Occupations"' `"Sales Occupations"'
           `"Office and Administrative Support Occupations"'
           `"Farming, Fishing, and Forestry Occupations"'
           `"Construction Trades"' `"Extraction Workers"'
           `"Installation, Maintenance, and Repair Workers"'
           `"Production Occupations"'
           `"Transportation and Material Moving Occupations"'
           `"Military Specific Occupations"' `"Unemployed"' ";
local n2   occ2010>0&occ2010<=430      occ2010>=500&occ2010<=730
occ2010>=800&occ2010<=950   occ2010>=1000&occ2010<=1240
occ2010>=1300&occ2010<=1560 occ2010>=1600&occ2010<=1960
occ2010>=2000&occ2010<=2060 occ2010>=2100&occ2010<=2150
occ2010>=2200&occ2010<=2550 occ2010>=2600&occ2010<=2960
occ2010>=3000&occ2010<=3540 occ2010>=3600&occ2010<=3650
occ2010>=3700&occ2010<=3950 occ2010>=4000&occ2010<=4160
occ2010>=4200&occ2010<=4250 occ2010>=4300&occ2010<=4650
occ2010>=4700&occ2010<=4965 occ2010>=5000&occ2010<=5940
occ2010>=6000&occ2010<=6130 occ2010>=6200&occ2010<=6765
occ2010>=6800&occ2010<=6940 occ2010>=7000&occ2010<=7630
occ2010>=7700&occ2010<=8965 occ2010>=9000&occ2010<=9750
occ2010>=9800&occ2010<9920  occ2010==9920;
#delimit cr
gen twoLevelOcc = ""
tokenize `n2'
foreach job of local l2 {
    replace twoLevelOcc = "`job'" if `1'
    macro shift
}
gen working1 = empstat==1
gen working2 = uhrswork!=0
drop if occ2010>=9800&occ2010<9920

sum working1 working2 
sum working1 working2 if nchlt==1&nchild==1&eldch==0
sum working1 working2 if nchlt==1&nchild==1&eldch==1
sum working1 working2 if nchlt==1&nchild==1&eldch==2
sum working1 working2 if nchlt==1&nchild==1&eldch==3
sum working1 working2 if nchlt==1&nchild==1&eldch==4


local kid0 nchlt==1&nchild==1&eldch==0
local kid1 nchlt==1&nchild==1&eldch==1
local kid2 nchlt==1&nchild==1&eldch==2
local kid3 nchlt==1&nchild==1&eldch==3
local kid4 nchlt==1&nchild==1&eldch==4

file open f1 using "$SUM/jobDynamicsMothers.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 1 (White, Married, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working1 if race==1&marst==1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working1 if race==1&marst==1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1


file open f1 using "$SUM/jobDynamicsMothers_whiteUn.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 1 (White, Unmarried, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working1 if race==1&marst!=1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working1 if race==1&marst!=1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1

file open f1 using "$SUM/jobDynamicsMothers_blackUn.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 1 (Black, Unmarried, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working1 if race==2&marst!=1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working1 if race==2&marst!=1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1



file open f1 using "$SUM/jobDynamicsMothers-2.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 2 (White, Married, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working2 if race==1&marst==1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working2 if race==1&marst==1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1


file open f1 using "$SUM/jobDynamicsMothers_whiteUn-2.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 2 (White, Unmarried, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working2 if race==1&marst!=1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working2 if race==1&marst!=1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1


file open f1 using "$SUM/jobDynamicsMothers_blackUn-2.tex", write replace
#delimit ;
file write f1 "\begin{table}[htpb]\begin{center}"_n
"\caption{Proportion Working and Birth Dynamics: Definition 2 (Black, Unmarried, 20-45)}"
"\begin{tabular}{lcccccc} \toprule" _n
"&\multicolumn{5}{c}{Child's Age}& No Children  \\" _n
"Occupation&0&1&2&3&4&\\ \midrule" _n;
#delimit cr


levelsof twoLevelOcc, local(jobs)
foreach occ of local jobs {
    foreach n of numlist 0(1)4 {
        sum working2 if race==2&marst!=1&twoLevelOcc=="`occ'"&`kid`n''
        local m`n'=string(r(mean),"%5.3f")
    }
    sum working2 if race==2&marst!=1&twoLevelOcc=="`occ'"
    local ma = string(r(mean),"%5.3f")
    file write f1 "`occ'&`m0'&`m1'&`m2'&`m3'&`m4'&`ma' \\" _n
}
file write f1 "\midrule \end{tabular}\end{center}\end{table}"
file close f1
