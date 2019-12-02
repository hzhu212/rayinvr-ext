% 解析 rayinvr/rayinvr 生成的 r1_ext.out 文件（射线追踪记录）。
% 进行射线照明分析。

filepath = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\stage_1_100\\p\\r1_ext.out';
% filepath = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\stage_0_005\\p\\r1_ext.out';
[data] = load_rayout(filepath, true);
plot_coverage(data, {}, 2, 0.025);



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


function [events, xturns, xrecvs] = get_ray_coverage(rayout_data)
% 从 ray.out 数据（由 load_rayout 获得的 Table 格式）中取出按事件分组的 xturn 值，用于计算射线覆盖密度
% 返回值：
% events: 一个 cell，包含所有不同的事件编号，例如 {'2.2', '3.2'}
% xturns: 一个与 events 相同长度的 cell，依次是每个事件所对应的所有射线的转折点的 X 坐标
% xrecvs: 一个与 events 相同长度的 cell，依次是每个事件所对应的所有射线的到达点的 X 坐标

    [G, events] = findgroups(rayout_data.code);
    xturns = splitapply(@(x){x}, rayout_data.xturn, G);
    xrecvs = splitapply(@(x){x}, rayout_data.xrecv, G);
end


function plot_coverage(rayout_data, events, survey_len, bin_width)
% 画图展示射线覆盖情况
% 参数：
% events: 一个 cell，限定要绘制的事件代号，如 {2.2, 3.2}。
% survey_len: 限定有效测线长度，测线范围之外的接收点不予统计，默认为 20。
% bin_width: 用于统计的单位线元长度，默认为 0.025km。

    if nargin < 4, bin_width = 0.025; end
    if nargin < 3, survey_len = 20; end
    if nargin < 2, events = {}; end

    mid_point = 10;

    if ~isempty(events) && ~ischar(events{1})
        events = cellfun(@(x) num2str(x), events, 'UniformOutput', false);
    end

    [xmin, xmax] = deal(mid_point - survey_len/2, mid_point + survey_len/2);
    bin_edges = xmin:bin_width:xmax;
    bin_centers = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;
    [event_ids, xturns, xrecvs] = get_ray_coverage(rayout_data);


    fig = figure('Position', [20, 50, 480, 360]);
    ax = axes(fig, 'Position', [0.1,0.12,0.85,0.83]);
    hold on;
    grid on;
    title(sprintf('Survey Length = %.1fkm', survey_len));
    xlabel('Offset (km)');
    ylabel('Frequency');
    for ii = 1:numel(event_ids)
        event = event_ids{ii};
        xturn = xturns{ii};
        xrecv = xrecvs{ii};

        if ~isempty(events) && isempty(find(strcmp(events, event)))
            continue;
        end

        mask = (xrecv >= xmin) & (xrecv <= xmax);
        xturn = xturn(mask);

        % h = histogram(xturn, bin_edges, 'DisplayStyle', 'stairs');
        [counts, ~] = histcounts(xturn, bin_edges);
        plot(bin_centers, counts, 'LineWidth', 1, 'DisplayName', sprintf('Event %s', event));
    end
    hleg = legend('show', 'AutoUpdate', 'off');
    % set(hleg, 'FontSize', 8, 'Location', 'northeast');

    % % obs_pos = 9.5:0.025:10.5;
    % obs_pos = 9.0:0.050:11.0;
    % plot(obs_pos, zeros(size(obs_pos)), 'Color', 'k', 'Marker', 'o', 'MarkerSize', 3);

    hold off;

end
