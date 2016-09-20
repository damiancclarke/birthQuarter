/* conjointImportMain.do v0.00    damiancclarke            yyyy-mm-dd:2016-09-19
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8


*/

vers 11
clear all
set more off
cap log close


*-------------------------------------------------------------------------------
*-- (1) globals and locals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/survey/conjoint-main"
global LOG "~/investigacion/2015/birthQuarter/log"
global USG "~/investigacion/2015/birthQuarter/data/weather"

log using "$LOG/conjointImportMain.do", text replace

foreach ado in geo2xy {
    cap which `ado'
    if _rc!=0 ssc install `ado'
}

*-------------------------------------------------------------------------------
*-- (2) Import
*-------------------------------------------------------------------------------   
insheet using "$DAT/conjointResponse.csv", delim(";") names clear
*FIX ONE PERSON'S TYPO
replace mturkcode = 263905 if mturkcode==2639053
*KEEP ONLY FIRST SURVEY FROM PERSON WHO HAD TO DO RE-DO IT
replace mturkcode = 99999999 if mturkcode== 7530533
replace mturkcode = 7530533 if mturkcode == 8215989

rename mturkcode answersurveycode
merge m:1 answersurveycode using "$DAT/MTurkResults", gen(_mergeMTQT)
keep if _mergeMTQT==3

drop if answersurveycode==.
gen ID = _n
rename qid3    RespSex
rename qid5_1  RespYOB
rename qid87_1 RespState
rename qid11   RespEduc
rename qid188  RespMarital
rename qid74   RespRace
rename qid75   RespHisp
rename qid86   RespEducCheck
rename qid76   RespEmployment
rename qid77   RespOccupation
rename qid12   RespNumKids
rename qid126  RespPregnant
rename qid141  RespPlansKids
rename qid169  RespMoreKids
rename qid166  RespKidUSBorn
rename qid167  RespKidGender
rename qid168  RespKidBMonth
rename qid189_1 RespKidBYear
rename qid190  RespTargetMonth
rename qid191  RespTargetWhich
rename qid78   RespMTurkType
rename qid79   RespMTurkSalary
rename qid82   RespSalary
rename qid192  RespSure

drop qid58
split startdate, gen(start)
split enddate  , gen(end)
split start2   , gen(stime) parse(:) destring
split end2     , gen(etime) parse(:) destring

rename start1 surveyStartDate
rename end1   surveyEndDate
rename start2 surveyStartTime
rename end2   surveyEndTime

gen surveyTime = etime2-stime2 + (etime1-stime1)*60 + (etime3-etime2)/60
gen surveyTimeMin = floor(surveyTime)
gen surveyTimeSec = round((surveyTime - surveyTimeMin)*60)

drop stime* etime*
    

count
local Numb = r(N)
rename locationlatitude latitude
rename locationlongitude longitude

gen address = ""
foreach num of numlist 1(1)1600 {
    sum latitude in `num'
    if `r(N)'!=0 {
        local lat = `r(mean)'
        sum longitude in `num'
        local long = `r(mean)'
        gcode_dcc `lat',`long'
        cap replace address = "`r(address)'" in `num'
    }
}
foreach num of numlist 1601(1)`Numb' {
    sum latitude in `num'
    if `r(N)'!=0 {
        local lat = `r(mean)'
        sum longitude in `num'
        local long = `r(mean)'
        gcode_dcc `lat',`long'
        cap replace address = "`r(address)'" in `num'
    }
}
lab var address "Address based on GEOcode (google maps search)"
split address, generate(_add) parse(",")
gen country = _add7
replace country = _add6 if country==""
replace country = _add5 if country==""
replace country = _add4 if country==""
replace country = _add3 if country==""
replace country = _add2 if country==""
replace country = subinstr(country, " ", "", 1)
gen notUSA = country !="USA"
gen stateGEO = _add3 if notUSA==0
replace stateGEO = _add4 if stateGEO==" Buffalo"
replace stateGEO = _add4 if stateGEO==" Charlottesville"
rename country countryGEO

geo2xy latitude longitude, gen(lat2 long2) projection(albers)
geo2xy latitude longitude, gen(lat3 long3) projection(web_mercator)

lab var lat2       "Albers projection of latitude (mapping only)"
lab var long2      "Albers projection of longitude (mapping only)"
lab var lat3       "Web Mercator projection of latitude (mapping only)"
lab var long3      "Web Mercator projection of longitude (mapping only)"

preserve
insheet using $USG/usaWeather.txt, names delim(";") clear
keep if year==2013
collapse temp (min) minTemp=temp (max) maxTemp=temp, by(state)
rename state stateString

tempfile temperature
save `temperature'
restore
gen stateString = RespState


merge m:1 stateString using `temperature'
replace temp = 54.71944 if stateS=="District of Columbia"
replace minTemp = 26.5 if stateS=="District of Columbia"
replace maxTemp = 86.5 if stateS=="District of Columbia"
drop if _merge==2
drop _merge

save "$DAT/conjointMergedAddresses", replace

use "$DAT/conjointMergedAddresses", clear


preserve
keep if qid173!=""
drop g*
rename qid173 ffid1
rename qid174 ffid2
rename qid175 ffid3
rename qid176 ffid4
rename qid177 ffid5
rename qid178 ffid6
rename qid179 ffid7
drop qid181-qid187

foreach round of numlist 1(1)7 {
    foreach aspect of numlist 1 2 3 4 {
        rename f`round'`aspect' ff`aspect'`round'
        foreach choice of numlist 1 2 {
            rename f`round'`choice'`aspect' ff`aspect'c`choice'`round'
        }
    }
}

