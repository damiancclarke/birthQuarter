# formatTabs.py v0.00             damiancclarke             yyyy-mm-dd:2015-05-07
#----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This file formats tables to produce output for the paper "Fertility Timing and
# Season of Birth..." (Clarke, Oreffice, Quintana-Domeque).  It produces indivi-
# dual tex files, and one final file called tables.tex which should be called by
# the main paper.tex file.  The only thing that needs to be changed is the defi-
# nition of RES and TAB in section (1).
# 
# At the command line:
#
#    python formatTabs.py

import re
import os
#import locale
#locale.setlocale(locale.LC_ALL, 'en_US')

print('\n\n Producing tex files for output tables.\n\n')

#==============================================================================
#== (1a) File names (comes from Stata do files)
#==============================================================================
RES   = "/home/damian/investigacion/2015/birthQuarter/results/"
TAB   = "/home/damian/investigacion/2015/birthQuarter/tables/"
ftype = 'nvss'
ftype = 'nvssall'
#ftype = 'hisp'
#ftype = 'hispall'

singleNVSS       = RES + ftype + '/sumStats/FullSample.txt'
singleEducNVSS   = RES + ftype + '/sumStats/EducSample.txt'
allEducNVSS      = RES + ftype + '/sumStats/JustEduc.txt'
singleSpain      = RES + 'spain/sumStats/FullSample.txt'
singleEducSpain  = RES + 'spain/sumStats/EducSample.txt'
allEducSpain     = RES + 'spain/sumStats/JustEduc.txt'
singleIPUMS      = RES + 'ipums/sumStats/FullSample.txt'
singleEducIPUMS  = RES + 'ipums/sumStats/EducSample.txt'
allEducIPUMS     = RES + 'ipums/sumStats/JustEduc.txt'


twinNVSS       = RES + ftype + '/sumStats/FullSampletwins.txt'
twinEducNVSS   = RES + ftype + '/sumStats/EducSampletwins.txt'
TallEducNVSS   = RES + ftype + '/sumStats/JustEductwins.txt'

sumNVSS  = RES + ftype + '/sumStats/nvssSum.tex'
MumNVSS  = RES + ftype + '/sumStats/nvssMum.tex'
MumPNVSS = RES + ftype + '/sumStats/nvssMumPart.tex'
KidNVSS  = RES + ftype + '/sumStats/nvssKid.tex'
sumIPUMS = RES + 'ipums/sumStats/IPUMSstats.tex'

MumNVSS2 = RES + ftype + '/sumStats/sampMum.tex'
MumPNVSS2= RES + ftype + '/sumStats/sampMumPart.tex'
KidNVSS2 = RES + ftype + '/sumStats/sampKid.tex'
Mumttest = RES + ftype + '/sumStats/SttestMum.tex'
MumPttest= RES + ftype + '/sumStats/SttestMumPart.tex'
Kidttest = RES + ftype + '/sumStats/SttestKid.tex'


MumSpain  = RES + 'spain' + '/sumStats/SpainMum.tex'
MumPSpain = RES + 'spain' + '/sumStats/SpainMumPart.tex'
KidSpain  = RES + 'spain' + '/sumStats/SpainKid.tex'
MumSpain2 = RES + 'spain' + '/sumStats/SpainSmpMum.tex'
MumPSpain2= RES + 'spain' + '/sumStats/SpainSmpMumPart.tex'
KidSpain2 = RES + 'spain' + '/sumStats/SpainSmpKid.tex'

NVSSGoodE = RES + ftype + '/regressions/NVSSBinaryExpectGood.tex'
NVSSBadE  = RES + ftype + '/regressions/NVSSBinaryExpectBad.tex'

