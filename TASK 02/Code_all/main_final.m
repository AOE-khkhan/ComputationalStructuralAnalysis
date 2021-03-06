function main
    clear
    clc
    close all
    
    % 1 = case A, 2 = case B, 3 = case C, 
    % 4 = case D, 5 = case E, 6 = all cases
    case_load = 5;
    % true: (beams+plate) false: (only plates)
    bool_k = true; 
    
    % Load mesh data
    input_fuselage

    % Material properties
    rho1 =   2700; % kg/m3
    E1   = 68.9e9; % Pa
    nu1  =   0.33; % Poisson's ratio
    rho2 =   2810; % kg/m3
    E2   =   70e9; % Pa
    nu2  =   0.33; % Poisson's ratio

    % Atmosphere
    rhoa = 1.225; % Air Density [kg/m3]
    g =     9.81; % Gravity Acceleration [m/s2]

    % Case A : Structural Weight
    Ms = 22900; % Mass fuselage [kg]

    % Case B : Passenger Weight
    Mp = 13500; % Mass passengers [kg]

    % Case C : Wing loads
    Ff = [78.94e3 ; 72.22e3 ; -71.07e3];
    Fr = [17.18e3 ; -72.22e3 ; -25.47e3];
    Mf = [-349.08e3 ; 194.87e3 ; -86.29e3];
    Mr = [-203.02e3 ; 83.85e3 ; -91.93e3];

    % Case D : Loads nose and tail cone
    CD = 0.42;  % Drag coefficient
    V = 230;    % Velocity [m/s]
    S = 12.84;  % Cross section area [m2]
    L_tail = 164.01e3; % Lift tail [N]
    D_tail = 56.98e3;  % Drag tail [N]

    % Case E : Cabin pressure
    pin = 78191.21;  % Cabin pressure [Pa]
    pout = 22632.06; % Outside pressure [Pa]
    
    [n_beams, n_plates, n] = dimensions (Tbeams, Tplates, Tframe, Tstring, Treinf, Tskin, Tfloor, xnodes);
    n_beams.el = [Tframe' Tstring' Treinf'];    % Beam elements
    n_plates.el = [Tskin' Tfloor'];            % Plate elements

%% SECTION PARAMETERS
    n_elem = size(Tbeams,1);
    
    beams.le = zeros(n_elem,1); % Length of the element
    beams.m = zeros(n_elem,1); %mass of the element
    beams.V = zeros(n_elem,1); %volume of the element
    beams.A = zeros(n_elem,1); %area of the element
    
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
    [beams.m, beams.le, beams.V, beams.A] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Tframe, Tbeams, xnodes, rho1, Aa, beams.A);

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
    [beams.m, beams.le, beams.V, beams.A] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Tstring, Tbeams, xnodes, rho1, Ab, beams.A);

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
    [beams.m, beams.le, beams.V, beams.A] = beam_mass_length_calculus (beams.m, beams.le, beams.V, Treinf, Tbeams, xnodes, rho2, Ac, beams.A);

    % Beam properties
    mat_beams = [
    %  Density  Young   Poisson     A     Iy     Iz     J
          rho1,    E1,      nu1,   Aa,   Iya,   Iza,   Ja; % Frames (1)
          rho1,    E1,      nu1,   Ab,   Iyb,   Izb,   Jb; % Stringers (2)
          rho2,    E2,      nu2,   Ac,   Iyc,   Izc,   Jc; % Reinforcements (3)
    ];

    % Stiffness matrix computation

    [R_beams, K_beams] = beam_elements(n_beams, beams.le, Tmat_beams, mat_beams, dat_beams);

%% PLATES

    % Plates thickness
    hs = 4e-3; hf = 8e-3;

    % Plate properties
    mat_plates = [
    %  Density  Young   Poisson     h
          rho2,    E2,      nu2,   hs; % Skin (1)
          rho2,    E2,      nu2,   hf; % Floor (2)
    ];

    [plates.m, plates.a, plates.b, plates.V, plates.h] = plates_mass_length_calculus(Tplates, xnodes, mat_plates, Tmat_plates);
    
    % Stiffness matrix computation
    
    [R_plates, K_plates] = plate_elements(n_plates, Tmat_plates, mat_plates, dat_plates, plates.a, plates.b);

