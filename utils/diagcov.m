function mat = diagcov(vec)
    vec = vec(:);
    % mat = vec .* vec';
    mat = diag(vec.^2);

end