IPUMSind  = RES + 'ipums/regressions/IPUMSIndustry.tex' 
IPUMSind2 = RES + 'ipums/regressions/IPUMSIndustry_GSample.tex' 
IPUMSind3 = RES + 'ipums/both/regressions/IPUMSIndustry.tex' 
IPUMSindG = RES + 'ipums/regressions/IPUMSIndustryGoldin.tex' 
IPUMSindG2= RES + 'ipums/regressions/IPUMSIndustryGoldinTeachers.tex'
IPUMSind4 = RES + 'ipums/regressions/IPUMSIndustry_noSelfEmp.tex' 
IPUMSind5 = RES + 'ipums/regressions/IPUMSIndustry_SelfEmpD.tex' 
IPUMSind6 = RES + 'ipums/regressions/IPUMSIndustryWeeksWork.tex' 
IPUMSind7 = RES + 'ipums/regressions/IPUMSIndustryWeeks_Int.tex' 
IPUMSind8 = RES + 'ipums/regressions/EducSq_IPUMSIndustry.tex' 

SpainInd  = RES + 'spain/regressions/SpainIndustry.tex' 
SpainTO   = RES + 'spain/regressions/SpainTradeoff.tex' 

#==============================================================================
#== (1b) shortcuts
#==============================================================================
foot = "$^{*}$p$<$0.1; $^{**}$p$<$0.05; $^{***}$p$<$0.01"
ls   = "\\\\"