local qs ff1 ff2 ff3 ff4 ff5
local cs ff1c1 ff2c1 ff3c1 ff4c1 ff1c2 ff2c2 ff3c2 ff4c2 
reshape long ffid `qs' `cs', i(ID) j(round)
reshape long ff1c ff2c ff3c ff4c ff5c, i(ID round ) j(option)


foreach var in cost birthweight gender sob {
    gen `var'=""
    gen `var'_position=.
}

local cost "Out of Pocket Expenses"
foreach n of numlist 1(1)4{
    replace cost          = ff`n'c if ff`n'==`"`cost'"'
    replace cost_p        = `n'    if ff`n'==`"`cost'"'
    replace birthweight   = ff`n'c if ff`n'=="Birth Weight"
    replace birthweight_p = `n'    if ff`n'=="Birth Weight"
    replace sob           = ff`n'c if ff`n'=="Season of Birth"
    replace sob_p         = `n'    if ff`n'=="Season of Birth"
    replace gender        = ff`n'c if ff`n'=="Gender"
    replace gender_p      = `n'    if ff`n'=="Gender"
}

rename ffid chooses
gen chosen = (chooses=="Scenario 1"&option==1)|(chooses=="Scenario 2"&option==2)
drop o1 o2 o3 o4

save "$DAT/conjointBWgroup.dta", replace
restore


preserve
keep if qid181!=""
drop f*
rename qid181 ggid1
rename qid182 ggid2
rename qid183 ggid3
rename qid184 ggid4
rename qid185 ggid5
rename qid186 ggid6
rename qid187 ggid7
drop qid173-qid179

foreach round of numlist 1(1)7 {
    foreach aspect of numlist 1 2 3 4 {
        rename g`round'`aspect' gg`aspect'`round'
        foreach choice of numlist 1 2 {
            rename g`round'`choice'`aspect' gg`aspect'c`choice'`round'
        }
    }
}

local qs gg1 gg2 gg3 gg4
local cs gg1c1 gg2c1 gg3c1 gg4c1 gg1c2 gg2c2 gg3c2 gg4c2 
reshape long ggid `qs' `cs', i(ID) j(round)
reshape long gg1c gg2c gg3c gg4c, i(ID round) j(option)


foreach var in cost dob gender sob {
    gen `var'=""
    gen `var'_position=.
}

local cost "Out of Pocket Expenses"
foreach n of numlist 1(1)4 {
    replace cost          = gg`n'c if gg`n'==`"`cost'"'
    replace cost_p        = `n'    if gg`n'==`"`cost'"'
    replace dob           = gg`n'c if gg`n'=="Day of Birth"
    replace dob_p         = `n'    if gg`n'=="Day of Birth"
    replace sob           = gg`n'c if gg`n'=="Season of Birth"
    replace sob_p         = `n'    if gg`n'=="Season of Birth"
    replace gender        = gg`n'c if gg`n'=="Gender"
    replace gender_p      = `n'    if gg`n'=="Gender"
}

rename ggid chooses
gen chosen = (chooses=="Scenario 1"&option==1)|(chooses=="Scenario 2"&option==2)
drop n1 n2 n3 n4

save "$DAT/conjointDOBgroup.dta", replace
restore
