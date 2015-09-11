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
RES   = "/home/damiancclarke/investigacion/2015/birthQuarter/results/"
TAB   = "/home/damiancclarke/investigacion/2015/birthQuarter/tables/"
ftype = 'nvss'
dloc  = './../'

singleNVSS       = RES + ftype + '/sumStats/FullSample.txt'
singleEducNVSS   = RES + ftype + '/sumStats/EducSample.txt'
allEducNVSS      = RES + ftype + '/sumStats/JustEduc.txt'
singleSpain      = RES + 'spain/sumStats/FullSample.txt'
singleEducSpain  = RES + 'spain/sumStats/EducSample.txt'
allEducSpain     = RES + 'spain/sumStats/JustEduc.txt'


twinNVSS       = RES + ftype + '/sumStats/FullSampletwins.txt'
twinEducNVSS   = RES + ftype + '/sumStats/EducSampletwins.txt'
TallEducNVSS   = RES + ftype + '/sumStats/JustEductwins.txt'

sumNVSS = RES + ftype + '/sumStats/nvssSum.tex'
MumNVSS = RES + ftype + '/sumStats/nvssMum.tex'
MumPNVSS= RES + ftype + '/sumStats/nvssMumPart.tex'
KidNVSS = RES + ftype + '/sumStats/nvssKid.tex'

MumSpain = RES + 'spain' + '/sumStats/SpainsumM.tex'
KidSpain = RES + 'spain' + '/sumStats/SpainsumK.tex'

