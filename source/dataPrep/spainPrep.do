/*spainPrep.do v0.00             damiancclarke             yyyy-mm-dd:2015-05-23
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Read in fixed width birth file from Spain using the dictionary file spainNac.dct
then attach labels as described in the online data description files from INE's
site: http://www.ine.es/en/prodyser/micro_mnp_nacim_en.htm

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Globals
*-------------------------------------------------------------------------------
global DAT "~/database/Spain/nacimientos"
global DIC "~/investigacion/2015/birthQuarter/source/dataPrep"
global OUT "~/investigacion/2015/birthQuarter/data/spain"

local data "Anonimizado Nacimientos sin causa A2013.txt"

*-------------------------------------------------------------------------------
*--- (2a) Import, destring
*-------------------------------------------------------------------------------
infile using "$DIC/spainNac.dct", using("$DAT/`data'")

foreach var of varlist mes* estudiom cautom {
    destring `var', replace
}

*-------------------------------------------------------------------------------
*--- (2) Generate variables
*-------------------------------------------------------------------------------
gen singleton     = multipli == 1
gen twin          = multipli == 2
gen premature     = intersem == 2
gen gestation     = semanas
gen birthweight   = peso if peso>=500 & peso<=5000
gen lbw           = peso < 2500 if peso != .
gen vlbw          = peso < 1500 if peso != .
gen married       = ecivm == 1
gen single        = ecivm == 2
gen cesarean      = cesarea == 1
gen survived1day  = clasif == 1
gen female        = sexo == 6

gen birthQuarter  = ceil(mespar/3)
gen goodQuarter   = birthQuarter == 2 | birthQuarter == 3
gen badQuarter    = birthQuarter == 1 | birthQuarter == 4

rename multipli multipleBirth
rename mespar   monthBirth
rename numhvt   parity
rename nacioem  motherSpanish
rename ecivm    civilStatus
rename estudiom educationMother
rename estudiop educationFather
rename cautom   professionMother
rename cautop   professionFather
rename edadm    ageMother
rename edadp    ageFather
rename proi     inscriptionProvince
rename muni     inscriptionMunicip
rename munpar   birthMunicip
rename propar   birthProvince

foreach parent in Mother Father {
    gen yrsEduc`parent' = 0 if education`parent'==1|education`parent'==2
    replace yrsEduc`parent' = 5 if education`parent'==3
    replace yrsEduc`parent' = 8 if education`parent'==4
    replace yrsEduc`parent' = 10 if education`parent'==6
    replace yrsEduc`parent' = 12 if education`parent'==5
    replace yrsEduc`parent' = 13 if education`parent'==7
    replace yrsEduc`parent' = 15 if education`parent'==8
    replace yrsEduc`parent' = 17 if education`parent'==9|education`parent'==10
}
    
*-------------------------------------------------------------------------------
*--- (3) Variable labels
*-------------------------------------------------------------------------------
#delimit ;
lab def cs   1 "Married" 2 "Single" 3 "Seperated/Divorced" 4 "Widowed" ;
lab def educ 1 "Illiterate" 2 "Less than 5 years" 3 "Incomplete EGB/ESO/Primary"
             4 "Complete Primary" 5 "Secondary Bachelor" 6 "Tertiary?"
             7 "Tertiary?" 8 "Tertiary?" 9 "Tertiary?" 10 "PhD";
lab def job  1 "Armed Forces" 2 "Public admin, business director" 3 "Intellectual"
             4 "Technician" 5 "Administrative offices" 6 "Restauration"
             7 "Agriculture" 8 "Construction (artesan)" 9 "Machine operators"
             10 "Unqualified workers" 11 "Students" 12 "Home work"
             13 "Pension/rents"; 

lab val civilStatus cs;
lab val education* educ;
lab val profession* job;

keep parity multipleBirth monthBirth singleton twin premature gestation lbw vlbw
inscription* birthM birthP married single cesarean survived1day female motherSp*
civilStatus education* profession* age* birthQuarter goodQuarter badQuarter yrs*;
#delimit cr


*-------------------------------------------------------------------------------
*--- (X) Save
*-------------------------------------------------------------------------------
lab data "Spain administrative births.  Imported and cleaned by damianclarke."
save "$OUT/births2013"
