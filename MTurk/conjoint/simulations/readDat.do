* NB: f-ROUND-CHARACTERISTIC
* NB: f-ROUND-OPTION-CHARACTERISTIC

insheet using DecisionsSim3.csv, comma names clear
gen ID = _n

foreach num of numlist 1 3 4 5 6 7 {
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


foreach var in cost eyecolor gender sob dob {
    gen `var'=""
}

local cost "Out+AC0-of+AC0-pocket expenses for a hospital no+AC0-complication birth"
foreach n of numlist 1(1)5{
    replace cost      = q`n'c if q`n'==`"`cost'"'
    replace eyecolor  = q`n'c if q`n'=="Eye color"
    replace sob       = q`n'c if q`n'=="Month of Birth"
    replace gender    = q`n'c if q`n'=="Gender"
    replace dob       = q`n'c if q`n'=="Day of Birth"
}
rename qid chooses
drop q*

destring cost, replace
gen chosen = (chooses=="Choice 1"&option==1)|(chooses=="Choice 2"&option==2)

lab dat "Simulated data with no patterns"
save "simulatedBase", replace


xi: reg chosen i.gender i.cost i.eyecolor i.dob i.sob, cluster(ID)
xi: reg chosen i.gender i.cost i.eyecolor i.dob i.sob i.round, cluster(ID)
