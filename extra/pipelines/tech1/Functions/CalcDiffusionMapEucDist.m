function [Eval,Evec] = CalcDiffusionMapEucDist(X,epsilonFactor,no_dims)
    % calculate diffusion map on a matrix of features using
    % euclidian distance.
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
%     D = zeros(size(X,1));
%     for m=1:size(X,1)
%         for n=1:size(X,1)
%            % for each row (observation) compute euqlidian distance
%            % between other observation
%            D(m,n) = sqrt(sum((X(m,:)-X(n,:)).^2));
%         end
%     end
    D = pdist2(X,X,'euclidean'); % calculate distances
    
    covLen = sqrt(size(X,2));
    M = euclideanfactory(covLen,covLen);
    D1 = zeros(size(X,1));
    for m=1:size(X,1)
        A = reshape(X(m,:),covLen,covLen);
        for n=1:size(X,1)
           % for each row (covariance matrix of a single observation) compute rimmanian distance
           % between other observations.
           B = reshape(X(n,:),covLen,covLen);
           D1(m,n) = M.dist(A,B);
        end
    end    
    
    epsilon = median(D(:))*epsilonFactor;
    K = exp(-(D.^2)/(epsilon.^2)); % create gaussian measure
    D1 = diag(sum(K,2));
    P = D1\K; % inv(D)*K -  normilize each row to sum of 1 (guess it represents probablity)
    [V,S] = eig(P);
    Sdiag = diag(S);
    [Eval, Emap] = sort(Sdiag(2:end),'descend');
    V2 = V(:,2:end);
    Evec = V2(:,Emap);
    %Evec(:,no_dims)*;
    
end

