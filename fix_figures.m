% 热调整 MATLAB 绘制的图像，修改尺寸、坐标轴范围等，供论文使用。

% adapt_ray_tracing();
% adapt_ray_tracing3_2();
adapt_wave_analyze('quarter');
% adapt_critical_offset_analyze();
% adapt_critical_offset_ray();


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

        'time-event2.3(p)';
        'amplitude-event2.3(p)';

        'time-event3.2(p)-section';
        'time-event4.2(p)-section';
        'time-event3.2(p)-section-diff';
        'time-event4.2(p)-section-diff';

        'time-event3.2(s)-section';
        'time-event4.2(s)-section';
        'time-event3.2(s)-section-diff';
        'time-event4.2(s)-section-diff';

        'amplitude-event2.2(p)';
        'amplitude-event3.2(p)';
        'amplitude-event4.2(p)';

        'amplitude-event3.2(p)-section';
        'amplitude-event4.2(p)-section';
        'amplitude-event3.2(p)-section-diff';
        'amplitude-event4.2(p)-section-diff';

        'amplitude-event2.2(s)';
        'amplitude-event3.2(s)';
        'amplitude-event4.2(s)';

        'amplitude-event3.2(s)-section';
        'amplitude-event4.2(s)-section';
        'amplitude-event3.2(s)-section-diff';
        'amplitude-event4.2(s)-section-diff';
        % 30
        'time-event3.2(p)-vsp';
        'time-event4.2(p)-vsp';
        'time-event3.2(p)-section-vsp';
        'time-event4.2(p)-section-vsp';
        'time-event3.2(p)-section-vsp-diff';
        'time-event4.2(p)-section-vsp-diff';

        'time-event3.2(s)-vsp';
        'time-event4.2(s)-vsp';
        'time-event3.2(s)-section-vsp';
        'time-event4.2(s)-section-vsp';
        'time-event3.2(s)-section-vsp-diff';
        'time-event4.2(s)-section-vsp-diff';

        'amplitude-event3.2(p)-vsp';
        'amplitude-event4.2(p)-vsp';
        'amplitude-event3.2(p)-section-vsp';
        'amplitude-event4.2(p)-section-vsp';
        'amplitude-event3.2(p)-section-vsp-diff';
        'amplitude-event4.2(p)-section-vsp-diff';

        'amplitude-event3.2(s)-vsp';
        'amplitude-event4.2(s)-vsp';
        'amplitude-event3.2(s)-section-vsp';
        'amplitude-event4.2(s)-section-vsp';
        'amplitude-event3.2(s)-section-vsp-diff';
        'amplitude-event4.2(s)-section-vsp-diff';
        % 54
        'wavelet-node21(p)-FM100-vsp';
        'wavelet-node21(p)-FM50-vsp';
        'wavelet-node21(p)-FM75-vsp';
        'wavelet-node21(s)-FM100-vsp';
        'wavelet-node21(s)-FM50-vsp';
    };
    xlimc = {...
        % time
        [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5;
        % 2.3
        [2.6, 2.7]; [2.5, 3];
        % time-section
        []; []; []; [];
        []; []; []; [];
        % amp-p
        [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5;
        % amp-section-p
        []; []; []; [];
        % amp-s
        [-1, 1]*0.5; [-1, 1]*0.5; [-1, 1]*0.5;
        % amp-section-s
        []; []; []; [];
        % vsp-time
        [1.02, 1.13]; [1.04, 1.16]; []; []; []; [];
        [1.00, 1.60]; [1.00, 1.65]; []; []; []; [];
        % vsp-amp
        [0, 0.20]; [0, 0.05]; []; []; []; [];
        [0, 0.035]; [0, 7e-3]; []; []; []; [];
        % vsp-wavelet
        [1.026, 1.086]; [1.015, 1.095]; [1.022, 1.09];
        [1.052, 1.17]; [1.04, 1.18];
    };
    ylimc = {...
        % time
        [1.02, 1.08]; [1.055, 1.12]; [1.08, 1.15]; [1.4, 1.46]; [1.455, 1.55]; [1.52, 1.62];
        % 2.3
        [2, 2.065]; [0.5, 1];
        % time-section
        [1.06, 1.09]; [1.085, 1.12]; [-2, 4]; [-3, 4];
        [1.46, 1.52]; [1.52, 1.59]; [-5, 15]; [-5, 20];
        % amp-p
        [0, 0.35]; [0, 0.26]; [0, 0.06];
        % amp-section-p
        [0, 0.2]; [0, 0.04]; [-60, 0]; [-100, 100];
        % amp-s
        [0, 12e-5]; [0, 8e-5]; [0, 1.8e-5];
        % amp-section-s
        [0, 5e-5]; [0, 1e-5]; [-65, 0]; [-100, 200];
        % vsp-time
        [1285, 1470]; [1285, 1470]; [1.04, 1.055]; [1.066, 1.082]; [-3, 5]; [-4, 5];
        [1285, 1470]; [1285, 1470]; [1.06, 1.14]; [1.12, 1.20]; [-2, 14]; [-2, 16];
        % vsp-amp
        [1285, 1470]; [1285, 1470]; [0, 0.20]; [0, 0.05]; [-60, 0]; [-80, 120];
        [1285, 1470]; [1285, 1470]; [0, 0.035]; [0, 7e-3]; [-70, 0]; [-100, 200];
        % vsp-wavelet
        [-0.2, 0.2]; [-0.2, 0.2]; [-0.2, 0.2];
        [-0.033, 0.033]; [-0.033, 0.033];
    };
    ytickc = {...
        % time
        []; []; []; []; []; [];
        % 2.3
        []; [];
        % time-section
        1.06:0.01:1.09; 1.08:0.01:1.12; []; [];
        [];[];[];[];
        % amp-p
        []; []; [];
        % amp-section-p
        [];0:0.01:0.04;[];[];
        % amp-s
        []; []; [];
        % amp-section-s
        [];[];[];[];
        % vsp-time
        [];[];[1.04:0.01:1.05];[1.06:0.01:1.08];[];[];
        [];[];[1.06:0.02:1.14];[1.12:0.02:1.20];[];[];
        % vsp-amp
        [];[];[];[];[];[];
        [];[];[0:0.01:0.04];[];[];[];
        % vsp-wavelet
        []; []; [];
        []; [];
    };

    legend_loc_config = containers.Map(...
        {22; 23; 29; 30; 46; 53; 54; 55; 56; 57; 58; 59}, {...
            'southwest';
            'southwest';
            'southwest';
            'northeast';
            'southwest';
            'southwest';
            'northeast';
            'northeast';
            'northeast';
            'northeast';
            'northeast';
            'northeast';
        });

    axpos_config = containers.Map(...
        {31; 32; 37; 38; 43; 44; 49; 50;}, {...
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.14, 0.83, 0.80];
        [0.132, 0.145, 0.825, 0.80];
        [0.132, 0.145, 0.825, 0.80];
        });

    all_figures = findobj('Type', 'figure');
    for ii = 1:numel(all_figures)
        % 找到目标图片
        fig = all_figures(ii);
        figname = get(fig, 'Name');
        if ~(startsWith(figname, 'time-') || startsWith(figname, 'amplitude-') || startsWith(figname, 'wavelet-'))
            continue;
        end

        fun_adapt_size(fig, size_descriptor);
        fun_adapt_font(fig);
        ax = get(fig, 'CurrentAxes');

        % 生成中文标题
        if contains(figname, 'event')
            tmp = strsplit(figname, '-');
            event_desc = tmp{2};
            wave = event_desc(end-1);
            event_id = event_desc(end-5:end-3);
            new_title_str = fun_get_event_description(wave, event_id);
            set(get(ax, 'Title'), 'String', new_title_str);
        end

        % 需要特殊修整的图片
        idx = find(strcmp(event_names, figname));
        if isempty(idx)
            continue;
        end

        % 修整坐标系尺寸
        if axpos_config.isKey(idx)
            fun_adapt_size(fig, size_descriptor, 'axpos', axpos_config(idx));
        end

        % 修整坐标轴范围
        if ~isempty(xlimc{idx})
            xlim(ax, xlimc{idx});
        end
        if ~isempty(ylimc{idx})
            ylim(ax, ylimc{idx});
        end
        if ~isempty(ytickc{idx})
            yticks(ax, ytickc{idx});
        end
        if legend_loc_config.isKey(idx)
            legend(ax, 'Location', legend_loc_config(idx));
        else
            % 自适应图例位置
            legend(ax, 'Location', 'Best');
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


function adapt_critical_offset_ray()
% 调整临界偏移距射线追踪图，展示临界偏移距随时间的变化

    all_figures = findobj('Type', 'figure');
    for ii = 1:numel(all_figures)
        fig = all_figures(ii);
        ax = get(fig, 'CurrentAxes');
        set(get(ax, 'XLabel'), 'String', '偏移距 (km)');
        set(get(ax, 'YLabel'), 'String', '深度 (km)');
        fun_adapt_size(fig, 'half', 'axpos', [0.08,0.04,0.89,0.81]);
        fun_adapt_font(fig);
        xlim(ax, [4, 6]);
        ylim(ax, [1.25, 1.48]);
    end
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

    xlim(ax, [0, 10]);
    xticks(ax, 0:10);
    xticklabels(ax, cellfun(@num2str, num2cell(xticks(ax)-5), 'UniformOutput', false));

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

    xlim(ax2, [4.5, 5.5]);
    xticks(ax2, 4.5:0.1:5.5);
    xticklabels(ax2, cellfun(@num2str, num2cell((xticks(ax2)-5)*1e3), 'UniformOutput', false));

    ylim(ax2, [1.25, 1.49]);
    yticks(ax2, [1.290, 1.410, 1.444, 1.468]);
    yticklabels(ax2, cellfun(@num2str, {1290, 1410, 1444, 1468}, 'UniformOutput', false));
end


function adapt_ray_tracing3_2()
% 调整由 rayinvr-matlab 生成的射线追踪图，演示照明分析

    % 原图
    fig = gcf();
    ax = get(fig, 'CurrentAxes');
    fun_adapt_size(fig, 'full', 'figsize', [700, 400], 'axpos', [0.08,0.04,0.90,0.85]);
    fun_adapt_font(fig);

    legend(ax, 'off');
    set(get(ax, 'XLabel'), 'String', '偏移距 (km)');
    set(get(ax, 'YLabel'), 'String', '深度 (km)');

    xlim(ax, [4.5, 5.5]);
    xticks(ax, 4.5:0.1:5.5);
    xticklabels(ax, cellfun(@num2str, num2cell(xticks(ax)-5), 'UniformOutput', false));

    ylim(ax, [1.26, 1.47]);
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
            % figsize = [700, 300];
            % axpos = [0.08, 0.14, 0.89, 0.80];
            figsize = [700, 360];
            axpos = [0.09, 0.14, 0.89, 0.80];
        case 'quarter'
            figsize = [446, 320];
            axpos = [0.125, 0.14, 0.85, 0.80];
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

    set(fig, 'Position', [20, 50, figsize]);
    % ax = get(fig, 'CurrentAxes');
    for ax = findall(fig, 'Type', 'Axes')
        set(ax, 'Position', axpos);
    end
end


function fun_adapt_font(fig)
% 统一图片上的文字字体与字号

    ax = get(fig, 'CurrentAxes');
    title_obj = get(ax, 'Title');
    xlabel_obj = get(ax, 'XLabel');
    ylabel_obj = get(ax, 'YLabel');
    legend_obj = get(ax, 'Legend');

    if ~isempty(title_obj)
        set(title_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
    if ~isempty(xlabel_obj)
        set(xlabel_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
    if ~isempty(ylabel_obj)
        set(ylabel_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 10);
    end
    if ~isempty(legend_obj)
        set(legend_obj, 'FontName', 'Microsoft Yahei', 'FontSize', 9);
    end
end


function [desc] = fun_get_event_description(wave, event_id)
% 生成某个地震事件的中文描述，可用做图片标题等

    wave_mapper = containers.Map({'p', 's'}, {'纵波', '横波'});
    event_mapper = containers.Map(...
        {'2.2'; '3.2'; '4.2'; '2.3'},...
        {'储层顶部反射'; '储层底部反射'; '含气层底部反射'; '储层顶部滑行'});

    if ~wave_mapper.isKey(wave)
        error('Invalid argument wave, should be one of ["%s"]', strjoin(wave_mapper.keys(), '", "'));
    end
    if ~event_mapper.isKey(event_id)
        error('Invalid argument wave, should be one of ["%s"]', strjoin(event_mapper.keys(), '", "'));
    end

    desc = sprintf('%s-%s(%s)', wave_mapper(wave), event_id, event_mapper(event_id));
end
