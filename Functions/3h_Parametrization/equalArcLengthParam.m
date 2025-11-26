function t_equal = equalArcLengthParam(bezierPts_, numPoints)
    % Bez.: bezierPts_ = [P0; P1; P2] ∈ ℝ³×3 (nur ein Segment!)
    % Rückgabe: t_equal — t-Werte, sodass Punkte gleichabständig auf der Kurve liegen

    % 1. Dichtes Sampling
    t_dense = linspace(0, 1, 1000);
    b0 = (1 - t_dense).^2;
    b1 = 2 * (1 - t_dense) .* t_dense;
    b2 = t_dense.^2;
    x = bezierPts_(1,1) * b0 + bezierPts_(2,1) * b1 + bezierPts_(3,1) * b2;
    y = bezierPts_(1,2) * b0 + bezierPts_(2,2) * b1 + bezierPts_(3,2) * b2;
    z = bezierPts_(1,3) * b0 + bezierPts_(2,3) * b1 + bezierPts_(3,3) * b2;

    % 2. Bogenlänge berechnen
    pts = [x; y; z]';
    diffs = vecnorm(diff(pts), 2, 2);
    arc = [0; cumsum(diffs)];
    arc = arc / arc(end);  % Normierung auf [0,1]

    % 3. Gleichverteilte Bogenlängenpunkte
    targetArc = linspace(0, 1, numPoints);

    % 4. Interpolation: finde t, sodass arc(t) ≈ targetArc
    t_equal = interp1(arc, t_dense, targetArc);
end
