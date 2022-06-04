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
function ValidateKernel(k,model,traindata,valdata)
    numval=50
    acc=Array{Float64}(undef,numval)
    for i=1:numval
        n=size(valdata.X,2)
            randsampind=rand(1:n,100)
            randsampx=valdata.X[:,randsampind]
            randsampy=valdata.Y[randsampind]
        
        ŷ, _ = svmpredict(model, kernelmatrix(k,ColVecs(traindata.X),ColVecs(randsampx)))
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

#Train Kernel
function RunKernel(traindata,valdata,box)
    k=SqExponentialKernel()∘ScaleTransform(0.001)
    #Train Model
    model = svmtrain(kernelmatrix(k, ColVecs(traindata.X)), traindata.Y; kernel=LIBSVM.Kernel.Precomputed)
    #Plot Model (Meshgrid)
    test_range_x=range(box.X[1], box.X[2]; length=100)
	test_range_y=range(box.Y[1], box.Y[2]; length=100)
    test_range_alt=range(box.ALT[1],box.ALT[2]; length=25)
    x_test=mapreduce(collect, hcat, Iterators.product(test_range_x, 
        test_range_y,test_range_alt))
    y_test,_=svmpredict(model, kernelmatrix(k,ColVecs(traindata.X), ColVecs(x_test)))
    #Validate Kernel
    acc=ValidateKernel(k,model,traindata,valdata)
    return acc,x_test,y_test
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
    #Plot Data
    # newx=DataProcess.LLAConvert(kdatat.X)
    # PlotData.plotgeo(newx,kdatat.Y)
    #Train Kernel
    acc,x_test,y_test=RunKernel(kdatat,kdatav,box)
    # #Plot Area of Interference
    newy=MargAlt(x_test,y_test)
    newx=DataProcess.LLAConvert(x_test)
    PlotData.PlotMap(newx,newy)
    #Plot Validation Accuracy
    PlotData.PlotValAccuracy(acc)
end

#Main Script
main()

#Old Code:
    # function testmain()
    #     filename,rawdata=DataProcess.FileUpload()
    #     timedata=DataProcess.ReClock(rawdata)
    #     timedata=sort!(timedata)
    #     ecefdata=DataProcess.ENUConvert(timedata)
    #     #Add ECEF Coordinbates to timetable
    #     timedata.x=ecefdata[:,1]
    #     timedata.y=ecefdata[:,2]
    #     timedata.z=ecefdata[:,3]
    #     testKernelTime(timedata)
    #     #newy=reshape(y_test,(Int(sqrt(length(y_test))),Int(sqrt(length(y_test)))))
    #     #PlotData.PlotContour(x_test,y_test,rbfdatat.X,rbfdatat.Y)
    # end

    #Function that Iterates by Hour
    # function KernelHour(rawdata)
    #     timedata=DataProcess.ReClock(rawdata)
    #     timedata=sort!(timedata)
    #     #Convert to ENU
    #     ecefdata=DataProcess.ENUConvert(timedata)
    #     timedata.x=ecefdata[:,1]
    #     timedata.y=ecefdata[:,2]
    #     timedata.z=ecefdata[:,3]
    #     #Sort by hours
    #     Hour=hour.(timedata.mintime)
    #     uniquehours=unique(Hour)
    #     n_hours=length(uniquehours)
    #     accfull=Vector{Vector{Float64}}(undef,n_hours)
    #     centerfull=Vector{Array{Float64}}(undef,n_hours)
    #     #run per hour
    #     for i=1:n_hours
    #         hourind=findall(x->x==uniquehours[i],Hour)
    #         accfull[i]=KernelTime(timedata[hourind,:])
    #     end
    #     return accful #centerfull
    # end

    #Simple Average NIC Value Algorithm
    # function AverageNic(data)
    #     adsb_points=DataProcess.RowVec2Matrix(data)
    #     indnic0=findall(x->x==0,data.Y)
    #     nic0points=adsb_points[indnic0,:]
    #     lat=mean(nic0points[:,1])
    #     lon=mean(nic0points[:,2])
    #     varlat=var(nic0points[:,1])
    #     varlon=var(nic0points[:,2])
    #     return lat, lon, varlat, varlon
    # end
    #Test Functions
    # function testKernelTime(timedata)
    #     Min=minute.(timedata.mintime)
    #     ind=findall(x->15<x<30,Min)
    #     filtereddata=timedata[ind,:]
    #     rbfdatat,rbfdatav,box=DataProcess.SplitData(filtereddata)
    #     #Train Kernel
    #     acc,x_test,y_test=RunKernel(rbfdatat,box)
    #     newy=MargAlt(x_test,y_test)
    #     newx=DataProcess.LLAConvert(x_test)
    #     PlotData.PlotMap(newx,newy)
    # end