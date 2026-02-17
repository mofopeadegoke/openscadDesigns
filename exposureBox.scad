function cat(L1, L2) = [for(L=[L1, L2], a=L) a];
function reverse(list) = [for (i = [len(list)-1:-1:0]) list[i]];

function If(condition, t, f) = condition ? t : f;

function ReverseIf(condition, data) = condition ? reverse(data) : data;

function finger_joint_regular(start, length, dir, offset, size, blank) = 
    let(sz = size, 
        l  = length, 
        st = start
    )
    (dir == 1 ?
        cat([for(i=[1:floor(l/sz)]) 
            each If((i%2 == (blank ? 0:1)), [
                [st[0]+i*sz, st[1]],
                [st[0]+i*sz, st[1]+offset]
            ], [
                [st[0]+i*sz, st[1]+offset],
                [st[0]+i*sz, st[1]]
             ])
          ],
          If(l/size == floor(l/size), [],
            If(floor(length/sz)%2 == (blank ? 0:1), [
                [st[0]+l, st[1]+offset]
             ], [
                [st[0]+l, st[1]]
             ]
            )
         )
        ) : 
        cat([for(i=[1:floor(l/sz)]) 
            each If((i%2 == (blank ? 0:1)), [
                [st[0]       , st[1]+i*sz],
                [st[0]+offset, st[1]+i*sz]
            ], [
                [st[0]+offset, st[1]+i*sz],
                [st[0]       , st[1]+i*sz]
             ])
          ],
          If(l/size == floor(l/size), [],
            If(floor(l/sz)%2 == (blank ? 0:1), [
                [st[0]+offset, st[1]+l]
             ], [
                [st[0]       , st[1]+l]
             ]
            )
         )
        ));

function finger_joint_reversed(start, length, dir, offset, size, blank) = 
    let(sz = -size, 
        l  = -length, 
        st = (dir == 1 ? 
            [start[0] + length, start[1]] : 
            [start[0], start[1] + length]
        )
    )
    reverse(dir == 1 ?
        cat(If(l/size == floor(l/size), [],
            If(blank, [
                [st[0], st[1]+offset]
             ], [
                [st[0], st[1]]
             ]
            )
         ),
          [for(i=[1:floor(l/sz)]) 
            each If((i%2 == (blank ? 0:1)), [
                [st[0]+i*sz, st[1]],
                [st[0]+i*sz, st[1]+offset]
            ], [
                [st[0]+i*sz, st[1]+offset],
                [st[0]+i*sz, st[1]]
             ])
          ]
        ) : 
        cat(If(l/size == floor(l/size), [],
            If(blank, [
                [st[0]+offset, st[1]]
             ], [
                [st[0], st[1]]
             ]
            )
         ),
          [for(i=[1:floor(l/sz)]) 
            each If((i%2 == (blank ? 0:1)), [
                [st[0]       , st[1]+i*sz],
                [st[0]+offset, st[1]+i*sz]
            ], [
                [st[0]+offset, st[1]+i*sz],
                [st[0]       , st[1]+i*sz]
             ])
          ]
        ));

function finger_joint(start, length, dir, offset, size, reversed = false, blank = false) = 
    reversed ? 
        finger_joint_reversed(start, length, dir, offset, size, blank) : 
        finger_joint_regular(start, length, dir, offset, size, blank)
        
    ;

//side setup [[-1: straight, 0: regular, 1: reversed][0: regular, 1: start with blank]]
module fingered_rect(size, thickness, finger_width = "", side_setup = [[0, 0], [0, 1], [0, 0], [0, 1]]) {
  finger = finger_width == "" ? thickness : finger_width;
    
  ft = is_list(finger) ? finger[0] : finger;
  fb = is_list(finger) ? finger[1] : finger;
  fl = is_list(finger) ? finger[2] : finger;
  fr = is_list(finger) ? finger[3] : finger;
    
  t_odd = ceil(size[0] / ft) % 2;
  b_odd = ceil(size[0] / fb) % 2;
  l_odd = ceil(size[1] / fl) % 2;
  r_odd = ceil(size[1] / fr) % 2;
    
