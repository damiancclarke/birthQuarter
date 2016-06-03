/* surveyImport.do v0.00         damiancclarke             yyyy-mm-dd:2016-05-12
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Read in the responses from MTurk and label.


*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals    
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/survey/main"
global LOG "~/investigacion/2015/birthQuarter/log"
global USG "~/investigacion/2015/birthQuarter/data/weather"

log using "$LOG/surveyImport.txt", text replace


********************************************************************************
*** (2) Open 
********************************************************************************
insheet using "$DAT/Oxford_Survey__Principal.csv", comma names
drop in 1
save "$DAT/BirthSurveyRaw.dta", replace

********************************************************************************
*** (3) Name correctly
********************************************************************************
rename v1         QualtricsID
rename v3         Name
rename v6         IPAddress
rename v8         startDate
rename v9         endDate
rename mturkcode  qualtricsCode
rename q1         female
rename q2_1       yearBirth
rename q3_1       state
rename q4         education
rename q5_1       newsOutlet_ABC
rename q5_2       newsOutlet_CBS
rename q5_3       newsOutlet_CNN
rename q5_4       newsOutlet_NBC
rename q5_5       newsOutlet_NWk
rename q6         numberKids
rename q6ai       planKidsM
rename q6aii      planKidsF
rename q6bi       moreKidsM
rename q6bii      moreKidsF
rename q7a        pregnantM
rename q7b        pregnantF
rename q8         maritalStatus
rename m1         childFlag
rename q10        childBornUS
rename q11        childFemale
rename q12a       childMonthBornGirl
rename q12b       childMonthBornBoy
rename q13a_1     childYearBornGirl
rename q13b_1     childYearBornBoy
rename q14a       childGestationGirl
rename q14b       childGestationBoy
rename q15        fertilityMedication
rename q16a       realImportanceSOB
rename q17a       realTargetedSOB
rename q18a       realSeasonTargeted
rename q16b       planImportanceSOB
rename q17b       planTargetedSOB
rename q18b       planSeasonTargeted
rename q20a       realReasonBirthday
rename q20b       realReasonLuckyDates
rename q20c       realReasonJobs
rename q20d       realReasonSchoolEntry
rename q20e       realReasonTax
rename q20f       realReasonChildHealth
rename q20g       realReasonMomHealth
rename q21a       resourcesChooseSOB
rename q21b       resourcesNoDiabetes
rename q22        WTPcheck
rename q24        peopleChooseSOB
rename q25        peopleSeasonTargeted
rename q26        peopleChooseMost
rename q27a       pCL1
rename q27b       pCL2
rename q27c       pCL3
rename q27d       pCL4
rename q27e       pCL5
rename q27f       pCL6
rename q27g       pCL7
rename q28        peopleIVFUse
rename q29        friendsChooseSOB
rename q30        friendsSeasonTargeted
rename q31        friendsChooseMost
rename q32a       fCL1 
rename q32b       fCL2 
rename q32c       fCL3 
rename q32d       fCL4 
rename q32e       fCL5 
rename q32f       fCL6
rename q32g       fCL7
rename q33        teacherPay
rename q34        teachersChooseWhy
rename q35        race 
rename q36        hispanic
rename q37        labourSituation
rename q38        occupation
rename q39        MTurkType
rename q40        MTurkPay 
rename q41        education_2 
rename q43        childBirthMonth_2
rename q44        familyIncome
rename locationla latitude
rename locationlo longitude
rename sc0_0      score

drop v2 v4 v5 v7 v10 sc0_1 sc0_2 intro q42 locationaccuracy q19a q19b v99 q23

********************************************************************************
*** (4) Generate Variables
*******************************************************************************
ds QualtricsID Name IPAddress startDate endDate, not
local numvars `r(varlist)'

foreach var of local numvars {
    destring `var', replace
}

replace yearBirth         = yearBirth+1919
replace childYearBornGirl = childYearBornGirl + 1959
replace childYearBornBoy  = childYearBornBoy  + 1959
replace female            = female - 1
replace numberKids        = numberKids - 1

gen passedAttention       = newsOutlet_ABC==1 & newsOutlet_NWk==1
gen completedSurvey       = qualtricsCode != .
egen childBirthMonth      = rowtotal(childMonthBorn*)
replace childBirthMonth   = . if childBirthMonth == 0
egen childBirthYear       = rowtotal(childYearBorn*)
replace childBirthYear    = . if childBirthYear == 0
replace childGestationG   = childGestationBoy if childGestationGirl == .
replace planKidsF         = planKidsM if planKidsF==.
replace moreKidsF         = moreKidsM if moreKidsF==.
replace pregnantF         = pregnantM if pregnantF==.

replace realTargetedSOB   = 0 if realTargetedSOB == 2
replace planTargetedSOB   = 0 if planTargetedSOB == 2
foreach var of varlist realImp planImp realReasonJ realReasonS realReasonTax  {
    replace `var' = `var' + 1 if `var' > 1
    replace `var' = 2         if `var' == 12
}
rename childGestationGirl childGestation
rename planKidsF planKids
rename moreKidsF moreKids
rename pregnantF pregnant
replace realReasonLucky   = 10 if realReasonLucky == 13
replace peopleChooseSOB   = 0 if peopleChooseSOB == 2
egen friendsChooseLeast   = rowtotal(fCL*)
replace friendsChooseLeas = . if friendsChooseLeast == 0
egen peopleChooseLeast    = rowtotal(pCL*)
replace peopleChooseLeas  = . if peopleChooseLeast == 0
replace realSeasonTargeted= 4 if realSeasonTargeted==5
replace planSeasonTargeted= 4 if planSeasonTargeted==5

replace hispanic          = 0 if hispanic == 2
replace childBirthMonth_2 = childBirthMonth_2 - 12
replace childFemale       = 0 if childFemale == 2
replace fertilityMedicati = 0 if fertilityMedication == 2
replace friendsChooseSOB  = 0 if friendsChooseSOB==2

drop newsOutlet* childMonthBorn* childYearBorn* childGestationBoy fCL* pCL*
drop planKidsM moreKidsM pregnantM


********************************************************************************
*** (5) Generate survey parameters
********************************************************************************
split startDate, gen(start)
split endDate  , gen(end)
split start2   , gen(stime) parse(:) destring
split end2     , gen(etime) parse(:) destring

rename start1 surveyStartDate
rename end1   surveyEndDate
rename start2 surveyStartTime
rename end2   surveyEndTime

gen surveyTime = etime2-stime2 + (etime1-stime1)*60 + (etime3-etime2)/60
gen surveyTimeMin = floor(surveyTime)
gen surveyTimeSec = round((surveyTime - surveyTimeMin)*60)

drop stime* etime*

gen BonusSOB   = peopleSeasonTargeted==2|peopleSeasonTargeted==3
gen BonusIVF   = peopleIVFUse==2
gen PenaltyIVF = peopleIVFUse>4

gen unaccounted= qua==60324|q==1394643|q==7929766|q==6357382|q==5886300|/*
*/               q==3998247|q==3090252|q==2861437

