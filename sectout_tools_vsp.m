% 解析和处理 rayinvr/tramp 生成的 sect.out 文件（模拟事件和振幅）
% 与 OBC 模型刚好相反，OBC 只有一个炮点和多个接收点，而 VSP 模型有多个炮点和一个接收点，因此专门针对 VSP 模型创建此脚本

global path_template stages colors layer_depth shots_mapper wave_mapper_zh;
path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\';
stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};
colors = parula(6+2); colors = colors(2:end-1, :);
layer_depth = [1290, 1410, 1444, 1468];
shots_mapper = containers.Map(5+(0:28)*0.0001, 1.291:0.00625:1.468);
wave_mapper_zh = containers.Map({'p', 's'}, {'纵波', '横波'});


% 使用步骤：
% 1. 设置好 r.in、tx.in 等 Rayinvr 配置文件。
% 2. 执行 run_tramp_fortran 函数（指定纵横波或两者），获得 sect_ext.out 输出文件（包含所有事件的走时、振幅、相位等数据）。
% 3. 执行 plot_multi_wave_anylyze 函数，解析 sect_ext.out 文件并绘制走时、振幅、相位等分析图像
% 4. 修改 r.in 参数后，为避免之前已生成的 sect_ext.out 数据被覆盖，可使用 batch_backup_data 函数进行批量备份或重命名，等使用时再改名回来。
% 5. 执行 plot_wavelet 函数，绘制模拟波形

% run_tramp_fortran({'p'});
% batch_backup_data('sect_ext.out', 'sect_ext.vsp.out', {'p'});
% merge_vsp_s_parts();
plot_multi_wave_anylyze('p', 'time', {'3.2','4.2'}, 'refresh', true, 'sectionAt', [19, 21]);
% plot_wavelet('p', 21, {'3.2', '4.2'}, 100);


function [wavelet, dt] = ricker_wavelet(FM, len)
% 生成 ricker 小波波形，FM 为主频率，len 为构造波形的点数
% 参考：https://wiki.seg.org/wiki/Dictionary:Ricker_wavelet

    if nargin < 1, FM=100; end
    if nargin < 2, len=300; end

    TD = sqrt(6) / pi / FM;
    t = linspace(-TD*2, TD*2, len);
    a = pi^2 * FM^2 * t.^2;
    dt = t(2) - t(1);
    wavelet = (1 - 2*a) .* exp(-a);
end


function [hil] = hilbert_impulse(len)
% Impulse response of bandpass Hilbert transform filter

    if nargin < 1, len=121; end
    half = floor(len / 2);
    mid = ceil(len / 2);

    hil = zeros(1, len);
    for ii = 2:2:half
        fudge = ii * 0.00018604 - 0.00037207;
        hil(mid+ii-1) = 0.6366198 / (ii-1) - fudge;
        hil(mid-ii+1) = -hil(mid+ii-1);
    end
end


function [wavelet] = simulate_wavelet(source_wave, amp, phase)
% 按照 Rayinvr/pltsyn 的方法生成模拟波形

    % https://zh.wikipedia.org/wiki/%E5%B8%8C%E7%88%BE%E4%BC%AF%E7%89%B9%E8%BD%89%E6%8F%9B
    % https://zh.wikipedia.org/wiki/File:Bandpass_discrete_Hilbert_transform_filter.tif
    hillen = 121;
    % hil = firpm(hillen,[0.05 0.95],[1 1],'h');
    hil = hilbert_impulse(hillen);

    r = zeros(1, hillen);
    kpos = ceil(hillen / 2);
    r(kpos) = cos(phase) * amp;
    sn = sin(phase) * amp;
    r(2:2:hillen) = -hil(2:2:hillen)*sn;
    s = conv(source_wave, r, 'same');
    wavelet = s;
end


