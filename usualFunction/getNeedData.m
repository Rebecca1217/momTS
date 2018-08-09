function dataN = getNeedData(dataOri,dateBasic,dateST,dateED)
% 从整个面板数据中截出所需时段的面板数据
% 并且给原来的数据加上了日期序列

stL = find(dateBasic==dateST,1,'first');
edL = find(dateBasic==dateED,1,'first');
dataN = [dateBasic(stL:edL),dataOri(stL:edL,:)];
