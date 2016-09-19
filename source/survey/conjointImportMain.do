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

log using "$LOG/conjointImportMain.do", text replace

*-------------------------------------------------------------------------------
*-- (2) Import
*-------------------------------------------------------------------------------   
insheet using "$DAT/conjointResponse.csv", delim(";") names clear
drop if mturkcode==.
gen ID = _n

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
reshape long ff1c ff2c ff3c ff4c ff5c, i(ID round) j(option)


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











