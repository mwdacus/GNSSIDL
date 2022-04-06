%% Code Information
%*************************************************************************
%Problem Statement: Find when an aircraft begins turning based on heading
%data and a scale metric

%Imported Data:
%ADS-B: flight data
%h_t: heading at time t
%h_next: heading at time t+1
%t: time at t
%t_next: time at t+1

%*************************************************************************

function [delta_ns,delta_n] = turnlocator(h_t,h_next,t,t_next)
    nx1=sind(h_next);
    nx2=sind(h_t);
    ny1=cosd(h_next);
    ny2=cosd(h_t);
    delta_n=((h_next-h_t)/abs(h_next-h_t))*(sqrt((nx1-nx2)^2+(ny1-ny2)^2)/(t_next-t));
      
    if delta_n>sind(1)
        delta_ns=20+delta_n;
    elseif delta_n<-sind(1)
        delta_ns=-20+delta_n;
    else
        delta_ns=0;
    end
end

