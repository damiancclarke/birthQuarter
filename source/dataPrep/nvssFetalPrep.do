/* nvssFetalPrep.do v0.00        damiancclarke             yyyy-mm-dd:2015-05-25
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Take raw NVSS fetal death data for years 2005-2013 and formats into a large file
with all fetal deaths.  This is set up to have the same variables as the NVSS b-
irth data file.

*NOTE: Think about gestation and birth season.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/database/NVSS/FetalDeaths/dta"
global OUT "~/investigacion/2015/birthQuarter/data/nvss"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssFetalPrep.txt", text replace

********************************************************************************
*** (2a) 2005 File
********************************************************************************
use "$DAT/fetl2005"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt != 9999
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
foreach var of varlist cig_1 cig_2 cig_3 {
    destring `var', replace
}
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
replace female  = . if sex == "U"
gen oldEduc     = umeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb if mpcb != 99
replace monthPrenat = precare if monthPrenat == . & precare != 99

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = . if meduc==9

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw gestation   /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single /*
*/ female birthMonth oldEduc numPrenatal monthPrenat liveBirth
tempfile B2005
save `B2005'

********************************************************************************
*** (2b) 2006 File
********************************************************************************
use "$DAT/fetl2006"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
foreach var of varlist cig_1 cig_2 cig_3 {
    destring `var', replace
}
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
replace female  = . if sex == "U"
gen oldEduc     = umeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb if mpcb != 99
replace monthPrenat = precare if monthPrenat == . & precare != 99

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = . if meduc==9

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw gestation   /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single /*
*/ female birthMonth oldEduc numPrenatal monthPrenat liveBirth
tempfile B2006
save `B2006'

********************************************************************************
*** (2c) 2007 File
********************************************************************************
use "$DAT/fetl2007"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder = lbo_rec
gen motherAge  = mager
gen fatherAge  = fagerec11
gen birthMonth = dod_mm
gen year       = dod_yy
gen twin       = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthweight vlbw lbw gestation premature /*
*/ motherAge fatherAge ageGroupMan married single female birthMonth liveBirth
tempfile B2007
save `B2007'

********************************************************************************
*** (2d) 2008 File
********************************************************************************
use "$DAT/fetl2008"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation liveBirth  /*
*/ premature motherAge fatherAge ageGroupMan married single female birthMonth 
tempfile B2008
save `B2008'

********************************************************************************
*** (2e) 2009 File
********************************************************************************
use "$DAT/fetl2009"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation premature /*
*/ motherAge fatherAge ageGroupMan married female birthMonth liveBirth single 
tempfile B2009
save `B2009'

********************************************************************************
*** (2f) 2010 File
********************************************************************************
use "$DAT/fetl2010"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >=25 & gestation<44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation premature  /*
*/ motherAge fatherAge ageGroupMan married single female birthMonth liveBirth
tempfile B2010
save `B2010'

********************************************************************************
*** (2g) 2011 File
********************************************************************************
use "$DAT/fetl2011"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >= 25 & gestation < 44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation premature /*
*/ motherAge fatherAge ageGroupMan married single female birthMonth liveBirth
tempfile B2011
save `B2011'

********************************************************************************
*** (2h) 2012 File
********************************************************************************
use "$DAT/fetl2012"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >= 25 & gestation < 44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation motherAge /*
*/ fatherAge ageGroupMan married single female birthMonth liveBirth
tempfile B2012
save `B2012'

********************************************************************************
*** (2i) 2013 File
********************************************************************************
use "$DAT/fetl2013"

gen liveBirth   = 0
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dod_mm
gen year        = dod_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen female      = sex=="F"
replace female  = . if sex == "U"

keep if birthOrder==0 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0
keep if gestation >= 25 & gestation < 44

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

keep birthQuarter ageGroup twin year birthwei vlbw lbw gestation motherAge  /*
*/ fatherAge ageGroupMan married single female birthMonth liveBirth
tempfile B2013
save `B2013'


********************************************************************************
*** (3) Append to 2005-2013 file
********************************************************************************
append using `B2005' `B2006' `B2007' `B2008' `B2009' `B2010' `B2011' `B2012'


********************************************************************************
*** (4) Save, clean
********************************************************************************
lab dat "NVSS fetal death data 2005-2013 (first births, white, 25-45 year olds)"
save "$OUT/nvssFD2005_2013.dta", replace
