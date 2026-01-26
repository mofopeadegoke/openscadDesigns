include <common.scad>
$fn = 32;
 rborder([75, 45, 20], 2, r=0);
difference () {
    rcube([75, 45, 2], r=1);
    translate([8.5, 8.5, -2])
    cylinder(h=20, r = 1.5);
    translate([66.5, 8.5, -2])
    cylinder(h=20, r = 1.5);
    translate([8.5, 36.5, -2])
    cylinder(h=20, r = 1.5);
    translate([66.5, 36.5, -2])
    cylinder(h=20, r = 1.5);
    translate([9.5, 10.5, -2])
    cube([35, 23.5, 10]);
    translate([56.25, 20.25, -2])
    cylinder(h=20, r = 9.25);
 } 
 