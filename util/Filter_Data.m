%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Filter Full ADS-B Data based on a variety of
%conditions:
    %remove data below 100 ft AGL (using geointerp)
    %only include commercial aircraft (part 121)

%*************************************************************************    

function [final_data]=Filter_Data(adsbdata,Z,RZ)
    %Filter data to remove data below 1000' AGL
    aglheight_m=1000/3.28;
    agl_h=geointerp(Z,RZ,adsbdata.lat,adsbdata.lon,"spline");
    agl_data=adsbdata(agl_h+aglheight_m<=adsbdata.alt,:);
    %remove data above 10000' MSL
    filtered_data=agl_data(agl_data.alt<=10000/3.28,:);
    %Filter data by commerical aircraft 
    filename_opensky="\aircraftDatabase_Opensky.csv";
    filename_mitre="\aircraftDatabase_MITRE.xlsx";
    registry_dir=fileparts(string(which('ADSBtools.util.loadAircraftDatabase')));
    aircraft_reg_mitre=readtable(strcat(registry_dir,filename_mitre));
    aircraft_reg_opensky=readtable(strcat(registry_dir,filename_opensky));
    %Gather tail numbers from opensky directory
    ac=unique(filtered_data.icao);
    ac_ind=ismember(aircraft_reg_opensky.icao24,lower(ac));
    tailno=aircraft_reg_opensky.registration(ac_ind);
    %remove empty cell entries
    tailno=tailno(~cellfun('isempty',tailno));
    %Find Part 121 Aircraft in Mitre Directory
    mitre_ind=ismember(aircraft_reg_mitre.Reg_,tailno);
    part121_ac=aircraft_reg_mitre.Reg_(mitre_ind);
    %Find part 121 aircraft (icao numbers) in opensky
    final_ind=ismember(aircraft_reg_opensky.registration,part121_ac);
    final_icao=aircraft_reg_opensky.icao24(final_ind);
    final_data=filtered_data(ismember(lower(filtered_data.icao),final_icao),:);
end
