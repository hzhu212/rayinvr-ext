% 解析和处理 rayinvr/tramp 生成的 sect.out 文件（模拟事件和振幅）

% p = 'D:\Archive\Research\rayinvr\rayinvr-data\obc\stage_1_100\p\sect_ext.out';
% [data, xshot] = parse_sectout(p);

plot_stages('s', 'time', {3.2}, 0.003, false);

% refresh_sectout({'p'});


function [] = refresh_sectout(waves)
% 重新生成全部 sect.out 文件，其实是重新调用 rayinvr/tramp 模块

    if nargin < 1
        waves = {'p', 's'};
    end

    path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\';
    stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};
    for ii = 1:numel(stages)
        for jj = 1:numel(waves)
            path = sprintf(path_template, stages{ii}, waves{jj});
            fprintf('================================================================================\n');
            fprintf(">> rayinvr_fortran('tramp', '%s')\n", path);
            rayinvr_fortran('tramp', path);
        end
    end
end



function [] = plot_stages(wave, ytype, events, xnoise, refresh)
% 绘制多阶段的 sect.out 数据
%
% wave: 'p' 或 's'，绘制纵波事件还是横波事件，默认为 'p'。
% ytype: 指定绘制数据的类别，包括走时(time)、振幅(amplitude)、相位(phase)。
% events: 一个 cell，限定要绘制的事件代号，如 {2.2, 3.2}。
% xnoise: 为接收点的 X 坐标添加随机白噪音的最大值，单位为 km。默认为 0.003，即 3m。
% refresh: 载入 sect.out 数据是是否强制重新解析原始数据，而不载入缓存的数据？

    ytype_id_mapper = containers.Map({'time', 'amplitude', 'phase', 'amp'}, {1, 2, 3, 2});
    ytype_name_mapper = containers.Map({1, 2, 3}, {'Time (s)', 'Amplitude', 'Phase (°)'});

    % 处理输入参数默认值
    if nargin < 5, refresh = false; end
    if nargin < 4, xnoise = 0.003; end
    if nargin < 3, events = {}; end
    if nargin < 2, ytype = 'time'; end
    if nargin < 1, wave = 'p'; end

    if ~any(strcmp({'p', 's'}, wave))
        error('argument "wave" should be "p" or "s"');
    end

    if ytype_id_mapper.isKey(ytype)
        ytype_id = ytype_id_mapper(ytype);
    else
        warning(sprintf('Unknown ytype name "%s", fall back to default value("time")\n', ytype));
        ytype_id = 1;
    end
    ytype_name = ytype_name_mapper(ytype_id);

    if ~iscell(events)
        events = num2cell(events);
    end
    if ~ischar(events{1})
        events = cellfun(@(x) num2str(x), events, 'UniformOutput', false);
    end

    % load data
    path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\sect_ext.out';
    stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};
    data_s = {};
    xshot_s = {};
    for ii = 1:numel(stages)
        stage = stages{ii};
        path = sprintf(path_template, stage, wave);
        [data, xrecvs, xshot] = load_sectout(path, refresh);
        data_s{end+1} = data;
        xshot_s{end+1} = xshot;
    end

    % plot
    all_events = data_s{1}.keys();
    if ~isempty(events)
        all_events = intersect(all_events, events);
    end
    all_events = sort(all_events);

    % 每次采集时，空气枪震源的位置不可能精确固定，因此为接收点坐标添加一个随机白噪声(3m)
    noise = randn(size(xrecvs)) * xnoise;
    noise_mapper = containers.Map(xrecvs, noise);

    for ii = 1:numel(all_events)
        event_id = all_events{ii};
        fig = figure();
        hold on;
        for jj = 1:numel(data_s)
            data = data_s{jj};
            if ~data.isKey(event_id)
                continue;
            end
            data = data(event_id);

            offset = data(:, 1);
            ydata = data(:, ytype_id+1);
            % 为 offset 添加白噪声
            selected_noise = cell2mat(values(noise_mapper, num2cell(offset)));
            ydata = interp1(offset, ydata, offset + selected_noise);
            % offset 扣除炮点 X 坐标
            offset = offset - xshot_s{jj};

            % 绘制相位时，将弧度转化为角度
            if contains(ytype_name, 'phase', 'IgnoreCase', true)
                ydata = ydata / pi * 180;
            end
            left_idx = (offset < 0);
            curve_left = plot(offset(left_idx), ydata(left_idx), 'k-', 'LineWidth', 1, 'DisplayName', sprintf('T%1d', jj));
            curve_right = plot(offset(~left_idx), ydata(~left_idx), 'k-', 'LineWidth', 1, 'HandleVisibility','off');
            curve_left.Color(4) = jj/numel(data_s);
            curve_right.Color(4) = jj/numel(data_s);
        end
        hold off;
        grid on;
        box on;
        title(sprintf('Event %s', event_id));
        % 绘制走时，反转 Y 轴
        if contains(ytype_name, 'time', 'IgnoreCase', true)
            set(gca, 'YDir', 'reverse');
        end
        if contains(ytype_name, 'phase', 'IgnoreCase', true)
            ylim([0, 360]);
        end
        xlabel('Offset (km)');
        ylabel(ytype_name);
        legend('show');
    end
