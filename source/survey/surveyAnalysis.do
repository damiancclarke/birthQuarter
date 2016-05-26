/* surveyAnalysis.do v0.00       damiancclarke             yyyy-mm-dd:2016-04-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Analyse survey data


*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals    
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/survey/main"
global NVS "~/investigacion/2015/birthQuarter/data/nvss"
global ACS "~/investigacion/2015/birthQuarter/data/raw"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/main/descriptives"
global GEO "~/investigacion/2015/birthQuarter/data/maps/states_simplified"

log using "$LOG/surveyAnalysis.txt", text replace

cap mkdir "$OUT"

********************************************************************************
*** (2) Open 
********************************************************************************
use "$DAT/BirthSurvey"
keep if completed==1

decode state, gen(statename)
bys state: gen stateProportion = _N/3003

********************************************************************************
*** (3) Test geographic var
********************************************************************************
preserve
collapse stateProportion, by(statename)
rename statename NAME

merge 1:1 NAME using "$GEO/US_db"

#delimit ;
spmap stateProportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord", title("Coverage of the Survey")
point(data("$DAT/BirthSurvey.dta") xcoord(longitude) ycoord(latitude)
      select(drop if (latitude<5.87|latitude>71.39)|(longitude<-180|longitude>-66.9))
      size(*0.5) fcolor(orange) ocolor(white) osize(vvthin)) id(_ID) osize(thin)
fcolor(Greens);
graph export "$OUT/surveyCoverage.eps", as(eps) replace;

#delimit cr
restore

********************************************************************************
*** (4) Compare with NVSS
********************************************************************************
preserve
gen N = 1

collapse (sum) N, by(cbirthmonth)
drop if cbirthmonth == .
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthProp
rename cbirthmonth Month

tempfile bmonth
save `bmonth'

use "$NVS/birthCond"

gen N = 1
collapse (sum) N, by(birthMonth)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthPropNVSS
rename birthMonth Month

merge 1:1 Month using `bmonth'
local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProp     Month, `line1' ||
       line birthPropNVSS Month, `line2' scheme(s1mono) 
xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
       9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec", axis(1)) xtitle("Birth Month")
legend(label(1 "MTurk Survey Sample") label(2 "NVSS Birth Data"))
ytitle("Proportion of Births");
graph export "$OUT/birthsMonth.eps", as(eps) replace;
#delimit cr

restore


********************************************************************************
*** (4) Compare with ACS
********************************************************************************
foreach var in occ educ {
    preserve
    gen N = 1
    collapse (sum) N, by(`var')
    egen tot = sum(N)
    gen prop`var' = N/tot
    tempfile `var'
    save ``var''
    restore
}
foreach var in occ educ {
    preserve
    keep if childFlag==1
    gen N = 1
    collapse (sum) N, by(`var')
    egen tot = sum(N)
    gen prop`var'Kid = N/tot
    tempfile `var'Kid
    save ``var'Kid'
    restore
}

preserve
use "$ACS/ACS_20052014_cleaned", clear
keep if motherAge>=25&motherAge<=45&twins==0
keep if marst==1
drop if occ2010 == 9920

bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter

gen N = 1
collapse (sum) N, by(twoLevelOcc)
egen tot = sum(N)
gen propoccACS = N/tot
sort twoLevelOcc
gen occ = _n

merge 1:1 occ using `occKid'
#delimit ;
lab def occ1 1 "Architecture" 2 "Arts, Design, Media" 3 "Business Operations"
4 "Community/Soc Services" 5 "Computer/Mathematical" 6 "Education, Library"
7 "Financial" 8 "Food Preparation" 9 "Healthcare Practitioners"
10 "Healthcare Support" 11 "Legal" 12 "Life, Physical, Social Sci"
13 "Management" 14 "Office and Administrative" 15 "Personal Care" 16 "Production"
17 "Sales" 18 "Never Worked for Pay";
lab val occ occ1;
#delimit cr

drop if occ==18
graph bar propoccACS propoccKid, over(occ) horizontal /*
*/ legend(lab(1 "ACS") lab(2 "MTurk Sample")) scheme(s1mono) /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4))
graph export "$OUT/occupations.eps", as(eps) replace
restore


preserve
use "$ACS/ACS_20052014_cleaned", clear
keep if motherAge>=25&motherAge<=45&twins==0
keep if marst==1
drop if occ2010 == 9920

bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter
drop educ
generate educ = 1 if educd <= 26
replace  educ = 2 if educd>26&educd<=61
replace  educ = 3 if educd>61&educd<=64
replace  educ = 4 if educd>64&educd<=71
replace  educ = 5 if educd==81
replace  educ = 6 if educd==101
replace  educ = 7 if educd==114
replace  educ = 8 if educd==116
replace  educ = 9 if educd==115


gen N = 1
collapse (sum) N, by(educ)
egen tot = sum(N)
gen propeducACS = N/tot
merge 1:1 educ using `educKid'

#delimit ;
lab def educ1   1 "<=8th grade" 2 "Some Highschool" 3 "Highschool Degree/GED"
4 "Some College" 5 "2 year College Degree" 6 "4 year College Degree"
7 "Masters Degree" 8 "Doctoral Degree" 9 "Professional Degree";
lab val educ educ1;
#delimit cr

replace propeducKid=0 if propeducKid==.&educ==1
graph bar propeducACS propeducKid, over(educ) horizontal /*
*/ legend(lab(1 "ACS") lab(2 "MTurk Sample")) scheme(s1mono) /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4))
graph export "$OUT/education.eps", as(eps) replace
restore
