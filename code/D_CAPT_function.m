function num_swaps = D_CAPT_function(full_points,t,h,N,r_base,plot_flag)

S = full_points(1:N,:);
G = full_points(N+1:end,:);

robots = cell(N,1);

num_swaps = 0;

t_0 = t(1);
t_f = t(end);

X = S;
C = calculate_C(X,h);
for i_t = 1:N
    robots{i_t}.U = C(i_t,:);
    robots{i_t}.goal = G(i_t,:);
    robots{i_t}.pos = S(i_t,:);
    robots{i_t}.start = S(i_t,:);
    robots{i_t}.t_0 = t_0;

end

C_prev = zeros(N);

if plot_flag
    thetas = linspace(0,2*pi,20)';
    r_c_x = r_base * cos(thetas);
    r_c_y = r_base * sin(thetas);
    h_c_x = h * cos(thetas);
    h_c_y = h * sin(thetas);

    pad = min(h,5);

    x_min = min(full_points(:,1))-pad;
    x_max = max(full_points(:,1))+pad;

    y_min = min(full_points(:,2))-pad;
    y_max = max(full_points(:,2))+pad;

    f = figure(1);
    clf
    r_plots = zeros(N,1);
    h_plots = zeros(N,1);
    p_plots = zeros(N,1);
    g_plots = zeros(N,1);

    hold on

    for i = 1:N
        h_plots(i) = patch(r_c_x + robots{i}.pos(1), r_c_y + robots{i}.pos(2), ...
            'b', 'facealpha', 0.2, 'edgealpha', 0);
        p_plots(i) = plot(0,0,'-','color',[1,0.5,0],'linewidth',2);
        g_plots(i) = plot(0,0,'--','color',[1,0.5,0],'linewidth',2);
    end
    for i = 1:N
        r_plots(i) = patch(h_c_x + robots{i}.pos(1), h_c_y + robots{i}.pos(2), ...
            'b','facecolor', [1,0.5,0], 'facealpha', 0.5, 'edgealpha', 1);
    end

    plot(G(:,1),G(:,2),'k+','markersize',8)
    plot(S(:,1),S(:,2),'kx','markersize',8)

    axis equal
    grid on
    set(gca,'color',1*ones(1,3))
    xlim([x_min,x_max])
    ylim([y_min,y_max])
    
end

for i_t = 1:length(t)
    % get new time stamp
    t_c = t(i_t);

    % update the motion for all robots
    for i = 1:N
        robots{i}.pos = update_pos(robots{i},t_c,t_f);
        X(i,:) = robots{i}.pos;
    end

    if plot_flag
        % update plotting for all robots
        for i = 1:N
            set(r_plots(i), 'xdata', r_c_x + robots{i}.pos(1), 'ydata', r_c_y + robots{i}.pos(2));
            set(h_plots(i), 'xdata', h_c_x + robots{i}.pos(1), 'ydata', h_c_y + robots{i}.pos(2));

            paths{i}(i_t,:) = robots{i}.pos;
            set(p_plots(i), 'xdata', paths{i}(1:i_t,1), 'ydata', paths{i}(1:i_t,2));
            set(g_plots(i), 'xdata', [robots{i}.pos(1), robots{i}.goal(1)], ...
                'ydata', [robots{i}.pos(2), robots{i}.goal(2)])
        end
    end
    
    % calculate the new C matrix
    C = calculate_C(X,h);

    % D-CAPT for each robot
    for i = 1:N
        robots{i}.U = (C(i,:) - C_prev(i,:)) > 0;

        while sum(robots{i}.U)

            j = find(robots{i}.U,1,'first');

            u = robots{j}.pos - robots{i}.pos;
            w = robots{j}.goal - robots{i}.goal;

            if dot(u,w) < 0

                num_swaps = num_swaps + 1;

                g_i = robots{i}.goal;
                g_j = robots{j}.goal;

                robots{i}.goal = g_j;
                robots{i}.t_0 = t_c;
                robots{i}.start = robots{i}.pos;

                robots{j}.goal = g_i;
                robots{j}.t_0 = t_c;
                robots{j}.start = robots{j}.pos;

                robots{i}.U = C(i,:);
                robots{j}.U = C(j,:);

            end

            robots{i}.U(j) = false;
            robots{j}.U(i) = false;

        end

    end

    % assign current C to previous C
    C_prev = C;

    if plot_flag && ~mod(i_t,5)
        drawnow
    end
    
end

if plot_flag
    pause
    delete(f)
end
