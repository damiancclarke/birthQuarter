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
global SUM "~/investigacion/2015/birthQuarter/results/births/sumstats"
global GRA "~/investigacion/2015/birthQuarter/results/births/graphs"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssRegs.txt", text replace
cap mkdir "$OUT"

#delimit ;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats        
             (N, fmt(%9.0g) labels(Observations))
             collabels(none) label;
local Fnote  "F-test of age variables refers to the test that
              the coefficients on mother's age and age squared are jointly
              equal to zero. The critical value for rejection of joint
              insignificance is displayed below the F-statistic.";
local onote  "Optimal age calculates the turning point of the mother's age
              quadratic.";
local enote  "Heteroscedasticity robust standard errors are reported in
              parentheses.";
lab def mon 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
            9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec";
#delimit cr


********************************************************************************
*** (2) Open data for descriptives
********************************************************************************
use          "$DAT/nvss2005_2013_all"
keep if twin==1
replace twin=twin-1
keep if birthOrder==1
gen birth = 1
/*
********************************************************************************
*** (3a) Descriptive age graph
********************************************************************************
#delimit ;
twoway hist motherAge if motherAge>=20&motherAge<=45, freq color(gs0)  width(1)
    || hist motherAge if motherAge<20|motherAge>=45,  freq color(gs12) width(1)
    ylabel(, angle(0) format(%15.0fc)) xtitle("Mother's Age")
    legend(label(1 "Estimation Sample") label(2 "<20 or >45")) scheme(s1mono);
graph export "$GRA/ageDescriptive.eps", as(eps) replace;

local fw freq width(1);
twoway hist motherAge if motherAge>=20&motherAge<=45&married==1, `fw' color(gs0)  
  || hist motherAge if (motherAge<20|motherAge>=45)&married==1, `fw' color(gs12) 
    ylabel(, angle(0) format(%15.0fc)) xtitle("Mother's Age")
    legend(label(1 "Estimation Sample") label(2 "<20 or >45")) scheme(s1mono);
graph export "$GRA/ageDescriptive-married.eps", as(eps) replace;
a#delimit cr

preserve
drop if ART==.|conceptionMonth==.
collapse (sum) birth, by(conceptionMonth ART)
reshape wide birth, i(conceptionMonth) j(ART)

lab val conceptionMon mon
gen proportionART = birth1/(birth0+birth1)
sort conceptionMonth
#delimit ;
twoway line proportionART conceptionMonth, xlabel(1(1)12, valuelabels) 
  scheme(s1mono) ytitle("Proportion of Conceptions Using ART")        
  xtitle("Month of Conception");
graph export "$GRA/proportionMonthART.eps", as(eps) replace;
#delimit cr
restore


preserve
gen teenBirth = motherAge>=15&motherAge<=19
keep if motherAge>=15&motherAge<=45
collapse (sum) birth, by(teenBirth birthMonth)
bys teenBirth: egen totbirth = sum(birth)
gen propBirth = birth/totbirth
sort teenBirth birthMonth
lab val birthMonth mon
#delimit ;
twoway line propBirth birthMonth if teenBirth==1, lcolor(ebblue) lwidth(thick)
 || line propBirth birthMonth if teenBirth==0, lcolor(cranberry) lwidth(thick)
lpattern(dash) xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul"
                      8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec")
ytitle("Proportion of Births") xtitle("Month of Birth") scheme(s1mono)
legend(lab(1 "Ages 15-19") lab(2 "Ages 20-45"));
graph export "$GRA/birthMonths-age.eps", as(eps) replace;
#delimit cr
restore

*/

