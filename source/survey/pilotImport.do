/* pilotImport.do v0.00          damiancclarke             yyyy-mm-dd:2016-04-14
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
global DAT "~/investigacion/2015/birthQuarter/data/survey/pilot"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/pilotImport.txt", text replace


********************************************************************************
*** (2) Open 
********************************************************************************
insheet using "$DAT/Demographic_Survey__Oxford.csv", comma names


********************************************************************************
*** (3) Name correctly
********************************************************************************
rename v1         QualtricsJobID
rename v3         Name
rename v6         IPAddress
rename v8         startDate
rename v9         endDate
rename mturkcode  qualtricsCode
rename q1         female
rename q2_1       yearBirth
rename q56_1      state
rename q4         education
rename q5         numberKids
rename q6         maritalStatus
rename q48_1      newsOutlet_ABC
rename q48_2      newsOutlet_CBS
rename q48_3      newsOutlet_CNN
rename q48_4      newsOutlet_NBC
rename q48_5      newsOutlet_NWk
rename i1         childFlag
rename q7         childBornUS
rename q8         childFemale
rename q9a        childMonthBornGirl
rename q9b        childMonthBornBoy
rename q49_1      childYearBornGirl
rename q50_1      childYearBornBoy
rename q10a       childBirthWeightGirl
rename q10b       childBirthWeightBoy
rename q22        fertilityMedication
rename q19        realImportanceSOB
rename q20        realTargetedSOB
rename q51        realSeasonTargeted
rename q66        realReasonBirthday
rename q59        realReasonLuckyDates
rename q58        realReasonJobs
rename q81        realReasonSchoolEntry
rename q68        realReasonTax
rename q62        realReasonChildHealth
rename q63        realReasonMomHealth
rename q52        resourcesChooseSOB
rename v50        resourcesNoDiabetes
rename q24        peopleChooseSOB
rename q25        peopleSeasonTargeted
rename q26        peopleIVFUse
rename q27        friendsChooseSOB
rename q28        friendsSeasonTargeted
rename q31        friendsChooseMost
rename q64        fCL1 
rename q67        fCL2 
rename v60        fCL3 
rename q69        fCL4 
rename q70        fCL5 
rename q71        fCL6
rename q72        fCL7
rename q65        teachersChooseWhy
rename r2         RFlagHP
rename r1         RFlagIP
rename r3         RFlagHN
rename r4         RFlagIN
rename v71        WTPInfoHP
rename q60        WTPInfoIP
rename q61        WTPInfoHN
rename v74        WTPInfoIN
rename v75        race 
rename v76        hispanic
rename v77        labourSituation
rename v78        occupation
rename v79        MTurkType
rename v80        MTurkPay 
rename q55        education_2 
rename v83        childBirthMonth_2
rename v84        familyIncome
rename locationla latitude
rename locationlo longitude


drop v2 v4 v5 v7 v10 sc0_0 sc0_1 sc0_2 intro q21 v51 q57 v88 q32
drop in 1

********************************************************************************
*** (4) Generate Variables
*******************************************************************************
ds QualtricsJobID Name IPAddress startDate endDate, not
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
replace childBirthWeightG = childBirthWeightBoy if childBirthWeightGirl == .
replace realTargetedSOB   = 0 if realTargetedSOB == 2
foreach var of varlist realImp realReasonJ realReasonS realReasonTax  {
    replace `var' = `var' + 1 if `var' > 1
    replace `var' = 2         if `var' == 12
}
rename childBirthWeightGirl childBirthweight
replace realReasonLucky   = 10 if realReasonLucky == 13
replace peopleChooseSOB   = 0 if peopleChooseSOB == 2
egen friendsChooseLeast   = rowtotal(fCL*)
replace friendsChooseLeas = . if friendsChooseLeast == 0
gen randomGroupAssign     = 1 if RFlagHP == 1
replace randomGroupAssign = 2 if RFlagIP == 1
replace randomGroupAssign = 3 if RFlagHN == 1
replace randomGroupAssign = 4 if RFlagIN == 1
egen randomWTPInfo        = rowtotal(WTPInfo*)
replace randomWTPInfo     =. if WTPInfoIN==.&WTPInfoIP==.&WTPInfoHN==.&WTPInfoHP==.
replace hispanic          = 0 if hispanic == 2
replace childBirthMonth_2 = childBirthMonth_2 - 12
replace childFemale       = 0 if childFemale == 2
replace fertilityMedicati = 0 if fertilityMedication == 2
replace friendsChooseSOB  = 0 if friendsChooseSOB==2

drop newsOutlet* childMonthBorn* childYearBorn* childBirthWeightBoy fCL* RFlag*
drop WTPInfo* locationaccuracy

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
gen BonusIVF   = peopleIVFUse==1|peopleIVFUse==2
gen PenaltyIVF = peopleIVFUse>4

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
lab def educ   1 "Master +" 2 "College" 3 "Highschool" 4 "Middle-school -";
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
lab def bwt 1 "< 5.5 lbs" 2 "5.5-6.79 lbs" 3 "6.8-7.79 lbs" 4 "7.8-8.79 lbs"
5 "> 8.8 lbs";
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
lab def rvl 1 "More Health" 2 "More Income" 3 "Less Health" 4 "Less Income";
lab def ivf 1 "0-1%" 2 "2-5%" 3 "6-10%" 4 "11-20%" 5 "21-40%" 6 "41% +";

lab val childBirthMonth months;
lab val childBirthMonth_2 monthA;
lab val education education_2 educ;
lab val state state;
lab val marital mar;
lab val childBirthweight bwt;
lab val realSeasonTargeted peopleSeasonTargeted friendsSeasonTargeted sea;
lab val friendsChooseMost friendsChooseLeast res;
lab val teachersChooseWhy res;
lab val race race;
lab val labourSituation job;
lab val occupation occ;
lab val MTurkType MT1;
lab val MTurkPay MT2;
lab val familyIncome inc;
lab val randomGroupAssign rvl;
lab val peopleIVFUse ivf;
#delimit cr


lab var QualtricsJobID    "Respondent's ID from Amazon (unique identifier)"
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
lab var childBirthweight  "What is the child's birthweight"
lab var fertilityMedica   "Was fertility medication used"  
lab var realImportance    "How much did Season of Birth Matter at time of birth (1-10)"
lab var realTargetedSOB   "Did respondent target season of birth when conceiving"
lab var realSeasonTarge   "If targeted season of birth when conceiving, what season"
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
lab var randomGroupAssign "What random information given?"
lab var randomWTPInfo     "Willingness to pay after random information"
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

********************************************************************************
*** (7) Order
********************************************************************************
#delimit ;
order QualtricsJobID Name IPAddress startDate endDate consent passedAttention
completedSurvey latitude longitude state;
#delimit cr


********************************************************************************
*** (8) Merge in payment info
********************************************************************************
preserve
insheet using "$DAT/bonuses.csv", comma clear
rename v1 qualtricsCode
rename v2 QualtricsJobID
rename v3 IPAddress_MTurk
rename v4 MTurk_Identifier
rename v5 MTurk_JobID
rename v6 BonusFlag

tempfile bonuses
save `bonuses'

restore

merge 1:1 QualtricsJobID using `bonuses'
drop _merge

lab var IPAddress_MTurk  "IP Address (as given by MTurk)"
lab var MTurk_Identifier "Mechanical Turk official worker ID"
lab var MTurk_JobID      "Mechanical Turk official Job ID"
lab var BonusFlag        "Received incorrect bonus (flag=amount)"


********************************************************************************
*** (9) Save
********************************************************************************
lab dat "Pilot survey: Choosing Season of Birth (Clarke, Oreffice, Quintana-Dom)"
save "$DAT/pilotData", replace
