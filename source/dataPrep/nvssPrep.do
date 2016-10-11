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
local nohisp  0
local noblack 0

global DAT "~/database/nvsscdc/births/dta"
global UNE "~/investigacion/2015/birthQuarter/data/employ"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/data/nvss"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvss0512Prep.txt", text replace
********************************************************************************
*** (2a) 2005 File
********************************************************************************
use "$DAT/natl2005"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
gen oldEduc     = dmeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb
replace monthPrenat = precare if monthPrenat == .

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1  keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fagerec11>6 & fagerec11 != 11
replace ageGroupMan = ageGroupMan + 1

gen educLevel=meduc>=4
replace educLevel=2 if meduc>=5
replace educLevel=. if meduc==9|meduc==.

gen education = meduc if meduc<=5
replace education = 5 if meduc==6
replace education = 6 if meduc==7|meduc==8
replace education = . if meduc==9

gen mcounty = ocntyfips
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth oldEduc numPrenat monthPrenat birthOrder fatherWhiteNonH /*
*/ liveBirth mcounty mstate bcounty bstate hispanic white black
tempfile B2005
save `B2005'

********************************************************************************
*** (2b) 2006 File
********************************************************************************
use "$DAT/natl2006"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
gen oldEduc     = dmeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb
replace monthPrenat = precare if monthPrenat == .

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = ocntyfips
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth oldEduc numPrenat monthPrenat birthOrder fatherWhiteNonH /*
*/ liveBirth mcounty mstate bcounty bstate hispanic white black
tempfile B2006
save `B2006'

********************************************************************************
*** (2c) 2007 File
********************************************************************************
use "$DAT/natl2007"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
gen oldEduc     = dmeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb
replace monthPrenat = precare if monthPrenat == .

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth oldEduc numPrenat monthPrenat birthOrder fatherWhiteNonH /*
*/ liveBirth mcounty mstate bcounty bstate hispanic white black
tempfile B2007
save `B2007'

********************************************************************************
*** (2d) 2008 File
********************************************************************************
use "$DAT/natl2008"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if (cig_1>0&cig_1<99)|(cig_2>0&cig_2<99)|(cig_3>0&cig_3<99)
replace smoker  = 0 if cig_1==0 & cig_2==0 & cig_3==0
gen female      = sex=="F"
gen oldEduc     = dmeduc != .
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = mpcb
replace monthPrenat = precare if monthPrenat == .

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth oldEduc numPrenat monthPrenat birthOrder fatherWhiteNonH /*
*/ liveBirth mcounty mstate bcounty bstate hispanic white black
tempfile B2008
save `B2008'

********************************************************************************
*** (2e) 2009 File
********************************************************************************
use "$DAT/natl2009"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"
gen Presmoker   = cig_0>0 if cig_0<99
gen female      = sex=="F"
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = precare
gen prePregBMI  = bmi
gen infertTreat = rf_inftr=="Y" if rf_inftr!="U"&rf_inftr!=""
gen ART         = rf_artec=="Y" if rf_artec!="U"&rf_artec!=""
gen WIC         = wic=="Y" if wic!="U"&wic!=""
gen PrePregWt   = pwgt_r if pwgt_r!=999
gen height      = m_ht_in if m_ht_in!=99
gen BMI         = (PrePregWt / (height^2))*703
replace BMI     = . if BMI<16 | BMI>40
gen underweight = BMI<18.5 if BMI!=.
gen overweight  = BMI>=25&BMI<30 if BMI!=.
gen obese       = BMI>=30 if BMI!=.

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat  /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single   /*
*/ female birthMonth numPrenat monthPrenat prePregBMI birthOrder fatherWhiteNo /*
*/ infertTreat ART liveBirth mcounty mstate bcounty bstate WIC Presmoker       /*
*/ PrePregWt height BMI underweight overweight obese hispanic white black
tempfile B2009
save `B2009'

********************************************************************************
*** (2f) 2010 File
********************************************************************************
use "$DAT/natl2010"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"
gen female      = sex=="F"
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = precare
gen prePregBMI  = bmi
gen infertTreat = rf_inftr=="Y" if rf_inftr!="U"&rf_inftr!=""
gen ART         = rf_artec=="Y" if rf_artec!="U"&rf_artec!=""
gen WIC         = wic=="Y" if wic!="U"&wic!=""
gen Presmoker   = cig_0>0 if cig_0<99
gen PrePregWt   = pwgt_r if pwgt_r!=999
gen height      = m_ht_in if m_ht_in!=99
gen BMI         = (PrePregWt / (height^2))*703
replace BMI     = . if BMI<16 | BMI>40
gen underweight = BMI<18.5 if BMI!=.
gen overweight  = BMI>=25&BMI<30 if BMI!=.
gen obese       = BMI>=30 if BMI!=.

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat  /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single   /*
*/ female birthMonth numPrenat monthPrenat prePregBMI birthOrder fatherWhiteNo /*
*/ infertTreat ART liveBirth mcounty mstate bcounty bstate WIC Presmoker       /*
*/ PrePregWt height BMI underweight overweight obese hispanic white black
tempfile B2010
save `B2010'