********************************************************************************
*** (3b) Summary stats 
********************************************************************************
#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 White unmarried" "20-45 Black unmarried" "';
local nam All whiteMarried whiteUnmarried blackUnmarried;
#delimit cr
tokenize `nam'

generat goodBirthQ = birthQuarter == 2 | birthQuarter == 3 
gen tvar = abs(goodQuarter-1)
lab var goodBirthQ  "Good season of birth (birth date)"
gen Quarter2 = birthQuarter == 2 if gestation!=.
gen Quarter3 = birthQuarter == 3 if gestation!=.
lab var Quarter2    "Quarter 2 Birth (Expected)"
lab var Quarter3    "Quarter 3 Birth (Expected)"

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0
    local mc hispanic
    if `k'==1 local mc black white hispanic married
    
    local Mum  motherAge `mc' young age2024 age2527 age2831 age3239 age4045
    local MumP college educCat smoker ART WIC BMI underwe normalBM overwe obese
    local Kid  Quarter2 Quarter3 fem birthweight lbw gestat premature apgar
    
    foreach st in Mum Kid MumP {
        preserve
        keep if smoker!=.&college!=.&twin==0&`gg'
        sum ``st''

        #delimit ;
        estpost tabstat ``st'', statistics(count mean sd min max)
        columns(statistics);
        esttab using "$SUM/samp`st'_``k''.tex", replace label noobs
        title("Descriptive Statistics (`type')") 
        cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))");
        #delimit cr
        restore
        
    }
    local ++k
}

exit
********************************************************************************
*** (3c) Numerical tabulations by age and education
********************************************************************************
tokenize `nam'
lab def educ 0 "No College" 1 "Some College +"
lab val highEd educ

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0
    local mc hispanic
    if `k'==1 local mc black white hispanic married
    
    preserve
    keep if `gg'
    drop if highEd==.|goodQuarter==.
    collapse premature ART (sum) birth, by(goodQuarter highEd)
    bys highEd: egen aveprem = mean(premature)
    bys highEd: egen aveART = mean(ART)
    drop premature ART
    reshape wide birth, i(highEd) j(goodQuarter)
    gen totalbirths = birth0 + birth1
    replace birth0=round(10000*birth0/totalbirths)/100
    replace birth1=round(10000*birth1/totalbirths)/100
    
    gen diff            = birth1 - birth0
    gen rati            = birth1 / birth0
    gen str5 b0         = string(birth0, "%05.2f")
    gen str5 b1         = string(birth1, "%05.2f")
    gen str4 difference = string(diff, "%04.2f")
    gen str4 ratio      = string(rati, "%04.2f")
    gen str4 prem       = string(aveprem, "%04.2f")
    gen str4 ART        = string(aveART, "%04.2f")
    drop totalbirths diff rati birth* ave*
    
    decode highEd, gen(el)
    order el
    drop highEd
    outsheet using "$SUM/JustEduc_``k''.txt", delimiter("&") replace noquote
    restore
    
    preserve
    keep if `gg'
    drop if highEd==.|goodQuarter==.|motherAge<20|motherAge>45
    gen ageG2 = motherAge>=20 & motherAge<25
    replace ageG2 = 2 if motherAge>=25 & motherAge<28
    replace ageG2 = 3 if motherAge>=28 & motherAge<32
    replace ageG2 = 4 if motherAge>=32 & motherAge<40
    replace ageG2 = 5 if motherAge>=40 & motherAge<46
    
    collapse premature ART (sum) birth, by(goodQuarter ageG2)
    #delimit ;
    lab def ag_2 1 "20-24 Years Old" 2 "25-27 Years Old" 3 "28-31 Years Old"
    4 "32-39 Years Old" 5 "40-45 Years Old";
    #delimit cr
    lab val ageG2 ag_2
    
    bys ageG2: egen aveprem = mean(premature)
    bys ageG2: egen aveART = mean(ART)
    drop premature ART
    reshape wide birth, i(ageG2) j(goodQuarter)
    gen totalbirths = birth0 + birth1
    replace birth0=round(10000*birth0/totalbirths)/100
    replace birth1=round(10000*birth1/totalbirths)/100
    gen diff            = birth1 - birth0
    gen rati            = birth1 / birth0
    gen str4 difference = string(diff, "%04.2f")
    gen str4 ratio      = string(rati, "%04.2f")
    gen str4 prem       = string(aveprem, "%04.2f")
    gen str4 ART        = string(aveART, "%04.2f")
    drop totalbirths diff rati ave*
    
    outsheet using "$SUM/FullSample_``k''.txt", delimiter("&") replace noquote
    restore
    local ++k
}

