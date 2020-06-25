% 解析和处理 rayinvr/tramp 生成的 sect.out 文件（模拟事件和振幅）。
% 进行走时、振幅、相位分析。

global path_template stages;
path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\';
stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};


% 使用步骤：
% 1. 设置好 r.in、tx.in 等 Rayinvr 配置文件。
% 2. 执行 run_tramp_fortran 函数（指定纵横波或两者），获得 sect_ext.out 输出文件（包含所有事件的走时、振幅、相位等数据）。
% 3. 执行 plot_multi_wave_anylyze 函数，解析 sect_ext.out 文件并绘制走时、振幅、相位等分析图像
% 4. 修改 r.in 参数后，为避免之前已生成的 sect_ext.out 数据被覆盖，可使用 batch_backup_data 函数进行批量备份或重命名，等使用时再改名回来。

% run_tramp_fortran({'p', 's'});
% batch_backup_data('sect_ext.out', 'sect_ext.obc.out', {'p', 's'});
plot_multi_wave_anylyze('p', 'amp', {3.2,4.2}, 'sectionAt', [0.1,0.3], 'xnoise', 0.00315, 'refresh', true);



function run_tramp_fortran(waves)
% 重新生成全部 sect_ext.out 文件，其实是重新调用 rayinvr/tramp 模块
    global path_template stages;

    if nargin < 1
        waves = {'p', 's'};
    end

    for ii = 1:numel(stages)
        for jj = 1:numel(waves)
            path = sprintf(path_template, stages{ii}, waves{jj});
            fprintf('================================================================================\n');
            fprintf(">> rayinvr_fortran('tramp', '%s')\n", path);
            rayinvr_fortran('tramp', path);
        end
    end
end


function batch_backup_data(from_name, to_name, waves, copy, overwrite)
% 批量备份已经生成的 sect_ext.out 数据。
% 当修改模型之后，如果全部重新生成一遍 sect_ext.out 速度较慢，因此设计该函数批量备份与还原 sect_ext.out 文件，再次使用时不必重新生成，方便多个模型之间做对比。
% 默认为拷贝备份，如将 copy 参数设为 false，则为重命名备份。

    global path_template stages;

    if nargin < 5, overwrite = false; end
    if nargin < 4, copy = true; end
    if nargin < 3, waves = {'p', 's'}; end

    if strcmp(from_name, to_name)
        error('from_name can not be same with to_name');
    end

    for ii = 1:numel(stages)
        for jj = 1:numel(waves)
            base_path = sprintf(path_template, stages{ii}, waves{jj});

            if ~overwrite && exist(fullfile(base_path, to_name), 'file')
                answer = questdlg(sprintf('文件名 %s 已存在，是否覆盖？', to_name), '警告', '是', '取消操作', '取消操作');
                overwrite = strcmp(answer, '是');
                if ~overwrite
                    fprintf('Operation canceled!\n');
                    return;
                end
            end

            if copy
                fprintf('%s : %s |-> %s\n', base_path, from_name, to_name);
                copyfile(fullfile(base_path, from_name), fullfile(base_path, to_name));
            else
                fprintf('%s : %s -> %s\n', base_path, from_name, to_name);
                movefile(fullfile(base_path, from_name), fullfile(base_path, to_name));
            end
        end
    end
end


