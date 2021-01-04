function [Eval,Evec] = CalcDiffusionMapRimDist_SDP(X,epsilonFactor)
    % calculate diffusion map on a matrix of features using
    % rimmanian distance on semi-definite positive matrices.
    % input:
    % X is a matrix of features: each column represents a single 
    % feature for all of the examples.
    % each row contains all the features for a single example.
    % epsilonFactor is a factor that can reduce or enlarge the denominator
    % in the gaussian measure.
    % output:
    % Eval - list of eigen values, sorted by amplitude in descending order.
    % Evec - list of corresponding eigen vectors.

    %% run diffusion map with euclidean distance
    M = sympositivedefinitefactory(size(X,1));
    D = zeros(size(X,1));
    covLen = sqrt(size(X,2));
    for m=1:size(X,1)
        A = reshape(X(m,:),covLen,covLen);
        for n=1:size(X,1)
           % for each row (covariance matrix of a single observation) compute rimmanian distance
           % between other observations.
           B = reshape(X(n,:),covLen,covLen);
           D(m,n) = M.dist(A,B);
        end
    end
    
    %D = RimDistSDP(X,X); % calculate rimmanian distance assuming Symmetric-Positive-Definite matrices
    epsilon = median(D(:))*epsilonFactor;
    K = exp(-(D.^2)/(epsilon.^2)); % create gaussian measure
    D1 = diag(sum(K,2));
    P = D1\K; % inv(D)*K -  normilize each row to sum of 1 (guess it represents probablity)
    [V,S] = eig(P);
    Sdiag = diag(S);
    [Eval, Emap] = sort(Sdiag(2:end),'descend');
    V2 = V(:,2:end);
    Evec = V2(:,Emap);
end

function D = RimDistSDP(X,Y)
    % from manopt toolbox (file sympositivedefinitefactory.m)
    A = real(logm(X\Y));
    Aconj = A';
    B = Aconj(:)'*A(:);
    D = real(sqrt(B));
end