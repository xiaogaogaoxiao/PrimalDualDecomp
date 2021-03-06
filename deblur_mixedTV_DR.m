function [xPlus_x,costs] = deblur_mixedTV_DR(b,kernel,Ks,params)
               
% This code corresponds to section 5.2 in the paper
% "Image deblurring by primal-dual operator splitting." 
% We solve minimize || Kx - b||_1 + gamma*|| Dx ||_{iso}
% subject to  0 <= x <= 1
% K = Kp + Ks. D = Dp + Ds.
% D uses symmetric BCs.

% In this code primal and dual step sizes are handled as follows:
% the operator A gets multiplied by beta, and g is replaced by
% gTilde, as in p. 7 of the paper.  
% With these modifications to the objective function,
% we then use Douglas-Rachford with the single step size t.

maxIter = params.maxIter;
t = params.t; % primal step size
s = params.s;
gamma = params.gamma;
showTrigger = params.showTrigger;
overRelax = params.overRelax; % called rho in paper.

beta = sqrt(s/t);

evalIsoNorm = @(y) sum(sum(sqrt(y(:,:,1).^2 + y(:,:,2).^2)));

[numRows,numCols] = size(b);
numPix = numRows*numCols;

Ks = beta*Ks;
kernel = beta*kernel;

eigValArr_Kp = eigValArrForCyclicConvOp(kernel,numRows,numCols);
eigValArr_KpTrans = conj(eigValArr_Kp);

applyKp = @(x) applyCyclicConv2D(x,eigValArr_Kp);
applyKpTrans = @(x) applyCyclicConv2D(x,eigValArr_KpTrans);

