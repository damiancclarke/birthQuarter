/* conjointAnalysisMain.do v0.00 damiancclarke             yyyy-mm-dd:2016-09-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

The script below is split into two parts.  The first is for the birthweight grou
p and the second is for the day of birth group.  The two parts are denoted using
B (birthweight) and D (day of birth)
*/

vers 11
clear all
set more off
cap log close



*-------------------------------------------------------------------------------
*--- (0) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint-main"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/conjoint-main"
global NVS "~/investigacion/2015/birthQuarter/data/nvss"
global ACS "~/investigacion/2015/birthQuarter/data/raw"
global GEO "~/investigacion/2015/birthQuarter/data/maps/states_simplified"

#delimit ;
local snames `" "Alabama" "Alaska" "Arizona" "Arkansas" "California"
"Colorado" "Connecticut" "Delaware" "District of Columbia" "Florida" "Georgia"
"Idaho" "Illinois" "Indiana" "Iowa" "Kansas" "Kentucky" "Louisiana" "Maine"
"Maryland" "Massachusetts" "Michigan" "Minnesota" "Mississippi" "Missouri"
"Montana" "Nebraska" "Nevada" "New Hampshire" "New Jersey" "New Mexico"
"New York" "North Carolina" "North Dakota" "Ohio" "Oklahoma" "Oregon"
"Pennsylvania" "Rhode Island" "South Carolina" "South Dakota" "Tennessee"
"Texas" "Utah" "Virginia" "Washington" "West Virginia" "Wisconsin" "Hawaii"
"Vermont" "Wyoming" "';
local sprop 151 23 212 93 1218 170 112 29 21 631 318 51 400 206 97 91 138 145
41 187 211 309 171 93 189 32 59 90 41 279 65 616 312 24 361 122 125 398 33 152
27 205 855 93 261 223 57 180 45 19 18;
#delimit cr

log using "$LOG/conjointAnalysisMain.txt", text replace
/*
*-------------------------------------------------------------------------------
*--- (1) Summary Statistics
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup"
append using "$DAT/conjointDOBgroup"
bys ID: gen N=_n
keep if N==1
drop N
keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2
gen parent     = RespNumKids !="0"
gen planning   = RespPlansKids=="Yes"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
*replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen certainty     = "1"  if RespSure=="1 (not sure at all)"
replace certainty = "10" if RespSure=="10 (definitely sure)"
replace certainty = RespSure if certainty==""
destring certainty, replace
save "$DAT/combined", replace
gen sex = RespSex=="Female"
gen birthyr = RespYOB
gen educY     = 8 if RespEduc=="Eighth Grade or Less"
replace educY = 10 if RespEduc=="Eighth Grade or Less"
replace educY = 12 if RespEduc=="High School Degree/GED"
replace educY = 13 if RespEduc=="Some College"
replace educY = 14 if RespEduc=="2-year College Degree"
replace educY = 16 if RespEduc=="4-year College Degree"
replace educY = 17 if RespEduc=="Master's Degree"
replace educY = 17 if RespEduc=="Doctoral Degree"
replace educY = 17 if RespEduc=="Professional Degree (JD,MD,MBA)"
gen pregnant1 = RespPregnant=="Yes"
gen black     = RespRace=="Black or African American"
gen otherRace = white==0&black==0
gen hispanic  = RespHisp=="Yes"
gen employed  = RespEmploymen=="Employed"
gen unemployed= RespEmploymen=="Unemployed"
gen highEduc  = educY>=13
gen nchild    = RespNumKids if RespNumKids!="6 or more"
destring nchild, replace
replace nchild=6 if nchild==.
generat ftotinc = 5000   if RespSalary=="Less than $10,000"
replace ftotinc = 15000  if RespSalary=="$10,000 - $19,999"
replace ftotinc = 25000  if RespSalary=="$20,000 - $29,999"
replace ftotinc = 35000  if RespSalary=="$30,000 - $39,999"
replace ftotinc = 45000  if RespSalary=="$40,000 - $49,999"
replace ftotinc = 55000  if RespSalary=="$50,000 - $59,999"
replace ftotinc = 65000  if RespSalary=="$60,000 - $69,999"
replace ftotinc = 75000  if RespSalary=="$70,000 - $79,999"
replace ftotinc = 85000  if RespSalary=="$80,000 - $89,999"
replace ftotinc = 95000  if RespSalary=="$90,000 - $99,999"
replace ftotinc = 125000 if RespSalary=="$100,000 - $149,999"
replace ftotinc = 175000 if RespSalary=="$150,000 or more"
replace ftotinc = ftotinc/1000
gen mturkSal = 1.5 if RespMTurkSalary=="Less than $2"
replace mturkSal = 2.5 if RespMTurkSalary=="$2-$2.99"
replace mturkSal = 3.5 if RespMTurkSalary=="$3-$3.99"
replace mturkSal = 4.5 if RespMTurkSalary=="$4-$4.99"
replace mturkSal = 5.5 if RespMTurkSalary=="$5-$5.99"
replace mturkSal = 6.5 if RespMTurkSalary=="$6-$6.99"
replace mturkSal = 7.5 if RespMTurkSalary=="$7-$7.99"
replace mturkSal = 8.5 if RespMTurkSalary=="$8-$8.99"
replace mturkSal = 9.5 if RespMTurkSalary=="$9-$9.99"
replace mturkSal = 10.5 if RespMTurkSalary=="$10-$10.99"
replace mturkSal = 11.5 if RespMTurkSalary=="$11 or more"
lab var sex       "Female"
lab var birthyr   "Year of Birth"
lab var age       "Age"
lab var educY     "Years of Education"
lab var nchild    "Number of Children"
lab var pregnant1 "Currently Pregnant"
lab var married   "Married"
lab var hispanic  "Hispanic"
lab var black     "Black"
lab var white     "White"
lab var otherRac  "Other Race"
lab var employed  "Employed"
lab var unemploy  "Unemployed"
lab var highEduc  "Some College +"
lab var parent    "Parent"
lab var teacher   "Education, Training, and Library occupation"
lab var ftotinc   "Total Family Income (1000s)"
lab var mturkSal  "Hourly earnings on MTurk"
#delimit ;
local statform cells("count(label(N)) mean(fmt(2) label(Mean))
sd(fmt(2) label(Std.\ Dev.)) min(fmt(2) label(Min)) max(fmt(2) label(Max))");
estpost sum sex age hispanic black white hispanic married highEduc educY
employed ftotinc teacher parent nchild mturkSal;
#delimit cr
estout using "$OUT/MTurkSum.tex", replace label style(tex) `statform'
preserve
gen N = 1
collapse (sum) N, by(educY)
rename educY educ
egen tot = sum(N)
gen propeducKid = N/tot
tempfile educKid
save `educKid'
use "$ACS/ACS_20052014_cleaned_hisp", clear
keep if motherAge>=25&motherAge<=45&twins==0
keep if marst==1
drop if occ2010 == 9920
bys twoLevelOcc: gen counter = _N
keep if counter>500
drop counter
drop educ
generate educ = 8 if educd <= 26
replace  educ = 10 if educd>26&educd<=61
replace  educ = 12 if educd>61&educd<=64
replace  educ = 13 if educd>64&educd<=71
replace  educ = 14 if educd==81
replace  educ = 16 if educd==101
replace  educ = 17 if educd==114
replace  educ = 18 if educd==116
replace  educ = 20 if educd==115
gen N = 1
collapse (sum) N, by(educ)
egen tot = sum(N)
gen propeducACS = N/tot
merge 1:1 educ using `educKid'
replace educ=1 if educ==8
replace educ=2 if educ==10
replace educ=3 if educ==12
replace educ=4 if educ==13
replace educ=5 if educ==14
replace educ=6 if educ==16
replace educ=7 if educ==17
replace educ=8 if educ==18
replace educ=9 if educ==20
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
*-------------------------------------------------------------------------------
*--- (1b) Comparison with NVSS
*-------------------------------------------------------------------------------
preserve
gen ageBirth=age
gen race=11 if white==1
gen marst=married
gen cbirthmonth     = 1  if RespKidBMonth=="January"
replace cbirthmonth = 2  if RespKidBMonth=="February"
replace cbirthmonth = 3  if RespKidBMonth=="March"
replace cbirthmonth = 4  if RespKidBMonth=="April"
replace cbirthmonth = 5  if RespKidBMonth=="May"
replace cbirthmonth = 6  if RespKidBMonth=="June"
replace cbirthmonth = 7  if RespKidBMonth=="July"
replace cbirthmonth = 8  if RespKidBMonth=="August"
replace cbirthmonth = 9  if RespKidBMonth=="September"
replace cbirthmonth = 10 if RespKidBMonth=="October"
replace cbirthmonth = 11 if RespKidBMonth=="November"
replace cbirthmonth = 12 if RespKidBMonth=="December"
keep  if ageBirth>=25&ageBirth<=45&sex==1
keep if nchild!=0
gen N = 1
gen Q1 = cbirthmonth >= 1 & cbirthmonth <=3
gen Q2 = cbirthmonth >= 4 & cbirthmonth <=6
gen Q3 = cbirthmonth >= 7 & cbirthmonth <=9
gen Q4 = cbirthmonth >=10 & cbirthmonth <=12
gen     sexchild = 1 if RespKidGender=="Girl"
replace sexchild = 0 if RespKidGender=="Boy"
collapse (sum) N (mean) nchild sexchild Q1 Q2 Q3 Q4 ageBirth hispanic      /*
*/ black white highEduc married (sd) sd_nchild=nchild sd_sexchild=sexchild /*
*/ sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4 sd_ageBirth=ageBirth                /*
*/ sd_black=black sd_hispanic=hispanic sd_white=white sd_highEduc=highEduc /*
*/ sd_married=married
expand 12
gen mean  = .
gen stdev = .
gen var   = ""
local i = 1
foreach var of varlist nchild sexchild Q1 Q2 Q3 Q4 ageBirth /*
*/ hispanic black white highEduc married {
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
use "$NVS/natl2013", clear
*keep if mbrace==1&mar==1
gen N_NV = 1
gen nchild = lbo_rec
replace nchild = 6 if nchild>6&nchild<20
replace nchild = . if nchild>=20
gen sexchild = sex=="F"
gen Q1 = dob_mm >= 1 & dob_mm <=3
gen Q2 = dob_mm >= 4 & dob_mm <=6
gen Q3 = dob_mm >= 7 & dob_mm <=9
gen Q4 = dob_mm >=10 & dob_mm <=12
gen ageBirth = mager
gen highEduc = meduc>=4 if meduc!=9&meduc!=.
gen hispanic = umhisp!=0
gen black    = mracerec==2
gen white    = mracerec==1
gen married  = mar==1
collapse (sum) N (mean) nchild sexchild Q1 Q2 Q3 Q4 ageBirth highEduc      /*
*/ hispanic black white married (sd) sd_nchild=nchild sd_sexchild=sexchild /*
*/ sd_Q1=Q1 sd_Q2=Q2 sd_Q3=Q3 sd_Q4=Q4 sd_ageBirth=ageBirth                /*
*/ sd_hispanic=hispanic sd_black=black sd_white=white sd_highEduc=highEduc /*
*/ sd_married=married
expand 12
gen meanNV  = .
gen stdevNV = .
gen var   = ""
local i = 1
foreach var of varlist nchild sexchild Q1 Q2 Q3 Q4 ageBirth /*
*/ hispanic black white highEduc married {
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
local vnames `""Number of Children" "Age at First Birth" "Female Child"
               "Some College +" "Born January-March" "Born April-June"
               "Born July-September" "Born October-December"
               "Black" "White" "Hispanic" "Married" "';
#delimit cr
local variables nchild ageBirth sexchild highEduc /*
*/ Q1 Q2 Q3 Q4 black white hispanic married
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
    local dif = string((`mu_1'-`mu_2'),"%5.3f")
    *if `dif'<1&`dif'>0 local dif = "0`dif'"
    file write bstats "`var'&`mu_1'&(`sd_1')&`mu_2'&(`sd_2')&`dif'&`t'\\ " _n
    macro shift
}
file close bstats
restore
gen statename=RespState
count
bys statename: gen stateProportion = _N/r(N)
preserve
collapse stateProportion, by(statename)
rename statename NAME
merge 1:1 NAME using "$GEO/US_db"
format stateProportion %5.2f
#delimit ;
spmap stateProportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord_mercator",
point(data($DAT/combined) xcoord(long3) ycoord(lat3)
      select(drop if (latitude<24.39|latitude>49.38)|(longitude<-124.84|longitude>-66.9))
      size(*0.5) fcolor(red))
