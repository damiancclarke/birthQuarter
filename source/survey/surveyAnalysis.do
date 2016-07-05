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

#delimit ;
local estopt cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label;
#delimit cr


cap mkdir "$OUT"
/*
********************************************************************************
*** (2) Open 
********************************************************************************
use "$DAT/BirthSurvey"
keep if completed==1
exit
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
replace ftotinc = ftotinc/1000

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
*/ legend(lab(1 "NVSS") lab(2 "MTurk Sample")) scheme(s1mono)           /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4)) ytitle("Proportion")
graph export "$OUT/nchild.eps", as(eps) replace
restore

preserve
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


preserve
use "$ACS/ACS_20052014_cleaned", clear

keep if motherAge>=25&motherAge<=45&twins==0
drop if occ2010 == 9920
gen N_ACS = 1
replace ftotinc = ftotinc/1000
gen educY     = 0  if educ==0
replace educY = 4  if educ==1
replace educY = 8  if educ==2
replace educY = 9  if educ==3
replace educY = 10 if educ==4
replace educY = 11 if educ==5
replace educY = 12 if educ==6
replace educY = 13 if educ==7
replace educY = 14 if educ==8
replace educY = 16 if educ==10
replace educY = 17 if educ==11

gen someCollege = educ>=7
gen white     = race == 1
gen black     = race == 2
gen otherRace = race!=1&race!=2
gen employed  = empstat==1
rename hispan hispanic

collapse (sum) N_ACS (mean) ftotinc educY someCollege married employed hispanic /*
*/ black white otherRace (sd) sd_ftotinc=ftotinc sd_educY=educY             /*
*/ sd_someCollege=someCollege sd_married=married sd_employed=employed       /*
*/ sd_hispanic=hispanic sd_black=black sd_white=white sd_otherRace=otherRace

expand 9
gen meanACS  = .
gen stdevACS = .
gen var      = "" 


local i = 1
foreach var of varlist ftotinc educY someCollege married employed hispanic /*
*/ black white otherRace {
    replace mean  = `var' in `i'
    replace stdev = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
keep meanACS stdevACS var N_ACS
tempfile ACSSum
save `ACSSum'


merge 1:1 var using `MTurkSum2'
local i = 1
#delimit ;
local vnames `""Family Income" "Education (Years)" "Some College +" "Married"
               "Currently Employed" "Hispanic" "Black" "White" "Other Race""';
#delimit cr
local variables ftotinc educY someCollege married employed hispanic /*
*/ black white otherRace
tokenize `variables'
file open mstats using "$OUT/ACScomp.txt", write replace
foreach var of local vnames {
    foreach stat in N mean stdev N_ACS meanACS stdevACS {
        qui sum `stat' if var=="`1'"
        local val`stat'=r(mean)
    }
    qui ttesti `valN' `valmean' `valstdev' `valN_ACS' `valmeanACS' `valstdevACS'
    foreach val in mu_1 sd_1 mu_2 sd_2 t {
        local `val'=round(r(`val')*1000)/1000
        if ``val''<1&``val''>0 local `val' = "0``val''"
    }
    local dif = round((`mu_1'-`mu_2')*1000)/1000
    if `dif'<1&`dif'>0 local dif = "0`dif'" 
    file write mstats "`var'&`mu_1'&(`sd_1')&`mu_2'&(`sd_2')&`dif'&`t'\\ " _n
    macro shift
}
file close mstats

********************************************************************************
*** (6) Graphs
********************************************************************************
use "$DAT/BirthSurvey", clear
keep if completed==1
keep if educ==educ_check

