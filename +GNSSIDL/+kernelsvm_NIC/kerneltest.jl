using KernelFunctions
using LIBSVM
using LinearAlgebra
using Random
using Main.PlotData


n1 = n2 = 50
angle1 = range(0, π; length=n1)
angle2 = range(0, π; length=n2)
X1 = [cos.(angle1) sin.(angle1)] .+ 0.1.* randn.()
X2 = [1 .- cos.(angle2) 1 .- sin.(angle2) .- 0.5] .+ 0.1 .* randn.()
X3=collect(2*angle1);
X4=collect(angle2);
X = [[X1; X2] [X3; X4]]
y_train = vcat(fill(-1, n1), fill(1, n2));
k=SqExponentialKernel()∘ScaleTransform(1.5)
newmod=svmtrain(kernelmatrix(k, RowVecs(X)), y_train; kernel=LIBSVM.Kernel.Precomputed)


test_rangex1 = range(minimum(X[:,1]), maximum(X[:,1]); length=25)
test_rangex2 = range(minimum(X[:,2]), maximum(X[:,2]); length=25)
test_rangex3 = range(minimum(X[:,3]), maximum(X[:,3]); length=10)
x_test = (mapreduce(collect, hcat, Iterators.product(test_rangex1,
    test_rangex2,test_rangex3)));
y_test, _ = svmpredict(newmod, kernelmatrix(k,RowVecs(X),ColVecs(x_test)))

PlotData.PlotContour(transpose(X),y_train,x_test,y_test)