id(_ID) osize(thin) legtitle("Proportion of Respondents") legstyle(2) fcolor(Greens)
legend(symy(*1.2) symx(*1.2) size(*1.4) rowgap(1));
graph export "$OUT/surveyCoverage.eps", as(eps) replace;
#delimit cr
restore
preserve
insheet using "$GEO/../population2015.csv", delim(";") names clear
replace state=subinstr(state,".","",1)
rename state NAME
merge 1:1 NAME using "$GEO/US_db"
format proportion %5.2f
#delimit ;
spmap proportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord_mercator", id(_ID) osize(thin)
legtitle("Proportion of Respondents (Census)") legstyle(2) fcolor(Greens)
legend(symy(*1.2) symx(*1.2) size(*1.4) rowgap(1));
graph export "$OUT/usaCoverage.eps", as(eps) replace;
#delimit cr
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
use "$NVS/natl2013", clear
gen N = 1
replace lbo_rec=6 if lbo_rec>=6
collapse (sum) N, by(lbo_rec)
egen totbirth = sum(N)
replace N = N/totbirth
rename N birthPropNVS
rename lbo_rec nchild
merge 1:1 nchild using `nchild'
graph bar birthPropNVS birthProp, over(nchild)                          /*
*/ legend(lab(1 "NVSS") lab(2 "MTurk Sample")) scheme(s1mono)           /*
*/ bar(1, color(blue*0.6)) bar(2, color(red*0.4)) ytitle("Proportion")
graph export "$OUT/nchild.eps", as(eps) replace
restore
preserve
gen N = 1
gen cbirthmonth = 1 if RespKidBMonth=="January"
replace cbirthmonth = 2 if RespKidBMonth=="February"
replace cbirthmonth = 3 if RespKidBMonth=="March"
replace cbirthmonth = 4 if RespKidBMonth=="April"
replace cbirthmonth = 5 if RespKidBMonth=="May"
replace cbirthmonth = 6 if RespKidBMonth=="June"
replace cbirthmonth = 7 if RespKidBMonth=="July"
replace cbirthmonth = 8 if RespKidBMonth=="August"
replace cbirthmonth = 9 if RespKidBMonth=="September"
replace cbirthmonth = 10 if RespKidBMonth=="October"
replace cbirthmonth = 11 if RespKidBMonth=="November"
replace cbirthmonth = 12 if RespKidBMonth=="December"
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
restore
*-------------------------------------------------------------------------------
*--- (1c) Comparison with ACS
*-------------------------------------------------------------------------------
preserve
gen N = 1
keep if RespSex=="Female" &age>=20&age<=45
gen someCollege = educY>=13
collapse (sum) N (mean) ftotinc highEduc someCollege married employed hispanic  /*
 */ black white otherRace age educY teacher (sd) sd_ftotinc=ftotinc              /*
 */ sd_highEduc=highEduc sd_someCollege=someCollege sd_married=married           /*
 */ sd_employed=employed sd_hispanic=hispanic sd_black=black sd_white=white      /*
 */ sd_otherRace=otherRace sd_age=age sd_educY=educY sd_teacher=teacher
expand 12
gen mean  = .
gen stdev = .
gen var   = ""
local i = 1
foreach var of varlist ftotinc highEduc someCollege married employed hispanic /*
*/ black white otherRace age educY teacher {
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

preserve
use "$ACS/ACS_20052014_All", clear
keep if motherAge>=20&motherAge<=45
*keep if year==2014
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
gen teacher = twoLevelOcc=="Education, Training, and Library Occupations"
gen hispanic=hispan!=0
gen age=motherAge
gen white = race==1
gen black = race==2
gen someCollege = educ>=7
gen otherRace = race!=1&race!=2
gen employed  = empstat==1
*rename hispan hispanic
collapse (sum) N_ACS (mean) ftotinc highEduc someCollege married employed hispanic /*
*/ black white otherRace age educY teacher (sd) sd_ftotinc=ftotinc                 /*
*/ sd_highEduc=highEduc  sd_someCollege=someCollege sd_married=married             /*
*/ sd_employed=employed sd_hispanic=hispanic sd_black=black sd_white=white         /*
*/ sd_otherRace=otherRace sd_age=age sd_educY=educY sd_teacher=teacher
expand 12
gen meanACS  = .
gen stdevACS = .
gen var      = ""
local i = 1
foreach var of varlist ftotinc highEduc married employed hispanic /*
*/ black white otherRace age educY teacher {
    replace mean  = `var' in `i'
    replace stdev = sd_`var' in `i'
    replace var = "`var'" in `i'
    local ++i
}
keep meanACS stdevACS var N_ACS
tempfile ACSSum
save `ACSSum'
merge 1:1 var using `MTurkSum2'
keep if _merge==3
local i = 1
#delimit ;
local vnames `" "Family Income (1000s)" "Age" "Some College +"
                "Employed" "Education, Training, Library Occ." "Black" "White"
                "Hispanic" "Married"  "';
