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
*** (2) Create yearly file from 1975-2012
********************************************************************************
foreach yy of numlist 1975(1)2002 {
    dis "Working on year `yy' of 2002."
    use "$DAT/natl`yy'"
    count
    gen birthOrder = dtotord
    gen motherAge  = dmage
    gen birthMonth = birmon
    keep birthOrder motherAge birthMonth

    
    keep if birthOrder==1 & (motherAge>=15 & motherAge<=49)
    gen birthQuarter = ceil(birthMonth/3)
    gen ageGroup = ceil((motherAge-14)/5)
    

    gen birth=1
    collapse (count) birth, by(birthQuarter ageGroup)
    gen year=`yy'

    
    tempfile f`yy'
    save `f`yy''
    local files `files' `f`yy''
}

********************************************************************************
*** (3) Append yearly files, format
********************************************************************************
clear
append using `files'

lab def AG 1 "15-19" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49"
lab val ageGroup AG

reshape wide birth, i(year ageGroup) j(birthQuarter)

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

log close
save "$OUT/nvssAgeQuarter", replace
