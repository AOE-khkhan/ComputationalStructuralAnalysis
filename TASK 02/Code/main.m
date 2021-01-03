function main
clear
clc
close all

% Load mesh data
input_fuselage_enric

% Material properties
rho1 =   2700; % kg/m3
E1   = 68.9e9; % Pa
nu1  =   0.33; % Poisson's ratio
rho2 =   2810; % kg/m3
E2   =   72e9; % Pa % Enric te 72e9
nu2  =   0.33; % Poisson's ratio

% Atmosphere
rhoa = 1.225;             % Air Density [kg/m3]
g = 9.81;                 % Gravity Acceleration [m/s2]

% Section A : Structural Weight
Ms = 22900;              % Mass fuselage [kg]

% Section B : Passenger Weight
Mp = 13500;              % Mass passengers [kg]

% Section C : Wing loads
Ff = [78.94e3 ; 72.22e3 ; -71.07e3];
Fr = [17.18e3 ; -72.22e3 ; -25.47e3];
Mf = [-349.08e3 ; 194.87e3 ; -86.29e3];
Mr = [-203.02e3 ; 83.85e3 ; -91.93e3];

% Section D : Loads nose & tail cone
CD = 0.42;               % Drag coefficient
V = 230;                 % Velocity [m/s]
S = 12.84;               % Cross section area [m2]
L_tail = 164.01e3;       % Lift tail [N]
D_tail = 17.58e3;        % Drag tail [N]

% Section E : Cabin pressure
pin = 78191.21;          % Cabin pressure [Pa]
pout = 22632.06;         % Outside pressure [Pa]

[n_beams, n_plates, n] = dimensions (Tbeams, Tplates, xnodes);
n_beams.el = [Tframe' Tstring' Treinf'];    % Beam elements
n_plates.el = [Tskin' Tfloor'];            % Plate elements

%% SECTION PARAMETERS
    n_elem = size(Tbeams,1);
    
    beams.le = zeros(n_elem,1); % Length of the element
    beams.m = zeros(n_elem,1); %mass of the element
    beams.V = zeros(n_elem,1); %volume of the element
    
%% Section A parameters

    h1 = 75e-3;     t1 = 2.5e-3;    a = 25e-3;

    % CG and A
    a1 = 2 * a;     b1 = t1;
    a2 = a + t1/2;  b2 = t1; 
    a3 = t1;        b3 = h1 - t1;

    y1 = 0;                      z1 = h1 / 2;
    y2 = - ((a+t1/2)/2 - t1/2);  z2 = -h1 / 2;
    y3 = 0;                      z3 = 0;

    [Iya, Iza, Aa, Ja] = Inertia_calculation(y1,z1, y2,z2, y3,z3, a1,b1, a2,b2, a3,b3);
    [beams.m, beams.le, beams.V] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Tframe, Tbeams, xnodes, rho1, Aa);

%% Section B parameters
    h2 = 25e-3;     t2 = 2e-3;      b  = 16e-3;     c  = 21e-3;

    % Beam side lengths
    a1 = c + t2/2;  b1 = t2;
    a2 = b + t2/2;  b2 = t2;
    a3 = t2;        b3 = h2 - t2;
    
    % Segment centroid
    y1 = (c+t2/2)/2 - t2/2;        z1 = h2 / 2;
    y2 = -((b+t2/2)/2 - t2/2) ;    z2 = -h2 / 2;
    y3 = 0;                        z3 = 0;
    
    [Iyb, Izb, Ab, Jb] = Inertia_calculation(y1,z1, y2,z2, y3,z3, a1,b1, a2,b2, a3,b3);
    [beams.m, beams.le, beams.V] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Tstring, Tbeams, xnodes, rho1, Ab);

%% Section C parameters
    h3 = 50e-3;     t3 = 3e-3;      d  = 25e-3;
    
    % CG and A
    a1 = 2 * d; b1 = t3;
    a2 = t3;    b2 = h3 - t3/2;
    a3 = 0;     b3 = 0;
    
    % Segment centroid
    y1 = 0;     z1 = h3 / 2;
    y2 = 0;     z2 = 0;
    y3 = 0;     z3 = 0;
    
    [Iyc, Izc, Ac, Jc] = Inertia_calculation(y1,z1, y2,z2, y3,z3, a1,b1, a2,b2, a3,b3);
    [beams.m, beams.le, beams.V] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Treinf, Tbeams, xnodes, rho2, Ac);

    % Beam properties
    mat_beams = [
    %  Density  Young   Poisson     A     Iy     Iz     J
          rho1,    E1,      nu1,   Aa,   Iya,   Iza,   Ja; % Frames (1)
          rho1,    E1,      nu1,   Ab,   Iyb,   Izb,   Jb; % Stringers (2)
          rho2,    E2,      nu2,   Ac,   Iyc,   Izc,   Jc; % Reinforcements (3)
    ];

    % Stiffness matrix computation

    [R_beams, K_beams] = beam_elements(n_beams, beams.le, Tmat_beams, mat_beams, dat_beams);
    
    load('Reb_enric.mat');
    result = R_beams == Reb_enric;
    id1 = find(result == 0);
    
    load('Keb_enric.mat');
    result = K_beams == Keb_enric;
    id2 = find(result == 0);

