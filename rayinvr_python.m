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
            fprintf('\tInvalid command "%s".\n\tPlease choose one from ["%s"]\n', command, strjoin(valid_commands, '", "'));
            return;
        end
    end

    if nargin < 2
        working_dir = pwd();
    end

    script_dir = fileparts(mfilename('fullpath'));
    script_name = sprintf('interactive_%s.py', command);
    full_command = sprintf('python "%s"', fullfile(script_dir, script_name));
    fprintf('\nRunning command:\t%s\nWorking directory:\t%s\n\n', full_command, working_dir);
    shell_cmd = sprintf('%s %s', full_command, working_dir);
    system(shell_cmd);
end