  b_st = side_setup[1][0]==-1 ? 0 : (side_setup[1][0]==1 ? side_setup[1][1] == b_odd : side_setup[1][1]);
  b_ed = side_setup[1][0]==-1 ? 0 : (side_setup[1][0]==0 ? side_setup[1][1] == b_odd : side_setup[1][1]);
  r_st = side_setup[3][0]==-1 ? 0 : (side_setup[3][0]==1 ? side_setup[3][1] == r_odd : side_setup[3][1]);
  r_ed = side_setup[3][0]==-1 ? 0 : (side_setup[3][0]==0 ? side_setup[3][1] == r_odd : side_setup[3][1]);
  t_st  = side_setup[0][0]==-1 ? 0 : (side_setup[0][0]==0 ? side_setup[0][1] == t_odd : side_setup[0][1]);
  t_ed = side_setup[0][0]==-1 ? 0 :  (side_setup[0][0]==1 ? side_setup[0][1] == t_odd : side_setup[0][1]);
  l_st = side_setup[2][0]==-1 ? 0 : (side_setup[2][0]==0 ? side_setup[2][1] == l_odd : side_setup[2][1]);
  l_ed = side_setup[2][0]==-1 ? 0 : (side_setup[2][0]==1 ? side_setup[2][1] == l_odd : side_setup[2][1]);
    
  polygon([
    [         0, 0],
    each If(b_st, [[0, -thickness]], []),
    each If(side_setup[1][0] != -1,
      finger_joint(
        [0, -thickness], size[0], 1, 
        thickness, fb, side_setup[1][0], !side_setup[1][1]
      ), []
    ),
    each(If(b_ed, [[   size[0], -thickness]], [])),
    [   size[0], 0],
    
    each If(r_st, [[size[0]+thickness, 0]], []),
    each If(side_setup[3][0] != -1,
      finger_joint(
        [size[0], 0], size[1], 0, 
        thickness, fr, side_setup[3][0], side_setup[3][1]
      ), []
    ),
    each If(r_ed, [[size[0]+thickness, size[1]]], []),
    
    size,
    each If(t_st, [[size[0], size[1] + thickness]], []),
    each If(side_setup[0][0] != -1,
      reverse(finger_joint(
        [0, size[1]], size[0], 1, 
        thickness, ft, side_setup[0][0], side_setup[0][1]
      )), []
    ),
    each If(t_ed, [[0, size[1] + thickness]], []),
    
    [0, size[1]],
    each If(l_st, [[-thickness, size[1]]], []),
    each If(side_setup[2][0] != -1,
      reverse(finger_joint(
        [-thickness, 0], size[1], 0, 
        thickness, fl, side_setup[2][0], !side_setup[2][1]
      )), []
    ),
    each If(l_ed, [[-thickness, 0]], []),
  ]);
}

module fingered_box(
    size, thickness, 
    finger_width = "", spacing = -1, 
    x_parts = 2, y_parts = 2, z_parts = 2
) {
    spc = spacing == -1 ? thickness + 1 : spacing;
    if(x_parts > 0) {
        translate([-size[2]-thickness-spc, 0])
        fingered_rect(
            [size[2], size[1]], thickness, finger_width, [
                [If(y_parts<2, -1, 0), 0], 
                [If(y_parts<1, -1, 0), 1], 
                [If(z_parts<2, -1, 0), 0], 
                [If(z_parts<1, -1, 0), 1]
            ]
        );
    }
    if(x_parts > 1) {
        translate([(z_parts > 0) ? size[0]+thickness+spc : 0, 0])
        fingered_rect(
            [size[2], size[1]], thickness, finger_width, [
                [If(y_parts<2, -1, 0), 0], 
                [If(y_parts<1, -1, 0), 1], 
                [If(z_parts<1, -1, 0), 0], 
                [If(z_parts<2, -1, 0), 1]
            ]
        );
    }

    if(y_parts > 0) {
        translate([0, -size[2]-thickness-spc])
        fingered_rect(
            [size[0], size[2]], thickness, finger_width, [
                [If(z_parts<1, -1, 0), 0], 
                [If(z_parts<2, -1, 0), 1], 
                [If(x_parts<1, -1, 0), 0], 
                [If(x_parts<2, -1, 1), 0]
            ]
        );
    }
    if(y_parts > 1) {
        translate([0,(z_parts > 0 || x_parts>1) ? size[1]+thickness+spc : 0])
        fingered_rect(
            [size[0], size[2]], thickness, finger_width, [
                [If(z_parts<2, -1, 0), 0], 
                [If(z_parts<1, -1, 0), 1], 
                [If(x_parts<1, -1, 1), 1],
                [If(x_parts<2, -1, 0), 1]
            ]
        );
    }

    if(z_parts > 0)
        fingered_rect(
            [size[0], size[1]], thickness, finger_width, [
                [If(y_parts<2, -1, 0), 0], 
                [If(y_parts<1, -1, 0), 1], 
                [If(x_parts<1, -1, 0), 0], 
                [If(x_parts<2, -1, 0), 1]
            ]
        );
    
    if(z_parts > 1)
        translate([size[0]+thickness+spc + ((x_parts > 1) ? size[2]+thickness+spc : 0), 0])
        fingered_rect(
            [size[0], size[1]], thickness, finger_width, [
                [If(y_parts<2, -1, 1), 1], 
                [If(y_parts<1, -1, 1), 0], 
                [If(x_parts<2, -1, 0), 0], 
                [If(x_parts<1, -1, 0), 1]
            ]
        );
    
}

