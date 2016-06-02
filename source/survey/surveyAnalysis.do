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
format stateProportion %5.2f
#delimit ;
spmap stateProportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord_mercator",
point(data("$DAT/BirthSurvey.dta") xcoord(long3) ycoord(lat3)
      select(drop if (latitude<24.39|latitude>49.38)|(longitude<-124.84|longitude>-66.9))
      size(*0.5) fcolor(red))
id(_ID) osize(thin) legtitle("Proportion of Respondents") legstyle(2) fcolor(Greens)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1));
graph export "$OUT/surveyCoverage.eps", as(eps) replace;

*clmethod(custom) clbreaks(0 0.01 0.02 0.04 0.06 0.08 0.10) legorder(lohi);
#delimit cr
restore

preserve
keep if nchild!=0
gen N = 1
gen gest = gestation + 5
gen Q1 = cbirthmonth >= 1 & cbirthmonth <=3
gen Q2 = cbirthmonth >= 4 & cbirthmonth <=6
gen Q3 = cbirthmonth >= 7 & cbirthmonth <=9
gen Q4 = cbirthmonth >=10 & cbirthmonth <=12

collapse (sum) N (mean) nchild sexchild fertmed gest Q1 Q2 Q3 Q4 /*
*/ (sd) sd_nchild=nchild sd_sexchild=sexchild sd_fertmed=fertmed /*
*/ sd_gest=gest sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4
expand 8
gen mean  = .
gen stdev = .
gen var   = "" 

local i = 1
foreach var of varlist nchild sexchild fertmed gest Q1 Q2 Q3 Q4 {
    replace mean  = `var' in `i'
    replace stdev = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
gen data = "MTurk"
keep mean stdev var data N
tempfile MTurkSum
save `MTurkSum'
restore

preserve
gen N = 1
replace ftotinc = 5000   if ftotinc==11
replace ftotinc = 15000  if ftotinc==12
replace ftotinc = 25000  if ftotinc==13
replace ftotinc = 35000  if ftotinc==14
replace ftotinc = 45000  if ftotinc==15
replace ftotinc = 55000  if ftotinc==16
replace ftotinc = 65000  if ftotinc==17
replace ftotinc = 75000  if ftotinc==18
replace ftotinc = 85000  if ftotinc==19
replace ftotinc = 95000  if ftotinc==20
replace ftotinc = 125000 if ftotinc==21
replace ftotinc = 175000 if ftotinc==22

gen educY     = 8 if educ==1
replace educY = 10 if educ==2
replace educY = 12 if educ==3
replace educY = 13 if educ==4
replace educY = 14 if educ==5
replace educY = 16 if educ==6
replace educY = 17 if educ==7
replace educY = 20 if educ==8
replace educY = 18 if educ==9
gen someCollege = educ>=4
gen white     = race == 11
gen black     = race == 12
gen otherRace = race!=11&race!=12
gen employed  = empstat==1
gen married   = marst==1


collapse (sum) N (mean) ftotinc educY someCollege married employed hispanic /*
*/ black white otherRace (sd) sd_ftotinc=ftotinc sd_educY=educY             /*
*/ sd_someCollege=someCollege sd_married=married sd_employed=employed       /*
*/ sd_hispanic=hispanic sd_black=black sd_white=white sd_otherRace=otherRace

expand 9
gen mean  = .
gen stdev = .
gen var   = "" 

local i = 1
foreach var of varlist ftotinc educY someCollege married employed hispanic /*
*/ black white otherRace {
    replace mean  = `var' in `i'
    replace stdev = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
gen data = "MTurk"
keep mean stdev var data N
tempfile MTurkSum2
save `MTurkSum2'
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
restore

preserve
keep if nchild > 0
gen N = 1
collapse (sum) N, by(nchild)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthProp
tempfile nchild
save `nchild'

use "$NVS/birthCond", clear

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

use "$NVS/natl2013", clear

gen N = 1
collapse (sum) N, by(lbo_rec)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthPropNVS
rename lbo_rec nchild
merge 1:1 nchild using `nchild'

graph bar birthPropNVS birthProp, over(nchild)                         /*
*/ legend(lab(1 "ACS") lab(2 "MTurk Sample")) scheme(s1mono)           /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4)) ytitle("Proportion")
graph export "$OUT/nchild.eps", as(eps) replace
restore

*preserve
use "$NVS/natl2013", clear
gen N_NV = 1
gen gest = 6 if estgest<=29
replace gest = 7  if estgest>29 & estgest<=34
replace gest = 8  if estgest>34 & estgest<=38
replace gest = 9  if estgest>38 & estgest<=43
replace gest = 10 if estgest>43
gen nchild = lbo_rec
gen sexchild = sex=="F"
gen     fertmed = 1 if rf_inftr=="Y"
replace fertmed = 0 if rf_inftr=="N"

gen Q1 = dob_mm >= 1 & dob_mm <=3
gen Q2 = dob_mm >= 4 & dob_mm <=6
gen Q3 = dob_mm >= 7 & dob_mm <=9
gen Q4 = dob_mm >=10 & dob_mm <=12

collapse (sum) N (mean) nchild sexchild fertmed gest Q1 Q2 Q3 Q4 /*
*/ (sd) sd_nchild=nchild sd_sexchild=sexchild sd_fertmed=fertmed /*
*/ sd_gest=gest sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4
expand 8
gen meanNV  = .
gen stdevNV = .
gen var   = "" 

local i = 1
foreach var of varlist nchild sexchild fertmed gest Q1 Q2 Q3 Q4 {
    replace meanNV  = `var' in `i'
    replace stdevNV = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
keep meanNV stdevNV var N_NV
tempfile NVSSSum
save `NVSSSum'


merge 1:1 var using `MTurkSum'
local i = 1
#delimit ;
local vnames `""Number of Children" "Female Child" "Used Fertility Treatment"
               "Gestation (months)" "Born January-March" "Born April-June"
               "Born July-September" "Born October-December""';
#delimit cr
local variables nchild sexchild fertmed gest Q1 Q2 Q3 Q4
tokenize `variables'
file open bstats using "$OUT/NVSScomp.txt", write replace
foreach var of local vnames {
    foreach stat in N mean stdev N_NV meanNV stdevNV {
        qui sum `stat' if var=="`1'"
        local val`stat'=r(mean)
    }
    qui ttesti `valN' `valmean' `valstdev' `valN_NV' `valmeanNV' `valstdevNV'
    foreach val in mu_1 sd_1 mu_2 sd_2 t {
        local `val'=round(r(`val')*1000)/1000
        if ``val''<1&``val''>0 local `val' = "0``val''"
    }
    local dif = round((`mu_1'-`mu_2')*1000)/1000
    if `dif'<1&`dif'>0 local dif = "0`dif'" 
    file write bstats "`var'&`mu_1'&(`sd_1')&`mu_2'&(`sd_2')&`dif'&`t'\\ " _n
    macro shift
}
file close bstats


