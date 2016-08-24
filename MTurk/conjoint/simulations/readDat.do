* NB: f-ROUND-CHARACTERISTIC
* NB: f-ROUND-OPTION-CHARACTERISTIC

insheet using DecisionsSim2.csv, comma names clear
gen ID = _n

foreach num of numlist 1 3 4 5 6 7 8 {
    local n1 = `num'
    if `num'!=1 local n1 = `num'-1
    rename qid`num' qid`n1'
}

foreach round of numlist 1(1)6 {
    foreach aspect of numlist 1 2 3 4 5 {
        rename f`round'`aspect' q`aspect'`round'
        foreach choice of numlist 1 2 {
            rename f`round'`choice'`aspect' q`aspect'c`choice'`round'
        }
    }
}
local qs q1 q2 q3 q4 q5
local cs q1c1 q2c1 q3c1 q4c1 q5c1 q1c2 q2c2 q3c2 q4c2 q5c2
reshape long qid `qs' `cs', i(ID) j(round)
reshape long q1c q2c q3c q4c q5c, i(ID round) j(option)
drop recip* extern

foreach var in cost premature gender sob dob {
    gen `var'=""
}

local cost "Monetary costs not covered by health insurance"
foreach n of numlist 1(1)5{
    replace cost      = q`n'c if q`n'==`"`cost'"'
    replace premature = q`n'c if q`n'=="Premature?"
    replace sob       = q`n'c if q`n'=="Season of Birth"|q`n'=="Season of birth"
    replace gender    = q`n'c if q`n'=="Gender"
    replace dob       = q`n'c if q`n'=="Day of Birth"
}
rename qid chooses
drop q*

destring cost, replace
gen chosen = (chooses=="Choice 1"&option==1)|(chooses=="Choice 2"&option==2)

xi: reg chosen i.gender i.cost i.premature i.dob i.sob
xi: reg chosen i.gender i.cost i.premature i.dob i.sob i.round