*/
********************************************************************************
*** (3d) Age plots by month (ART, no ART)
********************************************************************************
tokenize `nam'
count
local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0

    preserve
    keep if `gg'

    generat youngOld = 1 if motherAge>=28&motherAge<=31
    replace youngOld = 2 if motherAge>=40&motherAge<=45

    drop if youngOld==.|conceptionMonth==.
    count
    local NN = string(r(N),"%15.0fc")

    collapse (sum) birth, by(conceptionMonth youngOld)
    lab val conceptionMon mon
    bys youngOld: egen totalBirths = sum(birth)
    gen birthProportion = birth/totalBirths
    sort conceptionMonth youngOld

    local line1 lpattern(solid)    lcolor(black) lwidth(thick)
    local line2 lpattern(dash)     lcolor(black) lwidth(medium)

    #delimit ;
    twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
           line birthProportion conceptionMonth if youngOld==2, `line2'
    xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
    xlabel(1(1)12, valuelabels axis(2))
    xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
           10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
    legend(label(1 "28-31 Year-olds") label(2 "40-45 Year-olds"))
    ytitle("Proportion of All Births")
    note("Number of observations = `NN'");
    graph export "$GRA/conceptionMonth_``k''.eps", as(eps) replace;
    #delimit cr
    restore

    preserve
    keep if `gg'
    generat youngOld = 1 if motherAge>=28&motherAge<=39
    replace youngOld = 2 if motherAge>=40&motherAge<=45

    drop if youngOld==.|conceptionMonth==.
    keep if ART==1
    count
    local NN = string(r(N),"%15.0fc")
    collapse (sum) birth, by(conceptionMonth youngOld)
    lab val conceptionMon mon

    bys youngOld: egen totalBirths = sum(birth)
    gen birthProportion = birth/totalBirths
    sort conceptionMonth youngOld

    local line1 lpattern(solid)    lcolor(black) lwidth(thick)
    local line2 lpattern(dash)     lcolor(black) lwidth(medium)

    #delimit ;
    twoway line birthProportion conceptionMonth if youngOld==1, `line1' ||
           line birthProportion conceptionMonth if youngOld==2, `line2'
    xaxis(1 2) scheme(s1mono) xtitle("Month of Conception", axis(2))
    xlabel(1(1)12, valuelabels axis(2))
    xlabel(1 "Oct" 2 "Nov" 3 "Dec" 4 "Jan" 5 "Feb" 6 "Mar" 7 "Apr" 8 "May" 9 "Jun"
           10 "Jul" 11 "Aug" 12 "Sep", axis(1)) xtitle("Expected Month")
    legend(label(1 "28-39 Year-olds") label(2 "40-45 Year-olds"))
    ytitle("Proportion of All Births") note("Number of observations = `NN'");
    graph export "$GRA/conceptionMonthART_``k''.eps", as(eps) replace;
    #delimit cr
    restore
    
    local ++k
}
exit

