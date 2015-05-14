/* nvss0512Prep.do v0.00         damiancclarke             yyyy-mm-dd:2015-04-02
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Take raw NVSS data for years 2005-2012 and formats into a large file with all b-
irths.  This is set up to have the same variables as the IPUMS data file.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/database/NVSS/Births/dta"
global OUT "~/investigacion/2015/birthQuarter/data/nvss"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvss0512Prep.txt", text replace

********************************************************************************
*** (2a) 2005 File
********************************************************************************
use "$DAT/natl2005"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = abs(tobuse-2) if tobuse<3

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=dmeduc>=13
replace educLevel=2 if dmeduc>=16
replace educLeve=. if dmeduc==99

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2005
save `B2005'

********************************************************************************
*** (2b) 2006 File
********************************************************************************
use "$DAT/natl2006"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = abs(tobuse-2) if tobuse<3

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=dmeduc>=13
replace educLevel=2 if dmeduc>=16
replace educLevel=. if dmeduc==99|dmeduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2006
save `B2006'

********************************************************************************
*** (2c) 2007 File
********************************************************************************
use "$DAT/natl2007"

gen married     = mar==1
gen birthOrder = lbo_rec
gen motherAge  = mager
gen fatherAge  = fagerec11
gen birthMonth = dob_mm
gen year       = dob_yy
gen twin       = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = abs(tobuse-2) if tobuse<3

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2007
save `B2007'

********************************************************************************
*** (2d) 2008 File
********************************************************************************
use "$DAT/natl2008"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = abs(tobuse-2) if tobuse<3

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2008
save `B2008'

********************************************************************************
*** (2e) 2009 File
********************************************************************************
use "$DAT/natl2009"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2009
save `B2009'

********************************************************************************
*** (2f) 2010 File
********************************************************************************
use "$DAT/natl2010"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2010
save `B2010'

********************************************************************************
*** (2g) 2011 File
********************************************************************************
use "$DAT/natl2011"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2011
save `B2011'

********************************************************************************
*** (2h) 2012 File
********************************************************************************
use "$DAT/natl2012"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2012
save `B2012'

********************************************************************************
*** (2i) 2013 File
********************************************************************************
use "$DAT/natl2013"

gen married     = mar==1
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500
gen lbw         = birthweight < 2500
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"

keep if birthOrder==1 & (motherAge>=25 & motherAge<=45)
keep if mracerec == 1 & umhisp == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc <=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = 0 if meduc==9

keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw apgar /*
*/ gestation premature motherAge education fatherAge ageGroupMan married smoker
tempfile B2013
save `B2013'


********************************************************************************
*** (3) Append to 2005-2013 file
********************************************************************************
append using `B2005' `B2006' `B2007' `B2008' `B2009' `B2010' `B2011' `B2012'


********************************************************************************
*** (4) Save, clean
********************************************************************************
lab dat "NVSS birth data 2005-2013 (first births, white, 25-45 year olds)"
save "$OUT/nvss2005_2013.dta", replace