#delimit cr
local variables ftotinc age highEduc employed teacher black white hispanic married
tokenize `variables'
file open mstats using "$OUT/ACScomp.txt", write replace
foreach var of local vnames {
    dis "`var'"
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
restore
*/

*-------------------------------------------------------------------------------
*--- (A2) Generate [For Full Group]
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup", clear
append using "$DAT/conjointDOBgroup"
keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2
gen parent     = RespNumKids !="0"
gen planning   = RespPlansKids=="Yes"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen someCollege = RespEduc!="Eighth Grade or Less"&/*
        */ RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen hispanic = RespHisp=="Yes"
gen certainty     = "1"  if RespSure=="1 (not sure at all)"
replace certainty = "10" if RespSure=="10 (definitely sure)"
replace certainty = RespSure if certainty==""
destring certainty, replace

*DOB and BWT replace missings as separate indicator

replace dob        ="missing" if dob        ==""
replace birthweight="missing" if birthweight==""
replace birthweight_p=5 if birthweight_p==.
replace dob_position =5 if dob_position ==.

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)
tab dob        , gen(_dob)

drop _gend1 _cost5 _bwt2 _sob4 _dob1
rename _cost1 _costx
rename _cost4 _cost1
rename _cost3 _cost4
rename _costx _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _bwt1 _bwt2
rename _bwt4 _bwtx
rename _bwt5 _bwt4
rename _bwt3 _bwt5
rename _bwtx _bwt3
rename _bwt6 _bwtx
rename _bwt7 _bwt6
rename _bwt8 _bwt7
rename _bwtx _bwt8
rename _bwt9 _bwtx
rename _bwt10 _bwt9
rename _bwt11 _bwt10
rename _bwtx _bwt11
rename _sob1 _sob4
gen goodSeason=_sob2==1|_sob3==1
gen     costNumerical = subinstr(cost,"$","",1)
replace costNumerical = subinstr(costNumerical,",","",1)
destring costNumerical, replace
replace costNumerical = costNumerical/1000
gen spring = _sob2
gen summer = _sob3
gen all = 1
gen TPG = teacher*parent*goodSeason
gen TP = teacher*parent
gen TG = teacher*goodSeason
gen PG = parent*goodSeason
lab var age "Age"
lab var age2 "Age Squared"
lab var someCollege "Some College +"
lab var hispanic "Hispanic"
lab var teacher "Teacher"
lab var parent  "Parent"
lab var TPG "Teacher $\times$ Parent $\times$ Good Season"
lab var TP "Teacher $\times$ Parent"
lab var TG "Teacher $\times$ Good Season"
lab var PG "Parent $\times$ Good Season"
lab var _bwt2  "5lbs, 13oz"
lab var _bwt3  "6lbs, 3oz"
lab var _bwt4  "6lbs, 8oz"
lab var _bwt5  "6lbs, 13oz"
lab var _bwt6  "7lbs, 3oz"
lab var _bwt7  "7lbs, 8oz"
lab var _bwt8  "7lbs, 13oz"
lab var _bwt9  "8lbs, 3oz"
lab var _bwt10 "8lbs, 8oz"
lab var _bwt11 "8lbs, 13oz"
lab var _dob2  "Weekend Day"
lab var _gend2 "Girl"

