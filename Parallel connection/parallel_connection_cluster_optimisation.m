%optimizing spring clusters that are set to fail
%cluster is nothing but any combination of springs connected between two
%nodes
%this project addresses complex arrangements of springs

%==========================================================================
%information of the structure
%All springs here have same physical properties %assumption
%==========================================================================
k = 0;%stiffness of a single spring
e = 0;%number of elements
n = 0;%number of nodes
ele_node = [];%matrix of node numbering for elements from 1 to e
Ke = zeros(e, 1) + k;%initialising matrix to store element stiffness equal to k each
K = zeros(n);%initialising the global stiffness matrix
F_known = [];%matrix of nodal forces %0 values are unknowns %nan are known but equal to zero
F_zero = [];%matrix of zero nodal forces is known %non-zero values are either unknown forces or externally applied ones
U = [];%matrix of nodal displacements %NaN values are unknown
Fe = zeros(e, 1);%initilising matrix to store elemental force
Ue = zeros(e, 2);%initialising the elemental displacements for each element
umax = 0;%maximum elastic deformation of a spring
n_spring = 0;%number of extra springs available %in case of unlimited springs input a large number

%assembling the global stiffness matrix K
for i = 1:e
    ke_temp = SpringElementStiffness(Ke(i));
    K = SpringAssemble(K, ke_temp, ele_node(i, 1), ele_node(i, 2));
end

%setting values for the temporary force vector for gaussian elimination
index_fknown = find(F_known);
index_fzero = find(~F_zero);
ftemp_len = length(index_fknown);
f_temp = zeros(ftemp_len, 1);
var = 1;%variable for loop
for i = 1:n
    if F_known(i)~=0 && F_zero(i)~=0
        f_temp(var) = F_known(i);
        var = var+1;
    elseif F_known(i)~=0 && F_zero(i)==0
        f_temp(var) = 0;
        var = var+1;
    end
end

%setting values for the temporary stiffness matrix for gaussian elimination
index_unknown_displacements = find(U);
k_temp = zeros(length(index_unknown_displacements), length(index_fknown));
for i = 1:length(index_unknown_displacements)
    for j = 1:length(index_fknown)
        k_temp(i, j) = K(index_unknown_displacements(i), index_fknown(j));
    end
end

u_temp = k_temp\f_temp;%gaussian elimination

%creating global displacement vector
for i = 1:length(u_temp)
    U(index_unknown_displacements(i)) = u_temp(i);
end

F = K*U;%global force vector

%calculating and assigning the spring elemental forces
for i = 1:e
    Ue(i, 1) = U(ele_node(i, 1));
    Ue(i, 2) = U(ele_node(i, 2));
    ue = [Ue(i, 1); Ue(i, 2)];
    fe_temp = SpringElementForces(K(i), ue);
    Fe(i) = fe_temp(2);
end

%check to see if the strain on a spring is more than the maximum limit
U_check = Ue(:, 2) - Ue(:, 1);
U_check = find(U_check>umax);

%performing operation in a single index %write code to modify ine point
%check the whole configuration again and so on
iteration = 0;

%optimising the spring stiffness for where the structure fails
ele_index = U_check(1);
uneed = Fe(ele_index)/k(ele_index);
new_ele_config = OptimiseSeriesSpringElements(umax, uneed, k, n_spring);%new configuration

%the nuw element is the series connection of the elements added plus the
%element present before
k_old_ele = SpringElementStiffness(Ke(ele_index));
k_new_ele = SpringElementStiffness(new_ele_config(1));
Ke(ele_index) = new_ele_config(1);
K = K-SpringAssemble(zeros(n), k_old_ele, ele_node(ele_index, 1), ele_node(ele_index, 2));
K = SpringAssemble(K, k_new_ele, ele_node(ele_index, 1), ele_node(ele_index, 2));

n_spring = n_spring - (new_ele_config(2)-1);%minus one because the function
                                            %returns the total spring
                                            %elements required consedring
                                            %zero elements initially %but
                                            %we already have one in the
                                            %start
                                            %additional one spring is added
                                            %for tolerance
                                            
%run the simulation in a loop until the whole is optimised

%==========================================================================

%==========================================================================