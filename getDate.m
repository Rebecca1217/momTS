function date = getDate(stDate,edDate)

% javaaddpath('E:\sqljdbc4.jar');
conn = database('wind_fsync','query','query','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://10.201.4.164:1433;databaseName=wind_fsync');
% ping(conn)

sql = ['select TRADE_DAYS from CFuturesCalendar where S_INFO_EXCHMARKET= ','''czce''',...
    ' and TRADE_DAYS>=''',num2str(stDate),''' and TRADE_DAYS<=''',num2str(edDate),''' order by TRADE_DAYS'];
cursorA = exec(conn,sql);
cursorB = fetch(cursorA);
date = str2double(cursorB.Data);