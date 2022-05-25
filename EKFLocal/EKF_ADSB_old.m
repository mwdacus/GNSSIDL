function [x_kalman] = EKF_ADSB_old(adsb_data,initial_cond,reltime)
    %Global Parameters
    global Q R 
    delta_t=diff(reltime);
    n_iter=size(adsb_data,1);
    
    %Process and noise covariances
    Q=eye(6)*delta_t(1);
    R=200*eye(3)*delta_t(1);


    %EKF Parameters (Range Measurement)
    x_kalman=zeros(n_iter,6);
    x_kalman(1,:)=mvnrnd([0;0;0;initial_cond(4);initial_cond(5);initial_cond(6)],Q);
    Sigma_kalman=cell(1,n_iter);
    Sigma_kalman{1}=100*eye(6);
    

    for t=1:n_iter-1
            Q=eye(6)*delta_t(t);
            R=200*eye(3)*delta_t(t);
        y_meas=[adsb_data(t+1,1),adsb_data(t+1,2),adsb_data(t+1,3)]';
        [x_pred,Sigma_pred]=predict(x_kalman(t,:),Sigma_kalman{t},delta_t(t));
        [x_kalman(t+1,:),Sigma_kalman{t+1}]=update(x_pred,Sigma_pred,y_meas);
    end
end

%% Other Functions
%KF Predict
function [x_next,Sigma_next]=predict(mu,sigma,delta_t)
    global Q
    %State Dynamics and Jacobian
    [x_next,A]=statemodel(mu,delta_t);
    %Covariance
    Sigma_next=A*sigma*A'+Q;
end
%KF Update (Range Measurements)
function [x_next,Sigma_next]=update(mu_pred,Sigma_pred,y_t)
    global R
    C=[eye(3) zeros(3,3)];
    K=Sigma_pred*C'*inv(C*Sigma_pred*C'+R);
    x_next=mu_pred+K*(y_t-C*mu_pred);
    Sigma_next=Sigma_pred-K*C*Sigma_pred;
end

%Discrete Time Dynamics Model
function [x_next,A]=statemodel(mu,delta_t)
    %Dynamics
    x_next=zeros(6,1);
    x_next(1)=mu(1)+delta_t*mu(4)*sind(mu(5));
    x_next(2)=mu(2)+delta_t*mu(4)*cosd(mu(5));
    x_next(3)=mu(3)+delta_t*mu(6);
    x_next(4)=mu(4);
    x_next(5)=mu(5);
    x_next(6)=mu(6);
    %Jacobian
    A=eye(6);
    A(1,4:6)=[delta_t*sind(mu(5)) delta_t*mu(4)*cosd(mu(5)) 0];
    A(2,4:6)=[delta_t*cosd(mu(5)) -delta_t*mu(4)*sind(mu(5)) 0];
    A(3,4:6)=[0 0 delta_t];
end
