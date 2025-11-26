function [pts] = denormalize(pts, original_bbox)
    % Berechne den Skalierungsfaktor
    s = 1.6 / max(original_bbox(4:6) - original_bbox(1:3));
    
    % Rückskalierung der Punktwolke
    pts = pts / s;
    
    % Berechne den Schwerpunkt der ursprünglichen Bounding Box
    c = (original_bbox(4:6) + original_bbox(1:3)) * 0.5;
    
    % Rückverschiebung der Punktwolke
    pts = pts + repmat(c, size(pts, 1), 1);
end