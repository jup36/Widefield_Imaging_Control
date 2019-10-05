function resp = DynamicDialog(fields, vals, varargin)
%% Set default options
opts.Title = 'Inputs';
opts.FieldHeight = 20; %in pixels
opts.LabelWidth = 120; %in pixels
opts.LabelSpace = 5; %in pixels
opts.FieldWidth = 120; %in pixels
opts.FieldMargin = 10; %in pixels
opts.BorderMargin = 15; %in pixels
opts.ButtonWidth = 50; %in pixels
opts.ButtonHeight = 25; %in pixels
opts.BottomLeftPosition = [300 300];

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

%Initialize our response from the values passed
resp = vals;

%Now loop through the provided fields
for cur_field = 1:length(fields)
    %Test if there is a value provided, then copy if it exists
    if isfield(vals, fields(cur_field).Name)
        fields(cur_field).CurValue = vals.(fields(cur_field).Name);
    else
        fields(cur_field).CurValue = [];
    end
    
    %Check to see if there are any constraints on the inputs
    fields(cur_field).TypeConstraint = [];
    parse_exp = regexpi(fields(cur_field).Type, '(vector)\.*(\d)*', 'tokens');
    if ~isempty(parse_exp) && ~isempty(parse_exp{1}{2})
        fields(cur_field).TypeConstraint = str2double(parse_exp{1}{2});
        fields(cur_field).Type = parse_exp{1}{1};
    end
    
    %Initialize the response matrix
    resp.(fields(cur_field).Name) = fields(cur_field).CurValue;
end
%% Create the dialog

full_width = (2*opts.BorderMargin + opts.LabelWidth + opts.FieldWidth + opts.LabelSpace);
full_height = (2*opts.BorderMargin + num_fields*(opts.FieldHeight + opts.FieldMargin) + opts.ButtonHeight);

dlg = dialog('Position', [opts.BottomLeftPosition(1) opts.BottomLeftPosition(2) full_width full_height], 'Name', opts.Title, 'WindowStyle', 'modal', 'CloseRequestFcn', @cancel_button);

