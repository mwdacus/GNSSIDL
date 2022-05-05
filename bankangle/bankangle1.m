%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement: Determine the bank angle from OpenSky ADS-B Positioning
%Data for multiple aircraft

%Imported Data:
%ADS-B position_data4 (or state_vectors_data4) file (assumed to processed)
%mintime (in unixtime)
%lat, lon, and alt
%velocity, heading and vertrate

%Output Data:
%bank angle, load factor and turning rate
%*************************************************************************

clear
clc
close all

%% Import ADS-B File 
%Import CSV File (Position)
[file_adsb,path_adsb] = uigetfile('*.csv');
filename_adsb=[path_adsb,file_adsb];
flightdata=readtable(filename_adsb);
%Import CSV File (SV4)
[file_vel,path_vel] = uigetfile('*.csv');
filename_vel=[path_vel,file_vel];
flightvel=readtable(filename_vel);

%% Data Conversion/Filtering
%Convert from LLA to ECEF Coordinates
ecef=lla2ecef([flightdata.lat,...
    flightdata.lon,flightdata.alt],'WGS84');
flightdata.x=ecef(:,1);
flightdata.y=ecef(:,2);
flightdata.z=ecef(:,3);

%Calculate flight path angle (from velocity, vertrate information)
flightvel.pitch=atand(flightvel.vertrate./flightvel.velocity);

%Smooth data over 10 second window for each aircraft 
flightdata.x=smoothdata(flightdata.x,'gaussian',10);
flightdata.y=smoothdata(flightdata.y,'gaussian',10);
flightdata.z=smoothdata(flightdata.z,'gaussian',10);
%Filter SV4 data

%% Main Script

aircraft=unique(flightdata.icao24);
[Delta,turning,phi,loadfac,omega]=deal(cell(1,length(aircraft)), ...
    cell(1,length(aircraft)),cell(1,length(aircraft)),cell(1,length(aircraft)), ...
    cell(1,length(aircraft)));
for i=1:length(aircraft)
    aircraft_pos=flightdata(strcmp(flightdata.icao24,aircraft{i}),:);
    aircraft_vel=flightvel(strcmp(flightvel.icao24,aircraft{i}),:);
    if isempty(aircraft_vel)==1
        continue
    end
    vel_ind=zeros(length(aircraft_pos.mintime),1);
    %Filter Velocities with position data (closest received time)
    for k=1:length(aircraft_pos.mintime)
        compare=abs(aircraft_pos.mintime(k)-aircraft_vel.time);
        b=find(compare==min(compare));
        vel_ind(k)=b(1);
    end
    aircraft_vel=aircraft_vel(vel_ind,:);

    Delta{i}=DataProcessAngle(aircraft_vel);
    Delta{i}=[0;Delta{i}];
    counter=1;
    delta_turn=diff(Delta{i});
    turning_ind=find((delta_turn>20 & delta_turn<30) | (delta_turn>-30 & delta_turn<-20));  
    for j=1:2:length(turning_ind)-1
        if length(turning_ind(j)+1:turning_ind(j+1))~=1
        turning{i}(counter)={turning_ind(j)+1:turning_ind(j+1)};
%         [phi{i}{counter},loadfac{i}{counter},omega{i}{counter}]=...
%             TurnEst(turning{i}{counter},aircraft_path);
        counter=counter+1;
        end        
    end
end

%Ask User if they want to plot turns
choice=menu('Do you want to plot the turns?',{'Yes','No'});
if choice==1
    PlotTurn(flightdata,aircraft,turning)
else
end

plotnic(flightdata)
    

%% Data Conversion/Manipulation
function [delta_ns]=DataProcessAngle(aircraftdata)
    %Determine when Aircraft undergoes banking using Turn Performance Estimation
    [row,~]=size(aircraftdata);
    delta=zeros(row-1,1);
    delta_ns=zeros(row-1,1);
    for i=1:row-1
        [delta_ns(i),delta(i)]=turnlocator(aircraftdata.heading(i), ...
            aircraftdata.heading(i+1),aircraftdata.time(i),aircraftdata.time(i+1));
    end
end

%% Turn Performance Estimation
function [phi,n,omega]=TurnEst(turn,flightdata)
    turndata=flightdata(turn,:);
    [phi,n,omega]=planefinder(turndata);
end

%% Function to Plot Turns
function PlotTurn(flightdata,aircraft,turning)
    g=figure('color','w');
    gx=geoaxes;
    for i=1:length(aircraft)
        aircraft_path=flightdata(strcmp(flightdata.icao24,aircraft{i}),:);
        for j=1:length(turning{i})
            geoplot(aircraft_path.lat(turning{i}{j}),aircraft_path.lon(turning{i}{j}), ...
                'go','MarkerSize',5,'MarkerFaceColor','g')
            hold on
        end
        geoplot(aircraft_path.lat,aircraft_path.lon,'b.','MarkerSize',0.5)
    end
    geobasemap('topographic')
    hold off
end
%% Function to plot by NIC value
function plotnic(flightdata)
    g=figure('color','w');
    gx=geoaxes;
    nic=unique(flightdata.nic);
    i=1;
    while nic(i)<=7
        nic_value=flightdata(flightdata.nic==nic(i),:);
        geoplot(nic_value.lat,nic_value.lon,'o','MarkerSize',0.5)
        hold on
        i=i+1;
    end
    geobasemap('topographic')
    legend(cellstr(num2str(nic)))
    hold off
end