********************************************************************************
*** (3e) Age plots by quarter
********************************************************************************
tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0
    local mc hispanic
    if `k'==1 local mc black white hispanic married
    
    preserve
    keep if `gg'
    tab motherAge, gen(_age)

    foreach Q in 2 3 {
        cap gen quarter`Q' = birthQuarter==`Q'
        lab var quarter`Q' "Quarter `Q'"
        reg quarter`Q' _age1-_age26 if motherAge>=20&motherAge<=45, nocons
        
        gen ageES`Q' = .
        gen ageLB`Q' = .
        gen ageUB`Q' = .
        gen ageNM`Q' = .
        foreach num of numlist 1(1)26 {
            replace ageES`Q' = _b[_age`num']                     in `num'
            replace ageLB`Q' = _b[_age`num']-1.96*_se[_age`num'] in `num'
            replace ageUB`Q' = _b[_age`num']+1.96*_se[_age`num'] in `num'
            replace ageNM`Q' = `num'+19                          in `num'
        }

        local s1 lpattern(solid) lcolor(black) lwidth(medthick)
        local s2 lpattern(dash)  lcolor(black) lwidth(medium)
        local s3 lpattern(dash)  lcolor(black) lwidth(medium) 
        
        #delimit ;
        twoway line ageES`Q' ageNM`Q' in 1/26, `s1'
        || line ageLB`Q' ageNM`Q' in 1/26,     `s2'
        || line ageUB`Q' ageNM`Q' in 1/26,     `s3'
        || scatter ageES`Q' ageNM`Q' in 1/26, mcolor(black) m(S) xlabel(20(1)45)
        scheme(s1mono) legend(order(1 "Point Estimate" 2 "95 % CI"))
        xtitle("Mother's Age") ytitle("Proportion Quarter `Q'" " ");
        graph export "$GRA/quarter`Q'Age_2045_``k''.eps", as(eps) replace;
        #delimit cr
    }
    
    local s1 lpattern(solid) lwidth(medthick)
    local s2 lpattern(dash)  lwidth(medium)    
    #delimit ;
    twoway connected ageES2 ageNM2 in 1/26, `s1' lcolor(red) mcolor(red) m(S)
    || line ageLB2 ageNM2 in 1/26,     `s2' lcolor(red)
    || line ageUB2 ageNM2 in 1/26,     `s2' lcolor(red)
    || connected ageES3 ageNM3 in 1/26,`s1' lcolor(blue) mcolor(blue) m(Oh)
    || line ageLB3 ageNM3 in 1/26,     `s2' lcolor(blue) xlabel(20(1)45) 
    || line ageUB3 ageNM3 in 1/26,     `s2' lcolor(blue) scheme(s1mono) 
    legend(order(1 "Point Estimate (Quarter 2)" 2 "95 % CI (Quarter 2)"
                 4 "Point Estimate (Quarter 3)" 6 "95 % CI (Quarter 3)"))
    xtitle("Mother's Age") ytitle("Proportion in Quarter" " ");
    graph export "$GRA/quarter2-3Age_2045_``k''.eps", as(eps) replace;
    #delimit cr
    local ++k
    restore
}


********************************************************************************
*** (4) Open data for regressions
********************************************************************************
use          "$DAT/nvss2005_2013_all", clear
append using "$DAT/nvssFD2005_2013_all"
replace motherAge2 = motherAge2/100 if liveBirth==0
keep if twin<3

********************************************************************************
*** (5a) Run for quarter 2 and 3
********************************************************************************
#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 White unmarried"  "20-45 Black unmarried" "';
local nam All whiteMarried whiteUnmarried blackUnmarried;
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
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0
    local nc hispanic
    if `k'==1 local nc black white hispanic married

    local con smoker i.gestation `nc'
    preserve
    keep if twin==1&liveBirth==1&birthOrder==1&`gg'
    count
    
    foreach Q in 2 3 {
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

        local ysm if year>=2009&ART!=.&WIC!=.&underweight!=.
        eststo: areg quarter`Q' `age' `edu' `con' _year* `ysm', `se' `yab'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

        eststo: areg quarter`Q' `age' `edu' `con' `c2' _year* `ysm', `se' `yab'
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
        title("Season of Birth Correlates: Quarter `Q' (`type')") booktabs 
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
    }
    restore
    local ++k
}


