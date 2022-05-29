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

%Select Start and End ADSB Data 
startind=find(adsbdata.mintime=='2019-09-17 06:57:58.871');
endind=find(adsbdata.mintime=='2019-09-17 06:59:59.804');
adsbdata=adsbdata(startind:endind,:);

%% Aircraft Segment Split EKF run
reltime=seconds(adsbdata.mintime-adsbdata.mintime(1));
delta_t=diff(reltime);

gapsind={1 find((delta_t>4)) find((delta_t>4))+1 length(reltime)};
gapsind=vertcat(gapsind{:});
gapsind=sort(gapsind,'ascend');
adsbsync=cell(1,length(gapsind)/2);
counter=1;
for i=1:2:length(gapsind)
    gaptime=adsbdata.mintime(gapsind(i):gapsind(i+1));
    adsbseg=adsbdata(gapsind(i):gapsind(i+1),:);
    [~,ind1]=min(abs(adsbdata.mintime(gapsind(i))-gpsdata.mintime));
    [~,ind2]=min(abs(adsbdata.mintime(gapsind(i+1))-gpsdata.mintime));
    adsbsync{counter}=synchronize(adsbseg(:,1:7),gpsdata.mintime(ind1:ind2),...
        'linear');
    counter=counter+1;
end
adsbdata=vertcat(adsbsync{:});

%Filter GPS Data
starttime=adsbdata.mintime(1);
endtime=adsbdata.mintime(end);
[~,I_start]=min(abs(gpsdata.mintime-starttime));
[~,I_end]=min(abs(gpsdata.mintime-endtime));
gpsdata=gpsdata(I_start:I_end,:);

%trajplot(adsbdata,gpsdata)
%% EKF Main Script
%Convert to ENU for EKF
origin=table2array(gpsdata(1,:));
ENU_data_ADSB=[lla2enu([adsbdata.lat,adsbdata.lon,adsbdata.alt], ...
    [origin(1),origin(2),origin(3)],"ellipsoid"), adsbdata.velocity, ...
    adsbdata.heading, adsbdata.vertrate, adsbdata.nic];
ENU_data_GPS=[lla2enu([gpsdata.lat,gpsdata.lon,gpsdata.alt],...
    [origin(1),origin(2),origin(3)],"ellipsoid") gpsdata.velocity,...
    gpsdata.heading gpsdata.vertrate];


choice=menu('Do you want to calculate using ADSB, ADSB with GPS Control?', ...
    {'ADSB Only','ADSB with GPS Input'});
if choice==1
    ekfstateenu=EKF_ADSB(ENU_data_ADSB,ENU_data_GPS,reltime);
else
    ekfstateenu=EKF_ADSB_GPS(ENU_data_ADSB,ENU_data_GPS,reltime);
end
%Convert Back to LLA:
ekfstatella=enu2lla([ekfstateenu(:,1),ekfstateenu(:,2),ekfstateenu(:,3)],...
    [origin(1),origin(2),origin(3)],"ellipsoid");

trajplot(adsbdata,gpsdata,ekfstatella)
altplot(adsbdata.mintime,adsbdata,gpsdata,ekfstatella)
errorplot(adsbdata.mintime,ENU_data_GPS(:,1:3),ekfstateenu(:,1:3))
%% Plot Metrics
% Plot 2D Trajectory
function trajplot(adsbdata,gpsdata,ekf)
    gx=geoaxes;
    geoplot(adsbdata.lat,adsbdata.lon,'og','MarkerSize',4)
    hold on
    geoplot(gpsdata.lat,gpsdata.lon,'or','MarkerSize',4)
    
    geoplot(ekf(:,1),ekf(:,2),'ob','MarkerSize',4)
    legend('ADSB','GPS','EKF')
    geobasemap('topographic')
    hold off
end
%Plot Altitude v. Time
function altplot(time,adsbdata,gpsdata,ekf)
    figure('color','w')
    plot(time,adsbdata.alt,'og','MarkerSize',4)
    hold on
    plot(time,gpsdata.alt,'or','MarkerSize',4)
    plot(time,ekf(:,3),'ob','MarkerSize',4)
    grid on
    legend('ADSB','GPS','EKF')
    xlabel('Time (UTC)')
    ylabel('Altitude (MSL) [m]')
end


function errorplot(time,ENU_gps,ENU_ekf)
    figure('color','w')
    err_ENU=ENU_ekf-ENU_gps;
    plot(time,err_ENU(:,1))
    hold on
    plot(time,err_ENU(:,2))
    plot(time,err_ENU(:,3))
    legend('East-West Error','North-South Error','Altitude Error')
    xlabel('Time (UTC)')
    ylabel('Distance Error [m]')
    grid on
end