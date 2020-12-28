function plotWing(x,Tnod,u,uint)
% Inputs:
%  x     nodal coordinates matrix [Nnodes x Ndim]
%  Tnod  nodal connectivities matrix [Nelements x NnodesXelement]
%  le	 vector with element lengths [Nelements x 1]
%  u     global displacements/rotations vector [Ndofs x 1]
%  uint  matrix with element displacements and rotations in LOCAL axes [12 x Nelements] 
%        uint(1,e) : ux for node 1 of element e in local reference frame
%        uint(2,e) : uy for node 1 of element e in local reference frame
%        uint(3,e) : uz for node 1 of element e in local reference frame
%        uint(4,e) : angle_x for node 1 of element e in local reference frame
%        uint(5,e) : angle_y for node 1 of element e in local reference frame
%        uint(6,e) : angle_z for node 1 of element e in local reference frame
%        uint(7,e) : ux for node 2 of element e in local reference frame
%        uint(8,e) : uy for node 2 of element e in local reference frame
%        uint(9,e) : uz for node 2 of element e in local reference frame
%        uint(10,e): angle_x for node 2 of element e in local reference frame
%        uint(11,e): angle_y for node 2 of element e in local reference frame
%        uint(12,e): angle_z for node 2 of element e in local reference frame
%  n	 Axial force of element e in local reference frame [1 x Nelements]
%  qy	 Shear force in y-direction of element e in local reference frame [1 x Nelements]
%  qz	 Shear force in z-direction of element e in local reference frame [1 x Nelements]
%  t	 Torsion moment of element e in local reference frame [1 x Nelements]
%  my	 Bending moment in y-direction of element e in local reference frame [2 x Nelements]
%  mz	 Bending moment in z-direction of element e in local reference frame [2 x Nelements]

% Get dimensions
Ndim = size(x,2);
Nnodes = size(x,1);
Nelements = size(Tnod,1);
NnodesXelement = size(Tnod,2);
NdofsXnode = 2;

% X,Y data
X = reshape(x(Tnod',1),NnodesXelement,Nelements);
Y = reshape(x(Tnod',2),NnodesXelement,Nelements);

% Displacements
u = reshape(u,NdofsXnode,Nnodes);
Ux = reshape(u(1,Tnod'),NnodesXelement,Nelements);
Uy = reshape(u(2,Tnod'),NnodesXelement,Nelements);
D = sqrt(Ux.^2+Uy.^2);

% Initialize figure
figure('visible','off','color','w','Name','Wing','position',[50,50,565,540],'SizeChangedFcn',@resizeWindow);

% Create uicontrols
scale_lab = uicontrol('style','text','string','scale = ','position',[20,495,40,20],'backgroundcolor','w');
scale_edt = uicontrol('style','edit','string','1','position',[60,498,40,22],'callback',@scaleFactor);
show_lab = uicontrol('style','text','string','Show:','position',[120,495,40,20],'backgroundcolor','w');
show_pop = uicontrol('style','popupmenu','string',{'Displacements','Displacement X','Displacement Y','Displacement Z',...
    'Rotation X','Rotation Y','Rotation Z','Axial strain','Axial force','Shear force Y','Shear force Z',...
    'Torsion','Bending moment Y','Bending moment Z'},'position',[160,500,160,20],'callback',@showResults);
para_ax = axes('units','pixels','position',[20,20,400,450],'xcolor','none','ycolor','none','zcolor','none');

% Initial plot
sz = 2;
ori = [x(1,1),x(1,2)];
hold on;
plot(ori(1)+[0,sz],ori(2)+[0,0],'r','linewidth',1.5); text(ori(1)+1.1*sz,ori(2),'X','color','r');
plot(ori(1)+[0,0],ori(2)+[0,sz],'g','linewidth',1.5); text(ori(1),ori(2)+1.1*sz,'Y','color','g');
patch(X,Y,ones(size(X)),'edgecolor',[0.5,0.5,0.5],'linewidth',1);
p = patch(X+Ux,Y+Uy,D,'edgecolor','interp','linewidth',2);
view(30,25);
axis equal;
colormap jet; 
cbar = colorbar;
updateCase(D);
set(gcf,'visible','on');
set(gca,'xcolor','none','ycolor','none','zcolor','none');

function showResults(varargin)
    updateResults;
end

function resizeWindow(varargin)
    pos = get(gcf,'position');
    set(para_ax,'position',[20,20,pos(3)-165,pos(4)-90]);
    set(scale_lab,'position',[20,pos(4)-45,40,20]);
    set(scale_edt,'position',[60,pos(4)-42,40,22]);
    set(show_lab,'position',[120,pos(4)-45,40,20]);
    set(show_pop,'position',[160,pos(4)-40,160,20]);
end

function updateCase(var)
    set(p,'Cdata',var);
    caxis([min(var(:)),max(var(:))]);
    set(cbar,'Ticks',linspace(min(var(:)),max(var(:)),5));
    set(cbar,'visible','on');
end

function updateResults
    switch get(show_pop,'value')
        case 1
            updateCase(D);
    end
end

function scaleFactor(varargin)
    scale = str2double(get(scale_edt,'String'));
    set(p,'XData',X+scale*Ux,'YData',Y+scale*Uy);    
end

end