// --- NEW USER CONFIGURATION ---
box_width_new   = 208;  
box_depth       = 128;  
bottom_height   = 69;   
top_height      = 100;  
thickness       = 4;    

total_height = bottom_height + thickness + top_height;

linear_extrude(thickness)

spc = thickness + 1;

linear_extrude(thickness)
difference() {
    union() {
        // 1. Main Box & Floor
        fingered_box(
            [box_width_new, box_depth, total_height], 
            thickness = thickness, 
            x_parts = 2, z_parts = 1, y_parts = 2
        );
        
        // 2. Internal Tabs (Moved to sides)
        translate([-4, 0]) polygon([each finger_joint([0, 0], 32, 0, thickness, 4, true, false)]);
        translate([-4, box_depth-28]) polygon([each finger_joint([0, 0], 32, 0, thickness, 4, true, false)]);
        
        // 3. Lid & Accessories (Moved far right)
        translate([box_width_new * 3 + 200, 0, 0]) {
            square([box_width_new + 4, box_depth]); // Lid
            
            translate([0, 60]) square([4, 28]); // Handle part
            translate([100, -10]) square([40, 4]); // Stop part
            translate([100, box_depth + 10]) square([40, 4]); // Stop part
        }

        // 4. Side Locking Tabs
        translate([box_width_new * 3 + 196, 4]) polygon([each finger_joint([0, 0], 24, 0, thickness, 4, true, true)]);
        translate([box_width_new * 3 + 196, box_depth - 24]) polygon([each finger_joint([0, 0], 24, 0, thickness, 4, true, true)]);
        
        // --- NEW: THE MISSING DIVIDER PLATE ---
        // This generates the actual board to slide into the slots
        translate([box_width_new * 2 + 100, 0])
            fingered_rect([box_width_new, box_depth], thickness, 4, [[0,0],[0,0],[0,0],[0,0]]);
    }

    // --- CORRECTED CUTS (MOVED TO WALLS) ---
    
    // 1. Cut on the LEFT Wall (X is negative)
    // Wall starts at: -total_height - thickness - spc
    // We want the slot at 'bottom_height' up from the base.
    translate([-total_height - thickness - spc + bottom_height, 0, 0])
        polygon([each finger_joint([0, 0], box_depth, 0, thickness, 4, true, false)]);

    // 2. Cut on the RIGHT Wall (X is positive)
    // Wall starts at: box_width_new + thickness + spc
    translate([box_width_new + thickness + spc + bottom_height, 0, 0])
         polygon([each finger_joint([0, 0], box_depth, 0, thickness, 4, true, false)]);

    // 3. Cut on the FRONT Wall (Y is negative)
    translate([0, -total_height - thickness - spc + bottom_height, 0])
        polygon([each finger_joint([0, 0], box_width_new, 1, thickness, 4, false, false)]);

    // 4. Cut on the BACK Wall (Y is positive)
    translate([0, box_depth + thickness + spc + bottom_height, 0])
        polygon([each finger_joint([0, 0], box_width_new, 1, thickness, 4, false, false)]);
}
