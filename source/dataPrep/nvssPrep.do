/* nvssPrep.do v0.0              damiancclarke             yyyy-mm-dd:2015-03-10
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes raw birth certificate data (NVSS), and converts it into one line
per age group of mother (typical fertile age blocks) and year, with the proport-
ion of all first births which are born in each quarter.  Quarters are defined as
Jan-March, April-June, July-Sept, Oct-Dec.

The file can be completely controlled by the locals and globals in section 1, w-
hich list the location of raw data and where to output graphical results.

contact: damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT "~/database/NVSS/Births/dta"
global OUT "~/investigacion/2015/birthQuarter/data/nvss/"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssPrep.txt", text replace
cap mkdir "$OUT"

********************************************************************************
*** (2a) Create yearly file from 1975-2002
********************************************************************************
foreach yy of numlist 1975(1)2002 {
    dis "Working on year `yy' of 2002."
    use "$DAT/natl`yy'"
    count
    gen birthOrder = dtotord
    gen motherAge  = dmage
    gen birthMonth = birmon

    
    keep if birthOrder==1 & (motherAge>=15 & motherAge<=49)
    if `yy'<=1988 keep if mrace == 1 & mplbir <52
    if `yy'>=1989 keep if mrace == 1 & ormoth== 0 & mplbir <52
    
    gen birthQuarter = ceil(birthMonth/3)
    *gen ageGroup = ceil((motherAge-14)/5)
    gen ageGroup = motherAge>=25 & motherAge <=34
    replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
    replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45
    drop if ageGroup == 0

    gen college    = dmeduc>=16 if dmeduc<80
    gen highschool = dmeduc>=12 if dmeduc<80
    gen all        = 1
    
    gen birth=1
    gen year=`yy'

    tempfile a`yy' c`yy' h`yy'

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup college)
    drop if college = .
    save `c`yy''
    restore

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup highschool)
    drop if highschool = .
    save `h`yy''
    restore

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup all)
    save `a`yy''

    local afiles `afiles' `a`yy''
    local cfiles `cfiles' `c`yy''
    local hfiles `hfiles' `h`yy''   
}

********************************************************************************
*** (2b) Create yearly file from 2003-2012 [MUST CHECK COVERAGE OF EDUC]
********************************************************************************
foreach yy of numlist 2003(1)2008 {
    dis "Working on year `yy' of 2012."
    use "$DAT/natl`yy'"
    count
    gen birthOrder = lbo
    if `yy'==2003 gen motherAge  = mager41+13
    if `yy'>=2004 gen motherAge  = mager
    gen birthMonth = dob_mm

    
    keep if birthOrder==1 & (motherAge>=15 & motherAge<=49)
    if `yy'<=2004 keep if mracerec == 1 & umhisp == 0 & mpstate_rec == 1
    if `yy'>=2005 keep if mracerec == 1 & umhisp == 0
    
    gen birthQuarter = ceil(birthMonth/3)
    *gen ageGroup = ceil((motherAge-14)/5)
    gen ageGroup = motherAge>=25 & motherAge <=34
    replace ageGroup = 2 if motherAge >= 35 & motherAge <= 39
    replace ageGroup = 3 if motherAge >= 40 & motherAge <= 45
    drop if ageGroup == 0

    gen college    = dmeduc>=16 if dmeduc<80
    gen highschool = dmeduc>=12 if dmeduc<80
    gen all        = 1
    
    gen birth=1
    gen year=`yy'

    tempfile a`yy' c`yy' h`yy'

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup college)
    drop if college = .
    save `c`yy''
    restore

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup highschool)
    drop if highschool = .
    save `h`yy''
    restore

    preserve 
    collapse year (count) birth, by(birthQuarter ageGroup all)
    save `a`yy''

    local afiles `afiles' `a`yy''
    local cfiles `cfiles' `c`yy''
    local hfiles `hfiles' `h`yy''   
}


********************************************************************************
*** (3) Append yearly files, format
********************************************************************************
foreach ftype in college highschool all {
    clear
    if `"`ftype'"'=="college" append using `cfiles'
    if `"`ftype'"'=="highschool" append using `hfiles'
    if `"`ftype'"'=="all" append using `afiles'

    lab def AG 1 "25-34" 2 "35-39" 3 "40-45"
    lab val ageGroup AG

    reshape wide birth, i(year ageGroup `ftype') j(birthQuarter)

    foreach num of numlist 1/4 {
        rename birth`num' nQuarter`num'
    }

    egen yearTotal = rowtotal(nQuarter*)
    foreach num of numlist 1/4 {
        gen pQuarter`num'=nQuarter`num'/yearTotal
    }

********************************************************************************
*** (4) Label, clean up
********************************************************************************
    lab var ageGroup  "Mother's age group (5 year bins), labelled"
    lab var year      "Year of birth of child (first born)"
    lab var pQuarter1 "Proportion of births in first quarter"
    lab var pQuarter2 "Proportion of births in second quarter"
    lab var pQuarter3 "Proportion of births in third quarter"
    lab var pQuarter4 "Proportion of births in fourth"
    lab var nQuarter1 "Number of births in first quarter"
    lab var nQuarter2 "Number of births in second quarter"
    lab var nQuarter3 "Number of births in third quarter"
    lab var nQuarter4 "Number of births in fourth quarter"

    lab dat "NVSS (birth certificate) data: All first borns by age group and quarter"

    save "$OUT/nvssAgeQuarter_`ftype'", replace
}

log close
