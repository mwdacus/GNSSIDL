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

include("Util_Data.jl")
include("Plot_Data.jl")

#Validate Kernel
function ValidateKernel(model,valdata)
    numval=50
    acc=Array{Float64}(undef,numval)
    for i=1:numval
        n=size(valdata.X,2)
            randsampind=rand(1:n,500)
            randsampx=valdata.X[:,randsampind]
            randsampy=valdata.Y[randsampind]
        
        ŷ, _ = svmpredict(model, randsampx)
        n=length(ŷ)
        num=0
        for i=1:n
            if ŷ[i]==randsampy[i] 
                num=num+1
            end
        end
        acc[i]=num/n
    end
    return acc
end

#Create Confusion Matrix
function Confusion(model,valdata)
    numval=50
    allconf=Array{Matrix{Float64}}(undef,numval)
    for i=1:numval    
        n=size(valdata.X,2)
        randsampind=rand(1:n,500)
        randsampx=valdata.X[:,randsampind]
        randsampy=valdata.Y[randsampind]
        confusion=zeros(3,3)
        ŷ, _ = svmpredict(model, randsampx)
        n=length(ŷ)
        for j=1:n
            confusion[Int(randsampy[j])+1,Int(ŷ[j])+1]=
                confusion[Int(randsampy[j])+1,Int(ŷ[j])+1]+1.0
        end
        allconf[i]=confusion
    end
    return allconf
end

#Train Kernel
function RunKernel(traindata,box)
    #Train Model
    model = svmtrain(traindata.X, traindata.Y; svmtype=SVC,
        kernel=LIBSVM.Kernel.Polynomial,degree=3,coef0=0.25,gamma=3.0)
        #,degree=4,coef0=.25,gamma=1/4)
    #Plot Model (Meshgrid)
    test_range_x=range(-50000, 50000; length=100)
	test_range_y=range(-50000, 50000; length=100)
    test_range_alt=range(box.ALT[1],box.ALT[2]; length=25)
    x_test=mapreduce(collect, hcat, Iterators.product(test_range_x, 
        test_range_y,test_range_alt))
    y_test,_=svmpredict(model, x_test)
    return model,x_test,y_test
end

#Function that finds label averages among all planes
function MargAlt(x_data,y_data)
    npoints=length(unique(x_data[1,:]))
    altunq=length(unique(x_data[3,:]))
    newy_data=reshape(y_data,(npoints,npoints,altunq))
    newy_vec=vec(reshape(mean(newy_data,dims=3),(1,npoints*npoints)))
    return newy_vec
end

#Function that runs through Algorithms Every 5 minutes of very hour
function KernelTime(timedata)
    #Sort by minutes
    delta_t=0:10:10
    Min=minute.(timedata.mintime)
    counter=1
    acc=Array{Float64}(undef,length(delta_t))
    center=Array{Float64}(undef,length(delta_t),4)
    #Run kernel for each time interval
    for t=delta_t
        ind=findall(x->t<x<t+10,Min)
        filtereddata=timedata[ind,:]
        rbfdatat,rbfdatav,box=DataProcess.SplitData(filtereddata)
        #Polynomial Kernel 
        acc[counter],x_test,y_test=RunKernel(rbfdatat,rbfdatav,box)
        newy=MargAlt(x_test,y_test)
        newx=DataProcess.LLAConvert(x_test)
        PlotData.PlotMap(newx,newy)
        #Average NIC Function
        # (center[counter,1],center[counter,2],center[counter,3],center[counter,4])=AverageNic(rbfdatat)
        # counter=counter+1
    end

    return acc
end

#Main Function
function main()
    filename,rawdata=DataProcess.FileUpload()
    timedata=DataProcess.ReClock(rawdata)
    timedata=sort!(timedata)
    ecefdata=DataProcess.ENUConvert(timedata)
    timedata.x=ecefdata[:,1]
    timedata.y=ecefdata[:,2]
    timedata.z=ecefdata[:,3]
    kdatat,kdatav,box=DataProcess.SplitData(timedata)
    # Train Kernel
    model,x_test,y_test=RunKernel(kdatat,box)
    # Determine Validation Accuracy
    accfull=ValidateKernel(model,kdatav)
    #Confusion Matrix
    conf=Confusion(model,kdatav)
    # Plot Area of Interference
    newy=MargAlt(x_test,y_test)
    newx=DataProcess.LLAConvert(x_test)
    PlotData.PlotMap(newx,newy)
    # Plot Validation Accuracy
    PlotData.PlotValAccuracy(accfull)
    return conf
end

#Main Script
c=main()