foreach n of numlist 0 1 {
    if `n'== 0 local app
    if `n'== 1 {
        local app Msample
        keep if race==11&hispanic==0
    }
    
    twoway scatter WTPsob WTPdiabetes, jitter(0.5 ) scheme(lean1) /*
    */ ytitle("... to have baby in preferred season")
    *|| lfit WTPsob WTPdiabetes, /**/ lcolor(red) legend(off)
    graph export "$OUT/WTPboth`app'.eps", replace

    cap gen age = 2016-birthyr

    hist age, scheme(lean1) discrete xtitle("Respondent's Age") frac
    graph export "$OUT/ageMTurk`app'.eps", replace

    cap gen WTPratio = WTPsob/WTPdiabetes
    cap gen WTPdifference = WTPdiabetes-WTPsob

    sum WTPdifference
    local avedif = r(mean)
    sum WTPsob
    local avesob = round(r(mean)*100)/100

    #delimit ;
    hist WTPdifference, scheme(lean1) xtitle("Difference in Willingess to Pay") 
      frac discrete xline(`avedif', lcolor(red) lwidth(thick) lpattern(dash))  
      note(Average willingness to pay to avoid season of birth is `avesob'%);
    graph export "$OUT/WTPdifference`app'.eps", replace;


    local cond sex==1 sex==0 minTemp<14 minTemp>=14 childFlag==1 childFlag!=1
         educ<5 educ>4 educ<5&minTemp<14 educ<5&minTemp>=14 educ>4&minTemp<14
         educ>4&minTemp>=14;
    local name F M cold warm kids nokids noDegree Degree noDegreeCold
    noDegreeWarm DegreeCold DegreeWarm;
    tokenize `name';
    #delimit cr
    
    foreach c of local cond {
        preserve
        keep if `c'
        sum WTPdifference
        local avedif = r(mean)
        sum WTPsob
        local avesob = round(r(mean)*100)/100

        #delimit ;
        hist WTPdifference, scheme(lean1) frac discrete
        xtitle("Difference in Willingess to Pay")
        xline(`avedif', lcolor(red) lwidth(thick) lpattern(dash))
        note(Average willingness to choose season of birth is `avesob'%);
        graph export "$OUT/WTPdifference`1'`app'.eps", replace;
        #delimit cr
        
        restore
        macro shift
    }


    cap gen importance= SOBimport
    replace importance = pSOBimport if pSOBimport!=.

    preserve
    gen N = 1
    collapse (sum) N, by(importance)
    egen tot = sum(N)
    gen quantity = N/tot
    graph bar quantity, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents")
    graph export "$OUT/SOBimportance`app'.eps", replace
    restore

    preserve
    gen N = 1
    replace childFlag=0 if childFlag==.
    collapse (sum) N, by(importance childFlag)
    drop if importance==.
    bys childFlag: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(childFlag)

    graph bar quantity1 quantity0, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "Had Children") lab(2 "Will Have Children"))
    graph export "$OUT/SOBimportanceKids`app'.eps", replace
    restore

    preserve
    gen N = 1
    gen cold = minTemp <14
    collapse (sum) N, by(importance cold)
    drop if importance==.
    bys cold: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(cold)

    graph bar quantity1 quantity0, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "Cold Winter") lab(2 "Mild Winter"))
    graph export "$OUT/SOBimportanceWeather`app'.eps", replace
    restore

    preserve
    gen N = 1
    gen degree = educ > 4
    collapse (sum) N, by(importance degree)
    drop if importance==.
    bys degree: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(degree)

    graph bar quantity0 quantity1, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "No College Degree") lab(2 "College Degree"))
    graph export "$OUT/SOBimportanceEduc`app'.eps", replace
    restore

    preserve
    gen N = 1
    keep if plankids==1|plankids==3|childFlag==1
    gen ageGroup = 1 if age>=25&age<35
    replace ageGroup = 2 if age>35
    drop if ageGroup==.
    collapse (sum) N, by(importance ageGroup)
    drop if importance==.
    bys ageGroup: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(ageGroup)

    graph bar quantity1 quantity2, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "25-34 Year-Olds") lab(2 "> 35 Year-Olds"))
    graph export "$OUT/SOBimportanceAge`app'.eps", replace
    restore
    
    preserve
    gen N = 1
    gen teacher = occ == 6
    collapse (sum) N, by(importance teacher)
    drop if importance==.
    bys teacher: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(teacher)

    graph bar quantity0 quantity1, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "Non-Teachers") lab(2 "Teachers"))
    graph export "$OUT/SOBimportanceTeachers`app'.eps", replace
    restore

    preserve
    gen N = 1
    gen teacher = occ == 6
    keep if childFlag==1
    collapse (sum) N, by(importance teacher)
    drop if importance==.
    bys teacher: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(teacher)

    graph bar quantity0 quantity1, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "Non-Teachers") lab(2 "Teachers"))
    graph export "$OUT/SOBimportanceParentTeachers`app'.eps", replace
    restore

    preserve
    gen N = 1
    gen teacher = occ == 6 
    keep if plankids==1|plankids==3
    collapse (sum) N, by(importance teacher)
    drop if importance==.
    bys teacher: egen tot = sum(N)
    gen quantity = N/tot
    drop N tot
    reshape wide quantity, i(importance) j(teacher)

    graph bar quantity0 quantity1, over(importance) scheme(lean1) /*
    */ ytitle("Proportion of Respondents") /*
    */ legend(lab(1 "Non-Teachers") lab(2 "Teachers"))
    graph export "$OUT/SOBimportancePlansTeachers`app'.eps", replace
    restore

    
    
    preserve
    collapse SOBbirthday SOBluck SOBjob SOBsch SOBtax SOBchea SOBmhea
    local i = 1
    foreach v in birthday lucky jobs school tax chealth mhealth {
        rename SOB`v' SOB`i'
        local ++i
    }
    gen N = 1
    reshape long SOB, i(N) j(var)
    gen varname = ""
    local i = 1
    foreach v in birthday lucky jobs school tax {
        replace varname = "`v'" if var==`i'
        local ++i
    }
    replace varname = "child health" if var==6
    replace varname = "mom health" if var==7

    graph bar SOB, over(varname, sort(1)) scheme(lean1) /*
    */ ytitle("Importance of Factor")
    graph export "$OUT/SOBreason`app'.eps", replace
    restore

    preserve
    gen cold = minTemp <14
    collapse SOBbirth SOBluck SOBjob SOBsch SOBtax SOBche SOBmhea, by(cold)
    local i = 1
    foreach v in birthday lucky jobs school tax chealth mhealth {
        rename SOB`v' SOB`i'
        local ++i
    }

    reshape long SOB, i(cold) j(var)
    gen varname = ""
    local i = 1
    foreach v in birthday lucky jobs school tax {
        replace varname = "`v'" if var==`i'
        local ++i
    }
    replace varname = "child" if var==6
    replace varname = "mother" if var==7
    reshape wide SOB , i(varname) j(cold)
    
    graph bar SOB1 SOB0, over(varname, sort(1)) scheme(lean1)  /*
    */ legend(lab(1 "Cold Winters") lab(2 "Mild Winters")) /*
    */ ytitle("Importance of Factor")
    graph export "$OUT/SOBreasonCold`app'.eps", replace
    restore

    preserve
    gen college = educ > 4
    collapse SOBbirth SOBluck SOBjob SOBsch SOBtax SOBche SOBmhe, by(college)
    local i = 1
    foreach v in birthday lucky jobs school tax chealth mhealth {
        rename SOB`v' SOB`i'
        local ++i
    }

    reshape long SOB, i(college) j(var)
    gen varname = ""
    local i = 1
    foreach v in birthday lucky jobs school tax {
        replace varname = "`v'" if var==`i'
        local ++i
    }
    replace varname = "child" if var==6
    replace varname = "mother" if var==7
    reshape wide SOB , i(varname) j(college)
    
    graph bar SOB1 SOB0, over(varname, sort(1)) scheme(lean1) /*
    */ legend(lab(1 "College Degree") lab(2 "No Degree"))     /*
    */ ytitle("Importance of Factor")
    graph export "$OUT/SOBreasonCollege`app'.eps", replace
    restore
}

gen teacher = occ == 6
gen importance6plus=importance>=6 if importance!=.
sum importance6plus if teacher==1
sum importance6plus if teacher==0

sum importance6plus if teacher==1&childFlag==1
sum importance6plus if teacher==0&childFlag==1

sum importance6plus if teacher==1&(plankids==1|plankids==3)
sum importance6plus if teacher==0&(plankids==1|plankids==3)

sum importance6plus if childFlag==1
sum importance6plus if plankids==1|plankids==3

exit

********************************************************************************
*** (7) Tables
********************************************************************************
use "$DAT/BirthSurvey", clear
keep if completed==1
keep if educ==educ_check
gen WTPdifference = WTPdiabetes-WTPsob

file open bstats using "$OUT/SOBvalues.tex", write replace
#delimit ;
file write bstats "\begin{table}[htpb!]\caption{Season of Birth Descriptives}" 
                  _n "\begin{tabular}{lccccccccc} \toprule" _n
                  "& All & \multicolumn{2}{c}{Children} & "
                  "\multicolumn{2}{c}{Occupation}&\multicolumn{2}{c}{Some College +}"
                  "&\multicolumn{2}{c}{Target SOB}\\"
                  "\cmidrule(r){3-4}\cmidrule(r){5-6}\cmidrule(r){7-8}\cmidrule(r){9-10}" _n
                  "&&Yes&Plan&Teacher&Non-Teacher&Yes&No&Yes&No\\" _n
                  "\midrule ";
#delimit cr

gen All = 1
#delimit ;
local conds All==1 childFlag==1 plankids==1|plankids==3 occ==6 occ!=6 educ>3
            educ<4 SOBtarget==1|pSOBtarget==1 SOBtarget==0|pSOBtarget==0;
#delimit cr

egen chooseSOB    = rowtotal(SOBtarget pSOBtarget), missing
egen importSOB    = rowtotal(SOBimport pSOBimport), missing

#delimit ;
local vnames `""Choose SOB" "Importance of SOB" "Lucky Dates" "Birthdays"
"Tax" "Work" "School Entry" "Child Health" "Mom's Health"  "Diabetes Avoidance"
"Choose SOB" "Difference (Diabetes $-$ SOB)" "';
#delimit cr

local j=1
local reasons SOBlucky SOBbirthday SOBtax SOBjobs SOBschool SOBchealth SOBmhealth
local variables  chooseSOB importSOB `reasons' WTPdiabetes WTPsob WTPdiff
tokenize `variables'

foreach v of local vnames {    
    local c=1
    foreach cond of local conds {
        sum `1' if `cond'
        local v`c'=round(r(mean)*1000)/1000
        if `v`c''<1&`v`c''>0 local v`c' "0`v`c''"
        local ++c
    }
    
    if `j'<3 {
        file write bstats "`v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9' \\" _n
    }
    else if `j'==3 {
        file write bstats "\multicolumn{10}{l}{\textbf{Reasons (Importance)}} \\" _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>3&`j'<10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'==10 {
        file write bstats "\multicolumn{10}{l}{\textbf{Willingness to Pay}} \\ " _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    macro shift
    local ++j
}

