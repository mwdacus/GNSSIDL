function [outputArg1,outputArg2] = Plot_Data(inputArg1,inputArg2)

    timestep=1:n_iter;
    figure('color','w')
    subplot(3,1,1);
    plot(timestep,x_true(1,:))
    hold on
    plot(timestep,x_kalman(1,:))
    plot(timestep,x_kalmanb(1,:))
    legend('True State', 'EKF (Range)', 'EKF (Bearing)')
    xlabel('Number of Iterations')
    ylabel('Position (p_{x})')
    
    subplot(3,1,2);
    plot(timestep,x_true(2,:))
    hold on
    plot(timestep,x_kalman(2,:))
    plot(timestep,x_kalmanb(2,:))
    legend('True State', 'EKF (Range)', 'EKF (Bearing)')
    xlabel('Number of Iterations')
    ylabel('Position (p_{y})')
    
    subplot(3,1,3);
    plot(timestep,x_true(3,:))
    hold on
    plot(timestep,x_kalman(3,:))
    plot(timestep,x_kalmanb(3,:))
    legend('True State', 'EKF (Range)', 'EKF (Bearing)')
    xlabel('Number of Iterations')
    ylabel('Position (p_{\theta})')
    hold off

end