NVSSGoodE =  RES + ftype + '/regressions/NVSSBinaryExpectGood.tex'
NVSSBadE  =  RES + ftype + '/regressions/NVSSBinaryExpectBad.tex'

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
twid = ['10','6','7','7','7','6']
tcm  = ['}{p{16.6cm}}','}{p{13.4cm}}','}{p{15.6cm}}','}{p{17.6cm}}'
        ,'}{p{12.8cm}}','}{p{12.2cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2a) Write birth quarter summary tables NVSS
#==============================================================================
tNV  = open(twinNVSS, 'r').readlines()
tNVe = open(twinEducNVSS, 'r').readlines()
tNVj = open(TallEducNVSS, 'r').readlines()
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
    
    sumT.write(NV[1]+'\\\\ \n'
               +NV[2]+'\\\\ \n &&&& \\\\'
               "\multicolumn{7}{l}{\\textsc{Panel B: By Education}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               NVj[1]+'\\\\ \n'+
               NVj[2]+'\\\\ \n &&&& \\\\'
               "\multicolumn{7}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               NVe[1]+'\\\\ \n'+
               NVe[2]+'\\\\ \n'+
               NVe[3]+'\\\\ \n'+
               NVe[4]+'\\\\ \n &&&& \\\\'
               )
    
    
    sumT.write('\n'+mr+mc1+twid[4]+tcm[4]+mc3+
               "Good season refers to birth quarters 2 and 3 (Apr-Jun and "
               "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar "
               "and Oct-Dec).  Values reflect the percent of yearly births "
               "each season from 2005-2013. `Young' refers to 25-39 year olds,"
               " `Old' refers to 40-45 year olds. \n"
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
    
sumT.write(NV[1]+'\\\\ \n'
           +NV[2]+'\\\\ \n &&&&& \\\\'
           "\multicolumn{6}{l}{\\textsc{Panel B: By Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*5+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVj[1]+'\\\\ \n'+
           NVj[2]+'\\\\ \n &&&&& \\\\'
           "\multicolumn{6}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*5+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVe[1]+'\\\\ \n'+
           NVe[2]+'\\\\ \n'+
           NVe[3]+'\\\\ \n'+
           NVe[4]+'\\\\ \n &&&&& \\\\'
           )
    
    
sumT.write('\n'+mr+mc1+twid[5]+tcm[5]+mc3+
           "Good season refers to birth quarters 2 and 3 (Apr-Jun and "
           "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar "
           "and Oct-Dec).  Values reflect the percent of yearly births from "
           "each season in 2013. `Young' refers to 25-39 year olds,"
           " `Old' refers to 40-45 year olds. \n"
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
           "\\end{center}\\end{table}")
    
sumT.close()


#==============================================================================
#== (3) Basic Sum stats (NVSS)
#==============================================================================
sumT = open(TAB + 'sumStats'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (NVSS 2005-2013)}\n '
'\\label{bqTab:SumStatsNVSS}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumNVSS,  'r').readlines()
MP  = open(MumPNVSS, 'r').readlines()
Ki  = open(KidNVSS,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<12:
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
           "non-hispanic, US-born mothers. Good season refers to birth quarters"
           " 2 and 3 (Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()


#==============================================================================
#== (3b) Basic Sum stats (Spain)
#==============================================================================
sumT = open(TAB + 'sumStatsSpain.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (Spain 2013)}\n '
'\\label{bqTab:SumStatsSpain}'
'\\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumSpain,  'r').readlines()
Ki  = open(KidSpain,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<15:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki):
    if i>8 and i<16:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Sample consists of all singleton first-born children of Spanish   "
           "mothers. Good season refers to birth quarters 2 and 3 (Apr-Jun and"
           " Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

#==============================================================================
#== (4a) Heterogeneity table (birth quarter)
#==============================================================================
for vAge in ['.tex', '_A.tex', '_A2.tex']:
    hetT = open(TAB + 'quarterHeterogeneity' + vAge, 'w')
    loc  = './../../results/nvss/regressions/'
    rt3  = '/regressions/NVSSBinaryMain.tex'

    inum = [13,15,17,19]
    jnum = [4,7]

    if vAge == '.tex':
        label1 = 'Aged 25-29'
    if vAge == '_A.tex':
        label1 = 'Mother\'s Age (Years)'        
    table = [
        label1          ,'',
        'Some College +','',
        'Married'       ,'',
        'Smoked in Preg','',
        'Constant'      ,'',
        'Observations'
    ]
    if vAge == '_A2.tex':
        table = [
            'Mother\'s Age (Years)'  ,'',
            'Mother\'s Age$^2$'      ,'',
            'Some College +'         ,'',
            'Married'                ,'',
            'Smoked in Preg'         ,'',
            'Constant'               ,'',
            'Observations'
        ]
        inum = [15,17,19,21]
        jnum = [6,9]



    samples = [loc+'NVSSBinaryMain'+vAge   , loc+'NVSSBinarynon-smoking'+vAge,
               loc+'NVSSBinarysmoking'+vAge, loc+'NVSSBinary2012-2013'+vAge  ,
               loc+'NVSSBinarynon-ART'+vAge, loc+'NVSSBinaryART'+vAge        ]


    ii = 0
    for sample in samples:
        if ii ==1 or ii==2:
            jj = 0
            work  = open(sample,  'r').readlines()
            for i,line in enumerate(work):
                if i>=8 and i<=inum[0] or i==inum[1]:
                    while jj >= jnum[0] and jj <=jnum[1]:
                        table[jj]+= '&'
                        jj = jj+1

                    line = line.split('&')[-1]
                    line = line[:-3]
                    table[jj] += '&'+line
                    jj = jj+1
        else:
            jj = 0
            work  = open(sample,  'r').readlines()
            for i,line in enumerate(work):
                if i>=8 and i<=inum[2] or i==inum[3]:
                    line = line.split('&')[-1]
                    line = line[:-3]
                    table[jj] += '&'+line
                    jj = jj+1
        ii = ii+1
    hetT.write('\\begin{table}[htpb!] \n ' 
    '\\caption{Birth Season and Age: Alternative Samples and Definitions}\n '
    '\\begin{center} \n'
    '\\begin{tabular}{lcccccc} \\toprule\\toprule \n'
    '\\textsc{Dep Var:}&(1)&(2)&(3)&(4)&(5)&(6)\\\\'
    'Good Season\ \ \ \ \ \ \ \ \ \ \  &&\multicolumn{2}{c}{Smoked During}&'
    '&\multicolumn{2}{c}{Assisted Reproductive}\\\\'
    '&&\multicolumn{2}{c}{Pregnancy}&'
    '&\multicolumn{2}{c}{Technology}'
    '\\\\\cmidrule(r){3-4}\cmidrule(r){6-7}\n'
    '&All&Non-  &Smoker&2012- &No&Yes \\\\'
    '&   &Smoker&       &2013\ &  &  \\\\ '
    '\\midrule\n')
    hetT.write(table[0]+'\\\\ \n'
               +table[1]+'\\\\ \n'
               +table[2]+'\\\\ \n'
               +table[3]+'\\\\ \n'
               +table[4]+'\\\\ \n'
               +table[5]+'\\\\ \n'
               +table[6]+'\\\\ \n'
               +table[7]+'\\\\ \n'
               +table[8]+'\\\\ \n'
    )
    if vAge == '_A2.tex':
        hetT.write(table[9]+'\\\\ \n'
                   +table[10]+'\\\\ \n'
                   +table[11]+'\\\\ \\midrule \n'
                   +table[12]+'\\\\ \n'
        )
    else:
        hetT.write(table[9]+'\\\\ \\midrule \n'
                   +table[10]+'\\\\ \n'
        )


    hetT.write('\n'+mr+mc1+twid[2]+tcm[2]+mc3+
           'All specifications are linear probability models estimates by OLS w'
           'ith heteroscedasticity-robust standard errors.                     '
           'Infertility treatment regressions are only estimated for years 2012'
           '-2013. Descriptive statistics for each variable are available in ta'
           'ble \\ref{bqTab:SumStatsNVSS}.'
           '\\end{footnotesize}}\\\\ \n \\bottomrule '
           '\n\\end{tabular}\\end{center}\\end{table}'
    )
    hetT.close()

#==============================================================================
#== (4b) Heterogeneity table (quality)
#==============================================================================
for vAge in ['.tex', '_A.tex', '_A2.tex']:

    hetT = open(TAB + 'qualityHeterogeneity' + vAge, 'w')
    loc  = './../../results/nvss/regressions/'


    inum = [15,17,19,21]
    jnum = [6,9]

    if vAge == '.tex':
        label1 = 'Aged 25-29'
    if vAge == '_A.tex':
        label1 = 'Mother\'s Age (Years)'        
    table = [
        label1          ,'',
        'Bad Season'    ,'',
        'Some College +','',
        'Married'       ,'',
        'Smoked in Preg','',
        'Constant'      ,'',
        'Observations'
    ]
    if vAge == '_A2.tex':
        table = [
            'Mother\'s Age (Years)'  ,'',
            'Mother\'s Age$^2$'      ,'',
            'Bad Season'    ,'',
            'Some College +'         ,'',
            'Married'                ,'',
            'Smoked in Preg'         ,'',
            'Constant'               ,'',
            'Observations'
        ]
        inum = [17,19,21,23]
        jnum = [8,11]



    samples = [loc+'NVSSQualityMain'+vAge   ,loc+'NVSSQualitynon-smoking'+vAge,
               loc+'NVSSQualitysmoking'+vAge,loc+'NVSSQuality2012-2013'+vAge  ,
               loc+'NVSSQualitynon-ART'+vAge,loc+'NVSSQualityART'+vAge        ]

    ii = 0
    for sample in samples:
        if ii ==1 or ii==2:
            jj = 0
            work  = open(sample,  'r').readlines()
            for i,line in enumerate(work):
                if i>=8 and i<=inum[0] or i==inum[1]:
                    while jj >= jnum[0] and jj <= jnum[1]:
                        table[jj]+= '&'
                        jj = jj+1

                    line = line.split('&')[1]
                    table[jj] += '&'+line
                    jj = jj+1
        else:
            jj = 0
            work  = open(sample,  'r').readlines()
            for i,line in enumerate(work):
                if i>=8 and i<=inum[2] or i==inum[3]:
                    line = line.split('&')[1]
                    table[jj] += '&'+line
                    jj = jj+1
        ii = ii+1
    hetT.write('\\begin{table}[htpb!] \n '
    '\\caption{Birth Quality and Age: Alternative Samples and Definitions}\n '
    '\\begin{center} \n'
    '\\begin{tabular}{lcccccc} \\toprule\\toprule \n'
    '\\textsc{Dep Var:}&(1)&(2)&(3)&(4)&(5)&(6)\\\\'
    'Birthweight&&\multicolumn{2}{c}{Smoked During}&'
    '&\multicolumn{2}{c}{Assisted Reproductive}\\\\'
    '&&\multicolumn{2}{c}{Pregnancy}&'
    '&\multicolumn{2}{c}{Technology}'
    '\\\\\cmidrule(r){3-4}\cmidrule(r){6-7}\n'
    '&All&Non-  &Smoker&2012- &No&Yes \\\\'
    '&   &Smoker&      &2013\ &  &    \\\\ \\midrule\n')

    hetT.write(table[0]+'\\\\ \n'
               +table[1]+'\\\\ \n'
               +table[2]+'\\\\ \n'
               +table[3]+'\\\\ \n'
               +table[4]+'\\\\ \n'
               +table[5]+'\\\\ \n'
               +table[6]+'\\\\ \n'
               +table[7]+'\\\\ \n'
               +table[8]+'\\\\ \n'
               +table[9]+'\\\\ \n'
               +table[10]+'\\\\ \n'
    )
    if vAge == '_A2.tex':
        hetT.write(table[11]+'\\\\ \n'
                   +table[12]+'\\\\ \n'
                   +table[13]+'\\\\ \\midrule \n'
                   +table[14]+'\\\\ \n'
        )
    else:
        hetT.write(table[11]+'\\\\ \\midrule \n'
                   +table[12]+'\\\\ \n'
        )

    hetT.write('\n'+mr+mc1+twid[3]+tcm[3]+mc3+
           'All specifications are identical to column (2) of table 5 estimated'
           ' by OLS with heteroscedasticity-robust standard errors. Full term i'
           'n column (4) refers to any babies whose gestation was greater than '
           'or equal to 39 weeks. Infertility treatment regressions are only es'
           'timated for years 2012-2013. Descriptive statistics for variables  '
           'are available in table \\ref{bqTab:SumStatsNVSS}.'
           '\\end{footnotesize}}\\\\ \\bottomrule \n\\end{tabular}\\end{center}'
           '\\end{table}'
    )
    hetT.close()

#==============================================================================
#== (5) Fix labelling of gestation correction table
#==============================================================================
goodT = open(NVSSGoodE, 'r').readlines()
badT  = open(NVSSBadE , 'r').readlines()

outG = open(TAB + 'NVSSBinaryExpectGood.tex', 'w')
outB = open(TAB + 'NVSSBinaryExpectBad.tex' , 'w')

for line in goodT:
    line = line.replace('(due in good)','')
    line = line.replace('\\midrule'    ,'')
    line = line.replace('Aged','&(due in good)'*4+'\\\\ \\midrule\n Aged')
    line = line.replace('Observations','\\midrule\n Observations')
    outG.write(line)
for line in badT:
    line = line.replace('(due in bad)','')
    line = line.replace('\\midrule'    ,'')
    line = line.replace('Aged','&(due in bad)'*4+'\\\\ \\midrule\n Aged')
    line = line.replace('Observations','\\midrule\n Observations')
    outB.write(line)

outG.close
outB.close

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

TABLES = [loc1+'sumStats'+ftype+'.tex', loc1+'sumsingle'+ftype+'.tex'  ,
loc2+'NVSSBinaryMain.tex'             , loc2+'NVSSExpectMain.tex'      ,
loc2+'NVSSBinaryEdInteract.tex'       , loc2+'NVSSQualityEduc.tex'     ,
loc2+'QualityAllComb.tex'             , loc2+'QualityAllCombExp.tex'   ,
loc1+'sumStatsSpain.tex'              , loc1+'sumSpain.tex'            ,
loc3+'spainBinary.tex'                , loc3+'spainQualityEduc.tex'    ,
loc3+'spainQualityGestFix.tex'
]

i = 1

for table in TABLES:
    if i<3 or i==9 or i==10:
        final.write('\\input{'
                    +table+'}\n')
    elif i==5:
        final.write('%\\input{'
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
final = open(TAB + 'appendixTables.tex', 'w')

TABLES = [loc2 +'NVSSBinaryFDeaths.tex'      , 
          loc2 +'NVSSBinaryYoung34.tex'      , 
          TAB  +'quarterHeterogeneity_A.tex' ,
          TAB  +'qualityHeterogeneity_A.tex' ,
          TAB  +'quarterHeterogeneity_A2.tex',
          TAB  +'qualityHeterogeneity_A2.tex',
          locB2+'NVSSBinary.tex'             ,
          locB2+'NVSSQualityEducAll.tex'     ,
          loctw+'NVSSBinaryTwin.tex'         ,
          loctw+'NVSSQualityTwin.tex'        ,
          loctw+'NVSSBinaryunmarried.tex'    ,
          loctw+'NVSSQualityunmarried.tex'   ,
          loc90+'NVSSBinary.tex'             ,  
          loc90+'NVSSseasonMLogit.tex'       ,
          loc90+'QualityAllCombnoFE.tex'     ,
          loc90+'NVSSBinaryWeather.tex'      ,
          loc90+'NVSSQualityWeather.tex'     ,
          loc90+'NVSSQualityWarm.tex'        ,
          loc90+'NVSSQualityCold.tex'        ,
          loc90+'NVSSQualityWInterac.tex'    ,
          spain+'spainBinaryLForce.tex'
]

i = 1
for table in TABLES:
    if i==1 or i==6 or i==8 or i==10 or i==13:
        final.write('\\input{'
                    +table+'}\n')
    else:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    i = i+1
final.close()
