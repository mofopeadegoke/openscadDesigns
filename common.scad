
csilver     = [0.7, 0.7, 0.7];
cpcb        = [0,0.6,0.2];
cdarkgrey   = [0.1, 0.1, 0.1];

/** @param dir direction of the straight plane x: 0, y: 1, z: 2
 */
module rcube(d, r = 1, sides = 64, tight = false, center = false, extend = 0, on = [true, true, true, true], dir=2) {
    
    p = tight ? extend : extend / sqrt(2);
    
    dim = [
        [d[2], d[1], d[0]],
        [d[0], d[2], d[1]],
        [d[0], d[1], d[2]]
    ][dir];
    
    onp = is_list(on) ? 
        (dir!=0 ? [on[3], on[0], on[1], on[2]] : on) : 
        on == true  ? [true, true, true, true] : 
        on == false ? [false, false, false, false] : 
        on;
    
    off = 
        (center ? [-d[0]/2, -d[1]/2, 0] : [0, 0, 0]) -
        rotate_list([0, p, p], dir)
    ;
    
    translate(
        off + 
        [dir==0 ? d[0] : 0, dir==1 ? d[1] : 0, 0]
    )
    rotate([dir==1 ? 90 : 0, dir==0 ? -90 : 0, 0])
    linear_extrude(height=dim[2])
    rrect([dim[0] + p * 2, dim[1] + p * 2], r + extend, sides, tight, false, onp);
}

//border radius (r) is for inner part. Dimensions are for
//the space inside.
module rborder(d, border, r=1, sides=64, tight = false, center = false, extend = 0, on = [true, true, true, true], dir=2) {
    difference() {
        rcube(d, r, sides, tight, center, border + extend, on, dir);
        
        translate(rotate_list([-0.1, 0, 0],dir))
        rcube(d + rotate_list([0.3, 0, 0],dir), r, sides, tight, center, extend, on, dir);
    }
}

module rrect(d, r = 1, sides, tight = false, center = false, on = [true, true, true, true]) {
    polygon(rrect_coords(d, r, sides, tight, center, on));
}

function rrect_coords(d, r=1, $fn = 64, tight = false, center = false, on = [true, true, true, true]) = 
let(
    diff = tight ? r - r / sqrt(2) : 0,
    dim  = [d[0]-diff*2, d[1]-diff*2],
    rd   = r / sqrt(2), 
    ad   = 90 / $fn * 4,
    pos  = [
        [rd, rd], 
        [dim[0]-rd, rd], 
        [dim[0]-rd, dim[1]-rd], 
        [rd, dim[1]-rd]
    ],
    off = center ?
          [-d[0] / 2, -d[1] / 2] : 
          [0, 0]  
)
tr([
    for(i = [0:3])
        if(get_idx(on, i, true))
            for(j=[0:$fn/4])
                [
                    off[0] + pos[i][0] + cos(ad*j + i*90+180)*r, 
                    off[1] + pos[i][1] + sin(ad*j + i*90+180)*r
                ]
        else [off[0] + pos[i][0] + r * (i==0||i==3?-1:1), off[1] + pos[i][1] + r * (i==0||i==1?-1:1)]
],diff, diff);

function rect_coords(d) = [
        [0, 0, each len(d)==3 ? [d[2]] : []],
        [d[0], 0, each len(d)==3 ? [d[2]] : []],
        [d[0], d[1], each len(d)==3 ? [d[2]] : []],
        [0, d[1], each len(d)==3 ? [d[2]] : []]
];


module barrel_connector() {
    rotate([90,0,0]) 
    cylinder(r=4.1, h=10, center=true, $fn=32);
    
    translate([-5, -5, 0])
    cube([10, 10, 6.8]);    
}

module create_pin(h, clearance = 0.2) {
    translate([-7.5-clearance, -7.5-clearance])
    rcube([5+clearance*2, 5+clearance*2, h]);
    
    translate([2.5-clearance, -7.5-clearance])
    rcube([5+clearance*2, 5+clearance*2, h]);