********************************************************************************
*** (2g) 2011 File
********************************************************************************
use "$DAT/natl2011"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"
gen female      = sex=="F"
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = precare
gen prePregBMI  = bmi
gen infertTreat = rf_inftr=="Y" if rf_inftr!="U"&rf_inftr!=""
gen ART         = rf_artec=="Y" if rf_artec!="U"&rf_artec!=""
gen WIC         = wic=="Y" if wic!="U"&wic!=""
gen Presmoker   = cig_0>0 if cig_0<99
gen PrePregWt   = pwgt_r if pwgt_r!=999
gen height      = m_ht_in if m_ht_in!=99
gen BMI         = (PrePregWt / (height^2))*703
replace BMI     = . if BMI<16 | BMI>40
gen underweight = BMI<18.5 if BMI!=.
gen overweight  = BMI>=25&BMI<30 if BMI!=.
gen obese       = BMI>=30 if BMI!=.

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat  /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single   /*
*/ female birthMonth numPrenat monthPrenat prePregBMI birthOrder fatherWhiteNo /*
*/ infertTreat ART liveBirth mcounty mstate bcounty bstate WIC Presmoker       /*
*/ PrePregWt height BMI underweight overweight obese hispanic white black
tempfile B2011
save `B2011'

********************************************************************************
*** (2h) 2012 File
********************************************************************************
use "$DAT/natl2012"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"
gen female      = sex=="F"
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = precare
gen prePregBMI  = bmi
gen infertTreat = rf_inftr=="Y" if rf_inftr!="U"&rf_inftr!=""
gen ART         = rf_artec=="Y" if rf_artec!="U"&rf_artec!=""
gen WIC         = wic=="Y" if wic!="U"&wic!=""
gen Presmoker   = cig_0>0 if cig_0<99
gen PrePregWt   = pwgt_r if pwgt_r!=999
gen height      = m_ht_in if m_ht_in!=99
gen BMI         = (PrePregWt / (height^2))*703
replace BMI     = . if BMI<16 | BMI>40
gen underweight = BMI<18.5 if BMI!=.
gen overweight  = BMI>=25&BMI<30 if BMI!=.
gen obese       = BMI>=30 if BMI!=.

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth numPrenatal monthPrenat prePregBMI birthOrder infertTreat/*
*/ fatherWhiteNonH ART liveBirth mcounty mstate bcounty bstate WIC Presmoker  /*
*/ PrePregWt height BMI underweight overweight obese hispanic white black
tempfile B2012
save `B2012'

********************************************************************************
*** (2i) 2013 File
********************************************************************************
use "$DAT/natl2013"

