include <common.scad>
$fn = 32;
 rborder([76.5, 45, 20], 2, r=0);
difference () {
    rcube([76.5, 45, 2], r=1);
    translate([8.5, 7, -2])
    cylinder(h=20, r = 1.5);
    translate([68, 7, -2])
    #cylinder(h=20, r = 1.5);
    translate([8.5, 36.5, -2])
    #cylinder(h=20, r = 1.5);
    translate([68, 36.5, -2])
    cylinder(h=20, r = 1.5);
    translate([11, 10.5, -2])
    cube([35, 19.5, 10]);
    translate([59, 22.2, -2])
    #cylinder(h=20, r = 5);
 } 
 