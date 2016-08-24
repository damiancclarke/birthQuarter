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
local vars GENDER _gend1 _gend2 COST _cost1 _cost2 _cost3 _cost4 _cost5   /*
*/ _cost6 _cost7 _cost8 _cost9 PREMATURE _prem1 _prem2 SEASON-OF_BIRTH    /*
*/ _sob1 _sob2 _sob3 _sob4 DAY-OF-BIRTH _dob1 _dob2

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==4|`i'==14|`i'==17|`i'==22 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==2|`i'==5|`i'==15|`i'==18|`i'==23 {
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
lab def names -1 "GENDER" -2 "Male" -3 "Female" -4 "COST" -5 "0" -6 "50"   /*
*/ -7 "100" -8 "250" -9 "500" -10 "1000" -11 "2500" -12 "5000" -13 "10000" /*
*/ -14 "PREMATURE" -15 "Yes" -16 "No" -17 "SEASON OF BIRTH" -18 "Jan-Mar"  /*
*/ -19 "Apr-June" -20 "July-Sep" -21 "Oct-Dec" -22 "DAY-OF-BIRTH"          /*
*/ -23 "Weekday" -24 "Weekend"
lab val Y names

#delimit ;
twoway rcap  LB UB Y in 1/24, horizontal scheme(s1mono) ||
       scatter Y Est in 1/24, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(black)) ylabel(-1(-1)-24, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)")
legend(lab(1 "95% CI") lab(2 "Point Estimate"));

#delimit cr
graph export simulatedEsts.eps, replace
