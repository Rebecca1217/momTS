function nextTraday = get_nextTraday(oriDate)
% 提取oriDate的下一个交易日

% 导入全部的交易日
load dateCalendar.mat
stL = find(dateCalendar==oriDate(1),1,'first');
edL = find(dateCalendar>oriDate(end),1,'first');
dateCalendar = dateCalendar(stL:edL); %对应的区间交易日
li = find(ismember(dateCalendar,oriDate))+1; %组合生成日的后一个交易日所在行
nextTraday = dateCalendar(li);
