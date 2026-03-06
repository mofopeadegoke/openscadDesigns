// --- 3D PRINT FILE (STL) FOR HEXAGONAL FILTER ---

// 1. IMPORT YOUR COMMON LIBRARY
// This allows us to use the hextiling() module from your file
use <common.scad>

// --- 2. DIMENSION SETTINGS ---
// The exact internal dimensions of your laser-cut box
box_inner_width = 208;
box_inner_depth = 128;

// Clearance: 2mm total = 1mm of gap on all 4 sides for easy drop-in
clearance = 2; 

// Auto-calculate the final print size
filter_w = box_inner_width - clearance; 
filter_d = box_inner_depth - clearance; 

// --- 3. 3D PRINT SETTINGS ---
filter_height = 10;      // Total thickness of the print (Z-axis)
hex_radius    = 4;      // Radius of the individual honeycomb holes
hex_wall      = 0.4;    // Thickness of the walls between hexagons
border_width  = 4;      // Solid plastic frame around the outside for strength

// --- 4. GENERATION ---
difference() {
    // 1. Generate the solid outer frame plate
    cube([filter_w, filter_d, filter_height]);
    
    // 2. Cut out the honeycomb grid using common.scad
    // We translate it slightly inwards to leave the solid border
    translate([border_width, border_width, -0.1])
        hextiling(
            d = [filter_w - (border_width * 2), filter_d - (border_width * 2), filter_height + 0.2], 
            radius = hex_radius, 
            spacing = hex_wall, 
            cut = true
        );
        
    // 3. Add finger-lift holes at the top and bottom borders for easy removal
    translate([filter_w / 2, border_width / 2, -0.1]) 
        cylinder(d = border_width - 2, h = filter_height + 0.2, $fn = 30);
        
    translate([filter_w / 2, filter_d - (border_width / 2), -0.1]) 
        cylinder(d = border_width - 2, h = filter_height + 0.2, $fn = 30);
}