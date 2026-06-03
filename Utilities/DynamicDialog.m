function resp = DynamicDialog(fields, vals, varargin)
    %% Set default options
    opts.Title = 'Inputs';
    opts.FieldHeight = 22; % in pixels (single-line row)
    opts.LabelWidth = 200; % in pixels (wider so labels are not clipped)
    opts.LabelSpace = 8; % in pixels
    opts.FieldWidth = 320; % in pixels
    opts.FieldMargin = 10; % in pixels
    opts.BorderMargin = 15; % in pixels
    opts.ButtonWidth = 50; % in pixels
    opts.ButtonHeight = 25; % in pixels
    opts.BottomLeftPosition = [300 300];
    opts.MaxMultilineLines = 8; % cap height for multiline char fields

    for i = 1:2:length(varargin)
        if ~isfield(opts, varargin{i}), error('''%s'' is an unknown option.', varargin{i}); end
        try
            opts.(varargin{i}) = varargin{i+1};
        catch err
            fprintf('Couldn''t set option %s.\n', varargin{i});
            rethrow(err);
        end
    end

    %% Parse the inputs
    num_fields = length(fields);

    % Initialize our response from the values passed
    resp = vals;

    % Now loop through the provided fields
    for cur_field = 1:length(fields)
        % Test if there is a value provided, then copy if it exists
        if isfield(vals, fields(cur_field).Name)
            fields(cur_field).CurValue = vals.(fields(cur_field).Name);
        else
            fields(cur_field).CurValue = [];
        end

        % Initialize the response matrix
        resp.(fields(cur_field).Name) = fields(cur_field).CurValue;
    end

    %% Row heights (multiline char fields need Max>Min on edit + extra height)
    row_heights = dynamicDialogRowHeights(fields, opts);

    %% Create the dialog
    full_width = (2*opts.BorderMargin + opts.LabelWidth + opts.FieldWidth + opts.LabelSpace);
    content_h = sum(row_heights) + max(0, num_fields - 1) * opts.FieldMargin;
    full_height = opts.BorderMargin + opts.ButtonHeight + opts.FieldMargin + content_h + opts.BorderMargin;

    dlg = dialog('Position', [opts.BottomLeftPosition(1) opts.BottomLeftPosition(2) full_width full_height], ...
        'Name', opts.Title, 'WindowStyle', 'modal', 'CloseRequestFcn', @cancel_button);
    dlgColor = get(dlg, 'Color');

    fld_lbl = gobjects(1, num_fields);
    fld_inp = gobjects(1, num_fields);

    %% Loop through the fields
    acc = opts.BorderMargin;
    for cur_field = 1:num_fields
        h = row_heights(cur_field);
        acc = acc + h;
        field_y_pos = full_height - acc;
        label_x_pos = opts.BorderMargin;
        inp_x_pos = label_x_pos + opts.LabelWidth + opts.LabelSpace;

        % Create label
        if ~isfield(fields(cur_field), 'Label') || isempty(fields(cur_field).Label)
            cur_fld_lbl = fields(cur_field).Name;
        else
            cur_fld_lbl = fields(cur_field).Label;
        end
        fld_lbl(cur_field) = uicontrol('Parent', dlg, ...
            'Style', 'text', ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', dlgColor, ...
            'ForegroundColor', [0.1 0.1 0.1], ...
            'Position', [label_x_pos field_y_pos opts.LabelWidth h], ...
            'String', cur_fld_lbl);

        % Determine if the field should be editable
        if isfield(fields(cur_field), 'Editable') && fields(cur_field).Editable
            enable_status = 'on'; % Editable
        else
            enable_status = 'off'; % Non-editable
        end

        % Create field input based on type
        if strcmpi(fields(cur_field).Type, 'char')
            % Test whether values is set
            if ~isempty(fields(cur_field).Values)
                % Use a popup dialog
                cur_value = find(strcmpi(fields(cur_field).Values, fields(cur_field).CurValue), 1, 'first');
                if isempty(cur_value), cur_value = 1; end
                fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                    'Style', 'popup', ...
                    'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                    'String', fields(cur_field).Values, ...
                    'UserData', fields(cur_field).CurValue, ...
                    'Value', cur_value, ...
                    'Enable', enable_status, ...
                    'Callback', @popup_callback);
            else
                % Free-text char: use multiline edit when value has line breaks (Max>Min)
                sChar = dynamicDialogCharValue(fields(cur_field).CurValue);
                useMulti = dynamicDialogCharIsMultiline(sChar, fields(cur_field));
                if useMulti
                    fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                        'Style', 'edit', ...
                        'Min', 0, ...
                        'Max', 2, ...
                        'HorizontalAlignment', 'left', ...
                        'BackgroundColor', [1 1 1], ...
                        'ForegroundColor', [0 0 0], ...
                        'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                        'UserData', sChar, ...
                        'String', sChar, ...
                        'Enable', enable_status, ...
                        'Callback', @edit_callback);
                else
                    fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                        'Style', 'edit', ...
                        'HorizontalAlignment', 'left', ...
                        'BackgroundColor', [1 1 1], ...
                        'ForegroundColor', [0 0 0], ...
                        'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                        'UserData', sChar, ...
                        'String', sChar, ...
                        'Enable', enable_status, ...
                        'Callback', @edit_callback);
                end
            end
        elseif strcmpi(fields(cur_field).Type, 'scalar')
            % Test whether values is set
            if ~isempty(fields(cur_field).Values)
                % Use a popup dialog
                str = cell(length(fields(cur_field).Values), 1);
                for i = 1:length(fields(cur_field).Values), str{i} = num2str(fields(cur_field).Values(i)); end
                cur_value = find(fields(cur_field).Values == fields(cur_field).CurValue, 1, 'first');
                if isempty(cur_value), cur_value = 1; end
                fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                    'Style', 'popup', ...
                    'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                    'String', str, ...
                    'UserData', num2str(fields(cur_field).CurValue), ...
                    'Value', cur_value, ...
                    'Enable', enable_status, ...
                    'Callback', @popup_callback);
            else
                % Use a standard edit text dialog
                fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                    'Style', 'edit', ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', [1 1 1], ...
                    'ForegroundColor', [0 0 0], ...
                    'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                    'UserData', num2str(fields(cur_field).CurValue), ...
                    'String', num2str(fields(cur_field).CurValue), ...
                    'Enable', enable_status, ...
                    'Callback', @edit_callback);
            end
        elseif strcmpi(fields(cur_field).Type, 'vector')
            % Use a standard edit text dialog
            fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [1 1 1], ...
                'ForegroundColor', [0 0 0], ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                'UserData', sprintf('[ %s ]', num2str(fields(cur_field).CurValue(:)')), ...
                'String', sprintf('[ %s ]', num2str(fields(cur_field).CurValue(:)')), ...
                'Enable', enable_status, ...
                'Callback', @edit_callback);
        elseif strcmpi(fields(cur_field).Type, 'boolean')
            % Use a checkbox
            fld_inp(cur_field) = uicontrol('Parent', dlg, ...
                'Style', 'checkbox', ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth h], ...
                'UserData', fields(cur_field).CurValue, ...
                'String', '', ...
                'Value', fields(cur_field).CurValue, ...
                'Enable', enable_status, ...
                'Callback', @checkbox_callback);
        end
    end

    % Create buttons
    uicontrol('Parent', dlg, ...
        'Position', [(full_width - 2*opts.ButtonWidth - opts.FieldMargin - opts.BorderMargin) opts.BorderMargin opts.ButtonWidth opts.ButtonHeight], ...
        'String', 'OK', ...
        'Callback', @ok_button);

    uicontrol('Parent', dlg, ...
        'Position', [(full_width - opts.ButtonWidth - opts.BorderMargin) opts.BorderMargin opts.ButtonWidth opts.ButtonHeight], ...
        'String', 'Cancel', ...
        'Callback', @cancel_button);

    % Wait for d to close before running to completion
    uiwait(dlg);

    %% Callback Functions
    function popup_callback(hObject, ~)
        idx = hObject.Value;
        popup_items = hObject.String;
        hObject.UserData = char(popup_items(idx, :));
    end

    function edit_callback(hObject, ~)
        s = hObject.String;
        if iscell(s)
            s = sprintf('%s\n', s{:});
        end
        hObject.UserData = char(s);
    end

    function checkbox_callback(hObject, ~)
        hObject.UserData = logical(hObject.Value);
    end

    function ok_button(~, ~)
        all_ok = true;
        temp_resp = resp;
        for cur_inp = 1:length(fld_inp)
            if ~isgraphics(fld_inp(cur_inp))
                continue
            end
            if strcmp(fld_inp(cur_inp).Style, 'edit')
                ud = fld_inp(cur_inp).String;
                if iscell(ud)
                    ud = sprintf('%s\n', ud{:});
                end
                ud = char(ud);
            else
                ud = fld_inp(cur_inp).UserData;
            end

            % Parse non-character strings
            if strcmpi(fields(cur_inp).Type, 'char')
                temp_resp.(fields(cur_inp).Name) = dynamicDialogCharValue(ud);
            elseif strcmpi(fields(cur_inp).Type, 'scalar')
                try
                    temp_resp.(fields(cur_inp).Name) = str2num(ud); %#ok<ST2NM>
                    if isempty(temp_resp.(fields(cur_inp).Name)) && ~isempty(ud)
                        error('str2num could not parse number.');
                    end
                catch err
                    all_ok = false;
                    fprintf('Couldn''t assign ''%s'' with value: %s.\n', fields(cur_inp).Name, ud);
                    rethrow(err);
                end
            elseif strcmpi(fields(cur_inp).Type, 'vector')
                try
                    userdata_parsed = regexpi(ud, '\[(.+)\]', 'tokens');
                    if length(userdata_parsed) ~= 1, error('Bad input.'); end
                    userdata_parsed = strtrim(userdata_parsed{1}{1});
                    temp_resp.(fields(cur_inp).Name) = str2num(ud); %#ok<ST2NM>
                    if isempty(temp_resp.(fields(cur_inp).Name)) && ~isempty(userdata_parsed)
                        error('str2num could not parse number.');
                    end
                catch err
                    all_ok = false;
                    fprintf('Couldn''t assign ''%s'' with value: %s.\n', fields(cur_inp).Name, ud);
                    rethrow(err);
                end
            else
                temp_resp.(fields(cur_inp).Name) = ud;
            end
        end

        if all_ok
            resp = temp_resp;
            delete(dlg);
        end
    end

    function cancel_button(~, ~)
        resp = [];
        delete(dlg);
    end
end

function heights = dynamicDialogRowHeights(fields, opts)
num_fields = numel(fields);
heights = repmat(opts.FieldHeight, 1, num_fields);
for k = 1:num_fields
    if ~strcmpi(fields(k).Type, 'char') || ~isempty(fields(k).Values)
        continue
    end
    sChar = dynamicDialogCharValue(fields(k).CurValue);
    if ~dynamicDialogCharIsMultiline(sChar, fields(k))
        continue
    end
    nLines = max(2, min(opts.MaxMultilineLines, numel(strsplit(sChar, '\n'))));
    heights(k) = max(opts.FieldHeight, nLines * (opts.FieldHeight - 2));
end
end

function tf = dynamicDialogCharIsMultiline(s, fieldStruct)
tf = false;
if nargin >= 2 && isstruct(fieldStruct) && isfield(fieldStruct, 'Name')
    switch fieldStruct.Name
        case {'flex_stim_definition', 'flex_sequence_definition'}
            tf = true;
            return
    end
end
if nargin >= 2 && isstruct(fieldStruct) && isfield(fieldStruct, 'Multiline') ...
        && ~isempty(fieldStruct.Multiline) && logical(fieldStruct.Multiline)
    tf = true;
    return
end
if isempty(s) || ~ischar(s)
    return
end
s = dynamicDialogNormalizeCharRow(s);
if size(s, 1) ~= 1
    tf = true;
    return
end
tf = ~isempty(regexp(s, '\n|\r', 'once'));
end

function c = dynamicDialogCharValue(v)
if isempty(v)
    c = '';
    return
end
if isstring(v)
    if isscalar(v)
        c = char(v);
    else
        c = char(strjoin(v(:), newline));
    end
    return
end
if iscell(v)
    if isempty(v)
        c = '';
        return
    end
    c = char(strjoin(cellfun(@char, v, 'UniformOutput', false), newline));
    return
end
if ischar(v)
    if size(v, 1) > 1
        c = char(strjoin(cellstr(v), newline));
    else
        c = v;
    end
    return
end
c = char(string(v));
c = dynamicDialogNormalizeCharRow(c);
end

function s = dynamicDialogNormalizeCharRow(x)
if isempty(x)
    s = '';
    return
end
if isstring(x)
    if isscalar(x)
        s = char(x);
    else
        s = char(strjoin(x(:), newline));
    end
elseif ischar(x)
    if size(x, 1) > 1
        s = char(strjoin(cellstr(x), newline));
    elseif size(x, 2) > 1
        s = x;
    else
        s = x.';
    end
else
    s = char(string(x));
end
if size(s, 1) > 1
    s = char(strjoin(cellstr(s), newline));
end
end
