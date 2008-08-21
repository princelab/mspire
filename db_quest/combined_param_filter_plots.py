#!/usr/bin/python

import syck
from pylab import *
import sys
import re

fh = open(sys.argv[1])
yml = syck.load(fh.read())


##################################################
axhline_color = '#999999'
linewidth = 1.0
#colors = ['k','r', 'b', 'g', 'm']
#           black      red        blue       green      dark yel  magenta    olive green off blue  brown
#mycolors = ['#000000', '#FF0000', '#0000FF', '#00BB00', '#CCCC00', '#FF00FF', '#2D872D', '#4B4B83', '#A98638']
#mycolors = ['#0000FF', '#2222FF', '#0000AA', '#5500FF', '#FF0000', '#FF2222','#AA0000','#FF0055']
mycolors = ['#1111CC', '#444488', '#11CC11', '#339933', '#BBBB11', '#999922','#CC1111','#993333']
mydashes = [[5,4], [6,2,1,2], [1,2], [3,3,1,3], [4,2,1,2,1,2], [7,2,5,2,3,1,1,1], [7,2,1,2], [8,2,1,1,5,2,1,2]]
#mydashes = [[1,0], [1,0], [1,0], [1,0], [4,2],[4,2],[4,2],[4,2],[4,2]]
zlegend_loc = 'lower left'
markers = ['o', '^', 'v', '<', '>', 's', '+', 'x', 'D', 'd', '1', '2', '3', '4', 'h', 'H', 'p']
mydashes = mydashes + mydashes
markers = markers + markers
mycolors = mycolors + mycolors
##################################################

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

# modifies list to put anystring matching regexp at the front 
def tofront(list, regexp):
   for string in list:  
        if regexp.search(string):
            list.remove(string)
            list.insert(0,string)



# returns an array of keys ordered how I want:
def order_keys(keys):
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




num_rows = 5
num_cols = 3
plot_num = 1


row_labels = ['xcorr1', 'xcorr2', 'xcorr3', 'deltacn', 'ppm']
col_labels = ['zscore', 'precision', 'num hits']

frozen_xaxis_range = [0,5]
freeze_xaxis = [1,2,3,4,5,6,7,8,9]
print_ylabel = [7, 8, 9, 10000]
print_xlabel = [2,5,8,11,14, 10000]


for m in row_labels:
    for n in col_labels:
        mcolors = mycolors[:]
        subplot(num_rows, num_cols, plot_num)

        triplets = []
        filenames = order_keys(yml.keys())
        for filename in filenames:
            hash = yml[filename]
            
            prms = hash['params']
            decoy_num_hits = hash['estimates']['decoy']['x']
            decoy_precision = hash['estimates']['decoy']['y']
            decoy_zscore = hash['zscores']['decoy']['y']
            triplets.append( prms[m] )
            if n == 'zscore':
                triplets.append( decoy_zscore )
            elif n == 'precision':
                triplets.append( decoy_precision )
            elif n == 'num hits':
                triplets.append( decoy_num_hits )
            triplets.append('')

        sorted_triplets = []
        for i in (range(len(triplets)/3)):
            tmp_x = triplets.pop(0)
            tmp_y = triplets.pop(0)
            triplets.pop(0)

            both = []
            for i in range(len(tmp_x)):
                both.append([tmp_x[i], tmp_y[i]])

            ordered = sorted(both, lambda a,b: cmp(a[0], b[0]))
            new_x = []
            new_y = []
            for i in range(len(ordered)):
                new_x.append(ordered[i][0])
                new_y.append(ordered[i][1])
            sorted_triplets.append(new_x)
            sorted_triplets.append(new_y)
            sorted_triplets.append('')

            #scatter(tmp_x, tmp_y, color=mcolors.pop(0))

        #lines = plot(*triplets)
        lines = plot(*sorted_triplets)
        if plot_num in freeze_xaxis:
            gca().set_xlim(frozen_xaxis_range) 

        for i in range(len(lines)):
            setp(lines[i], color=mycolors[i], dashes=mydashes[i])
            #setp(lines[i], ls='None', marker=markers[i], mfc=mycolors[i], mec=mycolors[i])
        new_filenames = map(rename_key, filenames)

        if plot_num == 3:
            legend(new_filenames)


        

        if plot_num == print_ylabel[0]:
            print_ylabel.pop(0)
            ylabel(n)
        if plot_num == print_xlabel[0]:
            print_xlabel.pop(0)
            xlabel(m)
        plot_num += 1

show()



# what we're after:

# xcorr1  vs.  decoy zscore
# xcorr2
# xcorr3
# deltacn
# ppm

# xcorr1  vs.  decoy precision
# xcorr2
# xcorr3
# deltacn
# ppm

# xcorr1  vs.  decoy num hits
# xcorr2
# xcorr3
# deltacn
# ppm

# 15 plots, 5down, 3 across


