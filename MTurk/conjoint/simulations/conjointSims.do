/* conjointSims.do v0.00         damiancclarke             yyyy-mm-dd:2016-09-27
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Import
*-------------------------------------------------------------------------------
use simulatedBase.dta
tab gender, gen(_gend)
tab cost  , gen(_cost)
tab eyecol, gen(_eyec)
tab sob   , gen(_sob)
tab dob   , gen(_dob)

drop _gend1 _cost1 _eyec1 _sob1 _dob1

reg chosen _gend* _cost* _eyec* _sob* _dob* i.round, cluster(ID)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
 local names GENDER Male Female COST 250 500 750 1000 1500 2000 2500 3000 /*
*/ 3500 4000 4500 5000 6000 7500 10000 EYE-COLOR Blue Brown Green         /*
*/ SEASON-OF-BIRTH Jan Feb Mar Apr May June July Aug Sep Oct Nov Dec      /*
*/ DAY-OF-BIRTH Weekday Weekend
tokenize `names'
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5      /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 _cost11 _cost12 _cost13 _cost14 _cost15 /*
*/ s EYE-COLOR _eyec1 _eyec2 _eyec3 s SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4  /*
*/ _sob5 _sob6 _sob7 _sob8 _sob9 _sob10 _sob11 _sob12 s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==22|`i'==27|`i'==41 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==21|`i'==26|`i'==40|`i'==44 {
    }
    else if `i'==2|`i'==6|`i'==23|`i'==28|`i'==42 {
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
lab def names -1 "GENDER" -2 "Male" -3 "Female" -4 " " -5 "COST" -6 "250" -7 "500"       /*
*/ -8 "750" -9 "1000" -10 "1500" -11 "2000" -12 "2500" -13 "3000" -14 "3500" -15 "4000"  /*
*/ -16 "4500" -17 "5000" -18 "6000" -19 "7500" -20 "10000" -21 " " -22 "EYE COLOR"       /*
*/ -23 "Blue"  -24 "Brown" -25 "Green" -26 " " -27 "SEASON OF BIRTH" -28 "Jan" -29 "Feb" /*
*/ -30 "Mar" -31 "Apr" -32 "May" -33 "June" -34 "Jul" -35 "Aug" -36 "Sep" -37 "Oct"      /*
*/ -38 "Nov" -39 "Dec" -40 " " -41 "DAY OF BIRTH" -42 "Weekday" -43 "Weekend" -44 " "
lab val Y names

#delimit ;
twoway rcap  LB UB Y in 1/44, horizontal scheme(s1mono) lcolor(black) ||
       scatter Y Est in 1/44, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1(-1)-44, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export simulatedEsts.eps, replace  

*-------------------------------------------------------------------------------
*--- (2) Simulate
*-------------------------------------------------------------------------------
use simulatedBase.dta, clear
keep ID round option chooses cost eyecolor gender sob dob chosen
reshape wide chooses cost eyecolor gender sob dob chosen, i(ID round) j(option)
drop chooses* chosen*
    
gen summer1 = sob1=="April"|sob1=="May"|sob1=="June"|sob1=="July"|/*
*/            sob1=="August"|sob1=="September"  
gen winter2 = sob2=="January"|sob2=="February"|sob2=="March"|sob2=="October"|/*
*/            sob2=="November"|sob2=="December"

gen summerDif = summer1==1&winter2==1
replace summerDif = -1 if summer1==0&winter2==0

