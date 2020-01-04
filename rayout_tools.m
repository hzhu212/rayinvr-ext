% 解析 rayinvr/rayinvr 生成的 r1_ext.out 文件（射线追踪记录）。
% 进行射线照明分析。

global path_template stages;
path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\';
stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};



% run_rayinvr_fortran({'p', 's'});
% batch_backup_mat('r1_ext.out', 'r1_ext.10km_obc12d5m_recv12d5m.out');
plot_multi_lighting_analyze('p', 'r1_ext.10km_obc12d5m_recv12d5m.out', false, 'survey_len', 5, 'bin_width', 0.001);



function [fig] = plot_multi_lighting_analyze(wave, filename, refresh, varargin)
% 绘制各开采阶段的照明分析图

    global path_template stages;

    if nargin < 3, refresh = true; end
    if nargin < 2, filename = 'r1_ext.out'; end
    if nargin < 1, wave = 'p'; end

    opts = struct('survey_len', 10, 'bin_width', 0.025);
    custom_opts = struct(varargin{:});
    names = fieldnames(custom_opts);
    for ii = 1:numel(names)
        opts.(names{ii}) = custom_opts.(names{ii});
    end

    layer_depth = [1290, 1410, 1444, 1468];

    mid_point = 5;
    [xmin, xmax] = deal(mid_point - opts.survey_len/2, mid_point + opts.survey_len/2);
    bin_edges = xmin:opts.bin_width:xmax;
    bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

    tmp = strsplit(filename, '.');
    title_str_en = tmp{end-1};
    title_mapper = containers.Map(...
        {'10km_obc25m_recv25m', '10km_obc12d5m_recv25m', '10km_obc25m_recv12d5m', '10km_obc12d5m_recv12d5m'}, ...
        {'OBC节点间距25m，炮检距25m', 'OBC节点间距12.5m，炮检距25m', 'OBC节点间距25m，炮检距12.5m', 'OBC节点间距12.5m，炮检距12.5m'});
    if title_mapper.isKey(title_str_en)
        title_str_zh = title_mapper(title_str_en);
    else
        title_str_zh = '未知文件名';
    end

    figname = sprintf('LightingAnalyze-%s', title_str_en);
    fig = figure('Position', [20, 50, 900, 600], 'NumberTitle', 'off', 'Name', figname);
    % % size with title
    % ha = tight_subplot(3, 2, [.085 .08], [.07 .06], [.07 .10]);
    % size without title
    ha = tight_subplot(3, 2, [.085 .08], [.07 .02], [.07 .10]);
    for ii = 1:numel(stages)
        filepath = fullfile(sprintf(path_template, stages{ii}, wave), filename);
        data = load_rayout(filepath, refresh);
        [event_ids, xturns, ~] = get_ray_coverage(data, [xmin, xmax]);

        ax = ha(ii);
        % ax = subplot_tight(3, 2, ii, [0.08, 0.05]);
        axes(ax);

        hold on;
        for jj = 1:numel(event_ids)
            event = event_ids{jj};
            xturn = xturns{jj};

            % 按照小分区统计射线覆盖次数
            [counts, ~] = histcounts(xturn, bin_edges);
            % % 使用滑动平均对数据做平滑处理
            % [counts, ~] = smoothdata(counts, 'movmean', 1);

            x = bin_centers - mid_point;
            layer_no = int32(str2num(event));
            y = layer_depth(layer_no-1:layer_no);
            [xx, yy] = meshgrid(x, y);
            zz = repmat(counts, 2, 1);
            contourf(xx, yy, zz, 100, 'LineStyle', 'none');
        end
        % for d = layer_depth(2:end-1)
        %     plot([xmin, xmax], [d, d], 'Color', 'k', 'LineStyle', '--');
        % end
        hold off;
        % title(sprintf('T%d', ii-1), 'FontName', 'Microsoft Yahei', 'FontSize', 10);
        text(-1.45, 1305, sprintf('T%d', ii-1), 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 10);
        xlabel('偏移距 (km)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
        ylabel('深度 (m)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
        set(ax, 'YDir', 'reverse');
        yticks(layer_depth);
        % xlim([mid_point, xmax] - mid_point);
        xlim([-1.5, 1.5]);
        caxis([0, 20]);
    end
    % colormap(jet);
    h = colorbar();
    % % size without title
    % set(h, 'Position', [0.92,0.07,0.03,0.87]);
    % size with title
    set(h, 'Position', [0.92,0.07,0.03,0.91]);
    ylabel(h, '射线密度 (次/m)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    % mtit(fig, title_str_zh, 'xoff', 0, 'yoff', 0.02, 'Interpreter','none', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
end


function [events, xturns, xrecvs] = get_ray_coverage(rayout_data, xrecv_lim, centered)
% 从 ray.out 数据（由 load_rayout 获得的 Table 格式）中取出按事件分组的 xturn 值，用于计算射线覆盖密度。
% 数据中的接收点坐标遍布整个模型，但在统计时，可以用 xrecv_lim 限定只统计一定范围内的接收点。
% 如果 centered 为 true，则数据在返回之前需要扣除中心点坐标，使得正负对称。默认为 false，即不对数据做任何修改。
% 返回值：
% events: 一个 cell，包含所有不同的事件编号，例如 {'2.2', '3.2'}
% xturns: 一个与 events 相同长度的 cell，依次是每个事件所对应的所有射线的转折点的 X 坐标
% xrecvs: 一个与 events 相同长度的 cell，依次是每个事件所对应的所有射线的到达点的 X 坐标

    if nargin < 3 centered = false; end

    [G, events] = findgroups(rayout_data.code);
    xturns = splitapply(@(x){x}, rayout_data.xturn, G);
    xrecvs = splitapply(@(x){x}, rayout_data.xrecv, G);

    xmin = xrecv_lim(1);
    xmax = xrecv_lim(2);

    for ii = 1:numel(xrecvs)
        mask = (xrecvs{ii} >= xmin) & (xrecvs{ii} <= xmax);
        xrecvs{ii} = xrecvs{ii}(mask);
        xturns{ii} = xturns{ii}(mask);
    end

    if centered
        mid_point = (xmin + xmax) / 2;
        xrecvs = cellfun(@(arr) arr-mid_point, xrecvs, 'UniformOutput', false);
        xturns = cellfun(@(arr) arr-mid_point, xturns, 'UniformOutput', false);
    end
end


function run_rayinvr_fortran(waves)
% 重新生成全部 r1_ext.out 文件，其实是重新调用 rayinvr/rayinvr 模块
    global path_template stages;

    if nargin < 1
        waves = {'p', 's'};
    end

    for ii = 1:numel(stages)
        for jj = 1:numel(waves)
            path = sprintf(path_template, stages{ii}, waves{jj});
            fprintf('================================================================================\n');
            fprintf(">> rayinvr_fortran('rayinvr', '%s')\n", path);
            rayinvr_fortran('rayinvr', path);
        end
    end
end


function batch_backup_mat(from_name, to_name, copy, overwrite)
% 批量备份已经生成的 r1_ext.out 数据。
% 当修改模型之后，如果全部重新生成一遍 r1_ext.out 速度较慢，因此设计该函数批量备份与还原 r1_ext.out 文件，再次使用时不必重新生成，方便多个模型之间做对比。
% 默认为拷贝备份，如将 copy 参数设为 false，则为重命名备份。

    global path_template stages;

    if nargin < 4, overwrite = false; end
    if nargin < 3, copy = true; end

    if strcmp(from_name, to_name)
        error('from_name can not be same with to_name');
    end

    waves = {'p', 's'};
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


function [data] = parse_rayout(filepath)
% 解析 ray.out 文件的数据，返回一个 Table 类型。
% 包含以下列：code, xreceive, time, xturn, zturn

    data = readtable(filepath, 'FileType', 'text', 'Format', '%d%d%f%f%f%f%f%d%s%f%f');
    % 去掉不必要的列
    keep_fields = {'shot', 'code', 'xturn', 'xrecv'};
    data = data(:, keep_fields);
end


function [data] = load_rayout(filepath, refresh, savemat)
% 载入 rayout 数据。如果当前文件有对应的 .mat 文件，可直接载入，否则从 r1_ext.out 文件中解析数据。
%
% refresh: 若为 true，则强制从 r1_ext.out 文件中解析，不使用 .mat 文件。默认为 true。
% savemat: 若为 true，则将解析好的数据保存为 .mat 文件，方便下次直接加载。默认为 true。

    if nargin < 3, savemat = true; end
    if nargin < 2, refresh = true; end

    matfile = [filepath, '.mat'];
    if refresh || ~exist(matfile, 'file')
        is_from_mat = false;
        [data] = parse_rayout(filepath);
    else
        is_from_mat = true;
        obj = load(matfile);
        data = obj.data;
    end

    if savemat && ~is_from_mat
        save(matfile, 'data');
    end
end
