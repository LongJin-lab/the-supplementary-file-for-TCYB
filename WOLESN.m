% ��ջ�������
clear
%% ����ṹ����
%��ȡ����
data = load('MackeyGlass_t200.txt');
% data = load('JXB4.csv');
% data = load('flower.txt');
% data = load('test.txt');
% data = load('sunspot.txt');
% plot(data(1:500));
[data,ps]=mapminmax(data',-1,1);
data=data';
%�ڵ����
inSize = 1;
outSize = 1;

%% �Ŵ��㷨������ʼ��
maxgen=50;                         %��������������������
sizepop=10;                        %��Ⱥ��ģ
pcross=[0.4];                       %�������ѡ��0��1֮��
pmutation=[0.2];                    %�������ѡ��0��1֮��

%�ڵ�����
% numsum=inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum;
numsum=2;
lenchrom=ones(1,numsum);                       %���峤��
% bound=[-3*ones(numsum,1) 3*ones(numsum,1)];    %���巶Χ
bound=zeros(2,2);
bound(1,1)=10;
bound(1,2)=250;
bound(2,1)=0;
bound(2,2)=1;

individuals=struct('fitness',zeros(1,sizepop), 'chrom',[]);  %����Ⱥ��Ϣ����Ϊһ���ṹ��
avgfitness=[];                      %ÿһ����Ⱥ��ƽ����Ӧ��
bestfitness=[];                     %ÿһ����Ⱥ�������Ӧ��
bestchrom=[];                       %��Ӧ����õ�Ⱦɫ��
%���������Ӧ��ֵ
for i=1:sizepop
    %�������һ����Ⱥ
    individuals.chrom(i,:)=Code(lenchrom,bound);    %���루binary��grey�ı�����Ϊһ��ʵ����float�ı�����Ϊһ��ʵ��������
    x=individuals.chrom(i,:);
    %������Ӧ��    
    individuals.fitness(i)=fun(x,inSize,outSize,data);   %Ⱦɫ�����Ӧ��
end
FitRecord=[];
%����õ�Ⱦɫ��
[bestfitness bestindex]=min(individuals.fitness);
bestchrom=individuals.chrom(bestindex,:);  %��õ�Ⱦɫ��
avgfitness=sum(individuals.fitness)/sizepop; %Ⱦɫ���ƽ����Ӧ��
%��¼ÿһ����������õ���Ӧ�Ⱥ�ƽ����Ӧ��
trace=[avgfitness bestfitness]; 

%% ���������ѳ�ʼ��ֵ��Ȩֵ
% ������ʼ
for i=1:maxgen  
    % ѡ��
    individuals=Select(individuals,sizepop); 
    avgfitness=sum(individuals.fitness)/sizepop;
    %����
    individuals.chrom=Cross(pcross,lenchrom,individuals.chrom,sizepop,bound);
    % ����
    individuals.chrom=Mutation(pmutation,lenchrom,individuals.chrom,sizepop,i,maxgen,bound);
    
    % ������Ӧ�� 
    for j=1:sizepop
        x=individuals.chrom(j,:); %����
        individuals.fitness(j)=fun(x,inSize,outSize,data);   
    end
    
    %�ҵ���С�������Ӧ�ȵ�Ⱦɫ�弰��������Ⱥ�е�λ��
    [newbestfitness,newbestindex]=min(individuals.fitness);
    [worestfitness,worestindex]=max(individuals.fitness);
    
    %���Ÿ������
    if bestfitness>newbestfitness
        bestfitness=newbestfitness;
        bestchrom=individuals.chrom(newbestindex,:);
    end
    individuals.chrom(worestindex,:)=bestchrom;
    individuals.fitness(worestindex)=bestfitness;
    
    %��¼ÿһ����������õ���Ӧ�Ⱥ�ƽ����Ӧ��
    avgfitness=sum(individuals.fitness)/sizepop;
    trace=[trace;avgfitness bestfitness]; 
    FitRecord=[FitRecord;individuals.fitness];
end

%% �����Ŵ洢�سߴ磬�װ뾶��������Ԥ��
% %���Ŵ��㷨�Ż���ESN�������ֵԤ��
resSize=round(x(1,1));
SP=x(1,2);
%����ѵ��
cleanout=100;
initial=500;%����ǰcleanout�������ڳ�ʼ������
a = 1; % leaking rate
Block=500;
TrainingData=round(0.8*numel(data));
testLen=numel(data)-TrainingData;
% rand( 'seed', 4555555555 );
Win = -0.5+rand(resSize,inSize);
W = -0.5+rand(resSize,resSize);
opt.disp = 0;
rhoW = abs(eigs(W,1,'LM',opt));
W = W .* (SP/rhoW);%��1��ʼ����������ȡֵ ���ѡȡ������ʵ��

% allocated memory for the design (collected states) matrix
X = zeros(inSize+resSize,initial-cleanout);
XX=zeros(inSize+resSize,TrainingData-cleanout);
% set the corresponding target matrix directly
YTrain_initial = data(cleanout+1:initial)';
YTrain_T = data(cleanout+1:TrainingData)';
YTtest_T = data(TrainingData+1:TrainingData+testLen)';

% run the reservoir with the data and collect X
x = zeros(resSize,1);
for t = 1:initial
    u = data(t);
    x = (1-a)*x + a*tanh( Win*[u] + W*x );
    if t > cleanout
        X(:,t-cleanout) = [u;x];
    end
end

% train the output
X=X';
XX(:,1:initial-cleanout)=X';
M = pinv(X' * X); %M=P P=(K)_1 K=H'*H
beta = pinv(X) * YTrain_initial';

%%%%%%%%%%%%% step 2 Sequential Learning Phase
j=0;
for n = initial : Block : TrainingData
    j=j+1;
    if (n+Block-1) > TrainingData
        Pn = data(n:TrainingData,:);
        Tn = data(n+1:TrainingData+1,:);
        Block = size(Pn,1);             %%%% correct the block size
        %%%% correct the first dimention of V
    else
        Pn = data(n:(n+Block-1),:);
        Tn = data(n+1:(n+Block-1)+1,:);
    end
    size(Pn,1);
    for t = n:n+size(Pn,1)-1
        aa=size(Pn,1);
        u = data(t);
        Xb = zeros(inSize+resSize,size(Pn,1));
        x = (1-a)*x + a*tanh( Win*[u] + W*x );
        Xb(:,t-n+1) = [u;x];
        
    end
    XX(:,initial-cleanout+1+(j-1)*size(Pn,1):initial-cleanout+(j)*size(Pn,1))=Xb;
    Xb=Xb';
    %eye(n)����һ�����Խ���Ԫ��Ϊ 1 ������λ��Ԫ��Ϊ 0 �� n��n ��λ����
    M = M - M * (Xb)' * (eye(Block) + Xb * M * (Xb)')^(-1) * Xb * M;
    %     beta = beta + (Tn - beta * (Xb)')* (Xb) * M;
    beta = beta + M * (Xb)'* (Tn - Xb * beta);
end
%disp( ['time = ', num2str( toc )] );
%ѵ�����
Y_Train=XX' * beta;
% run the trained ESN in a generative mode. no need to initialize here,
% because x is initialized with training data and we continue from there.
Y_Test = zeros(outSize,testLen);
u = data(TrainingData+1);
for t = 1:testLen
    x = (1-a)*x + a*tanh( Win*[u] + W*x );
    y = beta'*[u;x];
    Y_Test(:,t) = y;
    % generative mode:
    % %     u = y;
    % this would be a predictive mode:
    if(TrainingData+t+1>size(data))
        break;
    else
        u = data(TrainingData+t+1);
    end
end

TestErrorLen = testLen;
mse = sum((Y_Test-YTtest_T).^2)./TestErrorLen;
ave=mean(YTtest_T);
nrmse = sqrt(sum((Y_Test-YTtest_T).^2)./sum((YTtest_T-ave).^2));
mae = mean(abs(Y_Test-YTtest_T));
disp( ['MSE = ', num2str( mse )] );
disp( ['MAE = ', num2str( mae )] );
disp( ['NRMSE = ', num2str( nrmse )] );
disp( ['reSize = ', num2str( resSize )] );
disp( ['SP = ', num2str( SP )] );