local c=1
foreach cond of local conds {
    count if `cond'
    local v`c'=r(N)
    local ++c
}
file write bstats "&&&&&&&&&\\" _n
file write bstats "Observations&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n


#delimit ;
file write bstats "\bottomrule "_n;
file write bstats "\multicolumn{10}{p{21.4cm}}{{\footnotesize \textsc{Notes}:"
" Full sample of respondents who passed all attention checks and answered  "
"consistently are included.  Importance of season of birth and all reasons "
"are ranked on a 1 to 10 scale, where 1 is not important at all and 10 is  "
"extremely important.  Questions about children and targeting are asked to "
"all people who have children, but not to women above fertile age without  "
"children. These are 2,380 of the 2,938 eligible respondents.}}" _n;
file write bstats "\end{tabular}\end{table}" _n;
#delimit cr
file close bstats

preserve
keep if sex==1

file open bstats using "$OUT/SOBvaluesWomen.tex", write replace
#delimit ;
file write bstats "\begin{table}[htpb!]\caption{Season of Birth Descriptives (Women Only)}" 
                  _n "\begin{tabular}{lccccccccc} \toprule" _n
                  "& All & \multicolumn{2}{c}{Children} & "
                  "\multicolumn{2}{c}{Occupation}&\multicolumn{2}{c}{Some College +}"
                  "&\multicolumn{2}{c}{Target SOB}\\"
                  "\cmidrule(r){3-4}\cmidrule(r){5-6}\cmidrule(r){7-8}\cmidrule(r){9-10}" _n
                  "&&Yes&Plan&Teacher&Non-Teacher&Yes&No&Yes&No\\" _n
                  "\midrule ";