%% Loop through the fields
for cur_field = 1:num_fields
    field_y_pos = full_height - (opts.BorderMargin + (cur_field - 1)*(opts.FieldMargin + opts.FieldHeight) + opts.FieldHeight);
    label_x_pos = opts.BorderMargin;
    inp_x_pos = label_x_pos + opts.LabelWidth + opts.LabelSpace;
    
    %Create label
    if ~isfield(fields, 'Label') || isempty(fields(cur_field).Label)
        cur_fld_lbl = fields(cur_field).Name;
    else
        cur_fld_lbl = fields(cur_field).Label;
    end    
    fld_lbl(cur_field) = uicontrol('Parent', dlg,...
        'Style', 'text',...
        'HorizontalAlignment', 'right', ...
        'Position', [label_x_pos field_y_pos opts.LabelWidth opts.FieldHeight], ...
        'String', cur_fld_lbl);
    
    %Create field
    if strcmpi(fields(cur_field).Type, 'char')
        %Test whether values is set
        if ~isempty(fields(cur_field).Values)
            %Then use a popup dialog
            cur_value = find(strcmpi(fields(cur_field).Values, fields(cur_field).CurValue), 1, 'first');
            if isempty(cur_value), cur_value = 1; end
            fld_inp(cur_field) = uicontrol('Parent', dlg,...
                'Style', 'popup', ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
                'String', fields(cur_field).Values, ...
                'UserData', fields(cur_field).CurValue, ...
                'Value', cur_value, ...
                'Callback', @popup_callback);
        else
            %Then use a standard edit text dialog
            fld_inp(cur_field) = uicontrol('Parent', dlg,...
                'Style', 'edit', ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
                'UserData', fields(cur_field).CurValue, ...
                'String', fields(cur_field).CurValue, ...
                'Callback', @edit_callback);
        end
    elseif strcmpi(fields(cur_field).Type, 'scalar')
        %Test whether values is set
        if ~isempty(fields(cur_field).Values)
            %Then use a popup dialog
            str = cell(length(fields(cur_field).Values), 1);
            for i = 1:length(fields(cur_field).Values), str{i} = num2str(fields(cur_field).Values(i)); end
            cur_value = find(fields(cur_field).Values == fields(cur_field).CurValue, 1, 'first');
            if isempty(cur_value), cur_value = 1; end
            fld_inp(cur_field) = uicontrol('Parent', dlg,...
                'Style', 'popup', ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
                'String', str, ...
                'UserData', num2str(fields(cur_field).CurValue), ...
                'Value', cur_value, ...
                'Callback', @popup_callback);
        else
            %Then use a standard edit text dialog
            fld_inp(cur_field) = uicontrol('Parent', dlg,...
                'Style', 'edit', ...
                'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
                'UserData', num2str(fields(cur_field).CurValue), ...
                'String', num2str(fields(cur_field).CurValue), ...
                'Callback', @edit_callback);
        end
    elseif strcmpi(fields(cur_field).Type, 'vector')
        %Use a standard edit text dialog
        fld_inp(cur_field) = uicontrol('Parent', dlg,...
            'Style', 'edit', ...
            'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
            'UserData', sprintf('[ %s ]', num2str(fields(cur_field).CurValue(:)')), ...
            'String', sprintf('[ %s ]', num2str(fields(cur_field).CurValue(:)')), ...
            'Callback', @edit_callback);
    elseif strcmpi(fields(cur_field).Type, 'boolean')
        %Use a checkbox
        fld_inp(cur_field) = uicontrol('Parent', dlg,...
            'Style', 'checkbox', ...
            'Position', [inp_x_pos field_y_pos opts.FieldWidth opts.FieldHeight], ...
            'UserData', fields(cur_field).CurValue, ...
            'String', '', ...
            'Value', fields(cur_field).CurValue, ...
            'Callback', @checkbox_callback);
    end
    
end

%Create buttons
ok_btn = uicontrol('Parent',dlg,...
    'Position', [(full_width - 2*opts.ButtonWidth - opts.FieldMargin - opts.BorderMargin) opts.BorderMargin opts.ButtonWidth opts.ButtonHeight], ...
    'String', 'OK', ...
    'Callback', @ok_button);

cancel_btn = uicontrol('Parent', dlg,...
    'Position', [(full_width - opts.ButtonWidth - opts.BorderMargin) opts.BorderMargin opts.ButtonWidth opts.ButtonHeight], ...
    'String', 'Cancel', ...
    'Callback', @cancel_button);

% Wait for d to close before running to completion
uiwait(dlg);

    function popup_callback(hObject, event)
        idx = hObject.Value;
        popup_items = hObject.String;
        hObject.UserData = char(popup_items(idx,:));
    end

    function edit_callback(hObject, event)
        hObject.UserData = hObject.String;
    end

    function ok_button(hObject, event)
        all_ok = true;
        temp_resp = resp;
        for cur_inp = 1:length(fld_inp)
            %Set the value to the user data (which is always updated)
            temp_resp.(fields(cur_inp).Name) = fld_inp(cur_inp).UserData;
            
            %Parse non-character strings
            if strcmpi(fields(cur_inp).Type, 'scalar') 
                try
                    %Make conversion, use str2num for better error handling
                    temp_resp.(fields(cur_inp).Name) = str2num(fld_inp(cur_inp).UserData);
                    if isempty(temp_resp.(fields(cur_inp).Name)) && ~isempty(fld_inp(cur_inp).UserData)
                        error('str2num could not parse number.');
                    end
                catch err
                    all_ok = false;
                    fprintf('Couldn''t assign ''%s'' with value: %s.\n', fields(cur_inp).Name, fld_inp(cur_inp).UserData);
                    rethrow(err);
                end       
            elseif strcmpi(fields(cur_inp).Type, 'vector')
                try
                    %Make sure it is in a valid vector format
                    if (fld_inp(cur_inp).UserData(1) ~= '[') || (fld_inp(cur_inp).UserData(end) ~= ']'), error('Vector inputs must be surrounded by brackets.'); end
                    userdata_parsed = regexpi(fld_inp(cur_inp).UserData, '\[(.+)\]', 'tokens');
                    %Make sure there are is a vector (and not multiple vectors)
                    if length(userdata_parsed) ~= 1, error('Bad input.'); end
                    %Trim off any white spaces
                    userdata_parsed = strtrim(userdata_parsed{1}{1});                    
                    %Make conversion, use str2num for better error handling
                    temp_resp.(fields(cur_inp).Name) = str2num(fld_inp(cur_inp).UserData);
                    if isempty(temp_resp.(fields(cur_inp).Name)) && ~isempty(userdata_parsed)
                        error('str2num could not parse number.');
                    end
                    %Check any length constraint
                    if ~isempty(fields(cur_inp).TypeConstraint)
                        if length(temp_resp.(fields(cur_inp).Name)) ~= fields(cur_inp).TypeConstraint
                            error('The length of %s was not correct (expected to be %d).', fields(cur_inp).Name, fields(cur_inp).TypeConstraint);
                        end
                    end
                catch err
                    all_ok = false;
                    fprintf('Couldn''t assign ''%s'' with value: %s.\n', fields(cur_inp).Name, fld_inp(cur_inp).UserData);
                    rethrow(err);
                end
            end
        end %input loop
        
        %If all are okay, copy over to our output structure and exit
        if all_ok
            resp = temp_resp;
            delete(dlg);
        end
    end

    function cancel_button(hObject, event)
        resp = [];
        delete(dlg);        
    end

end