gen liveBirth   = 1
gen married     = mar==1
gen single      = married==0&fagerec11==11
gen birthOrder  = lbo_rec
gen motherAge   = mager
gen fatherAge   = fagerec11
gen birthMonth  = dob_mm
gen year        = dob_yy
gen twin        = dplural
gen birthweight = dbwt if dbwt>=500 & dbwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = apgar5 if apgar5>=0 & apgar5 <=10
gen gestation   = combgest if combgest!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = 1 if cig_rec=="Y"
replace smoker  = 0 if cig_rec=="N"
gen female      = sex=="F"
gen numPrenatal = uprevis if uprevis != 99
gen monthPrenat = precare
gen prePregBMI  = bmi
gen infertTreat = rf_inftr=="Y" if rf_inftr!="U"&rf_inftr!=""
gen ART         = rf_artec=="Y" if rf_artec!="U"&rf_artec!=""
gen WIC         = wic=="Y" if wic!="U"&wic!=""
gen Presmoker   = cig_0>0 if cig_0<99
gen PrePregWt   = pwgt_r if pwgt_r!=999
gen height      = m_ht_in if m_ht_in!=99
gen BMI         = (PrePregWt / (height^2))*703
replace BMI     = . if BMI<16 | BMI>40
gen underweight = BMI<18.5 if BMI!=.
gen overweight  = BMI>=25&BMI<30 if BMI!=.
gen obese       = BMI>=30 if BMI!=.

keep if birthOrder<=2 
if `noblack'==1 keep if mracerec == 1
if `nohisp'==1 keep if umhisp == 0
gen hispanic = umhisp!=0
gen fatherWhiteNonHisp = fracerec==1 & ufhisp == 0
gen white = mracerec==1
gen black = mracerec==2

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

gen mcounty = mrcnty
gen mstate  = mrterr
gen bcounty = ocntyfips
gen bstate  = oterr

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar gestat /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth numPrenatal monthPrenat prePregBMI birthOrder infertTreat/*
*/ fatherWhiteNonH ART liveBirth mcounty mstate bcounty bstate WIC Presmoker  /*
*/ PrePregWt height BMI underweight overweight obese hispanic white black
tempfile B2013
save `B2013'



********************************************************************************
*** (3) Import weather
********************************************************************************
insheet using "$USW/usaWeather.txt", delim(";") names clear
destring temp, replace

reshape wide temp, i(state fips year month) j(type) string
keep if year>1997&year<=1999

collapse temptmpcst (min) temptminst (max) temptmaxst, by(state fips)
expand 2 if fips == 24, gen(expanded)
replace fips = 11 if expanded==1
replace state= "Washington DC" if expanded==1
drop expanded
rename temptmpcst meanT
rename temptminst cold
rename temptmaxst hot
gen Tvariation = hot-cold
*rename state stateSpace
*gen state = subinstr(stateSpace, " ", "", .)
*replace state = "DC" if state=="Washington DC"

tempfile weather
save `weather'

clear
********************************************************************************
*** (4) Append to 2005-2013 file, generate variables
********************************************************************************
append using `B2005' `B2006' `B2007' `B2008' `B2009' `B2010' `B2011' `B2013'

gen goodQuarter = birthQuarter == 2 | birthQuarter == 3
gen badQuarter  = birthQuarter == 4 | birthQuarter == 1
replace ageGroup  = ageGroup-1 if ageGroup>1
gen college = educLevel == 2 if educLevel!=.
gen educCat = 4 if education==1
replace educCat = 10 if education == 2
replace educCat = 12 if education == 3
replace educCat = 14 if education == 4
replace educCat = 16 if education == 5
replace educCat = 17 if education == 6

