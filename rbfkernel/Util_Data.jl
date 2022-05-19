#Michael Dacus                                                    Stanford GPS Lab

#Function Description: 
    #Split incoming ADS-B Data into features (x) and labels (y)
    #split data into training and validation data
    #Plot Resulting 2D Topographical map of ADS-B Points along with Classifying Regions
#Input Information: 
    #Raw ADS-B Data (time, position, velocity, aircraft ICAO number and NIC value)
#Output Information: 
    #Data split in between features and labels
#----------------------------------------------------------------------------------
module DataProcess

using CSV
using DataFrames
using KernelFunctions
using Random
using Gtk
using Dates
using Plots

struct Data
    X::RowVecs{Float64, Matrix{Float64}, SubArray{Float64, 1, Matrix{Float64}, 
    Tuple{Int64, Base.Slice{Base.OneTo{Int64}}}, true}}         #Features
    Y::Vector{Float64}                                          #Labels
end


#Import Data
function FileUpload()
    filename=open_dialog("Upload ADS-B File")
    rawdata=DataFrame(CSV.File(filename))
    return filename,rawdata
end

#Reprocess DateTime from String to DateTime
function ReClock(data)
    data.mintime=DateTime.(data.mintime, "yyyy-mm-dd HH:MM:SS.sss")
    return data
end

#Create Validation Data Set
function CreateDataSet(data)
    A=[data.lat data.lon]
    B=data.nic
    ind2=findall(x->x>5,B)
    ind1=findall(x->3<=x<=5,B)
    ind0=findall(x->x<3,B)
    B[ind2].=2
    B[ind1].=1
    B[ind0].=0
    return Data(RowVecs(A),B)
end

#Split Data
function SplitData(rawdata)
    indnic=findall(x->x<=7,rawdata.nic)
    data_nic=rawdata[indnic,:]
    indalt=findall(x->x<10000,data_nic.alt)
    data_nic=data_nic[indalt,:]
    n=size(data_nic,1)
    shuffledata=data_nic[shuffle(1:end),:]
    splitind=Int(round(0.9*n))
    trainingdata=shuffledata[1:splitind,:]
    valdata=shuffledata[splitind+1:end,:]
    datat=CreateDataSet(trainingdata)
    datav=CreateDataSet(valdata)
    box=[minimum(trainingdata.lon),maximum(trainingdata.lon),minimum(trainingdata.lat),maximum(trainingdata.lat)]
    return datat,datav,box
end


#Plot Data
function PlotADSB(test_range_lat,test_range_lon,y_pred,origin_data,filename,time)
    ind2=findall(x->x==2,origin_data.Y)
    ind1=findall(x->x==1,origin_data.Y)
    ind0=findall(x->x==0,origin_data.Y)
    adsb_points=mapreduce(permutedims,vcat,[origin_data.X[i][:] for i in 1:size(origin_data.X,1)])
    scatter(adsb_points[ind0,2],adsb_points[ind0,1],color=:blue)
    scatter!(adsb_points[ind1,2],adsb_points[ind1,1],color=:red)
    scatter!(adsb_points[ind2,2],adsb_points[ind2,1],color=:green)
    contourf!(
	    test_range_lon,
	    test_range_lat,
	    y_pred;
	    levels=4,
	    color=cgrad([:blue,:red,:green]),
	    alpha=0.2,
	    colorbar_title="prediction",
	)
    #Save Figure
end



#Old Functions
#Function for map information 
function plotpoints(data)
    nic=data[2]
    loc=data[1]
    ind2=findall(x->x==2,nic)
    ind1=findall(x->x==1,nic)
    ind0=findall(x->x==0,nic)
    t1=scatter(; x=loc[ind0,2], y=loc[ind0,1], mode="markers",color=:red, name="NIC [0 3]")
    t2=scatter(; x=loc[ind1,2], y=loc[ind1,1], mode="markers",color=:blue, name="NIC [4 6]")
    t3=scatter(; x=loc[ind2,2], y=loc[ind2,1], mode="markers",color=:green, name="NIC (7 or higher)")
    plot([t1,t2,t3])

end
#Create Data Set
function CreateDataSet1(data)
    A=[data.lat data.lon]
    B=data.nic
    ind2=findall(x->x>5,B)
    ind1=findall(x->4<x<=7,B)
    ind0=findall(x->0<=x<4,B)
    #B[ind2].=2
    B[ind1].=1
    B[ind0].=0
    return (A,B)
end

end

#PlotlyJs script (still need to determine how to get )

    # t1=scatter(; x=adsb_points[ind0,2], y=adsb_points[ind0,1], mode="markers",color=:red, name="NIC [0 3]")
    # t2=scatter(; x=adsb_points[ind1,2], y=adsb_points[ind1,1], mode="markers",color=:blue,name="NIC [4 6]")
    # t3=scatter(; x=adsb_points[ind2,2], y=adsb_points[ind2,1], mode="markers",color=:green, name="NIC (7 or higher)")
    
    # trace=contour(x=test_range_lon,y=test_range_lat,z=y_pred,colorscale="Hot",contours_start=0,contours_end=1)

    # plot([t1,t2,t3,trace])