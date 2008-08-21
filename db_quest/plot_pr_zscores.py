#!/usr/bin/python

import sys
import syck
import os
import re
from matplotlib.font_manager import *
from pylab import *
from optparse import OptionParser

from matplotlib.font_manager import *

#####################################################
axhline_color = '#999999'
linewidth = 1.0
#colors = ['k','r', 'b', 'g', 'm']
#           black      red        blue       green      dark yel  magenta    olive green off blue  brown
#mycolors = ['#000000', '#FF0000', '#0000FF', '#00BB00', '#CCCC00', '#FF00FF', '#2D872D', '#4B4B83', '#A98638', '#00CCCC', '#993311', '#113399']
## combined datasets:
mycolors = ['#00BB00', '#11FF11', '#22CC00', '#00BB22', '#339933', '#669911', '#778822', '#559977', '#111188', '#0000BB', '#3333FF', '#0033CC', '#000055', '#FF0000', '#AA2222', '#773300', '#CC0033', '#7777FF', '#6622BB']  # not sure why need last
#mycolors = ['#0000FF', '#2222FF', '#0000AA', '#5500FF', '#FF0000', '#FF2222','#AA0000','#FF0055']
mycolors = ['#00FF00', '#11CC11', '#000000', '#339933', '#55AA00', '#99AA00','#0000FF', '#1111CC', '#FF0000', '#333399', '#5500AA', '#9900AA']
#mycolors = ['#0000FF', '#333399', '#00FF00', '#22AA22', '#CCCC00', '#999911','#FF0000','#AA2222']
#mydashes = [[1,0], [4,2], [3,3,1,3], [1,2], [7,2,1,2,1,2], [7,2,5,2,3,2,1,2], [6,1], [8,2,1,1,5,2,1,2]]
## more shuffle prob datasets:
#mycolors = ['#00BB00', '#11FF11', '#22CC00', '#00BB22', '#339933', '#669911', '#778822', '#559977', '#111188', '#0000BB', '#3333FF', '#0033CC', '#000055', '#FF0000', '#AA2222', '#773300', '#CC0033', '#7777FF', '#6622BB']  # not sure why need last

mycolors = mycolors + mycolors + mycolors + mycolors + mycolors 
#mydashes = [[1,0], [1,0], [1,0], [1,0], [4,2],[4,2],[4,2],[4,2],[4,2]]
mydashes = [[1,0], [4,2], [3,3,1,3], [1,2], [7,2,1,2,1,2], [7,2,5,2,3,2,1,2], [6,1], [8,2,1,1,5,2,1,2]]
#mydashes = [[1,0], [1,0], [1,0], [1,0], [4,2],[4,2],[4,2],[4,2],[4,2]]

mydashes = mydashes + mydashes + mydashes + mydashes + mydashes + mydashes
zlegend_loc = 'lower left'
#####################################################

font_size = FontProperties(size=8)

op = OptionParser(usage="%prog [options] combined.yaml")
op.add_option("--xrange", dest="xrange", help="change xrange (negatives with n)", metavar="from:to")
op.add_option("--zyrange", dest="zyrange", help="change yrange for zscores", metavar="from:to")
op.add_option("--pyrange", dest="pyrange", help="change yrange for prec/recall", metavar="from:to")
op.add_option("--legend", dest="legend", help="position legend", metavar="'upper right'")

(opt, args) = op.parse_args()

if len(args) == 0:
    op.print_help()
    exit()

def to_float(st):
    st = st.replace('n', '-')
    return float(st)

def convert_range(string):
    ar = string.split(':')
    return map(to_float, ar)

if opt.xrange:
    xrange = convert_range(opt.xrange)
else:
    xrange = None

if opt.zyrange:
    zyrange = convert_range(opt.zyrange)
else:
    zyrange = None

if opt.pyrange:
    pyrange = convert_range(opt.pyrange)
else:
    pyrange = None

if opt.legend:
    legend_loc = opt.legend
else:
    legend_loc = 'upper right'
    
## MANUALLY OVERIDE LEGEND with exact location
#legend_loc = (0.3,0.25)

# modifies list to put anystring matching regexp at the front 
def tofront(list, regexp):
   for string in list:  
        if regexp.search(string):
            list.remove(string)
            list.insert(0,string)


"""
key_order = [
        #'fsh8',
        #'fsh4',
        #'fsh2',
        #'fsh1',
        #'fsh075',
        #'fsh05',
        #'fsh00',

        #'normal',
        #'shuffle_cat_decoy', 
        #'shuffle_cat',

        #'reverse_cat_decoy',
        #'reverse_cat',

        #'shuffle',
        #'reverse',

        'shuffle_cat_HS',
        'reverse_cat_HS',
        'shuffle_HS',
        'reverse_HS',
        'shuffle_cat',
        'reverse_cat',
        'shuffle',
        'reverse',
]
"""
"""
key_order = [
        'KRP shuffle_cat',
        'NE shuffle_cat',
        'KRP reverse_cat',
        'NE reverse_cat',
        'KRP shuffle',
        'NE shuffle',
        'KRP reverse'
        'NE reverse',
        ]
"""

