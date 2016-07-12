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
gen age      = 2016-birthyr
gen ageBirth = cbirthyr-birthyr

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
keep  if ageBirth>=25&ageBirth<=45&race==11&WTPcheck==2&occ!=18&marst==1&sex==1
keep if educ==educ_check

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
keep  if ageBirth>=25&ageBirth<=45&race==11&WTPcheck==2&occ!=18&marst==1&sex==1
keep if educ==educ_check
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

keep if cbirthmonth<=12
tab cbirthmonth, gen(_month)

gen birthProp = .
gen birthSE   = .
gen Month     = _n
foreach num of numlist 1(1)12 {
    sum _month`num'
    replace birthProp = r(mean) in `num'
    local se = r(sd)/sqrt(r(N))
    replace birthSE = `se'      in `num'
}
keep in 1/12
keep birthProp birthSE Month 
gen lower = birthProp-1.96*birthSE
gen upper = birthProp+1.96*birthSE


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

tab birthMonth, gen(_month)

gen birthPropNVSS = .
gen birthSENVSS   = .
gen Month         = _n
foreach num of numlist 1(1)12 {
    sum _month`num'
    replace birthPropNVSS = r(mean) in `num'
    local se = r(sd)/sqrt(r(N))
    replace birthSENVSS = `se'      in `num'
}
keep in 1/12
keep birthPropNVSS birthSENVSS Month 
gen lowerN = birthPropNVSS-1.96*birthSENVSS
gen upperN = birthPropNVSS+1.96*birthSENVSS


merge 1:1 Month using `bmonth'
local line1 lpattern(solid)    lcolor(black) lwidth(thick)
local line2 lpattern(dash)     lcolor(black) lwidth(medium)

#delimit ;
twoway line birthProp     Month, `line1'       ||
       rcap lower upper   Month,  lcolor(gs10) ||
       rcap lowerN upperN Month, lcolor(gs10)  ||
       line birthPropNVSS Month, `line2' scheme(s1mono) 
xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
       9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec", axis(1)) xtitle("Birth Month")
legend(order(1 "MTurk Survey Sample" 2 "95% CI" 4 "NVSS Birth Data"))
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
        local `val'=string(r(`val'), "%5.3f")
        *local `val'=round(r(`val')*1000)/1000
        *if ``val''<1&``val''>0 local `val' = "0``val''"
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
use "$ACS/ACS_20052014_cleaned_hisp", clear
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
use "$ACS/ACS_20052014_cleaned_hisp", clear

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
use "$ACS/ACS_20052014_cleaned_hisp", clear

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
use "$ACS/ACS_20052014_cleaned_hisp", clear

keep if motherAge>=25&motherAge<=45&twins==0&married==1
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
*rename hispan hispanic

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
local vnames `""Family Income" "Education (Years)" "Some College +" 
               "Currently Employed" "Hispanic" "';
#delimit cr
local variables ftotinc educY someCollege employed hispanic  
tokenize `variables'
file open mstats using "$OUT/ACScomp.txt", write replace
foreach var of local vnames {
    foreach stat in N mean stdev N_ACS meanACS stdevACS {
        qui sum `stat' if var=="`1'"
        local val`stat'=r(mean)
    }
    qui ttesti `valN' `valmean' `valstdev' `valN_ACS' `valmeanACS' `valstdevACS'
    foreach val in mu_1 sd_1 mu_2 sd_2 t {
        local `val'=string(r(`val'), "%5.3f")
        *local `val'=round(r(`val')*1000)/1000
        *if ``val''<1&``val''>0 local `val' = "0``val''"
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
gen age      = 2016-birthyr
gen ageBirth = cbirthyr-birthyr
keep  if ageBirth>=25&ageBirth<=45&race==11&WTPcheck==2&occ!=18&marst==1


cap gen importance= SOBimport
replace importance = pSOBimport if pSOBimport!=.

    
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


file open bstats using "$OUT/reasons.tex", write replace
#delimit ;
file write bstats "\begin{table}[htpb!]"
                  "\caption{MTurk: Reasons for Targeting Season of Birth}" 
                  _n "\begin{tabular}{lcccc} \toprule" _n
                  "& All     & Mothers & Teachers & Non       \\ " _n
                  "& Parents & Only    & Only     & Teachers  \\ "
                  "\midrule" _n;
#delimit cr
gen teacher = occ == 6
gen cond1=1
gen cond2=sex==1
gen cond3=teacher==1
gen cond4=teacher==0
#delimit ;

local vnames `""Lucky Birth Dates" "Tax Benefits" "Birthday Parties"
"Job Requirements" "School Entry Rules" "Child's Wellbeing" "Mom's Wellbeing" "';
#delimit cr
local rv SOBlucky SOBtax SOBbirthday SOBjobs SOBschool SOBmhealth SOBchealth
tokenize `rv'

foreach v of local vnames {
    foreach num of numlist 1(1)4 {
        sum `1' if cond`num'==1
        local c`num'=string(r(mean), "%5.3f")
    }
    file write bstats "`v'& `c1'& `c2'& `c3'& `c4'\\"_n
    macro shift
}
foreach num of numlist 1(1)4 {
    count if cond`num'==1&SOBlucky!=.
    local n`num'= r(N)
}
file write bstats "\midrule"_na
file write bstats "Observations& `n1'& `n2'& `n3'& `n4'\\"_n

