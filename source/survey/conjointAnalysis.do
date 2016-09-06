/* conjointAnalysis.do v0.00     damiancclarke             yyyy-mm-dd:2016-09-06
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/conjoint"

log using "$LOG/conjointAnalysis.txt", text replace

*-------------------------------------------------------------------------------
*--- (2) Generate
*-------------------------------------------------------------------------------
use "$DAT/conjointBase"

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)
tab dob        , gen(_dob)

drop _gend1 _cost4 _bwt2 _sob5 _dob1
rename _cost3 _cost4
rename _cost1 _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _bwt1 _bwt2
rename _bwt4 _bwtx
rename _bwt6 _bwt4
rename _bwtx _bwt6
rename _bwt5 _bwtx
rename _bwt7 _bwt5
rename _bwtx _bwt7
rename _sob9 _sob5
rename _sob12 _sob9
rename _sob3 _sob12
rename _sob8 _sob3
rename _sob2 _sob8
rename _sob4 _sob2
rename _sob1 _sob4
rename _sob6 _sobx
rename _sob7 _sob6
rename _sobx _sob7
rename _sob10 _sobx
rename _sob11 _sob10
rename _sobx _sob11

*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
reg chosen _gend* _cost* _bwt* _sob* _dob* i.round i.option, cluster(ID)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
 local names GENDER Male Female COST 250 750 1000 2000 3000 4000 5000 6000 7500 /*
*/ 10000 BIRTH-WEIGHT 6lbs-9oz 6lbs-13oz 7lbs-0oz 7lbs-4oz 7lbs-7oz 7lbs-11oz   /*
*/ 7lbs-15oz 8lbs-2oz 8lbs-6oz 8lbs-9oz SEASON-OF-BIRTH Jan Feb Mar Apr May June/*
*/ July Aug Sep Oct Nov Dec DAY-OF-BIRTH Weekday Weekend
tokenize `names'
local vars GENDER _gend1 _gend2 s COST _cost1 _cost2 _cost3 _cost4 _cost5       /*
*/ _cost6 _cost7 _cost8 _cost9 _cost10 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4   /*
*/ _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 s SEASON-OF_BIRTH _sob1 _sob2 _sob3     /*
*/ _sob4 _sob5 _sob6 _sob7 _sob8 _sob9 _sob10 _sob11 _sob12 s DAY-OF-BIRTH      /*
*/  _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==5|`i'==17|`i'==29|`i'==43 {
        dis "``i''"
        dis "`var'"
    }
    else if `i'==4|`i'==16|`i'==28|`i'==42|`i'==46 {
    }
    else if `i'==2|`i'==6|`i'==18|`i'==30|`i'==44 {
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
lab def names -1 "GENDER" -2 "Male" -3 "Female" -4 " " -5 "COST" -6 "250" -7 "750"  /*
*/ -8 "1000" -9 "2000" -10 "3000" -11 "4000" -12 "5000" -13 "6000" -14 "7500"       /*
*/ -15 "10000" -16 " " -17 "BIRTH WEIGHT" -18 "6lbs, 9oz" -19 "6lbs, 13oz"          /*
*/ -20 "7lbs, 0oz" -21 "7lbs, 4oz" -22 "7lbs, 7oz" -23 "7lbs, 11oz" -24 "7lbs, 15oz"/*
*/ -25 "8lbs, 2oz" -26 "8lbs, 6oz" -27 "8lbs, 9oz" -28 " " -29 "MONTH OF BIRTH"     /*
*/ -30 "Jan" -31 "Feb" -32 "Mar" -33 "Apr" -34 "May" -35 "June" -36 "Jul" -37 "Aug" /*
*/ -38 "Sep" -39 "Oct" -40 "Nov" -41 "Dec" -42 " " -43 "DAY OF BIRTH" -44 "Weekday" /*
*/ -45 "Weekend" -46 " "
lab val Y names

*-------------------------------------------------------------------------------
*--- (4) Graph
*-------------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/46, horizontal scheme(s1mono) lcolor(black) ||
       scatter Y Est in 1/46, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1(-1)-44, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/conjointMain.eps", replace  