applyKs = @(x) reshape(Ks*x(:),numRows,numCols);
applyKsTrans = @(x) reshape(Ks'*x(:),numRows,numCols);

applyK = @(x) applyKp(x) + applyKs(x);
applyKTrans = @(x) applyKpTrans(x) + applyKsTrans(x);

eigValArr_Dp1 = eigValArrForCyclicConvOp(beta*[-1 1]',numRows,numCols);
eigValArr_Dp2 = eigValArrForCyclicConvOp(beta*[-1 1],numRows,numCols);

eigValArr_Dp1Trans = conj(eigValArr_Dp1);
eigValArr_Dp2Trans = conj(eigValArr_Dp2);

applyDp1 = @(x) applyCyclicConv2D(x,eigValArr_Dp1);
applyDp1Trans = @(x) applyCyclicConv2D(x,eigValArr_Dp1Trans);
applyDp2 = @(x) applyCyclicConv2D(x,eigValArr_Dp2);
applyDp2Trans = @(x) applyCyclicConv2D(x,eigValArr_Dp2Trans);

applyDp = @(x) cat(3,applyDp1(x),applyDp2(x));
applyDpTrans = @(y) applyDp1Trans(y(:,:,1)) + applyDp2Trans(y(:,:,2));

[Ds1,Ds2] = makeSparseGradRemainderMatrices(numRows,numCols);
Ds1 = beta*Ds1;
Ds2 = beta*Ds2;
applyDs1 = @(x) reshape(Ds1*x(:),numRows,numCols);
applyDs1Trans = @(x) reshape(Ds1'*x(:),numRows,numCols);
applyDs2 = @(x) reshape(Ds2*x(:),numRows,numCols);
applyDs2Trans = @(x) reshape(Ds2'*x(:),numRows,numCols);

applyDs = @(x) cat(3,applyDs1(x),applyDs2(x));
applyDsTrans = @(y) applyDs1Trans(y(:,:,1)) + applyDs2Trans(y(:,:,2));

applyD = @(x) applyDp(x) + applyDs(x);
applyDTrans = @(y) applyDpTrans(y) + applyDsTrans(y);

applyB = @(x) cat(3,applyKp(x),applyDp(x));
applyBTrans = @(y) applyKpTrans(y(:,:,1)) + applyDpTrans(y(:,:,2:end));

applyC = @(x) cat(3,applyKs(x),applyDs(x));
applyCTrans = @(y) applyKsTrans(y(:,:,1)) + applyDsTrans(y(:,:,2:end));

applyA = @(x) cat(3,applyK(x),applyD(x));
applyATrans = @(y) applyKTrans(y(:,:,1)) + applyDTrans(y(:,:,2:end));

applyMtrx = @(x) x + (t^2)*(applyKpTrans(applyKp(x)) + applyDpTrans(applyDp(x)));
eigValsMtrx = (t^2)*(eigValArr_KpTrans.*eigValArr_Kp + eigValArr_Dp1Trans.*eigValArr_Dp1 + eigValArr_Dp2Trans.*eigValArr_Dp2)  ...
                + ones(numRows,numCols);

sparseMtrx = (1 + t^2)*speye(numPix) + ((t^2)/(1 + t^2))*(Ks'*Ks + Ds1'*Ds1 + Ds2'*Ds2);

[U,statusInfo,perm] = chol(sparseMtrx,'vector');
UTrans = U';
permInv(perm) = 1:numPix;

p_x = b;
p_y = applyA(b);
p_z = zeros(size(p_y));
p_w = zeros(size(p_x));

costs = [];
figure('Name','xPlus_x inside DR')

for n = 1:maxIter      
        
    rhs = p_x - t*applyBTrans(p_z);
    xPlus_x = ifft2(fft2(rhs)./eigValsMtrx);        
        
    xPlus_z = p_z + t*applyB(xPlus_x);      
    
    xPlus_y1 = beta*(b + prox1Norm(p_y(:,:,1)/beta - b,t/beta^2));
    xPlus_y2 = proxIsoNorm(gamma*t/beta,p_y(:,:,2:end));
    xPlus_y = cat(3,xPlus_y1,xPlus_y2);     
    
    prox = min(p_w/t,1);
    prox = max(prox,0);
    
    xPlus_w = p_w - t*prox;     
    
    xHat = 2*xPlus_x - p_x;
    yHat = 2*xPlus_y - p_y;
    zHat = 2*xPlus_z - p_z;
    wHat = 2*xPlus_w - p_w;   
    
    rhs2 = xHat - t*wHat - (t/(1 + t^2))*applyCTrans(zHat - t*yHat); 
    rhs2 = rhs2(:);   
        
    temp = UTrans\rhs2(perm);    
    w = U\temp;    
    yPlus_x = w(permInv);
    yPlus_x = reshape(yPlus_x,[numRows,numCols]);
    
    yPlus_z = (zHat - t*yHat + t*applyC(yPlus_x))/(1 + t^2);
    
    yPlus_y = yHat + t*yPlus_z;
    yPlus_w = wHat + t*yPlus_x;
    
    pPlus_x = p_x + overRelax*(yPlus_x - xPlus_x);
    pPlus_y = p_y + overRelax*(yPlus_y - xPlus_y);
    pPlus_z = p_z + overRelax*(yPlus_z - xPlus_z);
    pPlus_w = p_w + overRelax*(yPlus_w - xPlus_w);        
    
    p_x = pPlus_x;
    p_y = pPlus_y;
    p_z = pPlus_z;
    p_w = pPlus_w;        

    xFeas = min(xPlus_x,1);
    xFeas = max(xFeas,0);  
    xFeas = xFeas/beta;
    Dx = applyD(xFeas);
    KxMinusb = applyK(xFeas) - b;
    primalCost = sum(abs(KxMinusb(:))) + gamma*evalIsoNorm(Dx);
    
    costs = [costs,primalCost];         
                    
    if mod(n,showTrigger) == 0         
        imshow(xPlus_x,[])    
        disp(['Douglas-Rachford iteration is: ',num2str(n)])
        disp(['primal cost is: ',num2str(primalCost)])         
        keyboard        
    end             
    
end


end