mr   = '\\midrule'
tr   = '\\toprule'
br   = '\\bottomrule'
mc1  = '\\multicolumn{'
mc2  = '}}'
twid = ['10','6','7','7','7','6','5','6','6']
tcm  = ['}{p{16.6cm}}','}{p{17.6cm}}','}{p{15.6cm}}','}{p{17.6cm}}',
        '}{p{11.8cm}}','}{p{11.4cm}}','}{p{9.0cm}}','}{p{12.2cm}}' ,
        '}{p{16.2cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2a) Write birth quarter summary tables NVSS
#==============================================================================
sNV  = open(singleNVSS, 'r').readlines()
sNVe = open(singleEducNVSS, 'r').readlines()
sNVj = open(allEducNVSS, 'r').readlines()

for parity in ['single']:
    sumT = open(TAB + 'sum'+parity+ftype+'.tex', 'w')

    if parity=='twin':
        NV  = open(twinNVSS, 'r').readlines()
        NVe = open(twinEducNVSS, 'r').readlines()
        NVj = open(TallEducNVSS, 'r').readlines()
        headline = 'Twins'
    elif parity=='single':
        NV  = open(singleNVSS, 'r').readlines()
        NVe = open(singleEducNVSS, 'r').readlines()
        NVj = open(allEducNVSS, 'r').readlines()
        headline = 'Singletons'

    sumT.write("\\begin{table}[htpb!]"
               "\\caption{Percent of Births} \n"
               "\\label{bqTab:"+parity+"Sum}\\begin{center}"
               "\\begin{tabular}{lcccccc}\n\\toprule \\toprule \n"
               "& \\multicolumn{4}{c}{Seasons} & "
               "\\multicolumn{2}{c}{Characteristics} \\\\ "
               "\cmidrule(r){2-5} \cmidrule(r){6-7} \n"
               "& Bad    & Good   & Diff. & Ratio & $< $37 & ART \\\\\n"
               "& Season & Season &       &       &Gestation&     \\\\\n"
               "&        &        &       &       & Weeks   &     \\\\\\midrule"
               "\multicolumn{5}{l}{\\textsc{Panel A: By Age}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
    sumT.write(NV[1]+'\\\\ \n'+NV[2]+'\\\\ \n'+NV[3]+'\\\\ \n'
               +NV[4]+'\\\\ \n'+NV[5]+'\\\\ \n &&&&&& \\\\'
               "\multicolumn{7}{l}{\\textsc{Panel B: By Education}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               NVj[1]+'\\\\ \n'+
               NVj[2]+'\\\\ \n &&&&&& \\\\'
               ##"\multicolumn{7}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
               ##"\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               ##"\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               ##NVe[1]+'\\\\ \n'+
               ##NVe[2]+'\\\\ \n'+
               ##NVe[3]+'\\\\ \n'+
               ##NVe[4]+'\\\\ \n &&&& \\\\'
               )
    
    
    sumT.write('\n'+mr+mc1+twid[4]+tcm[4]+mc3+
               "Main estimation sample augmented with mothers aged 20-24. \n"
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
               "\\end{center}\\end{table}")
    
    sumT.close()

#==============================================================================
#== (2b) Write birth quarter summary table Spain
#==============================================================================
sumT = open(TAB + 'sumSpain.tex', 'w')

NV  = open(singleSpain,     'r').readlines()
NVe = open(singleEducSpain, 'r').readlines()
NVj = open(allEducSpain,    'r').readlines()


sumT.write("\\begin{table}[htpb!]"
           "\\caption{Percent of Births, Singletons} \n"
           "\\label{bqTab:SpainSum}\\begin{center}"
           "\\begin{tabular}{lccccc}\n\\toprule \\toprule \n"
           "& Bad    & Good   & Diff. & Ratio & Premature \\\\\n"
           "& Season & Season &       &       & ($<$ 37 weeks)\\\\\\midrule"
           "\multicolumn{6}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*5+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
sumT.write(NV[1]+'\\\\ \n'+NV[2]+'\\\\ \n'+NV[3]+'\\\\ \n'
           +NV[4]+'\\\\ \n'+NV[5]+'\\\\ \n &&&&& \\\\'
           "\multicolumn{6}{l}{\\textsc{Panel B: By Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*5+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVj[1]+'\\\\ \n'+
           NVj[2]+'\\\\ \n &&&&& \\\\'
           ##"\multicolumn{6}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
           ##"\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*5+
           ##"\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           ##NVe[1]+'\\\\ \n'+
           ##NVe[2]+'\\\\ \n'+
           ##NVe[3]+'\\\\ \n'+
           ##NVe[4]+'\\\\ \n &&&&& \\\\'
           )
    
    
sumT.write('\n'+mr+mc1+twid[5]+tcm[5]+mc3+
           "Good season refers to birth quarters 2 and 3 (Apr-Jun and    "
           "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar   "
           "and Oct-Dec).  Values reflect the percent of yearly births   "
           "each season from 2007-2013.\n"
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
           "\\end{center}\\end{table}")
    
sumT.close()


#==============================================================================
#== (2c) Write birth quarter summary table IPUMS
#==============================================================================
sumT = open(TAB + 'sumIPUMS.tex', 'w')

NV  = open(singleIPUMS,     'r').readlines()
NVe = open(singleEducIPUMS, 'r').readlines()
NVj = open(allEducIPUMS,    'r').readlines()


sumT.write("\\begin{table}[htpb!]"
           "\\caption{Percent of Births (ACS 2005-2014)} \n"
           "\\label{bqTab:SpainSum}\\begin{center}"
           "\\begin{tabular}{lcccc}\n\\toprule \\toprule \n"
           "& Bad    & Good   & Diff. & Ratio \\\\\n"
           "& Season & Season &       &       \\\\\\midrule"
           "\multicolumn{5}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
sumT.write(NV[1]+'\\\\ \n'+NV[2]+'\\\\ \n'+NV[3]+'\\\\ \n'
           +NV[4]+'\\\\ \n'+NV[5]+'\\\\ \n &&&& \\\\'
           "\multicolumn{5}{l}{\\textsc{Panel B: By Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVj[1]+'\\\\ \n'+
           NVj[2]+'\\\\ \n &&&& \\\\'
           ##"\multicolumn{5}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
           ##"\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           ##"\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           ##NVe[1]+'\\\\ \n'+
           ##NVe[2]+'\\\\ \n'+
           ##NVe[3]+'\\\\ \n'+
           ##NVe[4]+'\\\\ \n'+
           ##NVe[5]+'\\\\ \n'+
           ##NVe[6]+'\\\\ \n &&&& \\\\'
           )
    
    
sumT.write('\n'+mr+mc1+twid[6]+tcm[6]+mc3+
           "Good season refers to birth quarters 2 and 3 (Apr-Jun and      " 
           "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar     "
           "and Oct-Dec). \n"
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
           "\\end{center}\\end{table}")
    
sumT.close()


sumT = open(TAB + 'sumIPUMS_hisp.tex', 'w')
singleIPUMSh      = RES + 'hisp/ipums/sumStats/FullSample.txt'
allEducIPUMSh     = RES + 'hisp/ipums/sumStats/JustEduc.txt'
NVh  = open(singleIPUMSh,     'r').readlines()
NVhj = open(allEducIPUMSh,    'r').readlines()

sumT.write("\\begin{table}[htpb!]"
           "\\caption{Percent of Births (ACS 2005-2014)} \n"
           "\\label{bqTab:SpainSum}\\begin{center}"
           "\\begin{tabular}{lcccc}\n\\toprule \\toprule \n"
           "& Bad    & Good   & Diff. & Ratio \\\\\n"
           "& Season & Season &       &       \\\\\\midrule"
           "\multicolumn{5}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
sumT.write(NVh[1]+'\\\\ \n'+NVh[2]+'\\\\ \n'+NVh[3]+'\\\\ \n'
           +NVh[4]+'\\\\ \n'+NVh[5]+'\\\\ \n &&&& \\\\'
           "\multicolumn{5}{l}{\\textsc{Panel B: By Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVhj[1]+'\\\\ \n'+
           NVhj[2]+'\\\\ \n &&&& \\\\'
           ##"\multicolumn{5}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
           ##"\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           ##"\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           ##NVe[1]+'\\\\ \n'+
           ##NVe[2]+'\\\\ \n'+
           ##NVe[3]+'\\\\ \n'+
           ##NVe[4]+'\\\\ \n'+
           ##NVe[5]+'\\\\ \n'+
           ##NVe[6]+'\\\\ \n &&&& \\\\'
           )
    
    
sumT.write('\n'+mr+mc1+twid[6]+tcm[6]+mc3+
           "Good season refers to birth quarters 2 and 3 (Apr-Jun and      " 
           "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar     "
           "and Oct-Dec). \n"
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
           "\\end{center}\\end{table}")
    
sumT.close()



#==============================================================================
#== (3a) Basic Sum stats (NVSS)
#==============================================================================
sumT = open(TAB + 'sumStats'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics All Ages (NVSS 2005-2013)}\n '
'\\label{bqTab:SumStatsNVSS}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumNVSS,  'r').readlines()
MP  = open(MumPNVSS, 'r').readlines()
Ki  = open(KidNVSS,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<16:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP):
    if i>8 and i<20:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki):
    if i>8 and i<18:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to white, "
           "non-hispanic mothers of any age ocurring in the NVSS. "
           "birth register. Good season refers to birth quarters 2 and 3   "
           "(Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

if ftype == 'nvss':
    mnote = ', Non-Hispanic married '
    mnum  = 12
    mnu2  = 16
elif ftype=='hisp':
    mnote = ', married '
    mnum  = 12
    mnu2  = 17
elif ftype == 'nvssall':
    mnote = ' Non-Hispanic '
    mnum  = 13
    mnu2  = 17
elif ftype=='hispall':
    mnote = ' '
    mnum  = 13
    mnu2  = 18
    
    
sumT = open(TAB + 'sumStatsSamp'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (NVSS 2005-2013)}\n '
'\\label{bqTab:SumStatsMain}'
'\\scalebox{0.85}{'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu2  = open(MumNVSS2,  'r').readlines()
MP2  = open(MumPNVSS2, 'r').readlines()
Ki2  = open(KidNVSS2,  'r').readlines()

for i,line in enumerate(Mu2):
    if i>8 and i< mnum:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
    if i>mnum and i<mnu2:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP2):
    if i>8 and i<19:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Used ART (2009-2013 only)','Used ART$^{a}$')
        line = line.replace('Received WIC food in Pregnancy','Received WIC food in Pregnancy$^{a}$')
        line = line.replace('Underweight (BMI $<$ 18.5)','Pre-pregnancy Underweight (BMI $<$ 18.5)$^{a}$')
        line = line.replace('Normal Weight (BMI 18.5-25)','Pre-pregnancy Normal Weight (18.5 $\leq$ BMI $<$ 25)$^{a}$')
        line = line.replace('Overweight (BMI 25-30)','Pre-pregnancy Overweight (25 $\leq$ BMI $<$ 30)$^{a}$')
        line = line.replace('Obese (BMI $\geq$ 30)','Pre-pregnancy Obese (BMI $\geq$ 30)$^{a}$')
        line = line.replace('BMI  ','Pre-pregnancy BMI$^{a}$')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki2):
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Sample consists of all first-born, singleton children born to    "
           "White" + mnote + "mothers aged 25-45 for whom      "
           "education and smoking during pregnancy are available. Good season"
           "refers to birth quarters 2 and 3 (Apr-Jun and Jul-Sept). Bad     "
           "season refers to quarters 1 and 4 (Jan-Mar and Oct-Dec). ART     "
           "refers to the proportion of women who undertook assisted         "
           "reproductive technologies that resulted in these births.         "
           "$^{a}$ Only available from 2009."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}}        "
           "\\end{center}\\end{table}")