#delimit ;
file write bstats "\bottomrule "_n;
file write bstats "\multicolumn{5}{p{10.8cm}}{{\footnotesize \textsc{Notes}:    "
" Main estimation sample from table S5 is used.  Reasons are given by these     "
"who state that they chose season of birth. The importance of each aspect is    "
"ranked between 1 (not important) to 10 (very important).}}"_n;
file write bstats "\end{tabular}\end{table}" _n;
#delimit cr
file close bstats


sum SOBbirth SOBluck SOBjob SOBsch SOBtax SOBche SOBmhe

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
gen age      = 2016-birthyr
gen ageBirth = cbirthyr-birthyr
gen choose= pSOBtarget==1|SOBtarget==1
gen notchoose = pSOBtarget==0|SOBtarget==0
gen summer = SOBprefer==2|SOBprefer==3|pSOBprefer==2|pSOBprefer==3 if choose==1
gen winter = SOBprefer==1|SOBprefer==4|pSOBprefer==1|pSOBprefer==4 if choose==1

********************************************************************************
*** (7a) WTP descriptive age
********************************************************************************
#delimit ;
local vnames `""Choose SOB" "Don't Choose SOB" "Choose Summer" "Choose Winter""';
local conds choose==1 notchoose==1 summer==1 winter==1;
#delimit cr

*Married Parents, white, 25-45 at birth
preserve
keep if nchild!=0&race==11&ageBirth>=25&ageBirth<=45&marst==1&WTPcheck==2
file open bstats using "$OUT/SOBDiabsum-tvals-parents2545bMarried.tex", write replace
#delimit ;
file write bstats "\begin{table}[htpb!]"
                  "\caption{MTurk: Willingess to Pay for Season of Birth by actual choice of SOB}" 
                  _n "\begin{tabular}{p{5cm}cccccc} \toprule" _n
                  "& Mean & Standard & $ t$         & Standard & Obs. & Equal \\ " _n
                  "&      & Deviation & Statistic  & Error    &       & Means ($ t$) \\ "
                  "\midrule" _n;
local vnames `""Choose SOB" "Don't Choose SOB" "Choose Summer" "Choose Winter""';
local conds choose==1 notchoose==1 summer==1 winter==1;
#delimit cr
file write bstats "\multicolumn{7}{l}{\textsc{Panel A: Both Genders}}\\"_n
file write bstats "\multicolumn{7}{l}{\textbf{Willingness to Pay (Preferred Season)}}\\"_n
tokenize `conds'
ttest WTPsob, by(notchoose)
local t1 = string(r(t), "%5.3f")
ttest WTPsob, by(summer)
local t2 = string(-1*r(t), "%5.3f")
local j = 1
foreach v of local vnames {
    sum WTPsob if `1'
    local mean = string(r(mean),"%5.3f")
    local stdd = string(r(sd),"%5.3f")
    local SN   = r(N)
    gen xvar = `1'
    reg WTPsob xvar if WTPcheck==2, nocons
    local tsta = string(_b[xvar]/_se[xvar],"%5.3f")
    local stde = string(_se[xvar],"%5.3f")
    if `j'==1 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t1'} \\" _n
    if `j'==2|`j'==4 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'& \\" _n
    if `j'==3 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t2'} \\" _n
    drop xvar
    macro shift
    local ++j
}

file write bstats "\multicolumn{7}{l}{\textbf{Willingness to Pay (Avoid Diabetes)}}\\"_n
tokenize `conds'
ttest WTPdiab, by(notchoose)
local t1 = string(r(t), "%5.3f")
ttest WTPdiab, by(summer)
local t2 = string(-1*r(t), "%5.3f")
local j=1
foreach v of local vnames {
    sum WTPdiab if `1'&WTPcheck==2
    local mean = string(r(mean),"%5.3f")
    local stdd = string(r(sd),"%5.3f")
    local SN   = r(N)
    gen xvar = `1'
    reg WTPdiab xvar if WTPcheck==2, nocons
    local tsta = string(_b[xvar]/_se[xvar],"%5.3f")
    local stde = string(_se[xvar],"%5.3f")
    if `j'==1 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t1'} \\" _n
    if `j'==2|`j'==4 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'& \\" _n
    if `j'==3 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t2'} \\" _n
    drop xvar
    macro shift
    local ++j
}
restore



*Married Mothers, white, 25-45 at birth
preserve
keep if nchild!=0&race==11&ageBirth>=25&ageBirth<=45&sex==1&marst==1&WTPcheck==2
#delimit ;
file write bstats "\midrule" _n;
local vnames `""Choose SOB" "Don't Choose SOB" "Choose Summer" "Choose Winter""';
local conds choose==1 notchoose==1 summer==1 winter==1;
#delimit cr
ttest WTPsob, by(notchoose)
local t1 = string(r(t), "%5.3f")
*ttest WTPsob, by(summer)
*local t2 = string(-1*r(t), "%5.3f")
file write bstats "\multicolumn{7}{l}{\textsc{Panel B: Women Only}}\\"_n
file write bstats "\multicolumn{7}{l}{\textbf{Willingness to Pay (Preferred Season)}}\\"_n
tokenize `conds'
local j = 1
foreach v of local vnames {
    sum WTPsob if `1'&WTPcheck==2
    local mean = string(r(mean),"%5.3f")
    local stdd = string(r(sd),"%5.3f")
    local SN   = r(N)
    gen xvar = `1'
    reg WTPsob xvar if WTPcheck==2, nocons
    local tsta = string(_b[xvar]/_se[xvar],"%5.3f")
    local stde = string(_se[xvar],"%5.3f")
    if `j'==1 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t1'} \\" _n
    if `j'==2|`j'==4 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'& \\" _n
    if `j'==3 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{.} \\" _n
    drop xvar
    macro shift
    local ++j
}
file write bstats "\multicolumn{7}{l}{\textbf{Willingness to Pay (Avoid Diabetes)}}\\"_n
tokenize `conds'
ttest WTPdiab, by(notchoose)
local t1 = string(r(t), "%5.3f")
*ttest WTPdiab, by(summer)
*local t2 = string(-1*r(t), "%5.3f")
local j=1
foreach v of local vnames {
    sum WTPdiab if `1'&WTPcheck==2
    local mean = string(r(mean),"%5.3f")
    local stdd = string(r(sd),"%5.3f")
    local SN   = r(N)
    gen xvar = `1'
    reg WTPdiab xvar if WTPcheck==2, nocons
    local tsta = string(_b[xvar]/_se[xvar],"%5.3f")
    local stde = string(_se[xvar],"%5.3f")
    if `j'==1 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{`t1'} \\" _n
    if `j'==2|`j'==4 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'& \\" _n
    if `j'==3 file write bstats "`v'&`mean'&`stdd'&`tsta'&`stde'&`SN'&\multirow{2}{*}{.} \\" _n
    drop xvar
    macro shift
    local ++j
}
#delimit ;
file write bstats "\bottomrule "_n;
file write bstats "\multicolumn{7}{p{16.2cm}}{{\footnotesize \textsc{Notes}:    "
"The sample consists of married white respondents who are parents and had their "
"first child when they were between 25 and 45 years old, and who      "
"answered that they were definitely sure about their willingness to   "
"pay assessment.  The small portion of respondents who incorrectly    "
"responded to consistency checks in the survey are removed from the   "
"sample.  Parents are asked: \emph{When deciding to become pregnant   "
"(you or your partner), what percentage of your financial resources   "
"(income, savings, etc.) would you be willing to pay as a one-off     "
"payment to have your baby born in your preferred season [avoid your  "
"child being born with diabetes]?} and are prompted to enter a value  "
"between 0 and 100. Equal Means refers to the value of a $ t$-test    "
"between the mean for choosing and not choosing season of birth, and  "
"between choosing summer and choosing winter (where defined).}} " _n;
file write bstats "\end{tabular}\end{table}" _n;
#delimit cr
file close bstats
restore

preserve    
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
gen plankids1 = plankids==1 if plankids!=.
gen plankids2 = plankids==2 if plankids!=.
gen plankids3 = plankids==3 if plankids!=.
gen morekids1 = morekids==1 if morekids!=.
gen morekids2 = morekids==2 if morekids!=.
gen morekids3 = morekids==3 if morekids!=.
gen pregnant1 = pregnant==1 if pregnant!=.


lab var sex      "Female"
lab var birthyr  "Year of Birth"
lab var age      "Age"
lab var educY    "Years of Education"
lab var nchild   "Number of Children"
lab var pregnant1 "Currently Pregnant"
lab var plankids1 "Plans to have children (Yes)"
lab var morekids1 "Plans for more children (Yes)"
lab var plankids2 "Plans to have children (No)"
lab var morekids2 "Plans for more children (No)"
lab var plankids3 "Plans to have children (Don't Know)"
lab var morekids3 "Plans for more children (Don't Know)"
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
lab var WTPsob   "WTP (Season of Birth)"
lab var WTPdiab  "WTP (Avoid Diabetes)"
lab var unemploy "Unemployed"

#delimit ;
estpost sum sex age birthyr educY nchild plankids1-plankids3 morekids1-morekids3
pregnant1 married sexchild gestation fertmed SOBimport SOBtarget 
white black otherRace hispanic employed unemployed cbirthyr WTPsob WTPdiab;
#delimit cr
estout using "$OUT/MTurkSum.tex", replace label style(tex) `statform'
restore
preserve
keep  if ageBirth>=25&ageBirth<=45&race==11&WTPcheck==2&occ!=18&marst==1
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
gen morekids1 = morekids==1 if morekids!=.
gen morekids2 = morekids==2 if morekids!=.
gen morekids3 = morekids==3 if morekids!=.
gen pregnant1 = pregnant==1 if pregnant!=.

lab var sex      "Female"
lab var birthyr  "Year of Birth"
lab var ageBirth "Age at Birth"
lab var educY    "Years of Education"
lab var nchild   "Number of Children"
lab var plankids "Plans to have children"
lab var morekids "Plans for more children"
lab var pregnant1 "Currently Pregnant"
lab var morekids1 "Plans for more children (Yes)"
lab var morekids2 "Plans for more children (No)"
lab var morekids3 "Plans for more children (Don't Know)"
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
lab var unemploy "Unemployed" 
lab var cbirthyr "Child's Year of Birth"
lab var WTPsob   "WTP (Season of Birth)"
lab var WTPdiab  "WTP (Avoid Diabetes)"

#delimit ;
estpost sum sex ageBirth birthyr educY nchild morekids1-morekids3
pregnant1 sexchild gestation fertmed SOBimport SOBtarget 
hispanic employed unemployed cbirthyr WTPsob WTPdiab;
#delimit cr
estout using "$OUT/MTurkSum_Main.tex", replace label style(tex) `statform'

restore
*/
********************************************************************************
*** (8) Basic regressions
********************************************************************************
use "$DAT/BirthSurvey", clear
local bage 1
local nomh 0

keep if completed==1
keep if educ==educ_check

if `bage'==0 {
    gen age = 2016-birthyr
    gen ageSq = age^2/100
    local f
    local a Age is measured at the time of survey
}
if `bage'==1 {
    gen age = cbirthyr-birthyr
    replace age = 2016-birthyr if nchild==0
    gen ageSq = age^2/100
    local f birthAge
    local a Age refers to the age of the respondent when having their first birth
}
if `nomh'==1 {
    local f nomh
}
if `bage'==1&`nomh'==1 {
    local f birthAge/nomh
}



