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
dloc  = './../'

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

sumNVSS = RES + ftype + '/sumStats/nvssSum.tex'
MumNVSS = RES + ftype + '/sumStats/nvssMum.tex'
MumPNVSS= RES + ftype + '/sumStats/nvssMumPart.tex'
KidNVSS = RES + ftype + '/sumStats/nvssKid.tex'
sumIPUMS= RES + 'ipums/sumStats/IPUMSstats.tex'

MumNVSS2 = RES + ftype + '/sumStats/sampMum.tex'
MumPNVSS2= RES + ftype + '/sumStats/sampMumPart.tex'
KidNVSS2 = RES + ftype + '/sumStats/sampKid.tex'


MumSpain  = RES + 'spain' + '/sumStats/SpainMum.tex'
MumPSpain = RES + 'spain' + '/sumStats/SpainMumPart.tex'
KidSpain  = RES + 'spain' + '/sumStats/SpainKid.tex'
MumSpain2 = RES + 'spain' + '/sumStats/SpainSmpMum.tex'
MumPSpain2= RES + 'spain' + '/sumStats/SpainSmpMumPart.tex'
KidSpain2 = RES + 'spain' + '/sumStats/SpainSmpKid.tex'

NVSSGoodE =  RES + ftype + '/regressions/NVSSBinaryExpectGood.tex'
NVSSBadE  =  RES + ftype + '/regressions/NVSSBinaryExpectBad.tex'

IPUMSind  = RES + 'ipums/regressions/IPUMSIndustry.tex' 
IPUMSind2 = RES + 'ipums/regressions/IPUMSIndustry_GSample.tex' 
IPUMSindG = RES + 'ipums/regressions/IPUMSIndustryGoldin.tex' 
IPUMSindG2= RES + 'ipums/regressions/IPUMSIndustryGoldinTeachers.tex'

SpainInd  = RES + 'spain/regressions/SpainIndustry.tex' 

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
twid = ['10','6','7','7','7','6','5','6']
tcm  = ['}{p{16.6cm}}','}{p{14.2cm}}','}{p{15.6cm}}','}{p{17.6cm}}',
        '}{p{11.8cm}}','}{p{11.4cm}}','}{p{9.0cm}}','}{p{12.2cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2a) Write birth quarter summary tables NVSS
#==============================================================================
#tNV  = open(twinNVSS, 'r').readlines()
#tNVe = open(twinEducNVSS, 'r').readlines()
#tNVj = open(TallEducNVSS, 'r').readlines()
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

    sumT.write("\\begin{landscape}\\begin{table}[htpb!]"
               "\\caption{Percent of Births, "+headline+"} \n"
               "\\label{bqTab:"+parity+"Sum}\\begin{center}"
               "\\begin{tabular}{lcccccc}\n\\toprule \\toprule \n"
               "& \\multicolumn{4}{c}{Seasons} & "
               "\\multicolumn{2}{c}{Characteristics} \\\\ "
               "\cmidrule(r){2-5} \cmidrule(r){6-7} \n"
               "& Bad    & Good   & Diff. & Ratio & $< $37 & ART \\\\\n"
               "& Season & Season &       &       & Weeks  &     \\\\\\midrule"
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
               "Good season refers to birth quarters 2 and 3 (Apr-Jun and "
               "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar "
               "and Oct-Dec).  Values reflect the percent of yearly births "
               "each season from 2005-2013. \n"
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
               "\\end{center}\\end{table}\\end{landscape}")
    
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
           "\\caption{Percent of Births, Singletons} \n"
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
           NVj[2]+'\\\\ \n'+
           NVj[3]+'\\\\ \n &&&& \\\\'
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
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP):
    if i>8 and i<13:
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
    mnote = ' married '
elif ftype == 'nvssall':
    mnote = ' '

sumT = open(TAB + 'sumStatsSamp'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics Main Sample (NVSS 2005-2013)}\n '
'\\label{bqTab:SumStatsMain}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu2  = open(MumNVSS2,  'r').readlines()
MP2  = open(MumPNVSS2, 'r').readlines()
Ki2  = open(KidNVSS2,  'r').readlines()

for i,line in enumerate(Mu2):
    if i>8 and i<12:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
    if i>12 and i<17:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP2):
    if i>8 and i<13:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki2):
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to" + mnote  +
           "white, non-hispanic mothers aged between 25-45 for whom education,"
           " smoking, and marital status is recorded. This is the main        "
           "estimation sample. Good season refers to birth quarters 2 and 3   "
           " (Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
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
'\\caption{Descriptive Statistics (IPUMS 2005-2014)}\n '
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
           "Sample consists of all singleton first-born children from the ACS "
           "born in the USA to white non-hispanic married mothers aged 25-45  "
           "who are either the head of their household or the partner         "
           "           of the head of the household, and who work in an       "
           "occupation with at least 500 workers in the sample. Good season   "
           "refers to children born in birth quarters 2 and 3 (Apr-Jun and    "
           "Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

