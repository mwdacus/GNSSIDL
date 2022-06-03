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
using Geodesy

struct Data
    X::Matrix{Float64}        #Features
    Y::Vector{Float64}                                          #Labels
end

struct FlightBox
    X::Vector{Float64}
    Y::Vector{Float64}
    ALT::Vector{Float64}
end

#Import Data
function FileUpload()
    filename=open_dialog("Upload ADS-B Files",select_multiple=true)
    rawdata=DataFrame(CSV.File(filename))
    return filename,rawdata
end

#Convert to enu DataFrame
function ENUConvert(table::DataFrame)
    nsamples=size(table,1)
    points_LLA=[LLA(table.lat[i],table.lon[i],table.alt[i]) for i in 1:nsamples]
    origin=LLA(39.861667,-104.6731667,1656.2)
    trans=ENUfromLLA(origin,wgs84)
    new_points=map(trans,points_LLA)
    enudata=[[new_points[i][1], new_points[i][2], new_points[i][3]] for i in 
        1:length(new_points)]
    finalenu=reshape(mapreduce(permutedims,vcat,enudata),(length(new_points),3))
    return finalenu
end

#Convert to LLA DataFrame
function LLAConvert(data::Matrix)
    nsamples=size(data,2)
    enudata=[[ENU(data[1,i],data[2,i],data[3,i])] for i in 1:nsamples]
    origin=LLA(39.861667,-104.6731667,1656.2)
    trans=LLAfromENU(origin,wgs84)
    lladata=[[map(trans,enudata[i])[1].lat, map(trans,enudata[i])[1].lon,
        map(trans,enudata[i])[1].alt] for i in 1:nsamples]
    finallla=reshape(mapreduce(permutedims,vcat,lladata),(nsamples,3))
    return transpose(finallla)
end

#Reprocess DateTime from String to DateTime
function ReClock(data)
    data.mintime=DateTime.(data.mintime, "yyyy-mm-dd HH:MM:SS.sss")
    return data
end

#Create Validation Data Set
function CreateDataSet(data)
    A=[data.x data.y data.z]
    B=data.nic
    ind2=findall(x->x>=5,B)
    ind1=findall(x->2<=x<=4,B)
    ind0=findall(x->x<=1,B)
    B[ind2].=0
    B[ind1].=1
    B[ind0].=2
    return Data(transpose(A),B)
end

#Split Data
function SplitData(rawdata)
    indnic=findall(x->x<=6,rawdata.nic)
    data_nic=rawdata[indnic,:]
    indalt=findall(x->x<5000,data_nic.alt)
    data_nic=data_nic[indalt,:]
    n=size(data_nic,1)
    trainind=Int.(round.(collect(range(1,n,length=500))))
    a=collect(1:n) .∈ [trainind]
    valind=findall(x->x==0,a)
    trainingdata=data_nic[trainind,:]
    valdata=data_nic[valind,:]
    kdatat=CreateDataSet(trainingdata)
    kdatav=CreateDataSet(valdata)
    box=FlightBox(
        [minimum(data_nic.x),maximum(data_nic.x)],
        [minimum(data_nic.y),maximum(data_nic.y)],
        [minimum(data_nic.z),maximum(data_nic.z)])
    return kdatat,kdatav,box
end

#Convert Data from RowVecs{} to Matrix
function RowVec2Matrix(data)
    matform=mapreduce(permutedims,vcat,[data.X[i][:] for i in 1:size(data.X,1)])
    return matform
end

end