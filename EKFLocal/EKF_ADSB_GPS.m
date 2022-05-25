function [x_kalman] = EKF_ADSB_GPS(adsbdata,gpsdata,reltime)
    
    delta_t=diff(reltime);
    n_iter=size(adsbdata,1);
    
    %Process and noise covariances
    Qmatrix=diag([20 20 20 0 1]);
    Rmatrix=diag([100 100 100]);
    Qfirst=Qmatrix*delta_t(1);

    %EKF Parameters (Range Measurement)
    x_kalman=zeros(n_iter,5);

    x_kalman(1,:)=mvnrnd([0;0;0;adsbdata(1,3)-gpsdata(1,3);1],Qfirst);
    Sigma_kalman=cell(1,n_iter);
    Sigma_kalman{1}=Qfirst;
    
    for t=1:n_iter-1
        Q=Qmatrix*delta_t(t);
        R=Rmatrix*delta_t(t);
        u_t=[gpsdata(t,4) gpsdata(t,5) gpsdata(t,6)];
        y_meas=[adsbdata(t+1,1),adsbdata(t+1,2),adsbdata(t+1,3)]';
        [x_pred,Sigma_pred]=predict(x_kalman(t,:),Sigma_kalman{t},delta_t(t),Q,u_t);
        [x_kalman(t+1,:),Sigma_kalman{t+1}]=update(x_pred,Sigma_pred,y_meas,R);
    end
end

%% Other Functions
%KF Predict
function [x_next,Sigma_next]=predict(mu,sigma,delta_t,Q,u_t)
    %State Dynamics and Jacobian
    [x_next,A]=statemodel(mu,delta_t,u_t);
    %Covariance
    Sigma_next=A*sigma*A'+Q;
end
%KF Update (Range Measurements)
function [x_next,Sigma_next]=update(mu_pred,Sigma_pred,y_t,R)
    C=zeros(3,5);
    C(1:3,1:3)=eye(3);
    C(3,4)=1;
    K=Sigma_pred*C'*inv(C*Sigma_pred*C'+R);
    x_next=mu_pred+K*(y_t-C*mu_pred);
    Sigma_next=Sigma_pred-K*C*Sigma_pred;
end

%Discrete Time Dynamics Model
function [x_next,A]=statemodel(mu,delta_t,u_t)
    %Dynamics
    x_next=zeros(5,1);
    x_next(1)=mu(1)+(delta_t+mu(5))*u_t(1)*sind(u_t(2));
    x_next(2)=mu(2)+(delta_t+mu(5))*u_t(1)*cosd(u_t(2));
    x_next(3)=mu(3)+(delta_t+mu(5))*u_t(3);
    x_next(4)=mu(4);
    x_next(5)=mu(5);
    %Jacobian
    A=eye(5);
    A(1:3,5)=[u_t(1)*sind(u_t(2));u_t(1)*cosd(u_t(2)); u_t(3)];
end
