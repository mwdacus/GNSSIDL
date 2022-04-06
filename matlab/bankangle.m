%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement: Determine the bank angle from OpenSky ADS-B Positioning
%Data for one aircraft

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

%% Import ADS-B File 
%Import CSV File
[file_adsb,path_adsb] = uigetfile('*.csv');
filename_adsb=[path_adsb,file_adsb];
filename_adsb=string(filename_adsb);
flightdata=readtable(filename_adsb);

%Convert from LLA to ECEF Coordinates
ecef=lla2ecef([flightdata.lat,...
    flightdata.lon,flightdata.baroaltitude],'WGS84');
flightdata.x=ecef(:,1);
flightdata.y=ecef(:,2);
flightdata.z=ecef(:,3);
%Convert cell to string array
flightdata.icao24=string(flightdata.icao24);
%Calculate flight path angle (from velocity, vertrate information)
flightdata.pitch=atand(flightdata.vertrate./flightdata.velocity);

%% Main Script

aircraft=unique(flightdata.icao24);
[Delta,turning,phi,loadfac,omega]=deal(cell(1,length(aircraft)), ...
    cell(1,length(aircraft)),cell(1,length(aircraft)),cell(1,length(aircraft)), ...
    cell(1,length(aircraft)));
for i=1:length(aircraft)
    aircraft_path=flightdata(flightdata.icao24==aircraft(i),:);
    Delta{i}=DataProcessAngle(aircraft_path);
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
        aircraft_path=flightdata(flightdata.icao24==aircraft(i),:);
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