%% RHO EFFECTIVE AND TOTAL MASS

    [beams, plates] = rho_mass_calculus (beams, plates, n_beams, n_plates, Tmat_beams, Tmat_plates, mat_beams, mat_plates, Ms);
    
%% Join Beams and Plates Matrix:
    
    n_beams.T2 = calculate_T2 (n_beams, Tbeams, 'beams');
    n_plates.T2 = calculate_T2 (n_plates, Tplates, 'plates');
    
    KG = sparse(n_beams.n_dof,n_beams.n_dof);
    
    if bool_k == true
        for e = n_beams.el
            i = n_beams.T2(:,e);
            I = repmat(i,size(n_beams.T2,1),1);
            J = repelem(i,size( n_beams.T2,1),1);
            KG = KG + sparse(I,J,K_beams(:,:,e),n_beams.n_dof,n_beams.n_dof);
        end
    end
    
    % Plates
    for e = n_plates.el 
        i = n_plates.T2(:,e);
        I = repmat(i,size(n_plates.T2,1),1);
        J = repelem(i,size( n_plates.T2,1),1);
        KG = KG + sparse(I,J,K_plates(:,:,e),n_plates.n_dof,n_plates.n_dof);
    end

%% Prescribed degrees of freedom
   [vr, vl] = fixed_dof (case_load, n, Tsym, xnodes);
    
   F = zeros(n.n_dof, 1);
%% A) Structural weight
    if case_load == 1 || case_load == 6
        F1 = load_A (beams, n_beams, plates,n_plates, R_beams, R_plates, g);
        F = F + F1;
    end

%% B) Weight of the cabin passengers
    if case_load == 2 || case_load == 6
        F2 = load_B (Tfloor, plates, R_plates, g, Mp, n_plates);
        F = F + F2;
    end

%% C) Loads transmitted by the wing
    if case_load == 3 || case_load == 6
        F3 = load_C (xnodes, Tfront, Trear, beams, R_beams, n_beams, Fr, Ff, Mr, Mf);
        F = F + F3;
    end

%% D) Loads transmitted by the nose and the tail cone
    if case_load == 4 || case_load == 6
        F4 = load_D (n_beams, beams, Tnose, Ttail, R_beams, rhoa, V, S, CD, n, Tsym, xnodes, D_tail, L_tail);
        F = F + F4;
    end

%% E) Cabin pressure
    if case_load == 5 || case_load == 6
        F5 = load_E(n_plates, plates, R_plates, n_beams, beams, R_beams, dat_plates, Tskin, Tnose, Ttail, pin, pout, S);
        F = F + F5;
    end
    
    [u,R] = solver (vr, vl, KG, F, n.n_dof);
    
    [uint_beams, uint_plates] = local_displacements (n_beams, n_plates, R_beams, R_plates, u);
    [N,Qy,Qz,T,My,Mz] = beam_forces (n_beams, u, R_beams, K_beams);
%% Postprocess

plotFuselage(xnodes,Tbeams,Tplates,Tmat_beams,Tmat_plates,u,uint_beams,N,Qy,Qz,T,My,Mz,uint_plates,mat_plates)

finish=true;

end




function C = inner_join (A, B) 
    p = 1;
    for i = 1:length(A)
        for j = 1:length(B)
            if A(i) == B(j)
                C(p)=A(i);
                p = p+1;
            end
        end
    end
end