foreach var in sim est ub lb {
    gen `var'=.
}

local jj = 1
foreach num of numlist 0.001(0.001)0.1 {
    preserve
    gen rchoose = runiform()-0.5+`num'*summerDif
    gen choose1 = rchoose>0
    drop rchoose
    reshape long cost eyecolor gender sob dob, i(ID round) j(option)
    drop winter2 summer1
    
    gen chosen = option == choose1
    replace chosen =1 if option==2&choose1==0
    
    gen sobNum = 2 if sob=="April"|sob=="May"|sob=="June"|sob=="July"|/*
    */                sob=="August"|sob=="September"
    replace sobNum = 1 if sob=="January"|sob=="February"|sob=="March"|/*
    */                    sob=="October"|sob=="November"|sob=="December"

    tab gender, gen(_gend)
    tab cost  , gen(_cost)
    tab eyecol, gen(_prem)
    tab sobNum, gen(_sob)
    tab dob   , gen(_dob)
    
    drop _gend1 _cost1 _prem1 _sob1 _dob1
    
    reg chosen _gend* _cost* _prem* _sob* _dob* i.round, cluster(ID)
    foreach nn of numlist 2 {
        local est`nn' = _b[_sob`nn']
        local se`nn'  = _se[_sob`nn']
    }    
    restore
    replace sim = `num' in `jj'
    foreach nn of numlist 2 {
        replace est = `est`nn'' in `jj'
        replace lb  = `est`nn''-1.96*`se`nn'' in `jj'
        replace ub  = `est`nn''+1.96*`se`nn'' in `jj'        
    }
    local ++jj
}


replace sim = sim *100

#delimit ;
twoway line est sim, lcolor(blue) lwidth(thick) scheme(lean1) ||
    line lb  sim, lcolor(blue) lwidth(vthin) lpattern(dash)  ||
    line ub  sim, lcolor(blue) lwidth(vthin) lpattern(dash)  
yline(0, lcolor(red)) ytitle("Estimated Preference for Good Season")
xtitle("Simulated % Preference for Good Season")
legend(order(1 "Point Estimate" 2 "95% CI" ) position(1) row(1) ring(0));
graph export simulationValues2.eps, replace;
#delimit cr

foreach var in sim est ub lb {
    drop `var'
    gen `var'=.
}
lab def months -1 "Jan" -2 "Feb" -3 "Mar" -4 "Apr" -5 "May" -6 "Jun" /*
*/             -7 "Jul" -8 "Aug" -9 "Sep" -10 "Oct" -11 "Nov" -12 "Dec"


local jj = 1
local simgraphs
foreach num of numlist 0(0.01)0.11 {
    preserve
    gen rchoose = runiform()-0.5+`num'*summerDif
    gen choose1 = rchoose>0
    drop rchoose
    reshape long cost eyecolor gender sob dob, i(ID round) j(option)
    drop winter2 summer1
    
    gen chosen = option == choose1
    replace chosen =1 if option==2&choose1==0
    
    gen sobNum = 1 if sob=="January"
    replace sobNum = 2 if sob=="February"
    replace sobNum = 3 if sob=="March"
    replace sobNum = 4 if sob=="April"
    replace sobNum = 5 if sob=="May"
    replace sobNum = 6 if sob=="June"
    replace sobNum = 7 if sob=="July"
    replace sobNum = 8 if sob=="August"
    replace sobNum = 9 if sob=="September"
    replace sobNum = 10 if sob=="October"
    replace sobNum = 11 if sob=="November"
    replace sobNum = 12 if sob=="December"
    
    tab gender, gen(_gend)
    tab cost  , gen(_cost)
    tab eyecol, gen(_prem)
    tab sobNum, gen(_sob)
    tab dob   , gen(_dob)
    
    drop _gend1 _cost1 _prem1 _sob1 _dob1
    
    reg chosen _gend* _cost* _prem* _sob* _dob* i.round, cluster(ID)
    foreach nn of numlist 2(1)12 {
        local est`nn' = _b[_sob`nn']
        local se`nn'  = _se[_sob`nn']
    }
    replace est = 0 in 1
    replace lb  = 0 in 1
    replace ub  = 0 in 1
    foreach nn of numlist 2 3 4 5 6 7 8 9 10 11 12 {
        replace est = `est`nn'' in `nn'
        replace lb  = `est`nn''-1.96*`se`nn'' in `nn'
        replace ub  = `est`nn''+1.96*`se`nn'' in `nn'        
    }    
    gen Y = _n
    replace Y = -Y
    lab val Y months
    
    #delimit ;
    twoway rcap  lb ub Y in 1/12, horizontal scheme(s1mono) lcolor(black) ||
        scatter Y est in 1/12, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1(-1)-12, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) 
    name(s`jj', replace) title("Preference = `num'");
    #delimit cr
    local simgraphs `simgraphs' s`jj'
    
    restore
    local ++jj
}

graph combine `simgraphs', scheme(s1mono) ysize(8)
graph export simulatedMonths.eps, replace