local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n
tab RespTargetMonth if `base'&(parent==1|planning==1)&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&N==1

tab RespTargetMonth if `base'&(parent==1|planning==1)&teacher==1&N==1
tab RespTargetWhich if `base'&(parent==1|planning==1)&teacher==1&N==1

bys RespState: gen statePop = _N
count
gen surveyProportion = statePop/r(N)
gen censusProportion = .
        tokenize `sprop'
local total = 0
foreach state of local snames {
    dis "State: `state', pop: `1'"
    qui replace censusProportion = `1' if RespState=="`state'"
    local total = `total'+`1'
    macro shift
}
dis `total'
replace censusProportion = censusProportion/10000
gen weight = surveyProportion/censusProportion
replace weight=1/weight

gen osample = white==1&RespSex=="Female"&married==1&parent==1&age>=20&age<=45

/*
*-------------------------------------------------------------------------------
*-- (A3) Main analysis
*-------------------------------------------------------------------------------
reg chosen `oFEs' _sob* _cost* _gend* _bwt* _dob*, cluster(ID)

#delimit ;
local conds all==1;
local names All;
#delimit cr
tokenize `names'
lab def names -1 "Season of Birth" -2 "Winter" -3 "Spring" -4 "Summer"      /*
*/ -5 "Fall" -6 " " -7 "Cost" -8 "250" -9 "750" -10 "1000" -11 "2000"       /*
*/ -12 "3000" -13 "4000" -14 "5000" -15 "6000" -16 "7500" -17 "10000"       /*
*/ -18 " " -19 "Gender" -20 "Boy" -21 "Girl" -22 " " -23 "Birth Weight"     /*
*/ -24 "5lbs, 8oz" -25 "5lbs, 13oz" -26 "6lbs, 3oz" -27 "6lbs, 8oz"         /*
*/ -28 "6lbs, 13oz" -29 "7lbs, 3oz" -30 "7lbs, 8oz" -31 "7lbs, 13oz"        /*
*/ -32 "8lbs, 3oz" -33 "8lbs, 8oz" -34 "8lbs, 13oz"  -35 " "                /*
*/ -36 "Day of Birth" -37 "Weekday" -38 "Weekend" -39 " "

gen ratio = 1000*goodSeason/costNumerical
local nvar1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
order `nvar1'
local nvar2 _dob2

