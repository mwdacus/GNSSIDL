function [x_kalman] = EKF_ADSB(adsbdata,gpsdata,reltime)
    
    delta_t=diff(reltime);
    n_iter=size(adsbdata,1);
    
    %Process and noise covariances
    Qmatrix=diag([20 20 20 10 1 10 0 1]);
    Rmatrix=diag([100 100 100 10 10 10]);
    Qfirst=Qmatrix*delta_t(1);

    %EKF Parameters (Range Measurement)
    x_kalman=zeros(n_iter,8);

    x_kalman(1,:)=mvnrnd([0;0;0;gpsdata(1,4);gpsdata(1,5);...
        gpsdata(1,6);adsbdata(1,3)-gpsdata(1,3);1],Qfirst);
    Sigma_kalman=cell(1,n_iter);
    Sigma_kalman{1}=Qfirst;
    
    for t=1:n_iter-1
        Q=Qmatrix*delta_t(t);
        R=Rmatrix*delta_t(t);
        y_meas=[adsbdata(t+1,1),adsbdata(t+1,2),adsbdata(t+1,3), adsbdata(t+1,4)...
            adsbdata(t+1,5), adsbdata(t+1,6)]';
        [x_pred,Sigma_pred]=predict(x_kalman(t,:),Sigma_kalman{t},delta_t(t),Q);
        [x_kalman(t+1,:),Sigma_kalman{t+1}]=update(x_pred,Sigma_pred,y_meas,R);
    end
end

%% Other Functions
%KF Predict
function [x_next,Sigma_next]=predict(mu,sigma,delta_t,Q)
    %State Dynamics and Jacobian
    [x_next,A]=statemodel(mu,delta_t);
    %Covariance
    Sigma_next=A*sigma*A'+Q;
end
%KF Update (Range Measurements)
function [x_next,Sigma_next]=update(mu_pred,Sigma_pred,y_t,R)
    C=zeros(6,8);
    C(:,1:6)=eye(6);
    C(6,7)=1;
    K=Sigma_pred*C'*inv(C*Sigma_pred*C'+R);
    x_next=mu_pred+K*(y_t-C*mu_pred);
    Sigma_next=Sigma_pred-K*C*Sigma_pred;
end

%Discrete Time Dynamics Model
function [x_next,A]=statemodel(mu,delta_t)
    %Dynamics
    x_next=zeros(8,1);
    x_next(1)=mu(1)+(delta_t+mu(8))*mu(4)*sind(mu(5));
    x_next(2)=mu(2)+(delta_t+mu(8))*mu(4)*cosd(mu(5));
    x_next(3)=mu(3)+(delta_t+mu(8))*mu(6);
    x_next(4)=mu(4);
    x_next(5)=mu(5);
    x_next(6)=mu(6);
    x_next(7)=mu(7);
    x_next(8)=mu(8);
    %Jacobian
    A=eye(8);
    A(1,4:6)=[(delta_t+mu(8))*sind(mu(5)) (delta_t+mu(8))*mu(4)*cosd(mu(5)) 0];
    A(2,4:6)=[(delta_t+mu(8))*cosd(mu(5)) -(delta_t+mu(8))*mu(4)*sind(mu(5)) 0];
    A(3,4:6)=[0 0 (delta_t+mu(8))];
    A(1:3,8)=[mu(4)*sind(mu(5));mu(4)*cosd(mu(5)); mu(6)];
end