%% PLATES

    % Plates thickness
    hs = 4e-3; hf = 8e-3;

    % Plate properties
    mat_plates = [
    %  Density  Young   Poisson     h
          rho2,    E2,      nu2,   hs; % Skin (1)
          rho2,    E2,      nu2,   hf; % Floor (2)
    ];

    [plates.m, plates.a, plates.b, plates.V] = plates_mass_length_calculus(Tplates, xnodes, mat_plates, Tmat_plates);
    
    % Stiffness matrix computation
    
    [R_plates, K_plates] = plate_elements(n_plates, Tmat_plates, mat_plates, dat_plates, plates.a, plates.b);

        load('Kep_enric.mat');
        result = K_plates == Kep_enric;
        id3 = find(result == 0);
%% RHO EFFECTIVE AND TOTAL MASS

    [beams, plates] = rho_mass_calculus (beams, plates, n_beams, n_plates, Tmat_beams, Tmat_plates, mat_beams, mat_plates, Ms);

%% Join Beams and Plates Matrix:
    
    %Degrees of freedom connnectivities table
    
    n_beams.T2 = calculate_T2 (n_beams, Tbeams, 'beams');
    n_plates.T2 = calculate_T2 (n_plates, Tplates, 'plates');

    bool = true;

if bool == false 
    
    load('T2_beams_enric.mat');
        result = n_beams.T2 == T2_beams_enric;
        id4 = find(result == 0);
        
    load('T2_plates_enric.mat');
        result = n_plates.T2 == T2_plates_enric;
        id5 = find(result == 0);
    
    n_dof = n.n_dof;
    beam_el = n_beams.el;
    plate_el = n_plates.el;
    
    KG = sparse(n_dof,n_dof);
    
    Tdof_b = n_beams.T2;
    
    for e = beam_el
        i = Tdof_b(:,e);
        I = repmat(i,size(Tdof_b,1),1);
        J = repelem(i,size(Tdof_b,1),1);
        KG = KG + sparse(I,J,K_beams(:,:,e),n_dof,n_dof);
    end

    load('KG_enric_1.mat');
    result = KG == KG_enric_1;
    id7 = find(result == 0);
    
    KG = sparse(n_dof,n_dof);
    
    Tdof_p = n_plates.T2;

    % Plates
    for e = plate_el
        i = Tdof_p(:,e);
        I = repmat(i,size(Tdof_p,1),1);
        J = repelem(i,size(Tdof_p,1),1);
        KG = KG + sparse(I,J,K_plates(:,:,e),n_dof,n_dof);
    end
    
    
    
    load('KG_enric.mat');
    result = KG == KG_enric;
    id7 = find(result == 0);
%% Prescribed degrees of freedom

Tsym;


%Obtain the prescribed degrees of freedom vector by applying the symmetry condition on all nodes lying on the XZ-plane (list of nodes provided in Tsym). 
% Hint: To apply symmetry conditions with respect to XZ-plane, one must prescribe the displacement in y-direction and the rotations around x and z-axes. 
% Additionally, the displacement in x and z-directions of some node will need to be prescribed in order to avoid rigid body modes.

p = 1;
for i = 1:length(Tsym)
   % (1) = 1, 2, 3, 4, 5, 6
   % (2) = 7, 8, 9, 10, 11, 12
   e = Tsym(i);
   % displacement blocked in y-direction
   vr(p) = (e-1)*n.n_deg + 2; p=p+1;
   % rotation blocked in x-direction
   vr(p) = (e-1)*n.n_deg + 4; p=p+1;
   % rotation blocked in z-direction
   vr(p) = (e-1)*n.n_deg + 6; p=p+1;   
end

% Add a node with restricted x and z displacements. 
e = Tsym(1);
vr(p) = (e-1)*n.n_deg + 1; p=p+1;
vr(p) = (e-1)*n.n_deg + 3; p=p+1;

vl = setdiff(1:n.n_dof,vr);

end

% Get vr and vl ...

%% A) Structural weight

% Solve problem for loading case A ...

%% B) Weight of the cabin passengers

% Solve problem for loading case B ...

%% C) Loads transmitted by the wing

% Solve problem for loading case C ... 

%% D) Loads transmitted by the nose and the tail cone

F_nose = zeros( 2 * n_beams.n_nel * n_beams.n_deg/2, length(Tnose));
F_tail = zeros( 2 * n_beams.n_nel * n_beams.n_deg/2, length(Ttail));

l_nose = 2 * sum(beams.le(Tnose));
D_nose = 0.5 * rhoa * V * V * S * CD;
q_nose = [ D_nose/l_nose ; 0 ; 0 ];

% 1. Drag nose 
for i = 1:length(Tnose)
    e = Tnose(i);
    F_nose (:,e) = beam_force (e, beams.le, n_beams, R_beams, q_nose);
end