function [] = plot_wavelet(wave, nodeid, events, rickerFM)
% 以 ricker 子波为基础，绘制模拟波形
% wave: 'p' 或 's'
% nodeid: 所要研究的 VSP 节点。19、21 节点分别位于储层顶界面上下侧
% events: 一个 cell，包含一个或多个事件，如 {'3.2', '4.2'}，为空代表所有事件，多个事件的波形会叠加

    global path_template stages colors wave_mapper_zh;

    if nargin < 1, wave = 'p'; end
    if nargin < 2, nodeid = 21; end
    if nargin < 3, events = {}; end
    if nargin < 4, rickerFM = 100; end

    if ~any(strcmp({'p', 's'}, wave))
        error('argument "wave" should be "p" or "s"');
    end

    % 载入数据
    % 同时记录最早和最晚的走时，方便后续生成波形
    data = {};
    [tmin, tmax] = deal(inf, -inf);
    for ii = 1:numel(stages)
        stage = stages{ii};
        base_path = sprintf([path_template, 'sect_ext.out'], stage, wave);
        [sect] = load_sectout(base_path);
        if isempty(events)
            events = sect.keys;
        end

        for jj = 1:numel(events)
            event_id = events{jj};
            if sect.isKey(event_id)
                time = sect(event_id).time(nodeid);
                amp = sect(event_id).amplitude(nodeid);
                phase = sect(event_id).phase(nodeid);
                dd = [time, amp, phase];
                tmin = min(tmin, time);
                tmax = max(tmax, time);
            else
                dd = [];
            end
            data{ii, jj} = dd;
        end
    end

    wavelen = 300;
    [ricker, dt] = ricker_wavelet(rickerFM, wavelen);
    totallen = round((tmax-tmin) / dt) + wavelen;

    fig = figure('NumberTitle', 'off', 'Name', sprintf('wavelet-node%.0f(%s)-FM%.0f-vsp', nodeid, wave, rickerFM));
    ax = axes(fig);
    ax = baldbox(ax);
    hold on;

    [nrow, ncol] = size(data);
    for ii = 1:nrow
        base_wavelet = zeros(1, totallen);
        base_ts = ((1:totallen) - round(wavelen/2)) * dt;

        % 如果有多个事件，则依次叠加
        for jj = 1:ncol
            dd = data{ii, jj};
            if isempty(dd), continue; end
            [time, amp, phase] = deal(dd(1), dd(2), dd(3));
            wavelet = simulate_wavelet(ricker, amp, phase);
            offset = round((time-tmin) / dt) + 1;
            base_wavelet(offset:offset+wavelen-1) = base_wavelet(offset:offset+wavelen-1) + wavelet;
        end

        base_ts = base_ts + tmin;
        curve = plot(ax, base_ts, base_wavelet, '-', 'LineWidth', 1.5, 'Color', colors(ii,:), 'DisplayName', sprintf('T%1d', ii-1));
    end
    hold off;
    grid on;
    lgd = legend(ax, 'show');
    set(lgd, 'Color', 'none');
    title(sprintf('节点%.0f-%s', nodeid, wave_mapper_zh(wave)));
    xlabel(ax, '走时 (s)');
    ylabel(ax, '振幅');
    set(ax, 'TickDir', 'out');
end


