% 解析 rayinvr/rayinvr 生成的 r1_ext.out 文件（射线追踪记录）。
% 进行射线照明分析。

global path_template stages layer_depth param_combinations param_combinations_zh;
path_template = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\%s\\%s\\';
stages = {'stage_1_100', 'stage_0_100', 'stage_0_050', 'stage_0_030', 'stage_0_015', 'stage_0_005'};
layer_depth = [1290, 1410, 1444, 1468];
param_combinations = {'10km_obc25m_recv25m', '10km_obc12d5m_recv25m', '10km_obc25m_recv12d5m', '10km_obc12d5m_recv12d5m'};
param_combinations_zh = {'OBC节点间距=25m，炮点距=25m', 'OBC节点间距=12.5m，炮点距=25m', 'OBC节点间距=25m，炮点距=12.5m', 'OBC节点间距=12.5m，炮点距=12.5m'};


% 使用步骤：
% 1. 设置好 r.in、tx.in 等 Rayinvr 配置文件。
% 2. 执行 run_rayinvr_fortran 函数，对所有子项目配置执行 Rayinvr 正演，获得 r1_ext.out 输出文件。
% 3. 执行 plot_multi_lighting_analyze 函数，解析所有子项目中的 r1_ext.out 文件，并绘制一张整合的照明分析图。

% run_rayinvr_fortran({'p'})
plot_multi_lighting_analyze('s', false, 1, 'survey_len', 5, 'bin_width', 0.001);



function [fig] = plot_multi_lighting_analyze(wave, refresh, plottype, varargin)
% 绘制各开采阶段的照明分析图
% plottype：1-正常绘制全图，2-仅绘制云图（位图），3-仅绘制坐标轴及文字标注（矢量图）

    global path_template stages param_combinations param_combinations_zh;

    if nargin < 4, plottype = 1; end
    if nargin < 3, refresh = true; end
    if nargin < 2, filename = 'r1_ext.out'; end
    if nargin < 1, wave = 'p'; end

    opts = struct('survey_len', 5, 'bin_width', 0.025);
    custom_opts = struct(varargin{:});
    names = fieldnames(custom_opts);
    for ii = 1:numel(names)
        opts.(names{ii}) = custom_opts.(names{ii});
    end

    mid_point = 5;
    [xmin, xmax] = deal(mid_point - opts.survey_len/2, mid_point + opts.survey_len/2);
    bin_edges = xmin:opts.bin_width:xmax;

    target_stages = [1, 2, 6];

    fig = figure('Position', [20, 0, 1000, 900], 'NumberTitle', 'off');
    ha = tight_subplot(4, 3, [.035 .015], [.07 .03], [.065 .10]);
    for ii = 1:numel(param_combinations)
        filename = sprintf('r1_ext.%s.out', param_combinations{ii});
        for jj = 1:numel(target_stages)
            stage_idx = target_stages(jj);
            filepath = fullfile(sprintf(path_template, stages{stage_idx}, wave), filename);
            data = load_rayout(filepath, refresh);
            ax = ha((ii-1)*numel(target_stages) + jj);

            if ii == 1 && jj == 1, ilayer = true; else ilayer = false; end
            if jj == 1, iytick = true; else iytick = false; end
            if ii == numel(param_combinations), ixtick = true; else ixtick = false; end
            plot_one_lighting_analysis(ax, data, bin_edges, sprintf('T%d', stage_idx-1), ilayer, ixtick, iytick, plottype);

            if plottype~=2
                if jj == 2
                    subtitle = param_combinations_zh{ii};
                    subtitle = sprintf('(%s) %s', char(96+ii), subtitle);
                    text(ax, 0, 1288, subtitle, 'FontName', 'Microsoft Yahei', 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Interpreter', 'none', 'FontWeight', 'bold');
                end
            end
        end
    end
    if plottype~=2
        % colormap(jet);
        h = colorbar();
        set(h, 'Position', [0.92,0.07,0.035,0.90]);
        ylabel(h, '射线密度 (次/m)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
end


function plot_one_lighting_analysis(ax, data, bin_edges, time_label, ilayer, ixtick, iytick, plottype)
% 根据传入的数据，绘制一副照明分析图

    global layer_depth;

    mid_point = 5;
    xmin = bin_edges(1);
    xmax = bin_edges(end);
    bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

    [event_ids, xturns, ~] = get_ray_coverage(data, [xmin, xmax]);

    axes(ax);
    hold on;
    for ii = 1:numel(event_ids)
        event = event_ids{ii};
        xturn = xturns{ii};

        % 按照小分区统计射线覆盖次数
        [counts, ~] = histcounts(xturn, bin_edges);
        % % 使用滑动平均对数据做平滑处理
        % [counts, ~] = smoothdata(counts, 'movmean', 1);

        x = bin_centers - mid_point;
        layer_no = int32(str2num(event));
        y = layer_depth(layer_no-1:layer_no);
        [xx, yy] = meshgrid(x, y);
        zz = repmat(counts, 2, 1);
        if plottype~=3
            contourf(xx, yy, zz, 100, 'LineStyle', 'none');
        end
    end

    set(ax,'TickLength',[0.02, 0.02]);
    set(ax,'Layer','top');
    set(ax,'TickDir','out');
    set(ax,'Color','none');
    set(ax,'YDir','reverse');
    xlim([-1, 1]);
    ylim([1290, 1468]);
    caxis([0, 20]);

    if plottype == 2
        set(ax, 'Visible', 'off');
        return;
    end

    yticks(layer_depth);

    if ilayer
        for d = layer_depth(2:end-1)
            plot([xmin, xmax]-mid_point, [d, d], 'Color', [1,1,1], 'LineStyle', '--');
        end
        text(-0.95, 1444, 'BSR', 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 9, 'VerticalAlignment', 'bottom');
        text(0.95, 1350, '非储层', 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 9, 'HorizontalAlignment', 'right');
        text(0.95, 1427, '储   层', 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 9, 'HorizontalAlignment', 'right');
        text(0.95, 1456, '含气层', 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 9, 'HorizontalAlignment', 'right');
    end

    if ~isempty(time_label)
        text(-0.95, 1305, time_label, 'Color', [1,1,1], 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end

    if ~ixtick
        % set(ax, 'XTickLabels', []);
        set(ax, 'XTick', []);
    else
        xlabel('偏移距 (km)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end

    if ~iytick
        % set(ax, 'YTickLabels', []);
        set(ax, 'YTick', []);
    else
        ylabel('深度 (m)', 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end

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