#delimit cr

#delimit ;
local conds All==1 childFlag==1 plankids==1|plankids==3 occ==6 occ!=6 educ>3
            educ<4 SOBtarget==1|pSOBtarget==1 SOBtarget==0|pSOBtarget==0;
#delimit cr

#delimit ;
local vnames `""Choose SOB" "Importance of SOB" "Lucky Dates" "Birthdays"
"Tax" "Work" "School Entry" "Child Health" "Mom's Health"  "Diabetes Avoidance"
"Choose SOB" "Difference (Diabetes $-$ SOB)" "';
#delimit cr

local j=1
local reasons SOBlucky SOBbirthday SOBtax SOBjobs SOBschool SOBchealth SOBmhealth
local variables  chooseSOB importSOB `reasons' WTPdiabetes WTPsob WTPdiff
tokenize `variables'

foreach v of local vnames {    
    local c=1
    foreach cond of local conds {
        sum `1' if `cond'
        local v`c'=round(r(mean)*1000)/1000
        if `v`c''<1&`v`c''>0 local v`c' "0`v`c''"
        local ++c
    }
    
    if `j'<3 {
        file write bstats "`v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9' \\" _n
    }
    else if `j'==3 {
        file write bstats "\multicolumn{10}{l}{\textbf{Reasons (Importance)}} \\" _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>3&`j'<10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'==10 {
        file write bstats "\multicolumn{10}{l}{\textbf{Willingness to Pay}} \\ " _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    macro shift
    local ++j
}

local c=1
foreach cond of local conds {
    count if `cond'
    local v`c'=r(N)
    local ++c
}
file write bstats "&&&&&&&&&\\" _n
file write bstats "Observations&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n


#delimit ;
file write bstats "\bottomrule "_n;
file write bstats "\multicolumn{10}{p{21.4cm}}{{\footnotesize \textsc{Notes}:"
" Female sample of respondents who passed all attention checks and answered"
" consistently are included. Importance of season of birth and all reasons "
"are ranked on a 1 to 10 scale, where 1 is not important at all and 10 is  "
"extremely important.  Questions about children and targeting are asked to "
"all women who have children, and all women who do not have children below "
"the age of 49.  These are 1,164 of the 1,439 eligible respondents.}}" _n;
file write bstats "\end{tabular}\end{table}" _n;
#delimit cr
file close bstats
restore

preserve
keep if marst==1&race==11&hispanic==0

file open bstats using "$OUT/SOBvaluesMarried.tex", write replace
#delimit ;
file write bstats "\begin{table}[htpb!]\caption{Season of Birth Descriptives (White, Married)}" 
                  _n "\begin{tabular}{lccccccccc} \toprule" _n
                  "& All & \multicolumn{2}{c}{Children} & "
                  "\multicolumn{2}{c}{Occupation}&\multicolumn{2}{c}{Some College +}"
                  "&\multicolumn{2}{c}{Target SOB}\\"
                  "\cmidrule(r){3-4}\cmidrule(r){5-6}\cmidrule(r){7-8}\cmidrule(r){9-10}" _n
                  "&&Yes&Plan&Teacher&Non-Teacher&Yes&No&Yes&No\\" _n
                  "\midrule ";
#delimit cr

#delimit ;
local conds All==1 childFlag==1 plankids==1|plankids==3 occ==6 occ!=6 educ>3
            educ<4 SOBtarget==1|pSOBtarget==1 SOBtarget==0|pSOBtarget==0;
#delimit cr

#delimit ;
local vnames `""Choose SOB" "Importance of SOB" "Lucky Dates" "Birthdays"
"Tax" "Work" "School Entry" "Child Health" "Mom's Health"  "Diabetes Avoidance"
"Choose SOB" "Difference (Diabetes $-$ SOB)" "';
#delimit cr

local j=1
local reasons SOBlucky SOBbirthday SOBtax SOBjobs SOBschool SOBchealth SOBmhealth
local variables  chooseSOB importSOB `reasons' WTPdiabetes WTPsob WTPdiff
tokenize `variables'

foreach v of local vnames {    
    local c=1
    foreach cond of local conds {
        sum `1' if `cond'
        local v`c'=round(r(mean)*1000)/1000
        if `v`c''<1&`v`c''>0 local v`c' "0`v`c''"
        local ++c
    }
    
    if `j'<3 {
        file write bstats "`v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9' \\" _n
    }
    else if `j'==3 {
        file write bstats "\multicolumn{10}{l}{\textbf{Reasons (Importance)}} \\" _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>3&`j'<10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'==10 {
        file write bstats "\multicolumn{10}{l}{\textbf{Willingness to Pay}} \\ " _n
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    else if `j'>10 {
        file write bstats "\ `v'&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n
    }
    macro shift
    local ++j
}

local c=1
foreach cond of local conds {
    count if `cond'
    local v`c'=r(N)
    local ++c
}
file write bstats "&&&&&&&&&\\" _n
file write bstats "Observations&`v1'&`v2'&`v3'&`v4'&`v5'&`v6'&`v7'&`v8'&`v9'\\" _n


