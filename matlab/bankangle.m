%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement: Determine the bank angle from OpenSky ADS-B Positioning Data for one aircraft 

%Imported Data:
%ADS-B position_data4 (or state_vectors_data4) file (assumed to processed)
%mintime (in unixtime)
%lat
%lon
%alt
%heading
%velocity

%Output Data:
%bank angle
%*************************************************************************

clear
clc
close all

%% Import ADS-B File 
%Import CSV File
[file_adsb,path_adsb] = uigetfile('*.csv');
filename_adsb=[path_adsb,file_adsb];
filename_adsb=string(filename_adsb);
flightdata=readtable(filename_adsb);

%% Data Conversion
%Determine when Aircraft undergoes banking using Turn Performance
%Estimation
[row,col]=size(flightdata);
for i=1:row-1
    [delta(i),delta_ns(i)]=turnlocator(flightdata.heading(i), ...
        flightdata.heading(i+1),flightdata.mintime(i),flightdata.mintime(i+1));
end
%Convert from LLA to ECEF Coordinates
[flightdata.x,flightdata.y,flightdata.z]=lla2ecef([flightdata.lat,...
    flightdata.lon,flightdata.alt],'WGS84');

%% Turn Performance Estimation
turning_ind=find(delta_ns>10 & delta_ns<-10);
%find number of turns made and when