end



function [data, xrecvs, xshot] = load_sectout(filepath, refresh, savemat)
% 载入 sectout 数据。如果当前文件有对应的 .mat 文件，可直接载入，否则从 sect.out 文件中解析数据。
%
% refresh: 若为 true，则强制从 sect.out 文件中解析，不使用 .mat 文件。默认为 true。
% savemat: 若为 true，则将解析好的数据保存为 .mat 文件，方便下次直接加载。默认为 true。

    if nargin < 3
        savemat = true;
        if nargin < 2
            refresh = true;
        end
    end

    matfile = [filepath, '.mat'];
    if refresh || ~exist(matfile, 'file')
        is_from_mat = false;
        [data, xrecvs, xshot] = parse_sectout(filepath);
    else
        is_from_mat = true;
        obj = load(matfile);
        data = obj.data;
        xrecvs = obj.xrecvs;
        xshot = obj.xshot;
    end

    if savemat && ~is_from_mat
        save(matfile, 'data', 'xrecvs', 'xshot');
    end
end



function [data, xrecvs, xshot] = parse_sectout(filepath)
% 解析 sect.out 文件，返回数据体（containers.Map 类型）、接收点 X 坐标数组、炮点的 X 坐标
%
% 文件内容样例：
%    10.000        -1
%     0.000         0
%     0.025         0
%     0.050         2
% 0.67330E+01 0.40038E-01 0.30656E+01 2.2
% 0.59158E+01 0.74288E-06 0.00000E+00 4.2
%     0.075         2
% 0.67166E+01 0.40041E-01 0.30652E+01 2.2
% 0.59026E+01 0.74307E-06 0.00000E+00 4.2
%     0.100         2
% 0.67003E+01 0.40048E-01 0.30648E+01 2.2
% 0.58895E+01 0.74326E-06 0.00000E+00 4.2
%     0.125         3
% 0.66840E+01 0.40056E-01 0.30644E+01 2.2
% 0.58613E+01 0.38832E-03 0.31416E+01 3.2
% 0.58764E+01 0.74345E-06 0.00000E+00 4.2
%
% 格式含义：
% 1行炮点：<X 坐标>    <-1>
%     1行接收点：<X 坐标>  <事件个数 n>
%         n行事件：<时间>  <振幅>  <相位>  <代号>
%     1行接收点：<X 坐标>  <事件个数 n>
%         n行事件：<时间>  <振幅>  <相位>  <代号>
%     ...

    data = containers.Map();
    xrecvs = [];
    xshot = NaN;

    fid = fopen(filepath);
    lineno = 0;
    try
        % shot line
        lineno = lineno + 1;
        row = sscanf(fgetl(fid), '%10f%10d');
        xshot = row(1);
        const = row(2);
        assert(const == -1, 'shot line format error');

        while ~feof(fid)
            % receiver line
            lineno = lineno + 1;
            recv_line = fgetl(fid);
            recv_row = sscanf(recv_line, '%10f%10d');
            recv_x = recv_row(1);
            recv_n = recv_row(2);
            xrecvs = [xrecvs; recv_x];

            % event lines
            for ii = 1:recv_n
                lineno = lineno + 1;
                event_row = sscanf(fgetl(fid), '%12f%12f%12f%4f')';
                event_id = num2str(event_row(4));
                new_data = [recv_x, event_row(1:3)];
                if ~data.isKey(event_id)
                    data(event_id) = [new_data];
                else
                    data(event_id) = [data(event_id); new_data];
                end
            end
        end
    catch e
        fprintf('*** An error occured while processing line %d of file %s ***\n', lineno, filepath);
        fclose(fid);
        rethrow(e);
    end

    fclose(fid);
end
