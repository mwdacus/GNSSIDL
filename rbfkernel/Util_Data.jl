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

#Create Validation Data Set
function CreateDataSet(data)
    A=[data.lat data.lon data.alt]
    B=data.nic
    ind2=findall(x->x>=7,B)
    ind1=findall(x->3<=x<=6,B)
    ind0=findall(x->0<=x<=2,B)
    B[ind2].=2
    B[ind1].=1
    B[ind0].=0
    return Data(ColVecs(A),B)
end

#Split Data
function SplitData(rawdata)
    n=size(rawdata,1)
    shuffledata=rawdata[shuffle(1:end),:]
    splitind=Int(round(0.9*n))
    trainingdata=shuffledata[1:splitind,:]
    valdata=shuffledata[splitind+1:end,:]
    datat=CreateDataSet(trainingdata)
    datav=CreateDataSet(valdata)
    return datat,datav
end
#Comment: possibly remove some data points with nic value 9 or highter

#Plot Data
function PlotADSB()

end

end



