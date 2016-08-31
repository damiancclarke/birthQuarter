* NB: f-ROUND-CHARACTERISTIC
* NB: f-ROUND-OPTION-CHARACTERISTIC

insheet using DecisionSim5.csv, delim(";") names clear
gen ID = _n

drop qid17 qid20 qid21_1 qid22 qid30 qid31 qid32
rename qid23 qid1
rename qid24 qid2
rename qid25 qid3
rename qid26 qid4
rename qid27 qid5
rename qid28 qid6
rename qid29 qid7

foreach round of numlist 1(1)7 {
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


foreach var in cost birthweight gender sob dob {
    gen `var'=""
    gen `var'_position=.
}

local cost "Out of pocket expenses"
foreach n of numlist 1(1)5{
    replace cost          = q`n'c if q`n'==`"`cost'"'
    replace cost_p        = `n'   if q`n'==`"`cost'"'
    replace birthweight   = q`n'c if q`n'=="Birth weight"
    replace birthweight_p = `n'   if q`n'=="Birth weight"
    replace sob           = q`n'c if q`n'=="Month of Birth"
    replace sob_p         = `n'   if q`n'=="Month of Birth"
    replace gender        = q`n'c if q`n'=="Gender"
    replace gender_p      = `n'   if q`n'=="Gender"
    replace dob           = q`n'c if q`n'=="Day of Birth"
    replace dob_p         = `n'   if q`n'=="Day of Birth"
}
rename qid chooses
drop q* mturkcode

    
destring cost, replace
gen chosen = (chooses=="Birth Outcome 1"&option==1)|(chooses=="Birth Outcome 2"&option==2)

lab dat "Simulated data with no patterns"
save "simulatedBase_1000", replace


