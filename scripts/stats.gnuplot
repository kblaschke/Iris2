w=1.
h=1.
c=7.
dx=0.

set terminal png size 800,800
#set output "plot.png"
set output '| display png:-'
set size w,h
set origin dx,0

set xlabel "ticks"
set grid x y
set lmargin 10.

set multiplot layout 7,1 scale 1,1

plot "stats.dat" using 2 with lines title "fps"
plot "stats.dat" using 3 with lines title "batches"
plot "stats.dat" using 4 with lines title "triangles"
plot "stats.dat" using 5 with lines title "ogre mem"
plot "stats.dat" using 6 with lines title "lua mem"
plot "stats.dat" using 7 with lines title "jobs"
plot "stats.dat" using 8 with lines title "loading"

unset multiplot