gen goodSeason = cbirthmonth>3&cbirthmonth<10 if cbirthmonth!=.
gen teacher = occ == 6
gen WTPdifference = WTPsob - WTPdiabetes
gen age2024 = age>=20&age<=24
gen age2527 = age>=25&age<=27
gen age2831 = age>=28&age<=31
gen age3239 = age>=32&age<=39
gen noART   = fertmed== 0 if fertmed!=.
gen married = marst==1

lab var age2024 "Aged 20-24"
lab var age2527 "Aged 25-27"
lab var age2831 "Aged 28-31"
lab var age3239 "Aged 32-39"
lab var noART   "No ART"
lab var hispani "Hispanic"
lab var married "Married"

gen young = age<39
gen highEduc = educ>3
gen youngHighEd = young*highEduc
gen educ1 = educ<=3
gen educ2 = educ==4
gen educ3 = educ==5
gen educ4 = educ==6
gen educ5 = educ>=7
gen income = 5000 if ftotinc==11
replace income = 15000 if ftotinc==12
replace income = 25000 if ftotinc==13
replace income = 35000 if ftotinc==14
replace income = 45000 if ftotinc==15
replace income = 55000 if ftotinc==16
replace income = 65000 if ftotinc==17
replace income = 75000 if ftotinc==18
replace income = 85000 if ftotinc==19
replace income = 95000 if ftotinc==20
replace income = 125000 if ftotinc==21
replace income = 150000 if ftotinc==22
gen logInc = log(income)

