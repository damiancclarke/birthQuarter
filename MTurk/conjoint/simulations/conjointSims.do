/* conjointSims.do v0.00         damiancclarke             yyyy-mm-dd:2016-09-27
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close
/*
*-------------------------------------------------------------------------------
*--- (1) Import
*-------------------------------------------------------------------------------
use simulatedBase.dta
tab gender, gen(_gend)
tab cost  , gen(_cost)
tab premat, gen(_prem)
tab sob   , gen(_sob)
tab dob   , gen(_dob)

drop _gend1 _cost1 _prem1 _sob1 _dob1

reg chosen _gend* _cost* _prem* _sob* _dob* i.round, cluster(ID)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local names GENDER Male Female COST 0 50 100 250 500 1000 2500 5000 10000 /*
*/ PREMATURE Yes No SEASON-OF-BIRTH Jan-Mar Apr-June July-Sep Oct-Dec     /*
*/ DAY-OF-BIRTH Weekday Weekend
tokenize `names'
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5   /*
*/ _cost6 _cost7 _cost8 _cost9 s PREMATURE _prem1 _prem2 s SEASON-OF_BIRTH  /*
*/ _sob1 _sob2 _sob3 _sob4 s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==16|`i'==20|`i'==26 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==15|`i'==19|`i'==25|`i'==29 {
    }
    else if `i'==2|`i'==6|`i'==17|`i'==21|`i'==27 {
        qui replace Est = 0 in `i'
        qui replace UB  = 0 in `i'
        qui replace LB  = 0 in `i'
    }
    else {
        qui replace Est = _b[`var'] in `i'
        qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
        qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
    }
    local ++i
}


replace Y = -Y
lab def names -1 "GENDER" -2 "Male" -3 "Female" -4 " " -5 "COST" -6 "0" -7 "50"     /*
*/ -8 "100" -9 "250" -10 "500" -11 "1000" -12 "2500" -13 "5000" -14 "10000" -15 " " /*
*/ -16 "PREMATURE" -17 "Yes" -18 "No" -19 " " -20 "SEASON OF BIRTH" -21 "Jan-Mar"   /*
*/ -22 "Apr-June" -23 "July-Sep" -24 "Oct-Dec" -25 " " -26 "DAY-OF-BIRTH"           /*
*/ -27 "Weekday" -28 "Weekend" -29 " "
lab val Y names

#delimit ;
twoway rcap  LB UB Y in 1/29, horizontal scheme(s1mono) lcolor(black) ||
       scatter Y Est in 1/29, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1(-1)-29, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export simulatedEsts.eps, replace

*/

*-------------------------------------------------------------------------------
*--- (2) Simulate
*-------------------------------------------------------------------------------
use simulatedBase.dta
keep ID round option chooses cost premature gender sob dob chosen
reshape wide chooses cost premature gender sob dob chosen, i(ID round) j(option)
drop chooses* chosen*
gen summer1 = sob1=="April May June"|sob1=="July August September"
gen winter2 = sob2=="January February March"|sob2=="October November December"

gen summerDif = summer1==1&winter2==1
replace summerDif = -1 if summer1==0&winter2==0

foreach var in sim est2 est3 est4 ub2 ub3 ub4 lb2 lb3 lb4 {
    gen `var'=.
}

local jj = 1
foreach num of numlist 0.005(0.005)0.5 {
    preserve
    gen rchoose = runiform()-0.5+`num'*summerDif
    gen choose1 = rchoose>0
    drop rchoose
    reshape long cost premature gender sob dob, i(ID round) j(option)
    drop winter2 summer1
    
    gen chosen = option == choose1
    replace chosen =1 if option==2&choose1==0
    
    gen sobNum = 1 if sob=="January February March"
    replace sobNum = 2 if sob=="April May June"
    replace sobNum = 3 if sob=="July August September"
    replace sobNum = 4 if sob=="October November December"

    tab gender, gen(_gend)
    tab cost  , gen(_cost)
    tab premat, gen(_prem)
    tab sobNum, gen(_sob)
    tab dob   , gen(_dob)
    
    drop _gend1 _cost1 _prem1 _sob1 _dob1
    
    reg chosen _gend* _cost* _prem* _sob* _dob* i.round, cluster(ID)
    foreach nn of numlist 2 3 4 {
        local est`nn' = _b[_sob`nn']
        local se`nn'  = _se[_sob`nn']
    }    
    restore
    replace sim = `num' in `jj'
    foreach nn of numlist 2 3 4 {
        replace est`nn' = `est`nn'' in `jj'
        replace lb`nn'  = `est`nn''-1.96*`se`nn'' in `jj'
        replace ub`nn'  = `est`nn''+1.96*`se`nn'' in `jj'        
    }    

    local ++jj
}

