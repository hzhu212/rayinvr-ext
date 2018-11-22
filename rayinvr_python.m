function rayinvr_fortran(command, working_dir)
% rayinvr_python(command, working_dir)
%
% Run interactive plotting(by python-plotly). Commands including:
%   rayinvr, pltsyn.

    valid_commands = {'rayinvr', 'pltsyn'};

    if nargin < 1
        fprintf('\tArgument "command" is required.\n');
        return;
    else
        if ~any(strcmp(valid_commands, command))
            fprintf('\tInvalid command "interactive_%s.py".\n\tPlease choose one from ["%s"]\n', command, strjoin(valid_commands, '", "'));
            return;
        end
    end

    if nargin < 2
        working_dir = pwd();
    end

    fprintf('\nRunning command:\t%s\nWorking directory:\t%s\n\n', command, working_dir);
    script_dir = fileparts(mfilename('fullpath'));
    shell_cmd = sprintf('pushd "%s" && python interactive_%s.py %s && popd', script_dir, command, working_dir);
    system(shell_cmd);
end