restore



********************************************************************************
*** (5) Compare with ACS
********************************************************************************
foreach var in occ educ ftotinc {
    preserve
    gen N = 1
    collapse (sum) N, by(`var')
    egen tot = sum(N)
    gen prop`var' = N/tot
    tempfile `var'
    save ``var''
    restore
}
foreach var in occ educ ftotinc {
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

preserve
use "$ACS/ACS_20052014_cleaned", clear

keep if motherAge>=25&motherAge<=45&twins==0
drop if occ2010 == 9920

bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter
replace ftotinc = 11 if ftotinc <10000
replace ftotinc = 12 if ftotinc>=10000&ftotinc<20000
replace ftotinc = 13 if ftotinc>=20000&ftotinc<30000
replace ftotinc = 14 if ftotinc>=30000&ftotinc<40000
replace ftotinc = 15 if ftotinc>=40000&ftotinc<50000
replace ftotinc = 16 if ftotinc>=50000&ftotinc<60000
replace ftotinc = 17 if ftotinc>=60000&ftotinc<70000
replace ftotinc = 18 if ftotinc>=70000&ftotinc<80000
replace ftotinc = 19 if ftotinc>=80000&ftotinc<90000
replace ftotinc = 20 if ftotinc>=90000&ftotinc<100000
replace ftotinc = 21 if ftotinc>=100000&ftotinc<150000
replace ftotinc = 22 if ftotinc>=150000&ftotinc!=.
drop if ftotinc==.

gen N = 1
collapse (sum) N, by(ftotinc)
egen tot = sum(N)
gen ftotincACS = N/tot
merge 1:1 ftotinc using `ftotincKid'

#delimit ;
lab def inc1   11 "<10" 12 "[10-20)" 13 "[20-30)" 14 "[30-40)" 15 "[40-50)"
16 "[50-60)" 17 "[60-70)" 18 "[70-80)" 19 "[80-90)" 20 "[90-100)" 21 "[100-150)"
22 ">150";
lab val ftotinc inc1;
#delimit cr

graph bar ftotincACS propftotincKid, over(ftotinc) horizontal /*
*/ legend(lab(1 "ACS") lab(2 "MTurk Sample")) scheme(s1mono) /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4))
graph export "$OUT/income.eps", as(eps) replace
restore
exit
*/
********************************************************************************
*** (6) Graphs
********************************************************************************
use "$DAT/BirthSurvey"
keep if completed==1
gen age = 2016-birthyr

hist age, scheme(lean1) discrete xtitle("Respondent's Age") frac
graph export "$OUT/ageMTurk.eps", replace

exit
********************************************************************************
*** (7) Tables
********************************************************************************
local statform cells("count(label(N)) mean(fmt(2) label(Mean)) sd(fmt(2) label(Std.\ Dev.)) min(fmt(2) label(Min)) max(fmt(2) label(Max))")
    
gen white     = race == 11
gen black     = race == 12
gen otherRace = race!=11&race!=12
gen employed = empstat==1
gen unemployed = empstat==2

gen educY     = 8 if educ==1
replace educY = 10 if educ==2
replace educY = 12 if educ==3
replace educY = 13 if educ==4
replace educY = 14 if educ==5
replace educY = 16 if educ==6
replace educY = 17 if educ==7
replace educY = 20 if educ==8
replace educY = 18 if educ==9
gen married = marst == 1
replace gestation = gestation + 5

lab var sex      "Female"
lab var birthyr  "Year of Birth"
lab var age      "Age"
lab var educY    "Years of Education"
lab var nchild   "Number of Children"
lab var plankids "Plans to have children"
lab var morekids "Plans for more children"
lab var pregnant "Currently Pregnant"
lab var married  "Married"
lab var sexchild "Female Child"
lab var gestatio "Gestation (Months)"
lab var fertmed  "Used Fertility Treatment"
lab var SOBimpor "Importance of Birth Season"
lab var SOBtarge "Targeting Season of Birth"
lab var hispanic "Hispanic"
lab var black    "Black"
lab var white    "White"
lab var otherRac "Other Race"
lab var employed "Employed"
lab var cbirthyr "Child's Year of Birth"

#delimit ;
estpost sum sex age birthyr educY nchild plankids morekids pregnant 
married sexchild gestation fertmed SOBimport SOBtarget 
white black otherRace hispanic employed unemployed cbirthyr;
#delimit cr
estout using "$OUT/MTurkSum.tex", replace label style(tex) `statform'