    translate([-7.5-clearance, 2.5-clearance])
    rcube([5+clearance*2, 5+clearance*2, h]);
    
    translate([2.5-clearance, 2.5-clearance])
    rcube([5+clearance*2, 5+clearance*2, h]);
}

//creates a tree stump like shape to increase part to cube
//strength. Widens in x axis. stump([10, 25, 5], 15); widest
//point would be 15mm. Center parameter centers in x axis only.
//otherwise, non-widened width is used to zero in x axis.
module stump(d, maxw, center) {
   r = (maxw-d[0])/2;
   translate([center ? -d[0]/2 : 0, 0]) {
   cube(d);
   
   translate([-r,0]) difference() {
      cube([r,d[1],r]);
      translate([0,-0.1,r])
      rotate([-90,0,0])
      cylinder(r=r, h=d[1]+0.2,$fs=0.5);
   }
   translate([d[0],0]) difference() {
      cube([r,d[1],r]);
      translate([r,-0.1,r])
      rotate([-90,0,0])
      cylinder(r=r, h=d[1]+0.2,$fs=0.5);
   }}
}

module wedge(d, reverse = false, rot = 0) {
    rotdims  = [[0,1,2], [1, 0, 2], [0, 1, 2], [1, 0, 2]];
    rotmoves = [[0,0], [d[0], 0], [d[0], d[1]], [0, d[1]]];
    
    x = d[rotdims[rot][0]];
    y = d[rotdims[rot][1]];
    z = d[rotdims[rot][2]];
    
    
    translate([rotmoves[rot][0], rotmoves[rot][1], reverse ? z : 0])
    mirror([0,0,reverse ? 1 : 0])
    rotate(rot * 90)
    translate([0,y, z])
    rotate([0,90,-90])
    linear_extrude(height = y)
    polygon([
            [0, 0],
            [z, 0],
            [z, x]
        ], 2
    );
}

// when a rrect extends by x, returns offset needed in coordinates.
// use in coordination with rextend_r
function rextend_offset(x) = -x / sqrt(2);

// when a rrect extends by x, returns the size difference needed.
// use in coordination with rextend_r
function rextend_size(x) = 2 * x / sqrt(2);

// when a rrect extends by x, returns the change needed in radius.
// use in coordination with rextend_offset
function rextend_r(x) = x;

// difference between tight and non-tight rrect
function rstraight_off(r) = (r - r / sqrt(2));

function tr(d, x, y) = [for(i=d) [i[0] + x, i[1] + y]];

function reverse(d) = [for(i=[len(d)-1:-1:0]) d[i]];
    
//all polygons should have same number of points, at least 2 polygons
//are required. 
module bridge(polies, h) {
    pcount = len(polies[0]);
    
    pnts = [
        for(i=[0:len(polies)-1])
            for(p=[0:pcount-1])
                [polies[i][p][0], polies[i][p][1], 
                    len(h) ? h[i] : i*h
                ]
    ];
    
    faces = [
        for(i=[1:len(polies)-1])
            for(p=[0:pcount-1])
                [
                    pcount* i    +  p,
                    pcount* i    + (p+1)%pcount,
                    pcount*(i-1) + (p+1)%pcount,
                    pcount*(i-1) +  p,
                ]
    ];
    
    polyhedron(pnts, concat(
        [[for(p=[0:pcount-1]) p]],
        faces        ,
        [[for(p=[pcount-1:-1:0]) p+pcount*(len(polies)-1)]]
    ),5);
}

module tear(r1, r2, r3, h) {
    linear_extrude(height=h)
    polygon([
        for(i=[0:5:355])
            [cos(i) * r1 + sin(i) * cos(i) * r2, sin(i) * r3]
    ]);
}

module hextiling(d, radius, spacing, cut=true) {
    ydist = sqrt(3) * radius / 2 + spacing*sin(30);
    maxy  = d[1] / ydist+(cut?1:0);
    xdist = radius*3+spacing*cos(30)*2;
    maxx  = d[0] / xdist;
    