gen highEd              = (educLevel == 1 | educLevel == 2) if educLevel!=.
gen young               = motherAge>=25 & motherAge<40 
gen youngXhighEd        = young*highEd
gen youngXbadQ          = young*(1-goodQuarter)
gen highEdXbadQ         = highEd*(1-goodQuarter)
gen youngXhighEdXbadQ   = young*highEd*(1-goodQuarter)
gen youngMan            = ageGroupMan == 1
gen youngManXbadQ       = youngMan*(1-goodQuarter)
gen vhighEd             = educLevel == 2 if educLevel!=.
gen youngXvhighEd       = young*vhighEd
gen age2024             = motherAge>=20&motherAge<=24
gen age2534             = motherAge>=25 & motherAge <35
gen age2527             = motherAge>=25 & motherAge <28
gen age2831             = motherAge>=28 & motherAge <32
gen age3239             = motherAge>=32 & motherAge <40
gen age3539             = motherAge>=35 & motherAge <40
gen age4045             = motherAge>=40 & motherAge <46
gen age2534XhighEd      = age2534*highEd
gen age2527XhighEd      = age2527*highEd
gen age2831XhighEd      = age2831*highEd
gen age3239XhighEd      = age3239*highEd
gen age3539XhighEd      = age3539*highEd
gen teenage             = motherAge>=15 & motherAge <20
gen noPreVisit          = numPrenatal == 0 if numPrenatal<99
gen prenate3months      = monthPrenat>0 & monthPrenat <= 3 if monthPrenat<99
gen motherAge2          = motherAge^2
gen motherAgeXeduc      = motherAge*educCat
gen     prematurity     = gestation - 39
gen     monthsPrem      = round(prematurity/4)*-1
gen     expectedMonth   = birthMonth + monthsPrem
replace expectedMonth   = expectedMonth - 12 if expectedMonth>12
replace expectedMonth   = expectedMonth + 12 if expectedMonth<1
gene    expectQuarter   = ceil(expectedMonth/3) 
gene    badExpectGood   = badQuarter==1&(expectQuar==2|expectQuar==3) if gest!=.
gene    badExpectBad    = badQuarter==1&(expectQuar==1|expectQuar==4) if gest!=.
gen     expectGoodQ     = expectQuarter == 2 | expectQuarter == 3 if gest!=.
gen     expectBadQ      = expectQuarter == 4 | expectQuarter == 1 if gest!=.

gen     Qgoodgood       = expectGoodQ==1 & goodQuarter==1 if gest!=.
gen     Qgoodbad        = expectGoodQ==1 & badQuarter ==1 if gest!=.
gen     Qbadgood        = expectBadQ==1  & goodQuarter==1 if gest!=.
gen     Qbadbad         = expectBadQ==1  & badQuarter ==1 if gest!=.
gen     noART           = (ART-1)*-1
gen     noARTyoung      = noART*young
gen     ARTage2024      = ART*age2024
gen     BMIsq           = BMI^2
gen     conceptionMonth = birthMonth - round(gestation*7/30.5)
replace conceptionMonth = conceptionMonth + 12 if conceptionMonth<1

sum expectGoodQ expectBadQ
sum Qgoodgood Qgoodbad Qbadgood Qbadbad

drop goodQuarter badQuarter
gen goodQuarter = expectGoodQ
gen badQuarter  = expectBadQ
tab year, gen(_year)

#delimit ;
local stat AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME 
           MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX 
           UT VA VT WA WI WV WY;
local fips 8  7  10 9  11 12 13 15 14 16 17 18 22 19 20 21 23 24 25 28 27 26 
           29 30 32 31 33 40 41 34 36 37 38 35 39 42 43 44 45 47 48 49 50 51 
           52 54 53 56 58 57 59;
local snam " `"Alaska"' `"Alabama"' `"Arkansas"' `"Arizona"' `"California"'
             `"Colorado"' `"Connecticut"' `"Washington DC"' `"Delaware"'
             `"Florida"' `"Georgia"' `"Hawaii"' `"Iowa"' `"Idaho"' `"Illinois"'
             `"Indiana"' `"Kansas"' `"Kentucky"' `"Louisiana"' `"Massachusetts"'
             `"Maryland"' `"Maine"' `"Michigan"' `"Minnesota"' `"Missouri"'
             `"Mississippi"' `"Montana"' `"North Carolina"' `"North Dakota"'
             `"Nebraska"' `"New Hampshire"' `"New Jersey"' `"New Mexico"'
             `"Nevada"' `"New York"' `"Ohio"' `"Oklahoma"' `"Oregon"'
             `"Pennsylvania"' `"Rhode Island"' `"South Carolina"'
             `"South Dakota"' `"Tennessee"' `"Texas"' `"Utah"' `"Virginia"'
             `"Vermont"' `"Washington"' `"Wisconsin"' `"West Virginia"'
             `"Wyoming"'";
