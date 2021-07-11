% 提取当前打开的所有 figure 内的数据，保存到文件


out_file = '.\\output\\figure_dump.xlsx';

% figure name 到 Excel 文件中 sheet name 的映射表
name_mapper = containers.Map(...
    {
        'time-event3.2(p)';
        'time-event4.2(p)';
        'time-event3.2(p)-section';
        'time-event4.2(p)-section';
        'time-event3.2(p)-section-diff';
        'time-event4.2(p)-section-diff';

        'time-event3.2(s)';
        'time-event4.2(s)';
        'time-event3.2(s)-section';
        'time-event4.2(s)-section';
        'time-event3.2(s)-section-diff';
        'time-event4.2(s)-section-diff';

        'amplitude-event3.2(p)';
        'amplitude-event4.2(p)';
        'amplitude-event3.2(p)-section';
        'amplitude-event4.2(p)-section';
        'amplitude-event3.2(p)-section-diff';
        'amplitude-event4.2(p)-section-diff';

        'amplitude-event3.2(s)';
        'amplitude-event4.2(s)';
        'amplitude-event3.2(s)-section';
        'amplitude-event4.2(s)-section';
        'amplitude-event3.2(s)-section-diff';
        'amplitude-event4.2(s)-section-diff';

        'time-event3.2(p)-xnoise=3.00m';
        'time-event4.2(p)-xnoise=3.00m';
        'time-event3.2(s)-xnoise=6.25m';
        'time-event4.2(s)-xnoise=6.25m';

        'amplitude-event3.2(p)-xnoise=6.25m';
        'amplitude-event4.2(p)-xnoise=6.25m';
        'amplitude-event3.2(s)-xnoise=6.25m';
        'amplitude-event4.2(s)-xnoise=6.25m';
    }, {
        '5(a1)';
        '5(a2)';
        '5(b1)';
        '5(b2)';
        '5(c1)';
        '5(c2)';

        '6(a1)';
        '6(a2)';
        '6(b1)';
        '6(b2)';
        '6(c1)';
        '6(c2)';

        '7(a1)';
        '7(a2)';
        '7(b1)';
        '7(b2)';
        '7(c1)';
        '7(c2)';

        '8(a1)';
        '8(a2)';
        '8(b1)';
        '8(b2)';
        '8(c1)';
        '8(c2)';

        '9(a1)';
        '9(a2)';
        '9(b1)';
        '9(b2)';

        '10(a1)';
        '10(a2)';
        '10(b1)';
        '10(b2)';
    });

% 关闭已知 warning
warning('off', 'MATLAB:xlswrite:AddSheet');

% 将当前正在打开的图片的数据落盘到 Excel 中
all_figures = findobj('Type', 'figure');
all_figures = sortby(all_figures, 'Number');
for ii = 1:numel(all_figures)
    fig = all_figures(ii);
    fprintf('processing figure: %s ...\n', fig.Name);
    if ~name_mapper.isKey(fig.Name)
        warning('unregistered figure name: %s, skip.', fig.Name);
        continue;
    end

    % 提取数据并组成一个二维 cell，准备保存到 Excel
    data = extract_figure_data(fig);
    data = sortby(data, 'Name');
    all_x = cat(2, data.XData);
    all_y = cat(2, data.YData);
    all_name = {};
    for jj = 1:numel(data)
        curve = data(jj);
        all_name = [all_name, repmat({curve.Name}, [1, numel(curve.XData)])];
    end
    all_col = [num2cell(all_x); num2cell(all_y); all_name]';
    all_col = [{'X', 'Y', 'Name'}; all_col];
    sheet_name = name_mapper(fig.Name);
    [ok, msg] = xlswrite(out_file, all_col, sheet_name);
    if ~ok
        error(msg);
    end
    fprintf('finished figure: %s\n', fig.Name);
end


function data = extract_figure_data(fig)
%extract_figure_data - 从 figure 中提取所有 Curve 对应的数据
%
% Syntax: data = extract_figure_data(fig)
%
% 从 figure 中提取所有 Curve 对应的数据，保存成一个数组，其中的每个元素为 struct，包含 XData, YData, Name 字段

    data = [];
    ax = get(fig, 'CurrentAxes');
    for ii = 1:numel(ax.Children)
        curve = ax.Children(ii);
        % if ~strcmp(curve.Visible, 'on')
        %     continue;
        % end
        mask = (curve.XData >= ax.XLim(1)) & (curve.XData <= ax.XLim(2)) & (curve.YData >= ax.YLim(1)) & (curve.YData <= ax.YLim(2));
        obj = struct('XData', curve.XData(mask), 'YData', curve.YData(mask), 'Name', curve.DisplayName);
        data = [data, obj];
    end
end


function result = sortby(structArray, fieldName, reverse)
% sort a structure array by a field

    if nargin < 3, reverse = false; end
    elems = {structArray.(fieldName)};
    if ~isa(elems{1}, 'char')
        elems = cell2mat(elems);
    end
    [~, idx] = sort(elems);
    if reverse
        idx = flip(idx);
    end
    result = structArray(idx);
end
