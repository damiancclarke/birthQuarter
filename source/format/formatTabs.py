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
twid = ['10','6','7','7','7','5']
tcm  = ['}{p{16.6cm}}','}{p{14.2cm}}','}{p{16.4cm}}','}{p{17.6cm}}'
        ,'}{p{12.8cm}}','}{p{9.8cm}}']
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
               "\multicolumn{5}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
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


sumT.write("\\begin{landscape}\\begin{table}[htpb!]"
           "\\caption{Percent of Births, Singletons} \n"
           "\\label{bqTab:SpainSum}\\begin{center}"
           "\\begin{tabular}{lcccc}\n\\toprule \\toprule \n"
           "& Bad    & Good   & Diff. & Ratio \\\\\n"
           "& Season & Season &       &       \\\\\\midrule"
           "\multicolumn{5}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
sumT.write(NV[1]+'\\\\ \n'
           +NV[2]+'\\\\ \n &&&& \\\\'
           "\multicolumn{5}{l}{\\textsc{Panel B: By Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVj[1]+'\\\\ \n'+
           NVj[2]+'\\\\ \n &&&& \\\\'
           "\multicolumn{5}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
           NVe[1]+'\\\\ \n'+
           NVe[2]+'\\\\ \n'+
           NVe[3]+'\\\\ \n'+
           NVe[4]+'\\\\ \n &&&& \\\\'
           )
    
    
sumT.write('\n'+mr+mc1+twid[5]+tcm[5]+mc3+
           "Good season refers to birth quarters 2 and 3 (Apr-Jun and "
           "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar "
           "and Oct-Dec).  Values reflect the percent of yearly births from "
           "each season in 2013. `Young' refers to 25-39 year olds,"
           " `Old' refers to 40-45 year olds. \n"
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
           "\\end{center}\\end{table}\\end{landscape}")
    
sumT.close()


#==============================================================================
#== (3) Basic Sum stats (NVSS)
#==============================================================================
sumT = open(TAB + 'sumStats'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (NVSS 2005-2013)}\n \\begin{tabular}{lccccc} '
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
    if i>8 and i<17:
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
'\\caption{Descriptive Statistics (Spain 2013)}\n \\begin{tabular}{lccccc} '
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
hetT = open(TAB + 'quarterHeterogeneity.tex', 'w')
loc  = './../../results/nvss/regressions/'
rt3  = '/regressions/NVSSBinaryMain.tex'

table = [
'Aged 25-39'    ,'',
'Some College +','',
'Married'       ,'',
'Smoked in Preg','',
'Constant'      ,'',
'Observations'
]
samples = [loc+'NVSSBinaryMain.tex'   ,loc+'NVSSBinarynon-smoking.tex',
           loc+'NVSSBinarysmoking.tex',loc+'NVSSBinary2012-2013.tex'  ,
           loc+'NVSSBinarynon-ART.tex',loc+'NVSSBinaryART.tex'        ]


ii = 0
for sample in samples:
    if ii ==1 or ii==2:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=13 or i==15:
                while jj >= 4 and jj <=7:
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
            if i>=8 and i<=17 or i==19:
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
+table[9]+'\\\\ \\midrule \n'
+table[10]+'\\\\ \n'
)


hetT.write('\n'+mr+mc1+twid[2]+tcm[2]+mc3+
           'All specifications are linear probability models estimates by OLS w'
           'ith heteroscedasticity-robust standard errors. Full term in column '
           'Infertility treatment regressions are only estimated for years 2012'
           '-2013.\\end{footnotesize}}\\\\ \n \\bottomrule '
           '\n\\end{tabular}\\end{center}\\end{table}'
)
hetT.close()

#==============================================================================
#== (4b) Heterogeneity table (quality)
#==============================================================================
hetT = open(TAB + 'qualityHeterogeneity.tex', 'w')
loc  = './../../results/nvss/regressions/'

table = [
'Aged 25-39'    ,'',
'Bad Season    ','',
'Some College +','',
'Married'       ,'',
'Smoked in Preg','',
'Constant'      ,'',
'Observations'
]

samples = [loc+'NVSSQualityMain.tex'   ,loc+'NVSSQualitynon-smoking.tex',
           loc+'NVSSQualitysmoking.tex',loc+'NVSSQuality2012-2013.tex'  ,
           loc+'NVSSQualitynon-ART.tex',loc+'NVSSQualityART.tex'        ]

ii = 0
for sample in samples:
    if ii ==1 or ii==2:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=13 or i==15:
                while jj >= 4 and jj <=9:
                    print jj
                    table[jj]+= '&'
                    jj = jj+1

                line = line.split('&')[2]
                table[jj] += '&'+line
                jj = jj+1
    else:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=19 or i==21:
                line = line.split('&')[2]
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
+table[1 ] + '\\\\ \n'
+table[2 ] + '\\\\ \n'
+table[3 ] + '\\\\ \n'
+table[4 ] + '\\\\ \n'
+table[5 ] + '\\\\ \n'
+table[6 ] + '\\\\ \n'
+table[7 ] + '\\\\ \n'
+table[8 ] + '\\\\ \n'
+table[9 ] + '\\\\ \n'
+table[10] + '\\\\ \n'
+table[11] + '\\\\ \\midrule \n'
+table[12] + '\\\\ \n'
)


hetT.write('\n'+mr+mc1+twid[3]+tcm[3]+mc3+
           'All specifications are identical to column (2) of table 5 estimated'
           ' by OLS with heteroscedasticity-robust standard errors. Full term i'
           'n column (4) refers to any babies whose gestation was greater than '
           'or equal to 39 weeks. Infertility treatment regressions are only es'
           'timated for years 2012-2013.'
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
loc2+'NVSSBinaryMain.tex'             , loc1+'quarterHeterogeneity.tex',
loc2+'NVSSBinaryEdInteract.tex'       , loc2+'NVSSBinaryYoung34.tex'   , 
loc2+'NVSSseasonMLogit.tex'           , loc2+'NVSSQualityEduc.tex'     ,
loc1+'qualityHeterogeneity.tex'       , loc2+'QualityAllComb.tex'
]

#            , 
#         , loc2+'NVSSQualityGFYoung1.tex' ,
#loc2+'NVSSQualityGFYoung0.tex'        , loc3+'spainBinary.tex'         ,       
#loc3+'spainQualityEduc.tex'           , loc3+'spainQualityGestFix.tex' ]

itera = 1

for table in TABLES:
    if itera<4 or itera==5 or itera==6 or itera==7:
        final.write('\\input{'
                    +table+'}\n')
    if itera==4 or itera==8 or itera==9 or itera==10:
        final.write('\\begin{landscape}\n\\input{'
                    +table+'}\n\\end{landscape}\n')
    itera = itera+1
final.close()
