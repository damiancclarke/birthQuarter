/* qualification.do v0.00      damiancclarke              yyyy-mm-dd:2016-09-04
---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

  Generate qualification data based on first round.
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals 
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/survey/main"
global OUT "~/investigacion/2015/birthQuarter/data/survey/conjoint"

cap mkdir $OUT

use "$DAT/BirthSurvey", clear
keep if completed==1
keep if educ==educ_check
gen age      = 2016-birthyr
gen ageBirth = cbirthyr-birthyr

replace ageBirth = age if ageBirth==.
replace ageBirth = .   if  plankids ==2

count if ageBirth>=25&ageBirth<=45&race==11&occ!=18&marst==1

keep if  ageBirth>=25&ageBirth<=45&race==11&occ!=18&marst==1

keep qualtricsid educ birthyr state address ipaddress

save $OUT/surveyComparison, replace

keep qualtricsid
outsheet using "$OUT/qualification.csv", comma replace
