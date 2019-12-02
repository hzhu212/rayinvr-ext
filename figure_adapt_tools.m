% 热调整 MATLAB 绘制的图像，修改尺寸、坐标轴范围等，供论文使用。

adapt_ray_tracing();
% adapt_wave_analyze();
% adapt_critical_offset_analyze();


function adapt_wave_analyze(size_descriptor)
% 调整波形分析相关图片，包括走时分析、振幅分析、相位分析等

    if nargin < 1, size_descriptor = 'quarter'; end

    event_names = {...
        'time-event2.2(p)';
        'time-event3.2(p)';
        'time-event4.2(p)';
        'time-event2.2(s)';
        'time-event3.2(s)';
        'time-event4.2(s)';
        'amplitude-event2.2(p)';
        'amplitude-event3.2(p)';
        'amplitude-event4.2(p)';
        'amplitude-event2.2(s)';
        'amplitude-event3.2(s)';
        'amplitude-event4.2(s)';
        'time-event2.3(p)';
        'amplitude-event2.3(p)';
    };
    xlimc = {...
        [-1, 1]*0.5;
        [-1, 1]*0.5;
        [-1, 1]*0.5;
        [-1, 1]*0.5;
        [-1, 1]*0.5;
        [-1, 1]*0.5;
        [-1, 1];
        [-1, 1];
        [-1, 1];
        [-1, 1];
        [-1, 1];
        [-1, 1];
        [2.6, 2.7];
        [2.5, 3];
    };
    ylimc = {...
        [1.02, 1.08];
        [1.055, 1.12];
        [1.08, 1.15];
        [1.4, 1.46];
        [1.465, 1.55];
        [1.525, 1.62];
        [0, 0.35];
        [0, 0.18];
        [0, 0.04];
        [0, 12e-5];
        [0, 8e-5];
        [0, 1.8e-5];
        [2, 2.065];
        [0.5, 1];
    };
    ytickc = {...
        []; []; []; []; []; []; []; [];
        0:0.01:0.04;
        []; []; []; []; [];
    };

    all_figures = findobj('Type', 'figure');
    for ii = 1:numel(all_figures)
        fig = all_figures(ii);
        figname = get(fig, 'Name');
        idx = find(strcmp(event_names, figname));
        if isempty(idx)
            continue;
        end

        fun_adapt_size(fig, size_descriptor);
        fun_adapt_font(fig);
        ax = get(fig, 'CurrentAxes');
        xlim(ax, xlimc{idx});
        ylim(ax, ylimc{idx});
        if ~isempty(ytickc{idx})
            yticks(ax, ytickc{idx});
        end
    end
end


function adapt_critical_offset_analyze()
% 调整临界偏移距分析图

    % 原图
    fig = gcf();
    ax = get(fig, 'CurrentAxes');
    fun_adapt_size(fig, 'half');
    fun_adapt_font(fig);
    xlim(ax, [-5, 5]);
    ylim(ax, [1.5, 3.5]);

    % 局部放大图
    fig2 = copyobj(fig, groot);
    ax2 = get(fig2, 'CurrentAxes');
    fun_adapt_font(fig2);
    xlim(ax2, [-2.6, -1.7]);
    ylim(ax2, [1.55, 2.05]);
    set(legend, 'Location', 'northwest');
end


function adapt_ray_tracing()
% 调整由 rayinvr-matlab 生成的射线追踪图

    % 原图
    fig = gcf();
    ax = get(fig, 'CurrentAxes');
    set(ax, 'XAxisLocation', 'top');
    fun_adapt_size(fig, 'half', 'axpos', [0.08,0.04,0.89,0.81]);
    fun_adapt_font(fig);

    set(legend, 'Location', 'northeast');
    set(get(ax, 'XLabel'), 'String', '偏移距 (km)');
    set(get(ax, 'YLabel'), 'String', '深度 (km)');

    xlim(ax, [0, 20]);
    xticks(ax, 0:2:20);
    xticklabels(ax, cellfun(@num2str, num2cell(xticks(ax)-10), 'UniformOutput', false));

    ylim(ax, [0, 1.5]);
    yticks(ax, 0:0.3:1.5);
    yticklabels(ax, cellfun(@num2str, num2cell(yticks(ax)), 'UniformOutput', false));


    % 局部放大图
    fig2 = copyobj(fig, groot);
    ax2 = get(fig2, 'CurrentAxes');
    set(ax2, 'XAxisLocation', 'bottom');
    fun_adapt_size(fig2, 'half');
    fun_adapt_font(fig2);

    set(get(ax2, 'XLabel'), 'String', '偏移距 (m)');
    set(get(ax2, 'YLabel'), 'String', '深度 (m)');

    xlim(ax2, [9.5, 10.5]);
    xticks(ax2, [9.5:0.1:10.5]);
    xticklabels(ax2, cellfun(@num2str, num2cell((xticks(ax2)-10)*1e3), 'UniformOutput', false));

    ylim(ax2, [1.25, 1.49]);
    yticks(ax2, [1.290, 1.410, 1.444, 1.468]);
    yticklabels(ax2, cellfun(@num2str, {1290, 1410, 1444, 1468}, 'UniformOutput', false));
end



function fun_adapt_size(fig, size_descriptor, varargin)
% 调整图片大小，统一图片尺寸
% 可以使用 full, half, quarter 引用预设的图片尺寸。也可以通过 figsize, axpos 两个参数自定义图片尺寸。

    if nargin < 2, size_descriptor = 'full'; end

    switch size_descriptor
        case 'full'
            figsize = [700, 450];
            axpos = [0.08, 0.1, 0.89, 0.86];
        case 'half'
            figsize = [700, 300];
            axpos = [0.08, 0.145, 0.89, 0.81];
        case 'quarter'
            figsize = [500, 350];
            axpos = [0.11, 0.125, 0.85, 0.825];
        otherwise
            error('Invalid size descriptor, should be one of "full", "half" or "quarter"');
    end

    ii = 1;
    while ii < numel(varargin)
        switch varargin{ii}
            case 'figsize'
                figsize = varargin{ii+1};
            case 'axpos'
                axpos = varargin{ii+1};
            otherwise
                ii = ii - 1;
        end
        ii = ii + 2;
    end

    ax = get(fig, 'CurrentAxes');
    set(fig, 'Position', [20, 50, figsize]);
    set(ax, 'Position', axpos);
end


function fun_adapt_font(fig)
% 统一图片上的文字字体与字号

    ax = get(fig, 'CurrentAxes');
    title_obj = get(ax, 'Title');
    xlabel_obj = get(ax, 'XLabel');
    ylabel_obj = get(ax, 'YLabel');

    if ~isempty(title_obj)
        set(title_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 9);
    end
    if ~isempty(xlabel_obj)
        set(xlabel_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
    if ~isempty(ylabel_obj)
        set(ylabel_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
end




