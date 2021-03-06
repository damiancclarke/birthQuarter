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

local allobs  1
local hisp    1
local allrace 1

if `allobs'==0 local f nvss
if `allobs'==1 local f nvssall
if `allobs'==0 local mnote " married "
local fend
if `hisp'==1    local fend _hisp
if `allrace'==1 local fend _all

if `hisp'==1   &`allobs'==0 local f hisp
if `hisp'==1   &`allobs'==1 local f hispall
if `allrace'==1&`allobs'==1 local f raceall
if `allrace'==1&`allobs'==0 local f race

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/nvss"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/`f'/regressions"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

#delimit ;
local qual   birthweight lbw vlbw gestation premature apgar;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats        
             (N, fmt(%9.0g) labels(Observations))
             collabels(none) label;
*             (N r2, fmt(%9.0g %5.3f) labels(Observations R-Squared))
local yFE    i.year;
local se     robust;
local cnd    if twin==1 & motherAge>19 & motherAge <= 45 & liveBirth==1;
local keepif birthOrder==1;
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
*** (2a) Open data for births and deaths
********************************************************************************
use          "$DAT/nvss2005_2013`fend'"
append using "$DAT/nvssFD2005_2013`fend'"
if `allobs'==0 keep if married==1


local mc 
if `allobs'==1              local mc married
if `hisp'==1                local mc hispanic
if `allrace'==1             local mc hispanic black white
if `allobs'==1&`hisp'==1    local mc married hispanic
if `allobs'==1&`allrace'==1 local mc married hispanic black white

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

#delimit ;
gen maternalPolicy = state=="NewJersey"|state=="California";
gen ParentalPolicy = "AB" if state=="California"|state=="Connecticut"|
    state=="DC"|state=="NewJersey"|state=="Hawaii"|state=="Washington"|
    state=="Oregon"|state=="Maine"|state=="NewYork"|state=="Illnois";
replace ParentalPolicy = "F" if state=="Alabama"|state=="Delaware"|
    state=="Georgia"|state=="Idaho"|state=="Kansas"|state=="Michigan"|
    state=="Mississippi"|state=="Missouri"|state=="Nebraska"|
    state=="Nevada"|state=="NorthCarolina"|state=="NorthDakota"|
    state=="Oklahoma"|state=="SouthCarolina"|state=="SouthDakota"|
    state=="Utah"|state=="WestVirginia"|state=="Wyoming";
