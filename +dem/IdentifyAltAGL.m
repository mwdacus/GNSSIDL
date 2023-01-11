function [outTrack, isEmpty] = IdentifyAltAGL(inTrack,p)
% Copyright 2018 - 2020, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Create output
outTrack = inTrack;
isEmpty = false;

%% Only check ocean if not all points are over land
isCheckOcean = ~any(cellfun(@(lat,lon)(all(InPolygon(outTrack.lat_deg, outTrack.lon_deg,lat,lon))),p.Results.Tland.Lat,p.Results.Tland.Lon,'UniformOutput',true));

%% Get terrain elevation
% In dted():
% If a directory name is supplied instead of a file name and LATLIM
% spans either 50 degrees North or 50 degrees South, an error results.
if contains(p.Results.dem,{'srtm','dted'}) && (min(outTrack.lat_deg) < -50 && max(outTrack.lat_deg) > -50) || (min(outTrack.lat_deg) < 50 && max(outTrack.lat_deg) > 50)
    warning('process:dted:latlimSpans50','DEMs in the DTED format will throw an error if the latitude limit spans either 50 degrees North or 50 degrees South, trying backup DEM\n');
    el_ft_msl = [];
else
    try
        [el_ft_msl,~,~,~] = msl2agl(outTrack.lat_deg, outTrack.lon_deg, p.Results.dem,'demDir',p.Results.demDir,...
            'maxMissingPercent',0.8,'isCheckOcean',isCheckOcean,'isFillAverage',true,'isVerbose',p.Results.isVerbose);
    catch err
        warning('process:msl2agl:error','Got error when calling ms2agl, trying backup DEM\n');
        el_ft_msl = [];
    end
end
if isempty(el_ft_msl)
    [el_ft_msl,~,~,~] = msl2agl(outTrack.lat_deg, outTrack.lon_deg, p.Results.demBackup,'demDir',p.Results.demDirBackup,...
        'maxMissingPercent',0.8,'isCheckOcean',isCheckOcean,'isFillAverage',true,'isVerbose',p.Results.isVerbose);
end
if isempty(el_ft_msl)
    isEmpty = true;
end

%% Convert from msl to agl
if ~isEmpty
outTrack.alt_baro_ft_agl = round(outTrack.alt_baro_ft_msl - el_ft_msl);
outTrack.alt_geo_ft_agl = round(outTrack.alt_geo_ft_msl - el_ft_msl);
outTrack.el_ft_msl = el_ft_msl;
end
