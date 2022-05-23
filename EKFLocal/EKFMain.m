%% Code Information
%*************************************************************************
%AA 273                        EKFMain                       Michael Dacus

%Function Description: Implement EKF on nonholonomic mobile robot model

%Inputs:
    %Dynamics of the state model
    %Measurement Model
%Output:
    %EKF Estimated State, Compared to State
   

%**************************************************************************

clear
clc
close all

%% Data Import/Manipulation
[adsbfile_csv,adsbpath_csv] = uigetfile(...
    'C:\Users\mwdacus\OneDrive - Stanford\GPS\GNSS-Interference-Detect\data\*.csv');
[gpsfile_csv,gpspath_csv] = uigetfile(...
    'C:\Users\mwdacus\Documents\Data\GPS_Data\GPS Data Individual Flights\*.csv');
adsbdata=readtimetable([adsbpath_csv,adsbfile_csv]);
gpsdata=readtimetable([gpspath_csv,gpsfile_csv]);
adsbdata=sortrows(adsbdata,'mintime','ascend');
gpsdata=sortrows(gpsdata,'mintime','ascend');
%Filter GPS Data
starttime=adsbdata.mintime(1);
endtime=adsbdata.mintime(end);
[~,I_start]=min(abs(gpsdata.mintime-starttime));
[~,I_end]=min(abs(gpsdata.mintime-endtime));
gpsdata=gpsdata(I_start:I_end,:);
%Synchronize ADSB Time with GPS Times
adsbdata=synchronize(adsbdata(:,1:6),unique(gpsdata.mintime),'linear');


%% EKF Main Script
%Convert to ENU for EKF
origin=table2array(gpsdata(1,:));
ENU_data=lla2enu([adsbdata.lat,adsbdata.lon,adsbdata.alt], ...
    [origin(1),origin(2),origin(3)],"ellipsoid");

%Run EKF on Interpolation Data
reltime=seconds(adsbdata.mintime-adsbdata.mintime(1));
ekfstateenu=EKF_ADSB(ENU_data,origin,reltime);
%Convert Back to LLA:
ekfstatella=enu2lla([ekfstateenu(:,1),ekfstateenu(:,2),ekfstateenu(:,3)],[origin(1),origin(2),origin(3)],"ellipsoid");
ekfstatella=[ekfstatella ekfstateenu(:,4:6)];

trajplot(adsbdata,gpsdata,ekfstatella)
%% Plot Metrics

function trajplot(adsbdata,gpsdata,ekf)
    gx=geoaxes;
    geoplot(adsbdata.lat,adsbdata.lon,'o')
    hold on
    geoplot(gpsdata.lat,gpsdata.lon,'o')
    geoplot(ekf(:,1),ekf(:,2),'o')

end