function [] = plot_multi_wave_anylyze(wave, ytype, events, varargin)
% 绘制多阶段的走时分析/振幅分析/相位分析图
%
% 位置参数：
% wave: 'p' 或 's'，绘制纵波事件还是横波事件，默认为 'p'。
% ytype: 指定绘制数据的类别，包括走时(time)、振幅(amplitude)、相位(phase)。
% events: 一个 cell，限定要绘制的事件代号，如 {2.2, 3.2}。
% 可选参数：
% xnoise: 为接收点的 X 坐标添加的高斯随机噪音的标准差，单位为 km。默认为 0.003，即 3m。
% refresh: 载入 sect.out 数据时强制重新解析原始数据，否则载入缓存的数据。
% sectionAt: 在哪些 offset 处创建纵向切片图。默认不创建切片图。

    global path_template stages;

    wave_mapper = containers.Map({'p', 's'}, {'P wave', 'S wave'});
    wave_mapper_zh = containers.Map({'p', 's'}, {'纵波', '横波'});
    ytype_id_mapper = containers.Map({'time', 'amplitude', 'phase'}, {1, 2, 3});
    ytype_name_mapper = containers.Map({1, 2, 3}, {'Time (s)', 'Amplitude', 'Phase (°)'});
    ytype_name_mapper_zh = containers.Map({1, 2, 3}, {'走时 (s)', '振幅', '相位 (°)'});
    colors = parula(6+2); colors = colors(2:end-1, :);

    % 处理输入参数默认值
    if nargin < 3, events = {}; end
    if nargin < 2, ytype = 'time'; end
    if nargin < 1, wave = 'p'; end

    opts = struct('xnoise', 0, 'refresh', true, 'sectionAt', []);
    custom_opts = struct(varargin{:});
    names = fieldnames(custom_opts);
    for ii = 1:numel(names)
        opts.(names{ii}) = custom_opts.(names{ii});
    end

    if ~any(strcmp({'p', 's'}, wave))
        error('argument "wave" should be "p" or "s"');
    end

    if strcmp(ytype, 'amp'), ytype = 'amplitude'; end
    if ytype_id_mapper.isKey(ytype)
        ytype_id = ytype_id_mapper(ytype);
    else
        warning(sprintf('Unknown ytype name "%s", fall back to default value("time")\n', ytype));
        ytype_id = 1;
    end
    ytype_name = ytype_name_mapper(ytype_id);
    ytype_name_zh = ytype_name_mapper_zh(ytype_id);

    if ~iscell(events)
        events = num2cell(events);
    end
    if ~ischar(events{1})
        events = cellfun(@(x) num2str(x), events, 'UniformOutput', false);
    end

    % load data
    data_s = {};
    xshot_s = {};
    for ii = 1:numel(stages)
        stage = stages{ii};
        path = sprintf([path_template, 'sect_ext.out'], stage, wave);
        [data, xrecvs, xshot] = load_sectout(path, opts.refresh);
        data_s{end+1} = data;
        xshot_s{end+1} = xshot;
    end

    % plot
    all_events = data_s{1}.keys();
    if ~isempty(events)
        all_events = intersect(all_events, events);
    end
    all_events = sort(all_events);

    % 每次采集时，空气枪震源的位置不可能精确固定，因此为接收点坐标添加一个随机白噪声(3m)作为定位误差
    % 每个航次分配一致的误差，即该航次中的所有的事件具有相同的误差，但不同航次具有不同的误差
    noise = randn(numel(xrecvs), numel(data_s)) * opts.xnoise;
    noise_mapper = containers.Map(xrecvs, 1:numel(xrecvs));

    for ii = 1:numel(all_events)
        if ~isempty(opts.sectionAt)
            sectionys = cell(size(opts.sectionAt));
        end

        event_id = all_events{ii};
        fig = figure('NumberTitle', 'off', 'Name', sprintf('%s-event%s(%s)', ytype, event_id, wave));
        ax = axes(fig);
        ax = baldbox(ax);
        hold on;
        for jj = 1:numel(data_s)
            data = data_s{jj};
            if ~data.isKey(event_id)
                continue;
            end
            data = data(event_id);

            offset = data(:, 1);
            ydata = data(:, ytype_id+1);

            % 当地层比较复杂时，同一个事件的多条射线可能通过不同的路径先后到达同一个接收器。
            % 绘制走时图像时只考虑第一个到达的射线，但为了在绘图时不遗漏多个事件的信息，将剩余事件概括在一个 error bar 内？
            % 绘图时为了避免杂乱，只考虑第一个到达的事件，将后续事件忽略
            [offset, idx, ~] = unique(offset);
            ydata = ydata(idx);

            % 为 offset 添加白噪声
            if opts.xnoise > 0
                noise_idx = cell2mat(values(noise_mapper, num2cell(offset)));
                ydata = interp1(offset, ydata, offset + noise(noise_idx, jj));
            end

            % offset 扣除炮点 X 坐标
            offset = offset - xshot_s{jj};

            % 绘制相位时，将弧度转化为角度
            if contains(ytype_name, 'phase', 'IgnoreCase', true)
                ydata = ydata / pi * 180;
            end

            % 绘制横向图
            left_idx = (offset < 0);
            curve_left = plot(ax, offset(left_idx), ydata(left_idx), 'LineWidth', 1, 'Color', colors(jj,:), 'DisplayName', sprintf('T%1d', jj-1));
            curve_right = plot(ax, offset(~left_idx), ydata(~left_idx), 'LineWidth', 1, 'Color', colors(jj,:), 'HandleVisibility','off');

            % 收集纵向切片数据，用于绘制纵向剖面图
            for kk = 1:numel(opts.sectionAt)
                ydata_idx = find(abs(offset-opts.sectionAt(kk))<1e-4, 1);
                if ~isempty(ydata_idx)
                    sectionys{kk}(jj) = ydata(ydata_idx);
                else
                    sectionys{kk}(jj) = NaN;
                end
            end
        end
        hold off;
        % title(sprintf('Event %s', event_id));
        title(sprintf('%s-%s', wave_mapper_zh(wave), event_id));
        set(ax, 'TickDir', 'out');
        % 绘制走时，反转 Y 轴
        if contains(ytype_name, 'time', 'IgnoreCase', true)
            set(ax, 'YDir', 'reverse');
        end
        if contains(ytype_name, 'phase', 'IgnoreCase', true)
            ylim(ax, [0, 360]);
        end
        xlabel(ax, '偏移距 (km)');
        ylabel(ax, ytype_name_zh);
        lgd = legend(ax, 'show', 'Location', 'Best');
        set(lgd, 'Color', 'none');

        % 绘制纵向剖面图
        if ~isempty(opts.sectionAt)
            fig2 = figure('NumberTitle', 'off', 'Name', sprintf('%s-event%s(%s)-section', ytype,event_id,wave));
            % set(fig2, 'Name', [get(fig2, 'Name'), '-diff']);
            ax2 = axes(fig2);
            ax2 = baldbox(ax2);
            hold on;
            for kk = 1:numel(opts.sectionAt)
                % 绝对量折线图
                plot(ax2, sectionys{kk}, '-o', 'DisplayName', sprintf('偏移距=%.2fkm', opts.sectionAt(kk)));
                % % 差异走时stem图
                % stem(ax2, [0, diff(sectionys{kk})]*1e3, 'LineWidth', 1, 'DisplayName', sprintf('偏移距=%.2fkm', opts.sectionAt(kk)));
                % % 相对差异振幅stem图
                % y = sectionys{kk}; stem(ax2, [0, diff(y)./y(1:end-1)]*100, 'LineWidth', 1, 'DisplayName', sprintf('偏移距=%.2fkm', opts.sectionAt(kk)));
            end
            hold off;
            lgd = legend(ax2, 'show', 'Location', 'Best');
            set(lgd, 'Color', 'none');
            title(ax2, sprintf('%s-%s', wave_mapper_zh(wave), event_id));
            set(ax2, 'TickDir', 'out');
            xlabel(ax2, '时间点');
            ylabel(ax2, ytype_name_zh); if contains(ytype_name, 'time', 'IgnoreCase', true), set(ax2, 'YDir', 'reverse'); end
            % ylabel(ax2, ['差异', replace(ytype_name_zh, '(s)', '(ms)')]);
            % ylabel(ax2, ['相对差异', ytype_name_zh, ' (%)']); set(lgd, 'Location', 'southwest');
            xlim([1, 6]);
            xticks(1:6);
            xticklabels(cellfun(@(x) sprintf('T%d', x-1), num2cell(xticks), 'UniformOutput', false));
        end
    end