lab var logInc "log(HH Inc)"
lab var educ1 "Highschool or less"
lab var educ2 "Some College"
lab var educ3 "Two Year Degree"
lab var educ4 "Four Year Degree"
lab var educ5 "Higher Degree"
lab var WTPsob "WTP"
lab var WTPdia "Avoid Diab"
lab var WTPdif "Difference"

gen parent = nchild!= 0
gen parentTeacher = parent*teacher

lab var parent        "Parent"
lab var parentTeacher "Parent $\times$ Teacher"
lab var teacher       "Teacher"
lab var age           "Age"
lab var ageSq         "Age Squared/100"
lab var highEduc      "Some College +"



drop if occ==18|race!=11

*XXX: S18
local cnd if age>=25&age<=45&WTPcheck==2&marst==1
local con parent teacher parentTeacher age ageSq highEduc hispanic
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'

local cnd if age>=25&age<=45&sex==1&WTPcheck==2&marst==1
eststo: reg WTPsob        `con' `cnd'
eststo: reg WTPdiabetes   `con' `cnd'
eststo: reg WTPdifference `con' `cnd'
#delimit ;
esttab est1 est4  using "$OUT/`f'/TeacherParentWTPSure_conMarried.tex", replace
`estopt' booktabs mlabels(, depvar)
keep(`con')
mgroups("Both Genders" "Women Only",
        pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("MTurk: Willingness to Pay for SOB -- Parents and Teachers")
postfoot("\bottomrule\multicolumn{3}{p{8.4cm}}{\begin{footnotesize} The main estimation "
         " sample is used, augmented with non-parents aged 25-45."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear



preserve
keep if nchild!=0

lab var WTPsob "WTP"
lab var WTPdif "WTP"

local ages age ageSq
local educ highEduc
local ctls married hispanic
if `nomh'==1 local ctls hispanic


*XXX: S19
local cond if age>=25&age<=45&race==11&WTPcheck==2&occ!=18&marst==1
eststo: reg WTPsob teacher               `cond'
eststo: reg WTPsob teacher `ages'        `cond'
eststo: reg WTPsob teacher `educ'        `cond'
eststo: reg WTPsob teacher `ages' `educ' `ctlsM' `cond'

local cond if age>=25&age<=45&race==11&sex==1&WTPcheck==2&occ!=18&marst==1
eststo: reg WTPsob teacher               `cond'
eststo: reg WTPsob teacher `ages'        `cond'
eststo: reg WTPsob teacher `educ'        `cond'
eststo: reg WTPsob teacher `ages' `educ' `ctlsM' `cond'

#delimit ;
esttab est1 est2 est3 est4 est5 est6 est7 est8 using "$OUT/`f'/TeacherWTP_20-45_SureMarried.tex",
replace `estopt' booktabs mlabels(, depvar)
keep(teacher `ages' `educ' `ctlsM')
mgroups("Both Genders" "Women Only",
        pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span
        erepeat(\cmidrule(lr){@span}))
title("MTurk: Willingess to Pay for Season of Birth and Teachers")
postfoot("\bottomrule\multicolumn{9}{p{19.2cm}}{\begin{footnotesize} The main  "
         " estimation sample is used.  The omitted education category is       "
         "highschool or lower. "
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


restore


exit

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
