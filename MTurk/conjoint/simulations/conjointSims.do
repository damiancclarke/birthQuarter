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



*-------------------------------------------------------------------------------
*--- (2) Simulate
*-------------------------------------------------------------------------------
