/* nvssRegs.do v0.00             damiancclarke             yyyy-mm-dd:2015-04-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses NVSS data on first births and runs regressions on births by quar-
ter, allowing for additional controls, fixed effects, and so forth.

The main set of tables are made for married women only.  In the online appendix,
the results are replicated for married and unmarried women.  Running this file m
akes the main tables, however, if the full sample results are desired, the local
on line 19 should be set equal to 1.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/births/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

#delimit ;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats        
             (N, fmt(%9.0g) labels(Observations))
             collabels(none) label;
*             (N r2, fmt(%9.0g %5.3f) labels(Observations R-Squared))
local yFE    i.year;
local se     robust;
local Fnote  "F-test of age variables refers to the test that
              the coefficients on mother's age and age squared are jointly
              equal to zero. Reported p-values are those corresponding to
              this classical F-test.";
local onote  "Optimal age calculates the turning point of the mother's age
              quadratic.";
local enote  "Heteroscedasticity robust standard errors are reported in
              parentheses.";
#delimit cr

********************************************************************************
*** (2) Open data for births and deaths
********************************************************************************
use          "$DAT/nvss2005_2013_all"
append using "$DAT/nvssFD2005_2013_all"

replace motherAge2 = motherAge2/100
lab var motherAge2 "Mother's Age$^2$ / 100"
replace PrePregWt = PrePregWt/10
lab var PrePregWt  "Pre-Pregnancy Weight / 10"
lab var height     "Height (Inches)"
lab var overweight  "Pre-pregnancy Overweight $(25\leq$ BMI$ <30)$ "
lab var underweight "Pre-pregnancy Underweight (BMI$ <18.5)$ "
lab var obese       "Pre-pregnancy Obese (BMI$ \geq 30)$ "

gen educYrs   = educCat
gen educYrsSq = educYrs*educYrs
lab var educYrs   "Years of Education"
lab var educYrsSq "Education Squared"
gen quarter2 = birthQuarter==2
gen quarter3 = birthQuarter==3
lab var quarter2 "Quarter 2"
lab var quarter3 "Quarter 3"





********************************************************************************
*** (X) Run for quarter 2 and 3
********************************************************************************
#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 White unmarried" "';
local nam All whiteMarried whiteUnmarried;
#delimit cr
tokenize `nam'

local age motherAge motherAge2
local edu highEd
local c2  WIC underweight overweight obese noART
local yab abs(fips)

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==1 local nc white black hispanic married
    if `k'!=1 local nc hispanic

    local con smoker i.gestation `nc'
    foreach Q in 2 3 {
        preserve
        keep if twin==1&liveBirth==1&birthOrder==1&`gg'
        count
        eststo: areg quarter`Q' `age' `edu' `con' _year*, `se' `yab'
        test `age'
        local F1a= string(r(F), "%5.3f")
        local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
        local pvL  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2

        eststo: areg quarter`Q' `age'       _year* if e(sample) , `se' `yab'
        test `age'
        local F2a= string(r(F), "%5.3f")
        local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        eststo:  reg quarter`Q' `age'              if e(sample) , `se'
        test `age'
        local F3a= string(r(F), "%5.3f")
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        keep if year>=2009&ART!=.&WIC!=.&underweight!=.
        eststo: areg quarter`Q' `age' `edu' `con' _year*, `se' `yab'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

        eststo: areg quarter`Q' `age' `edu' `con' `c2' _year*, `se' `yab'
        test `age'
        local F5a= string(r(F), "%5.3f")
        local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        #delimit ;
        local not "All singleton, first born children from the indicated sample 
        are included. `Fnote' Leamer critical values refer to Leamer/Schwartz/Deaton 
        critical 5\% values adjusted for sample size. The Leamer critical value 
        for a t-statistic is `tL1' in columns 1-3 and `tL4' in columns 4 and 5.
        `onote' `enote' $^{\ddagger}$ Siginificant based on Leamer criterion.";

        esttab est3 est2 est1 est4 est5 using "$OUT/NVSSBinaryQ`Q'_``k''.tex",
        replace `estopt' keep(`age' `edu' smoker `c2' `nc') 
        title("Season of Birth Correlates (Quarter `Q', `type')") booktabs 
        style(tex) mlabels(, depvar)
        starlevel ("$ ^{\ddagger} $" `pvL')
        postfoot("F-test of Age Variables  &`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\ "
                 "Leamer Critical Value (F)&`L1'&`L1'&`L1'&`L4'&`L4' \\      "
                 "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\         "
                 "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\       "
                 "2009-2013 Only&&&&Y&Y\\ \bottomrule                        "
                 "\multicolumn{6}{p{16.2cm}}{\begin{footnotesize} `not'"
                 "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
        restore
    }
    local ++k
}

********************************************************************************
*** (X) Alternative Regressions
********************************************************************************
#delimit ;
local add `" "(excluding babies conceived in Nomvember or December)"
             "(second births)" "(including fetal deaths)" "';
local nam NoNovDec Birth2 IncludeFD;
#delimit cr
tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg liveBirth==1&birthOrder==1&birthMonth!=9&birthMonth!=8
    if `k'==2 local gg liveBirth==1&birthOrder==2
    if `k'==3 local gg birthOrder==1

    local con smoker i.gestation hispanic
    foreach Q in 2 3 {
        preserve
        keep if twin==1&motherAge>=20&motherAge<=45&white==1&married==1&`gg'
        count
    
        eststo: areg quarter`Q' `age' `edu' `con' _year* `spcnd', `se' `yab'
        test `age'
        local F1a= string(r(F), "%5.3f")
        local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
        local pvL  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2

        eststo: areg quarter`Q' `age'       _year* if e(sample) , `se' `yab'
        test `age'
        local F2a= string(r(F), "%5.3f")
        local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        eststo:  reg quarter`Q' `age'              if e(sample) , `se'
        test `age'
        local F3a= string(r(F), "%5.3f")
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        keep if year>=2009&ART!=.&WIC!=.&underweight!=.
        eststo: areg quarter`Q' `age' `edu' `con' _year* `spcnd', `se' `yab'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

        eststo: areg quarter`Q' `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
        test `age'
        local F5a= string(r(F), "%5.3f")
        local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        #delimit ;
        local not "All singleton, first births occurring to white, married
        women aged 20-45 from the indicated sample are included. `Fnote'
        Leamer critical values refer to Leamer/Schwartz/Deaton critical 5\%
        values adjusted for sample size. The Leamer critical value for a
        t-statistic is `tL1' in columns 1-3 and `tL4' in columns 4 and 5.
        `onote' `enote' $^{\ddagger}$ Siginificant based on Leamer criterion.";

        esttab est3 est2 est1 est4 est5 using "$OUT/NVSSBinaryQ`Q'_``k''.tex",
        replace `estopt' keep(`age' `edu' smoker `c2' hispanic) 
        title("Season of Birth Correlates (Quarter `Q', `type')") booktabs 
        style(tex) mlabels(, depvar)
        starlevel ("$ ^{\ddagger} $" `pvL')
        postfoot("F-test of Age Variables  &`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\ "
                 "Leamer Critical Value (F)&`L1'&`L1'&`L1'&`L4'&`L4' \\      "
                 "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\         "
                 "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\       "
                 "2009-2013 Only&&&&Y&Y\\ \bottomrule                        "
                 "\multicolumn{6}{p{16.2cm}}{\begin{footnotesize} `not'"
                 "\end{footnotesize}}\end{tabular}\end{table}");
        #delimit cr
        estimates clear
        restore
    }
    local ++k
}

********************************************************************************
*** (X) Clear
********************************************************************************
log close