% 2. Drag + Lift tail : Distributed force + Element force vector
l_tail = 2 * sum(beams.le(Ttail));
q_tail = [ D_tail/l_tail ; 0 ; L_tail/l_tail ];
for i = 1:length(Ttail)
    e = Ttail(i);
    F_tail (:,e) = beam_force(e, beams.le, n_beams, R_beams, q_tail);
end

% 3. Global force vector : Drag + Lift - Nose & Tail

F = zeros(n_beams.n_dof,1);
for j = 1:length(Tnose)
    e = Tnose(j);
    i = n_beams.T2(:,e)';
    F(i) = F(i) + F_nose(:,e);
end
for j = 1:length(Ttail)
    e = Ttail(j);
    i = n_beams.T2(:,e)';
    F(i) = F(i) + F_tail(:,e);
end

    %case 5
    %    vr = [(925-1)*6+1 (925-1)*6+3]; % centro en medio
    %case 6
    %    vr = [1555 1557 11803 11805]; % abajo delante y detras

    
[u,R] = solver (vr, vl, KG, f, n_dof);




stop = true;
%% E) Cabin pressure

% Solve problem for loading case E ...

%% Postprocess

plotFuselage(xnodes,Tbeams,Tplates,Tmat_beams,Tmat_plates,u,uint_beams,N,Qy,Qz,T,My,Mz,uint_plates,mat_plates)
end

function load_D (beam)
    
end


function [Iy, Iz, A, J] = Inertia_calculation(y1,z1, y2,z2, y3,z3, a1,b1, a2,b2, a3,b3)
    
    s1 = a1 * b1;     s2 = a2 * b2;     s3 = a3 * b3;
    A = s1 + s2 + s3;
    
    y_cg = (y1 * s1 + y2 * s2  + y3 * s3) / A; 
    z_cg = (z1 * s1 + z2 * s2  + z3 * s3) / A; 
    
    Iy1 = (a1*b1^3)/12;     Iz1 = (a1^3*b1)/12;
    Iy2 = (a2*b2^3)/12;     Iz2 = (a2^3*b2)/12;
    Iy3 = (a3*b3^3)/12;     Iz3 = (a3^3*b3)/12;
    
    Iy = (Iy1 + s1 * (z1 - z_cg)^2) + (Iy2 + s2 * (z2 - z_cg)^2) + (Iy3 + s3 * (z3 - z_cg)^2);
    Iz = (Iz1 + s1 * (y1 - y_cg)^2) + (Iz2 + s2 * (y2 - y_cg)^2) + (Iz3 + s3 * (y3 - y_cg)^2);

    J = 4 * ( min(Iy1,Iz1) + min(Iy2,Iz2) + min(Iy3,Iz3) );
    
end


function [R_e, K_el] = beam_and_plates_elements(n, l_elem, T_mat, mat, dat)
   
    Kel = zeros(n.n_nel*n.n_deg,n.n_nel*n.n_deg,n.n_elem);
    Fel = zeros(n.n_nel*n.n_deg, n.n_elem);
    
    for e=1:n.n_elem
        
        %ROTATION MATRIX
        alpha=dat(e,1);
        beta=dat(e,2);
        gamma=dat(e,3);
   
        R = [ cos(beta)*cos(gamma), cos(beta)*sin(gamma), sin(beta);
            -(sin(alpha)*sin(beta)*cos(gamma))-(cos(alpha)*sin(gamma)), -(sin(alpha)*sin(beta)*sin(gamma))+(cos(alpha)*cos(gamma)), sin(alpha)*cos(beta);
            -(cos(alpha)*sin(beta)*cos(gamma))+(sin(alpha)*sin(gamma)), -(cos(alpha)*sin(beta)*sin(gamma))-(sin(alpha)*cos(gamma)), cos(alpha)*cos(beta)];
        
        Re = zeros(12);
        
        Re(1:3,1:3) = R; Re(4:6,4:6) = R;
        Re(7:9,7:9) = R; Re(10:12,10:12) = R;
        
        R_e(:,:,e) = Re;
        
        % MATRIX Ke
        K_e_local = zeros(12);
        
        L = l_elem(e);
        A = mat(T_mat(e),4);
        E = mat(T_mat(e),2);
        Iy = mat(T_mat(e),5);
        Iz = mat(T_mat(e),6);
        J = mat(T_mat(e),7);
        nu = mat(T_mat(e),3);
    
        % Axial stress in x-direction (bars)
        K_axial = E*A/L*[
            1,    -1;
           -1,     1;
        ];
        % Shear stress in y-direction and bending moment in z-direction (beam)
        K_sheary_bendz = 2*E*Iz/L^3*[
            6,   3*L,    -6,   3*L;
          3*L, 2*L^2,  -3*L,   L^2;
           -6,  -3*L,     6,  -3*L; 
          3*L,   L^2,  -3*L, 2*L^2;
        ];
        % Shear stress in z-direction and bending moment in y-direction (beam)
        K_shearz_bendy  = 2*E*Iy/L^3*[
            6,  -3*L,    -6,  -3*L;
         -3*L, 2*L^2,   3*L,   L^2;
           -6,   3*L,     6,   3*L; 
         -3*L,   L^2,   3*L, 2*L^2;
        ];
        % Torsion moment in x-direction
        K_torsion = E*J/(2*(1+nu)*L)*[
            1,    -1;
           -1,     1;
        ];

        K_e_local([1,7],[1,7]) = K_axial;
        K_e_local([2,6,8,12],[2,6,8,12]) = K_sheary_bendz;
        K_e_local([3,5,9,11],[3,5,9,11]) = K_shearz_bendy;
        K_e_local([4,10],[4,10]) = K_torsion;
    
        K_e = R_e(:,:,e).'*K_e_local*R_e(:,:,e);
        
    end
    
    for r=1:n.n_nel*n.n_deg
        for s=1:n.n_nel*n.n_deg
            K_el(r,s,e) = K_e(r,s);
        end
    end
    
