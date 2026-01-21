function mat = diagcov(vec)
    vec = vec(:);
    mat = vec .* vec';
end