gen BonusAmount     = 0.4*BonusSOB + 0.1*BonusIVF
replace BonusAmount = 0 if PenaltyIVF == 1


********************************************************************************
*** (6) Label
********************************************************************************
#delimit ;
lab def months 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
               9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec";
lab def monthA 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug"
               9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec" 13 "None";
lab def educ   1 "<=8th grade" 2 "Some Highschool" 3 "Highschool Degree/GED"
4 "Some College" 5 "2 year College Degree" 6 "4 year College Degree"
7 "Masters Degree" 8 "Doctoral Degree" 9 "Professional Degree";
lab def state  1 "Alabama" 2 "Alaska" 3 "Arizona" 4 "Arkansas" 5 "California"
6 "Colorado" 7 "Connecticut" 8 "Delaware" 9 "District of Columbia" 10 "Florida"
11 "Georgia" 12 "Hawaii" 13 "Idaho" 14 "Illinois" 15 "Indiana" 16 "Iowa"
17 "Kansas" 18 "Kentucky" 19 "Louisiana" 20 "Maine" 21 "Maryland"
22 "Massachusetts" 23 "Michigan" 24 "Minnesota" 25 "Mississippi" 26 "Missouri"
27 "Montana" 28 "Nebraska" 29 "Nevada" 30 "New Hampshire" 31 "New Jersey"
32 "New Mexico" 33 "New York" 34 "North Carolina" 35 "North Dakota" 36 "Ohio"
37 "Oklahoma" 38 "Oregon" 39 "Pennsylvania" 40 "Rhode Island"
41 "South Carolina" 42 "South Dakota" 43 "Tennessee" 44 "Texas" 45 "Utah"
46 "Vermont" 47 "Virginia" 48 "Washington" 49 "West Virginia" 50 "Wisconsin"
51 "Wyoming";
lab def mar 1 "Married" 2 "Separated/Divorced" 3 "Never Married";
lab def ges 1 "<=6 months" 2 "7 months" 3 "8 months" 4 "9 months"
5 "> 10 months";
lab def sea 1 "Jan-Mar" 2 "Apr-Jun" 3 "Jul-Sep" 4 "Oct-Dec";
lab def res 1 "Birthday Parties" 2 "Job Requirements" 3 "Lucky Dates"
4 "School Entry" 5 "Tax Benefits" 6 "Child Well-being" 7 "Mother Well-being";
lab def re2 1 "Birthday Parties" 2 "Job Requirements" 3 "Lucky Dates"
4 "School Entry" 5 "Tax Benefits" 6 "Child Well-being" 7 "Mother Well-being"
8 "Don't know";
lab def race 11 "White" 12 "Black" 13 "Native American" 14 "Asian"
15 "Hawaiian/Pacific Islander" 16 "Other";
lab def job 1 "Employed" 2 "Unemployed" 3 "Not in labour force";
lab def occ 1 "Architecture" 2 "Arts, Design, Media" 3 "Business Operations"
4 "Community/Social Services" 5 "Computer/Mathematical" 6 "Education, Library"
7 "Financial" 8 "Food Preparation" 9 "Healthcare Practitioners"
10 "Healthcare Support" 11 "Legal" 12 "Life, Physical, Social Science"
13 "Management" 14 "Office and Administrative" 15 "Personal Care" 16 "Production"
17 "Sales" 18 "Never Worked for Pay";
lab def MT1 1 "MTurk Main Income" 2 "MTurk Supplements" 3 "MTurk Hobby" 4 "Other";
lab def MT2 1 "< $2" 2 "$2-$2.99" 3 "$3-$3.99" 4 "$4-$4.99" 5 "$5-$5.99"
6 "$6-$6.99" 7 "$7-$7.99" 8 "$8-$8.99" 9 "$9-$9.99" 10 "$10-$10.99" 11 ">= $11";
lab def inc 11 "< 10K" 12 "10K-20K" 13 "20K-30K" 14 "30K-40K" 15 "40K-50K"
16 "50K-60K" 17 "60K-70K" 18 "70K-80K" 19 "80K-90K" 20 "90K-100K" 21 "100K-150K"
22 ">= 150K";
lab def ivf 1 "0-1%" 2 "2-5%" 3 "6-10%" 4 "11-20%" 5 "21-40%" 6 "41% +";
lab def sure 1 "Yes" 2 "No" 3 "Don't Know";
lab def tpay 1 "More" 2 "The Same" 3 "Less";
lab def wtp 1 "Probably Sure" 2 "Definitely Sure";