qui reg chosen `oFEs' _sob* _cost* _gend* _bwt* _dob*
local tvL  = sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1))
local pvL  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2
dis `pvL'

count

reg chosen `oFEs' _sob* _cost* _gend* _bwt* _dob*, cluster(ID)
local Nobs = e(N)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local vars SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4 s COST _cost1 _cost2      /*
*/ _cost3 _cost4 _cost5 _cost6 _cost7 _cost8 _cost9 _cost10 s GENDER _gend1  /*
*/ _gend2 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8     /*
*/ _bwt9 _bwt10 _bwt11 s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==7|`i'==19|`i'==23|`i'==36 {
        dis "`var'"
    }
    else if `i'==6|`i'==18|`i'==22|`i'==35|`i'==39 {
    }
    else if `i'==2|`i'==12|`i'==20|`i'==24|`i'==37 {
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
lab val Y names

*---------------------------------------------------------------------------
*--- (A4) Graph
*---------------------------------------------------------------------------
#delimit ;
twoway rcap  LB UB Y in 1/39, horizontal scheme(s1mono) lcolor(black) ||
  scatter Y Est in 1/39, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7))
ylabel(-1 -7 -19 -23 -36, valuelabel angle(0))
ymlabel(-2(-1)-5 -8(-1)-17 -20 -21 -24(-1)-34 -37 -38, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-FullGroup_`1'.eps", replace
macro shift
drop Est UB LB Y

local ctrl `oFEs' _gend* _bwt* _dob*
eststo: logit chosen goodSeason costNumerical `ctrl', cluster(ID)
margins, dydx(goodSeason costNumerical _gend2 `nvar1' `nvar2') post
est store m1
estadd scalar wtp = -1000*_b[goodSeason]/_b[costNumerical]
nlcom ratio:_b[goodSeason]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": m1

foreach spec in main wt {
    if `"`spec'"'=="main" {
        local wt
    }
    else if `"`spec'"'=="wt" {
        local wt [pw=weight]
    }
    local se cluster(ID)
    eststo: logit chosen spring summer _sob4 costNumerical `ctrl' `wt', `se'
    margins, dydx(spring summer costNumerical  _gend2 `nvar1' `nvar2' _sob4) post
    est store n1
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`ub';`lb']": n1
    est restore n1
    nlcom ratio:_b[summer]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95su "[`ub';`lb']": n1

    **NVSS main sample
    local c osample==1
    eststo: logit chosen spring summer _sob4 costNumerical `ctrl' `wt' if `c', `se'
    margins, dydx(spring summer costNumerical  _gend2 `nvar1' `nvar2' _sob4) post
    est store nmain1
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`ub';`lb']": nmain1
    est restore nmain1
    nlcom ratio:_b[summer]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95su "[`ub';`lb']": nmain1

    local c planning==0&white==1&RespSex=="Female"&parent!=1&age>=20&age<=45
    local c planning==0&white==1&RespSex=="Female"&married==0&parent!=1&age>=20&age<=45
    local c planning==0&parent!=1
    eststo: logit chosen spring summer _sob4 costNumerical `ctrl' `wt' if `c', `se'
    margins, dydx(spring summer costNumerical  _gend2 `nvar1' `nvar2' _sob4) post
    est store nplan1
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    estadd scalar wtpSu = -1000*_b[summer]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`ub';`lb']": nplan1
    est restore nplan1
    nlcom ratio:_b[summer]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
    estadd local conf95su "[`ub';`lb']": nplan1

    lab var _dob2 "Weekend Day"
    lab var _sob4 "Fall"
    lab var spring "Spring"
    lab var summer "Summer"
    lab var costNumerical "Cost (in 1000s)"
    lab var goodSeason "Quarter 2 or Quarter 3"
                                        #delimit ;
    esttab n1 nplan1 nmain1 using "$OUT/conjointWTP-seasons-`spec'.tex", replace
    cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
    (wtpSp conf95sp N, fmt(%5.1f %5.1f %9.0g) label("WTP for Spring (USD)" "95\% CI"
                                                    Observations))
    starlevel ("$ ^{\ddagger} $" `pvL') collabels(,none)
    mlabels("Full Sample" "Non-Planners" "White Mothers, 20-45") booktabs
    label title("Birth Characteristics and Willingness to Pay for Season of Birth"
                \label{conjointWTP`spec'})
    keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex)
    postfoot("\bottomrule           "
             "\multicolumn{4}{p{12.2cm}}{\begin{footnotesize} Average marginal   "
             "effects from a logit regression are displayed. All columns include "
             "option order fixed effects and round fixed effects. Standard       "
             "errors are clustered by respondent. Willingness to pay and its     "
             "95\% confidence interval is estimated based on the ratio of costs  "
             "to the probability of choosing a spring birth. The 95\% confidence "
             "interval is calculated using the delta method for the (non-linear) "
             "ratio, with confidence levels based on Leamer values. $^{\ddagger}$"
             " Siginificant based on Leamer criterion at 5\%."
             "\end{footnotesize}}\end{tabular}\end{table}");
    #delimit cr
    estimates clear
}

#delimit ;
gen young   = age>=20&age<=34;
gen nkids = 1 if RespNumKids=="1";
replace nkids = 2 if RespNumKids!="0"&nkids==.;
#delimit cr

qui reg chosen spring summer _sob4 costNumerical `ctrl' if osample==1
local pvL2  = ttail(e(N),sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1)))*2
local cc young==1 young==0 nkids==1 nkids==2
local jj = 1

foreach c of local cc {
    qui reg chosen spring summer _sob4 costNumerical `ctrl' if `c'
    local tvL2  = sqrt((e(df_r)/1)*(e(N)^(1/e(N))-1))

    local c `c'&osample==1
    eststo: logit chosen spring summer _sob4 costNumerical `ctrl' if `c', `se'
    margins, dydx(spring summer costNumerical _gend2 `nvar1' `nvar2' _sob4) post
    est store ns`jj'
    estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
    nlcom ratio:_b[spring]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-`tvL2'*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+`tvL2'*_se[ratio]), "%5.1f")
    estadd local conf95sp "[`ub';`lb']": ns`jj'
    est restore ns`jj'
    local ++jj
}

