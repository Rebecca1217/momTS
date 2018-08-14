function dataBasic = getBasicData(fut_variety,FPath,dateBasic,PType)
% 将时序数据整理成面板数据


dataBasic = nan(length(dateBasic),length(fut_variety)); % 定义一个空矩阵（截面的）
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入品种数据
    load([FPath,'\',fut,'.mat'])
    str = ['priceF = futureData.',PType,';'];
    eval(str) %执行文本中的MATLAB表达式
    dateF = futureData.Date;
    priceF = getIntersect(priceF,dateBasic,dateF);
    % 我觉得这个地方很迷。。如果price和date在同一个table里面，直接设置一下date的限制条件就可以
    % 截取出需要的数据了，这里要每列数据都分开，然后再单写一个函数去截取，好麻烦。。。
    % 现在是只有一个date需要截取，如果有几个不同的限制条件呢？
    % 是MATLAB语法只能这样做吗？
    % 可以用table，DT(DT.Var1 > dateST & DT.Var1 <= dateEd, :)这样筛选
    
    %目前的期货数据是两层Struct的格式在存储，相当于三维数据全打散，可以采用的办法是...
    %读出来自己合并成Table后再做后续处理。
    
    % 有没有join函数，这里感觉join 类似data.table的DT1[DT2, on = "Date"]也可以实现。。
    % 可以的，MATLAB里join(A, B)是based on A， 把B的内容join上去...
    % 这里可以用join(dateAim, dataRead)把数据join到目标日期上，然后roll = TRUE就行了
    priceF = getFullTS(priceF);
    % 就是这个函数实现的功能就是data.table join的时候roll = TRUE
    % MATLAB中还没有发现有roll = TRUE这个功能
    dataBasic(:,i_fut) = priceF;
end