lab val childBirthMonth months;
lab val childBirthMonth_2 monthA;
lab val education education_2 educ;
lab val state state;
lab val marital mar;
lab val childGestation ges;
lab val realSeasonTargeted planSeasonT peopleSeasonT friendsSeasonT sea;
lab val friendsChooseMost friendsChooseLeast peopleChooseM peopleChooseL res;
lab val teachersChooseWhy res;
lab val race race;
lab val labourSituation job;
lab val occupation occ;
lab val MTurkType MT1;
lab val MTurkPay MT2;
lab val familyIncome inc;
lab val peopleIVFUse ivf;
lab val pregnant sure;
lab val moreKids sure;
lab val planKids sure;
lab val WTPcheck wtp;
lab val teacherPay tpay;
#delimit cr

lab var QualtricsID       "Respondent's ID from Amazon (unique identifier)"
lab var Name              "Respondent's Name"
lab var IPAddress         "Respondent's IP Address"
lab var startDate         "Start date of survey (date, time)"
lab var endDate           "End date of survey (date, time)"
lab var consent           "Does the respondent consent to conditions"
lab var passedAttention   "Does the respondent pass the attention test (A and E)"
lab var completedSurvey   "Does the respondent complete the survey"
lab var latitude          "Respondent's geographical latitude (automatic)"
lab var longitude         "Respondent's geographical latitude (automatic)"
lab var state             "Respondent's state of residence (reported)"
lab var qualtricsCode     "Qualtrics code given to respondent to confirm payment"
lab var female            "Is respondent female (binary)"
lab var yearBirth         "Respondent's year of birth"
lab var education         "Respondent's education level"
lab var numberKids        "Total number of children of respondent"
lab var maritalStatus     "Respondent's marital status"
lab var childFlag         "Does respondent respond to child questions"
lab var childBornUS       "Is child born in the US"
lab var childFemale       "Is the child female"
lab var childGestation    "What was the child's gestation length"
lab var fertilityMedica   "Was fertility medication used"  
lab var realImportance    "How much did Season of Birth Matter at time of birth (1-10)"
lab var realTargetedSOB   "Did respondent target season of birth when conceiving"
lab var realSeasonTarge   "If targeted season of birth when conceiving, what season"
lab var planImportance    "How much will Season of Birth Matter at time of birth (1-10)"
lab var planTargetedSOB   "Will you target season of birth when conceiving"
lab var planSeasonTarge   "If targeting season of birth when conceiving, what season"
lab var realReasonBirt    "How important were Birthdays when deciding to target SOB"  
lab var realReasonLuck    "How important were Lucky Dates when deciding to target SOB"  
lab var realReasonJobs    "How important were job conditions when deciding to target SOB"  
lab var realReasonSchool  "How important was School Entry Date when deciding to target SOB"    
lab var realReasonTax     "How important was tax when deciding to target SOB"    
lab var realReasonChild   "How important was child health when deciding to target SOB"      
lab var realReasonMom     "How important was mother health when deciding to target SOB"    
lab var resourcesChoose   "What percent of all resources to have baby in preferred season" 
lab var resourcesNoDiab   "What percent of all resources to have baby without diabetes"
lab var peopleChooseSOB   "Do you think people target season of birth?"
lab var peopleSeasonTar   "If you think peolpe target SOB, What season do you think?"
lab var peopleChooseMost  "What is the most relevant reason why people target SOB?"   
lab var peopleChooseLeast "What is the least relevant reason why people target SOB?"   
lab var peopleIVFUse      "What percent of births in USA are from IVF"
lab var friendsChooseSOB  "Do your friends choose SOB"
lab var friendsSeasonTar  "If you think your friends target SOB, what season?"  
lab var friendsChooseMost "What is the most relevant reason why friends target SOB?"   
lab var teachersChooseWhy "Why do you think teachers target SOB" 
lab var race              "Race of respondent"
lab var hispanic          "Is respondent hispanic"
lab var labourSituation   "Respondent's employment status"
lab var occupation        "Respondent's occupation"
lab var MTurkType         "Main Use of MTurk"
lab var MTurkPay          "Normal MTurk Pay"
lab var education_2       "Respondent's education (check)"
lab var childBirthMonth_2 "Child Birth Month (check)"
lab var familyIncome      "Family's income"
lab var childBirthMonth   "Child Birth Month"
lab var childBirthYear    "Child Birth Year"
lab var friendsChooseLea  "What is the least relevant reason why friends target SOB?"   
lab var surveyStartDate   "Survey start date (yyyy-mm-dd)"
lab var surveyStartTime   "Survey start time (hh:mm:ss)"
lab var surveyEndDate     "Survey end date (yyyy-mm-dd)"
lab var surveyEndTime     "Survey end time (hh:mm:ss)"
lab var surveyTime        "Total survey time in minutes and fraction of minutes"
lab var surveyTimeMin     "Total survey time in minutes (floor)"
lab var surveyTimeSec     "Total survey time in seconds"
lab var BonusSOB          "Bonus for correctly identifying seasons from NVSS"
lab var BonusIVF          "Bonus for correctly %IVF from NVSS"
lab var PenaltyIVF        "Penalty for a very high guess of IVF"
lab var BonusAmount       "BONUS = 0.4*BonusSOB + 0.1*BonusIVF or 0 if PenaltyIVF==1"
lab var score             "Score assigned by Qualtrics"
lab var planKids          "Do you plan to have any children"
lab var moreKids          "Do you plan to have any more children"
lab var pregnant          "Are you or your partner curently Pregnant"
lab var WTPcheck          "Are you sure of WTP values"
lab var unaccounted       "Survey is unaccounted for in MTurk payments"
lab var teacherPay        "Are teachers paid more, the same, or less"