#delimit ;
esttab ns1 ns2 ns3 ns4 using "$OUT/conjointWTP-marriedSubsamples.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtpSp conf95sp N, fmt(%5.1f %5.1f %9.0g) label("WTP for Spring (USD)" "95\% CI"
                                                Observations))
starlevel ("$ ^{\ddagger} $" `pvL2') collabels(,none)
mgroups("Age" "Fertility", pattern(1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mlabels("20-34" "35-45" "1 Child" "2+ Children") booktabs
label title("Birth Characteristics and WTP by Group"
            \label{conjointWTPmarriedSubsamples})
keep(spring summer _sob4 costNumerical _gend2 `nvar1' `nvar2') style(tex)
postfoot("\bottomrule           "
         "\multicolumn{5}{p{14.1cm}}{\begin{footnotesize} Each regression    "
         "sample consists of white married mothers aged 20-45 who meet the   "
         "criteria in column headings. Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a spring birth. The 95\% confidence "
         "interval is calculated using the delta method for the (non-linear) "
         "ratio, with confidence levels based on Leamer values. $^{\ddagger}$"
         " Siginificant based on Leamer criterion at 5\%."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr

*-------------------------------------------------------------------------------
*-- (A5) Heterogeneity using mixed logit
*-------------------------------------------------------------------------------
gen price = costNumerical
gen group = 1000*ID+round
tab round, gen(_rr)
tab option, gen(_oo)
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11

mixlogit chosen price, id(ID) group(group) rand(_sob* _gend* `bwts')
estimates store mlall
estadd scalar pcb = 100*normal(_b[Mean:_sob2]/abs(_b[SD:_sob2]))
local price = _b[price]
mixlbeta _sob2, saving("$OUT/mixparameters_all") replace
preserve
use "$OUT/mixparameters_all", clear
gen wtp = -1000*_sob2/`price'
#delimit ;
hist wtp, scheme(s1mono) xtitle("WTP for Spring Birth ($)")
fcolor(gs10) lcolor(black) fintensity(25);
#delimit cr
graph export "$OUT/WTPdistSpring.eps", replace
restore
estadd scalar wtp = -1000*(_b[_sob2]/_b[price])
nlcom ratio:_b[_sob2]/_b[price], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": mlall

*mixlogit chosen price if osample==1, id(ID) group(group) rand(_sob* _gend* `bwts')
*estimates store mlmain
*estadd scalar pcb = 100*normal(_b[Mean:_sob2]/abs(_b[SD:_sob2]))
*local price = _b[price]
*mixlbeta _sob2 if osample==1, saving("$OUT/mixparameters_main") replace
*preserve
*use "$OUT/mixparameters_main", clear
*gen wtp = -1000*_sob2/`price'
*#delimit ;
*hist wtp, scheme(s1mono) xtitle("WTP for Spring Birth ($)")
*fcolor(gs10) lcolor(black) fintensity(25);
*#delimit cr
*graph export "$OUT/WTPdistSpring_main.eps", replace
*restore
*estadd scalar wtp = -1000*(_b[_sob2]/_b[price])
*nlcom ratio:_b[_sob2]/_b[price], post
*local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
*local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
*estadd local conf95 "[`ub';`lb']": mlmain
*mixlogit chosen price if planning==0&parent!=1, id(ID) group(group) rand(_sob* _gend* `bwts')
*estimates store mlplan
*estadd scalar pcb = 100*normal(_b[Mean:_sob2]/abs(_b[SD:_sob2]))
*local price = _b[price]
*mixlbeta _sob2 if planning==0&parent!=1, saving("$OUT/mixparameters_noplan") replace
*preserve
*use "$OUT/mixparameters_noplan", clear
*gen wtp = -1000*_sob2/`price'
*#delimit ;
*hist wtp, scheme(s1mono) xtitle("WTP for Spring Birth ($)")
*fcolor(gs10) lcolor(black) fintensity(25);
*#delimit cr
*graph export "$OUT/WTPdistSpring_noplan.eps", replace
*restore
*estadd scalar wtp = -1000*(_b[_sob2]/_b[price])
*nlcom ratio:_b[_sob2]/_b[price], post
*local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
*local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
*estadd local conf95 "[`ub';`lb']": mlplan

lab var _sob2 "Spring"
lab var _sob3 "Summer"
lab var _sob4 "Fall"
lab var price "Cost (in 1000s)"
*MIXED LOGIT
#delimit ;
esttab mlall using "$OUT/WTP-mixedlogit.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 pcb N, fmt(%5.1f %5.1f %5.1f %9.0g)
    label("WTP for Spring Birth" "95\% CI"
          "\% Positively Impacted by Spring Birth" Observations))
starlevel ("$ ^{\ddagger} $" `pvL') collabels(,none) style(tex)
aamlabels("Mixed Logit") booktabs label
title("Allowing for Preference Heterogeneity with Mixed Logit"\label{WTPmix})
postfoot("\bottomrule           "
         "\multicolumn{2}{p{14.1cm}}{\begin{footnotesize} Panel A displays   "
         "mean coefficients from the mixed logit, and panel B displays the   "
         "estimated standard deviation of each coefficient.  All coefficients"
         " with the exception of Cost are allowed to vary randomly throughout"
         " the sample.  The WTP is calculated as the ratio of the coefficient"
         " on spring birth to that on costs, and confidence intervals are    "
         "calculated by the delta method. The \% of respondents who value    "
         "a spring birth positively based on individual coefficients is      "
         "displayed at the foot of the table.  Standard errors are clustered "
         "by respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
*/
*-------------------------------------------------------------------------------
*-- (A5b) Bootstrap WTP predictors for NVSS analysis
*-------------------------------------------------------------------------------
cap gen price = costNumerical
cap gen group = 1000*ID+round
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11

gen educYrs     = 8 if RespEduc=="Eighth Grade or Less"
replace educYrs = 10 if RespEduc=="Eighth Grade or Less"
replace educYrs = 12 if RespEduc=="High School Degree/GED"
replace educYrs = 13 if RespEduc=="Some College"
replace educYrs = 14 if RespEduc=="2-year College Degree"
replace educYrs = 16 if RespEduc=="4-year College Degree"
replace educYrs = 17 if RespEduc=="Master's Degree"
replace educYrs = 17 if RespEduc=="Doctoral Degree"
replace educYrs = 17 if RespEduc=="Professional Degree (JD,MD,MBA)"
local wt [pw=weight]


mixlogit chosen price `wt' if osample==1, id(ID) group(group) rand(_sob* _gend* `bwts')
local price = _b[price]
tempfile betas
set seed 1704
mixlbeta _sob2 if osample==1, saving(`betas') replace
rename _sob2 __sob2
merge m:1 ID using `betas'
drop _merge
rename _sob2 betaSOB
rename __sob2 _sob2
replace betaSOB=-1000*betaSOB/`price'
gen educYrsSq = educYrs^2

reg betaSOB i.age educYrs educYrsSq `wt'
estimates store WTPbase
gen WTPests  = .
gen WTPestsC = .
gen WTPmean  = .                
*preserve
local bsamp 0
if `bsamp'==1 {
    use "$NVS/nvss2005_2013_all", clear
    keep if birthOrder==1&motherAge>=20&motherAge<=45&married==1&twin==1&white==1&liveBirth==1
    drop if educYrs==.|smoker==.|gestation==.
    rename motherAge age
    #delimit ;
    keep age educYrs educYrsSq quarter2 smoker gestation WIC underweight hispanic
    overweight obese noART fips;
    #delimit cr
    save "$NVS/nvss2005_2013_BSAMP", replace
}
else use "$NVS/nvss2005_2013_BSAMP", clear
local controls smoker WIC underweight overweight obese noART hispanic


predict WTPhat, xb
reg quarter2 WTPhat if smoker!=.&gest!=.
predict q2hat if e(sample)==1

logit quarter2 WTPhat if smoker!=.&gest!=.
margins, dydx(*)
predict q2hatLog if e(sample)==1
exit
sum WTPhat if e(sample)==1
local WTPmean = r(mean)
dis 1000*_b[WTPhat]
local wtp1 _b[WTPhat]
reg quarter2 WTPhat `controls' i.fips
sum WTPhat if e(sample)==1
dis 1000*_b[WTPhat]
local wtp2 _b[WTPhat]
restore
replace WTPests  = `wtp1'    in 1
replace WTPestsC = `wtp2'    in 1
replace WTPmean  = `WTPmean' in 1
drop betaSOB


*-- Bootstrap N=100 --------------------------------------------------------
set seed 1307

local j = 2
local N = 100
foreach num of numlist 1(1)`N' {
    dis "BOOTSTRAP REPLICATION `num'"
    preserve
    estimates restore WTPbase

    use "$NVS/nvss2005_2013_BSAMP", clear
    bsample
    local controls smoker WIC underweight overweight obese noART hispanic

    predict WTPhat, xb
    qui reg quarter2 WTPhat if smoker!=.&gest!=.
    sum WTPhat if e(sample)==1
    local WTPmean = r(mean)
    dis 1000*_b[WTPhat]
    local wtp1 =  _b[WTPhat]
    reg quarter2 WTPhat `controls'
    dis 1000*_b[WTPhat]
    local wtp2 =  _b[WTPhat]
    restore
    replace WTPests  = `wtp1'    in `j'
    replace WTPestsC = `wtp2'    in `j'
    replace WTPmean  = `WTPmean' in `j'
    local ++j
}    
exit
*---------------------------------------------------------------------------
*--- (A6) Continuous cost graph
*---------------------------------------------------------------------------
#delimit cr
lab def namesT -1 "Season of Birth" -2 "Winter" -3 "Spring" -4 "Summer"      /*
*/ -5 "Fall" -6 " " -7 "Cost" -8 "1000s of USD" -9 " " -10 "Gender"          /*
*/ -11 "Boy" -12 "Girl" -13 " " -14 "Birth Weight" -15 "5lbs, 8oz"           /*
*/ -16 "5lbs, 13oz" -17 "6lbs, 3oz" -18 "6lbs, 8oz" -19 "6lbs, 13oz"         /*
*/ -20 "7lbs, 3oz" -21 "7lbs, 8oz" -22 "7lbs, 13oz" -23 "8lbs, 3oz"          /*
*/ -24 "8lbs, 8oz" -25 "8lbs, 13oz"  -26 " " -27 "Day of Birth" -28 "Weekday"/*
*/ -29 "Weekend" -30 " "

reg chosen `oFEs' _sob* costNumerical _gend* _bwt* _dob*, cluster(ID)
local Nobs = e(N)

gen Est = .
gen UB  = .
gen LB  = .
gen Y   = .
local i = 1
local vars SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4 s COST costNumerical s    /*
*/ GENDER _gend1 _gend2 s BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6   /*
*/ _bwt7 _bwt8 _bwt9 _bwt10 _bwt11 s DAY-OF-BIRTH _dob1 _dob2 s

foreach var of local vars {
    qui replace Y = `i' in `i'
    if `i'==1|`i'==7|`i'==10|`i'==14|`i'==27 {
        dis "`var'"
    }
    else if `i'==6|`i'==9|`i'==13|`i'==26|`i'==30 {
    }
    else if `i'==2|`i'==11|`i'==15|`i'==28 {
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
lab val Y namesT

#delimit ;
twoway rcap  LB UB Y in 1/30, horizontal scheme(s1mono) lcolor(black) ||
scatter Y Est in 1/30, mcolor(black) msymbol(oh) mlwidth(thin)
xline(0, lpattern(dash) lcolor(gs7))
ylabel(-1 -7 -10 -14 -27, valuelabel angle(0))
ymlabel(-2(-1)-5 -8 -11 -12 -15(-1)-25 -28 -29, valuelabel angle(0))
ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
*legend(lab(1 "95% CI") lab(2 "Point Estimate"));
#delimit cr
graph export "$OUT/Conjoint-FullGroup_continuous.eps", replace
drop Est UB LB Y



reg chosen `oFEs' _sob* costNumerical _gend* _bwt* _dob*, cluster(ID)
#delimit ;
local vars _sob2 _sob3 _sob4 _gend2 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8
           _bwt9 _bwt10 _bwt11  _dob2;
local wts `" "5lbs, 13oz" "6lbs, 3oz" "6lbs, 8oz" "6lbs, 13oz" "7lbs, 3oz"
           "7lbs, 8oz" "7lbs, 13oz" "8lbs, 3oz" "8lbs, 8oz" "8lbs, 13oz" "';
#delimit cr
foreach var of varlist `vars' {
    local v`var'= -1000*_b[`var']/_b[costNumerical]
}

