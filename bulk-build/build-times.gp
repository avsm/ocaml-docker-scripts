set term png
set output "build-times.png"
set key off
set border 3
set yzeroaxis
set style fill solid 1.0 noborder
bin_width = 5;
bin_number(x) = floor(x/bin_width)
rounded(x) = bin_width * ( bin_number(x) + 0.5 )
plot 'build-times.txt' using (rounded($1)):(1) smooth frequency with boxes
