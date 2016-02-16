/* spainPrep.do v1.00            damiancclarke             yyyy-mm-dd:2015-05-23
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

local d2007 "A2007.ANONIMINACIMI.TXT"
local d2008 "NACIMIENTOS.A2008"
local d2009 "nacimientos A2009.txt"
local d2010 "NACIMIENTOS A2010.txt"
local d2011 "datos_nacimientos11.txt"
local d2012 "datos_nacimientos12.txt"
local d2013 "Anonimizado Nacimientos sin causa A2013.txt"


foreach year of numlist 2007(1)2013 {
    *---------------------------------------------------------------------------
    *--- (2a) Import, destring
    *---------------------------------------------------------------------------
    infile using "$DIC/spainNac0713.dct", using("$DAT/`year'/`d`year''") clear

    foreach var of varlist mes* estudio* cauto* {
        destring `var', replace
    }

    *---------------------------------------------------------------------------
    *--- (2b) Generate variables
    *---------------------------------------------------------------------------
    gen singleton     = multipli == 1
    gen twin          = multipli == 2
    gen premature     = intersem == 2
    gen gestation     = semanas
    gen birthweight   = peso if peso>=500 & peso<=5000
    gen lbw           = peso < 2500 if birthweight != .
    gen vlbw          = peso < 1500 if birthweight != .
    gen married       = ecivm == 1
    gen single        = ecivm == 2
    gen cesarean      = cesarea == 1
    gen survived1day  = clasif == 3
    gen female        = sexo == 6
    gen birthYear     = `year'
    gen marBirth      = (anopar*12+mespar)-(anomat*12+mesmat)
    gen marrPreBirth  = married==1 & marBirth > 8
    gen preDeaths     = numh-numhv
    
    gen birthQuarter  = ceil(mespar/3)

    rename multipli multipleBirth
    rename mespar   birthMonth
    rename sordenv  birthOrder
    rename nacioem  motherSpanish
    rename ecivm    civilStatus
    rename estudiom educationMother
    rename estudiop educationFather
    rename cautom   professionMother
    rename cautop   professionFather
    rename edadm    motherAge
    rename edadp    fatherAge
    rename proi     inscriptionProvince
    rename muni     inscriptionMunicip
    rename munpar   birthMunicip
    rename propar   birthProvince
    rename paisnacm motherNationality
    rename paisnxm  motherBirthCountry
    
    foreach parent in Mother Father {
        gen yrsEduc`parent' = 0 if education`parent'==1|education`parent'==2
        replace yrsEduc`parent' = 5 if education`parent'==3
        replace yrsEduc`parent' = 8 if education`parent'==4
        replace yrsEduc`parent' = 10 if education`parent'==6
        replace yrsEduc`parent' = 12 if education`parent'==5
        replace yrsEduc`parent' = 13 if education`parent'==7
        replace yrsEduc`parent' = 15 if education`parent'==8
        replace yrsEduc`parent' = 17 if education`parent'==9
        replace yrsEduc`parent' = 17 if education`parent'==10
    }
    
    keep if birthOrder <= 2 & multipleBirth <= 2
    *-------------------------------------------------------------------------------
    *--- (2c) Variable labels
    *-------------------------------------------------------------------------------
    #delimit ;
    lab drop _all;
    lab def cs   1 "Married" 2 "Single" 3 "Seperated/Divorced" 4 "Widowed" ;
    lab def educ 1 "Illiterate" 2 "Less than 5 years" 3 "Incomplete EGB/ESO/Primary"
                 4 "Complete Primary" 5 "Secondary Bachelor" 6 "Secondary"
                 7 "Tertiary 1" 8 "Tertiary 2" 9 "Tertiary 3" 10 "PhD" 0 "N/A";
    lab def job  1 "Armed Forces" 2 "Public admin, business manager" 
                 3 "High rank science/intellectual worker"
                 4 "Low rank technician/professional" 5 "Administrative" 
                 6 "Hospitality and Tourism" 7 "Agriculture and fisheries"
                 8 "Construction (artesan)"  9 "Machine operators"
                 10 "Unskilled workers" 11 "Students" 
                 12 "Housework related" 13 "Pension/rents"; 

    lab val civilStatus cs;
    lab val education* educ;
    lab val profession* job;
    gen year = `year';
    
    keep birthOrder multipleBirth birthMonth singleton twin premature gestation
    lbw vlbw inscription* birthMu birthP married single cesarean survived1day
    female motherSp* civilStatus education* profession* motherAge fatherAge yrs*
    year birthQuarter birthweight marBirth marrPreBirth preDeaths motherBirthC
    motherNationality;
    #delimit cr

    tempfile f`year'
    save `f`year''
}

*-------------------------------------------------------------------------------
*--- (3a) Append, generate
*-------------------------------------------------------------------------------
clear
append using `f2007' `f2008' `f2009' `f2010' `f2011' `f2012' `f2013'

gen id = birthProvince
destring id, replace
merge m:1 id using "$OUT/temperature2012"
drop _merge
replace gestation = . if gestation == 0


gen goodQuarter         = birthQuarter == 2 | birthQuarter == 3
gen badQuarter          = birthQuarter == 1 | birthQuarter == 4
gen college             = educationMother>6 if educationMother!=.&educationM!=0
gen highEd              = yrsEducMother> 12 if yrsEducMother !=.
gen young               = motherAge >= 25   & motherAge    <= 40
gen youngXhighEd        = young*highEd
gen age2024             = motherAge>=20&motherAge<=24
gen age2527             = motherAge>=25 & motherAge <28
gen age2831             = motherAge>=28 & motherAge <32
gen age3239             = motherAge>=32 & motherAge <40
gen age4045             = motherAge>=40 & motherAge <46
gen motherAge2          = motherAge*motherAge
gen motherAgeXeduc      = motherAge*yrsEducMother
gen age2527XhighEd      = age2527*highEd
gen age2831XhighEd      = age2831*highEd
gen age3239XhighEd      = age3239*highEd
gen prematurity         = gestation - 39 
gen monthsPrem          = round(prematurity/4)*-1
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
egen    cold            = rowmin(enero-diciembre)
egen    hot             = rowmax(enero-diciembre)
egen    meanTemp        = rowmean(enero-diciembre)

gen     conceptionMonth = birthMonth - round(gestation*7/30.5)
replace conceptionMonth = conceptionMonth + 12 if conceptionMonth<1

drop goodQuarter badQuarter
gen goodQuarter = expectGoodQ
gen badQuarter  = expectBadQ
tab year, gen(_year)

rename yrsEducMother educCat
*-------------------------------------------------------------------------------
*--- (3b) Label variables
*-------------------------------------------------------------------------------
lab var goodQuarter        "Good Season"
lab var expectGoodQ        "Good Expect"
lab var badQuarter         "Bad Season"
lab var highEd             "Some College +"
lab var young              "Aged 25-39"
lab var youngXhighEd       "College$\times$ Aged 25-39"
lab var age2024            "Aged 20-24"
lab var age2527            "Aged 25-27"
lab var age2831            "Aged 28-31"
lab var age3239            "Aged 32-39"
lab var age4045            "Aged 40-45"
lab var married            "Married"
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
lab var motherAge          "Mother's Age"
lab var motherAge2         "Mother's Age$^2$"
lab var motherAgeXeduc     "Mother's Age $\times$ Education"
lab var educCat            "Years of Education"
lab var age2527XhighEd     "Aged 25-27 $\times$ Some College +"
lab var age2831XhighEd     "Aged 28-31 $\times$ Some College +"
lab var age3239XhighEd     "Aged 32-39 $\times$ Some College +"
    
*-------------------------------------------------------------------------------
*--- (X) Save
*-------------------------------------------------------------------------------
lab data "Spain administrative births.  Imported and cleaned by damianclarke."
save "$OUT/births2007-2013", replace
