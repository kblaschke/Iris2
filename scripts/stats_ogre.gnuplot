set terminal png size 800,800
#set output "plot.png"
set output '| display png:-'
set size w,h
set origin 0,0

set xlabel "ticks"
set grid x y
set lmargin 10.

set multiplot layout 8,1 scale 1,1

plot "stats.dat" using 9 with lines title "ogre mem compositor"
plot "stats.dat" using 10 with lines title "ogre mem font"
plot "stats.dat" using 11 with lines title "ogre mem gpuprogram"
plot "stats.dat" using 12 with lines title "ogre mem highlevelgpuprogram"
plot "stats.dat" using 13 with lines title "ogre mem material"
plot "stats.dat" using 14 with lines title "ogre mem mesh"
plot "stats.dat" using 15 with lines title "ogre mem skeleton"
plot "stats.dat" using 16 with lines title "ogre mem texture"

unset multiplot