function [vr, vl] = fixed_dof (case_load, n, Tsym, xnodes)
    %Obtain the prescribed degrees of freedom vector by applying the symmetry condition on all nodes lying on the XZ-plane (list of nodes provided in Tsym). 
    % Hint: To apply symmetry conditions with respect to XZ-plane, one must prescribe the displacement in y-direction and the rotations around x and z-axes. 
    % Additionally, the displacement in x and z-directions of some node will need to be prescribed in order to avoid rigid body modes.

    mid_x = (min(xnodes(:,1)) + max(xnodes(:,1))) / 2;
    mid_x_nodes = find(round(xnodes(:,1)) == round(mid_x));
    mid_y = (min(xnodes(:,2)) + max(xnodes(:,2))) / 2;
    mid_y_nodes = find(round(xnodes(:,2)) == round(mid_y));
    mid_z = (min(xnodes(:,3)) + max(xnodes(:,3))) / 2;
    mid_z_nodes = find(round(xnodes(:,3)) == round(mid_z));
    
    min_x_nodes = find(xnodes(:,1) == min(xnodes(:,1)));
    max_x_nodes = find(xnodes(:,1) == max(xnodes(:,1)));
    min_y_nodes = find(xnodes(:,2) == min(xnodes(:,2)));
    max_y_nodes = find(xnodes(:,2) == max(xnodes(:,2)));
    min_z_nodes = find(xnodes(:,3) == min(xnodes(:,3)));
    max_z_nodes = find(xnodes(:,3) == max(xnodes(:,3)));
    
    switch case_load
        case 1  % front and rear (low)
            max_x_min_z_nodes = inner_join (max_x_nodes, min_z_nodes);
            selected(1) = max_x_min_z_nodes(1);
            
            min_x_min_z_nodes = inner_join (min_x_nodes, min_z_nodes);
            selected(2) = min_x_min_z_nodes(1);
            
            vr = [(selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ...
                (selected(2)-1)*n.n_deg+1 (selected(2)-1)*n.n_deg+3]; 
            
        case 2 
            max_x_midz_nodes = inner_join (max_x_nodes, mid_z_nodes);
            selected(1) = max_x_midz_nodes(length(max_x_midz_nodes));
            
            min_x_midz_nodes = inner_join (min_x_nodes, mid_z_nodes);
            selected(2) = min_x_midz_nodes(length(min_x_midz_nodes));
            
            vr = [(selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ...
                (selected(2)-1)*n.n_deg+1 (selected(2)-1)*n.n_deg+3]; 
            %x = (y-1)*6 + 1
            
        case 3 % front and rear (low)
            max_x_min_z_nodes = inner_join (max_x_nodes, min_z_nodes);
            selected(1) = max_x_min_z_nodes(1);
            
            min_x_min_z_nodes = inner_join (min_x_nodes, min_z_nodes);
            selected(2) = min_x_min_z_nodes(1);
            
            vr = [(selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ...
                (selected(2)-1)*n.n_deg+1 (selected(2)-1)*n.n_deg+3]; 
            
        case 4
            max_x_min_z_nodes = inner_join (max_x_nodes, min_z_nodes);
            selected(1) = max_x_min_z_nodes(1);
            
            min_x_min_z_nodes = inner_join (min_x_nodes, min_z_nodes);
            selected(2) = min_x_min_z_nodes(1);
            
            vr = [(selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ...
                (selected(2)-1)*n.n_deg+1 (selected(2)-1)*n.n_deg+3]; 
            
        case 5
            % x: middle, y: middle and z: middle
            mid_xz_nodes = inner_join (mid_x_nodes, mid_z_nodes); 
            
            % We select the first one
            selected(1) = mid_xz_nodes(1);
            vr = [ (selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ];

        case 6 % front and rear (low)
            max_x_min_z_nodes = inner_join (max_x_nodes, min_z_nodes);
            selected(1) = max_x_min_z_nodes(1);
            
            min_x_min_z_nodes = inner_join (min_x_nodes, min_z_nodes);
            selected(2) = min_x_min_z_nodes(1);
            
            vr = [(selected(1)-1)*n.n_deg+1 (selected(1)-1)*n.n_deg+3 ...
                (selected(2)-1)*n.n_deg+1 (selected(2)-1)*n.n_deg+3]; 
    end
    
    for i = 1:length(Tsym)
        e = Tsym(i);
        % Displacement y-dir
        v1 = n.n_deg * (e-1) + 2;
        % Rotation x-dir
        v2 = n.n_deg * (e-1) + 4;
        % Rot y_dir
        v3 = n.n_deg * (e-1) + 6;             
    
        vr = [vr [v1 v2 v3]];
    
    end

    vl = setdiff(1:n.n_dof,vr); 

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


function [N,Qy,Qz,Tor,My,Mz] = beam_forces (n_beams, u, R_beams, K_beams)

    N = zeros (1,n_beams.n_elem);
    Qy = zeros (1,n_beams.n_elem);
    Qz = zeros (1,n_beams.n_elem);
    Tor = zeros (1,n_beams.n_elem);
    My = zeros (2,n_beams.n_elem);
    Mz = zeros (2,n_beams.n_elem);

    for i = 1:length(n_beams.el)
        e = n_beams.el(i);   
        for r = 1 : n_beams.n_nel * n_beams.n_deg
            p = n_beams.T2(r,e);
            disp(r,1) = u(p,1);
        end
        f_int = R_beams (:,:,e) * K_beams (:,:,e) * disp; 

        %Axial force x
        N(e) = f_int (7);
        %Shear force y
        Qy(e) = f_int (8);
        %Shear force z
        Qz(e) = f_int (9);
        %Torsion moment x
        Tor(e) = f_int (10);
        %Bending moment y
        My(1,e) = -f_int (5);
        My(2,e) = f_int (11);
        %Bending moment z
        Mz(1,e) = -f_int (6);
        Mz(2,e) = f_int (12);
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


function [fe] = plate_force (e, plates, R_plates, pe, n_plates)

fe_p = zeros(2* n_plates.n_nel * n_plates.dim, 1);

R = R_plates (1:3,1:3,e);
       
pe_p = R * pe;

a = plates.a(e);
b = plates.b(e);

fe_p ([1,2,7,8,13,14,19,20]) = (pe_p (1) * a * b) ...
                                * [1 ; 0 ; 1 ; 0 ; 1 ; 0 ; 1 ; 0] + ...
                                (pe_p (2) * a * b) ...
                                * [ 0 ; 1 ; 0 ; 1 ; 0 ; 1 ; 0 ; 1];

fe_p ([3,4,5,9,10,11,15,16,17,21,22,23]) = (a * b * pe_p(3)) ...
     * [1 ; b/3 ; a/3 ; 1 ; -b/3 ; a/3 ; 1 ; -b/3 ; -a/3 ; 1 ; b/3 ; -a/3]; 

fe = R_plates(:,:,e)' * fe_p;

end


function [uint_beams,uint_plates] = local_displacements (n_beams, n_plates, R_beams, R_plates, u)

uint_beams = zeros ( n_beams.n_deg * n_beams.n_nel ,  n_beams.n_elem);
uint_plates = zeros ( n_beams.n_deg * n_plates.n_nel ,  n_plates.n_elem );

%% BEAMS
for i = 1 : length(n_beams.el)
    e = n_beams.el(i);
    for r = 1 : n_beams.n_nel * n_beams.n_deg
        p = n_beams.T2(r,e);
        d(r,1) = u(p,1);
    end
    uint_beams (:,e) = R_beams (:,:,e) * d;  
end

%% PLATES
for i = 1 : length(n_plates.el)
    e = n_plates.el(i);
    for r = 1 : n_plates.n_nel * n_plates.n_deg
        p = n_plates.T2(r,e);
        d(r,1) = u(p,1);
    end
    uint_plates (:,e) = R_plates (:,:,e) * d;
end

end


function [n_beams, n_plates, n] = dimensions (Tbeams, Tplates, Tframe, Tstring, Treinf, Tskin, Tfloor, xnodes)

%% PREPROCESS
    n_beams.n_deg = 6; % Degrees of freedom per node
    n_beams.n_elem = size(Tbeams,1); % Number of elements
    n_beams.n_nel = size(Tbeams,2); % Number of nodes in a beam
    n_beams.n_nod = size(xnodes,1); %Total number of nodes
    n_beams.n_dof = n_beams.n_nod*n_beams.n_deg; %Total number of degrees of freedom
    n_beams.elements = [Tframe' Tstring' Treinf'];
    n_beams.dim = size(xnodes,2);
    
    n_plates.n_deg = 6; % Degrees of freedom per node
    n_plates.n_elem = size(Tplates,1); % Number of elements
    n_plates.n_nel = size(Tplates,2); % Number of nodes in a plate
    n_plates.n_nod = size(xnodes,1); %Total number of nodes
    n_plates.n_dof = n_beams.n_nod*n_beams.n_deg; %Total number of degrees of freedom
    n_plates.elements = [Tskin' Tfloor'];
    n_plates.dim = size(xnodes,2);
    
    n.n_deg = 6; % Degrees of freedom per node
    n.n_elem = size(Tbeams,1) + size(Tplates,1); % Number of elements
    n.n_nod = size(xnodes,1); %Total numbre of nodes
    n.n_dof = n.n_nod*n.n_deg; %Total number of degrees of freedom
end


function [m, le, V, A2] = beam_mass_length_calculus (m, le, V, T, Tbeams, xnodes, rho, A, A2)
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
        A2(e) = A;

        % Mass beam
        m(e) = V(e) .* rho;
        
        

    end
end


function [m, a, b, V, h] = plates_mass_length_calculus(Tplates, xnodes, mat_plates, Tmat_plates)
    
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
        h(e) = mat_plates(Tmat_plates(e),4);
        rho = mat_plates(Tmat_plates(e),1);

        V(e) = 4 * a(e) * b(e) * h(e);

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


function f = load_A (beams, n_beams,plates, n_plates, R_beams, R_plates, g)

fwb = zeros (n_beams.n_nel*n_beams.n_deg, length(n_beams.elements));
fwp = zeros (n_plates.n_nel*n_plates.n_deg, length(n_plates.elements));

% 1. Element force vector : Weight beams
for e = n_beams.elements
    wb = g * beams.rho_eff(e) * beams.A(e);
    wbeam = [0 ; 0 ; -wb];
    fwb (:,e) = beam_force (e, beams.le, n_beams, R_beams, wbeam);
end


% 2. Element force vector : Weight plates
for e = n_plates.elements
    wp = g * plates.h(e) * plates.rho_eff(e);
    wplate = [0 ; 0 ; -wp];
    fwp (:,e) = plate_force(e, plates, R_plates, wplate, n_plates);
end


% 3. Global force vector : Structural weight

f = zeros(n_beams.n_dof,1);
for e = n_beams.elements
    i = n_beams.T2(:,e);
    f(i) = f(i) + fwb(:,e);
end

for e = n_plates.elements
    i = n_plates.T2(:,e);
    f(i) = f(i) + fwp(:,e);
end


end


function f = load_B (Tfloor, plates, R_plates, g, Mp, n_plates)

    fw_pass = zeros (n_plates.n_nel * n_plates.n_deg, length(Tfloor));

    % 1. Floor surface
    S_f = 0;
    for e = Tfloor'
        S_f = S_f + 4 * plates.a(e) * plates.b(e) ;
    end
    S_f = 2 * S_f;


    % 2. Weight passengers
    w_pass_e = ( Mp / S_f ) * g;


    % 3. Element force vector : Weight passengers
    for e = Tfloor'
        w_pass = [0 ; 0 ; -w_pass_e];
        fw_pass (:,e) = plate_force (e, plates, R_plates, w_pass, n_plates);
    end


    % 3. Global force vector : Structural weight

    f = zeros(n_plates.n_dof,1);
    for e = Tfloor'
        i = n_plates.T2(:,e);
        f(i) = f(i) + fw_pass(:,e);
    end

end


function f = load_C (xnodes, Tfront, Trear, beams, R_beams, n_beams, Fr, Ff, Mr, Mf)


f_front = zeros (2 * n_beams.n_nel * n_beams.dim,length(Tfront));
f_rear = zeros (2 * n_beams.n_nel * n_beams.dim,length(Trear));

l_front = sum(beams.le(Tfront));
l_rear = sum(beams.le(Trear));

q_front = - Ff / l_front;
q_rear = - Fr / l_rear;


% Element force vector : Distributed Load Wing
for e = Tfront'
    f_front (:,e) = beam_force (e, beams.le, n_beams, R_beams, q_front);
end
for e = Trear'
    f_rear (:,e) = beam_force (e, beams.le, n_beams, R_beams, q_rear);
end


% Global force vector : Distributed Load Wing

f = zeros(n_beams.n_dof,1);
for e = Tfront'
    i = n_beams.T2(:,e);
    f(i) = f(i) + f_front(:,e);
end
for e = Trear'
    i = n_beams.T2(:,e);
    f(i) = f(i) + f_rear(:,e);
end


% Point wing loads: moments
H = xnodes(1323,3) - xnodes(1340,3);
L = xnodes(1043,1) - xnodes(1328,1);
W = xnodes(1323,2) - xnodes(1340,2);

Meqz = - ( Mf(3) + Mr(3) ) - ( Mf(2) + Mr(2) ) * (W/H);
Fr1 = - Mr(1) / H;        Ff1 = - Mf(1) / H;
Fr2 = - Mr(2) / H;        Ff2 = - Mf(2) / H; 
Fr3 = Meqz / L;           Ff3 = Fr3;

% Node 1035
f (6205) = Fr2;   f (6206) = - Fr1;
% Node 1058
f (6343) = - Fr2;   f (6344) = Fr1;
% Node 1043
f (6254) = Fr3;
% Node 1323
f (7933) = Ff2;   f (7934) = - Ff1;
% Node 1340
f (8035) = - Ff2;   f (8036) = Ff1;
% Node 1328
f (7964) = - Ff3;


end


function F = load_D ( ...
    n_beams, beams, Tnose, Ttail, R_beams, rhoa, V, S, CD, n, Tsym, xnodes, D_tail, L_tail)

    F_nose = zeros( n_beams.n_nel * n_beams.n_deg, length(Tnose));
    F_tail = zeros( n_beams.n_nel * n_beams.n_deg, length(Ttail));

    l_nose = 2 * sum(beams.le(Tnose));
    D_nose = 0.5 * rhoa * V * V * S * CD;
    q_nose = [ D_nose/l_nose ; 0 ; 0 ];

    % Drag nose 
    for i = 1:length(Tnose)
        e = Tnose(i);
        F_nose (:,e) = beam_force (e, beams.le, n_beams, R_beams, q_nose);
    end

    % Drag + Lift tail : Distributed force + Element force vector
    l_tail = 2 * sum(beams.le(Ttail));
    q_tail = [ D_tail/l_tail ; 0 ; L_tail/l_tail ];
    for i = 1:length(Ttail)
        e = Ttail(i);
        F_tail (:,e) = beam_force(e, beams.le, n_beams, R_beams, q_tail);
    end

    % Global force 
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
    
end


function F = load_E ( ...
    n_plates, plates, R_plates, n_beams, beams, R_beams, dat_plates, Tskin, Tnose, Ttail, pin, pout, S)

    F_pressure = zeros(n_plates.n_nel*n_plates.n_deg, length(Tskin));
    F_nose = zeros(n_beams.n_nel*n_beams.n_deg, length(Tnose));
    F_tail = zeros(n_beams.n_nel*n_beams.n_deg, length(Ttail));
    
    
    for i = 1:length(Tskin)
       e = Tskin(i); 
       alpha = dat_plates (e,1);
       beta = dat_plates (e,2);
       gamma = dat_plates (e,3);

       sa = sin(alpha);   sb = sin(beta);   sg = sin(gamma);
       ca = cos(alpha);   cb = cos(beta);   cg = cos(gamma);

       n_e = [ -ca*sb*cg+sa*sg ; -ca*sb*sg-sa*cg ; ca*cb ];

       p_skin = (pin-pout) * n_e;
        
       F_pressure (:,e) = plate_force(e, plates, R_plates, p_skin, n_plates);
       
    end
    
    % Nose Pressure nose
    l_nose = 2 * sum(beams.le(Tnose));
    for i = 1:length(Tnose) 
       e = Tnose(i);
       p_nose = [ -(pin-pout)*(S/l_nose); 0; 0];
       F_nose (:,e) = beam_force(e, beams.le, n_beams, R_beams, p_nose);
    end

    % Tail Pressure 
    l_tail = 2 * sum(beams.le(Ttail));
    for i = 1:length(Ttail) 
       e = Ttail(i);
       p_tail = [ (pin-pout)*(S/l_tail); 0; 0];
       F_tail (:,e) = beam_force(e, beams.le, n_beams, R_beams, p_tail); 
    end
    
    % Global force 
    F = zeros(n_beams.n_dof,1);
    for j = 1:length(Tskin)
        e = Tskin(j);
        i = n_plates.T2(:,e)';
        F(i) = F(i) + F_pressure(:,e);
    end
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
    
end