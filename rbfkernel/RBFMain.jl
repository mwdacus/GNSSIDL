#Michael Dacus                                                    Stanford GPS Lab

#Function Description: 
    #Implment an RBF Kernel Function on ADS-B Data to Determine and localize GNSS Interference Source
#Input Information: 
    #Raw ADS-B Data (time, position, velocity, aircraft ICAO number and NIC value)
#Output Information: 
    #Resulting Plot of Interference Region based on Kernel Function
#----------------------------------------------------------------------------------


using CSV
using DataFrames
using LinearAlgebra
using KernelFunctions
using LIBSVM
using Dates
using Statistics
using Main.DataProcess
using Main.PlotData


#Validate Kernel
function ValidateKernel(ŷ,y)
    n=length(ŷ)
    num=0
    for i=1:n
        if ŷ[i]==y[i] 
            num=num+1
        end
    end
    return num/n
end

#Train Kernel
function RunKernel(traindata,valdata,box)
    k=SqExponentialKernel()∘ ScaleTransform(2.5)
    model = svmtrain(kernelmatrix(k, traindata.X), traindata.Y; kernel=LIBSVM.Kernel.Precomputed)
    #Validate Data
    mval=DataProcess.RowVec2Matrix(valdata)
    x_val=RowVecs(mval)
    y_val, _ = svmpredict(model, kernelmatrix(k, traindata.X, x_val))
    acc=ValidateKernel(valdata.Y,y_val)

    #Create Contours (from Surface to 4000m MSL)
    test_range_lat=range(box.SE[2], box.NE[2]; length=50)
	test_range_lon=range(box.NW[1], box.NE[1]; length=50)
    test_range_alt=range(box.ALT[1],4000; length=25)
    x_data=mapreduce(collect, hcat, Iterators.product(test_range_lat, test_range_lon, test_range_alt))
    x_test=ColVecs(x_data);
    y_test,_=svmpredict(model, kernelmatrix(k,traindata.X, x_test))

    return x_data,y_test
end

#Create Function to find average lat/lon position among contour plots

#Simple Average NIC Value Algorithm
function AverageNic(data)
    adsb_points=DataProcess.RowVec2Matrix(data)
    indnic0=findall(x->x==0,data.Y)
    nic0points=adsb_points[indnic0,:]
    lat=mean(nic0points[:,1])
    lon=mean(nic0points[:,2])
    varlat=var(nic0points[:,1])
    varlon=var(nic0points[:,2])
    return lat, lon, varlat, varlon
end


#Function that runs through Algorithms Every 5 minutes of very hour
function KernelTime(timedata)
    delta_t=0:5:55
    Min=minute.(timedata.mintime)
    counter=1
    acc=Array{Float64}(undef,length(delta_t))
    center=Array{Float64}(undef,length(delta_t),4)
    for t=delta_t
        ind=findall(x->t<x<t+5,Min)
        filtereddata=timedata[ind,:]
        rbfdatat,rbfdatav,box=DataProcess.SplitData(filtereddata)
        #RBF #acc[counter]
        (acc,center)=RunKernel(rbfdatat,rbfdatav,box)
        #Average NIC Function
        (center[counter,1],center[counter,2],center[counter,3],center[counter,4])=AverageNic(rbfdatat)
        counter=counter+1
    end
    Min=minute.(timedata.mintime)
    ind=findall(x->0<x<5,Min)
    filtereddata=timedata[ind,:]
    rbfdatat,rbfdatav,box=DataProcess.SplitData(filtereddata)
    #RBF 
    (acc,center)=RunKernel(rbfdatat,rbfdatav,box)
    return acc,center
end

#Function that Iterates by Hour
function KernelHour(rawdata)
    timedata=DataProcess.ReClock(rawdata)
    timedata=sort!(timedata)
    Hour=hour.(timedata.mintime)
    uniquehours=unique(Hour)
    n_hours=length(uniquehours)
    accfull=Vector{Vector{Float64}}(undef,n_hours)
    centerfull=Vector{Array{Float64}}(undef,n_hours)
    for i=1:n_hours
        hourind=findall(x->x==uniquehours[i],Hour)
        accfull[i],centerfull[i]=KernelTime(timedata[hourind,:])
        #accful[i],centerfull[i]
    end
    return accful,centerfull
    #accful,centerfull
end

#Main Function
function main()
    filename,rawdata=DataProcess.FileUpload()
    accfull,accfull=KernelHour(rawdata)
    PlotData.PlotValAccuracy(accfull)
    PlotData.PlotAverage(centerfull)  
end


#Test Functions
function testKernelTime(timedata)
    Min=minute.(timedata.mintime)
    ind=findall(x->0<x<30,Min)
    filtereddata=timedata[ind,:]
    rbfdatat,rbfdatav,box=DataProcess.SplitData(filtereddata)
    #RBF 
    (x_test,y_test)=RunKernel(rbfdatat,rbfdatav,box)
    return x_test, y_test,box
end

function testmain()
    filename,rawdata=DataProcess.FileUpload()
    timedata=DataProcess.ReClock(rawdata)
    timedata=sort!(timedata)
    x_test,y_test,box=testKernelTime(timedata)
    x=transpose(x_test)

    #Filter altitude with nic of 0 included
    nic0=findall(x->x==0,y_test)
    newx=x[nic0,:]
    altunq=unique(newx[:,3])

    altind=[findall(x->x==altunq[i],x[:,3]) for i=1:length(altunq)]
    altind=vec(mapreduce(permutedims,hcat,altind))
    finalx=x[altind,:]
    finaly=y_test[altind]

    #Find Average of all planes
    planary=reshape(finaly,(50,50,length(altunq)))
    oneyd=reshape(mean(planary,dims=3),(50,50))
    oney=vec(reshape(mean(planary,dims=3),(1,2500)))

    grid=transpose(mapreduce(collect,hcat,Iterators.product(unique(finalx[:,2]),unique(finalx[:,1]))))
    



    #PlotData.PlotContour(unique(x[:,2]), unique(x[:,1]),oneyd,box)
    PlotData.PlotMap(grid,oney,box)
    #return unique(x[:,2]), unique(x[:,1]),oney,box
end

#Main Script
testmain()