#delimit cr
gen fips = .
tokenize `stat'
foreach ff of local fips {
    dis "State: `1', FIPS = `ff'"
    replace fips = `ff' if bstate=="`1'"
    macro shift
}
gen state = ""
tokenize `stat'
foreach ff of local snam {
    dis "State: `1', state name = `ff'"
    replace state = "`ff'" if bstate=="`1'"
    macro shift
}
merge m:1 state using `weather'
*MERGE = 1 is Hawaii (no temp data)
*MERGE = 2 is national average (1 obs)
*MERGE = 3 are correct merges.  This is 99.54% of the sample
drop if _merge==2
drop _merge


gen period = ""
foreach num of numlist 1(1)12 {
    if `num'<10 {
        replace period = "M0`num'" if conceptionMonth == `num'
    }
    else {
        replace period = "M`num'"  if conceptionMonth == `num'
    }
}
merge m:1 fips year period using "$UNE/unemployment"
*MERGE = 1 are people who don't have gestation recorded so no conception month
*MERGE = 2 are periods before the sample where unemployment is irrelevant
*MERGE = 3 are correct merges.  This is 99.75% of the sample
drop if _merge==2 
drop v8 _merge notes

********************************************************************************
*** (5) Label variables
********************************************************************************
lab def aG  1 "25-39" 2 "40-45"
lab def gQ  0 "quarter 4(t) or quarter 1(t+1)" 1 "quarter 2(t) or quarter 3(t)"
lab def eL  1 "No College" 2 "1-5 years" 
lab val ageGroup    aG
lab val goodQuarter gQ

lab var goodQuarter        "Good Season"
lab var expectGoodQ        "Good Expect"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Aged 25-39"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var ageGroup           "Categorical age group"
lab var youngXbadQ         "Young$\times$ Bad S"
lab var highEdXbadQ        "College$\times$ Bad S"
lab var youngXhighEdXbadQ  "Young$\times$ College$\times$ Bad S"
lab var youngManXbadQ      "Young Man$\times$ Bad S"
lab var vhighEd            "Complete Degree"
lab var youngXvhighEd      "Degree$\times$ Aged 25-39"
lab var age2534            "Aged 25-34"
lab var age2527            "Aged 25-27"
lab var age2831            "Aged 28-31"
lab var age3239            "Aged 32-39"
lab var age3539            "Aged 35-39"
lab var age4045            "Aged 40-45"
lab var age2534XhighEd     "Aged 25-34 $\times$ Some College"
lab var age3539XhighEd     "Aged 35-39 $\times$ Some College"
lab var age2527XhighEd     "Aged 25-27 $\times$ Some College"
lab var age2831XhighEd     "Aged 28-31 $\times$ Some College"
lab var age3239XhighEd     "Aged 32-39 $\times$ Some College"
lab var teenage            "Aged 15-19"
lab var married            "Married"
lab var smoker             "Smoked in Pregnancy"
lab var noPreVisit         "No Prenatal Visits"
lab var prenate3months     "Prenatal 1\textsuperscript{st} Trimester"
lab var apgar              "APGAR"
lab var birthweight        "Birthweight"
lab var gestation          "Gestation"
lab var lbw                "LBW"
lab var premature          "Premature"
lab var vlbw               "VLBW"
lab var prematurity        "Weeks premature"
lab var monthsPrem         "Months Premature"
lab var badExpectGood      "Bad Season (due in good)"
lab var badExpectBad       "Bad Season (due in bad)"
lab var Qgoodbad           "Bad Season (due in good)"
lab var Qbadbad            "Bad Season (due in bad)"
lab var Qbadgood           "Good Season (due in bad)"
lab var motherAge          "Mother's Age (years)"
lab var motherAge2         "Mother's Age$^2$"
lab var noART              "Did not undergo ART"
lab var noARTyoung         "No ART$\times$ Young"
lab var age2024            "Aged 20-24"
lab var ARTage2024         "Aged 20-24$\times$ ART"
lab var motherAgeXeduc     "Mother's Age $\times$ Education"
lab var educCat            "Years of Education"
lab var value              "Unemployment Rate"
lab var WIC                "Received WIC food in Pregnancy"
lab var Presmoker          "Smoked 3 months prior to Pregnancy"
lab var BMI                "BMI"
lab var BMIsq              "BMI Squared"
lab var underweight        "Underweight (BMI $<$ 18.5)"
lab var overweight         "Overweight (BMI 25-30)"
lab var obese              "Obese (BMI $\geq$ 30)" 
lab var hispanic           "Hispanic"
lab var black              "Black"
lab var white              "White"
lab var goodQuarter        "Proportion good season"
lab var cold               "Coldest monthly average (degree F)"
lab var hot                "Warmest monthly average (degree F)"
lab var Tvariation         "Annual Variation in Temperature (degree F)"
lab var meanT              "Mean monthly temperature (degree F)"

