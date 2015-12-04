/* ipumsPrep.do v0.00            damiancclarke             yyyy-mm-dd:2015-12-04
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Takes raw ACS data from 2005-2014 (exported in Sonia's IPUMS file) and generates
additional variables.  Along with variables from the IPUMS data, unemployment da
ta and weather in quarter of conception is added, and occupation classes from Bl
au's AER (2014) are added.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global ACS "~/investigacion/2015/birthQuarter/data/raw"
global UNE "~/investigacion/2015/birthQuarter/data/employ"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsPrep.txt", text replace

local data noallocatedagesexrelate_children__withmother_bio_reshaped_2005_2014

********************************************************************************
*** (2) Open data, subset, and create variables from IPUMS
********************************************************************************
use "$DAT/`data'"
keep if ((bpl1<150 & firstborn_1==1) | (bpl2<150 & firstborn_1==0))
keep if race==1 & hispan==0 & twins==0
keep if school==1
keep if ((nchild==1)|(nchild==2 & twins==1)|(nchild==2&twins==0&firstborn_1==0))
keep if age>19&age<46
drop _merge

rename age motherAge
rename birthqtr1 birthQuarter
gen goodQuarter = birthQuarter==2|birthQuarter==3
gen badQuarter  = birthQuarter==4|birthQuarter==1
gen age2024     = motherAge>=20&motherAge<=24
gen age2527     = motherAge>=25 & motherAge <28
gen age2831     = motherAge>=28 & motherAge <32
gen age3239     = motherAge>=32 & motherAge <40
gen age4045     = motherAge>=40 & motherAge <46
gen birth       = 1
gen married     = marst==1|marst==2
gen hhincomeSq  = hhincome^2
gen female      = sex1==2
gen highEduc    = educ>6 if educ<=11

tab year    , gen(_year)
tab statefip, gen(_state)


********************************************************************************
*** (3) Import weather data
********************************************************************************
preserve
use "$UNE/unemployment", clear
gen birthQuarter = .
replace birthQuarter = 1 if period=="M01"|period=="M02"|period=="M03"
replace birthQuarter = 2 if period=="M04"|period=="M05"|period=="M06"
replace birthQuarter = 3 if period=="M07"|period=="M08"|period=="M09"
replace birthQuarter = 4 if period=="M10"|period=="M11"|period=="M12"

#delimit ;
local fipsB  1  2  4  5  6  8  9 11 10 12 13 15 16 17 18 19 20 21 22 23 24 25
            26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
            48 49 50 51 53 54 55 56;
local fipsW  7  8  9 10 11 12 13 15 14 16 17 18 19 20 21 22 23 24 25 26 27 28
            29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
            51 52 53 54 56 57 58 59;
local stat  AL AK AZ AR CA CO CT DC DE FL GA HI ID IL IN IA KS KY LA ME MD MA  
            MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI SC SD TN
            TX UT VT VA WA WV WI WY;
#delimit cr

gen statefip = .
tokenize `fipsB'
foreach ff of local fipsW {
    qui replace statefip = `1' if fips==`ff'
    macro shift
}
gen stateabbrev = ""
tokenize `stat'
foreach ff of local fipsB {
    qui replace stateabbrev = "`1'" if statefip==`ff'
    macro shift
}

collapse value, by(state fips year statefip birthQuarter)
replace birthQuarter = birthQuarter+3
replace year         = year+1         if birthQuarter >4 
replace birthQuarter = birthQuarter-4 if birthQuarter >4

tempfile weather
save `weather'
restore

merge m:1 statefip year birthQuarter using `weather'
** Merges perfectly for all in ACS data (0 obs with _merge==1)
** Observations for which _merge==2 is because weather data goes back very far
keep if _merge==3
drop _merge


********************************************************************************
*** () Label 
********************************************************************************
lab var goodQuarter  "Good Season"
lab var age2024      "Aged 20-24"
lab var age2527      "Aged 25-27"
lab var age2831      "Aged 28-31"
lab var age3239      "Aged 32-39"
lab var married      "Married"
lab var highEduc     "Some College +"