    difference() {
    union() {
        for(y = [0:maxy])
            for(x = [0:maxx+(y%2?0:0.5)])
                translate([
                    x * xdist + (y%2 ? radius*1.5+spacing*cos(30) : 0),
                    y * ydist
                ])
                cylinder(r=radius, h=d[2], $fn=6);
    }
    if(cut) {
        translate([-xdist*3, -ydist*3, -0.1])
        cube([d[0]+xdist*6, ydist*3, d[2]+1]);
        translate([-xdist*3, -ydist*3, -0.1])
        cube([xdist*3, d[1]+ydist*6, d[2]+1]);
        translate([-xdist*3, d[1], -0.1])
        cube([d[0]+xdist*6, ydist*3, d[2]+1]);
        translate([d[0], -ydist*3, -0.1])
        cube([xdist*3, d[1]+ydist*6, d[2]+1]);
    }
    }
}

function pmod(v, mod) = v%mod < 0 ? v%mod + mod : v%mod;

function sum(in, p, to) = p == to+1 ? [for(i=in[0]) 0] : sum(in, p+1, to) + in[pmod(p, len(in))];

function sumscalar(in, p, to) = p == to+1 ? 0 : sumscalar(in, p+1, to) + in[pmod(p, len(in))];

function average(in, from, to) = sum(in, from, to) / (to - from + 1);

function subdivide(in, times) = 
    let(inlen = len(in))
    [for(i=[0:inlen-1]) for(j=[0:times-1]) 
        (in[pmod(i+1, inlen)] - in[i]) * j/times + in[i]
    ]
;


function smooth(in, n) = 
    let(inlen = len(in))
    [for(i=[0:inlen-1])
        average(in, i-n, i+n)
    ]
;    

function star(r_out, r_in, sides, shape = 1, angle_off = 0) = 
    let(a = 360 / (sides*2))
    [for(i = [0:(sides*2-1)]) 
        let(rx = i%2 ? r_out : r_in, ry = i%2 ? r_out - r_in + (r_in * shape) : r_in * shape)
        [cos(a*i+angle_off) * rx, sin(a*i+angle_off) * ry]];
    
function ngon(r, sides) = star(r, r, sides / 2);

function star_inner(sides, mod, custom) = 
    mod   == 0  ? cos(180/sides) :
    mod   == 1  ? custom * cos(180/sides) :
    sides == 5  ? 0.5 * sqrt(3 - sqrt(5)) :
    sides == 6  ? sqrt(3) / 3 :
    sides == 8  ? (
             mod == 2 ? sqrt(2 - sqrt(2)) 
                      : sin(22.5*3) - sin(22.5) ):
    sides == 10 ? (
             mod == 2 ? sqrt( (5+sqrt(5)) / 10 )
                      : sqrt(5 - 2*sqrt(5)) ):
    sides == 12 ? (
             mod == 2 ? sqrt(2) * (3-sqrt(3)) / 2
                      : sqrt(6) / 3 ):
    custom
;

//clearance is between two components that will be
//connected. Use 0 if you are using a flexible flament
module connector(h = 10, clearance = 0.25) {
    c = clearance / 2;
    
    linear_extrude(height=h)
    polygon(smooth(subdivide(
      [
        [-5-c, -4],
        [-5-c, -5],
        [-4-c, -5],
        [-2-c, -2],
        [ 2+c, -2],
        [ 4+c, -5],
        [ 5+c, -5],
        [ 5+c, -4],
        [ 5+c,  4],
        [ 5+c,  5],
        [ 4+c,  5],
        [ 2+c,  2],
        [-2-c,  2],
        [-4-c,  5],
        [-5-c,  5],
        [-5-c,  4]
      ],
      12), 3)
    );
    
}


//clearance is between two components and for 
//the connector
module connector_socket(h = 10, rotation = 0, clearance = 0.25) {
    c  = clearance / 2;
    cl = clearance;
    