********************************************************************************
*** (5b) Alternative Regressions
********************************************************************************
#delimit ;
local add `" "excluding babies conceived in November or December"
             "second births" "';
local nam NoNovDec Birth2;
#delimit cr
tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg liveBirth==1&birthOrder==1&birthMonth!=9&birthMonth!=8
    if `k'==2 local gg liveBirth==1&birthOrder==2

    local con smoker i.gestation hispanic
    preserve
    keep if twin==1&motherAge>=20&motherAge<=45&white==1&married==1&`gg'
    count
    
    foreach Q in 2 3 {    
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

        local ysm if year>=2009&ART!=.&WIC!=.&underweight!=.
        eststo: areg quarter`Q' `age' `edu' `con' _year* `ysm', `se' `yab'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L4   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL4  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")

        eststo: areg quarter`Q' `age' `edu' `con' `c2' _year* `ysm', `se' `yab'
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
        title("Season of Birth Correlates: Quarter `Q' (`type')") booktabs 
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
    }
    restore
    local ++k
}
*/
********************************************************************************
*** (5c) Including fetal deaths
********************************************************************************
keep if twin==1 & motherAge>=20 & motherAge <= 45 & birthOrder==1

#delimit ;
local add `" "20-45 All Observations" "20-45 White married"
             "20-45 White unmarried"  "20-45 Black unmarried" "';
local nam All whiteMarried whiteUnmarried blackUnmarried;
#delimit cr
tokenize `nam'

local k=1
foreach type of local add {
    if `k'==1 local gg motherAge>=20&motherAge<=45
    if `k'==2 local gg motherAge>=20&motherAge<=45&white==1&married==1
    if `k'==3 local gg motherAge>=20&motherAge<=45&white==1&married==0
    if `k'==4 local gg motherAge>=20&motherAge<=45&black==1&married==0
    local mc hispanic
    if `k'==1 local mc black white hispanic married

    local con smoker `nc'
    preserve
    keep if `gg'
    count
    
    foreach Q in 2 3 {
        eststo: areg quarter`Q' `age' `con' _year* i.gestation , `se' `yab'
        test `age'
        local F1a= string(r(F), "%5.3f")
        local opt1 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100
        local L1   = string((e(df_r)/2)*(e(N)^(2/e(N))-1), "%5.3f")
        local tL1  = string(sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)), "%5.3f")
        local pvL  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2
        
        eststo: areg quarter`Q' `age' `con' _year*             , `se' `yab'
        test `age'
        local F2a= string(r(F), "%5.3f")
        local opt2 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        eststo: areg quarter`Q' `age'       _year* if e(sample), `se' `yab'
        test `age'
        local F3a= string(r(F), "%5.3f")
        local opt3 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        eststo:  reg quarter`Q' `age'              if e(sample), `se'
        test `age'
        local F4a= string(r(F), "%5.3f")
        local opt4 = round((-_b[motherAge]/(0.02*_b[motherAge2]))*100)/100

        #delimit ;
        esttab est4 est3 est2 est1 using "$OUT/NVSSFDeathsQ`Q'_``k''.tex", replace
        title("Birth Correlates Including Fetal Deaths: Quarter `Q' (`type')")
        `estopt' keep(`age' `con') style(tex) mlabels(, depvar)
        starlevel("$ ^{\ddagger} $" `pvL')
        postfoot("F-test of Age Variables&`F4a'&`F3a'&`F2a'&`F1a' \\         "
         "Leamer Critical Value (F)  &`L1'&`L1'&`L1'&`L1'     \\             "
         "Optimal Age &`opt4'&`opt3'&`opt2'&`opt1' \\                        "
         "State and Year FE&&Y&Y&Y\\  Gestation FE &&&&Y \\ \bottomrule      "
         "\multicolumn{5}{p{12.4cm}}{\begin{footnotesize}  Main sample is    "
         "augmented to include fetal deaths occurring between 25 and 44      "
         "weeks of gestation. Fetal death files include only a subset of the "
         "full set of variables included in the birth files, so education and"
         " ART controls are not included. `Fnote' Leamer critical values     "
         "refer to Leamer/Schwartz/Deaton critical 5\% values adjusted for   "
         "sample size. The Leamer critical value for the t-statistic is      "
         "`tL1'. `onote' `enote' $^{\ddagger}$ Siginificant based on Leamer  "
         "criterion. \end{footnotesize}}\end{tabular}\end{table}") booktabs ;
        #delimit cr
        estimates clear
    }
    restore
    local ++k
}



********************************************************************************
*** (X) Clear
********************************************************************************
log close