********************************************************************************
*** (6) Save, clean
********************************************************************************
if `nohisp'==1&`noblack'==1 {
    lab dat "NVSS birth data 2005-2013 (first births, white, 25-45 year olds)"
    save "$OUT/nvss2005_2013.dta", replace
}
if `nohisp'==0&`noblack'==1 {
    lab dat "NVSS birth data 2005-2013 (first births, white/hisp, 25-45 years)"
    save "$OUT/nvss2005_2013_hisp.dta", replace
}
if `nohisp'==0&`noblack'==0 {
    lab dat "NVSS birth data 2005-2013 (first births, 25-45 years)"
    save "$OUT/nvss2005_2013_all.dta", replace
}


exit
********************************************************************************
*** (6a) 1998 File
********************************************************************************
global DAT "~/database/NVSS/Births/dta"
use "$DAT/natl1998"

gen married     = dmar==1
gen single      = married==0&fage11==11
gen birthOrder  = dlivord
gen motherAge   = dmage
gen fatherAge   = fage11
gen birthMonth  = birmon
gen year        = biryr
gen twin        = dplural
gen birthweight = dbirwt if dbirwt>=500 & dbirwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = fmaps if fmaps>=0 & fmaps <=10
gen gestation   = dgestat if dgestat!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = cigar>0 if cigar < 99
gen female      = csex==2
gen numPrenatal = nprevis if nprevis != 99
gen monthPrenat = monpre

keep if birthOrder<=2 & (motherAge>=15 & motherAge<=45)
keep if mrace == 1 & ormoth == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fage11>6 & fage11 != 11
replace ageGroupMan = ageGroupMan + 1

gen educLevel = dmeduc >= 13
replace educLevel = 2 if dmeduc >= 16
replace educLevel = . if dmeduc == 99