replace sim = sim *100
gen sim2 = sim-0.25
gen sim4 = sim+0.25

#delimit ;
twoway line est2 sim2, lcolor(blue) lwidth(thick) scheme(lean1) ||
    line est3 sim ,  lcolor(red)    lwidth(thick) lpattern(solid) ||
    line est4 sim4,  lcolor(green)  lwidth(thick) lpatter(solid) ||
    line lb2  sim2, lcolor(blue) lwidth(vthin) lpattern(dash)  ||
    line ub2  sim2, lcolor(blue) lwidth(vthin) lpattern(dash)  ||
    line lb3  sim , lcolor(red) lwidth(vthin) lpattern(dash)   ||
    line ub3  sim , lcolor(red) lwidth(vthin) lpattern(dash)   ||
    line lb4  sim4, lcolor(green) lwidth(vthin) lpattern(dash) ||
        line ub4  sim4, lcolor(green) lwidth(vthin) lpattern(dash)
yline(0, lcolor(red)) ytitle("Estimated Preference for SOB 2 or SOB 3")
xtitle("Simulated % Preference for SOB 2 or SOB 3 versus SOB 1 or SOB 4")
legend(order(1 "SOB 2" 2 "SOB 3" 3 "SOB 4") position(1) row(1) ring(0));
graph export simulationValues2.eps, replace;
#delimit cr

#delimit ;
twoway line est2 sim2, lcolor(blue) lwidth(thick) scheme(lean1) ||
    line est3 sim ,  lcolor(red)    lwidth(thick) lpattern(solid) ||
    line lb2  sim2, lcolor(blue) lwidth(vthin) lpattern(dash)  ||
    line ub2  sim2, lcolor(blue) lwidth(vthin) lpattern(dash)  ||
    line lb3  sim , lcolor(red) lwidth(vthin) lpattern(dash)   ||
    line ub3  sim , lcolor(red) lwidth(vthin) lpattern(dash)   
yline(0, lcolor(red))
legend(order(1 "SOB 2" 2 "SOB 3") position(1) row(1) ring(0));
graph export simulationValues3.eps, replace;
#delimit cr

foreach var in sim est2 est3 est4 ub2 ub3 ub4 lb2 lb3 lb4 {
    drop `var'
    gen `var'=.
}

drop sim2 sim4
local jj = 1
foreach num of numlist 0(0.01)0.08 {
    preserve
    gen rchoose = runiform()-0.5+`num'*summerDif
    gen choose1 = rchoose>0
    drop rchoose
    reshape long cost premature gender sob dob, i(ID round) j(option)
    drop winter2 summer1
    
    gen chosen = option == choose1
    replace chosen =1 if option==2&choose1==0
    
    gen sobNum = 1 if sob=="January February March"
    replace sobNum = 2 if sob=="April May June"
    replace sobNum = 3 if sob=="July August September"
    replace sobNum = 4 if sob=="October November December"

    tab gender, gen(_gend)
    tab cost  , gen(_cost)
    tab premat, gen(_prem)
    tab sobNum, gen(_sob)
    tab dob   , gen(_dob)
    
    drop _gend1 _cost1 _prem1 _sob1 _dob1
    
    reg chosen _gend* _cost* _prem* _sob* _dob* i.round, cluster(ID)
    foreach nn of numlist 2 3 4 {
        local est`nn' = _b[_sob`nn']
        local se`nn'  = _se[_sob`nn']
    }    
    restore
    replace sim = `num' in `jj'
    foreach nn of numlist 2 3 4 {
        replace est`nn' = `est`nn'' in `jj'
        replace lb`nn'  = `est`nn''-1.96*`se`nn'' in `jj'
        replace ub`nn'  = `est`nn''+1.96*`se`nn'' in `jj'        
    }    

    local ++jj
}

replace sim = sim *100
gen sim2 = sim-0.1
gen sim4 = sim+0.1

#delimit ;
twoway rcap lb2 ub2 sim2, scheme(lean1) ||
    rcap lb3 ub3 sim ||
    rcap lb4 ub4 sim4 ||
    scatter est2 sim2, msymbol(S) msize(medium) ||
    scatter est3 sim, msymbol(Oh) msize(large)  ||
    scatter est4 sim4, msymbol(T) msize(medium) yline(0, lcolor(red))
xlabel(0(1)8) ytitle("Estimated Preference for SOB 2 or SOB 3")
xtitle("Simulated % Preference for SOB 2 or SOB 3 versus SOB 1 or SOB 4")
legend(order(4 "SOB 2" 5 "SOB 3" 6 "SOB 4") position(1) row(1) ring(0));
graph export simulationValues.eps, replace;
#delimit cr