end


function [R_e, K_el] = beam_elements2(n, l_elem, T_mat, mat, dat)
   
    Kel = zeros(n.n_nel*n.n_deg,n.n_nel*n.n_deg,n.n_elem);
    Fel = zeros(n.n_nel*n.n_deg, n.n_elem);
    
    for e=1:n.n_elem
        
        %ROTATION MATRIX
        alpha=dat(e,1);
        beta=dat(e,2);
        gamma=dat(e,3);
   
        R = [ cos(beta)*cos(gamma), cos(beta)*sin(gamma), sin(beta);
            -(sin(alpha)*sin(beta)*cos(gamma))-(cos(alpha)*sin(gamma)), -(sin(alpha)*sin(beta)*sin(gamma))+(cos(alpha)*cos(gamma)), sin(alpha)*cos(beta);
            -(cos(alpha)*sin(beta)*cos(gamma))+(sin(alpha)*sin(gamma)), -(cos(alpha)*sin(beta)*sin(gamma))-(sin(alpha)*cos(gamma)), cos(alpha)*cos(beta)];
        
        Re = zeros(12);
        
        Re(1:3,1:3) = R; Re(4:6,4:6) = R;
        Re(7:9,7:9) = R; Re(10:12,10:12) = R;
        
        R_e(:,:,e) = Re;
        
        % MATRIX Ke
        K_e_local = zeros(12);
        
        L = l_elem(e);
        A = mat(T_mat(e),4);
        E = mat(T_mat(e),2);
        Iy = mat(T_mat(e),5);
        Iz = mat(T_mat(e),6);
        J = mat(T_mat(e),7);
        nu = mat(T_mat(e),3);
    
        % Axial stress in x-direction (bars)
        K_axial = E*A/L*[
            1,    -1;
           -1,     1;
        ];
        % Shear stress in y-direction and bending moment in z-direction (beam)
        K_sheary_bendz = 2*E*Iz/L^3*[
            6,   3*L,    -6,   3*L;
          3*L, 2*L^2,  -3*L,   L^2;
           -6,  -3*L,     6,  -3*L; 
          3*L,   L^2,  -3*L, 2*L^2;
        ];
        % Shear stress in z-direction and bending moment in y-direction (beam)
        K_shearz_bendy  = 2*E*Iy/L^3*[
            6,  -3*L,    -6,  -3*L;
         -3*L, 2*L^2,   3*L,   L^2;
           -6,   3*L,     6,   3*L; 
         -3*L,   L^2,   3*L, 2*L^2;
        ];
        % Torsion moment in x-direction
        K_torsion = E*J/(2*(1+nu)*L)*[
            1,    -1;
           -1,     1;
        ];

        K_e_local([1,7],[1,7]) = K_axial;
        K_e_local([2,6,8,12],[2,6,8,12]) = K_sheary_bendz;
        K_e_local([3,5,9,11],[3,5,9,11]) = K_shearz_bendy;
        K_e_local([4,10],[4,10]) = K_torsion;
    
        K_e = R_e(:,:,e).'*K_e_local*R_e(:,:,e);
        
        for r=1:n.n_nel*n.n_deg
            for s=1:n.n_nel*n.n_deg
                K_el(r,s,e) = K_e(r,s);
            end
        end
    end

end


