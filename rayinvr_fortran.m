function rayinvr_fortran(command, working_dir)
% rayinvr_fortran(command, working_dir)
%
% Run compiled rayinvr commands(from fortran), including:
%   rayinvr, tramp, vmodel, pltsyn.
%
% The command should be in `PATH`, or the full path is required.

    if nargin < 1
        fprintf('\tArgument "command" is required.\n');
        return;
    else
        if ~exist(command, 'file')
            [status, command_path] = system(sprintf('where "%s"', command));
            if status ~= 0
                fprintf('\tCommand "%s" not found.\n', command);
                return;
            end
            command = strtrim(command_path);
        end
    end

    if nargin < 2
        working_dir = pwd();
    end

    fprintf('\nRunning command:\t%s\nWorking directory:\t%s\n\n', command, working_dir);
    shell_cmd = sprintf('pushd "%s" && %s && popd', working_dir, command);
    system(shell_cmd);
end
