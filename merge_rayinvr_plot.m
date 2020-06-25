% 将 Rayinvr 正演输出的射线图与走时图合并到一张图上

f1 = hgload('ray.fig');
f2 = hgload('time.fig');
ax1 = findobj(f1, 'type', 'axes');
ax2 = findobj(f2, 'type', 'axes');

fnew = figure();
[ha, pos] = fun_tight_subplot(2, 1, 0.04, [0.1, 0.05], [0.1, 0.06]);
% ha(1) = subplot(2, 1, 1);
% ha(2) = subplot(2, 1, 2);

copyobj(allchild(get(f1,'CurrentAxes')), ha(1));
copyobj(allchild(get(f2,'CurrentAxes')), ha(2));

% title(ha(1), get(f1,'Name'));
% title(ha(2), get(f2,'Name'));

set(ha(1), 'YDir', get(ax1,'YDir'));
set(ha(2), 'YDir', get(ax2,'YDir'));
set(ha(1), 'Box', get(ax1,'Box'));
set(ha(2), 'Box', get(ax2,'Box'));

set(ha(1), 'xlim', get(ax1,'xlim'));
set(ha(1), 'ylim', get(ax1,'ylim'));
set(ha(2), 'xlim', get(ax2,'xlim'));
set(ha(2), 'ylim', get(ax2,'ylim'));

% set(ha(1), 'XMinorTick', 'on');
% set(ha(2), 'XMinorTick', 'on');
xbounds = xlim(ha(1));
set(ha(1), 'XTick', xbounds(1):xbounds(2));
set(ha(2), 'XTick', xbounds(1):xbounds(2));

xlb1 = get(ax1, 'xlabel');
ylb1 = get(ax1, 'ylabel');
xlb2 = get(ax2, 'xlabel');
ylb2 = get(ax2, 'ylabel');

% xlabel(ha(1), get(xlb1,'String'));
xticklabels(ha(1), {});
ylabel(ha(1), get(ylb1,'String'));
xlabel(ha(2), get(xlb2,'String'));
ylabel(ha(2), get(ylb2,'String'));

close(f1);
close(f2);