end



function [data, xrecvs, xshot] = load_sectout(filepath, refresh, savemat)
% 载入 sectout 数据。如果当前文件有对应的 .mat 文件，可直接载入，否则从 sect.out 文件中解析数据。
%
% refresh: 若为 true，则强制从 sect.out 文件中解析，不使用 .mat 文件。默认为 true。
% savemat: 若为 true，则将解析好的数据保存为 .mat 文件，方便下次直接加载。默认为 true。

    if nargin < 3, savemat = true; end
    if nargin < 2, refresh = true; end

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
%    5.0000        -1
%    0.0000         0
%    0.0125         3
% 0.34946E+01 0.16198E+00 0.28085E+01 2.2
% 0.32571E+01 0.38330E-02 0.31416E+01 3.2
% 0.32722E+01 0.17297E-04 0.00000E+00 4.2
%    0.0250         3
% 0.34866E+01 0.16206E+00 0.28068E+01 2.2
% 0.32506E+01 0.38341E-02 0.31416E+01 3.2
% 0.32656E+01 0.17309E-04 0.00000E+00 4.2
%    0.0375         3
% 0.34786E+01 0.16219E+00 0.28051E+01 2.2
% 0.32440E+01 0.38359E-02 0.31416E+01 3.2
% 0.32591E+01 0.17327E-04 0.00000E+00 4.2
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