********************************************************************************
*** (7) Order
********************************************************************************
count
local Numb = r(N)
gen address = ""
foreach num of numlist 1(1)1600 {
    sum latitude in `num'
    if `r(N)'!=0 {
        local lat = `r(mean)'
        sum longitude in `num'
        local long = `r(mean)'
        gcode_dcc `lat',`long'
        cap replace address = "`r(address)'" in `num'
    }
}
foreach num of numlist 1601(1)`Numb' {
    sum latitude in `num'
    if `r(N)'!=0 {
        local lat = `r(mean)'
        sum longitude in `num'
        local long = `r(mean)'
        gcode_dcc `lat',`long'
        cap replace address = "`r(address)'" in `num'
    }
}
lab var address           "Address based on GEOcode (google maps search)"
split address, generate(_add) parse(",")
gen country = _add8
replace country = _add7 if country==""
replace country = _add6 if country==""
replace country = _add5 if country==""
replace country = _add4 if country==""
replace country = _add3 if country==""
replace country = _add2 if country==""
replace country =" China" if country==" 100009"
replace country = subinstr(country," ", "", 1)
gen notUSA = country !="USA"
gen stateGEO = _add3 if notUSA==0
replace stateGEO = " FL 33950" if stateGEO==" 41 Multi-Use Trail"
replace stateGEO = " IL 60103" if _add1 == "Bartlett"
replace stateGEO = " VA 22904" if stateGEO==" Charlottesville"
replace stateGEO = " WA 98101" if stateGEO==" Seattle"
replace stateGEO = " CA" if _add1=="Round Valley Trail"
replace stateGEO = " MA" if _add1=="Fall River"
rename country countryGEO

#delimit ;
order QualtricsID Name IPAddress startDate endDate consent passedAttention
completedSurvey latitude longitude state address;
#delimit cr

lab var stateGEO   "State according to IP"
lab var countryGEO "Country according to IP"
lab var notUSA     "Not USA according to IP"
lab var lat2       "Albers projection of latitude (mapping only)"
lab var long2      "Albers projection of longitude (mapping only)"
lab var lat3       "Web Mercator projection of latitude (mapping only)"
lab var long3      "Web Mercator projection of longitude (mapping only)"

drop childFlag

preserve
insheet using $USG/usaWeather.txt, names delim(";") clear
keep if year==2013
collapse temp (min) minTemp=temp (max) maxTemp=temp, by(state)
rename state stateString

tempfile temperature
save `temperature'
restore
decode state, gen(stateString)

merge m:1 stateString using `temperature'
replace temp = 54.71944 if state=="District of Columbia"
replace minTemp = 26.5 if stateS=="District of Columbia"
replace maxTemp = 86.5 if stateS=="District of Columbia"

********************************************************************************
*** (8) Rename
********************************************************************************
#delimit ;
local orig startDate endDate passedAttention completedSurvey yearBirth education
numberKids planKids moreKids maritalStatus childBornUS childFemale female
childGestation fertilityMed realImportanceSOB realTargetedSOB realSeasonTargeted
planImportanceSOB planTargetedSOB planSeasonTargeted realReasonBi realReasonLu
realReasonJob realReasonSchool realReasonTax realReasonChild realReasonMom
resourcesChooseSOB resourcesNoDiab peopleChooseSOB peopleSeasonT peopleChooseM
peopleChooseL peopleIVFUse friendsChooseSOB friendsSeason friendsChooseMost
friendsChooseLeast teachersChooseWhy teacherPay labourSituation occupation
MTurkType MTurkPay education_2 childBirthMonth childBirthMonth_2 familyIncome
childBirthYear QualtricsID Name IPAddress;
local new  startdate enddate attentioncheck completed birthyr educ nchild
plankids morekids marst USchild sexchild sex gestation fertmed SOBimport
SOBtarget SOBprefer pSOBimport pSOBtarget pSOBprefer SOBbirthday SOBlucky
SOBjobs SOBschool SOBtax SOBchealth SOBmhealth WTPsob WTPdiabetes oSOBtarget
oSOBprefer oSOBmost oSOBleast oIVF fSOBtarget fSOBprefer fSOBmost fSOBleast
SOBteacher teacherpay empstat occ mturktype mturkpay educ_check cbirthmonth
cbirthmonth_check ftotinc cbirthyr qualtricsid name ipaddress;
#delimit cr

********************************************************************************
*** (9) Save
********************************************************************************
lab dat "Birth survey: Choosing Season of Birth (Clarke, Oreffice, Quintana-Dom)"
save "$DAT/BirthSurvey", replace