function [] = plot_multi_wave_anylyze(wave, ytype, events, varargin)
% 绘制多阶段的走时分析/振幅分析/相位分析图
%
% 位置参数：
% wave: 'p' 或 's'，绘制纵波事件还是横波事件，默认为 'p'。
% ytype: 指定绘制数据的类别，包括走时(time)、振幅(amplitude)、相位(phase)。
% events: 一个 cell，限定要绘制的事件代号，如 {2.2, 3.2}。
% 可选参数：
% refresh: 载入 sect.out 数据时强制重新解析原始数据，否则载入前一次 .mat 文件缓存的数据，速度会稍快。
% sectionAt: 在哪些 offset 处创建纵向切片图。默认不创建切片图。

    global path_template stages colors layer_depth shots_mapper wave_mapper_zh;

    wave_mapper = containers.Map({'p', 's'}, {'P wave', 'S wave'});
    ytype_id_mapper = containers.Map({'time', 'amplitude', 'phase'}, {1, 2, 3});
    ytype_name_mapper = containers.Map({1, 2, 3}, {'Time (s)', 'Amplitude', 'Phase (°)'});
    ytype_name_mapper_zh = containers.Map({1, 2, 3}, {'走时 (s)', '振幅', '相位 (°)'});

    % 处理输入参数默认值
    if nargin < 3, events = {}; end
    if nargin < 2, ytype = 'time'; end
    if nargin < 1, wave = 'p'; end

    opts = struct('refresh', true, 'sectionAt', []);
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
    for ii = 1:numel(stages)
        stage = stages{ii};
        path = sprintf([path_template, 'sect_ext.out'], stage, wave);
        [data] = load_sectout(path, opts.refresh);
        data_s{end+1} = data;
    end

    % plot
    all_events = data_s{1}.keys();
    if ~isempty(events)
        all_events = intersect(all_events, events);
    end
    all_events = sort(all_events);


    for ii = 1:numel(all_events)
        % 用于收集切面数据
        if ~isempty(opts.sectionAt)
            sectionys = cell(size(opts.sectionAt));
        end

        event_id = all_events{ii};
        fig = figure('NumberTitle', 'off', 'Name', sprintf('%s-event%s(%s)-vsp', ytype, event_id, wave));
        ax = axes(fig);
        ax = baldbox(ax);
        hold on;

        for jj = 1:numel(data_s)
            data = data_s{jj};
            if ~data.isKey(event_id)
                continue;
            end
            data = data(event_id);
            ydata = data.(ytype);
            % 绘制相位时，将弧度转化为角度
            if contains(ytype_name, 'phase', 'IgnoreCase', true)
                ydata = ydata / pi * 180;
            end
            zshots = arrayfun(@(k)shots_mapper(k), data.xshot)*1000;
            curve = plot(ax, ydata, zshots, '-o', 'LineWidth', 1, 'Color', colors(jj,:), 'MarkerSize', 3, 'MarkerfaceColor', colors(jj,:), 'DisplayName', sprintf('T%1d', jj-1));

            % 收集切面数据，用于绘制切面图
            section_xshot = 5 + (opts.sectionAt - 1) / 1e4;
            for kk = 1:numel(opts.sectionAt)
                section_idx = find(data.xshot == section_xshot(kk), 1);
                if ~isempty(section_idx)
                    sectionys{kk}(jj) = ydata(section_idx);
                else
                    sectionys{kk}(jj) = NaN;
                end
            end
        end

        hold off;
        set(ax, 'ygrid', 'on');
        % title(sprintf('Event %s', event_id));
        title(sprintf('%s-%s', wave_mapper_zh(wave), event_id));
        yticks(layer_depth);
        set(ax, 'TickDir', 'out');
        set(ax, 'YDir', 'reverse');
        if contains(ytype_name, 'phase', 'IgnoreCase', true)
            ylim(ax, [0, 360]);
        end
        xlabel(ax, ytype_name_zh);
        ylabel(ax, '深度 (m)');
        lgd = legend(ax, 'show');
        set(lgd, 'Color', 'none');

        % 绘制纵向剖面图，包含绝对值与 diff 图
        if ~isempty(opts.sectionAt)
            fig2 = figure('NumberTitle', 'off', 'Name', sprintf('%s-event%s(%s)-section-vsp', ytype,event_id,wave));
            ax2 = baldbox(axes(fig2));
            fig3 = figure('NumberTitle', 'off', 'Name', [get(fig2, 'Name'), '-diff']);
            ax3 = baldbox(axes(fig3));
            hold(ax2, 'on'); hold(ax3, 'on');
            for kk = 1:numel(opts.sectionAt)
                % 绝对量折线图
                plot(ax2, sectionys{kk}, '-o', 'DisplayName', sprintf('节点%.0f', opts.sectionAt(kk)));
                % 差异走时 stem 图
                if ~strcmp(ytype, 'amplitude')
                    stem(ax3, [0, diff(sectionys{kk})]*1e3, 'LineWidth', 1, 'DisplayName', sprintf('节点%.0f', opts.sectionAt(kk)));
                    % 相对差异振幅 stem 图
                else
                    y = sectionys{kk}; stem(ax3, [0, diff(y)./y(1:end-1)]*100, 'LineWidth', 1, 'DisplayName', sprintf('节点%.0f', opts.sectionAt(kk)));
                end
            end
            hold(ax2, 'off'); hold(ax3, 'off');
            lgd2 = legend(ax2, 'show', 'Location', 'Best'); set(lgd2, 'Color', 'none');
            lgd3 = legend(ax3, 'show', 'Location', 'Best'); set(lgd3, 'Color', 'none');
            title(ax2, sprintf('%s-%s', wave_mapper_zh(wave), event_id));
            title(ax3, sprintf('%s-%s', wave_mapper_zh(wave), event_id));
            set(ax2, 'TickDir', 'out'); xlabel(ax2, '时间点');
            set(ax3, 'TickDir', 'out'); xlabel(ax3, '时间点');
            ylabel(ax2, ytype_name_zh); if contains(ytype_name, 'time', 'IgnoreCase', true), set(ax2, 'YDir', 'reverse'); end
            if ~strcmp(ytype, 'amplitude')
                ylabel(ax3, ['差异', replace(ytype_name_zh, '(s)', '(ms)')]);
            else
                ylabel(ax3, ['相对差异', ytype_name_zh, ' (%)']); set(lgd3, 'Location', 'southwest');
            end
            xlim(ax2, [1, 6]); xticks(ax2, 1:6); xticklabels(ax2, cellfun(@(x) sprintf('T%d', x-1), num2cell(xticks), 'UniformOutput', false));
            xlim(ax3, [1, 6]); xticks(ax3, 1:6); xticklabels(ax3, cellfun(@(x) sprintf('T%d', x-1), num2cell(xticks), 'UniformOutput', false));
        end
    end