function [R_e, K_el] = beam_elements(n, l_elem, Tmat, mat, dat)
    
    for i=1:length(n.el)
        
        e = n.el(i);
        %ROTATION MATRIX
        alpha=dat(e,1);
        beta=dat(e,2);
        gamma=dat(e,3);
        
        %  Density  Young   Poisson     A     Iy     Iz     J
        L = l_elem(e);
        E = mat(Tmat(e),2);
        nu = mat(Tmat(e),3);
        A = mat(Tmat(e),4);
        Iy = mat(Tmat(e),5);
        Iz = mat(Tmat(e),6);
        J = mat(Tmat(e),7);
    
        sa = sin (alpha);   sb = sin (beta);   sg = sin (gamma);
        ca = cos (alpha);   cb = cos (beta);   cg = cos (gamma);

        R = [             cb*cg             cb*sg       sb;
                -sa*sb*cg-ca*sg   -sa*sb*sg+ca*cg    sa*cb;
                -ca*sb*cg+sa*sg   -ca*sb*sg-sa*cg    ca*cb];

        R_e (1:3,1:3,e) = R;
        R_e (4:6,4:6,e) = R;
        R_e (7:9,7:9,e) = R;
        R_e (10:12,10:12,e) = R;
    
        % Axial stress in x-direction (bars)
        K_axial = E*A/L*[
            1,    -1;
           -1,     1;
        ];
        % Shear stress in y-direction and bending moment in z-direction (beam)
        K_sheary_bendz = 2*E*Iz/L^3*[
            6,   3*L,    -6,   3*L;
          3*L, 2*L^2,  -3*L,   L^2;
           -6,  -3*L,     6,  -3*L; 
          3*L,   L^2,  -3*L, 2*L^2;
        ];
        % Shear stress in z-direction and bending moment in y-direction (beam)
        K_shearz_bendy  = 2*E*Iy/L^3*[
            6,  -3*L,    -6,  -3*L;
         -3*L, 2*L^2,   3*L,   L^2;
           -6,   3*L,     6,   3*L; 
         -3*L,   L^2,   3*L, 2*L^2;
        ];
        % Torsion moment in x-direction
        K_torsion = E*J/(2*(1+nu)*L)*[
            1,    -1;
           -1,     1;
        ];
        
        dof_axial = [1,7];
        K_e_local(dof_axial,dof_axial) = K_axial;
        dof_sheary_bendz = [2,6,8,12];
        K_e_local(dof_sheary_bendz,dof_sheary_bendz) = K_sheary_bendz;
        dof_shearz_bendy = [3,5,9,11];
        K_e_local(dof_shearz_bendy,dof_shearz_bendy) = K_shearz_bendy;
        dof_torsion = [4,10];
        K_e_local(dof_torsion,dof_torsion) = K_torsion;
                                                  
        K_el(:,:,e) = R_e(:,:,e).'*K_e_local*R_e(:,:,e);
    %}
        
        
        %for r=1:n.n_nel*n.n_deg
        %    for s=1:n.n_nel*n.n_deg
        %        K_el(r,s,e) = K_e(r,s);
        %    end
        %end
    end

end