replace ParentalPolicy = "CDE" if ParentalPolicy == "";
#delimit cr
/*
********************************************************************************
*** (3a) Good Quarter Regressions
********************************************************************************
#delimit ;
local add `" "(maternal leave states)" "(non-maternal leave states)"
             "(Expecting Better: A-B)" "(Expecting Better: C-E)"
             "(Expecting Better F)" "';
local add `" "" "(excluding babies conceived in September)"
           "(second births)" "(only twins)" "(including twins)" "';
local add `" "(excluding babies conceived in August or September)" "';
local add `" ""  "';
local nam MLeave NoMLeave PLeaveAB PLeaveCE PLeaveF;
local nam Main NoSep Bord2 Twin TwinS;
local nam Main;
#delimit cr
tokenize `nam'


foreach type of local add {
    preserve

    local age motherAge motherAge2
    local edu highEd
    local con smoker i.gestation `mc' 
    local c2  WIC underweight overweight obese noART
    local yab abs(fips)
    local spcnd
    local group `cnd'&`keepif'
    local samp1 "singleton"
    local samp2 "first born"
    
    if `"`1'"' == "NoSep"    local spcnd if birthMonth!=9
    if `"`1'"' == "NoAugSep" local spcnd if birthMonth!=9&birthMonth!=8
    if `"`1'"' == "Bord2"    local group `cnd'&birthOrder==2&liveBirth==1
    if `"`1'"' == "Twin"     local group /*
           */ if twin==2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "TwinS"    local group /*
           */ if twin<=2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "MLeave"   local group `cnd'&`keepif'&maternalPolicy==1
    if `"`1'"' == "NoMLeave" local group `cnd'&`keepif'&maternalPolicy==0
    if `"`1'"' == "PLeaveAB" local group `cnd'&`keepif'&ParentalPolicy=="AB"
    if `"`1'"' == "PLeaveCE" local group `cnd'&`keepif'&ParentalPolicy=="CDE"
    if `"`1'"' == "PLeaveF"  local group `cnd'&`keepif'&ParentalPolicy=="F"

    keep `group'
    count
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F1a= string(r(F), "%5.3f")
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
    local tL1  = string(sqrt(  (e(df_r)/1)*(e(N)^(1/e(N))-1)     ), "%5.3f")


    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'
    local F2a= string(r(F), "%5.3f")
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F3a= string(r(F), "%5.3f")
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000
    local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    keep if year>=2009&ART!=.&WIC!=.&underweight!=.
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F4a= string(r(F), "%5.3f")
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000
    local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
    local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

    eststo: areg goodQuarter `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
    test `age'
    local F5a= string(r(F), "%5.3f")
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000
    local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    #delimit ;
    local not "All singleton, first born children from the main sample are included.
    `Fnote' Leamer critical values refer to Leamer/Schwartz/Deaton critical 5\%
    values adjusted for sample size. The Leamer critical value for a t-statistic is
    `tL1' in columns 1-3 and `tL4' in columns 4 and 5. `onote' `enote'
    ***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.";
    #delimit cr


    #delimit ;
    if `"`1'"' != "Main" local not "\textsc{Notes}: Refer to table 3 in the
               main text. The Leamer critical value for a t-statistic is `tL1'
               in columns 1-3 and `tL4' in columns 4 and 5.";
    esttab est3 est2 est1 est4 est5 using "$OUT/NVSSBinary`1'.tex",
    replace `estopt' keep(`age' `edu' smoker `c2' `mc') 
    title("Season of Birth Correlates `type'"\label{tab:bq`1'}) booktabs 
    style(tex) mlabels(, depvar)
    postfoot("F-test of Age Variables&`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\       "
             "p-value of F-test      &`F3'&`F2'&`F1'&`F4'&`F5' \\            "
             "Leamer Critical Value  &`L1'&`L1'&`L1'&`L4'&`L4' \\            "
             "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\             "
             "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\           "
             "2009-2013 Only&&&&Y&Y\\ \bottomrule                            "
             "\multicolumn{6}{p{21cm}}{\begin{footnotesize} `not'"
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear


    macro shift
    restore
}
*/
********************************************************************************
*** (3b) Run for quarter 2 and 3
********************************************************************************
#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 Black and White married and unmarried"
             "15-24 All races married and unmarried" "20-45 Black unmarried"
             "20-45 White unmarried" "';
local nam All whiteMarried blackWhiteAll youngAll blackUnmarried whiteUnmarried;
#delimit cr
tokenize `nam'

gen quarter2 = birthQuarter==2
gen quarter3 = birthQuarter==3
lab var quarter2 "Quarter 2"
lab var quarter3 "Quarter 3"
local age motherAge motherAge2
local edu highEd
local con smoker i.gestation `mc' 
local c2  WIC underweight overweight obese noART
local yab abs(fips)

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&(white==1|black==1)
    if `k'==4 local gg motherAge>=15&motherAge<=24
    if `k'==5 local gg motherAge>=20&motherAge<=45&black==1&married==0
    if `k'==6 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==1 local nc white black hispanic married
    if `k'==2 local nc hispanic
    if `k'==3 local nc black hispanic married
    if `k'==4 local nc white black hispanic married
    if `k'==5 local nc 
    if `k'==6 local nc hispanic

    local con smoker i.gestation `nc'
    foreach Q in 2 3 {
        preserve
        keep if twin==1&liveBirth==1&birthOrder==1&`gg'
        count
        eststo: areg quarter`Q' `age' `edu' `con' _year* `spcnd', `se' `yab'
        test `age'
        local F1a= string(r(F), "%5.3f")
        local F1 = round(r(p)*1000)/1000
        if   `F1' == 0 local F1 0.000
        local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
        local pvL  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2

        eststo: areg quarter`Q' `age'       _year* if e(sample) , `se' `yab'
        test `age'
        local F2a= string(r(F), "%5.3f")
        local F2 = round(r(p)*1000)/1000
        if   `F2' == 0 local F2 0.000
        local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        eststo:  reg quarter`Q' `age'              if e(sample) , `se'
        test `age'
        local F3a= string(r(F), "%5.3f")
        local F3 = round(r(p)*1000)/1000
        if   `F3' == 0 local F3 0.000
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        keep if year>=2009&ART!=.&WIC!=.&underweight!=.
        eststo: areg quarter`Q' `age' `edu' `con' _year* `spcnd', `se' `yab'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local F4 = round(r(p)*1000)/1000
        if   `F4' == 0 local F4 0.000
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

        eststo: areg quarter`Q' `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
        test `age'
        local F5a= string(r(F), "%5.3f")
        local F5 = round(r(p)*1000)/1000
        if   `F5' == 0 local F5 0.000
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
        postfoot("F-test of Age Variables&`F3a'&`F2a'&`F1a'&`F4a'&`F5a' \\   "
                 "p-value of F-test      &`F3'&`F2'&`F1'&`F4'&`F5' \\        "
                 "Leamer Critical Value  &`L1'&`L1'&`L1'&`L4'&`L4' \\        "
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

exit

local age motherAge motherAge2
local edu highEd
local co1 smoker `mc' i.gestation
local con smoker `mc' value i.gestation
local c2  WIC underweight overweight obese noART
local yab abs(fips)

preserve
keep `cnd'&`keepif'

eststo: areg goodQuarter `age' `edu' `con' _year* i.fips#c.year, `se' `yab'
test `age'
local F1a= string(r(F), "%5.3f")
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F2a= string(r(F), "%5.3f")
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `co1' _year* i.fips#c.year, `se' `yab'
test `age'
local F3a= string(r(F), "%5.3f")
local F3 = round(r(p)*1000)/1000
if   `F3' == 0 local F3 0.000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

keep if year>=2009&ART!=.&WIC!=.&underweight!=.
eststo: areg goodQuarter `age' `edu' `con' _year*              , `se' `yab'
test `age'
local F4a= string(r(F), "%5.3f")
local F4 = round(r(p)*1000)/1000
if   `F4' == 0 local F4 0.000
local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
           
eststo: areg goodQuarter `age' `edu' `con' _year* `c2'        , `se' `yab'
test `age'
local F5a= string(r(F), "%5.3f")
local F5 = round(r(p)*1000)/1000
if   `F5' == 0 local F5 0.000
local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age' `edu' `con' `c2' i.fips#c.year  , `se' `yab'
test `age'
local F6a= string(r(F), "%5.3f")
local F6 = round(r(p)*1000)/1000
if   `F6' == 0 local F6 0.000
local opt6 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

local tnote "controlling for state-specific trends and unemployment rate"
#delimit ;
esttab est3 est2 est1 est4 est5 est6 using
"$OUT/NVSSBinaryMain_robust.tex", replace `estopt'
title("Season of Birth Correlates (`tnote')" \label{tab:robustness})
booktabs keep(`age' `edu' `c2' smoker value `mc')
style(tex) mlabels(, depvar)
postfoot("F-test of Age Variables&`F3a'&`F2a'&`F1a'&`F4a'&`F5a'&`F6a' \\  "
         "p-value of F-test      &`F3'&`F2'&`F1'&`F4'&`F5'&`F6' \\        "
         "Leamer Critical Value  &`L1'&`L1'&`L1'&`L4'&`L4'&`L4' \\        "
         "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5'&`opt6' \\       "
         "State and Year FE&Y&Y&Y&Y&Y&Y\\ Gestation FE &Y&Y&Y&Y&Y&Y\\     "
         "State Specific Linear Trends&Y& &Y& & & Y \\                    "
         "2009-2013 Only&&&&Y&Y&Y\\ \bottomrule                           "
         "\multicolumn{7}{p{22cm}}{\begin{footnotesize} See table 3 in the"
         " main text. The Leamer critical value for a t-statistic is `tL1'"
         " in columns 1-4 and `tL4' in columns 5 and 6.                   "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
restore
*/
********************************************************************************
*** (4) ART and Teens
********************************************************************************
local lab "\label{tab:ART2024}"
local con smoker WIC underweight overweight obese `mc'
local ageA age2024 age2527 age2831 age3239

preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `keepif'

eststo: areg goodQuarter `ageA' noART highEd `con'  _year*, abs(fips)
keep if e(sample) == 1                                     
eststo: areg goodQuarter `ageA' noART highEd smoker _year*, abs(fips)
eststo: areg goodQuarter `ageA' noART               _year*, abs(fips)
eststo:  reg goodQuarter `ageA' noART                                
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/ART2024.tex", replace
`estopt' keep(`ageA' noART highEd `con') style(tex) booktabs
title("Season of Birth Correlates: Very Young (20-24) and ART users`lab'")
postfoot("State and Year FE&&Y&Y&Y\\  \bottomrule                          "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Main sample is   "
         "augmented include women aged 20-24. The Leamer critical value for"
         "the t-statistic is `tL1'. Heteroscedasticity robust standard     "
         "errors are reported.                                             "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore
exit

********************************************************************************
*** (5) Regressions (Quality on Age, season)
********************************************************************************
#delimit ;
local c1      twin==1&birthOrd==1&liveBir==1
              twin==1&birthOrd==1&liveBir==1&maternalPolicy==1
              twin==1&birthOrd==1&liveBir==1&maternalPolicy==0
              twin==1&birthOrd==1&liveBir==1&ParentalPolicy=="AB"
              twin==1&birthOrd==1&liveBir==1&ParentalPolicy=="CDE"
              twin==1&birthOrd==1&liveBir==1&ParentalPolicy=="F";
local c1      twin==1&birthOrd==1&liveBir==1;
local varsY   motherAge motherAge2;
local control highEd smoker WIC underweight overweight obese ART `mc';
local names   Main MLeave NoMLeave PLeaveAB PLeaveCE PLeaveF;
local names   Main;
#delimit cr
tokenize `names'


foreach cond of local c1 {
    if `"`1'"'=="Main"    local title     
    dis "`1', `title'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    local jj=1
    foreach y of varlist `qual' {
        eststo: areg `y' goodQuarter `varsY' `control' `yFE', `se' abs(fips)
        test `varsY'
        local F`jj'a  = round(r(p)*1000)/1000
        if   `F`jj'a' == 0 local F`jj'a 0.000
        local F`jj'b  = string(r(F), "%5.3f")
        dis "`F`jj'b'"
        local L`jj'   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL`jj'  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
        
        local smp if e(sample)==1        
        eststo: areg `y' goodQuarter         `yFE' `smp', `se' abs(fips)

        local ++jj
    }

    local lab "with controls"
    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/NVSSQuality`1'.tex",
    title("Birth Quality and Season of Birth (`title'`lab')"\label{tab:quality`1'})
    keep(goodQuarter `varsY' `control') style(tex) mlabels(, depvar) `estopt'
    postfoot("F-test of Age Variables&`F1b'&`F2b'&`F3b'&`F4b'&`F5b'&`F6b' \\ "
             "p-value of F-test      &`F1a'&`F2a'&`F3a'&`F4a'&`F5a'&`F6a' \\ "
             "Leamer Critical Value  &`L1'&`L2'&`L3'&`L4'&`L5'&`L6'       \\ "
             "\bottomrule                                                    "
             "\multicolumn{7}{p{18.8cm}}{\begin{footnotesize}Main estimation "
             "sample is used. State and year fixed effects are               "
             "included, and `Fnote' Leamer critical values refer to          "
             "Leamer/Schwartz/Deaton critical 5\% values adjusted for sample "
             "size. The maximum Leamer critical value for the t-statistic is "
             "`tL5'. `enote'                                                 "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs replace;

    local lab "without controls";
    esttab est2 est4 est6 est8 est10 est12 using "$OUT/NVSSQuality`1'_NC.tex",
    replace `estopt' title("Birth Quality and Season of Birth (`title'`lab')")
    keep(_cons goodQuarter) style(tex) mlabels(, depvar) 
    postfoot("\bottomrule                                                    "
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Main estimation   "
             "sample is used. State and year fixed effects are               "
             "included. `enote'                                              "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear

    restore
    macro shift
}

keep if `keepif'

********************************************************************************
*** (6) Regression including fetal deaths
********************************************************************************
keep if twin==1 & motherAge>24 & motherAge <= 45

local age motherAge motherAge2
local edu highEd
local con smoker `mc'
local yab abs(fips)
local ges i.gestation
local spcnd

eststo: areg goodQuarter `age' `con' _year* i.gestation , `se' `yab'
test `age'
local F1a= string(r(F), "%5.3f")
local F1 = round(r(p)*1000)/1000
if   `F1' == 0 local F1 0.000
local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

eststo: areg goodQuarter `age' `con' _year*             , `se' `yab'
test `age'
local F2a= string(r(F), "%5.3f")
local F2 = round(r(p)*1000)/1000
if   `F2' == 0 local F2 0.000
local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo: areg goodQuarter `age'       _year* if e(sample), `se' `yab'
test `age'
local F3a= string(r(F), "%5.3f")
local F3 = round(r(p)*1000)/1000
if   `F3' == 0 local F3 0.000
local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

eststo:  reg goodQuarter `age'              if e(sample), `se'
test `age'
local F4a= string(r(F), "%5.3f")
local F4 = round(r(p)*1000)/1000
if   `F4' == 0 local F4 0.000
local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/NVSSBinaryFDeaths.tex", replace
title("Season of Birth Correlates (Including Fetal Deaths)"\label{tab:FDeaths}) 
`estopt' keep(`age' `con') style(tex) mlabels(, depvar)
postfoot("F-test of Age Variables&`F4a'&`F3a'&`F2a'&`F1a' \\                 "
         "p-value of F-test      &`F4' &`F3' &`F2' &`F1'  \\                 "
         "Leamer Critical Value  &`L1'&`L1'&`L1'&`L1'     \\                 "
         "Optimal Age &`opt4'&`opt3'&`opt2'&`opt1' \\                        "
         "State and Year FE&&Y&Y&Y\\  Gestation FE &&&&Y \\ \bottomrule      "
         "\multicolumn{5}{p{15.2cm}}{\begin{footnotesize}  Main sample is    "
         "augmented to include fetal deaths occurring between 25 and 44      " 
         "weeks of gestation. Fetal death files include only a subset of the "
         "full set of variables included in the birth files, so education and"
         " ART controls are not included. `Fnote' Leamer critical values     "
         "refer to Leamer/Schwartz/Deaton critical 5\% values adjusted for   "
         "sample size. The Leamer critical value for the t-statistic is      "
         "`tL1'. `onote' `enote'                                             "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "\end{footnotesize}}\end{tabular}\end{table}") booktabs ;
#delimit cr
estimates clear
exit

********************************************************************************
*** (7) Appendix examining missing covariates
********************************************************************************
keep `cnd'&`keepif'
gen smokeMissing = smoker    == .
gen educMissing  = educLevel == .
gen fatherAgeMis = fatherAge == 11
foreach year of numlist 2005(1)2013 {
    foreach var in smoke educ {
        gen `var'Missing`year' = 1 if `var'Missing & year==`year'
        replace `var'Missing`year' = 0 if `var'Missing`year'==.
    }
    lab var educMissing`year'  "Missing Education$\times$ `year'"
    lab var smokeMissing`year' "Missing Smoking$\times$ `year'"
}
lab var smokeMissing "Missing Smoking"
lab var educMissing  "Missing Education"
lab var fatherAgeMis "Father's Age Not Known"

local base young
local y goodQuarter
eststo: reg `y' `base' educMissing   smokeMissing              `yFE', `se'
eststo: reg `y' `base' educMissing   smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing   fatherAgeM `yFE', `se'
eststo: reg `y' `base' educMissing2* smokeMissing2* fatherAgeM `yFE', `se'
#delimit ;
esttab est1 est2 est3 est4 using "$OUT/NVSSMissing.tex",
replace `estopt' title("Missing Records (NVSS 2005-2013)") booktabs 
keep(_cons `base' educM* smokeM* fatherA*) style(tex) mlabels(, depvar)
postfoot("\bottomrule"
         "\multicolumn{5}{p{15cm}}{\begin{footnotesize}All regressions "
         "include year fixed effects.  Missing values for smoking and "
         "education are for those states who have not yet adopted the 2003 "
         "updated birth certificates.  Father's age is missing where it "
         "is not reported by the mother. "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

gen propMissing = .
gen propOldEduc = .
gen yearMissing = .

local ii = 1
foreach y of numlist 2005(1)2013 {
    qui count if educLevel == . & year==`y'
    local mis = `=r(N)'
    qui count if year==`y'
    local all = `=r(N)'
    local prop = `mis'/`all'

    replace propMissing = `prop' in `ii'
    replace yearMissing = `y'    in `ii'

    sum oldEduc if year==`y'
    if `y'<2009  replace propOldEduc = r(mean) in `ii'
    if `y'>=2009 replace propOldEduc = 0       in `ii'
    local ++ii
}

#delimit;
twoway bar propMissing yearMissing in 1/9, color(white) lcolor(gs0)
|| connect propOldEduc yearMissing in 1/9,
scheme(s1mono) xtitle("Data Year") ytitle("Proportion Missing Education") 
note("Missing education measures occurr in states which use pre-2003 format.")
legend(label(1 "Missing (2003 coding)") label(2 "Old Variable Available"));
graph export "$OUT/../graphs/missingEduc.eps", as(eps) replace;
#delimit cr


********************************************************************************
*** (X) Clear
********************************************************************************
log close




#delimit ;
local Fnote  "F-test of age variables refers to the p-value on the test that
              the coefficients on mother's age and age squared are jointly
              equal to zero.";
#delimit cr

********************************************************************************
*** (E3a) Good Quarter Regressions
********************************************************************************
#delimit ;
local add `" "" "';
local nam Main 
#delimit cr
tokenize `nam'

foreach type of local add {
    preserve

    local age motherAge motherAge2
    local edu educYrs educYrsSq
    local con smoker i.gestation `mc' 
    local c2  WIC underweight overweight obese noART
    local yab abs(fips)
    local spcnd
    local group `cnd'&`keepif'
    local samp1 "singleton"
    local samp2 "first born"
    
    if `"`1'"' == "NoSep" local spcnd if birthMonth!=9
    if `"`1'"' == "Bord2" local group `cnd'&birthOrder==2&liveBirth==1
    if `"`1'"' == "Twin"  local group /*
           */ if twin==2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "TwinS" local group /*
           */ if twin<=2&motherAge>24&motherAge<46&`keepif'&liveBirth==1
    if `"`1'"' == "Bord2" local samp2 "second born"
    if `"`1'"' == "Twin"  local samp1 "twin" 
    if `"`1'"' == "TwinS" local samp1 "twin and singleton" 

    keep `group'

    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F1 = round(r(p)*1000)/1000
    if   `F1' == 0 local F1 0.000
    local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
    
    eststo: areg goodQuarter `age'       _year* if e(sample) , `se' `yab'
    test `age'    
    local F2 = round(r(p)*1000)/1000
    if   `F2' == 0 local F2 0.000
    local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo:  reg goodQuarter `age'              if e(sample) , `se'
    test `age'
    local F3 = round(r(p)*1000)/1000
    if   `F3' == 0 local F3 0.000
    local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    keep if year>=2009&ART!=.&WIC!=.&underweight!=.
    eststo: areg goodQuarter `age' `edu' `con' _year* `spcnd', `se' `yab'
    test `age'
    local F4 = round(r(p)*1000)/1000
    if   `F4' == 0 local F4 0.000
    local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    eststo: areg goodQuarter `age' `edu' `con' `c2' _year* `spcnd', `se' `yab'
    test `age'
    local F5 = round(r(p)*1000)/1000
    if   `F5' == 0 local F5 0.000
    local opt5 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

    #delimit ;
    esttab est3 est2 est1 est4 est5 using "$OUT/EducSq_NVSSBinary`1'.tex",
    replace `estopt' keep(`age' `edu' smoker `c2' `mc') 
    title("Season of Birth Correlates `type'"\label{tab:bq`1'}) booktabs 
    style(tex) mlabels(, depvar)
    postfoot("F-test of Age Variables&`F3'&`F2'&`F1'&`F4'&`F5' \\            "
             "Optimal Age &`opt3'&`opt2'&`opt1'&`opt4'&`opt5' \\             "
             "State and Year FE&&Y&Y&Y&Y\\ Gestation FE &&&Y&Y&Y\\           "
             "2009-2013 Only&&&&Y&Y\\ \bottomrule                            "
             "\multicolumn{6}{p{19cm}}{\begin{footnotesize} All `samp1',     "
             "`samp2' children from the main sample are included.  Years of  "
             "education are inferred from 6 categorical measures. `Fnote'    "
             "`onote' `enote'     "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear

    macro shift
    restore
}


********************************************************************************
*** (E4) ART and Teens
********************************************************************************
local lab "\label{tab:ART2024}"
local con smoker WIC underweight overweight obese `mc'

preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `keepif'
               
eststo: areg goodQuarter age2024 noART educYrs* `con'  _year*, abs(fips)
keep if e(sample) == 1                                     
eststo: areg goodQuarter age2024 noART educYrs* smoker _year*, abs(fips)
eststo: areg goodQuarter age2024 noART                 _year*, abs(fips)
eststo:  reg goodQuarter age2024 noART                                

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/EducSq_ART2024.tex", replace
`estopt' keep(age2024 noART educYrs educYrsSq `con') style(tex) booktabs
title("Season of Birth Correlates: Very Young (20-24) and ART users`lab'")
postfoot("State and Year FE&&Y&Y&Y\\  \bottomrule                        "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Main estimation  "
         "sample is augmented to also include women aged 20-24.            "
         "Heteroscedasticity robust standard errors are reported.          "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore

********************************************************************************
*** (E5) Regressions (Quality on Age, season)
********************************************************************************
local c1      twin==1&birthOrd==1&liveBir==1
local varsY   motherAge motherAge2
local control educYrs educYrsSq smoker WIC underweight overweight obese ART `mc'
local names   Main

tokenize `names'

foreach cond of local c1 {
    if `"`1'"'=="Main"    local title     
    dis "`1', `title'"
    preserve
    keep if motherAge>24 & motherAge<=45 & `cond'
    
    local jj=1
    foreach y of varlist `qual' {
        eststo: areg `y' goodQuarter `varsY' `control' `yFE', `se' abs(fips)
        test `varsY'
        local F`jj'a = round(r(p)*1000)/1000
        if   `F`jj'a' == 0 local F`jj'a 0.000

        local smp if e(sample)==1        
        eststo: areg `y' goodQuarter         `yFE' `smp', `se' abs(fips)

        local ++jj
    }

    local lab "with controls"
    #delimit ;
    esttab est1 est3 est5 est7 est9 est11 using "$OUT/EducSq_NVSSQuality`1'.tex",
    title("Birth Quality and Season of Birth (`title'`lab')"\label{tab:quality`1'})
    keep(goodQuarter `varsY' `control') style(tex) mlabels(, depvar) `estopt'
    postfoot("F-test of Age Variables&`F1a'&`F2a'&`F3a'&`F4a'&`F5a'&`F6a' \\ "
             "\bottomrule                                                    "
             "\multicolumn{7}{p{18.8cm}}{\begin{footnotesize}Main estimation "
	     "sample is used. State and year fixed effects are               "
             "included, and `Fnote'         `enote'                          "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs replace;

    local lab "without controls";
    esttab est2 est4 est6 est8 est10 est12 using "$OUT/EducSq_NVSSQuality`1'_NC.tex",
    replace `estopt' title("Birth Quality and Season of Birth (`title'`lab')")
    keep(_cons goodQuarter) style(tex) mlabels(, depvar) 
    postfoot("\bottomrule                                                    "
             "\multicolumn{7}{p{15cm}}{\begin{footnotesize}Main estimation   "
	     "sample is used. State and year fixed effects are               "
             "included. `enote'                                              "
             "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.          "
             "\end{footnotesize}}\end{tabular}\end{table}") booktabs;
    #delimit cr
    estimates clear
    
    macro shift
    restore
}
*/


********************************************************************************
*** (E4) ART and Teens
********************************************************************************
local nam MLeave NoMLeave PLeaveAB PLeaveCE PLeaveF
tokenize `nam'

foreach num of numlist 1(1)5 {
    if `"`1'"' == "MLeave" local group   `keepif'&maternalPolicy==1
    if `"`1'"' == "NoMLeave" local group `keepif'&maternalPolicy==0
    if `"`1'"' == "PLeaveAB" local group `keepif'&ParentalPolicy=="AB"
    if `"`1'"' == "PLeaveCE" local group `keepif'&ParentalPolicy=="CDE"
    if `"`1'"' == "PLeaveF"  local group `keepif'&ParentalPolicy=="F"
    
    
local lab "\label{tab:ART2024}"
local con smoker WIC underweight overweight obese `mc'

preserve
keep if twin==1 & motherAge>=20 & motherAge<=45 & liveBirth==1 & `group'
               
eststo: areg goodQuarter age2024 noART educYrs* `con'  _year*, abs(fips)
keep if e(sample) == 1                                     
eststo: areg goodQuarter age2024 noART educYrs* smoker _year*, abs(fips)
eststo: areg goodQuarter age2024 noART                 _year*, abs(fips)
eststo:  reg goodQuarter age2024 noART                                

#delimit ;
esttab est4 est3 est2 est1 using "$OUT/ART2024_`1'.tex", replace
`estopt' keep(age2024 noART educYrs educYrsSq `con') style(tex) booktabs
title("Season of Birth Correlates: Very Young (20-24) and ART users`lab'")
postfoot("State and Year FE&&Y&Y&Y\\  \bottomrule                        "
         "\multicolumn{5}{p{16.4cm}}{\begin{footnotesize} Main estimation  "
         "sample is augmented to also include women aged 20-24.            "
         "Heteroscedasticity robust standard errors are reported.          "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.            "
         " \end{footnotesize}}\end{tabular}\end{table}") mlabels(, depvar);
#delimit cr
estimates clear
restore

macro shift
}