#==============================================================================
#== (4) IPUMS Industry clean
#==============================================================================
IndTabs = ['IPUMSIndustry_IncEduc.tex','IPUMSIndustry.tex',
           'IPUMSIndustry_Income.tex','IPUMSIndustry_NoEduc.tex']
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
                            '\\scalebox{0.7}{\\begin{tabular}{l*{3}{c}}')
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



#==============================================================================
#== (X) write tables.tex file
#==============================================================================
#===== TABLE 1: Descriptive Statistics                                        X
#===== TABLE 2: Percent births by season [G]                                  X
#===== TABLE 3: Birth by season                                               X
#===== TABLE 4: Heterogeneity birth season [G,l]                              X
#===== TABLE 5: Birth by season (interaction)                                 X
#===== TABLE 6: Birth by season (young)                                       X
#===== TABLE 7: Multinomial logit of expected and actual                       
#===== TABLE 8: Quality full [l]                                               
#===== TABLE 9: Quality heterogeneity bwt [G,l]                                
#===== TABLE 10: Qualilty gestation correction [l]                             
#===== TABLE 11: Spain DS1                                                     
#===== TABLE 12: Spain DS2                                                     
#===== TABLE 13: Spain quality [l]                                             
#===== TABLE 14: Spain quality gestation correction                            
#===== TABLE 15: Spain Qualilty gestation correction [l]                       
#==============================================================================
loc1  = './../tables/'
loc2  = './../results/'+ftype+'/regressions/'
loc3  = './../results/spain/regressions/'
final = open(TAB + "tables"+ ftype +".tex", 'w')

TABLES = [loc1+'sumStats'+ftype+'.tex', loc1 + 'sumStatsSamp'+ftype+'.tex',
loc1 + 'sumsingle'+ftype+'.tex'       , loc2 + 'NVSSBinaryMain.tex'       ,
loc2 + 'NVSSBinaryMain_robust.tex'    , loc2 + 'NVSSBinaryEducAge.tex'    ,
loc2 + 'ART2024.tex'                  , loc2 +'NVSSBinaryFDeaths.tex'     , 
loc2 + 'NVSSQualityMain.tex'                                              ]
          
i = 1

for table in TABLES:
    if i<4 or i==8:
        final.write('\\input{'
                    +table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()


#==============================================================================
#== (X) write appendixTables.tex file
#==============================================================================
loc70 = './../results/1970s/regressions/'
loc90 = './../results/1990s/regressions/'
locB2 = './../results/bord2/regressions/'
loctw = './../results/nvss/regressions/'
spain = './../results/spain/regressions/'
final = open(TAB + ftype + 'AppendixTables.tex', 'w')

TABLES = [loc2 +'NVSSPremature.tex'          ,
          loc2 +'NVSSBinaryBord2.tex'        ,
          loc2 +'NVSSBinaryTwin.tex'         ,
          loc2 +'NVSSBinaryMain_A.tex'       , 
          loc2 +'NVSSBinaryNoSep.tex'        , 
          loc2 +'NVSSQualityBord2.tex'       ,
          loc2 +'NVSSQualityTwin.tex'        , 
          loc2 +'NVSSQualityFDeaths.tex'     ]

i = 1
for table in TABLES:
    if i==1:
        final.write('\\input{'+table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1

final.close()

#==============================================================================
#== (X) write SpainTables.tex file
#==============================================================================
final = open(TAB + 'SpainTables.tex', 'w')

TABLES = [loc1 +'sumStatsSpain.tex'          ,
          loc1 +'sumStatsSampSpain.tex'      ,
          loc1 +'sumSpain.tex'               ,
          loc3 +'spainBinaryMain.tex'        , 
          loc3 +'SpainBinaryEducAge.tex'     ,
          loc3 +'spainBinaryFDeaths.tex'     , 
          spain+'spainQuality.tex'           ,
          loc1 +'SpainIndustry.tex'          ,
          loc3 +'spainBinaryBord2.tex'       , 
          loc3 +'spainBinaryTwin.tex'        , 
          loc3 +'spainBinarygirls.tex'       , 
          loc3 +'spainBinaryboys.tex'        ,
          loc3 +'spainBinarynoArmy.tex'      ] 

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