function [R_e, K_el] = plate_elements(n, T_mat, mat, dat, as, bs)
   
    for e=1:n.n_elem
        
        %ROTATION MATRIX
        alpha=dat(e,1);
        beta=dat(e,2);
        gamma=dat(e,3);
   
        R = [ cos(beta)*cos(gamma), cos(beta)*sin(gamma), sin(beta);
            -(sin(alpha)*sin(beta)*cos(gamma))-(cos(alpha)*sin(gamma)), -(sin(alpha)*sin(beta)*sin(gamma))+(cos(alpha)*cos(gamma)), sin(alpha)*cos(beta);
            -(cos(alpha)*sin(beta)*cos(gamma))+(sin(alpha)*sin(gamma)), -(cos(alpha)*sin(beta)*sin(gamma))-(sin(alpha)*cos(gamma)), cos(alpha)*cos(beta)];
        
        Re = zeros(24);
        
        Re(1:3,1:3) = R; Re(4:6,4:6) = R;
        Re(7:9,7:9) = R; Re(10:12,10:12) = R;
        Re(13:15,13:15) = R; Re(16:18,16:18) = R;
        Re(19:21,19:21) = R; Re(22:24,22:24) = R; 
        
        R_e(:,:,e) = Re;
        % MATRIX Ke
        %  Density  Young   Poisson     h
        K_e_local = zeros(24);
        
        %  Density  Young   Poisson     h
        E = mat(T_mat(e),2);
        nu = mat(T_mat(e),3);
        h = mat(T_mat(e),4);
        a = as(e); 
        b = bs(e); 
    
        % In-plane stress in x and y-directions (rectangular membrane)
        K_1 = ...
        E*b*h/(12*a*(1-nu^2))*[
            4,         0, -4,         0, -2,         0,  2,         0;
            0,  2*(1-nu),  0, -2*(1-nu),  0,   -(1-nu),  0,      1-nu;
           -4,         0,  4,         0,  2,         0, -2,         0;
            0, -2*(1-nu),  0,  2*(1-nu),  0,      1-nu,  0,   -(1-nu);
           -2,         0,  2,         0,  4,         0, -4,         0;
            0,   -(1-nu),  0,      1-nu,  0,  2*(1-nu),  0, -2*(1-nu);
            2,         0, -2,         0, -4,         0,  4,         0;
            0,      1-nu,  0,   -(1-nu),  0, -2*(1-nu),  0,  2*(1-nu);
        ] + ...
        E*a*h/(12*b*(1-nu^2))*[
            2*(1-nu),  0,      1-nu,  0,   -(1-nu),  0, -2*(1-nu),  0;
                   0,  4,         0,  2,         0, -2,         0, -4;
                1-nu,  0,  2*(1-nu),  0, -2*(1-nu),  0,   -(1-nu),  0;
                   0,  2,         0,  4,         0, -4,         0, -2;
             -(1-nu),  0, -2*(1-nu),  0,  2*(1-nu),  0,      1-nu,  0;
                   0, -2,         0, -4,         0,  4,         0,  2;
           -2*(1-nu),  0,   -(1-nu),  0,      1-nu,  0,  2*(1-nu),  0;
                   0, -4,         0, -2,         0,  2,         0,  4;
        ] + ...
        E*h/(8*(1-nu^2))*[
                   0,      1+nu,         0, -(1-3*nu),         0,   -(1+nu),         0,    1-3*nu;
                1+nu,         0,    1-3*nu,         0,   -(1+nu),         0, -(1-3*nu),         0;
                   0,    1-3*nu,         0,   -(1+nu),         0, -(1-3*nu),         0,      1+nu;
           -(1-3*nu),         0,   -(1+nu),         0,    1-3*nu,         0,      1+nu,         0;
                   0,   -(1+nu),         0,    1-3*nu,         0,      1+nu,         0, -(1-3*nu);
             -(1+nu),         0, -(1-3*nu),         0,      1+nu,         0,    1-3*nu,         0;
                   0, -(1-3*nu),         0,      1+nu,         0,    1-3*nu,         0,   -(1+nu);
              1-3*nu,         0,      1+nu,         0, -(1-3*nu),         0,   -(1+nu),         0;
        ];
        
    % Out-of-plane stress in z-direction and in-plane bending moment in x and y-directions (rectangular plate)
        K_2 = ...
        E*a*h^3/(72*b^3*(1-nu^2))*[
                 6,  0,    6*b,    3,  0,    3*b,   -3,  0,    3*b,   -6,  0,    6*b;
                 0,  0,      0,    0,  0,      0,    0,  0,      0,    0,  0,      0;
               6*b,  0,  8*b^2,  3*b,  0,  4*b^2, -3*b,  0,  2*b^2, -6*b,  0,  4*b^2;
                 3,  0,    3*b,    6,  0,    6*b,   -6,  0,    6*b,   -3,  0,    3*b;
                 0,  0,      0,    0,  0,      0,    0,  0,      0,    0,  0,      0;
               3*b,  0,  4*b^2,  6*b,  0,  8*b^2, -6*b,  0,  4*b^2, -3*b,  0,  2*b^2;
                -3,  0,   -3*b,   -6,  0,   -6*b,    6,  0,   -6*b,    3,  0,   -3*b;
                 0,  0,      0,    0,  0,      0,    0,  0,      0,    0,  0,      0;
               3*b,  0,  2*b^2,  6*b,  0,  4*b^2, -6*b,  0,  8*b^2, -3*b,  0,  4*b^2;
                -6,  0,   -6*b,   -3,  0,   -3*b,    3,  0,   -3*b,    6,  0,   -6*b;
                 0,  0,      0,    0,  0,      0,    0,  0,      0,    0,  0,      0;
               6*b,  0,  4*b^2,  3*b,  0,  2*b^2, -3*b,  0,  4*b^2, -6*b,  0,  8*b^2;
        ] + ...
        E*b*h^3/(72*a^3*(1-nu^2))*[
                 6,    6*a,  0,   -6,    6*a,  0,   -3,    3*a,  0,    3,    3*a,  0;
               6*a,  8*a^2,  0, -6*a,  4*a^2,  0, -3*a,  2*a^2,  0,  3*a,  4*a^2,  0;
                 0,      0,  0,    0,      0,  0,    0,      0,  0,    0,      0,  0;
                -6,   -6*a,  0,    6,   -6*a,  0,    3,   -3*a,  0,   -3,   -3*a,  0;
               6*a,  4*a^2,  0, -6*a,  8*a^2,  0, -3*a,  4*a^2,  0,  3*a,  2*a^2,  0;
                 0,      0,  0,    0,      0,  0,    0,      0,  0,    0,      0,  0;
                -3,   -3*a,  0,    3,   -3*a,  0,    6,   -6*a,  0,   -6,   -6*a,  0;
               3*a,  2*a^2,  0, -3*a,  4*a^2,  0, -6*a,  8*a^2,  0,  6*a,  4*a^2,  0;
                 0,      0,  0,    0,      0,  0,    0,      0,  0,    0,      0,  0;
                 3,    3*a,  0,   -3,    3*a,  0,   -6,    6*a,  0,    6,    6*a,  0;
               3*a,  4*a^2,  0, -3*a,  2*a^2,  0, -6*a,  4*a^2,  0,  6*a,  8*a^2,  0;
                 0,      0,  0,    0,      0,  0,    0,      0,  0,    0,      0,  0;
        ] + ...
        E*nu*h^3/(24*a*b*(1-nu^2))*[
                 1,      a,      b, -1,      0,     -b,  1,      0,      0, -1,     -a,      0;
                 a,      0,  2*b*a,  0,      0,      0,  0,      0,      0, -a,      0,      0;
                 b,  2*a*b,      0, -b,      0,      0,  0,      0,      0,  0,      0,      0;
                -1,      0,     -b,  1,     -a,      b, -1,      a,      0,  1,      0,      0;
                 0,      0,      0, -a,      0, -2*b*a,  a,      0,      0,  0,      0,      0;
                -b,      0,      0,  b, -2*a*b,      0,  0,      0,      0,  0,      0,      0;
                 1,      0,      0, -1,      a,      0,  1,     -a,     -b, -1,      0,      b;
                 0,      0,      0,  a,      0,      0, -a,      0,  2*b*a,  0,      0,      0;
                 0,      0,      0,  0,      0,      0, -b,  2*a*b,      0,  b,      0,      0;
                -1,     -a,      0,  1,      0,      0, -1,      0,      b,  1,      a,     -b;
                -a,      0,      0,  0,      0,      0,  0,      0,      0,  a,      0, -2*b*a;
                 0,      0,      0,  0,      0,      0,  b,      0,      0, -b, -2*a*b,      0;
        ] + ...
        E*h^3/(360*a*b*(1+nu))*[
                21,    3*a,    3*b,  -21,    3*a,   -3*b,   21,   -3*a,   -3*b,  -21,   -3*a,    3*b;
               3*a,  8*a^2,      0, -3*a, -2*a^2,      0,  3*a,  2*a^2,      0, -3*a, -8*a^2,      0;
               3*b,      0,  8*b^2, -3*b,      0, -8*b^2,  3*b,      0,  2*b^2, -3*b,      0, -2*b^2;
               -21,   -3*a,   -3*b,   21,   -3*a,    3*b,  -21,    3*a,    3*b,   21,    3*a,   -3*b;
               3*a, -2*a^2,      0, -3*a,  8*a^2,      0,  3*a, -8*a^2,      0, -3*a,  2*a^2,      0;
              -3*b,      0, -8*b^2,  3*b,      0,  8*b^2, -3*b,      0, -2*b^2,  3*b,      0,  2*b^2;
                21,    3*a,    3*b,  -21,    3*a,   -3*b,   21,   -3*a,   -3*b,  -21,   -3*a,    3*b;
              -3*a,  2*a^2,      0,  3*a, -8*a^2,      0, -3*a,  8*a^2,      0,  3*a, -2*a^2,      0;
              -3*b,      0,  2*b^2,  3*b,      0, -2*b^2, -3*b,      0,  8*b^2,  3*b,      0, -8*b^2;
               -21,   -3*a,   -3*b,   21,   -3*a,    3*b,  -21,    3*a,    3*b,   21,    3*a,   -3*b;
              -3*a, -8*a^2,      0,  3*a,  2*a^2,      0, -3*a, -2*a^2,      0,  3*a,  8*a^2,      0;
               3*b,      0, -2*b^2, -3*b,      0,  2*b^2,  3*b,      0, -8*b^2, -3*b,      0,  8*b^2;
        ];
    
        % Torsion moment in z-direction (rectangular plate)
        K_3 = 4*a*b*E*[
           1,  0,  0,  0;
           0,  1,  0,  0;
           0,  0,  1,  0;
           0,  0,  0,  1; 
        ];
        
        var1 = [1,2,7,8,13,14,19,20];
        var2 = [3,4,5,9,10,11,15,16,17,21,22,23];
        var3 = [6,12,18,24];

        K_e_local(var1, var1) = K_1;
        K_e_local(var2, var2) = K_2;
        K_e_local(var3, var3) = K_3;

        K_el(:,:,e) = R_e(:,:,e).'*K_e_local*R_e(:,:,e);
        
    end