#delimit ;
file write bstats "\bottomrule "_n;
file write bstats "\multicolumn{10}{p{21.4cm}}{{\footnotesize \textsc{Notes}:"
" Sample consists of all married, white, non-hispanic respondents who passed "
"all attention checks and answered consistently are included. Importance of  "
"season of birth and all reasons are ranked on a 1 to 10 scale, where 1 is   "
"not important at all and 10 is extremely important. Questions about children"
" and targeting are asked to all women who have children, and all women who  "
"do not have children below the age of 49.  These are 910 of the 1,025       "
"eligible respondents.}}" _n;
file write bstats "\end{tabular}\end{table}" _n;
#delimit cr
file close bstats
restore


exit
#delimit ;
local statform cells("count(label(N)) mean(fmt(2) label(Mean))
sd(fmt(2) label(Std.\ Dev.)) min(fmt(2) label(Min)) max(fmt(2) label(Max))");
#delimit cr

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
lab var SOBimpor "Importance of Conception Season"
lab var SOBtarge "Targeting Season of Conception"
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
exit
*/
********************************************************************************
*** (8) Basic regressions
********************************************************************************
use "$DAT/BirthSurvey", clear
keep if completed==1
keep if educ==educ_check
gen age = 2016-birthyr
gen ageSq = age^2
gen ageBirth = age-(2016-cbirthyr)
gen goodSeason = cbirthmonth>3&cbirthmonth<10 if cbirthmonth!=.
gen teacher = occ == 6
gen WTPdifference = WTPsob - WTPdiabetes
gen age2024 = age>=20&age<=24
gen age2527 = age>=25&age<=27
gen age2831 = age>=28&age<=31
gen age3239 = age>=32&age<=39

lab var age2024 "Aged 20-24"
lab var age2527 "Aged 25-27"
lab var age2831 "Aged 28-31"
lab var age3239 "Aged 32-39"


gen young = age<39
gen highEduc = educ>3
gen youngHighEd = young*highEduc
gen educ1 = educ<=3
gen educ2 = educ==4
gen educ3 = educ==5
gen educ4 = educ==6
gen educ5 = educ>=7
lab var educ1 "Highschool or less"
lab var educ2 "Some College"
lab var educ3 "Two Year Degree"
lab var educ4 "Four Year Degree"
lab var educ5 "Higher Degree"
lab var WTPsob "SOB"
lab var WTPdia "Avoid Diab"
lab var WTPdif "Difference"

gen parent = nchild!= 0
gen parentTeacher = parent*teacher

lab var parent        "Parent"
lab var parentTeacher "Parent $\times$ Teacher"
lab var teacher       "Teacher"
lab var age           "Age"
lab var ageSq         "Age Squared"
lab var highEduc      "Some College +"

local cnd if age>=25&age<=45&race==11&hispanic==0&marst==1
local con parent teacher parentTeacher age ageSq highEduc
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'

local cnd if age>=25&age<=45&race==11&hispanic==0&marst==1&sex==1
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/TeacherParentWTP.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`con' _cons)
mgroups("Both Genders" "Women Only",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Parents, Teachers and Willingness to Pay")
postfoot("\bottomrule\multicolumn{7}{p{15.8cm}}{\begin{footnotesize} All       "
         "willingness-to-pay (WTP) measures are represented as the proportion  "
         "of all financial resources to be paid as a one-off sum. The sample   "
         "consists of all married 25-45 year-old white non-hispanic respondents"
         "who answered the attention checks consistently."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


local cnd if age>=25&age<=45&race==11&hispanic==0
local con parent teacher parentTeacher age ageSq highEduc
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'

local cnd if age>=25&age<=45&race==11&hispanic==0&sex==1
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/TeacherParentWTPBoth.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`con' _cons)
mgroups("Both Genders" "Women Only",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Parents, Teachers and Willingness to Pay (Married and Unmarried)")
postfoot("\bottomrule\multicolumn{7}{p{15.8cm}}{\begin{footnotesize} All     "
         "willingness-to-pay (WTP) measures are represented as the proportion"
         "of all financial resources to be paid as a one-off sum. The sample "
         "consists of all married and unmarried 25-45 5 year-old white       "
         "non-hispanic respondents who answered the attention checks         "
         "consistently."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local cnd if age>=25&age<=45
local con parent teacher parentTeacher age ageSq highEduc
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'

local cnd if age>=25&age<=45&sex==1
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/TeacherParentWTPAll.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`con' _cons)
mgroups("Both Genders" "Women Only",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Parents, Teachers and Willingness to Pay (All Race Married and Unmarried)")
postfoot("\bottomrule\multicolumn{7}{p{15.8cm}}{\begin{footnotesize} All      "
         "willingness-to-pay (WTP) measures are represented as the proportion "
         "of all financial resources to be paid as a one-off sum. The sample  "
         "consists of all married and unmarried 25-45 5 year-old respondents  "
         "who answered the attention checks consistently."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
drop if occ==18|race!=11
local cnd if age>=25&age<=45&WTPcheck==2
local con parent teacher parentTeacher age ageSq highEduc
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'

local cnd if age>=25&age<=45&sex==1&WTPcheck==2
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'
#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/TeacherParentWTPSure.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`con' _cons)
mgroups("Both Genders" "Women Only",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Parents, Teachers and Willingness to Pay (Definitely Sure Only)")
postfoot("\bottomrule\multicolumn{7}{p{15.8cm}}{\begin{footnotesize} All      "
         "willingness-to-pay (WTP) measures are represented as the proportion "
         "of all financial resources to be paid as a one-off sum. The sample  "
         "consists of all married and unmarried white 25-45 year-old          "
         " respondents who have ever worked,   "
         "who answered the attention checks consistently and who stated that  "
         "they were ``definitely sure'' about their stated WTP values.        "
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear




preserve
keep if nchild!=0

lab var WTPsob "WTP"
lab var WTPdif "WTP"

local ages age2024 age2527 age2831 age3239
local educ educ2 educ3 educ4 educ5

eststo: reg WTPsob `ages'
eststo: reg WTPsob `educ'
eststo: reg WTPsob `ages' `educ'

eststo: reg WTPdif `ages'
eststo: reg WTPdif `educ'
eststo: reg WTPdif `ages' `educ'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/WTP_all.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk (All Parents)")
postfoot("\bottomrule\multicolumn{7}{p{16.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All MTurk respondents "
         "who answer consistently are included. The omitted education       "
         "category is highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


local cond if age>=20&age<=45
eststo: reg WTPsob `ages'        `cond'
eststo: reg WTPsob `educ'        `cond'
eststo: reg WTPsob `ages' `educ' `cond'

eststo: reg WTPdif `ages'        `cond'
eststo: reg WTPdif `educ'        `cond'
eststo: reg WTPdif `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/WTP_20-45.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk (20-45 Year-Old Parents)")
postfoot("\bottomrule\multicolumn{7}{p{16.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All MTurk respondents "
         "aged between 20-45 who answer consistently are included. The      "
         "omitted education category is highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local cond if age>=20&age<=45&race==11&hispanic==0
eststo: reg WTPsob `ages'        `cond'
eststo: reg WTPsob `educ'        `cond'
eststo: reg WTPsob `ages' `educ' `cond'

eststo: reg WTPdif `ages'        `cond'
eststo: reg WTPdif `educ'        `cond'
eststo: reg WTPdif `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/WTP_20-45white.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(`ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk (White non-Hispanic 20-45 Year Old Parents)")
postfoot("\bottomrule\multicolumn{7}{p{16.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All white,            "
         "non-Hispanic MTurk respondents aged between 20-45 who answer      "
         "consistently are included. The omitted education category is      "
         "highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local cond if age>=20&age<=45&race==11&sex==1
eststo: reg WTPsob `ages'        `cond'
eststo: reg WTPsob `educ'        `cond'
eststo: reg WTPsob `ages' `educ' `cond'

eststo: reg WTPdif `ages'        `cond'
eststo: reg WTPdif `educ'        `cond'
eststo: reg WTPdif `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/WTP_20-45whiteFemale.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(`ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk (White female 20-45 Year Old Parents)")
postfoot("\bottomrule\multicolumn{7}{p{16.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All white,            "
         "non-Hispanic female MTurk respondents aged between 20-45 who      "
         "answer consistently are included. The omitted education category  "
         "is highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local cond if age>=20&age<=45&race==11&WTPcheck==2
eststo: reg WTPsob `ages'        `cond'
eststo: reg WTPsob `educ'        `cond'
eststo: reg WTPsob `ages' `educ' `cond'

eststo: reg WTPdif `ages'        `cond'
eststo: reg WTPdif `educ'        `cond'
eststo: reg WTPdif `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/WTP_20-45whiteCheck.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(`ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk (White non-Hispanic 20-45 Year Olds: Sure)")
postfoot("\bottomrule\multicolumn{7}{p{16.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All white,            "
         "non-Hispanic MTurk respondents aged between 20-45 who answer      "
         "consistently are included. The omitted education category is      "
         "highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear



local cond if age>=20&age<=45&race==11
eststo: reg WTPsob teacher               `cond'
eststo: reg WTPsob teacher `ages'        `cond'
eststo: reg WTPsob teacher `educ'        `cond'
eststo: reg WTPsob teacher `ages' `educ' `cond'

eststo: reg WTPdif teacher               `cond'
eststo: reg WTPdif teacher `ages'        `cond'
eststo: reg WTPdif teacher `educ'        `cond'
eststo: reg WTPdif teacher `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 est8 using "$OUT/TeacherWTP_20-45.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(teacher `ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay and Teachers (20-45 Year Olds)")
postfoot("\bottomrule\multicolumn{9}{p{20.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All MTurk respondents "
         "aged between 20-45 who answer consistently are included. The      "
         "omitted education category is highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local cond if age>=20&age<=45&race==11&WTPcheck==2
eststo: reg WTPsob teacher               `cond'
eststo: reg WTPsob teacher `ages'        `cond'
eststo: reg WTPsob teacher `educ'        `cond'
eststo: reg WTPsob teacher `ages' `educ' `cond'

eststo: reg WTPdif teacher               `cond'
eststo: reg WTPdif teacher `ages'        `cond'
eststo: reg WTPdif teacher `educ'        `cond'
eststo: reg WTPdif teacher `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 est8 using "$OUT/TeacherWTP_20-45_Sure.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(teacher `ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay and Teachers (20-45 Year Old White Parents: Sure Only)")
postfoot("\bottomrule\multicolumn{9}{p{20.6cm}}{\begin{footnotesize} The    "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the        "
         "proportion of all financial resources as a one-off payment. WTP in"
         " columns 4-6 is the difference in WTP to perfectly time season of "
         "birth and to avoid diabetes, where a positive coefficient implies "
         "a greater relative WTP for season of birth. All MTurk respondents "
         "aged between 20-45 who answer consistently are included. The      "
         "omitted education category is highschool or lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


local cond if age>=20&age<=45&race==11&sex==1
eststo: reg WTPsob teacher               `cond'
eststo: reg WTPsob teacher `ages'        `cond'
eststo: reg WTPsob teacher `educ'        `cond'
eststo: reg WTPsob teacher `ages' `educ' `cond'

eststo: reg WTPdif teacher               `cond'
eststo: reg WTPdif teacher `ages'        `cond'
eststo: reg WTPdif teacher `educ'        `cond'
eststo: reg WTPdif teacher `ages' `educ' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 est8 using "$OUT/TeacherWTP_20-45WF.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(teacher `ages' `educ' _cons)
mgroups("Willingness to Pay (\%)" "Difference (SOB-Diabetes Avoid)",
        pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("Willingness to Pay MTurk and Teachers (20-45 Year-olds White Female)")
postfoot("\bottomrule\multicolumn{9}{p{20.6cm}}{\begin{footnotesize} The     "
         "willingness-to-pay (WTP) in columns 1-3 is measured as the         "
         "proportion of all financial resources as a one-off payment. WTP in "
         " columns 4-6 is the difference in WTP to perfectly time season of  "
         "birth and to avoid diabetes, where a positive coefficient implies  "
         "a greater relative WTP for season of birth. All white, non-Hispanic"
         "female MTurk respondents aged between 20-45 who answer consistently"
         "are included. The omitted education category is highschool or      "
         " lower."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear
restore


********************************************************************************
*** (9) Temperature graphs
********************************************************************************
gen wt=1
count
local SN = r(N)
gen old = age>=40 if age<=45


preserve
collapse WTPdifference WTPsob minTemp (sum) wt, by(stateString)
drop if stateString=="Alaska"
drop if stateString=="North Dakota"

foreach var of varlist WTPdifference WTPsob {
    local fname WTP
    local atitle "WTP Difference (SOB-Diabetes Avoidance)"
    if `"`var'"'=="WTPsob" local fname WTPsob
    if `"`var'"'=="WTPsob" local atitle "WTP (Choose Season of Birth)"
    corr `var' minTemp [aw=wt] 
    local ccoef = string(r(rho),"%5.3f")
    reg `var' minTemp [aw=wt]
    local pval   = (1-ttail(e(df_r),(_b[minTemp]/_se[minTemp])))
    local pvalue = string(`pval',"%5.3f")
    if `pvalue' == 0 local pvalue 0.000

    #delimit ;
    twoway scatter `var' minTemp, msymbol(i) mlabel(state) || 
           scatter `var' minTemp      [aw=wt], msymbol(Oh) || 
              lfit `var' minTemp [aw=wt], scheme(s1mono)
    legend(off) lpattern(dash) lcolor(gs0) ytitle(`atitle')
    xtitle("Minimum Temperature")
    note("Correlation coefficient (p-value) =`ccoef' (`pvalue'), N=`SN'");
    #delimit cr
    graph export "$OUT/TempCold_`fname'.eps", as(eps) replace
}
restore

#delimit ;
local cnd old==1 old==0 WTPcheck==2 WTPcheck==2&old==1
          WTPcheck==2&old==0 nchild!=0 nchild!=0&old==1
          nchild!=0&old==0;
local nam old young check oldcheck youngcheck parent oldparent youngparent;
#delimit cr

tokenize `nam'
foreach cond of local cnd {
    preserve
    keep if `cond'
    count
    local SN = r(N)
    collapse WTPdifference minTemp WTPsob (sum) wt, by(stateString)
    drop if stateString=="Alaska"
    drop if stateString=="North Dakota"

    foreach var of varlist WTPdifference WTPsob {
        local fname WTP
        local atitle "WTP Difference (SOB-Diabetes Avoidance)"
        if `"`var'"'=="WTPsob" local fname WTPsob
        if `"`var'"'=="WTPsob" local atitle "WTP (Choose Season of Birth)"
        corr `var' minTemp [aw=wt] 
        local ccoef = string(r(rho),"%5.3f")
        reg `var' minTemp [aw=wt]
        local pval   = (1-ttail(e(df_r),(_b[minTemp]/_se[minTemp])))
        local pvalue = string(`pval',"%5.3f")
        if `pvalue' == 0 local pvalue 0.000

        #delimit ;
        twoway scatter `var' minTemp, msymbol(i) mlabel(state) || 
               scatter `var' minTemp      [aw=wt], msymbol(Oh) || 
                  lfit `var' minTemp [aw=wt], scheme(s1mono)
        legend(off) lpattern(dash) lcolor(gs0) ytitle(`atitle')
        xtitle("Minimum Temperature")
        note("Correlation coefficient (p-value) =`ccoef' (`pvalue'), N=`SN'");
        #delimit cr
        graph export "$OUT/TempCold_`fname'`1'.eps", as(eps) replace
    }
    restore
    macro shift
}

exit



tab pSOBtarget
gen ppreferredGood = pSOBprefer==2|pSOBprefer==3 if pSOBprefer!=.
tab ppreferredGood


tab SOBtarget
gen preferredGoodS = SOBprefer==2|SOBprefer==3 if SOBprefer!=.
tab preferredGoodS
exit
count if SOBtarget == 0
local indif = r(N)
count if preferredGoodS==1
local pgood = r(N)
count if preferredGoodS==0
local pbad = r(N)
count if goodSeason == 1
local agood = r(N)
count if goodSeason == 0
local abad = r(N)
dis "Percent good season based on plan:" (`pgood'+`indif'/2)/(`pgood'+`pbad'+`indif')
dis "Percent good season in reality:" `agood'/(`agood'+`abad')

preserve
keep if teacher==1
count if SOBtarget == 0
local indif = r(N)
count if preferredGoodS==1
local pgood = r(N)
count if preferredGoodS==0
local pbad = r(N)
count if goodSeason == 1
local agood = r(N)
count if goodSeason == 0
local abad = r(N)
tab SOBtarget
tab preferredGoodS
dis "Percent good season based on plan:" (`pgood'+`indif'/2)/(`pgood'+`pbad'+`indif')
dis "Percent good season in reality:" `agood'/(`agood'+`abad')
tab goodSeason if preferredGoodS==1
tab goodSeason if preferredGoodS==0
restore

preserve
keep if teacher==0
count if SOBtarget == 0
local indif = r(N)
count if preferredGoodS==1
local pgood = r(N)
count if preferredGoodS==0
local pbad = r(N)
count if goodSeason == 1
local agood = r(N)
count if goodSeason == 0
local abad = r(N)
tab SOBtarget
tab preferredGoodS
dis "Percent good season based on plan:" (`pgood'+`indif'/2)/(`pgood'+`pbad'+`indif')
dis "Percent good season in reality:" `agood'/(`agood'+`abad')
tab goodSeason if preferredGoodS==1
tab goodSeason if preferredGoodS==0
restore

preserve
keep if educ>3
count if SOBtarget == 0
local indif = r(N)
count if preferredGoodS==1
local pgood = r(N)
count if preferredGoodS==0
local pbad = r(N)
count if goodSeason == 1
local agood = r(N)
count if goodSeason == 0
local abad = r(N)
tab SOBtarget
tab preferredGoodS
dis "Percent good season based on plan:" (`pgood'+`indif'/2)/(`pgood'+`pbad'+`indif')
dis "Percent good season in reality:" `agood'/(`agood'+`abad')
tab goodSeason if preferredGoodS==1
tab goodSeason if preferredGoodS==0
restore

preserve
keep if educ<4
count if SOBtarget == 0
local indif = r(N)
count if preferredGoodS==1
local pgood = r(N)
count if preferredGoodS==0
local pbad = r(N)
count if goodSeason == 1
local agood = r(N)
count if goodSeason == 0
local abad = r(N)
tab SOBtarget
tab preferredGoodS
dis "Percent good season based on plan:" (`pgood'+`indif'/2)/(`pgood'+`pbad'+`indif')
dis "Percent good season in reality:" `agood'/(`agood'+`abad')
tab goodSeason if preferredGoodS==1
tab goodSeason if preferredGoodS==0
restore

exit


gen prematurity = gestation<4 if gestation != .
gen goodPref    = SOBprefer==2|SOBprefer==3
gen goodAchieve = cbirthmonth>3&cbirthmonth<10
gen goodPlanAch = goodPref*goodAchieve
lab var goodPref    "Prefers Good Season"
lab var goodAchieve "Born Good Season"
lab var goodPlanAch "Achieved Good Season Preference"
lab var prematurity "Premature"

*local ctl sex i.educ

eststo: reg prematurity goodPref                          `ctl'
eststo: reg prematurity goodAchieve                       `ctl'
eststo: reg prematurity goodPref goodAchieve goodPlanAch  `ctl'

eststo: areg prematurity goodPref                         `ctl', abs(ageBirth)
eststo: areg prematurity goodAchieve                      `ctl', abs(ageBirth)
eststo: areg prematurity goodPref goodAchieve goodPlanAch `ctl', abs(ageBirth)

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/gestationSeason.tex", replace
keep(_cons goodPref goodAchieve goodPlanAch) style(tex) mlabels(, depvar)
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) ))
stats(N r2, fmt(%9.0g %5.3f) labels(Observations R-Squared))
starlevel("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
title("Gestation and Good Season Preferences")
postfoot("Age at Birth Controls&&&&Y&Y&Y\\ \bottomrule "
         "\multicolumn{7}{p{20.2cm}}{{\footnotesize Gestation is measured in "
         "months and premature is a binary variable referring to births      "
         "occurring at 8 months or less of gestation. "
         "Achieved good season preference refers to those individuals who    "
         "both stated a preference for and achieved a good season birth.     "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "}}\end{tabular}\end{table}");
#delimit cr
estimates clear

keep if race==11&hispanic==0
eststo: reg prematurity goodPref                          `ctl'
eststo: reg prematurity goodAchieve                       `ctl'
eststo: reg prematurity goodPref goodAchieve goodPlanAch  `ctl'

eststo: areg prematurity goodPref                         `ctl', abs(ageBirth)
eststo: areg prematurity goodAchieve                      `ctl', abs(ageBirth)
eststo: areg prematurity goodPref goodAchieve goodPlanAch `ctl', abs(ageBirth)

#delimit ;
esttab est1 est2 est3 est4 est5 est6 using "$OUT/gestationSeasonSamp.tex", replace
keep(_cons goodPref goodAchieve goodPlanAch) style(tex) mlabels(, depvar)
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) ))
stats(N r2, fmt(%9.0g %5.3f) labels(Observations R-Squared))
starlevel("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
title("Gestation and Good Season Preferences (White, non-hispanic)")
postfoot("Age at Birth Controls&&&&Y&Y&Y\\ \bottomrule "
         "\multicolumn{7}{p{20.2cm}}{{\footnotesize Gestation is measured in "
         "months and premature is a binary variable referring to births      "
         "occurring at 8 months or less of gestation. "
         "Achieved good season preference refers to those individuals who    "
         "both stated a preference for and achieved a good season birth.     "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01.              "
         "}}\end{tabular}\end{table}");
#delimit cr
estimates clear
