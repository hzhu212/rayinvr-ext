function [new_ax] = baldbox(ax)
% 改进的 box on，显示 box 但不显示顶部和右侧 ticks

    set(ax, 'box', 'on', 'xtick', [], 'ytick', []);
    new_ax = axes('Position', get(ax,'Position'), 'box', 'off', 'color', 'none');
    linkaxes([ax, new_ax]);
    axes(new_ax);
end