end


function [fe] = beam_force (e, le, n_beams, R_beams, qe)

fe = zeros (2 * n_beams.n_deg,1);

R = R_beams (1:3,1:3,e);
       
qe = R * qe;
l = le(e);

fe ([1,7]) = (0.5 * qe (1) * l) * [1 ; 1];
fe ([2,6,8,12]) = (0.5 * qe (2) * l) * [1 ; l/6 ; 1 ; -l/6];
fe ([3,5,9,11]) = (0.5 * qe (3) * l) * [1 ; -l/6 ; 1 ; l/6];

fe = R_beams(:,:,e)' * fe;

end


function [n_beams, n_plates, n] = dimensions (Tbeams, Tplates, xnodes)

%% PREPROCESS
    n_beams.n_deg = 6; % Degrees of freedom per node
    n_beams.n_elem = size(Tbeams,1); % Number of elements
    n_beams.n_nel = size(Tbeams,2); % Number of nodes in a beam
    n_beams.n_nod = size(xnodes,1); %Total number of nodes
    n_beams.n_dof = n_beams.n_nod*n_beams.n_deg; %Total number of degrees of freedom
    
    n_plates.n_deg = 6; % Degrees of freedom per node
    n_plates.n_elem = size(Tplates,1); % Number of elements
    n_plates.n_nel = size(Tplates,2); % Number of nodes in a plate
    n_plates.n_nod = size(xnodes,1); %Total number of nodes
    n_plates.n_dof = n_beams.n_nod*n_beams.n_deg; %Total number of degrees of freedom
    
    n.n_deg = 6; % Degrees of freedom per node
    n.n_elem = size(Tbeams,1) + size(Tplates,1); % Number of elements
    n.n_nod = size(xnodes,1); %Total numbre of nodes
    n.n_dof = n.n_nod*n.n_deg; %Total number of degrees of freedom
