% 生成模拟 tx.in 数据，其中走时列无效，只是让 rayinvr 程序能够跑起来而已

% receiver parameters
[xmin, xmax] = deal(0, 20);
xinc = 0.025;

% shot parameters
xshots = [10.000];
% xshots = [9.500, 10.000, 10.500];
% xshots = 9:0.025:11;
% xshots = 10 + (0:20)*0.0001;

% output parameters
line_format = '%10.4f%10.4f%10.4f%10d\n';
out_file = 'D:\\Archive\\Research\\rayinvr\\rayinvr-data\\obc\\tx.in';


xrecvs = xmin:xinc:xmax;
% 默认输出到当前脚本目录下的 tx.in 文件中
if isempty(out_file)
    [curdir, ~, ~] = fileparts(mfilename('fullpath'));
    out_file = fullfile(curdir, 'output', 'tx.in');
end



fid = fopen(out_file, 'w');
for ii = 1:numel(xshots)
    xshot = xshots(ii);
    left_idx = (xrecvs < xshot);
    left_part = xrecvs(left_idx);
    right_part = xrecvs(~left_idx);
    left_data = [left_part; zeros(size(left_part)); ones(size(left_part)) * 0.02; ones(size(left_part))];
    right_data = [right_part; zeros(size(right_part)); ones(size(right_part)) * 0.02; ones(size(right_part))];
    fprintf(fid, line_format, xshot, -1, 0, 0);
    fprintf(fid, line_format, left_data);
    fprintf(fid, line_format, xshot, 1, 0, 0);
    fprintf(fid, line_format, right_data);
end
fprintf(fid, line_format, 0, 0, 0, -1);
fclose(fid);