key_order = ['fsh05_HS', 'fsh075_HS', 'fsh1_HS', 'fsh2_HS', 'fsh4_HS', 'fsh8_HS','fsh05', 'fsh075', 'fsh1', 'fsh2', 'fsh4', 'fsh8']

"""
key_order = [
        "filter_shuffle_cat_HS", 
        "filter_reverse_cat_HS", 
        "filter_shuffle_HS", 
        "filter_reverse_HS",       
        "filter_shuffle_cat",
        "filter_reverse_cat",
        "filter_shuffle", 
        "filter_reverse", 
        "PP_normal",
        "PP_shuffle_cat_decoy",
        "PP_reverse_cat_decoy",
        "PP_shuffle_cat",
        "PP_reverse_cat",
        "perc_shuffle_cat",
        "perc_reverse_cat",
        "perc_shuffle",
        "perc_reverse",
        ]
"""

# returns an array of keys ordered how I want:
def order_keys(keys):
    print keys
    newkeys = keys[:]
    #print newkeys
    #newkeys.sort()
    keyorder = key_order[:]
    for regexp_s in keyorder:
        tofront(newkeys, re.compile(regexp_s + '$'))
    newkeys.reverse()
    return newkeys

def rename_key(key):
    repl = key.replace('_decoy',' (decoy flag)')
    repl = repl.replace('_',' ').replace('reverse','rev').replace('shuffle', 'shf')
    repl = repl.replace('fsh', '+ shf ')
    repl = repl.replace('00', '0')
    repl = repl.replace('05', '0.5')
    repl = repl.replace('075', '0.75')
    repl = repl.replace('1', '1.0')
    return repl


file = args[0]
fh = open(file)
ym = syck.load(fh.read())

labels = []
triplets = []
ztriplets = []

def use_better_labels(hash):
    better_labels = False
    for subhash in hash.values():
        if subhash['zscores'].has_key('prob') and subhash['zscores'].has_key('decoy'):
            better_labels = True
    return better_labels 



use_better_labels_bool = use_better_labels(ym)

color_by_key = {}
dashes_by_key = {}

zlabels = []

for key in order_keys(ym.keys()):
    f = ym[key]
    triplets.append( f['mean']['x'] )
    triplets.append( f['mean']['y'] )
    triplets.append( '' )
    probkeys = []
    ## right now, this excludes decoy in the (rare) case where we have prob and decoy
    if f['zscores'].has_key('prob'):
        probkeys.append('prob')
    if f['zscores'].has_key('qval'):
        probkeys.append('qval')
    if f['zscores'].has_key('decoy'):
        probkeys.append('decoy')

    # in most instances we'll have a single probkey and so the same number of prec/recall
    # lines as we have zscore lines.  In the case of use_better_labels_bool, we have a
    # different # of lines, so we need two sets of labels
    labels.append(key)

    for probkey in probkeys: 
        ztriplets.append( f['zscores'][probkey]['x'] )
        ztriplets.append( f['zscores'][probkey]['y'] )
        ztriplets.append( '' )
        label = key
        if use_better_labels_bool:
            label += (' ' + probkey)    
            zlabels.append(label)
        else:
            zlabels.append(label)


# rect=[left, bottom, width, height]
left, width = 0.1, 0.85
total_height = 0.85
separation = 0.12
bottom_height = 0.40
top_height = total_height - bottom_height
top_start = bottom_height + separation
zscore_rect = [left, top_start, width, top_height]
pr_rect =     [left, 0.1, width, bottom_height]

axes(pr_rect)

###############################################
# PLOT P/R
###############################################
lines = plot(lw=linewidth, *triplets)

axhline(y=0.99, ls=':', color=axhline_color)
axhline(y=0.95, ls=':', color=axhline_color)
gca().set_ylim(pyrange)
gca().set_xlim(xrange)
xlim = gca().get_xlim()

for i in range(len(lines)):
    color = mycolors.pop(0)
    dashes = mydashes.pop(0)
    setp(lines[i], dashes=dashes, color=color)
    color_by_key[labels[i]] = color
    dashes_by_key[labels[i]] = dashes


xlabel("num hits")
ylabel("precision TP/(TP+FP)")


def nohead(string):
    new = string.replace("scx_",'')
    return new.replace("orbi_",'')

renamed_labels = map(nohead, labels)
renamed_labels = map(rename_key, renamed_labels)

legend(renamed_labels, loc=legend_loc, pad=0.1, labelsep=0.004, axespad=0.0)
fp = FontProperties(size=10)