    difference() {
        translate([0,0,-c])
        rotate([0,0,rotation*90])
        linear_extrude(height=h+c*2, convexity=6)
        polygon(smooth(subdivide(
          [
            [-5-cl, -4-c],
            [-5-cl, -5-c],
            [-4-c , -5-c],
            [-2-c , -2-c],
            [ 1+c , -2-c], //overflow is to ensure
            [ 1+c ,  2+c], //smoothing will not cause
            [-2-c ,  2+c], //any issues
            [-4-c ,  5+c],
            [-5-cl,  5+c],
            [-5-cl,  4+c]
          ],
          12), 3),
        convexity=8);
        
        translate([c,-5-c,-c*2])
        cube([5, 10,h+c*4]); 
    }
    
}
//clearance is between two components that will be
//connected. Use 0 if you are using a flexible flament
module connector_thin(h = 10, clearance = 0.25) {
    c = clearance / 2;
    
    linear_extrude(height=h)
    polygon(smooth(subdivide(
      [
        [-3-c, -4],
        [-3-c, -5],
        [-2-c, -5],
        [-1-c, -2],
        [ 1+c, -2],
        [ 2+c, -5],
        [ 3+c, -5],
        [ 3+c, -4],
        [ 3+c,  4],
        [ 3+c,  5],
        [ 2+c,  5],
        [ 1+c,  2],
        [-1-c,  2],
        [-2-c,  5],
        [-3-c,  5],
        [-3-c,  4]
      ],
      12), 3)
    );
    
}


//clearance is between two components and for 
//the connector
module connector_socket_thin(h = 10, rotation = 0, clearance = 0.25) {
    c  = clearance / 2;
    cl = clearance;
    
    difference() {
        translate([0,0,-c])
        rotate([0,0,rotation*90])
        linear_extrude(height=h+c*2, convexity=6)
        polygon(smooth(subdivide(
          [
            [-3-cl, -4-c],
            [-3-cl, -5-c],
            [-2-c , -5-c],
            [-1-c , -2-c],
            [ 0.5+c , -2-c], //overflow is to ensure
            [ 0.5+c ,  2+c], //smoothing will not cause
            [-1-c ,  2+c], //any issues
            [-2-c ,  5+c],
            [-3-cl,  5+c],
            [-3-cl,  4+c]
          ],
          12), 3),
        convexity=8);
        
        rotate([0,0,rotation*90])
        translate([c,-5-c,-c*2])
        cube([5, 10,h+c*4]); 
    }
    
}

//radius, extra border, height under board, clearance, hole height
module screw_stand(r, b, hb, hh = 2, clr = 0.25, $fn = 12) {
    cylinder(r = r + b, h = hb, $fn = $fn);
    cylinder(r = r - clr, h = hh + hb, $fn = $fn);
}

module pin_opening(x = 1, y = 1, depth = 10, size = 2.54, clr = 0.7, r = 0.5,hcenter=false, vcenter = false, rotation=1) {
    rotate([rotation == 1 ? 90 : 0, rotation == 2 ? 90 : 0, 0])
    translate([
      -clr - (hcenter ? (x * size + clr * 2) / 2 : 0),
      -clr - (vcenter ? (y * size + clr * 2) / 2 : 0),
      -0.01])
    rcube([x * size + clr * 2, y * size + clr * 2, depth + 0.01], r, 64, true);
}

//create male pins along x axis.
module pin_standin_male(count, pitch = 2.54, h_over = 6, h_under=3, thickness = 0.7) {
   for(i=[0:count-1]) {
      translate([i*pitch-pitch*0.5, -pitch*0.45]) {
         color([1,1,0.0]) {
            translate([pitch*0.15, pitch*0.05])
            cube([pitch*0.7, pitch*0.9, pitch]);
            linear_extrude(height=pitch)
            polygon([
               [0, pitch*0.2],
               [pitch*0.15, pitch*0.05],
               [pitch*0.15, pitch*0.95],
               [0, pitch*0.8]
            ]);   
            linear_extrude(height=pitch)
            polygon([
               [pitch, pitch*0.2],
               [pitch*0.85, pitch*0.05],
               [pitch*0.85, pitch*0.95],
               [pitch, pitch*0.8]
            ]);
         }
         color(csilver) {
            translate([pitch*0.5-thickness*0.5, pitch*0.5-thickness*0.5, -h_under])
            cube([thickness, thickness, h_under+h_over+pitch]);
         }
      }
   }
}

