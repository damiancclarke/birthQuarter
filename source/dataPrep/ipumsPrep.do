/* ipumsPrep.do v0.00            damiancclarke             yyyy-mm-dd:2015-12-04
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Takes raw ACS data from 2005-2014 (exported in Sonia's IPUMS file) and generates
additional variables.  Along with variables from the IPUMS data, unemployment da
ta and weather in quarter of conception is added, and occupation classes from Go
ldin's AER (2014) are added.

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
global OCC "~/investigacion/2015/birthQuarter/data/occup"
global USW "~/investigacion/2015/birthQuarter/data/weather"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/ipumsPrep.txt", text replace

local data noallocatedagesexrelate_children__withmother_bio_reshaped_2005_2014

********************************************************************************
*** (2) Open data, subset, and create variables from IPUMS
********************************************************************************
use "$ACS/`data'"
keep if (bpl1<150 & firstborn_1==1) | (bpl2<150 & firstborn_1==0)
keep if race==1 & hispan==0 
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

********************************************************************************
*** (3) Import unemployment data
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

collapse value, by(state fips year statefip birthQuarter stateabbrev)
replace birthQuarter = birthQuarter+3
replace year         = year+1         if birthQuarter >4 
replace birthQuarter = birthQuarter-4 if birthQuarter >4
rename value unemployment

tempfile unemployment
save `unemployment'
restore

merge m:1 statefip year birthQuarter using `unemployment'
** Merges perfectly for all in ACS data (0 obs with _merge==1)
** Obs for which _merge==2 is because unemployment data goes back to 1976
keep if _merge==3
drop _merge
preserve

********************************************************************************
*** (4) Import temperature data
********************************************************************************
insheet using "$USW/usaWeather.txt", delim(";") names clear
expand 2 if fips == 24, gen(expanded)
replace fips = 11 if expanded==1
replace state= "Washington DC" if expanded==1
drop expanded
keep if year>1997&year<=1999

destring temp, replace
reshape wide temp, i(state fips year month) j(type) string
gen birthQuarter = ceil(month/3)
rename temptmpcst meanT
rename temptminst cold
rename temptmaxst hot


#delimit ;
local stat AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME
           MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX
           UT VA VT WA WI WV WY;
local snam " `"Alaska"' `"Alabama"' `"Arkansas"' `"Arizona"' `"California"'
             `"Colorado"' `"Connecticut"' `"Washington DC"' `"Delaware"'
             `"Florida"' `"Georgia"' `"Hawaii"' `"Iowa"' `"Idaho"' `"Illinois"'
             `"Indiana"' `"Kansas"' `"Kentucky"' `"Louisiana"' `"Massachusetts"'
             `"Maryland"' `"Maine"' `"Michigan"' `"Minnesota"' `"Missouri"'
             `"Mississippi"' `"Montana"' `"North Carolina"' `"North Dakota"'
             `"Nebraska"' `"New Hampshire"' `"New Jersey"' `"New Mexico"'
             `"Nevada"' `"New York"' `"Ohio"' `"Oklahoma"' `"Oregon"'
             `"Pennsylvania"' `"Rhode Island"' `"South Carolina"'
             `"South Dakota"' `"Tennessee"' `"Texas"' `"Utah"' `"Virginia"'
             `"Vermont"' `"Washington"' `"Wisconsin"' `"West Virginia"'
             `"Wyoming"'";
#delimit cr
tokenize `stat'
gen stateabbrev = ""
foreach sname of local snam {
    dis "`1' <--> `sname'"
    replace stateabbrev="`1'" if state=="`sname'"
    macro shift
}
collapse meanT (min) cold (max) hot, by(state fips stateabb)
rename state stateTemp
rename fips  fipsTemp

tempfile temperature
save `temperature'
restore

merge m:1 stateabbrev using `temperature'
** All except for 208 observations merge from IPUMS data.
** 208 obs are from Hawaii, where no temperature data, so _merge==1
** Observations with _merge==2 is because temperature data goes back a long way
drop if _merge==2
drop _merge

********************************************************************************
*** (5) Import occupation data (codes from Goldin files)
********************************************************************************
#delimit ;
local l1 " `"Management, Professional and Related Occupations"'
           `"Service Occupations"' `"Sales and Office Occupations"'
           `"Construction, Extraction and Maintenance Occupations"'
           `"Production, Transportation and Material Moving Occupations"'";
local n1   occ2010>=10&occ2010<=3540   occ2010>=3600&occ2010<=4650
           occ2010>=4700&occ2010<=6130 occ2010>=6200&occ2010<=7630
           occ2010>=7700&occ2010<=9920;
local l2 " `"Management Occupations"' `"Business Operations Specialists"'
           `"Financial Specialists"' `"Computer and Mathematical Occupations"'
           `"Architecture and Engineering Occupations"'
           `"Life, Physical, and Social Science Occupations"'
           `"Community and Social Services Occupations"'
           `"Legal Occupations"'
           `"Education, Training, and Library Occupations"'
           `"Arts, Design, Entertainment, Sports, and Media Occupations"'
           `"Healthcare Practitioners and Technical Occupations"'
           `"Healthcare Support Occupations"' `"Protective Service Occupations"'
           `"Food Preparation and Serving Occupations"'
           `"Building and Grounds Cleaning and Maintenance Occupations"'
           `"Personal Care and Service Occupations"' `"Sales Occupations"'
           `"Office and Administrative Support Occupations"'
           `"Farming, Fishing, and Forestry Occupations"'
           `"Construction Trades"' `"Extraction Workers"'
           `"Installation, Maintenance, and Repair Workers"'
           `"Production Occupations"'
           `"Transportation and Material Moving Occupations"'
           `"Military Specific Occupations"' `"Unemployed"' ";
local n2   occ2010>0&occ2010<=430      occ2010>=500&occ2010<=730
           occ2010>=800&occ2010<=950   occ2010>=1000&occ2010<=1240
           occ2010>=1300&occ2010<=1560 occ2010>=1600&occ2010<=1960
           occ2010>=2000&occ2010<=2060 occ2010>=2100&occ2010<=2150
           occ2010>=2200&occ2010<=2550 occ2010>=2600&occ2010<=2960
           occ2010>=3000&occ2010<=3540 occ2010>=3600&occ2010<=3650
           occ2010>=3700&occ2010<=3950 occ2010>=4000&occ2010<=4160
           occ2010>=4200&occ2010<=4250 occ2010>=4300&occ2010<=4650
           occ2010>=4700&occ2010<=4965 occ2010>=5000&occ2010<=5940
           occ2010>=6000&occ2010<=6130 occ2010>=6200&occ2010<=6765
           occ2010>=6800&occ2010<=6940 occ2010>=7000&occ2010<=7630
           occ2010>=7700&occ2010<=8965 occ2010>=9000&occ2010<=9750
           occ2010>=9800&occ2010<9920  occ2010==9920;
#delimit cr

gen oneLevelOcc = "" 
gen twoLevelOcc = ""

tokenize `n1'
foreach job of local l1 {
    replace oneLevelOcc = "`job'" if `1'
    macro shift
}

tokenize `n2'
foreach job of local l2 {
    replace twoLevelOcc = "`job'" if `1'
    macro shift
}


gen GoldinClass = .
#delimit ;
replace GoldinCla = 1 if occ2010==110|occ2010==300|occ2010==1000|occ2010==1010|
         occ2010==1020|occ2010==1050|occ2010==1100|occ2010==1200|occ2010==1220|
         occ2010==1320|occ2010==1350|occ2010==1360|occ2010==1400|occ2010==1410|
        occ2010==1420|occ2010==1430|occ2010==1440|occ2010==1450|occ2010==1460|
         occ2010==1450|occ2010==1520|occ2010==1530|occ2010==1550|occ2010==2840|
         occ2010==4930|occ2010==9030;
replace GoldinCla = 2 if occ2010==10|occ2010==20  |occ2010==30  |occ2010==100 |
         occ2010==120 |occ2010==130 |occ2010==140 |occ2010==150 |occ2010==600 |
         occ2010==710 |occ2010==720 |occ2010==730 |occ2010==800 |occ2010==810 |
         occ2010==820 |occ2010==830 |occ2010==840 |occ2010==850 |occ2010==860 |
         occ2010==900 |occ2010==910 |occ2010==950 |occ2010==1060|occ2010==1800|
         occ2010==4810|occ2010==4820|occ2010==4840|occ2010==4850|occ2010==5200;
replace GoldinCla = 3 if occ2010==350|occ2010==360|occ2010==1820|occ2010==3000|
         occ2010==3010|occ2010==3040|occ2010==3050|occ2010==3060|occ2010==3110|
         occ2010==3120|occ2010==3130|occ2010==3140|occ2010==3150|occ2010==3160|
         occ2010==3200|occ2010==3210|occ2010==3220|occ2010==3240|occ2010==3250|
         occ2010==3260;
replace GoldinC = 4 if occ2010==1240|occ2010==1650|occ2010==1700|occ2010==1710|
         occ2010==1720|occ2010==1740|occ2010==1760;
replace GoldinCla = 5 if occ2010==220|occ2010==230|occ2010==320 |occ2010==430 |
         occ2010==560 |occ2010==1300|occ2010==1840|occ2010==2100|occ2010==2200|
         occ2010==2710|occ2010==2825|occ2010==3710|occ2010==3820|occ2010==5000|
         occ2010==4900|occ2010==4965|occ2010==9040;
lab def jobs 1 "Technology Occupations" 2 "Business Occupations"
           3 "Health Occupations" 4 "Science Occupations" 5 "Other Occupations";
lab val GoldinClass jobs;
#delimit cr

********************************************************************************
*** (6) Label 
********************************************************************************
lab var goodQuarter  "Good Season"
lab var badQuarter   "Born in quarter 1 or quarter 4"
lab var age2024      "Aged 20-24"
lab var age2527      "Aged 25-27"
lab var age2831      "Aged 28-31"
lab var age3239      "Aged 32-39"
lab var age4045      "Aged 40-45"
lab var married      "Married"
lab var highEduc     "Some College +"
lab var state        "State name (string) no spaces"
lab var fips         "State FIPS (old style, weather)"
lab var stateabbrev  "State code (two letters)"
lab var unemployment "Unemployment rate in quarter of conception"
lab var stateTemp    "State names from temperature data"
lab var fipsTemp     "FIPS codes (current) from temperature data"
lab var meanT        "Average monthly temperature in state"
lab var cold         "Coldest monthly temperature in state"
lab var hot          "Warmest monthly temperature in state"
lab var GoldinClass  "Occupation grouping from Goldin (2014)"


lab dat "ACS data from 2005-2014 with temp, occupation and employment (DCC)"
********************************************************************************
*** (7) Save, close
********************************************************************************
save "$ACS/ACS_20052014_cleaned", replace
log close
