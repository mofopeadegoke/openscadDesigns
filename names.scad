box_width_new   = 208;
box_depth       = 128;
bottom_height   = 68;   // Aligned with 4mm grid
top_height      = 100;
thickness       = 4;

// --- TEXT & LOGO SETTINGS ---
// Change these names to whatever you like!
project_names = ["Project Team", "Prof. Cem Kalyoncu", "Daniel Adegoke", "Immaculata Umoh", "Mujhaid Akanayo"];
text_size = 6;       // Font size for the names
logo_size = 25; 

translate([total_height - bottom_height + 10, box_depth/2]) {
            rotate([0, 0, 90])
            translate([-20, 69]) 
            scale([0.4, 0.4])
            import("eul.svg");
            for (i = [0 : len(project_names) - 1]) {
                rotate([0, 0, 90])
                translate([0, -i * (text_size * 1.8)+65]) {
                    text(project_names[i], size=text_size, halign="center", valign="center", font="Palatino Linotype");
                }
            }
        }