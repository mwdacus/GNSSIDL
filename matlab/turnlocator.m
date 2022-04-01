%% Code Information
%*************************************************************************
%Problem Statement: Find when an aircraft begins turning based on heading
%data and a scale metric

%Imported Data:
%ADS-B flight data
%*************************************************************************

function [delta_ns,delta_n] = turnlocator(h_t,h_next,t,t_next)
    nx1=sind(h_next);
    nx2=sind(h_t);
    ny1=cosd(h_next);
    ny2=cosd(h_t);
    delta_n=(h_t-h_next)/abs(h_t-h_next)*sqrt((ny2-ny1)^2+(nx2-ny1)^2)...
        /(t-t_last);
      
    if delta_n>sind(1)
        delta_ns=20+delta_n;
    elseif delta_n<-sind(1)
        delta_ns=-10+delta_n;
    else
        delta_ns=0;
    end
end