sumT.close()

#==============================================================================
#== (3b) Basic Sum stats (Spain)
#==============================================================================
sumT = open(TAB + 'sumStatsSpain.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
           '\\caption{Descriptive Statistics All Ages (Spain 2007-2013)}\n '
           '\\label{bqTab:SumStatsSpain}'
           '\\begin{tabular}{lccccc} '
           '\n \\toprule\\toprule \\vspace{5mm} \n'
           '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
           '\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumSpain,  'r').readlines()
MP  = open(MumPSpain, 'r').readlines()
Ki  = open(KidSpain,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP):
    if i>8 and i<11:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki):
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to Spanish "
           "mothers of any age ocurring in the Spanish birth register. Good "
           " season refers to birth quarters 2 and 3 (Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()


sumT = open(TAB + 'sumStatsSampSpain.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
           '\\caption{Descriptive Statistics Main Sample (Spain 2007-2013)}\n '
           '\\label{bqTab:SumStatsMainSpain}'
           '\\begin{tabular}{lccccc} '
           '\n \\toprule\\toprule \\vspace{5mm} \n'
           '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
           '\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu2  = open(MumSpain2,  'r').readlines()
MP2  = open(MumPSpain2, 'r').readlines()
Ki2  = open(KidSpain2,  'r').readlines()

for i,line in enumerate(Mu2):
    if i>8 and i<12:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
    if i>12 and i<17:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP2):
    if i>8 and i<11:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki2):
    if i>8 and i<16:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to married   "
           "Spanish mothers aged between 25-45.  This is the main estimation  "
           "sample. Good season refers to birth quarters 2 and 3              "
           " (Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