//create male pins along x axis.
module pin_standin_male_angled(count, pitch = 2.54, h_over = 6, h_under = 3, thickness = 0.7) {
   for(i=[0:count-1]) {
      translate([i*pitch-pitch*0.5, -pitch*0.45]) {
         rotate([90, 0, 0])
         color([1,1,0.0]) {
            translate([pitch*0.15, pitch*0.05])
            cube([pitch*0.7, pitch*0.9, pitch]);

            linear_extrude(height=pitch)
            polygon([
               [0, pitch*0.2],
               [pitch*0.15, pitch*0.05],
               [pitch*0.15, pitch*0.95],
               [0, pitch*0.8]
            ]);

            linear_extrude(height=pitch)
            polygon([
               [pitch, pitch*0.2],
               [pitch*0.85, pitch*0.05],
               [pitch*0.85, pitch*0.95],
               [pitch, pitch*0.8]
            ]);
         }
         color(csilver) {
            translate([pitch*0.5-thickness*0.5, pitch*0.5-thickness*0.5, -h_under])
            cube([thickness, thickness, h_under+pitch*0.5+thickness*0.5]);
         }
         color(csilver) {
            translate([pitch*0.5-thickness*0.5, pitch*0.5-thickness*0.5-pitch*1.5-h_over, pitch*0.5-thickness*0.5])
            cube([thickness, pitch*1.5+h_over, thickness]);
         }
      }
   }
}

//size of board [w, h], holeradius height of the part, offset from edges to center of hole [x, y], clearance. This function adds clr to z as well (x2)
module holes_around(size, holeradius, height, off, clr = 0.25) {
   
      translate([off[0],off[1],-clr])
      cylinder(r=holeradius+clr, h=height+clr*2, $fs=0.25, $fn=24);
    
      translate([size[0]-off[0],off[1],-clr])
      cylinder(r=holeradius+clr, h=height+clr*2, $fs=0.25, $fn=24);
   
      translate([size[0]-off[0],size[1]-off[1],-clr])
      cylinder(r=holeradius+clr, h=height+clr*2, $fs=0.25, $fn=24);

      translate([off[0],size[1]-off[1],-clr])
      cylinder(r=holeradius+clr, h=height+clr*2, $fs=0.25, $fn=24);
}

//create pin holes in x axis. Clearance will be added to radius and z axis. First hole is centered at 0, 0
module pin_holes(count, radius, height, pitch = 2.54, clr = 0.25) {
   for(i=[0:count-1]) {
      translate([pitch*i, 0,-clr])
      cylinder(r=radius, h=height+clr*2, $fs=0.25, $fn=24);
   }
}

module semi_cylinder(r, h, ang, $fn=24, center = true) {
   a = ang/$fn;
   linear_extrude(height=h, convexity=8)
   translate(center ? [0, 0] : [-r * cos(a*$fn/2), 0])
   polygon([for(i=[-$fn/2:$fn/2]) 
      [r * cos(i*a), r * sin(i*a)]
   ], convexity=8);
}

module semi_cylinder_double(r, h, start, ang, $fn=24, center = true) {
   a = ang/$fn;
   linear_extrude(height=h, convexity=8)
   translate(center ? [0, 0] : [-r * cos(a*$fn/2), 0])
   polygon([for(i=[-$fn:$fn])
      i == 0 ?
         [r * cos(1*a+start), 0]
      : i > 0 ? 
         [r * cos(i*a+start), r * sin(i*a+start)]
      :
         [r * cos(i*a-start), r * sin(i*a-start)]
   ], convexity=8);
}