end


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


function merge_vsp_s_parts(overwrite)
% 由于 VSP 的节点在纵向上跨越了地层界面，无法在 Rayinvr 中一次性计算。
% 对每个地层内部的节点分批进行横波射线追踪，然后将生成的数据合并到单个文件

    global path_template stages;

    if nargin < 1, overwrite = false; end

    for ii = 1:numel(stages)
        base_path = sprintf(path_template, stages{ii}, 's');
        to_name = 'sect_ext.vsp.out';

        if ~overwrite && exist(fullfile(base_path, to_name), 'file')
            answer = questdlg(sprintf('文件名 %s 已存在，是否覆盖？', to_name), '警告', '是', '取消操作', '取消操作');
            overwrite = strcmp(answer, '是');
            if ~overwrite
                fprintf('Operation canceled!\n');
                return;
            end
        end

        filenames = {'sect_ext.vsp.part1.out', 'sect_ext.vsp.part2.out', 'sect_ext.vsp.part3.out'};

        cmd0 = sprintf('pushd "%s" && type %s > %s', base_path, strjoin(filenames, ' '), to_name);
        cmd = ['@echo off && ', cmd0, ' && popd'];
        [status, cmdout] = system(cmd);
        if status == 0, msg = 'OK'; else, msg = 'ERROR'; end
        fprintf('[%s] %s\n', msg, cmd0);
    end
end


function [data] = load_sectout(filepath, refresh, savemat)
% 载入 sectout 数据。如果当前文件有对应的 .mat 文件，可直接载入，否则从 sect.out 文件中解析数据。
%
% refresh: 若为 true，则强制从 sect.out 文件中解析，不使用 .mat 文件。默认为 true。
% savemat: 若为 true，则将解析好的数据保存为 .mat 文件，方便下次直接加载。默认为 true。

    if nargin < 3, savemat = true; end
    if nargin < 2, refresh = true; end

    matfile = [filepath, '.mat'];
    if refresh || ~exist(matfile, 'file')
        is_from_mat = false;
        [data] = parse_sectout(filepath);
    else
        is_from_mat = true;
        obj = load(matfile);
        data = obj.data;
    end

    if savemat && ~is_from_mat
        save(matfile, 'data');
    end
end



function [data] = parse_sectout(filepath)
% 解析 sect.out 文件，返回数据体（containers.Map 类型），每个事件对应的数据放在一个 table 中
%
% 文件内容样例：
%    5.0000        -1
%    4.6000         2
% 0.10934E+01 0.13204E+00 0.31416E+01 3.2
% 0.11217E+01 0.16370E-01 0.00000E+00 4.2
%    5.0001        -1
%    4.6000         2
% 0.10894E+01 0.13233E+00 0.31416E+01 3.2
% 0.11178E+01 0.16411E-01 0.00000E+00 4.2
%    5.0002        -1
%    4.6000         2
% 0.10855E+01 0.13261E+00 0.31416E+01 3.2
% 0.11138E+01 0.16452E-01 0.00000E+00 4.2
%
% 格式含义：
% 1行炮点：<X 坐标>    <-1>
%     1行接收点：<X 坐标>  <事件个数 n>
%         n行事件：<时间>  <振幅>  <相位>  <代号>
%     1行接收点：<X 坐标>  <事件个数 n>
%         n行事件：<时间>  <振幅>  <相位>  <代号>
%     ...

    arr = [];

    fid = fopen(filepath);
    lineno = 0;
    try
        while ~feof(fid)
            lineno = lineno + 1;
            row = sscanf(fgetl(fid), '%10f%10d');

            % shot line
            if row(2) == -1
                xshot = row(1);
                continue;
            end

            % receiver line
            xrecv = row(1);
            n = row(2);

            % event lines
            for ii = 1:n
                lineno = lineno + 1;
                event_row = sscanf(fgetl(fid), '%12f%12f%12f%4f')';
                arr = [arr; [xshot, xrecv, event_row]];
            end
        end
    catch e
        fprintf('*** An error occured while processing line %d of file %s ***\n', lineno, filepath);
        fclose(fid);
        rethrow(e);
    end
    fclose(fid);

    data = containers.Map();
    [G, events] = findgroups(arr(:, 6));
    for ii=1:numel(events)
        event_id = num2str(events(ii));
        selected_arr = arr(G==ii, 1:5);
        column_names = {'xshot', 'xrecv', 'time', 'amplitude', 'phase'};
        data(event_id) = array2table(selected_arr, 'VariableNames', column_names);
    end
end