#==============================================================================
#== (3c) Basic Sum stats (IPUMS)
#==============================================================================
sumT = open(TAB + 'sumStatsIPUMS.tex', 'w')
SI = open(sumIPUMS, 'r').readlines()

sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (ACS 2005-2014)}\n '
'\\label{bqTab:SumStatsIPUM}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n')

for i,line in enumerate(SI):
    if i>8 and i<19:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[7]+tcm[7]+mc3+
           "We focus on White non-Hispanic married women aged 25-45 who are   "
           "either head of the household or spouse of the head of the         "
           "household, and have a first singleton child who is \emph{at most} "
           "one year old. We exclude women who are in the military, in a farm "
           "household, or currently in school. We retain only women who had   "
           "worked within the previous five years where each occupation must  "
           "have at least 500 women over the entire range of survey years.    "
           "Good season refers to children born in birth quarters 2 and 3     "
           "(Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()


sumIPUMSh = RES + 'hisp/ipums/sumStats/IPUMSstats.tex'
sumT = open(TAB + 'sumStatsIPUMS_hisp.tex', 'w')
SI = open(sumIPUMSh, 'r').readlines()

sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (ACS 2005-2014)}\n '
'\\label{bqTab:SumStatsIPUM}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n')

for i,line in enumerate(SI):
    if i>8 and i<20:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[7]+tcm[7]+mc3+
           "We focus on White married women aged 25-45 who are   "
           "either head of the household or spouse of the head of the         "
           "household, and have a first singleton child who is \emph{at most} "
           "one year old. We exclude women who are in the military, in a farm "
           "household, or currently in school. We retain only women who had   "
           "worked within the previous five years where each occupation must  "
           "have at least 500 women over the entire range of survey years.    "
           "Good season refers to children born in birth quarters 2 and 3     "
           "(Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