module cylinder_shell(r, thickness, h, $fn = 24) {
   difference() {
      cylinder(r = r+thickness, h=h, $fn=$fn);
      translate([0,0,-0.05])
      cylinder(r = r, h=h+0.1, $fn=$fn);
   }
}

module semi_cylinder_shell(r, thickness, h, ang, fn = 24) {
   difference() {
      semi_cylinder(r+thickness, h, ang, fn);
      translate([0,0,-0.05])
      semi_cylinder(r, h+0.1, ang, fn);
   }
}

module semi_cylinder_double_shell(r, thickness, h, start, ang, $fn = 24) {
   difference() {
      semi_cylinder_double(r+thickness, h, start, ang, $fn);
      translate([0,0,-0.05])
      semi_cylinder_double(r, h+0.1, start, ang, $fn);
   }
}

//$fn is per segment for on sections
module cylinder_shell_parts(r, thickness, h, on = 15, off=45, $fn = 4) {
   segments = ceil(360 / (on+off));
   
   aps = on / $fn;
   
   for(s = [0:segments-1])
      linear_extrude(height=h, convexity=8)
      polygon(concat([
            for(a = [0:$fn])
               let (ang = s*(on+off)+aps *a)
               [(r+thickness) * cos(ang), (r+thickness) * sin(ang)]
      ],
      [
            for(a = [0:$fn])
               let (ang = s*(on+off)+on-aps*a)
               [r * cos(ang), r * sin(ang)]
      ]), convexity=8);
}

module box_18650(w = 18.8, h = 15, l = 70, bt = 1.67, st = 1, offset = [0, 0, 0]) {
    difference() {
        //translate([0, -18.8/2])
        rcube([l, w, h], r=2, extend=st);

        //battery
        translate([offset[0], (w-18.8)/2+offset[1], 9.4+bt+offset[2]])
        rcube([70, 18.8, h], tight=true);

        translate([offset[0], w/2+offset[1], 9.4+bt+offset[2]])
        rotate([0,90,0])
        cylinder(r=9.4, h=70, $fn=128);
    }
}

module mirror_dup(v, t = [0,0,0]) {
    translate(t)
    children();
    
    mirror(v)
    translate(t)
    children();
}

function slice(list, start, end) = [for(i=[start:end-1]) list[i]];

function before(list, end) = [for(i=[0:end-1]) list[i]];

function after(list, start) = [for(i=[start:len(list)-1]) list[i]];

// take maximum of given dimension
function max_dim_imp(list, n, pos) = 
    len(list) == pos+1 ? 
        list[pos][n]   :
        max(list[pos][n], max_dim_imp(list, n, pos+1));

function max_dim(list, n) = 
    list == [] ? undef : max_dim_imp(list, n, 0);

// take maximum of given dimension
function max_dim_after_imp(list, n, pos) = 
    len(list) == pos+1 ? 
        list[pos][n]   :
        max(list[pos][n], max_dim_imp(list, n, pos+1));

function max_dim_after_impl(list, n, pos) =
    len(list) == pos+1 ? 
        max(after(list[pos], n)) :
        max(max(after(list[pos],n)), max_dim_imp(list, n, pos+1));

function max_dim_after(list, n) = 
    list == [] ? undef : max_dim_after_imp(list, n, 0);

function cumulative(list, n) = 
    list == [] ? 0   :
    n == 0 ? list[0] :
    cumulative(list, n-1) + list[n];

function switch(ind, options) = options[ind];

function map_get_impl(map, key) = [
    for(elm = map)
        if(elm[0] == key) elm[1]
];

function map_get(map, key, def = undef) = 
    let (fnd = map_get_impl(map, key))
    len(fnd) > 0 ? fnd[0] : def;

function get_idx(list, idx, def = undef) = 
    is_list(list) ?
        len(list) > idx && idx >= 0 ? list[idx] : def :
        def;

function rotate_list(list, shift) = [for(i=[0:len(list)-1]) list[(i-shift+len(list))%len(list)]];
