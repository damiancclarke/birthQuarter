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


********************************************************************************
*** (2) Import
********************************************************************************
insheet using "$DAT/MTurk_returned_Principal.csv", delimit(";") names clear
replace approve = "839884" if regexm(approve,"839884,")==1
drop if approve=="A2I2L0WL1UTLTM"
drop if regexm(approve,"facebook")==1
drop if approve=="sfkhalf74heuiuew284d"
drop if approve=="{}"

destring approve, gen(qualtricsCode)
merge 1:m qualtricsCode using "$DAT/BirthSurvey"

keep if completed==1
keep if educ==educ_check
gen age      = 2016-birthyr
gen ageBirth = cbirthyr-birthyr

replace ageBirth = age if ageBirth==.

count if ageBirth>=25&ageBirth<=45&race==11&occ!=18&marst==1&qualtricsCode!=.
keep if  ageBirth>=25&ageBirth<=45&race==11&occ!=18&marst==1

keep qualtricsid workerid assignmentstatus educ birthyr state address ipaddress

save $OUT/surveyComparison, replace

keep assignmentstatus
outsheet using "$OUT/qualification.csv", comma replace