gen education = dmeduc if dmeduc != 99

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar        /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth gestation numPrenatal monthPrenat birthOrder statenat    /*
*/ stoccfip stresfip stateres
tempfile B1998
save `B1998'

********************************************************************************
*** (6b) 1999 File
********************************************************************************
use "$DAT/natl1999"

gen married     = dmar==1
gen single      = married==0&fage11==11
gen birthOrder  = dlivord
gen motherAge   = dmage
gen fatherAge   = fage11
gen birthMonth  = birmon
gen year        = biryr
gen twin        = dplural
gen birthweight = dbirwt if dbirwt>=500 & dbirwt <= 5000
gen vlbw        = birthweight < 1500 if birthweight != .
gen lbw         = birthweight < 2500 if birthweight != .
gen apgar       = fmaps if fmaps>=0 & fmaps <=10
gen gestation   = dgestat if dgestat!=99
gen premature   = gestation < 37 if gestation != .
gen smoker      = cigar>0 if cigar < 99
gen female      = csex==2
gen numPrenatal = nprevis if nprevis != 99
gen monthPrenat = monpre

keep if birthOrder<=2 & (motherAge>=15 & motherAge<=45)
keep if mrace == 1 & ormoth == 0

gen birthQuarter = ceil(birthMonth/3)

gen ageGroup = motherAge>=25 & motherAge <=34
replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

gen ageGroupMan = fage11>6 & fage11 != 11
replace ageGroupMan = ageGroupMan + 1

gen educLevel = dmeduc >= 13
replace educLevel = 2 if dmeduc >= 16
replace educLevel = . if dmeduc == 99

gen education = dmeduc if dmeduc != 99

keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar        /*
*/ premature motherAge education fatherAge ageGroupMan married smoker single  /*
*/ female birthMonth gestation numPrenatal monthPrenat birthOrder statenat    /*
*/ stoccfip stresfip stateres
tempfile B1999
save `B1999'


********************************************************************************
*** (7) Append to 1998, 1999 file, save
********************************************************************************
clear
append using `B1998' `B1999'

lab dat "NVSS birth data 1998-1999 (1st and 2nd births, white, 15-45 year olds)"
save "$OUT/nvss1998_1999.dta", replace