end


function [m, le, V] = beam_mass_length_calculus (m, le, V, T, Tbeams, xnodes, rho, A)
    for i = 1:length(T)
        e = T(i);
        % Coordinates 
        x1 = xnodes( Tbeams(e,1), 1 );       x2 = xnodes( Tbeams(e,2), 1 );
        y1 = xnodes( Tbeams(e,1), 2 );       y2 = xnodes( Tbeams(e,2), 2 );
        z1 = xnodes( Tbeams(e,1), 3 );       z2 = xnodes( Tbeams(e,2), 3 ); 

        % Length 
        le(e) = sqrt ( (x2-x1).^2 + (y2-y1).^2 + (z2-z1).^2 );

        % Volume 
        V(e) = A * le(e);

        % Mass beam
        m(e) = V(e) .* rho;

    end
end


function [m, a, b, V] = plates_mass_length_calculus(Tplates, xnodes, mat_plates, Tmat_plates)
    
    for e = 1:size(Tplates,1)

        x1 = xnodes( Tplates(e,1), 1 );       x2 = xnodes( Tplates(e,2), 1 );
        y1 = xnodes( Tplates(e,1), 2 );       y2 = xnodes( Tplates(e,2), 2 );
        z1 = xnodes( Tplates(e,1), 3 );       z2 = xnodes( Tplates(e,2), 3 ); 

        x3 = xnodes( Tplates(e,3), 1 );       x4 = xnodes( Tplates(e,4), 1 );
        y3 = xnodes( Tplates(e,3), 2 );       y4 = xnodes( Tplates(e,4), 2 );
        z3 = xnodes( Tplates(e,3), 3 );       z4 = xnodes( Tplates(e,4), 3 );

        % a
        a(e) = sqrt ( (x2-x1).^2 + (y2-y1).^2 + (z2-z1).^2 ) / 2;
        b(e) = sqrt ( (x4-x1).^2 + (y4-y1).^2 + (z4-z1).^2 ) / 2;
        h = mat_plates(Tmat_plates(e),4);
        rho = mat_plates(Tmat_plates(e),1);

        V(e) = 4 * a(e) * b(e) * h;

        m(e) = rho * V(e);
    end
end


function [beams, plates] = rho_mass_calculus (beams, plates, n_beams, n_plates, Tmat_beams, Tmat_plates, mat_beams, mat_plates, Ms)
    beams.Vtotal = 2 * sum(beams.V);
    beams.Mtotal = 2 * sum(beams.m);
    plates.Vtotal = 2 * sum(plates.V);
    plates.Mtotal = 2 * sum(plates.m);

    rho_pseudo = (Ms - beams.Mtotal - plates.Mtotal ) / (beams.Vtotal  + plates.Vtotal);

    % Effective density element
    for e = n_beams.el
        rho = mat_beams (Tmat_beams(e),1);
        rho_eff = rho + rho_pseudo;
        beams.rho_eff (e) = rho_eff;
    end
    for e = n_plates.el
        rho = mat_plates (Tmat_plates(e),1);
        rho_eff = rho + rho_pseudo;
        plates.rho_eff (e) = rho_eff;
    end
end


function T2 = calculate_T2 (n, T, x)
    
    T2=zeros(n.n_deg*n.n_nel, n.n_elem); 
    
    ndim = n.n_deg / 2;
    
    if strcmp(x,'beams') == 1
        for e = n.el
            I = T(e,1);
            J = T(e,2);
            for i = 1:2*ndim
                T2(i,e) = (I-1) * 2 * ndim + i;
                T2(i+2*ndim,e) = (J-1) * 2 * ndim + i;  
            end
        end
    end
    
    if strcmp(x,'plates') == 1
        for e = n.el
            G = T(e,1);
            H = T(e,2);
            I = T(e,3);
            J = T(e,4);
            for i = 1:2*ndim
                T2(i,e) = (G-1) * 2 * ndim + i;
                T2(i+2*ndim,e) = (H-1) * 2 * ndim + i;  
                T2(i+4*ndim,e) = (I-1) * 2 * ndim + i; 
                T2(i+6*ndim,e) = (J-1) * 2 * ndim + i; 
            end
        end
    end
  
end


function [u,R] = solver (vr, vl, KG, f, n_dof)

    ur = zeros (length(vr) , 1);                              % Imposed disp.

    % Partitioned system of equations : Stiffness

    Kll = KG(vl,vl);
    Klr = KG(vl,vr);
    Krl = KG(vr,vl);
    Krr = KG(vr,vr);

    u = zeros (n_dof , 1);
    R = zeros (n_dof , 1);

    % Partitioned system of equations : Force
    fl = f(vl,1);
    fr = f(vr,1);

    % Solve linear system
    ul = Kll \ (fl - Klr * ur);                            % Free displacements
    Rr = Krr * ur + Krl * ul - fr;                         % Reactions 

    % Assembly of global displacements
    u(vl,1) = ul;
    u(vr,1) = ur;

    % Assembly of global reactions
    R(vl,1) = 0;
    R(vr,1) = Rr;

end