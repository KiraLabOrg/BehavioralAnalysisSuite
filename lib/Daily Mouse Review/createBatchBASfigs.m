function createBatchBASfigs()

    init_date = '260424';   % yymmdd
    last_date = today;      % serial date number

    % Convert init_date string to serial date
    start_datenum = datenum(init_date,'yymmdd');

    % Generate full range of serial dates
    date_range = start_datenum:last_date;

    % Convert to cell array of yymmdd strings
    date_str_set = cellstr(datestr(date_range,'yymmdd'));

    % Loop through dates
    for i = 1:length(date_str_set)
        date_str = date_str_set{i};

        fprintf('Processing date %d/%d: %s\n', ...
            i, length(date_str_set), date_str);

        dailyBASfigs(date_str);
    end

end