exit
********************************************************************************
*** (8) 1990s File
********************************************************************************
foreach year of numlist 1990(1)1999 {
    use "$DAT/natl`year'"

    gen married     = dmar==1
    gen single      = married==0&fage11==11
    gen birthOrder  = dlivord
    gen motherAge   = dmage
    gen fatherAge   = fage11
    gen birthMonth  = birmon
    gen year        = biryr
    gen twin        = dplural
    gen birthweight = dbirwt if dbirwt>=500 & dbirwt <= 5000
    gen vlbw        = birthweight < 1500 if birthweight != .
    gen lbw         = birthweight < 2500 if birthweight != .
    gen apgar       = fmaps if fmaps>=0 & fmaps <=10
    gen gestation   = dgestat if dgestat!=99
    gen premature   = gestation < 37 if gestation != .
    gen smoker      = cigar>0 if cigar < 99
    gen female      = csex==2
    gen numPrenatal = nprevis if nprevis != 99
    gen monthPrenat = monpre

    keep if birthOrder<=2 & (motherAge>=20 & motherAge<=45)
    keep if mrace == 1 & ormoth == 0
    
    gen birthQuarter = ceil(birthMonth/3)

    gen ageGroup = motherAge>=25 & motherAge <=34
    replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
    replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

    gen ageGroupMan = fage11>6 & fage11 != 11
    replace ageGroupMan = ageGroupMan + 1

    gen educLevel = dmeduc >= 13
    replace educLevel = 2 if dmeduc >= 16
    replace educLevel = . if dmeduc == 99

    gen education = dmeduc if dmeduc != 99

    foreach var of varlist statenat stoccfip stresfip stateres {
        tostring `var', replace
        foreach num of numlist 1(1)9 {
            replace `var' = "0`num'" if `var'=="`num'"
        }
    }
        
    
    
    keep birthQuarter ageGroup educLevel twin year birthwei vlbw lbw apgar      /*
    */ premature motherAge education fatherAge ageGroupMan married smoker single/*
    */ female birthMonth gestation numPrenatal monthPrenat birthOrder statenat  /*
    */ stoccfip stresfip stateres
    tempfile B`year'
    save `B`year''
}
clear
append using `B1990' `B1991' `B1992' `B1993' `B1994', force
append using `B1995' `B1996' `B1997' `B1998' `B1999', force

lab dat "NVSS birth data 1990s (first births, white, 25-45 year olds)"
save "$OUT/nvss1990s.dta", replace

********************************************************************************
*** (9) 1970s File
********************************************************************************
foreach year of numlist 1971(1)1979 {
    use "$DAT/natl`year'"

    if `year'<1978  gen married     = dlegit==1 if dlegit < 8
    if `year'>1977  gen married     = mar2 == 1
    gen birthOrder  = dlivord
    gen motherAge   = dmage
    gen fatherAge   = fage11
    gen birthMonth  = birmon
    gen year        = `year'
    gen twin        = dplural
    gen birthweight = dbirwt if dbirwt>=500 & dbirwt <= 5000
    gen vlbw        = birthweight < 1500 if birthweight != .
    gen lbw         = birthweight < 2500 if birthweight != .
    gen gestation   = dgestat if dgestat!=99&dgestat!=0
    gen premature   = gestation < 37 if gestation != .
    *gen smoker      = cigar>0 if cigar < 99
    gen female      = csex==2
    gen sampWeight  = 1
    cap replace sampWeight = recwt
    
    keep if birthOrder<=2 & (motherAge>=20 & motherAge<=45)
    keep if mrace == 1
    
    gen birthQuarter = ceil(birthMonth/3)

    gen ageGroup = motherAge>=25 & motherAge <=34
    replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
    replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

    gen ageGroupMan = fage11>6 & fage11 != 11
    replace ageGroupMan = ageGroupMan + 1

    gen educLevel = dmeduc >= 13
    replace educLevel = 2 if dmeduc >= 16
    replace educLevel = . if dmeduc == 99

    gen education = dmeduc if dmeduc != 99

    keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw     /*
    */ premature motherAge education fatherAge ageGroupMan married female   /*
    */ birthMonth gestation birthOrder statenat stateres sampWeight
    tempfile B`year'
    save `B`year''
}
clear
append using         `B1971' `B1972' `B1973' `B1974', force
append using `B1975' `B1976' `B1977' `B1978' `B1979', force

lab dat "NVSS birth data 1970s (first births, white, 25-45 year olds)"
save "$OUT/nvss1970s.dta", replace

    
********************************************************************************
*** (10) 1980s File
********************************************************************************
foreach year of numlist 1980(1)1989 {
    use "$DAT/natl`year'"

    if `year'>1988  gen married     = dmar == 1
    if `year'<1989  gen married     = mar2 == 1
    gen birthOrder  = dlivord
    gen motherAge   = dmage
    gen fatherAge   = fage11
    gen birthMonth  = birmon
    gen year        = `year'
    gen twin        = dplural
    gen birthweight = dbirwt if dbirwt>=500 & dbirwt <= 5000
    gen vlbw        = birthweight < 1500 if birthweight != .
    gen lbw         = birthweight < 2500 if birthweight != .
    gen gestation   = dgestat if dgestat!=99&dgestat!=0
    gen premature   = gestation < 37 if gestation != .
    *gen smoker      = cigar>0 if cigar < 99
    gen female      = csex==2
    gen sampWeight  = 1
    cap replace sampWeight = recwt
    
    keep if birthOrder<=2 & (motherAge>=20 & motherAge<=45)
    keep if mrace == 1
    
    gen birthQuarter = ceil(birthMonth/3)

    gen ageGroup = motherAge>=25 & motherAge <=34
    replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
    replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45

    gen ageGroupMan = fage11>6 & fage11 != 11
    replace ageGroupMan = ageGroupMan + 1

    gen educLevel = dmeduc >= 13
    replace educLevel = 2 if dmeduc >= 16
    replace educLevel = . if dmeduc == 99

    gen education = dmeduc if dmeduc != 99

    keep birthQuarter ageGroup educLevel twin year birthweight vlbw lbw     /*
    */ premature motherAge education fatherAge ageGroupMan married female   /*
    */ birthMonth gestation birthOrder statenat stateres sampWeight
    tempfile B`year'
    save `B`year''
}
clear
append using `B1980' `B1981' `B1982' `B1983' `B1984', force
append using `B1985' `B1986' `B1987' `B1988' `B1989', force

lab dat "NVSS birth data 1980s (first births, white, 25-45 year olds)"
save "$OUT/nvss1980s.dta", replace
