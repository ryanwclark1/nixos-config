.pragma library

// Shared line-graph painter for Canvas elements.
// Options (all optional):
//   yScale       – vertical multiplier (default 1.0; SystemGraphs uses 0.8 for headroom)
//   fill         – whether to draw gradient fill (default true; NetworkGraphs uses false)
//   fillAlphaTop – gradient top opacity  (default 0.3)
//   fillAlphaBot – gradient bottom opacity (default 0.0)
//
// `withAlpha` must be passed in because .pragma library cannot access QML singletons.

function paintLineGraph(canvas, data, strokeColor, withAlpha, options) {
    if (!data.length || canvas.width <= 0 || canvas.height <= 0)
        return;

    var ctx = canvas.getContext("2d");
    ctx.reset();
    var w = data.length > 1 ? canvas.width / (data.length - 1) : canvas.width;
    var yScale = (options && options.yScale !== undefined) ? options.yScale : 1.0;

    // Gradient fill
    if (!options || options.fill !== false) {
        var topA = (options && options.fillAlphaTop !== undefined) ? options.fillAlphaTop : 0.3;
        var botA = (options && options.fillAlphaBot !== undefined) ? options.fillAlphaBot : 0.0;
        var grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
        grad.addColorStop(0, withAlpha(strokeColor, topA));
        grad.addColorStop(1, withAlpha(strokeColor, botA));

        ctx.beginPath();
        ctx.moveTo(0, canvas.height);
        for (var i = 0; i < data.length; ++i)
            ctx.lineTo(i * w, canvas.height - (data[i] * canvas.height * yScale));
        ctx.lineTo(canvas.width, canvas.height);
        ctx.fillStyle = grad;
        ctx.fill();
    }

    // Stroke
    ctx.beginPath();
    for (var j = 0; j < data.length; ++j) {
        var x = j * w;
        var y = canvas.height - (data[j] * canvas.height * yScale);
        if (j === 0)
            ctx.moveTo(x, y);
        else
            ctx.lineTo(x, y);
    }
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2;
    ctx.stroke();
}
