%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Solve Convex Problem using Cone Fitting Formulations

%************************************************************************
clear
clc
close all

%% Input Parameters
angle=10;
height=30;
cent=[1,2,0];
%Gather simulated data
conesimdata=Util_Cone.ConeRandData(cent,angle,height);

%% Solve Convex problem
%Call Convex Formulation
gamma=1;
[A,r]=ConeCVX([conesimdata.x conesimdata.t],gamma);
%Define Boundaries
boxlat=[min(conesimdata.x(:,1)),max(conesimdata.x(:,1))];
boxlon=[min(conesimdata.x(:,2)),max(conesimdata.x(:,2))];
boxalt=[min(conesimdata.t),max(conesimdata.t)];

%% Plot Data
interval = [boxlon(1) boxlon(2) boxlat(1) boxlat(2) boxalt(1) boxalt(2)];
for i=1:length(gamma)
    f=@(x,y,z) norm(A*[x;y]+r(1:2),2)+r(3)-z;
    fimplicit3(f,interval)
    hold on
end

scatter3(conesimdata.x(:,1),conesimdata.x(:,2),conesimdata.t,'filled')


%old Julia calls
% %Start up Julia server, activate project
% jlcall('','project','C:\Users\Michael\OneDrive - Stanford\MATLAB\Github-GPS\GNSSIDL\ConeCVX',...
%     'modules',{'ConeCVX'},'restart',true,'threads',8)
% %Call Functions for random data
% data=jlcall('ConeCVX.ConeRandData',{cent,angle,height},'modules',{'ConeCVX'});
% %call Convex formulation
% params=jlcall('ConeCVX.main',{data,cvxoption,gamma},'modules',{'ConeCVX'});