#legend(renamed_labels, loc=legend_loc, prop=fp)


###############################################
# PLOT zscores
###############################################
axes(zscore_rect)
zlines = plot(lw=linewidth, *ztriplets)
axhline(ls=':', color=axhline_color)
for i in range(len(zlines)):
    color = None
    if color_by_key.has_key(zlabels[i].split(' ')[0]):
        color = color_by_key[zlabels[i].split(' ')[0]]
        del color_by_key[zlabels[i].split(' ')[0]]
    else:
        color = mycolors.pop(0)

    dashes = None
    if dashes_by_key.has_key(zlabels[i].split(' ')[0]):
        dashes = dashes_by_key[zlabels[i].split(' ')[0]]
        del dashes_by_key[zlabels[i].split(' ')[0]]
    else:
        dashes = mydashes.pop(0)

    setp(zlines[i], dashes=dashes, color=color)

# ensure that the x axis is exactly the same
gca().set_xlim(xlim)
gca().set_ylim(zyrange)


if use_better_labels_bool == True:
    renamed_zlabels = map(nohead, zlabels)
    renamed_zlabels = map(rename_key, renamed_zlabels)

    legend(renamed_zlabels, loc=zlegend_loc, prop=font_size, pad=0.1, labelsep=0.004, axespad=0.0)
    #legend(renamed_zlabels, loc=zlegend_loc, prop=fp)

setp(gca(), 'xticklabels', [])
ylabel('zscore')

show()

fh.close()



###################################################
# REFERENCE:
###################################################

#############################################
# FILE STRUCTURE:
#############################################

# Expects a yaml file structured like this:

# <filename>:
# ## means for PR:
#   mean:
#      x:
#      y:
# ## vals std for errorbars
#   stdev:
#      x: 
#      y:
# ## PR estimates for comparison:
#   estimates:
#      prob:
#        x:
#        y:
#      qval:
#        x:
#        y:
#      decoy:
#        x:
#        y:
# ## zscores zscore
#   zscores:
#      prob:
#        x:
#        y:
#      qval:
#        x:
#        y:
#      decoy:
#        x:
#        y:

#############################################
# LEGEND PLACEMENT:
#############################################
#'best' : 0,
#      'upper right'  : 1, (default)
#      'upper left'   : 2,
#      'lower left'   : 3,
#      'lower right'  : 4,
#      'right'        : 5,
#      'center left'  : 6,
#      'center right' : 7,
#      'lower center' : 8,
#      'upper center' : 9,
#      'center'       : 10,


#############################################
# COLORS:
#############################################
# b  : blue, g  : green, r  : red, c  : cyan, m  : magenta, y  : yellow, k  : black, w  : white

#############################################
# SYMBOLS:
#############################################
#    -     : solid line
#    --    : dashed line
#    -.    : dash-dot line
#    :     : dotted line
#    .     : points
#    ,     : pixels
#    o     : circle symbols
#    ^     : triangle up symbols
#    v     : triangle down symbols
#    <     : triangle left symbols
#    >     : triangle right symbols
#    s     : square symbols
#    +     : plus symbols
#    x     : cross symbols
#    D     : diamond symbols
#    d     : thin diamond symbols
#    1     : tripod down symbols
#    2     : tripod up symbols
#    3     : tripod left symbols
#    4     : tripod right symbols
#    h     : hexagon symbols
#    H     : rotated hexagon symbols
#    p     : pentagon symbols
#    |     : vertical line symbols
#    _     : horizontal line symbols
    

#############################################
# LINE PROPERTIES:
#############################################
#    alpha: float
#    animated: [True | False]
#    antialiased or aa: [True | False]
#    clip_box: a matplotlib.transform.Bbox instance
#    clip_on: [True | False]
#    color or c: any matplotlib color - see help(colors)
#    dash_capstyle: ['butt' | 'round' | 'projecting']
#    dash_joinstyle: ['miter' | 'round' | 'bevel']
#    dashes: sequence of on/off ink in points
#    data: (array xdata, array ydata)
#    figure: a matplotlib.figure.Figure instance
#    label: any string
#    linestyle or ls: [ '-' | '--' | '-.' | ':' | 'steps' | 'None' | ' ' | '' ]
#    linewidth or lw: float value in points
#    lod: [True | False]
#    marker: [ '+' | ',' | '.' | '1' | '2' | '3' | '4'
#    markeredgecolor or mec: any matplotlib color - see help(colors)
#    markeredgewidth or mew: float value in points
#    markerfacecolor or mfc: any matplotlib color - see help(colors)
#    markersize or ms: float
#    solid_capstyle: ['butt' | 'round' |  'projecting']
#    solid_joinstyle: ['miter' | 'round' | 'bevel']
#    transform: a matplotlib.transform transformation instance
#    visible: [True | False]
#    xdata: array
#    ydata: array
#    zorder: any number