local bws _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
tokenize `bws'
foreach bw of local wts {
    local k=1
    foreach sb of varlist _sob2 _sob3 _sob4 {
        if `k'==1 local sbn "Spring"
        if `k'==2 local sbn "Winter"
        if `k'==3 local sbn "Fall"
        local vC = string(`v`1''+`v`sb''+`v_dob2'+`v_gend2',"%5.3f")
        dis "Comparative WTP of a girl, born weekend with `bw' and `sbn' is: $`vC'"
    }
    macro shift
}


*-------------------------------------------------------------------------------
*-- (A0) groups
*-------------------------------------------------------------------------------
gen cold = minTemp<23
gen father = parent==1 if RespSex=="Male"
gen mother = parent==1 if RespSex=="Female"
gen motherEmp = RespEmployment=="Employed" if mother==1
gen motherTeach = teacher==1 if mother==1
#delimit ;
local ng RespSex=="Female" RespSex=="Male" parent==1 parent==0 cold==1 cold==0
teacher==1 teacher==0 RespEmployment=="Employed" RespEmployment!="Employed"
father==1 father==0 mother==1 mother==0 motherEmp==1 motherEmp==0
motherTeach==1 motherTeach==0 motherEmp==1&osample==1 motherEmp==0&osample==1
motherTeach==1&osample==1 motherTeach==0&osample==1;
local names Female Male Parent Non-Parent Cold Warm Teacher Non-Teacher Employed
Unemployed Father Non-Father Mother Non-Mother Mother-Employed
Mother-Unemployed Mother-Teacher Mother-Non-Teacher
Mother-Employed-sample Mother-Unemployed-sample
Mother-Teacher-sample Mother-Non-Teacher-sample;
#delimit cr
tokenize `names'
cap rm "$OUT/samples.xls"
cap rm "$OUT/samples.txt"

foreach gg of local ng {
    reg chosen _sob* costNumerical _gend* _bwt* _dob* if `gg', cluster(ID)
    local wtp = string(-1000*_b[_sob2]/_b[costNumerical], "%5.2f")
    est store e1
    nlcom ratio:_b[_sob2]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    est restore e1
    outreg2 using $OUT/samples.xls, excel ctitle(`1')/*
    */ keep(_sob* costNumerical _gend* _bwt* _dob*)  /*
    */ addtext(WTP, `wtp', 95% CI, [`ub' - `lb'])
    macro shift
}
gen female   = RespSex=="Female"
gen employed = RespEmployment=="Employed"
gen mempsample   = motherEmp if osample==1
gen mteachsample = motherTeach if osample==1

#delimit ;
local ng female parent cold teacher employed father mother motherEmp motherTeach
mempsample mteachsample;
local names Female Parent Cold Teacher Employed Father Mother Mother-Employed
Mother-Teacher Mother-Employed-Sample Mother-Teacher-Sample;
#delimit cr
tokenize `names'
cap rm "$OUT/samplesInteraction.xls"
cap rm "$OUT/samplesInteraction.txt"

foreach group of local ng {
    foreach v of varlist _sob* _gend* _bwt* _dob* {
        gen _INT`v'=`v'*`group'
    }
    reg chosen  _sob* costNumerical _gend* _bwt* _dob* _INT* `group', cluster(ID)
    local wtp = string(-1000*_b[_sob2]/_b[costNumerical], "%5.2f")
    local iwtp = string(-1000*_b[_INT_sob2]/_b[costNumerical], "%5.2f")

    est store e1
    nlcom ratio:_b[_sob2]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    est restore e1
    nlcom ratio2:_b[_INT_sob2]/_b[costNumerical], post
    local lbi = string(-1000*(_b[ratio2]-1.96*_se[ratio2]), "%5.1f")
    local ubi = string(-1000*(_b[ratio2]+1.96*_se[ratio2]), "%5.1f")
    est restore e1
    outreg2 using $OUT/samplesInteraction.xls, excel ctitle(`1') /*
    */ keep(_sob* costNumerical _INT_sob*)  /*
    */ addtext(WTP, `wtp', 95% CI, [`ub' - `lb'], /*
    */         WTP Interaction, `iwtp', 95% CI Interaction, [`ubi' - `lbi'])
    macro shift
    drop _INT*
}

