function GroupList = getGroupList(OriList,GroupNo)
% �������תΪ�ֲַ���

GroupList = cell(size(OriList,1),2);
GroupList(:,2) = OriList(:,2);
for d = 1:size(OriList,1)
    tmpList = OriList{d,1};
    if isempty(tmpList)
        continue;
    end
    tmpList(cell2mat(tmpList(:,2))~=GroupNo,:) = [];
    tmpList(:,2) = num2cell(ones(size(tmpList,1),1));
    GroupList{d,1} = tmpList;
end
       