#==============================================================================
#== (4) IPUMS Industry clean
#==============================================================================
IndTabs = ['IPUMSIndustry_IncEduc.tex'  ,'IPUMSIndustry.tex'         ,
           'IPUMSIndustry_Income.tex'   ,'IPUMSIndustry_NoEduc.tex'  ,
           'IPUMSIndustry_noSelfEmp.tex','IPUMSIndustry_SelfEmpD.tex',
           'IPUMSIndustryWeeksWork.tex' ,'IPUMSIndustryWeeks_Int.tex',
           'EducSq_IPUMSIndustry.tex'   ,'IPUMSIndustryMLeave.tex'   ,
           'IPUMSIndustryNoMLeave.tex'  ,'IPUMSIndustryPLeaveAB.tex' ,
           'IPUMSIndustry_cold.tex'     ,'IPUMSIndustry_warm.tex'    ,
           'IPUMSIndustryPLeaveCE.tex'  ,'IPUMSIndustryPLeaveF.tex'  ]
for table in IndTabs:
    IPUMSind  = RES + 'ipums/regressions/'+table

    ipoT = open(TAB + table, 'w')
    ipiT = open(IPUMSind, 'r').readlines()

    for i,line in enumerate(ipiT):
        line = line.replace('oneLevelOcc==','')
        line = line.replace('twoLevelOcc==','')
        line = line.replace('Occupations','')
        line = line.replace('Occpations==','')
        line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                            '\\end{footnotesize}}\\end{tabular}}\\end{table}')
        line = line.replace('\\begin{tabular}{l*{3}{c}}',
                            '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
        ipoT.write(line)

    ipoT.close()


#HISPANIC TABS
IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustry.tex'
ipoT = open(TAB + 'IPUMSIndustry_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustry_cold.tex'
ipoT = open(TAB + 'IPUMSIndustrycold_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustry_warm.tex'
ipoT = open(TAB + 'IPUMSIndustrywarm_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()


IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ2.tex'
ipoT = open(TAB + 'IPUMSIndustryQ2_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ3.tex'
ipoT = open(TAB + 'IPUMSIndustryQ3_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ2-cold.tex'
ipoT = open(TAB + 'IPUMSIndustryQ2cold_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ3-cold.tex'
ipoT = open(TAB + 'IPUMSIndustryQ3cold_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ2-warm.tex'
ipoT = open(TAB + 'IPUMSIndustryQ2warm_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustryQ3-warm.tex'
ipoT = open(TAB + 'IPUMSIndustryQ3warm_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.82}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()


IPUMSind  = RES + 'hisp/ipums/regressions/IPUMSIndustry_IncEduc.tex'
ipoT = open(TAB + 'IPUMSIndustry_IncEduc_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.76}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()
IPUMSind  = RES + 'hispall/ipums/regressions/IPUMSIndustry.tex'
ipoT = open(TAB + 'IPUMSIndustryBoth_hisp.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.76}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()
IPUMSind  = RES + 'hisp/ipums/t-reg/regressions/IPUMSIndustry.tex'
ipoT = open(TAB + 'IPUMSIndustry_hisp-t.tex', 'w')
ipiT = open(IPUMSind, 'r').readlines()
for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.76}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

    
    

    
ipoT = open(TAB + 'IPUMSIndustry_GSample.tex', 'w')
ipiT = open(IPUMSind2, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    ipoT.write(line)
ipoT.close()

ipoT = open(TAB + 'IPUMSIndustryBoth.tex', 'w')
ipiT = open(IPUMSind3, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('oneLevelOcc==','')
    line = line.replace('twoLevelOcc==','')
    line = line.replace('Occupations','')
    line = line.replace('Occpations==','')
    line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                        '\\end{footnotesize}}\\end{tabular}}\\end{table}')
    line = line.replace('\\begin{tabular}{l*{3}{c}}',
                        '\\scalebox{0.7}{\\begin{tabular}{l*{3}{c}}')
    ipoT.write(line)
ipoT.close()

ipoT = open(TAB + 'IPUMSIndustryGoldin.tex', 'w')
ipiT = open(IPUMSindG, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('GoldinClass==','')
    ipoT.write(line)
ipoT.close()

ipoT = open(TAB + 'IPUMSIndustryGoldinTeachers.tex', 'w')
ipiT = open(IPUMSindG2, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('GoldinClass==','')
    ipoT.write(line)
ipoT.close()


ipoT = open(TAB + 'SpainIndustry.tex', 'w')
ipiT = open(SpainInd, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('professionMother==','')
    ipoT.write(line)
ipoT.close()

ipoT = open(TAB + 'SpainTradeoff.tex', 'w')
ipiT = open(SpainTO, 'r').readlines()

for i,line in enumerate(ipiT):
    line = line.replace('professionMother==','')
    ipoT.write(line)
ipoT.close()



#==============================================================================
#== (Xi) write tables.tex file
#==============================================================================
#===== TABLE 1: Sum stats with sample
#===== TABLE 2: Percent good season
#===== TABLE 3: Good season
#===== TABLE 4: Education (?)
#===== TABLE 5: ART table
#===== TABLE 6: Fetal Deaths included
#===== TABLE 7: IPUMS Full careers
#===== TABLE 8: IPUMS with teachers 
#===== TABLE 9: Teachers X Mothers 
#===== TABLE 10: Quality
#==============================================================================
tabs  = './../tables/'
nvss  = './../results/nvss/regressions/'
nall  = './../results/nvssall/regressions/'
espa  = './../results/spain/regressions/'
ipum  = './../results/ipums/regressions/'
ipumb = './../results/ipums/both/regressions/'
final = open(TAB + "tables.tex", 'w')

TABLES = [tabs+'sumStatsSampnvss.tex'    , tabs+'sumsinglenvss.tex'     ,  
          nvss+'NVSSBinaryMain.tex'      , nvss+'NVSSBinaryTwinS.tex'   ,
          nvss+'NVSSBinaryFDeaths.tex'   , nvss+'ART2024.tex'           , 
          tabs+'IPUMSIndustry.tex'       , ipum+'IPUMSTeachers.tex'     ,
          ipum+'ValueGoodSeasonInc.tex'  , nvss+'NVSSQualityMain.tex'   ,
          nvss+'NVSSQualityMain_NC.tex'                                 ]

i = 1

for table in TABLES:
    if i<3 or i==5 or i==7 or i==9:
        final.write('\\input{'
                    +table+'}\n')
    elif i==3 or i==10:
        final.write('\\begin{subtables}\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    elif i==4 or i==11:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\\end{subtables}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()

#==============================================================================
#== (Xii) write appendix tables A tex file
#==============================================================================
#===== Appendix A: Additional Descriptive Statistics
#===== TABLE A1: Sum stats with all data
#===== TABLE A2: IPUMS descriptives
#===== TABLE A3: IPUMS birth quarters
#==============================================================================
final = open(TAB + "appendixTablesA.tex", 'w')
TABLES = [nvss +'NVSSBinaryNoSep.tex'   , tabs+'sumStatsIPUMS.tex'          , 
          tabs +'sumIPUMS.tex'          , nvss +'NVSSBinaryMain_robust.tex' ,
          nvss +'NVSSBinaryFDeaths.tex' , nvss +'NVSSBinaryBord2.tex'       ,
          nvss +'NVSSBinaryTwinS.tex'   , nvss +'NVSSBinaryTwin.tex'        ,
          tabs +'IPUMSIndustry_IncEduc.tex' ,     ipum+'ValueGoodSeason.tex']

i = 1
for table in TABLES:
    if i==2 or i==3 or i==5 or i==9:
        final.write('\\input{' +table+ '}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()

#==============================================================================
#== (Xiii) write appendix tables B tex file
#==============================================================================
#===== Appendix B: Supplementary Results for good season
#===== TABLE B1: Robustness adding unemployment and trends
#===== TABLE B2: Bord 2 results
#===== TABLE B3: Twin results
#===== TABLE B4: No sep results
#===== TABLE B5: IPUMS other occupaton results
#===== TABLE B6: IPUMS value results with income
#==============================================================================
final = open(TAB + "appendixTablesB.tex", 'w')
TABLES = [nvss +'NVSSBinaryMain_robust.tex' , nvss +'NVSSBinaryBord2.tex',
          nvss +'NVSSBinaryTwin.tex'        , nvss +'NVSSBinaryNoSep.tex', 
          nvss +'NVSSBinaryMain_A.tex', tabs +'IPUMSIndustry_IncEduc.tex',
          ipum+'ValueGoodSeason.tex'                                     ]
i = 1
for table in TABLES:
    if i==6 or i==7 or i==8:
        final.write('\\input{'
                    +table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()


#==============================================================================
#== (Xiii) write appendix tables C tex file
#==============================================================================
#===== Appendix C: Replicating results with married and unmarried
final = open(TAB + "appendixTablesC.tex", 'w')
TABLES = [tabs+'sumStatsSampnvssall.tex'   , tabs+'sumsinglenvssall.tex'      ,  
          nall+'NVSSBinaryMain.tex'        , nall+'NVSSBinaryART.tex'         ,
          nall+'NVSSBinaryFDeaths.tex'     , nall+'ART2024.tex'               , 
          tabs+'IPUMSIndustryBoth.tex'     , ipum+'ValueGoodSeasonInc_all.tex',
          ipumb+'IPUMSTeachers.tex'        , nall+'NVSSQualityMain_NC.tex'    ,
          nall+'NVSSQualityMain.tex'       , nall+'NVSSQualityART_NC.tex'     ,
          nall+'NVSSQualityART_age.tex'    , nall+'NVSSQualityART.tex'        ]

i = 1

for table in TABLES:
    if i<3 or i==5 or i==7:
        final.write('\\input{'
                    +table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()


#==============================================================================
#== (Xiv) write appendix tables D tex file
#==============================================================================
#===== Appendix D: Spanish results
final = open(TAB + 'SpainTables.tex', 'w')
TABLES = [tabs +'sumStatsSpain.tex'          ,
          tabs +'sumStatsSampSpain.tex'      ,
          tabs +'sumSpain.tex'               ,
          espa +'spainBinaryMain.tex'        , 
          espa +'SpainBinaryEducAge.tex'     ,
          espa +'spainBinaryFDeaths.tex'     , 
          espa +'spainQuality.tex'           ,
          tabs +'SpainIndustry.tex'          ,
          espa +'spainBinaryBord2.tex'       , 
          espa +'spainBinaryTwin.tex'        , 
          espa +'spainBinarynoArmy.tex'      ] 

i = 1
for table in TABLES:
    if i==1 or i==2 or i==8:
        final.write('\\input{'
                    +table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()


#==============================================================================
#== (Xv) write appendix tables E tex file
#==============================================================================
#===== Appendix E: Teacher temperature results
final = open(TAB + "appendixTablesE.tex", 'w')
final.write('\\begin{landscape}\n\\input{')
final.write(ipum + 'IPUMSTeachersCold.tex')
final.write('}\n\\end{landscape}\n')
final.close()
